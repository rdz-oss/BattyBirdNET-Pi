## Interpreting the classifications


In order to get the most out of the system it helps to be aware of a few things. Unfortunately you cannot just assume that a detection is always due to a bat.
Essentially, a classification is a suggestion that it is one of these similar groups. Often right - but also expect mismatches in
the above categories.

You can use local knowledge to find the most likely species together with the classifier suggestion.
Also, you can consult handbooks on bat call identification.

### Noise can trigger the classifier

This can be reduced by not entirely avoided. Look at the spectrogram visualization and decide if this is a noise trigger. This is very likely the case during daytime, and it does happen at night. Expect that this happens.
There are many sources of such noise:
  - The RaspberryPi itself (operating noise). This is filtered out to a large degree by the classifiers.
  - The power plug of the RaspberryPi. This pollutes the recordings and triggers false detections. Take care
  to use noise cancelling foam around it or to get as big a distance between the power plug and the microphone.
  Or use a power bank.
  - Bush crickets can confuse the classifier. The classifier is trained to ignore them on samples from GER and SE, but not all types.
  - Cars while operating, parcking etc. Also, sometimes they have ultrasound based deterrrents for martens.
  - There are often two or more species flying at the same time. 

### Some bats have near identical calls

There are several bat species which make very similar sound which can be hard for experts to manually tell apart. This is also hard for the classifier. Expect that the classifier identifies both species the call might have originated from. The more likely one will be identified more often, but you need to check with an expert or consult expert materials yourself.
Bats in Europe which have similar calls include, but are not limited to:

  - Myotis daubentonii and Myotis mystacinus/brandtii
  - Myotis mystacinus and Myotis brandtii are so similar they were added to one category (mystacinus) in the EU classifiers
  - Pipistrellus nathusii and Pipistrellus kuhlii
  - Pipistrellus pipistrellus and Pipistrellus pygmaeus
  - Nyctalus leisleri, Eptisecus serotinus, Vespertilio murinus
  - Plecotus auritus and Plecotus austriacus  are both under Plecotus auritus in the classifier

so expect that there is a certain degree of overlap between the species. 

### Typical end call frequencies of European bats

* Calls are very variable and affected by the bats surroundings
* In woodland there are many obstacles to avoid and bat sound become more similar
* It is not always possible to ID a bat just from echolocation calls
* There are echo location calls as well as social calls. Social calls can be on very different frequencies.

### Echolocation frequency
A quick overview for a first orientation. Bats shift up or downwards depending also on each others presence and 
the environment.

Echolocation frequency (max energy) | Common name           | Species         | 
|-----------------|-----------------------|-----------------|
20-25 kHz | Noctule               | Nyctalus noctula | 
25 kHz | Leislers              | Nyctalus leisleri | 
27 kHz | Serotine              | Eptisecus serotinus | 
28 kHz  | Vespertilio murinus   | Part-coloured bat | 
32 kHz  | Eptisecus nilssoni    | Northern bat    | 
32 kHz | Barbastelle           | Barbastella barbastellus | 
39 kHz | Nathusius pipistrelle | Pipistrellus nathusii | 
36-40 kHz | Kuhls pipistrelle     | Pioistrellus kuhlii | 
43-46 kHz | Alcathoe              | Myotis alcathoe | 
45 kHz | Common pipistrelle    | Pipistrellus pipistrellus | 
45 kHz | Whiskered             | Myotis mystacinus | 
45 kHz | Brandts               | Myotis brandtii | 
45 kHz | Daubentons            | Myotis daubentonii | 
45-50 kHz | Brown long-eared      | Plecotus auritus | 
45-50 kHz | Grey long-eared       | Plecotus austriacus |
50 kHz | Natterers             | Myotis natteri  | 
50 kHz | Bechsteins            | Myotis bechsteinii | 
55 kHz | Soprano pipistrelle   | Pipistrellus pygmaeus | 
80 kHz | Greater Horseshoe     | Rhinolophus ferrumequinum | 
108 kHz | Lesser Horseshoe      | Rhinolophus hipposideros | 





















