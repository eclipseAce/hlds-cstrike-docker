#!/bin/bash
  
/etc/init.d/smbd start

su - steam && cd /opt/steam/hlds && ./hlds_run -game cstrike "$@"
