## Set hostname
## Install dependencies for calibre
    hostnamectl set-hostname calibreweb.domain.com
    yum -y install qt5-qtbase qt5-qttools qt5-qtwayland wget python3 nfs-utils

## Add Calibre user
## Create mount point and set to calibre user    
    useradd calibre

    mkdir /mnt/calibre_library
    chown calibre:calibre /mnt/calibre_library

## Add Calibre user to sudoers
##

echo 'calibre   ALL=(ALL)NOPASSWD:/opt/calibre/*' >> /etc/sudoers

## Allow calibre user access to accept SSH using public key
##

    chmod 600 /root/.ssh/
    chmod 700 /root/.ssh/authorized_keys

    mkdir /home/calibre/.ssh/

    cat /root/.ssh/authorized_keys >> /home/calibre/.ssh/authorized_keys
    chmod 700 /home/calibre/.ssh
    chmod 600 /home/calibre/.ssh/authorized_keys

    chown -R calibre:calibre /home/calibre/.ssh/

## Disallow passwords over SSH
## Force only public key auth
## 

    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

## Disable root login over SSH
##
## sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

    systemctl restart sshd.service

## Add and mount NFS mount
## Location of your calibre library .db file
##
    echo 'nas.domain.com:/NAS/ebooks/calibre_library  /mnt/calibre_library    nfs     rw,sync' >> /etc/fstab
    mount -a
## Add firewall entries
## You may wish to add/adjust more entries
    sourceIP='192.168.1.0/24'
    firewall-cmd --zone=public --add-port=8081/tcp
    firewall-cmd --zone=public --add-source=$sourceIP
    firewall-cmd --runtime-to-permanent
    firewall-cmd --reload

## wget and install calibre
## /opt/calibre/
    wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin

## Create file
## Set executable on service file
## Copy text into new file 

    touch /etc/systemd/system/calibre-server.service
    chmod +x /etc/systemd/system/calibre-server.service

echo "
## startup service
[Unit]
Description=calibre content server
After=network.target network-online.target

[Service]
Type=simple
User=calibre
Group=calibre
ExecStart=/opt/calibre/calibre-server /mnt/calibre_library --enable-local-write --port=8081

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/calibre-server.service

## Enable calibre-server.service to launch on reboot
##

    systemctl enable calibre-server.service

## Restart
##
    reboot
