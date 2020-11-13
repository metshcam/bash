####
## Prepare CentOS8 build based on HyperV parent disk
####

hostname='workstation'
domain='domain.com'
username='service_user'
userhomepath='/home/'${username}
## Example installations
installations='httpd tcpdump vim'

## Set hostname
##
    hostnamectl set-hostname ${hostname}'.'${domain}

## Firewall settings
## Adjust for your network environment
## Adds open range of networks
##
    sourceIP='0.0.0.0/24'
    firewall-cmd --zone=public --add-source=${sourceIP}
    
## Set firewall and reload
##
    firewall-cmd --runtime-to-permanent
    firewall-cmd --reload
    
## Add firewall entries
## Allow all
## To-do: work on port range
## Create rich rules
#firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0" port protocol="tcp" port="22" accept'

## Add service User
##  
    useradd ${username}

## Change service user password
## Service user should not use a password
## Removed as service user will use ssh key from host
##
#echo -e "supersecretpassword\nsupersecretpassword" | passwd ${username}

## Install dependencies for service/build
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
## sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

## Restart
##
    reboot
