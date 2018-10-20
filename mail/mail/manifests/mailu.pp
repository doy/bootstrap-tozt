class mail::mailu {
  include docker

  file {
    "/mailu":
      ensure => directory;
    "/mailu/docker-compose.yml":
      content => "puppet:///modules/mail/docker-compose.yml",
      require => File["/mailu"];
    "/mailu/.env.tmpl":
      content => "puppet:///modules/mail/env",
      require => File["/mailu"];
  }

  secret { "/mailu/secret-key":
    source => "mailu-secret-key",
    require => File["/mailu"];
  }

  exec { "create env file with secret":
    provider => shell,
    command => "cat /mailu/.env.tmpl /mailu/secret-key > /mailu/.env",
    creates => "/mailu/.env",
    require => [
      File["/mailu/secret-key"],
      File["/mailu/.env.tmpl"],
    ];
  }
}
