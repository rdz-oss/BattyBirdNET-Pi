<p align="center">
  <img src="homepage/images/bnp.png" width="320" />
</p>

## BattyBirdNET-Pi  Automated real-time bat detection & id

Fully functional and extended fork of BirdNET-Pi for bats.

### Purpose
Ever wondered which bat is flying in your yard and when? BattyBirdNET-Pi is readily assembled and will help you getting to know the 
night-life around you. Can also be placed remotely with a power source.

* Scans ultrasound with 256kHz sampling rate continuously from dusk to dawn (timer function) 
* Automated bat ID using the companion https://github.com/rdz-oss/BattyBirdNET-Analyzer.
* Inherits many great things from BirdNET-Pi - including notifications on detection
* Enabled for European, UK and North American species
* Not designed for automated biodiversity assessments - recreational use at this point.
* Adds some meta-data in GUANO format to the recordings
* Requires either audiomoth 1.2 (very cool open hardware) or wildlife acoustics echo meter touch 2 microphones and RaspberryPi 4B.

Keywords: bat detection, automated bat identification, deep learning, machine learning at the edge, raspberry pi, transfer learning,
citizen science, acoustic biomonitoring, audiomoth, BirdNET-Pi for bats, BatNET

### Installations around the world
There are several installations in the US, Germany and the UK that I am aware of. One of my dev stations can be checked out.
Keep in mind it is a development station - testing things and potentially unstable or unavailable. But likely here:

http://battybirdnet.duckdns.org:6734/

Bats tend to fly at dusk GER time from 18:30 on. Kuhls Pipistrelle and Nyctalus Noctula likely.

### License
Enjoy! Feel free to use BattyBirdNET-Pi for your acoustic analyses and research. If you do, please cite as:
``` bibtex
@misc{Zinck2023,
  author = {Zinck, R.D.},
  title = {BattyBirdNET-Pi: Automated real-time bat detector},
  year = {2023},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/rdz-oss/BattyBirdNET-Pi }}
}
```
Be aware there is a  limitation: you cannot use it to build a commercial system.
LICENSE: http://creativecommons.org/licenses/by-nc-sa/4.0/  
Also consider the references at the end of the page.

### Screenshots
Overview page

<img src="homepage/images/BatNET-Pi-Screen.png" width="800" />

Including stats and spectrograms to 128 kHz

<img src="homepage/images/BatNET-Pi-Screen-3.png" width="800" />

### System components

* A RasPi 4B with 4GB or more, currently Pi 5 will not work (similar to BirdNET-PI). Use some form of passive or active cooling!
* Power supply for the Raspi and an sd card - choose a large one 64 Gb +
* A USB microphone for ultra sound: tested on audiomoth usb 1.2 and wildlife acoustics echo meter touch 2 (2 and 2 pro)
* USB cable (USB C female to USB 3, 1.2m) or a USB 3 to USB 3 cable and a USB to USB C adapter
* Optional: You can use a power bank to run the system as long as the power lasts at any location. 
You might want to add some form of rain protection.

Some hints:

* The echo meter touch 2 pro works for my setup but not for some. Unkown reason at this point.
* If you use the audiomoth, you will have to set the sampling frequency to 250kHz or the system will overload after a few hours.
* https://www.openacousticdevices.info/audiomoth  (Usb or battery version with usb microphone configuration). 
You will need a USB A male to micro USB cable to connect this one.
* https://www.wildlifeacoustics.com/products/echo-meter-touch-2-android-2

It is easily assembled
<p align="center">
  <img src="homepage/images/System-1.png" width="400" />
</p>

### Location and setup hints
1. Find a place with low noise from crickets, machinery (cars), or electrical appliances and outlets. They
tend to produce ultra sonic noise. Be aware that the RaspberryPi itself and its power source generate considerate ultra sound noise.
2. Place it in the bats flight path (elevated e.g. 3m if you can) or point it to the flight paths.
3. Place it away from reflective surfaces or other sources of echo. It does work (in Munich) between buildings, 
but there is an echo effect as well as the bats adapting to the situation (calls shift a bit).
4. Shield your power converter with acoustic padding or use a long power cable to avoid the ultra sound noise
in your recordings as well as false detections. Less such issues if run from  a power bank.

