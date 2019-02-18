# tautulli_rtorrent_throttler

**Description**

Most of us still use low speed connexions. Having a Plex Media Server and a torrent client in often struggling. You don't want to always throttle your torrent client to leave Plex enough bandwidth. And if you don't, your Plex clients miss bandwidth time to time.
This script allows to automatically throttle rTorrent/ruTorrent when Plex Media Server streams to external clients.
It uses Tautully, which is a monitoring tool for Plex Media Server. It allows to compute great statistics about your Plex server and it is able to trigger script execution on given events.
Tautully informs the scripts that a stream is playing with the needed bandwidth and the remaining duration. Servral events are caught to be accurate as possible. 
The script automatically throttle rTorrent for the needed time and bandwidth. It uses SCGI communication, so your rTorrent shall be on your local network for security purpose. 

**Dependencies**

[rTorrent](https://github.com/rakshasa/rtorrent)  
[ruTorrent](https://github.com/Novik/ruTorrent)  
[Tautully](https://github.com/Tautulli/Tautulli)  
[XMLRPC2SCGI](https://github.com/rakshasa/rtorrent/wiki/RPC-Utility-XMLRPC2SCGI)  
[Plex Media Server](https://www.plex.tv/)

**Setup**

This tutorial won't explain how to install rTorrent, ruTorrent, Tautully and Plex Media Server. 

If you need to install one or serveral of those depencies, please refer to an external tutorial.
That said, for an easy deployement with Docker containers, you can use the excellent [PlexGuide script](https://plexguide.com/)
If you need a VPN encapsulated version of rTorrent/ruTorrent, please refer to [rTorrentVPN](https://github.com/binhex/arch-rtorrentvpn)

