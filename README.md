# tautulli_rtorrent_throttler

**Description**

Most of us still use low speed connexions. Having a Plex Media Server and a torrent client in often struggling. You don't want to always throttle your torrent client to leave Plex enough bandwidth because you need ratio. And if you don't throttle, your Plex clients miss bandwidth time to time for a smooth playing. 
This script allows to automatically throttle rTorrent/ruTorrent when Plex Media Server streams to external clients.  
It uses Tautully, which is a monitoring tool for Plex Media Server. It allows to compute great statistics about your Plex server and it is able to trigger script execution on given events. 
Tautully informs the scripts that a stream is playing with the needed bandwidth, stream duration and client's IP. Serveral events are caught to be accurate as possible.   
The script automatically throttle rTorrent for the needed time and bandwidth. It uses SCGI communication (like ruTorrent), so your rTorrent shall be on your local network for security purpose. 

**Dependencies**   
[rTorrent](https://github.com/rakshasa/rtorrent)  
[ruTorrent](https://github.com/Novik/ruTorrent)  
[Tautully](https://github.com/Tautulli/Tautulli)  
[XMLRPC2SCGI](https://github.com/rakshasa/rtorrent/wiki/RPC-Utility-XMLRPC2SCGI)  
[Plex Media Server](https://www.plex.tv/)  
[Git](https://git-scm.com/) 
Python 

**Setup**   
This tutorial won't explain how to install git, rTorrent, ruTorrent, Tautully and Plex Media Server. 

If you need to install one or serveral of those depencies, please refer to an external tutorial. That been said, for an easy deployement with Docker containers, you can use the excellent [PlexGuide script](https://plexguide.com/). If you need a VPN encapsulated version of rTorrent/ruTorrent with port forwarding, [rTorrentVPN](https://github.com/binhex/arch-rtorrentvpn) is for you.

**XMLRPC2SCGI**   
XMLRPC2SCGI is a Ptyhon script allowing to send command to rTorrent deamon through its scgi port. 

First, clone git repository
``` 
cd /tmp
git clone https://github.com/rakshasa/rtorrent-vagrant.git
``` 
Move the script and add rights (could be at any location accessible to user running Tautulli). 

``` 
 sudo mv rtorrent-vagrant/scripts/xmlrpc2scgi.py /usr/bin/
 sudo chmod 775 /home/user/scripts/xmlrpc2scgi.py
``` 
 Clean unwanted files
``` 
 rm -rf rtorrent-vagrant
``` 

**tautulli_rtorrent_throttler**  
We need to install and configure the throttling script. 
First, clone git repository. 
``` 
cd 
git clone https://github.com/Blacksad-cat/tautulli_rtorrent_throttler.git
``` 
**Script config**  
We need to setup few finds in the script, so open it in your prefered editor. 
``` 
cd tautulli_rtorrent_throttler 
nano tautulli_rtorrent_throttler.sh 
``` 
Set xmlrpc2scgi path.
``` 
XMLRPC2SCGI=/usr/bin/xmlrpc2scgi.py
``` 
Set IP on which rTorrent is running (not ruTorrent). Likely the localhost (127.0.0.1).
Set rTorrent SCGI port. rTorrent default is 5000. If your rTorrent is distant, ensure scgi port is reachable.
``` 
RTORRENT_ADR=127.0.0.1
SCGI_PORT=5000
``` 
The white list avoid throttling torrent traffic for IPs in the list. For exemple, you don't want to slow down your torrent traffic for local connexion. 
The list is space separated and allows cibr format. 
``` 
WHITE_LIST="192.168.1.0/24"
``` 
You must tell the script your maximum upload and download rate, so it can throttle properly your connexion. If you have an unstable bandwidth, you should be conservative and put your lowest rate. 
Rate is given in B/s. The exemple shows a 400/50Mbps max download/upload. 
 From Mbps multiply by 131072  
 From kbp multiply by 128  
 From kB/s multiply by 1024  
 From MB/s multiply by 1048576  
 From GB/s you don't need this script :p 
``` 
MAX_UPLOAD_RATE=6553600  
MAX_DOWNLOAD_RATE=52428800  
``` 
Uploading a stream requieres a bit of download bandwidth... At least for acks.  
I recommand to throttle a little bit your download. 30% of needed upload bandwidth is enough. But you can disable it if you want.  
``` 
THROTTLE_UPLOAD=true  
DOWNLOAD_THROTTLE_FACTOR=30  
```  
Save the script (Ctrl+x from nano).
Let's move it to an accessible location (could be at any location accessible to user running Tautulli). 
``` 
 sudo mv tautulli_rtorrent_throttler.sh /usr/bin/ 
 sudo chmod 775 /home/user/scripts/tautulli_rtorrent_throttler.sh 
```  
**Tautulli config**  
Open Tautulli settings page, click "Notification Agents", then "Add a Notification Agent". Choose "Script".
In "Configuration" tab, enter the script folder 
``` 
/usr/bin/
```  
And script file: 
``` 
tautulli_rtorrent_throttler.sh 
```  
In "Triggers" tab select:   
Playback Start  
Playback Stop  
Playback Resume  
Playback Pause   
Transcode Decision Change    
Watched    

In Arguments tab, fill out as following: 
Playback Start  
``` 
-play "{ip_address}" "{session_id}" "{remaining_duration}" "{stream_bandwidth}"
```  
Playback Stop  
``` 
-stop "{ip_address}" "{session_id}"
```  
Playback Resume  
``` 
-play "{ip_address}" "{session_id}" "{remaining_duration}" "{stream_bandwidth}"
```  
Playback Pause 
``` 
-pause "{ip_address}" "{session_id}" "{remaining_duration}" "{stream_bandwidth}"
```  
Transcode Decision Change 
``` 
-play "{ip_address}" "{session_id}" "{remaining_duration}" "{stream_bandwidth}"
```  
Watched  
``` 
-watched "{ip_address}" "{session_id}" "{remaining_duration}" "{stream_bandwidth}"
```  
Save. 
Tautulli configuration is done. 
**Systemd timer**  
Finally, we need to settup as timer checking if throttling is needed frequently. We will do that with a systemd timer, but you can use another system. All you need is calling the script with "check" flag. 
``` 
/home/user/scripts/tautulli_rtorrent_throttler.sh  -check
```  

By default, the service is configured to run as root. But as there is no reason to run it with those priviledges, I recommend to change it. The user you will use must be part of syslog group. If not, you will miss logs.  
Open the service file with your favorite editor. 
``` 
nano tautulli_rtorrent_throttler.service 
```  
Update "User" and "Group" fields as your convenience and save the file. 
Copy service and timer files to systemd folder. 
``` 
sudo cp tautulli_rtorrent_throttler.service /etc/systemd/system/
sudo cp tautulli_rtorrent_throttler.timer /etc/systemd/system/
chmod 664 /etc/systemd/system/tautulli_rtorrent_throttler.service 
chmod 664 /etc/systemd/system/tautulli_rtorrent_throttler.timer 
```  
Enable the service and start the timer.
