class vagrant_substrate::staging::windows {
  include vagrant_substrate

  $cache_dir         = $vagrant_substrate::cache_dir
  $embedded_dir      = $vagrant_substrate::embedded_dir
  $staging_dir       = $vagrant_substrate::staging_dir
  $installer_version = $vagrant_substrate::installer_version

  #------------------------------------------------------------------
  # Extra directories
  #------------------------------------------------------------------
  # For GnuForWin32 stuff
  $gnuwin32_dir = "${embedded_dir}\\gnuwin32"
  util::recursive_directory { $gnuwin32_dir: }

  #------------------------------------------------------------------
  # Dependencies
  #------------------------------------------------------------------
  class { "atlas_upload_cli":
    install_path => "${embedded_dir}\\bin\\atlas-upload",
  }

  class { "curl":
    file_cache_dir => $cache_dir,
    install_dir    => "${embedded_dir}\\bin",
  }

  class { "ruby::windows":
    file_cache_dir => $cache_dir,
    install_dir    => $embedded_dir,
  }

  class { "git::windows":
    file_cache_dir => $cache_dir,
  }

  class { "vagrant":
    embedded_dir   => $embedded_dir,
    file_cache_dir => $cache_dir,
    revision       => "1.7.4",
    require        => [
      Class["ruby::windows"],
      Class["git::windows"],
    ],
  }

  #------------------------------------------------------------------
  # Bin wrappers
  #------------------------------------------------------------------
  # Batch wrapper so that Vagrant can be executed from normal cmd.exe
  file { "${staging_dir}/bin/vagrant.bat":
    content => template("vagrant_substrate/vagrant.bat.erb"),
    require => Class["vagrant"],
  }

  # Normal Bash wrapper for Cygwin installations
  file { "${staging_dir}/bin/vagrant":
    content => template("vagrant_substrate/vagrant.erb"),
    require => Class["vagrant"],
  }
}
