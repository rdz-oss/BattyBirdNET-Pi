"""
This is the Python reference implementation for reading and writing GUANO metadata.

GUANO is the "Grand Unified Acoustic Notation Ontology", an extensible metadata format
for representing bat acoustics data.

Import this Python module as::

    import guano

This module utilizes the Python :mod:`logging` framework for issuing warnings and debug messages.
Application code may wish to enable logging with the :func:`logging.basicConfig` function.
Under The MIT License (MIT)
"""

import os
import sys
import wave
import struct
import os.path
import shutil
from datetime import datetime, tzinfo, timedelta
from contextlib import closing
from tempfile import NamedTemporaryFile
from collections import OrderedDict, namedtuple
from base64 import standard_b64encode as base64encode
from base64 import standard_b64decode as base64decode

import logging
log = logging.Logger(__name__)

if sys.version_info[0] > 2:
    unicode = str
    basestring = str


__version__ = '1.0.15.dev0'

__all__ = 'GuanoFile',


WHITESPACE = ' \t\n\x0b\x0c\r\0'

wavparams = namedtuple('wavparams', 'nchannels, sampwidth, framerate, nframes, comptype, compname')


_ZERO = timedelta(0)

class tzutc(tzinfo):
    """UTC timezone"""

    def utcoffset(self, dt):
        return _ZERO

    def tzname(self, dt):
        return 'UTC'

    def dst(self, dt):
        return _ZERO

    def __repr__(self):
        return 'UTC'

utc = tzutc()

class tzoffset(tzinfo):
    """
    Fixed-offset concrete timezone implementation.
    `offset` should be numeric hours or ISO format string like '-07:00'.
    """

    def __init__(self, offset):
        if isinstance(offset, basestring):
            # offset as ISO string '-07:00', '-0700', or '-07' format
            if len(offset) < 4:
                vals = offset, '00'              # eg '-07'
            elif ':' in offset:
                vals = offset.split(':')         # '-07:00'
            else:
                vals = offset[:-2], offset[-2:]  # '-0700'
            if vals[0].startswith('-'):
                offset = int(vals[0]) - int(vals[1])/60.0
            else:
                offset = int(vals[0]) + int(vals[1])/60.0
        self._offset_hours = offset
        self._offset = timedelta(hours=offset)

    def utcoffset(self, dt):
        return self._offset

    def dst(self, dt):
        return _ZERO

    def tzname(self, dt):
        return 'UTC'+str(self._offset_hours)

    def __repr__(self):
        return self.tzname(None)


def parse_timestamp(s):
    """
    Parse a string in supported subset of ISO 8601 / RFC 3331 format to :class:`datetime.datetime`.
    The timestamp will be timezone-aware of a TZ is specified, or timezone-naive if in "local" fmt.

    :rtype: datetime or None
    """
    # Python's standard library does an awful job of parsing ISO timestamps, so we do it manually

    if s is None or not s.strip():
        return None

    timestamp, tz = None, None

    s = s.replace(' ', 'T', 1)  # support using space rather than 'T' as date/time delimiter

    if s[-1] == 'Z':  # UTC "zulu" time
        tz = utc
        s = s[:-1]
    elif '+' in s or s.count('-') == 3:  # UTC offset provided
        i = s.index('+') if '+' in s else s.rfind('-')
        s, offset = s[:i], s[i:]
        tz = tzoffset(offset)

    if len(s) > 22:  # milliseconds included
        timestamp = datetime.strptime(s, '%Y-%m-%dT%H:%M:%S.%f')
    else:
        timestamp = datetime.strptime(s, '%Y-%m-%dT%H:%M:%S')

    return timestamp.replace(tzinfo=tz) if tz else timestamp


_chunkid = struct.Struct('> 4s')
_chunksz = struct.Struct('< L')


