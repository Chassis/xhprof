# A Chassis extension that installs XHProf and XHGui
class xhprof (
  $config,
  $path = '/vagrant/extensions/xhprof',
  $php_version  = $config[php],
) {
	if ( ! empty( $config[disabled_extensions] ) and 'chassis/xhprof' in $config[disabled_extensions] ) {
		$package = absent
		$file = absent
	} else {
		$package = latest
		$file = file
	}

	if ! defined( Package["php${config[php]}-dev"] ) {
		package { "php${config[php]}-dev":
			ensure  => $package,
			require => Package["php${config[php]}-fpm"]
		}
	}

	file { [
		"/etc/php/${config[php]}/fpm/conf.d/xhprof.ini",
		"/etc/php/${config[php]}/cli/conf.d/xhprof.ini",
	]:
		ensure  => $file,
		content => template('xhprof/xhprof.ini.erb'),
		owner   => 'root',
		group   => 'root',
		mode    => '0644',
		require => [ Package["php${config[php]}-fpm"] ],
		notify  => Service["php${config[php]}-fpm"]
	}

	file { [
		"/etc/php/${config[php]}/fpm/conf.d/xhgui.ini",
		"/etc/php/${config[php]}/cli/conf.d/xhgui.ini",
	]:
		ensure  => $file,
		content => template('xhprof/xhgui.ini.erb'),
		owner   => 'root',
		group   => 'root',
		mode    => '0644',
		require => [ Package["php${config[php]}-fpm"] ],
		notify  => Service["php${config[php]}-fpm"]
	}

	if ( latest == $package ) {
		exec { 'download xhprof and build it':
			path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
			command =>
				'curl -L https://github.com/humanmade/xhprof/archive/sampling-interval.zip > /tmp/xhprof.zip && unzip -o /tmp/xhprof.zip -d /tmp && cd /tmp/xhprof-sampling-interval/extension && phpize && ./configure && make && make install'
			,
			require => [ Package['curl'], Package["php${config[php]}-dev"] ],
			unless  => 'php -m | grep xhprof',
		}

		exec { 'move module':
			path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
			command =>
				'cp /tmp/xhprof-sampling-interval/extension/modules/xhprof.so /usr/lib/php/20151012'
			,
			require => Exec['download xhprof and build it'],
			unless  => 'test -f /usr/lib/php/20151012/xhprof.so'
		}
	} else {
		file { [
			'/usr/lib/php/20151012/xhprof.so',
			'/tmp/xhprof.zip',
			'/tmp/xhprof-sampling-interval'
			]:
			ensure  => $file,
			recurse => true,
			force   => true
		}
	}

	exec { 'install xhgui':
		path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
		cwd => '/vagrant/extensions/xhprof/xhgui/',
		command => 'php install.php',
		require => [ Package["php$php_version-cli"], Package["php$php_version-fpm"] ],
		environment => ['HOME=/home/vagrant']
	}

	package { "php$php_version-mongodb":
		ensure  => $package,
		notify  => Service["php$php_version-fpm"]
	}

	package { 'mongodb':
		ensure  => $package,
	}

}
