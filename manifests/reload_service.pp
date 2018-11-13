class asterisk::reload_service {
  if $asterisk::manage_service {
    exec { '/usr/sbin/asterisk -rx "core reload"':
      refreshonly => true,
      tries       => 2,
      require     => Class['asterisk::service']
    }
  }
}
