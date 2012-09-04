class ocf::common::ldap {

  # LDAP packages
  package { [ 'ldap-utils', 'openssl' ]: }

  file {
    # provide LDAP connection config
    '/etc/ldap/ldap.conf':
      source  => 'puppet:///modules/ocf/common/auth/ldap/ldap.conf',
      require => [ Package['ldap-utils'], File['/etc/ldap/cacert.pem'] ];
    # provide LDAP CA certificate
    '/etc/ldap/cacert.pem':
      source  => 'puppet:///modules/ocf/common/auth/ldap/cacert.pem',
      require => Package['openssl']
  }

}
