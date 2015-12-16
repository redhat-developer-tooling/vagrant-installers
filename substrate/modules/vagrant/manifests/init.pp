# == Class: vagrant
#
# This downloads Vagrant source, compiles it, and then installs it.
#
class vagrant(
  $autotools_environment = {},
  $embedded_dir,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $revision,
) {
  $extension = $operatingsystem ? {
    'windows' => 'zip',
    default   => 'tar.gz',
  }

  $gem_renamer = path("${file_cache_dir}/vagrant_gem_rename.rb")
  $source_url = "https://github.com/mitchellh/vagrant/archive/v${revision}.${extension}"
  $source_file_path = path("${file_cache_dir}/vagrant-${revision}.${extension}")
  $source_dir_path  = path("${file_cache_dir}/vagrant-${revision}")
  $vagrant_gem_path = path("${source_dir_path}/vagrant.gem")

  if $operatingsystem == 'windows' {
    $extract_command   = "cmd.exe /C exit /B 0"
    $gem_command       = "${embedded_dir}\\bin\\gem.bat"
    $install__bundler_command = "cmd.exe /C ${gem_command} install bundler -v 1.10.5"
    $gem_build_command = "cmd.exe /C ${gem_command} build vagrant.gemspec"
    $ruby_command      = "cmd.exe /C ${embedded_dir}\\bin\\ruby.exe"
    $bundle_command    = "${embedded_dir}\\bin\\bundle"
    $rake_command      = "${embedded_dir}\\bin\\rake"
    $bundle_install_command = "${ruby_command} ${bundle_command} install"
    $rake_install_command = "${ruby_command} ${rake_command} install"
    $git_path          = path("${file_cache_dir}/PortableGit/bin")
    $cmd_path          = "C:\\Windows\\System32"
    $windows_path      = "${git_path};${cmd_path};${embedded_dir}\\bin;"
  } else {
    $extract_command   = "tar xvzf ${source_file_path}"
    $gem_command       = "${embedded_dir}/bin/gem"
    $gem_build_command = "${gem_command} build vagrant.gemspec"
    $ruby_command      = "${embedded_dir}/bin/ruby"
  }

  $extra_environment = {
    "GEM_HOME" => "${embedded_dir}/gems",
    "GEM_PATH" => "${embedded_dir}/gems",
  }

  $merged_environment = autotools_merge_environments(
    $autotools_environment, $extra_environment)

  #------------------------------------------------------------------
  # Resetter
  #------------------------------------------------------------------
  # Users outside this class should notify this resource if they want
  # to force a recompile of Vagrant.
  exec { "reset-vagrant":
    command     => "rm -rf ${source_dir_path}",
    refreshonly => true,
    before      => Exec["extract-vagrant"],
  }

  #------------------------------------------------------------------
  # Download and Compile Vagrant
  #------------------------------------------------------------------
  download { "vagrant":
    source         => $source_url,
    destination    => $source_file_path,
    file_cache_dir => $file_cache_dir
  }

  if $operatingsystem == 'windows' {
    # Unzip things on Windows
    powershell { "extract-vagrant":
      content => template("vagrant/windows_extract.erb"),
      creates => $source_dir_path,
      file_cache_dir => $file_cache_dir,
      require => Download["vagrant"],
      before  => Exec["extract-vagrant"],
    }
  }

  exec { "extract-vagrant":
    command => $extract_command,
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Download["vagrant"],
  }

  exec { "gem-install-bundler":
    command => $install__bundler_command,
    cwd     => $source_dir_path,
    require => Exec["extract-vagrant"],
  }

  exec { "bundle-install":
    command => $bundle_install_command,
    cwd     => $source_dir_path,
    path    => $windows_path,
    require => Exec["gem-install-bundler"],
  }

  exec { "rake-install":
    command => $rake_install_command,
    cwd     => $source_dir_path,
    path    => $windows_path,
    require => Exec["bundle-install"],
  }
}
