#!/bin/bash
#
# Provision script for Vagrant

yum -y update && yum -y install \
  ntp ntpdate ntp-doc \
  gcc \
  gcc-c++ \
  make \
  openssl-devel \
  libxml2-devel \
  libxslt-devel \
  python-devel \
  curl \
  gettext \
  httpd \
  vim \
  git \
  zip \
  python-setuptools

# chkconfig ntpd on
ntpdate no.pool.ntp.org
\cp /usr/share/zoneinfo/UTC /etc/localtime

hash docker 2>/dev/null || {
	# Ref: https://docs.docker.com/engine/installation/linux/rhel/
	echo "Installing docker"

	tee /etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

	yum update && yum install docker-engine
	service docker start

	# curl -fsSL https://get.docker.com/ | sh
	# service docker start

	# Start at boot
	# chkconfig docker on

	# Let the 'vagrant' user use Docker without sudo
	usermod -aG docker vagrant
}

yum repolist 2>/dev/null | grep ius -q || {
	echo "Adding ius community repo"

	\curl -sSL 'https://setup.ius.io/' | bash
}

hash php 2>/dev/null || {
	echo "Installing php56"

	yum install -y php56u php56u-pgsql php56u-mbstring php56u-pdo php56u-gd php56u-ldap \
	    php56u-pecl-imagick php56u-curl php56u-apc
}

test -f /usr/local/bin/docker-compose 2>/dev/null || {
	echo "Installing docker-compose"

	\curl -sSL https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
}

test -f /usr/local/bin/composer 2>/dev/null || {
	echo "Installing composer"

	\curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
	chmod +x /usr/local/bin/composer
}

hash pip 2>/dev/null || {
	echo "Installing pip"

	\curl -sS https://bootstrap.pypa.io/get-pip.py | python
}

# echo "Starting docker-compose"
# cd /opt/data.ub/docker
# docker-compose up -d

# Apache config
# chkconfig httpd on
\cp /opt/data.ub/apache/000-default.conf /etc/httpd/conf.d/000-default.conf
\cp /opt/data.ub/apache/001-fuseki.conf /etc/httpd/conf.d/001-fuseki.conf
\cp /opt/data.ub/apache/002-skosmos.conf /etc/httpd/conf.d/002-skosmos.conf
\cp /opt/data.ub/apache/003-yasqe.conf /etc/httpd/conf.d/003-yasqe.conf
sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/opt/data.ub/www/default"|' /etc/httpd/conf/httpd.conf
sed -i 's|<Directory "/var/www">|<Directory "/opt/data.ub/www">|' /etc/httpd/conf/httpd.conf
sed -i 's|<Directory "/var/www/html">|<Directory "/opt/data.ub/www/default">|' /etc/httpd/conf/httpd.conf

apachectl restart

chown root:vagrant /opt/data.ub
chmod g+w /opt/data.ub
