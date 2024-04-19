#!/usr/bin/env python
import argparse
import sys
from suntime import Sun, SunTimeException
from datetime import datetime
from dateutil import tz

def _parse_args():
    parser = argparse.ArgumentParser(description='Provide info on sunrise and sundown for  a lat long.')
    parser.add_argument('--lat', type=float, default=51.11, help='Lotitude in WGS84')
    parser.add_argument('--lon', type=float, default=8.96, help='Longitude in WGS84')
    parser.add_argument('--updown', default="up", help='up or down')
    return parser.parse_args()

def main(lat, lon, updown):
    sun = Sun(lat, lon)
    t_time = ""
    today_sr = "06:00"
    today_ss = "18:00"
    now = datetime.now()
    tz_string = datetime.now().astimezone().tzname()


    # Get today's sunrise and sunset in UTC
    try:
        today_sr = sun.get_local_sunrise_time(now, tz.gettz(tz_string))
        today_ss = sun.get_local_sunset_time(now, tz.gettz(tz_string))
    except SunTimeException as e:
        print("Error: {0}.".format(e))

    if updown == "up":
        t_time = today_sr.strftime('%H:%M')
    else:
        t_time = today_ss.strftime('%H:%M')
    return t_time


if __name__ == '__main__':
    args = _parse_args()
    lat = args.lat
    lon = args.lon
    updown = args.updown

    res = main(lat, lon, updown)
    print(res)
    sys.exit(0)