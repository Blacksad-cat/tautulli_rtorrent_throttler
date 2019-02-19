# tautulli_rtorrent_throttler

**Description**

Most of us still use low speed connexions. Having a Plex Media Server and a torrent client in often struggling. You don't want to always throttle your torrent client to leave Plex enough bandwidth. And if you don't, your Plex clients miss bandwidth time to time.
This script allows to automatically throttle rTorrent/ruTorrent when Plex Media Server streams to external clients.  
It uses Tautully, which is a monitoring tool for Plex Media Server. It allows to compute great statistics about your Plex server and it is able to trigger script execution on given events. Tautully informs the scripts that a stream is playing with the needed bandwidth and the remaining duration. Servral events are caught to be accurate as possible.   
The script automatically throttle rTorrent for the needed time and bandwidth. It uses SCGI communication, so your rTorrent shall be on your local network for security purpose. 

**Dependencies** 
[rTorrent](https://github.com/rakshasa/rtorrent)  
[ruTorrent](https://github.com/Novik/ruTorrent)  
[Tautully](https://github.com/Tautulli/Tautulli)  
[XMLRPC2SCGI](https://github.com/rakshasa/rtorrent/wiki/RPC-Utility-XMLRPC2SCGI)  
[Plex Media Server](https://www.plex.tv/)  
[Git](https://git-scm.com/)

**Setup**   
This tutorial won't explain how to install git, rTorrent, ruTorrent, Tautully and Plex Media Server. 

If you need to install one or serveral of those depencies, please refer to an external tutorial. That been said, for an easy deployement with Docker containers, you can use the excellent [PlexGuide script](https://plexguide.com/). If you need a VPN encapsulated version of rTorrent/ruTorrent, [rTorrentVPN](https://github.com/binhex/arch-rtorrentvpn) is for you.

**XMLRPC2SCGI** 
XMLRPC2SCGI is a Ptyhon script allowing to send command to rTorrent deamon through its scgi port. 

First, clone git repository
``` 
cd /tmp
git clone https://github.com/rakshasa/rtorrent-vagrant.git
``` 
Move the script to your favorite location and add rights
``` 
 mv rtorrent-vagrant/scripts/xmlrpc2scgi.py /home/user/scripts/
 chmod 775 /home/user/scripts/xmlrpc2scgi.py
``` 
 Clean unwanted files
``` 
 rm -rf rtorrent-vagrant
``` 

**tautulli_rtorrent_throttler**  
First, clone git repository
``` 
cd 
git clone https://github.com/Blacksad-cat/tautulli_rtorrent_throttler.git
``` 

We need to setup few finds in the script. 
``` 
cd tautulli_rtorrent_throttler
nano tautulli_rtorrent_throttler.sh
``` 
Set xmlrpc2scgi path.
``` 
# Path to xmlrpc2scgi.py script
XMLRPC2SCGI=/home/user/scripts/xmlrpc2scgi.py
``` 
Set IP on which rTorrent is running (not ruTorrent). Likely localhost (127.0.0.1).
Set rTorrent SCGI port. rTorrent default is 5000. If your rTorrent is distant, ensure scgi port is reachable.
``` 
# Rtorrent connexion settings
# You can find your scgi port in your rtorrent.rc file. Default is 5000
RTORRENT_ADR=127.0.0.1
SCGI_PORT=5000
``` 
The white list avoid throttling torrent traffic for IPs in list. For exemple, you don't want to slow down your torrent traffic for local connexion. 
The list is white space separated and allows cibr format. 
``` 
# All IPs in that list won't cause any throttling on plex input connexion
# Usually, you want put your local network in that list
# => Space separated list of networks in cibr or range format
WHITE_LIST="192.168.0.0/24"
``` 
You must tell the script your maximum upload rate, so it can throttle properly your connexion. If you have an unstable bandwidth, you should be conservative and put your lower rate. 
Rate is given in B/s. The exemple shows a 50Mbps max upload.
 From Mbps multiply by 131072
 From kbp multiply by 128
 From kB/s multiply by 1024
 From MB/s multiply by 1048576
 From GB/s you don't need this script :p
``` 
# Max upload speed in B/s (from Mbps x131072)
# This script use this value and apply the amount of bandwidth needed by plex as throttling
MAX_UPLOAD_RATE=6553600
``` 