#### Use as a station
You can run the station continuously if you like, e.g. at your home.
However, note that the DC/AC power converter of the RasPi (the 'plug') produces a lot of ultrasound noise that triggers the classifier. As there are many
versions out there the classifier cannot be trained on the noise of all to avoid that. Also, you will have the noise in the recordings.
So use as long a cable to get away from the power source as far as you can. Shield it if you have a way to do that e.g. by a wall.
Until another solution is found **it is recommended to run the system with a power bank.**. This way, you will only have some noise from the RasPi which
is not as bad and consistent among setups.

#### Use on the go
You can plug the RasPi into a power bank, put the entire thing in your backpack and take a walk. Use a 1.2m usb cable for this
and point the microphone to where you want.
Also, you can connect the RasPi to the WIFI hotspot on your phone. To do that, rename your phone WIFI hotspot
to the name and password expected by the RasPi ( the one you configured during installation). You got yourself a nice
bat detector for your adventures on foot. Live spectrogram included. 

### Is it good enough?
That depends on your purpose. Use your judgement, no guarantees or liability. I would not currently use it for fully automated biomonitoring. That said,
in test runs in Munich (October) the error rate was approximately (rough estimate, no science):
* Wrong 3% for every bat species flying plus 8% on noise falsely detected as bats 
* So at that location 4 bats species flying simultaneously would currently lead to approximately:  12%+8% = 20% wrong assessments on species level
per night (not counting false noise detections during daytime).
This may differ for other locations and background noises. 
* Under development - moving target. You can contribute by writing me when things are not working well.

## Interpreting the classifications
In order to get the most out of the system it helps to be aware of a few things. Unfortunately you cannot just assume that a detection is always due to a bat.
Essentially, a classification is a suggestion that it is one of these similar groups. Often right - but also expect mismatches in
the below categories.

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
  - Cars while operating, parking etc. Also, sometimes they have ultrasound based deterrents for martens.
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

</br></br>

<p align="center">
  <img src="doc/images/320px-Haeckel_Chiroptera_Plecotus_auritus_2.jpg" width="320" />
</p>

### Typical call frequencies of European bats

* Calls are very variable and affected by the bats surroundings
* In woodland there are many obstacles to avoid and bat sound become more similar
* It is not always possible to ID a bat just from echolocation calls
* There are echo location calls as well as social calls. Social calls can be on very different frequencies.

### Echolocation frequency (max energy)
A quick overview for a first orientation. Bats shift up or downwards depending also on each others presence and 
the environment. Highest energy is the lightest color in the spectrogram.

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

### Eastern US Species
Echolocation frequency (max energy) | Common name                 | Species                   | 
|-----------------|-----------------------------|---------------------------|
21 kHz | Hoary bat                   | Lasiurus cinereus         | 
28 kHz | Free–tailed bat             | Tadarida  brasiliensis    | 
29 kHz | Northern yellow bat         | Lasiurus intermedius      | 
29 kHz | Silver–haired bat           | Lasionycteris noctivagans | 
32 kHz | Big brown bat               | Eptesicus fuscus          | 
31 kHz | Townsend’s big–eared bat    | Corynorhinus townsendii   | 
33 kHz | Rafinesque’s big–eared bat  | Cornorhinus rafinesquii   | 
40 kHz | Evening bat                 | Nycticeius humeralis      | 
43 kHz | Seminole bat                | Lasiurus seminolus        | 
44 kHz | Little brown bat            | Myotis lucifugus          | 
44 kHz | Tri-colored bat             | Perimyotis subflavus      | 
44 kHz | EasternRed Bat              | Lasiurus borealis         | 
44 kHz | Indiana bat                 | Myotis sodalis            | 
46 kHz | South-eastern myotis        | Myotis austroriparius     | 
48 kHz | Gray bat                    | Myotis grisescens         | 
49 kHz | Eastern small–footed myotis | Myotis leibii             |
51 kHz | Northern long-eared myotis  | Myotis septentrionalis    | 

