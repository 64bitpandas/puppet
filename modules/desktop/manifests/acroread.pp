class desktop::acroread {

  package {
    'acroread':
    ;
    # required dependency
    'ia32-libs-gtk':
    ;
  }

  # hide EULA
  file { '/usr/lib/Adobe/Reader9/Reader/GlobalPrefs/reader_prefs':
    source => 'puppet:///modules/desktop/acroread_prefs',
  }

}
