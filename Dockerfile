FROM debian:stable-slim

ARG rehlds_version=3.12.0.780
ARG reunion_version=0.1.0.92d
ARG metamod_version=1.3.0.131
ARG amxmodx_version=1.8.2
ARG yapb_version=4.3.734

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -y

RUN apt-get install -y lib32gcc-s1 curl unzip xz-utils

WORKDIR /opt/steam

# Install SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -zxvf - \
 && echo 'force_install_dir hlds' >> hlds_install.txt \
 && echo 'login anonymous' >> hlds_install.txt \
 && echo 'app_set_config 90 mod cstrike' >> hlds_install.txt \
 && echo 'app_update 90' >> hlds_install.txt \
 && echo 'app_update 90' >> hlds_install.txt \
 && echo 'app_update 90 validate' >> hlds_install.txt \
 && echo 'app_update 90 validate' >> hlds_install.txt \
 && echo 'quit' >> hlds_install.txt \
 && ./steamcmd.sh +runscript hlds_install.txt \
 && rm -f hlds_install.txt

# Fix error that steamclient.so is missing
RUN mkdir -p $HOME/.steam \
 && ln -s $(pwd)/linux32 $HOME/.steam/sdk32

# Install reHLDS
RUN curl -sqL "https://github.com/dreamstalker/rehlds/releases/download/${rehlds_version}/rehlds-bin-${rehlds_version}.zip" > rehlds.zip \
 && unzip rehlds.zip -d rehlds \
 && cp -R rehlds/bin/linux32/* hlds/ \
 && rm -rf rehlds.zip rehlds

# Install Metamod-r
RUN curl -sqL "https://github.com/theAsmodai/metamod-r/releases/download/${metamod_version}/metamod-bin-${metamod_version}.zip" > metamod.zip \
 && unzip metamod.zip addons/metamod/{config.ini,metamod_i386.so} -d hlds/cstrike \
 && sed -i 's/"dlls\/cs.so"/"addons\/metamod\/metamod_i386\.so"/g' hlds/cstrike/liblist.gam \
 && rm -f metamod.zip

# Install Reunion
RUN curl -sqL "https://dl.rehlds.ru/metamod/Reunion/reunion_${reunion_version}.zip" > reunion.zip \
 && unzip reunion.zip -d reunion \
 && mkdir -p hlds/cstrike/addons/reunion \
 && cp reunion/bin/Linux/reunion_mm_i386.so hlds/cstrike/addons/reunion/ \
 && cp reunion/reunion.cfg hlds/cstrike/ \
 && echo 'linux addons/reunion/dlls/reunion_mm_i386.so' >> hlds/cstrike/addons/metamod/plugins.ini \
 && rm -rf reunion.zip reunion

# Install Amxmodx
RUN curl -sqL "https://www.amxmodx.org/release/amxmodx-${amxmodx_version}-base-linux.tar.gz" | tar -C hlds/cstrike -zxvf - \
 && curl -sqL "https://www.amxmodx.org/release/amxmodx-${amxmodx_version}-cstrike-linux.tar.gz" | tar -C hlds/cstrike -zxvf - \
 && echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' >> hlds/cstrike/addons/metamod/plugins.ini

# Install YAPB
RUN curl -sqL "https://github.com/yapb/yapb/releases/download/${yapb_version}/yapb-${yapb_version}-linux.tar.xz" | tar -C hlds/cstrike -Jxvf - \
 && echo 'linux addons/yapb/bin/yapb.so' >> hlds/cstrike/addons/metamod/plugins.ini

# Install SAMBA
RUN apt-get install -y samba \
 && echo '[hlds]' >> /etc/samba/smb.conf \
 && echo '   comment = HLDS Folder' >> /etc/samba/smb.conf \
 && echo '   force create mode = 0660' >> /etc/samba/smb.conf \
 && echo '   force directory mode = 0660' >> /etc/samba/smb.conf \
 && echo '   inherit permissions = yes' >> /etc/samba/smb.conf \
 && echo '   path = /opt/steam/hlds' >> /etc/samba/smb.conf \
 && echo '   read only = no' >> /etc/samba/smb.conf \
 && echo '   browseable = yes' >> /etc/samba/smb.conf \
 && echo '   valid users = steam' >> /etc/samba/smb.conf

RUN apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

COPY startup.sh startup.sh

RUN useradd -r -m -U steam
RUN chown -R steam:steam startup.sh /opt/steam 
RUN chmod o+x startup.sh

EXPOSE 27015/udp
EXPOSE 137-139
EXPOSE 445

ENTRYPOINT ["/opt/steam/startup.sh"]