### Western US Species
Echolocation frequency (max energy) | Common name                     | Species                   | 
|-----------------|---------------------------------|---------------------------|
12.5 kHz | Spotted bat                     | Euderma maculatum         |
13 kHz | Mastiff bat                     | Eumops perotis            |
22 kHz | Hoary bat                       | Lasiurus cinereus         |
25 kHz | Big freetailed / pocketed bats  | Nyctinomops spp.          |
28 kHz | free–tailed bat                 | Tadarida brasiliensis     |
29 kHz | Silver–haired bat               | Lasionycteris noctivagans |
30 kHz | Fringed myotis                  | Myotis thysanodes         |
31 kHz | Townsend’s big–eared bat        | Corynorhinus townsendii   |
32 kHz | Pallid bat                      | Antrozous pallidus        |
32 kHz | Big brown bat                   | Eptesicus fuscus          |
37 kHz | Western yellow bat              | Lasiurus xanthinus        | 
39 kHz | Long–eared myotis               | Myotis evotis             | 
42 kHz | Western red bat                 | Lasiurus blossevillii     | 
44 kHz | Little brown bat                | Myotis lucifugus          | 
48 kHz | Hairy–winged myotis             | Myotis volans             | 
48 kHz | Canyon bat (western pip.)       | Parastrellus hesperus     |
49 kHz | Small–footed myotis             | Myotis ciliolabrum        | 
53 kHz | California myotis               | Myotis californicus       | 
55 kHz | Yuma myotis                     | Myotis yumanensis         | 

</br></br>

<p align="center">
  <img src="doc/images/Bat_found_in_summer_of_2021_and_currently_unidentified.jpg" width="320" />
</p>

### Install
* Install Raspbian OS 64 bit lite on the sd card. **Use the legacy version (Bullseye based)**. Set a system user, name and configure your WIFI. If you have not done this before, 
you can follow the instructions for installing BirdNET-Pi to the point of flashing the sd card with the operating system ([see here](./README-BirdNET-Pi.md)). 
* After that you will log in to the RasPi with your username and password via ssh (it should be in your wireless LAN after booting)
* You call the install script from this repository (i.e.. this is where you deviate from the instructions found for BirdNET-Pi)
```sh
curl -s https://raw.githubusercontent.com/rdz-oss/BattyBirdNET-Pi/main/newinstaller.sh | bash
```
The operating system is now updated, two repositories are pulled from github, files are copied for the automation of services, the webserver setup etc.
Might take a few minutes. When done, it will reboot. **If you see a bat flying in the middle of the WbUI - you have installed BattyBirdNET-Pi**.

You can connect to the WebUI via your browser if you are in the same WIFI network. It should show up under http://name-you-gave-it.local .
This sometimes does not work depending on your router configuration. You can look up the ip address given to the BattyBirdNET-Pi
in your router and call that directly from the browser, e.g. http://192.168.178.XX . Alternatively, tools like Ning (https://f-droid.org/packages/de.csicar.ning/) on your smartphone will
list all the devices in your network. The BattyBirdNET-Pi should show up.

### To use the North American/UK version:

* Install as above, 
* Go to the Tools setting
* Log in as user 'birdnet', leave password empty
* Settings -> Advanced Settings -> Bat Classifier (use USA or UK)
* The system will reboot, wait two minutes refresh browser

### Acknowledgements
* This project would not have been possible without the developers of BirdNET and BirdNET-Pi.
* Thanks to the Animal Sound Archive Berlin, ChiroVox, NABAT and XenoXanto databases and individual data donors:
Kelvin R. (UK), Guillaume M. (FR), Svardsten L. (SE), Zinck R. (GER).
* Thank you for your great work at testing Kelvin!
* Thank you @spambake and Bill from Pixcams Inc for your support in getting the US version up to shape!
* Thank you community for tips and testing! Your help is much appreciated!

### References

### Papers

FROMMOLT, KARL-HEINZ. "The archive of animal sounds at the Humboldt-University of Berlin." Bioacoustics 6.4 (1996): 293-296.

Görföl, Tamás, et al. "ChiroVox: a public library of bat calls." PeerJ 10 (2022): e12445.

Gotthold, B., Khalighifar, A., Straw, B.R., and Reichert, B.E., 2022, 
Training dataset for NABat Machine Learning V1.0: U.S. Geological Survey 
data release, https://doi.org/10.5066/P969TX8F.

Kahl, Stefan, et al. "BirdNET: A deep learning solution for avian diversity monitoring." Ecological Informatics 61 (2021): 101236.

### Links

https://www.museumfuernaturkunde.berlin/en/science/animal-sound-archive

https://www.chirovox.org/

https://www.sciencebase.gov/catalog/item/627ed4b2d34e3bef0c9a2f30

https://github.com/kahst/BirdNET-Analyzer

https://github.com/mcguirepr89/BirdNET-Pi
