define duplicati::backup($content) {
  include duplicati

  file { "/etc/duplicati/$name.json":
    content => $content,
    require => File['/etc/duplicati'];
  }

  exec { "load backup for $name":
    provider => shell,
    command => "
      duplicati-client login
      duplicati-client create backup /etc/duplicati/$name.json
      duplicati-client logout
    ",
    unless => "duplicati-client list backups | grep -qF '- $name:'",
    require => [
      Class['duplicati'],
      File["/etc/duplicati/$name.json"],
    ];
  }
}
