# A Chassis extension that installs XHProf and XHGui
class xhprof (
  $config,
  $path = '/vagrant/extensions/xhprof'
) {

	if ! defined( Package["${config[php]}-dev"] ) {
		package { "php${config[php]}-dev":
			ensure  => latest,
			require => Package["php${config[php]}-fpm"]
		}
	}

  exec { 'download xhprof and build it':
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
    command =>
      'curl -L https://github.com/humanmade/xhprof/archive/sampling-interval.zip > /tmp/xhprof.zip && unzip -o /tmp/xhprof.zip -d /tmp && cd /tmp/xhprof-sampling-interval/extension && phpize && ./configure && make && make install',
    require => [ Package['curl'], Package["php${config[php]}-dev"] ],
    unless  => 'php -m | grep xhprof',
  }

	exec { 'move module':
		path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
		command => 'cp /tmp/xhprof-sampling-interval/extension/modules/xhprof.so /usr/lib/php/20151012',
		require => Exec['download xhprof and build it']
	}

	file { [
		"/etc/php/${config[php]}/fpm/conf.d/xhprof.ini",
		"/etc/php/${config[php]}/cli/conf.d/xhprof.ini",
	]:
		ensure  => file,
		content => template('xhprof/xhprof.ini.erb'),
		owner   => 'root',
		group   => 'root',
		mode    => '0644',
		require => [ Package["php${config[php]}-fpm"] ],
		notify  => Service["php${config[php]}-fpm"]
	}
}
