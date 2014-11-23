class desktop::packages {
  include common::extrapackages

  package {
    # remove accidentally-installed packages
    ['php5', 'libapache2-mod-php5', 'apache2']:
      ensure => purged;
  }

  file { '/opt/share/puppet/packages':
    ensure  => directory,
    source  => 'puppet:///contrib/desktop/packages',
    recurse => true
  }

  # install patched evince packages (version 3.14.1-1+ocf1) to get around
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=768133
  package {
    'libevdocument3-4':
      ensure   => latest,
      provider => dpkg,
      source   => '/opt/share/puppet/packages/libevdocument3-4_3.14.1-1+ocf1_amd64.deb',
      require  => File['/opt/share/puppet/packages'];
    'libevview3-3':
      ensure   => latest,
      provider => dpkg,
      source   => '/opt/share/puppet/packages/libevview3-3_3.14.1-1+ocf1_amd64.deb',
      require  => File['/opt/share/puppet/packages'];
    'evince-common':
      ensure   => latest,
      provider => dpkg,
      source   => '/opt/share/puppet/packages/evince-common_3.14.1-1+ocf1_all.deb',
      require  => [Package['libevview3-3'], Package['libevdocument3-4']];
    'evince-gtk':
      ensure   => latest,
      provider => dpkg,
      source   => '/opt/share/puppet/packages/evince-gtk_3.14.1-1+ocf1_amd64.deb',
      require  => Package['evince-common'];
  }

  # install packages specific to desktops
  #
  # in general, prefer to install packages to common::packages so that they are
  # also available on the login and web servers; this is helpful to users, and
  # avoids surprises
  #
  # this list should be used only for packages that don't make sense on a
  # server (such as gimp)
  package {
    # applications
    ['claws-mail', 'geany', 'filezilla', 'inkscape', 'mssh', 'numlockx', 'remmina', 'simple-scan', 'vlc', 'zenmap', 'gimp']:;
    # desktop
    ['desktop-base', 'desktop-file-utils', 'gpicview', 'xarchiver', 'xterm', 'lightdm', 'accountsservice']:;
    # fonts
    ['cm-super', 'fonts-inconsolata', 'fonts-liberation', 'fonts-linuxlibertine']:;
    # games
    ['armagetronad', 'gl-117', 'gnome-games', 'wesnoth', 'wesnoth-music']:;
    # useful tools
    ['lyx', 'texmaker']:;
    # nonfree packages
    ['firmware-linux', 'flashplugin-nonfree', 'ttf-mscorefonts-installer']:;
    # notifications
    ['libnotify-bin', 'notification-daemon']:;
    # performance improvements
    ['preload', 'readahead-fedora']:;
    # Xorg
    ['xserver-xorg', 'xscreensaver']:
  }

  # remove some packages
  package {
    # causes gid conflicts
    'sane-utils':
      ensure  => purged;
    # no longer used
    [ 'rusers', 'rusersd' ]:
      ensure  => purged;
    # xpdf takes over as default sometimes
    'xpdf':
      ensure  => purged;
  }

  # install packages without recommends
  ocf::repackage {
    'brasero':
      recommends => false;
    'gedit':
      recommends => false;
    ['libreoffice-calc', 'libreoffice-draw', 'libreoffice-gnome', 'libreoffice-impress', 'libreoffice-writer', 'ure']:
      recommends => false,
      backports  => true;
    'thunar':
      recommends => false;
    ['virt-manager', 'virt-viewer']:
      recommends => false;
  }
}
