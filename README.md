# tautulli_rtorrent_throttler
Most of us still use low speed connexions. Having a Plex Media Server and a torrent client in often struggling. You don't want to always throttle your torrent client to leave Plex enough bandwidth. And if you don't, your Plex clients miss bandwidth time to time.
This script allows to automatically throttle rTorrent/ruTorrent when Plex Media Server streams to external clients.
It uses Tautully, which is a monitoring tool for Plex Media Server. It allows to compute great statistics about your Plex server and it is able to trigger script execution on given events.
Tautully informs the scripts that a stream is playing with the needed bandwidth and the remaining duration. Servral events are caught to be accurate as possible. 
The script automatically throttle rTorrent for the needed time and bandwidth. It uses SCGI communication, so your rTorrent shall be on your local network for security purpose. 

# Dependencies
