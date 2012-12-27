class pencil (
  $graphite_host = 'localhost',
  $web_user      = 'apache',
  ) {

  $pencil_gems = [
    #"map",  # !rewrite
    "rack",
    "rack-protection",  # rewrite
    "tilt",
    "sinatra",
    "backports",  # rewrite
    "rack-test",  # rewrite
    "eventmachine",  # rewrite
    "sinatra-contrib",  # rewrite
    "chronic",
    "numerizer",
    "chronic_duration",  # rewrite
    "graphite_graph",  # rewrite
    #"pencil",
  ]

  package { $pencil_gems: provider => 'gem', }

  ## Installing the rewrite branch of pencil
  $gem_build_gems = ['rake','bundler']
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
      require => [Package['rake'],Exec['branch pencil']];

    "install pencil":
      cwd     => "/usr/src/pencil",
      command => "gem install pkg/pencil-0.4.0a.gem",
      creates => "/usr/bin/pencil",
      require => Exec['build pencil'];
  }

  ## End rewrite installation sidebar

  file {
    "/etc/pencil":
      ensure => directory,
      mode   => 755,
      owner  => 'root',
      group  => 'root';

    "/etc/pencil/pencil.yml":
      mode    => 644,
      owner   => "$web_user",
      group   => "$web_user",
      content => template("pencil/etc/pencil/pencil.yml.erb"),
      #require => [Package["pencil"],File['/etc/pencil']];
      require => [File['/etc/pencil']];
  }

}
