#!/bin/bash
if [ "$pyload" = "true" ]
  then
    clear
		echo -e "running initial pyload setup... "
		sudo -u kodi -H /usr/bin/pyLoadCore
fi