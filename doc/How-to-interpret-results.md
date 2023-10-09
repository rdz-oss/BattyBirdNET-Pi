## Intrepreting the classifications


In order to get the most out of the system it helps to be aware of a few things. Unfortunately you cannot just assume that a detection is always due to a bat.
In short,

* Noise can trigger the classifier: This can be reduced by not entirely avoided. Look at the spectrogram visualization and decide if this is a noise trigger. This is very likely the case during daytime, and it does happen at night. Expect that this happens.
There are many sources of such noise:
  - The raspberryPi itself (operating noise). This is filtered out to a large degree by the classifiers.
  - The power plug of the RaspberryPi. This pollutes the recordings and triggers false detections. Take care
  to use noise cancelling foam around it or to get as big a distance between the power plug and the microphone.
  Or use a power bank.
  - Bush crickets can confuse the classifier. The classifier is trained to ignore them on samples from GER and SE, but not all types.
  - Cars while operating, parcking etc. Also, sometimes they have ultrasound based deterrrents for martens.
  - There are often two or more species flying at the same time. 
* There are several bat species which make very similar sound which can be hard for experts to manually tell apart. This is also hard for the classifier. Expect that the classifier identifies both species the call might have originated from. The more likely one will be identified more often, but you need to check with an expert or consult expert materials yourself.
Bats in Europe which have similar calls include, but are not limited to:

  - Myotis daubentonii and Myotis mystacinus/brandtii
  - Myotis mystacinus and Myotis brandtii are so similar they were added to one category (mystacinus) in the EU classifiers
  - Pipistrellus nathusii and Pipistrellus kuhlii
  - Pipistrellus pipistrellus and Pipistrellus pygmaeus
  - Nyctalus leisleri, Eptisecus serotinus, Vespertilio murinus
  - Plecotus auritus and Plecotus austriacus  are both under Plecotus auritus in the classifier

so expect that there is a certain degree of overlap between the species. Essentially, a classification is
a suggestion that it is one of these similar groups. Often right - but also expect mismatches in
the above categories.

You can use local knowledge to find the most likely species together with the classifier suggestion.
Also, you can consult handbooks on bat call identification.


















