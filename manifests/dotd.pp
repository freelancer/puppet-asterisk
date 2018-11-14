# Configure the contents of a file and create a corresponding .d configuration
# directory so that puppet can drop files for on-demand configuration snippets.
#
# $additional_paths lets one manage multiple .d directories while managing only
#   one configuration file. This trick is useful if some configuration snippets
#   need to be parsed before others (e.g. registries vs. contexts)
#
# $content is the configuration file contents
#
# $source is a puppet file source. If this is specified, $content will be
#   overridden. So one must not use both parameters at the same time.
#
# $manage_nullfile is a boolean value that decides if a null.conf file is
#   created in each .d directories. This file is necessary in empty .d dirs,
#   since asterisk will refuse to start if some included files do not exist.
#   Default is to create null.conf in all .d directories.
#
define asterisk::dotd (
  $additional_paths = [],
  $content          = '',
  $source           = '',
  $manage_nullfile  = true,
) {
  include asterisk::install
  include asterisk::reload_service

  $dirname = ["${name}.d"]
  $cf_file_name = "${name}.conf"
  $paths = [$dirname, $additional_paths]

  file { $paths :
    ensure  => directory,
    owner   => 'root',
    group   => 'asterisk',
    mode    => '0750',
    require => Class['asterisk::install'],
  }

  if $manage_nullfile {
    # Avoid error messages
    # [Nov 19 16:09:48] ERROR[3364] config.c: *********************************************************
    # [Nov 19 16:09:48] ERROR[3364] config.c: *********** YOU SHOULD REALLY READ THIS ERROR ***********
    # [Nov 19 16:09:48] ERROR[3364] config.c: Future versions of Asterisk will treat a #include of a file that does not exist as an error, and will fail to load that configuration file.  Please ensure that the file '/etc/asterisk/iax.conf.d/*.conf' exists, even if it is empty.
    asterisk::dotd::nullfile{ $paths : }
  }

  file { $cf_file_name :
    ensure  => present,
    owner   => 'root',
    group   => 'asterisk',
    mode    => '0640',
    require => Class['asterisk::install'],
    notify  => Class['asterisk::reload_service'],
  }

  if $content != '' {
    if $source != '' {
      fail('Please define only one of $content and $source')
    }

    File[$cf_file_name] {
      content => $content,
    }
  } else {
    $filename = inline_template('<%= File.basename(cf_file_name) -%>')
    File[$cf_file_name] {
      source => $source ? {
        '' => [ "puppet:///modules/site_asterisk/${filename}.${::fqdn}",
                "puppet:///modules/site_asterisk/${filename}",
                "puppet:///modules/asterisk/${filename}"],
        default => $source,
      },
    }
  }
}
