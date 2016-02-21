class ocf_tv {
  include ocf::packages::chrome

  package {
    [
      'arandr',
      'ffmpeg',
      'flashplugin-nonfree',
      'i3',
      'iceweasel',
      'nodm',
      'pavucontrol',
      'pulseaudio',
      'vlc',
      'x11vnc',
      'xinit',
    ]:;
  }

  user { 'ocftv':
    comment => 'TV NUC',
    home    => '/opt/tv',
    groups  => ['sys', 'audio'],
    shell   => '/bin/bash';
  }

  file {
    # Create home directory for ocftv user
    '/opt/tv':
      ensure  => directory,
      owner   => ocftv,
      group   => ocftv,
      require => User['ocftv'];

    '/etc/X11/xorg.conf':
      source => 'puppet:///modules/ocf_tv/X11/xorg.conf';
  }

  ocf::systemd::service { 'x11vnc':
    source  => 'puppet:///modules/ocf_tv/x11vnc.service',
    require => [
      Package['x11vnc', 'nodm'],
      User['ocftv'],
    ],
  }
}
