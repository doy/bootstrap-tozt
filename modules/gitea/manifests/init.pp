class gitea {
  package { "gitea":
    ensure => installed;
  }

  user { "gitea":
    home => '/media/persistent/gitea',
    require => Package["gitea"];
  }

  service { "gitea":
    ensure => running,
    enable => true,
    subscribe => [
      Systemd::Override['gitea'],
      File['/media/persistent/gitea/custom/conf/app.ini'],
    ],
    require => Package['gitea'];
  }

  $secret_key = secret::value('gitea_secret_key')
  $smtp_password = secret::value('gitea_smtp_password')

  $gitea_username = secret::value('gitea_username')
  $gitea_password = secret::value('gitea_password')
  $gitea_email = secret::value('gitea_email')

  $github_username = secret::value('github_username')
  $github_password = secret::value('github_password')
  $github_api_token = secret::value('github_api_token')
  $github_oauth_key = secret::value('github_oauth_key')
  $github_oauth_secret = secret::value('github_oauth_secret')

  file {
    '/media/persistent/gitea':
      ensure => directory,
      owner => 'gitea',
      group => 'gitea';
    '/media/persistent/gitea/custom':
      ensure => directory,
      owner => 'gitea',
      group => 'gitea',
      require => [
        Package['gitea'],
        File['/media/persistent/gitea'],
      ];
    '/media/persistent/gitea/custom/conf':
      ensure => directory,
      owner => 'gitea',
      group => 'gitea',
      require => [
        Package['gitea'],
        File['/media/persistent/gitea/custom'],
      ];
    '/media/persistent/gitea/custom/conf/app.ini':
      content => template('gitea/app.ini'),
      owner => 'gitea',
      group => 'gitea',
      require => File['/media/persistent/gitea/custom/conf'];
    '/usr/local/bin/github2gitea':
      content => template('gitea/github2gitea'),
      mode => "0755";
    '/usr/local/bin/setup-gitea':
      content => template('gitea/setup-gitea'),
      mode => "0755";
  }

  systemd::override { "gitea":
    source => 'puppet:///modules/gitea/override.conf';
  }

  exec { "initialize gitea":
    provider => shell,
    command => 'su -p gitea /usr/local/bin/setup-gitea && systemctl restart gitea && /usr/local/bin/github2gitea',
    timeout => 3600,
    environment => [
      'USER=gitea',
      'HOME=/media/persistent/gitea',
      'GITEA_WORK_DIR=/media/persistent/gitea',
    ],
    onlyif => '
      test ! -s /media/persistent/gitea/gitea.sqlite || \
      test `sqlite3 /media/persistent/gitea/gitea.sqlite "select count(*) from user"` -eq 0
    ',
    require => [
      File['/usr/local/bin/setup-gitea'],
      File['/usr/local/bin/github2gitea'],
      Package['gitea'],
      Service['gitea'],
    ]
  }
}
