node default {

  class { 'common::groups': stage => first }
  class { 'common::puppet': stage => first }
  class { 'common::rootpw': stage => first }
  case $::hostname {
    hal, pandemic: { }
    default:       { include common::ntp }
  }
  case $::hostname {
    sandstorm: { }
    default:   { include common::postfix }
  }
  include common::autologout
  include common::git
  include common::kerberos
  include common::ldap
  include common::smart
  include common::zabbix
  if $::macAddress {
      include networking
  } else {
    case $::hostname {
      fallingrocks: {
        $bridge = true
        $vlan   = true
      }
      hal, pandemic: {
        $bridge = true
        $vlan   = false
      }
      default: {
        $bridge = false
        $vlan   = false
      }
    }
    class { 'networking':
      ipaddress   => $::ipHostNumber,
      netmask     => '255.255.255.192',
      gateway     => '169.229.172.65',
      bridge      => $bridge,
      vlan        => $vlan,
      domain      => 'ocf.berkeley.edu',
      nameservers => ['169.229.172.66', '128.32.206.12', '128.32.136.9'],
    }
  }

  if $type == 'server' {
    case $::hostname {
      death:     { class { 'common::apt': stage => first, nonfree => true } }
      default:   { class { 'common::apt': stage => first } }
    }
    case $::hostname {
      supernova: { class { 'common::packages': extra => true, login => true } }
      tsunami:   { class { 'common::packages': extra => true, login => true } }
      jaws:      { class { 'common::packages': extra => true, login => true } }
      default:   { class { 'common::packages': } }
    }
    case $::hostname {
      locusts:   { class { 'common::auth': ulogin => [ ['NuclearPoweredKimJongIl', 'ALL' ] ] } }
      printhost: { class { 'common::auth': glogin => 'approve', gsudo => 'ocfstaff' } }
      supernova: { class { 'common::auth': glogin => 'approve' } }
      riot:      { class { 'common::auth': ulogin => [ ['kiosk', 'LOCAL'] ] } }
      tsunami:   { class { 'common::auth': glogin => [ 'ocf', 'sorry' ] } }
      jaws:      { class { 'common::auth': glogin => [ 'ocf', 'sorry' ] } }
      default:   { class { 'common::auth': } }
    }
    include common::ssh
  }

  if $type == 'desktop' {
    class { 'common::apt':  stage => first, nonfree => true, desktop => true }
    case $::hostname {
      eruption:  { class { 'common::auth': glogin => 'approve' } }
      default:   { class { 'common::auth': glogin => 'ocf' } }
    }
    include common::acct
    include common::crondeny
    include common::cups
    if $::lsbdistcodename != 'wheezy' {
      include desktop::acroread
    }
    include desktop::iceweasel
    include desktop::lxpanel
    include desktop::numlockx
    include desktop::packages
    include desktop::pulse
    include desktop::seti
    include desktop::sshfs
    include desktop::suspend
    if $::hostname != 'eruption' {
      include desktop::tmpfs
      include desktop::limits
    }
    include desktop::xsession
  }

}
