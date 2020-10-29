####
## HyperV:  Create virtual differencing disk, with existing parent drive (centos8)
## Service: steamcmd 
## Game:    Insurgency Sandstorm
## Req:     Windows 10,HyperV,existing virtual switch, openssh
####

hostname='insurgency'
domain='domain.com'
game='insurgency'
gameid='581330'
username='steam'
userhomepath='/home/'${username}
installations='glibc.i686 libstdc++.i686 policycoreutils-python-utils'

## Set hostname
##
    hostnamectl set-hostname ${hostname}'.'${domain}

## Firewall settings
## Insurgency
    sourceIP='0.0.0.0/24'
    firewall-cmd --zone=public --add-source=${sourceIP}
    firewall-cmd --zone=public --add-port=27016/tcp
    firewall-cmd --zone=public --add-port=27102/tcp
    firewall-cmd --zone=public --add-port=27131/tcp
    
## Set firewall and reload    
    firewall-cmd --runtime-to-permanent
    firewall-cmd --reload
    
## Add firewall entries
## Allow all
## To-do: work on port range
## Create rich rules
## todo
    #firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0" port protocol="tcp" port="22" accept'

## Add service User
##  
    useradd ${username}

## Change service user password
## Removed as service user will use ssh key from host
    #echo -e "steam\nsteam" | passwd steam

## Install steamcmd dependencies
##
    yum -y install ${installations}
    
## Set permissions on SSH folder and authorized_keys
##
    chmod 700 /root/.ssh/
    chmod 600 /root/.ssh/authorized_keys

## Create SSH path for new user, and copy host public RSA key (from Copy-VMFile; /root/hyperv/)
## Set proper permissions on new user's SSH folder and file
##
    mkdir -p ${userhomepath}'/.ssh/'
    cat /root/.ssh/authorized_keys >> ${userhomepath}'/.ssh/authorized_keys'
    chmod 700 ${userhomepath}'/.ssh'
    chmod 600 ${userhomepath}'/.ssh/authorized_keys'

## Disallow passwords over SSH
## Force only public key auth
## 
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

## Disable root login over SSH
## Enable this when done testing
##
    #sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

## Restart SSH server
##
    #systemctl restart sshd.service

## Create preconfigured game server settings
## Prepopulate the folder to move files for Insurgency configuration
## e.g.
##  mkdir -p $userhomepath'/steamcmd/'$game'/Insurgency/Saved/Config/LinuxServer/'

    mkdir -p ${userhomepath}'/steamcmd/'${game}/

## Download and extract steamcmd to service user home
##
    curl -o ${userhomepath}'/steamcmd/steamcmd_linux.tar.gz' -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    tar -zxvf ${userhomepath}'/steamcmd/steamcmd_linux.tar.gz' -C ${userhomepath}'/steamcmd/'

## Build the launch and update files for your game server
## Removed: no need to move more files with little text
    #mv '/root/hyperv/insurgency_update.sh' $userhomepath'/steamcmd/insurgency_update'
    #mv '/root/hyperv/insurgency_launch.sh' $userhomepath'/steamcmd/insurgency_launch'

## Build the update file for your game server
## 
echo "
@ShutdownOnFailedCommand 1 //set to 0 if updating multiple servers at once
@NoPromptForPassword 1
login anonymous
force_install_dir ${userhomepath}/steamcmd/${game}/
app_update ${gameid}
quit
" > ${userhomepath}'/steamcmd/'${game}'_update'

## Build the launch file for your game server
##
echo "
${userhomepath}/steamcmd/${game}/Insurgency/Binaries/Linux/InsurgencyServer-Linux-Shipping Farmhouse?Scenario=Scenario_Farmhouse_Checkpoint_Insurgents?Port=27102 -QueryPort=27131 -hostname=InsurgencyServer -GSLTToken=A157871E8478DF94R6939D3RE31BF602 -GameStats
" > $userhomepath'/steamcmd/'${game}'_launch'

## Make files executable
##
    chmod +x ${userhomepath}'/steamcmd/'${game}'_update'
    chmod +x ${userhomepath}'/steamcmd/'${game}'_launch'

## Make sure all the files are owned by the user before running the installer
##
    chown -R ${username}':'${username} ${userhomepath}'/'
    
## Run the steamcmd.sh installer and use the game update file
##    
    runuser -l ${username} -c "${userhomepath}'/steamcmd/steamcmd.sh +runscript ${userhomepath}'/steamcmd/'${game}'_update'"

## Create steamcmd service file
## Use gameid from steam to build server
##
    touch '/etc/systemd/system/steamcmd_'${gameid}'.service'

## Copy game server configuration into new file 
##
echo "
## /etc/systemd/system/steamcmd_${gameid}.service
[Unit]
Description=My steamcmd ${game} Server
After=network.target network-online.target

[Service]
User=${username}
WorkingDirectory=${userhomepath}/steamcmd/

ExecStartPre=${userhomepath}/steamcmd/steamcmd.sh +runscript ${userhomepath}/steamcmd/${game}_update
ExecStart=${userhomepath}/steamcmd/${game}_launch

TimeoutStartSec=infinity
## Restart=always
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
## END OF FILE
" > '/etc/systemd/system/steamcmd_'${gameid}'.service'

## Set executable and permissions on systemd service file
##
    chmod +x '/etc/systemd/system/steamcmd_'${gameid}'.service'
    chmod 0644 '/etc/systemd/system/steamcmd_'${gameid}'.service'

## Disable SELinux
##
    setenforce 0

## Enable steamcmd game service
##
    systemctl enable 'steamcmd_'${gameid}'.service'

## Save SELinux module for service
##
    grep steamcmd /var/log/audit/audit.log | audit2allow -M steamcmd

## Import steamcmd.pp and .te
##
    semodule -i steamcmd.pp

## Enable SELinux
##
    setenforce 1

## Restart
##
    reboot
