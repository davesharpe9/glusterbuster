service { 'squid3':
  ensure => running,
  enable => true,
}

package { 'squid3':
  ensure => installed,
}

file { '/etc/squid3/squid.conf':
  ensure  => file,
  source  => '/vagrant/puppet/files/squid.conf', 
  require => Package['squid3'],
  notify  => Service['squid3'],
}

package { 'python-twisted-conch':
  ensure => installed,
}

package { 'screen':
  ensure => installed,
}
