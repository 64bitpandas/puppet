class ocf_stats {
  include ocf_ssl

  class { '::apache':
    default_vhost => false,
    mpm_module    => 'prefork'
  }
  include '::apache::mod::php'

  include apache
  include ocf_stats::labstats
  include ocf_stats::munin
  include ocf_stats::www
}
