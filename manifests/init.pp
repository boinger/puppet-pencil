class pencil (
  $graphite_url    = 'http://graphite/',
  $pencil_port     = '9292',
  $pencil_conf_dir = "/etc/pencil.d",
  $web_user        = 'apache',
  ) {

  Package { ensure => "installed", }
  File {
    ensure => present,
    mode   => 0644,
    owner  => 'root',
    group  => 'root',
  }

  #$prereqs = []
  #package { $prereqs: require => Package['ruby'], }

  $pencil_gems = [
    "map",  # !rewrite
    "rack",
    "rack-protection",  # rewrite
    "tilt",
    "sinatra",
    "backports",  # rewrite
    "rack-test",  # rewrite
    "sinatra-contrib",  # rewrite
    "chronic",
    "numerizer",
    "chronic_duration",  # rewrite
    "graphite_graph",  # rewrite
  ]

  package { $pencil_gems:
    provider => 'gem',
    require => [Package['ruby'], Package['ruby-devel'], Package['rubygems']]
  }

  ## Installing the rewrite branch of pencil ##

  $gem_build_gems = ['rake']
  package { $gem_build_gems: provider => 'gem', }

  exec {
    "clone pencil":
      cwd     => "/usr/src",
      command => "git clone git://github.com/fetep/pencil.git",
      creates => "/usr/src/pencil",
      require => Package['git'];

    "branch pencil":
      cwd     => "/usr/src/pencil",
      command => "git checkout rewrite",
      creates => "/usr/src/pencil/README-rewrite.md",
      require => Exec['clone pencil'];

    "build pencil":
      cwd     => "/usr/src/pencil",
      command => "rake build",
      creates => "/usr/src/pencil/pkg/pencil-0.4.0a.gem",
      require => [ Package['rake'],Exec['branch pencil'], ];

    "install pencil":
      cwd     => "/usr/src/pencil",
      command => "gem install pkg/pencil-0.4.0a.gem",
      creates => "/usr/bin/pencil",
      require => Exec['build pencil'];

    "restart-pencil":
      command     => "stop pencil; start pencil",
      refreshonly => true,
      require     => [ File['/etc/init/pencil.conf'], Exec['install pencil'], ];

    "reload pencil":
      command     => "/usr/bin/curl localhost:9292/reload",
      refreshonly => true,
      require     => Exec['install pencil'],
      subscribe   => [
        File['/etc/pencil.yml'],
        File['/etc/init/pencil.conf'],
        File[$pencil_conf_dir],
        ];
  }

  ## End rewrite installation bits ##

  file {
    "${pencil_conf_dir}":
      ensure  => directory,
      recurse => true,
      #purge   => true,
      force   => true,
      source  => "puppet:///modules/pencil/${pencil_conf_dir}";

    "/etc/pencil.yml":
      owner   => "$web_user",
      group   => "$web_user",
      content => template("pencil/etc/pencil.yml.erb");

    "/etc/init/pencil.conf":
      source  => "puppet:///modules/pencil/etc/init/pencil.conf",
      require => Exec['install pencil'];
  }

}
