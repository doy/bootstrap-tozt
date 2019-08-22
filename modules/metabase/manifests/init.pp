class metabase {
  include postgres
  include systemd

  $metabase_version = "v0.33.0"

  package { "jre-openjdk-headless":
    ensure => installed;
  }

  group { "metabase":
    ensure => present;
  }

  user { "metabase":
    ensure => present,
    gid => "metabase",
    system => true,
    require => Group["metabase"];
  }

  file {
    "/opt/metabase":
      ensure => directory;
    "/opt/metabase/run":
      ensure => directory;
    "/usr/lib/systemd/system/metabase.service":
      source => "puppet:///modules/metabase/metabase.service",
      notify => Exec["/usr/bin/systemctl daemon-reload"];
  }

  exec { "download metabase":
    provider => shell,
    command => "curl -LO http://downloads.metabase.com/${metabase_version}/metabase.jar",
    cwd => "/opt/metabase",
    creates => "/opt/metabase/metabase.jar",
    require => File["/opt/metabase"];
  }

  exec { "create metabase db user":
    provider => shell,
    command => "createuser -d metabase",
    user => 'postgres',
    unless => "psql -Atc 'select usename from pg_catalog.pg_user' | grep -F metabase",
    require => [
      Package["postgresql"],
      Service["postgresql"],
    ];
  }

  exec { "create metabase db":
    provider => shell,
    command => "createdb -U metabase metabase",
    user => 'postgres',
    unless => "psql -Atc 'select datname from pg_catalog.pg_database' | grep -F metabase",
    require => [
      Exec["create metabase db user"],
      Package["postgresql"],
      Service["postgresql"],
    ];
  }

  service { "metabase":
    ensure => running,
    require => [
      Package["jre-openjdk-headless"],
      File["/usr/lib/systemd/system/metabase.service"],
    ];
  }
}