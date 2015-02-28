#!/bin/bash
#install vdr and compile dvbapi plugin
if [ "$target" = "host" ] && [ "$live_tv" = "true" ]
	then
		add-apt-repository -y ppa:aap/vdr
		apt-get update
		apt-get upgrade -y
		apt-get install -y vdr vdr-dev vdr-plugin-streamdev-server vdr-plugin-dvbapi w-scan git-core pkg-config libtool tsdecrypt libdvbcsa-dev libdvbcsa1 libusb-1.0-0 libusb-1.0-0-dev openssl libssl-dev libncurses5-dev subversion cmake	
		apt-get build-dep -y vdr
		cd $install/src/
		git clone git://projects.vdr-developer.org/vdr.git
		cd $install/src/vdr/PLUGINS/src
		git clone https://github.com/FernetMenta/vdr-plugin-vnsiserver
		ln -s vdr-plugin-vnsiserver vnsiserver
		cd $install/src/vdr
		make -j2
		make install
		vnsiversion=$(ls /usr/local/lib/vdr/ | grep vnsi | grep 2.* | awk '{gsub("libvdr-vnsiserver.so.", "");print}')
		ln -s /usr/local/lib/vdr/libvdr-vnsiserver.so.$vnsiversion /usr/lib/vdr/plugins/libvdr-vnsiserver5.so.$vnsiversion
fi

useradd vdr
usermod -a -G video vdr
apt-get install -y build-essential libjpeg62-dev libcap-dev libfontconfig1-dev gettext libncursesw5-dev libncurses5-dev
apt-get build-dep -y vdr
cd /$install/src
#get vdr source
git clone git://projects.vdr-developer.org/vdr.git
cd /$install/src/vdr/PLUGINS/src
#get plugin sources (streamdev, vnsi, xvdr, dvbapi, epgsync, svdrpservice)
git clone git://projects.vdr-developer.org/vdr-plugin-streamdev.git
git clone https://github.com/FernetMenta/vdr-plugin-vnsiserver
git clone https://github.com/pipelka/vdr-plugin-xvdr.git
git clone https://github.com/manio/vdr-plugin-dvbapi.git
wget http://vdr.schmirler.de/epgsync/vdr-epgsync-1.0.1.tgz
wget http://vdr.schmirler.de/svdrpservice/vdr-svdrpservice-1.0.0.tgz
tar -xzf vdr-epgsync-1.0.1.tgz
tar -xzf vdr-svdrpservice-1.0.0.tgz
rm *.tgz
ln -s vdr-plugin-streamdev streamdev
ln -s vdr-plugin-vnsiserver vnsiserver
ln -s vdr-plugin-xvdr xvdr
ln -s vdr-plugin-dvbapi dvbapi
ln -s vdr-epgsync-1.0.1 epgsync
ln -s svdrpservice-1.0.0 svdrpservice
cd ../../
make -j2 && make install
#link plugins?
#####
sudo cp runvdr.template /usr/local/bin/runvdr
#autostart script
cat > /etc/init/vdr.conf << vdrconf
description "vdr"
start on (local-filesystems
     and net-device-up IFACE=lo
   and dvb-ready)

stop on runlevel [!2345]
nice -1

pre-start script
  while [ ! -e /dev/dvb/adapter0/frontend0 ]
  do
    sleep 1
  done
end script

script
  su -c /usr/local/bin/runvdr vdr > /var/log/vdr.log 2>&1
end script
vdrconf
#udev rule for dvb-card detection
cat > /etc/udev/rules.d/85-vdr.rules << dvbdetection
#DVB
SUBSYSTEM=="dvb" , KERNEL=="dvb0.frontend0", ACTION=="add", RUN+="/sbin/initctl --quiet emit --no-wait dvb-ready"
dvbdetection
#copy configs
cp svdrphosts.conf /etc/vdr
cp diseqc.conf /etc/vdr
cp sources.conf /etc/vdr
