# == Class: ruby::windows
#
# This installs Ruby on Windows.
#
class ruby::windows(
  $install_dir = undef,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  $devkit_source_url = "http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe"
  $devkit_installer_path = "${file_cache_dir}\\devkit-4.7.2-64.exe"
  $ruby_source_url = "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p645.exe?direct"
  $ruby_installer_path = "${file_cache_dir}\\ruby-2.0.0-p645.exe"

  $extra_args = $install_dir ? {
    undef   => "",
    default => " /dir=\"${install_dir}\"",
  }

  #------------------------------------------------------------------
  # Ruby
  #------------------------------------------------------------------
  download { "ruby":
    source         => $ruby_source_url,
    destination    => $ruby_installer_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "install-ruby":
    command => "cmd.exe /C ${ruby_installer_path} /silent${extra_args}",
    creates => "${install_dir}/bin/ruby.exe",
    require => Download["ruby"],
  }

  # Remove the "DL is deprecated warning"
  # NOTE(mitchellh): REMOVE THIS AT SOME POINT. BE CAREFUL WITH EVERY
  # RUBY VERSION TO CHANGE THIS.
  file { "${install_dir}/lib/ruby/2.0.0/dl.rb":
    source  => "puppet:///modules/ruby/modified_dl.rb",
    require => Exec["install-ruby"],
    owner => "Administrators",
    group => "Administrator",
    mode => 644
  }

  #------------------------------------------------------------------
  # Ruby DevKit
  #------------------------------------------------------------------
  download { "ruby-devkit":
    source      => $devkit_source_url,
    destination => $devkit_installer_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "extract-devkit":
    command => "cmd.exe /C ${devkit_installer_path} -y -o\"${install_dir}\"",
    creates => "${install_dir}/dk.rb",
    require => [
      Download["ruby-devkit"],
      Exec["install-ruby"],
    ],
  }

  file { "${install_dir}/config.yml":
    content => template("ruby/windows/config.yml.erb"),
    require => Exec["extract-devkit"],
    owner => "Administrators",
    group => "Administrator",
    mode => 644
  }

  exec { "install-devkit":
    command => "cmd.exe /C ${install_dir}\\bin\\ruby.exe dk.rb install",
    creates => "${install_dir}/lib/ruby/site_ruby/devkit.rb",
    cwd     => $install_dir,
    require => [
      Exec["extract-devkit"],
      File["${install_dir}/config.yml"],
    ],
  }

  file { "${install_dir}/lib/ruby/site_ruby/devkit.rb":
    backup  => false,
    content => template("ruby/windows/devkit.rb.erb"),
    require => Exec["install-devkit"],
    owner => "Administrators",
    group => "Administrator",
    mode => 644
  }
}
