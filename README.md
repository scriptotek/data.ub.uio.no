
## Init

    git submodule init
    git submodule sync

## Local development with Vagrant

    vagrant up
    vagrant plugin install vagrant-vbguest
    vagrant vbguest --do install


* Note: We can't set selinux security context for shared folders (see https://github.com/mitchellh/vagrant/issues/6970), so we need to the set permissive mode: `setenforce permissive` (or edit `/etc/selinux/config`). On the production server
we will have enforcing mode.

* Note: `sendfile()` is not reliable with Vagrant shared folders. Therefore, set `EnableSendfile off` in apache conf. Ref: https://coderwall.com/p/ztskha/vagrant-apache-nginx-serving-outdated-static-files-turn-off-sendfile

    cd /opt/data.ub/docker
    docker-compose up -d

    cd /opt/data.ub

    git clone git@github.com:realfagstermer/mrtermer.git \
    && cd mrtermer \
    && sudo pip install -r requirements.txt \
    && cd ..

    git clone git@github.com:realfagstermer/realfagstermer.git \
    && cd realfagstermer \
    && sudo pip install -r requirements.txt \
    && cd ..

## Production: Centos 7 with SELinux

Follow the instructions on
https://docs.docker.com/install/linux/docker-ce/centos/
to install `docker-ce` and `docker-ce-selinux`.

    systemctl enable docker.service
    groupadd docker
    usermod -aG docker ${USER}
    systemctl start docker

    groupadd utv
    usermod -a -G utv ubo-bot

    mkdir /opt/data.ub
    chown -R ubo-bot:utv /opt/data.ub

    git clone git@github.com:scriptotek/data.ub.uio.no.git /opt/data.ub
    chown -R ubo-bot:utv /opt/data.ub

    cd /opt/data.ub
    git checkout v2

Copy `dynmotd` to `/usr/local/bin/dymotd` and add ` /usr/local/bin/dymotd`
at end of `/etc/profile`.

Log out and in again to refresh group membership.

    docker version

SELinux

    chcon -Rv --type=httpd_sys_content_t /opt/data.ub/www
    setsebool -P httpd_can_network_connect 1

Do:

  * Clone all the vocabularies into `/data/vocabs`
  * Change default umask from 022 to 002 for all users in `/etc/profile`
  * Configure tmp folder to be cleaned more often through `/usr/lib/tmpfiles.d/tmp.conf`: The default on Redhat 7 is 10d for `/tmp` and 30d for `/var/tmp`. We reduce both to `2d`.

```
$ cat /usr/lib/tmpfiles.d/tmp.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# See tmpfiles.d(5) for details

# Clear tmp directories separately, to make them easier to override
v /tmp 1777 root root 1d
v /var/tmp 1777 root root 1d

# Exclude namespace mountpoints created with PrivateTmp=yes
x /tmp/systemd-private-%b-*
X /tmp/systemd-private-%b-*/tmp
x /var/tmp/systemd-private-%b-*
X /var/tmp/systemd-private-%b-*/tmp
````

### Adding a bot user for updating data

    sudo su
    useradd --create-home -s /sbin/nologin ubo-bot

    cd /home/ubo-bot/
    mkdir .ssh && cd .ssh
    KEYNAME=ubo-bot-github
    ssh-keygen -t rsa -f id_rsa.$KEYNAME -C "$KEYNAME key for ubprod01-uxl"
    KEYNAME=ubo-bot-utvuio
    ssh-keygen -t rsa -f id_rsa.$KEYNAME -C "$KEYNAME key for ubprod01-uxl"

    cat > config <<EOF
    Host github.com
        User git
        IdentityFile ~/.ssh/id_rsa.ubo-bot-github

    Host bitbucket.usit.uio.no
        User dmheggo
        IdentityFile ~/.ssh/id_rsa.ubo-bot-utvuio
    EOF

    cd ..

    cat > .gitconfig <<EOF
    [user]
        name = ubo-bot
        email = danmichaelo+ubobot@gmail.com
    [push]
        default = simple
    EOF

    chown -R ubo-bot:ubo-bot .

Add SetGID bit

    chown -R ubo-bot:utv /data
    chgrp -R utv /data
    chmod -R u+rwX,g+rwX,o+rX /data
    find /data -type d -exec chmod g+s {} \;


    chown -R ubo-bot:utv /opt/data.ub
    chgrp -R utv /opt/data.ub
    chmod -R u+rwX,g+rwX,o+rX /opt/data.ub
    find /opt/data.ub -type d -exec chmod g+s {} \;


Crontab: Load from file:

    crontab crontab

    /etc/crontab :

    15 * * * * ubo-bot cd /data/vocabs/realfagstermer && doit fuseki publish-dumps

### Starting services

    cd /opt/data.ub/docker
    docker-compose up -d

Use `docker-compose ps` to check status. Restart policies are assigned, so
the containers should restart automatically on crashes or reboots.
