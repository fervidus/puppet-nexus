# === Class: nexus
#
# Install and configure Sonatype Nexus
#
# === Parameters
#
# [*version*]
#   The version to download.
#
# [*revision*]
#   The revision of the archive. This is needed for the name of the
#   directory the archive is extracted to.  The default should suffice.
#
# [*nexus_root*]
#   The root directory where the nexus application will live and tarballs
#   will be downloaded to.
#
# === Examples
#
# class{ 'nexus':
#   var => 'foobar'
# }
#
# === Authors
#
# Tom McLaughlin <tmclaughlin@hubspot.com>
#
# === Copyright
#
# Copyright 2013 Hubspot
#

class nexus (
  String $version,
  String $revision,
  Boolean $deploy_pro,
  String $download_site,
  String $pro_download_site,
  String $type,
  String $nexus_root,
  String $nexus_home_dir,
  Boolean $nexus_work_dir_manage,
  String $nexus_user,
  String $nexus_group,
  String $nexus_host,
  String $nexus_port,
  Boolean $nexus_work_recurse,
  String $nexus_context,
  Boolean $nexus_manage_user,
  String $download_folder,
  Boolean $manage_config,
  Boolean $nexus_selinux_ignore_defaults,
  Optional[String] $nexus_data_folder = undef,
  Optional[String] $nexus_work_dir = undef,
  Optional[String] $md5sum = undef,
) {

  include stdlib

  # Bail if $version is not set.  Hopefully we can one day use 'latest'.
  if ($version == 'latest') or ($version == undef) {
    fail('Cannot set version nexus version to "latest" or leave undefined.')
  }

  if $nexus_work_dir != undef {
    $real_nexus_work_dir = $nexus_work_dir
  } else {
    if $version !~ /\d.*/ or versioncmp($version, '3.1.0') >= 0 {
      $real_nexus_work_dir = "${nexus_root}/sonatype-work/nexus3"
    } else {
      $real_nexus_work_dir = "${nexus_root}/sonatype-work/nexus"
    }
  }

  # Determine if Nexus Pro should be deployed instead of OSS
  validate_bool($deploy_pro)
  if ($deploy_pro) {
      $real_download_site = $pro_download_site
  } else {
    # Deploy OSS version. The default download_site, or whatever is
    # passed in is the correct location to download from
    $real_download_site = $download_site
  }

  if ($nexus_manage_user){
    group { $nexus_group :
      ensure  => present
    }

    user { $nexus_user:
      ensure  => present,
      comment => 'Nexus User',
      gid     => $nexus_group,
      home    => $nexus_root,
      shell   => '/bin/sh',     # required to start application via script.
      system  => true,
      require => Group[$nexus_group]
    }
  }

  class{ 'nexus::package':
    version                       => $version,
    revision                      => $revision,
    deploy_pro                    => $deploy_pro,
    download_site                 => $real_download_site,
    type                          => $type,
    nexus_root                    => $nexus_root,
    nexus_home_dir                => $nexus_home_dir,
    nexus_user                    => $nexus_user,
    nexus_group                   => $nexus_group,
    nexus_work_dir                => $real_nexus_work_dir,
    nexus_work_dir_manage         => $nexus_work_dir_manage,
    nexus_work_recurse            => $nexus_work_recurse,
    nexus_selinux_ignore_defaults => $nexus_selinux_ignore_defaults,
    download_folder               => $download_folder,
    md5sum                        => $md5sum,
    notify                        => Class['nexus::service']
  }

  if $manage_config {
    class{ 'nexus::config':
      nexus_root        => $nexus_root,
      nexus_home_dir    => $nexus_home_dir,
      nexus_host        => $nexus_host,
      nexus_port        => $nexus_port,
      nexus_context     => $nexus_context,
      nexus_work_dir    => $real_nexus_work_dir,
      nexus_data_folder => $nexus_data_folder,
      version           => $version,
      notify            => Class['nexus::service'],
      require           => Anchor['nexus::setup']
    }
  }

  class { 'nexus::service':
    nexus_home  => "${nexus_root}/${nexus_home_dir}",
    nexus_user  => $nexus_user,
    nexus_group => $nexus_group,
    version     => $version,
  }

  anchor { 'nexus::setup': } -> Class['nexus::package'] -> Class['nexus::config'] -> Class['nexus::Service'] -> anchor { 'nexus::done': }

}
