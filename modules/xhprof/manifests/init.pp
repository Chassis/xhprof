# A Chassis extension that installs XHProf and XHGui
class xhprof (
  $path = '/vagrant/extensions/xhprof'
) {
  package { 'php5-dev':
    ensure => latest,
  }
  package { 'php-pear':
    ensure  => latest,
    require => Package['php5-dev']
  }
  package { 'php5-mcrypt':
    ensure  => latest,
    require => Package['php5-dev'],
  }
  exec { 'enable mcrypt':
    path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    command => 'php5enmod mcrypt',
    notify  => Service['php5-fpm'],
    require => Package['php5-common'],
    unless  => 'php -m mcrypt'
  }
  exec { 'xhprof install':
    command => 'pecl install xhprof-beta',
    path    => [ '/bin', '/usr/bin' ],
    require => Package[ 'php5-cli', 'php5-dev', 'php-pear', 'php5-fpm' ],
    unless  => 'pecl info xhprof',
    notify  => Service['php5-fpm'],
  }
  file { '/etc/php5/fpm/conf.d/xhprof.ini':
    content => template('xhprof/xhprof.ini.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['php5-fpm'],
    require => Package['php5-fpm']
  }
  package { 'mongodb':
    ensure  => latest
  }
  exec { 'enable mongodb':
    path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    command => 'php5enmod mongodb',
    notify  => Service['php5-fpm'],
    require => Package['php5-common'],
    unless  => 'php -m mcrypt'
  }
  package { 'php5-mongo':
    ensure  => latest,
    notify  => Service['php5-fpm'],
    require => Package['php5-fpm'],
  }
  exec { 'clone xhgui':
    path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    command => 'git clone https://github.com/perftools/xhgui.git /vagrant/extensions/xhprof/xhgui',
    require => Package[ 'git-core' ],
    unless  => 'test -d /vagrant/extensions/xhprof/xhgui'
  }
  exec { 'install composer':
    path        => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
    environment => [ 'COMPOSER_HOME=/usr/bin/composer' ],
    command     => 'curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer',
    require     => [ Package['curl'], Package['php-pear'] ],
    unless      => 'test -f /usr/bin/composer',
  }
  exec { 'install mongo-php-adapter':
    environment => [ 'COMPOSER_HOME=/usr/bin/composer' ],
    path        => [ '/usr/bin/' ],
    command     => 'composer require alcaeus/mongo-php-adapter --ignore-platform-reqs',
    require     => Exec[ 'install composer' ],
    unless      => 'composer show alcaeus/mongo-php-adapter'
  }
  exec { 'install xhgui':
    path    => [ '/usr/bin/' ],
    cwd     => '/vagrant/extensions/xhprof/xhgui/',
    command => [ 'php install.php' ],
    require => [ Exec['clone xhgui'], Exec['install composer'] ],
    unless  => 'test -d /vagrant/extensions/xhprof/xhgui'
  }
  file { '/vagrant/xhgui':
    ensure => link,
    target => '/vagrant/extensions/xhprof/xhgui/webroot',
    notify => Service['nginx']
  }
  file { '/etc/php5/fpm/conf.d/xhgui.ini':
    content => template('xhprof/xhgui.ini.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['php5-fpm'],
    require => Package['php5-fpm']
  }
}
