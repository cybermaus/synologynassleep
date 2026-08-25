# synologynassleep
Script to sleep Synology NAS after inactivity.

For some reason, the hibernate is never working, even with no extra dockers or services running.
And in any case, hibernate is not all that efficient, energy wise.
My DS415+ device uses 50W, and 24/7 that adds up, and also I am annoyed by the hum
I just want to have a scheduled backup from my devices

So I made a script, if the disk IO is below a threshold for a prolonged time, it means no-one is doing anything and 
there are only some idle processes, so shutdown the server. 

To run this script, just add it to /volume1/scripts folder and run it from the job sceduler at boot, as root

-----

A partner script runs on my OpenWRT, it does a few things:
- At 19h00, send a scheduled WoL, as some other devices like HomeAssistant will do a backup at 19h10
- Any repeated TCP-SYN attempt on a exposed port used for SFTP based backup will send a WoL
This way, I can start my backup, wait 5 minutes and start it again. Or even just PuTTY to that port

I will add the OpenWRT scrips as soon as I have prettyfied it.
