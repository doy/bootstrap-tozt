class tick::server::kapacitor {
  package::makepkg { 'kapacitor-bin':
    ensure => installed;
  }

  $smtp_password = secret::value('kapacitor_smtp_password')
  $smtp_to = secret::value('kapacitor_to')

  file {
    "/etc/kapacitor/kapacitor.conf":
      content => template('tick/kapacitor.conf'),
      require => Package::Makepkg['kapacitor-bin'],
      notify => Service['kapacitor'];
    "/etc/kapacitor/load":
      ensure => directory,
      require => Package::Makepkg['kapacitor-bin'];
    "/etc/kapacitor/load/tasks":
      ensure => directory,
      recurse => true,
      purge => true,
      require => File["/etc/kapacitor/load"];
    "/media/persistent/kapacitor":
      ensure => directory,
      owner => "kapacitor",
      group => "kapacitor",
      require => Package::Makepkg['kapacitor-bin'];
  }

  service { 'kapacitor':
    ensure => running,
    enable => true,
    require => Package::Makepkg['kapacitor-bin'];
  }
}