class GuanoFile(object):
    """
    An abstraction of a .WAV file with GUANO metadata.

    A `GuanoFile` object behaves like a normal Python :class:`dict`, where keys can either be
    well-known metadata keys, namespaced keys, or a tuple of (namespace, key).

    Well-known keys will have their values coerced into the correct data type. The parser may be
    configured to coerce new namespaced keys with the :func:`register()` function.

    Example usage::

        gfile = GuanoFile('myfile.wav')
        print gfile['GUANO|Version']
        >>> '1.0'
        gfile['Species Manual ID'] = 'Mylu'
        gfile['Note'] = 'I love GUANO!'
        gfile.write()

    Though reading, writing, and editing .WAV files is the target usage, this class may also be
    used independent from the .WAV file format. GUANO metadata can be written into an
    Anabat-format file or to a sidecar file, for example, by populating a `GuanoFile` object and
    then using the :func:`serialize()` method to produce correctly formatted UTF-8 encoded metadata.

    :ivar str filename:  path to the file which this object represents, or `None` if a "new" file
    :ivar bool strict_mode:  whether the GUANO parser is configured for strict or lenient parsing
    :ivar bytes wav_data:  the `data` subchunk of a .WAV file consisting of its actual audio data,
                           lazily-loaded and cached for performance
    :ivar wavparams wav_params:  namedtuple of .WAV parameters (nchannels, sampwidth, framerate, nframes, comptype, compname)
    """

    _coersion_rules = {
        'Filter HP': float,
        'Length': float,
        'Loc Accuracy': float,
        'Loc Elevation': float,
        'Loc Position': lambda value: tuple(float(v) for v in value.split()),
        'Note': lambda value: value.replace('\\n', '\n'),
        'Samplerate': int,
        'TE': lambda value: int(value) if value else 1,
        'Timestamp': parse_timestamp,
    }
    _serialization_rules = {
        'Length': lambda value: '%.2f' % value,
        'Loc Position': lambda value: '%f %f' % value,
        'Note': lambda value: value.replace('\n', '\\n'),
        'Timestamp': lambda value: value.isoformat() if value else '',
    }

    def __init__(self, filename=None, strict=False):
        """
        Create a GuanoFile instance which represents a single file's GUANO metadata.
        If the file already contains GUANO metadata, it will be parsed immediately. If not, then
        this object will be initialized as "new" metadata.

        :param filename:  path to an existing .WAV file with GUANO metadata; if the path does not
                          exist or is `None` then this instance represents a "new" file
        :type filename:  str or None
        :param bool strict:  whether the parser should be strict and raise exceptions when
                             encountering bad metadata values, or whether it should be as lenient
                             as possible (default: False, lenient); if in lenient mode, bad values
                             will remain in their UTF-8 string form as found persisted in the file
        :raises ValueError:  if the specified file doesn't represent a valid .WAV or if its
                             existing GUANO metadata is broken
        """
        self.filename = filename
        self.strict_mode = strict

        self.wav_params = None
        self._md = OrderedDict()  # metadata storage - map of maps:  namespace->key->val

        self._wav_data = None  # lazily-loaded and cached
        self._wav_data_offset = 0
        self._wav_data_size = 0

        if filename is not None and os.path.isfile(filename):
            self._load()

    def _coerce(self, key, value):
        """Coerce a value from its Unicode representation to a specific data type"""
        if key in self._coersion_rules:
            try:
                return self._coersion_rules[key](value)
            except (ValueError, TypeError) as e:
                if self.strict_mode:
                    raise
                else:
                    log.warning('Failed coercing "%s": %s', key, e)
        return value  # default should already be a Unicode string

    def _serialize(self, key, value):
        """Serialize a value from its real representation to GUANO Unicode representation"""
        serialize = self._serialization_rules.get(key, unicode)
        try:
            return serialize(value)
        except (ValueError, TypeError) as e:
            if self.strict_mode:
                raise
            else:
                log.warning('Failed serializing "%s": %s', key, e)

    def _load(self):
        """Load the contents of our underlying .WAV file"""
        fsize = os.path.getsize(self.filename)
        if fsize < 8:
            raise ValueError('File too small to contain valid RIFF "WAVE" header (size %d bytes)' % fsize)

        with open(self.filename, 'rb') as f:

            f.seek(0x08)
            chunk = _chunkid.unpack(f.read(4))[0]
            if chunk != b'WAVE':
                raise ValueError('Expected RIFF chunk "WAVE" at 0x08, but found "%s"' % repr(chunk))

            try:
                f.seek(0)
                self.wav_params = wavparams(*wave.open(f).getparams())
            except RuntimeError as e:
                return ValueError(e)  # Python's chunk.py throws this inappropriate exception

            # iterate through the file until we find our 'guan' subchunk
            metadata_buf = None
            f.seek(0x0c)
            while f.tell() < fsize - 1:
                try:
                    chunkid = _chunkid.unpack(f.read(4))[0]
                    size = _chunksz.unpack(f.read(4))[0]
                except struct.error as e:
                    raise ValueError(e)

                if chunkid == b'guan':
                    metadata_buf = f.read(size)
                elif chunkid == b'data':
                    self._wav_data_offset = f.tell()
                    self._wav_data_size = size
                    f.seek(size, 1)
                else:
                    f.seek(size, 1)

                if size % 2:
                    f.read(1)  # align to 16-bit boundary

            if not self._wav_data_offset:
                raise ValueError('No DATA sub-chunk found in .WAV file')

            if metadata_buf:
                self._parse(metadata_buf)

    def _parse(self, metadata_str):
        """Parse metadata and populate our internal mappings"""
        if not isinstance(metadata_str, unicode):
            try:
               metadata_str = metadata_str.decode('utf-8')
            except UnicodeDecodeError as e:
                log.warning('GUANO metadata is not UTF-8 encoded! Attempting to coerce. %s', self.filename)
                metadata_str = metadata_str.decode('latin-1')

        for line in metadata_str.split('\n'):
            line = line.strip(WHITESPACE)
            if not line:
                continue
            full_key, val = line.split(':', 1)
            namespace, key = full_key.split('|', 1) if '|' in full_key else ('', full_key)
            namespace, key, full_key, val = namespace.strip(), key.strip(), full_key.strip(), val.strip()
            if not key or not val:
                continue
            if namespace not in self._md:
                self._md[namespace] = OrderedDict()
            self._md[namespace][key] = self._coerce(full_key, val)
        return self

    @classmethod
    def from_string(cls, metadata_str, *args, **kwargs):
        """
        Create a :class:`GuanoFile` instance from a GUANO metadata string

        :param metadata_str:  a string (or string-like buffer) of GUANO metadata
        :param bool strict:  whether the parser should be strict and raise exceptions when
                             encountering bad metadata values, or whether it should be as lenient
                             as possible (default: True); if in lenient mode, bad values will
                             remain in their UTF-8 string form as found persisted in the file
        :rtype:  GuanoFile
        """
        return GuanoFile(*args, **kwargs)._parse(metadata_str)

    @classmethod
    def register(cls, namespace, keys, coerce_function, serialize_function=str):
        """
        Configure the GUANO parser to recognize new namespaced keys.

        :param namespace:  vendor namespace which the keys belong to
        :param keys:  a key or sequence of keys under the specified vendor namespace
        :param coerce_function:  a function for coercing the UTF-8 value to any desired data type
        :type coerce_function:  callable
        :param serialize_function:  an optional function for serializing the value to UTF-8 string
        :type serialize_function:  callable
        """
        if isinstance(keys, basestring):
            keys = [keys]
        for k in keys:
            full_key = namespace+'|'+k if namespace else k
            cls._coersion_rules[full_key] = coerce_function
            cls._serialization_rules[full_key] = serialize_function

    def _split_key(self, item):
        if isinstance(item, tuple):
            namespace, key = item[0], item[1]
        elif '|' in item:
            namespace, key = item.split('|', 1)
        else:
            namespace, key = '', item
        return namespace, key

    def __getitem__(self, item):
        namespace, key = self._split_key(item)
        return self._md[namespace][key]

    def get(self, item, default=None):
        try:
            return self[item]
        except KeyError:
            return default

    def __setitem__(self, key, value):
        if not self._md:
            self._md['GUANO'] = {}
            self._md['GUANO']['Version'] = '1.0'

        namespace, key = self._split_key(key)
        if namespace not in self._md:
            self._md[namespace] = {}
        self._md[namespace][key] = value

    def __contains__(self, item):
        namespace, key = self._split_key(item)
        return namespace in self._md and key in self._md[namespace]

    def __delitem__(self, key):
        namespace, key = self._split_key(key)
        del self._md[namespace][key]
        if not self._md[namespace]:
            del self._md[namespace]

    def __bool__(self):
        return bool(self._md)
    __nonzero__ = __bool__  # py2

    def __repr__(self):
        return '%s(%s)' % (self.__class__.__name__, self.filename)

    def get_namespaces(self):
        """
        Get list of all namespaces represented by this metadata.
        This includes the 'GUANO' namespace, and the '' (empty string) namespace for well-known fields.
        """
        return self._md.keys()

    def items(self, namespace=None):
        """Iterate over (key, value) for entire metadata or for specified namespace of fields"""
        if namespace is not None:
            for k, v in self._md[namespace].items():
                yield k, v
        else:
            for namespace, data in self._md.items():
                for k, v in data.items():
                    k = '%s|%s' % (namespace, k) if namespace else k
                    yield k, v

    def items_namespaced(self):
        """Iterate over (namespace, key, value) for entire metadata"""
        for namespace, data in self._md.items():
            for k, v in data.items():
                yield namespace, k, v

    def well_known_items(self):
        """Iterate over (key, value) for all the well-known (defined) fields"""
        return self.items('')

    def to_string(self):
        """Represent the GUANO metadata as a Unicode string"""
        lines = []
        for namespace, data in self._md.items():
            for k, v in data.items():
                k = u'%s|%s' % (namespace, k) if namespace else k
                v = self._serialize(k, v)
                lines.append(u'%s: %s' % (k, v))
        return u'\n'.join(lines)

    def serialize(self, pad='\n'):
        """Serialize the GUANO metadata as UTF-8 encoded bytes"""
        md_bytes = bytearray(self.to_string(), 'utf-8')
        if pad is not None and len(md_bytes) % 2:
            # pad for alignment on even word boundary
            md_bytes.append(ord(pad))
        return md_bytes

    @property
    def wav_data(self):
        """Actual audio data from the wav `data` chunk. Lazily loaded and cached."""
        if not self._wav_data_size:
            raise ValueError()
        if not self._wav_data:
            with open(self.filename, 'rb') as f:
                f.seek(self._wav_data_offset)
                self._wav_data = f.read(self._wav_data_size)
        return self._wav_data

    @wav_data.setter
    def wav_data(self, data):
        self._wav_data_size = len(data)
        self._wav_data = data

    def write(self, make_backup=True):
        """
        Write the GUANO .WAV file to disk.

        :param bool make_backup:  create a backup file copy before writing changes or not (default: True);
                                  backups will be saved to a folder named `GUANO_BACKUP`
        :raises ValueError:  if this `GuanoFile` doesn't represent a valid .WAV by having
            appropriate values for `self.wav_params` (see :meth:`wave.Wave_write.setparams()`)
            and `self.wav_data` (see :meth:`wave.Wave_write.writeframes()`)
        """
        # FIXME: optionally write other unknown subchunks for redundant metadata formats

        if not self.filename:
            raise ValueError('Cannot write .WAV file without a self.filename!')
        if not self.wav_params:
            raise ValueError('Cannot write .WAV file without appropriate self.wav_params (see `wavfile.setparams()`)')
        if not self.wav_data:
            raise ValueError('Cannot write .WAV file without appropriate self.wav_data (see `wavfile.writeframes()`)')

        # prepare our metadata for a byte-wise representation
        md_bytes = self.serialize()

        # create tempfile and write our vanilla .WAV ('data' sub-chunk only)
        tempfile = NamedTemporaryFile(mode='w+b', prefix='guano_temp-', suffix='.wav', delete=False)
        if os.path.isfile(self.filename):
            shutil.copystat(self.filename, tempfile.name)

        with closing(wave.Wave_write(tempfile)) as wavfile:
            wavfile.setparams(self.wav_params)
            wavfile.writeframes(self.wav_data)

        # add the 'guan' sub-chunk after the 'data' sub-chunk
        tempfile.write(_chunkid.pack(b'guan'))
        tempfile.write(_chunksz.pack(len(md_bytes)))
        tempfile.write(md_bytes)

        # fix the RIFF file length
        total_size = tempfile.tell()
        tempfile.seek(0x04)
        tempfile.write(_chunksz.pack(total_size - 8))
        tempfile.close()

        # verify it by re-parsing the new version
        GuanoFile(tempfile.name)

        # finally overwrite the original with our new version (and optionally back up first)
        if make_backup and os.path.exists(self.filename):
            backup_dir = os.path.join(os.path.dirname(self.filename), 'GUANO_BACKUP')
            backup_file = os.path.join(backup_dir, os.path.basename(self.filename))
            if not os.path.isdir(backup_dir):
                log.debug('Creating backup dir: %s', backup_dir)
                os.mkdir(backup_dir)
            if os.path.exists(backup_file):
                os.remove(backup_file)
            shutil.move(self.filename, backup_file)
        shutil.move(tempfile.name, self.filename)


# This ugly hack prevents a warning if application-level code doesn't configure logging
if sys.version_info[0] > 2:
    NullHandler = logging.NullHandler
else:
    class NullHandler(logging.Handler):
        def emit(self, record):
            pass
log.addHandler(NullHandler())
