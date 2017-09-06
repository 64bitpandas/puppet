class ocf_desktop::packages {
  include ocf::extrapackages

  # install packages specific to desktops
  #
  # in general, prefer to install packages to ocf::packages so that they are
  # also available on the login and web servers; this is helpful to users, and
  # avoids surprises
  #
  # this list should be used only for packages that don't make sense on a
  # server (such as gimp)
  package {
    # applications
    ['arandr', 'atom', 'claws-mail', 'eog', 'evince-gtk', 'filezilla', 'florence',
      'freeplane', 'galculator', 'geany', 'gimp', 'gparted', 'hexchat', 'inkscape',
      'lyx', 'mssh', 'mumble', 'numlockx', 'simple-scan', 'texmaker',
      'texstudio', 'vlc', 'xarchiver', 'xterm', 'zenmap']:;
    # desktop
    ['desktop-base', 'anacron', 'accountsservice', 'desktop-file-utils', 'redshift',
      'xfce4-whiskermenu-plugin']:;
    # display manager
    ['lightdm', 'lightdm-gtk-greeter', 'libpam-trimspaces']:;
    # fonts
    ['cm-super', 'fonts-croscore', 'fonts-crosextra-caladea', 'fonts-crosextra-carlito',
      'fonts-inconsolata', 'fonts-linuxlibertine', 'fonts-noto-unhinted', 'fonts-unfonts-core',
      'ttf-ancient-fonts']:;
    # FUSE
    ['fuse', 'exfat-fuse']:;
    # games
    ['armagetronad', 'gl-117', 'gnome-games', 'wesnoth', 'wesnoth-music']:;
    # graphics/plotting
    ['r-cran-rgl', 'jupyter-qtconsole']:;
    # input method editors
    ['fcitx', 'fcitx-libpinyin', 'fcitx-rime', 'fcitx-hangul', 'fcitx-mozc']:;
    # nonfree packages
    ['firmware-linux', 'ttf-mscorefonts-installer', 'nvidia-smi']:;
    # notifications
    ['libnotify-bin', 'notification-daemon']:;
    # performance improvements
    ['preload']:;
    # user requested
    ['imagej']:;
    # Xorg
    ['xserver-xorg', 'xclip', 'xscreensaver']:;
  }

  # TODO: temporary code for removing unstable packages, remove
  package {
    ['firefox', 'gcc-5-base', 'libevent-2.1-6', 'libhunspell-1.6-0', 'libmysqlclient20',
      'libreadline6', 'libvirglrenderer0']:
      ensure => purged,
  }
  ['libfontconfig1', 'libfontconfig1-dev', 'fontconfig-config', 'libnss3'].each |$pkg| {
    exec {
      "/usr/bin/apt-get -y --allow-downgrades -o Dpkg::Options::=--force-confold install ${pkg}/stretch":
        unless  => "/usr/bin/apt-cache policy ${pkg} | grep -A1 \\* | grep -w stretch",
    }
  }
  file {
    '/etc/fonts/conf.d/10-hinting-slight.conf':
      ensure => absent,
  }

  # Packages that only work on jessie
  if $::lsbdistcodename == 'jessie' {
    package {
      [
        'readahead-fedora',
      ]:;
    }
  }

  # Install rstudio, custom built to work with libssl1.0.2 and run on stretch.
  # TODO: Remove libgstreamer0.10-0 and libgstreamer-plugins-base0.10-0 once
  # rstudio is packaged officially for stretch. These two packages are installed
  # from our apt repo (ported from jessie) and are dependencies of rstudio until
  # rstudio updates to libgstreamer1.0-0 and libgstreamer-plugins-base1.0-0.
  package { 'rstudio':; }

  # TODO: install remmina from backports when that becomes available

  # remove some packages
  package {
    # causes gid conflicts
    'sane-utils':
      ensure  => purged;
    # xpdf takes over as default sometimes
    'xpdf':
      ensure  => purged;
  }

  # install packages without recommends
  ocf::repackage {
    'brasero':
      recommends => false;
    'fcitx-table-wubi':
      recommends => false;
    'gedit':
      recommends => false;
    ['libreoffice-calc', 'libreoffice-draw', 'libreoffice-gnome', 'libreoffice-impress', 'libreoffice-pdfimport', 'libreoffice-writer', 'ure']:
      recommends => false;
    'thunar':
      recommends => false;
    ['virt-manager', 'virt-viewer']:
      recommends => false;
  }
}
