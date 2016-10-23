class xhprof (
  $path = "/vagrant/extensions/xhprof"
) {
  exec { "apt update":
    command => "/usr/bin/apt-get update"
  }
  package { "php5-dev":
    ensure => latest,
  }
  package { "php-pear":
    ensure  => latest,
    require => Package['php5-dev']
  }
  package { "php5-mcrypt":
    ensure  => latest,
    require => Package['php5-dev']
  }
  exec { "enable mcrypt":
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
    command => "php5enmod mcrypt",
    notify => Service["php5-fpm"],
    require => Package["php5-common"],
  }
  exec { "xhprof install":
    command => "pecl install xhprof-beta",
    path    => ["/bin", "/usr/bin"],
    require => Package[ 'php5-cli', 'php5-dev', 'php-pear', 'php5-fpm' ],
    unless  => 'pecl info xhprof',
    notify  => Service['php5-fpm'],
  }
  file { '/etc/php5/fpm/conf.d/xhprof.ini':
    content => template('xhprof/xhprof.ini.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    notify  => Service['php5-fpm'],
    require => Package['php5-fpm']
  }
  package { 'mongodb':
    ensure  => latest
  }
  exec { "enable mongo":
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
    command => "php5enmod mongo",
    notify => Service["php5-fpm"],
    require => Package["php5-common"],
  }
  package { "php5-mongo":
    ensure  => latest,
    notify  => Service["php5-fpm"],
    require => Package["php5-fpm"],
  }
}
