class ocf_mesos::master::load_balancer {
  include ocf::packages::docker

  ocf::systemd::service { 'ocf-lb':
    ensure  => running,
    source  => 'puppet:///modules/ocf_mesos/master/ocf-lb.service',
    enable  => true,
    require => Package['docker.io'],
  }
}
