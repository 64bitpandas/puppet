class ocf_jenkins {
  include ocf_ssl
  include ocf::extrapackages

  class { 'ocf_jenkins::jenkins_apt':
    stage => first;
  }

  include proxy

  package { 'jenkins':; }
  service { 'jenkins':
    require => Package['jenkins'];
  }

  augeas { '/etc/default/jenkins':
    context => '/files/etc/default/jenkins',
    changes => [
      'set JAVA_ARGS \'"-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Xmx1024m"\'',
    ],
    require => Package['jenkins'],
    notify  => Service['jenkins'];
  }

  # We set up two separate jenkins user:
  #
  #   - jenkins-slave:
  #         Used for running build jobs with possibly untrusted code.
  #   - jenkins-deploy:
  #         Used for running *trusted* deploy jobs from a user that has access
  #         to the ocfdeploy keytab. This user should NEVER run untrusted code.
  #
  # This is in addition to the `jenkins` user that is configured by the
  # Debian package, which is used for hosting the Jenkins master.
  #
  # Within Jenkins, we configure two "slaves" which are really the same server,
  # but launched by executing the slave.jar binaries as the appropriate users
  # (via sudo). We then set access controls on the jobs so that only trusted
  # jobs run as `jenkins-deploy`.
  #
  # This is a bit complicated, but it allows us both better security (we no
  # longer have to worry that anybody who can get some code built can become
  # ocfdeploy, which is a privileged user account) and protects Jenkins
  # somewhat against bad jobs that might e.g. delete files or crash processes.
  #
  # Of course, in many cases once code builds successfully, we ship it off
  # somewhere where it gets effectively run as root anyway. But this feels a
  # little safer.
  file {
    '/opt/jenkins':
      ensure => directory;

    '/opt/jenkins/launch-slave':
      source => 'puppet:///modules/ocf_jenkins/launch-slave',
      mode   => '0755';

    '/opt/jenkins/slave':
      ensure => directory,
      owner  => jenkins-slave,
      group  => jenkins-slave;

    '/etc/sudoers.d/jenkins-slave':
      content => "jenkins ALL=(jenkins-slave) NOPASSWD: ALL\n";

    '/opt/jenkins/deploy':
      ensure => directory,
      owner  => jenkins-deploy,
      group  => jenkins-deploy;

    '/opt/jenkins/deploy/ocfdeploy.keytab':
      source => 'puppet:///private/ocfdeploy.keytab',
      owner  => root,
      group  => jenkins-deploy,
      mode   => '0640';

    '/etc/sudoers.d/jenkins-deploy':
      content => "jenkins ALL=(jenkins-deploy) NOPASSWD: ALL\n",
      owner   => root,
      group   => root;
  }

  user {
    'jenkins-slave':
      comment => 'OCF Jenkins Slave',
      home    => '/opt/jenkins/slave/',
      groups  => ['sys'],
      shell   => '/bin/bash';

    'jenkins-deploy':
      comment => 'OCF Jenkins Deploy',
      home    => '/opt/jenkins/deploy/',
      groups  => ['sys'],
      shell   => '/bin/bash';
  }
}
