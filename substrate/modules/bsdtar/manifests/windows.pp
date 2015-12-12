class bsdtar::windows {
  $file_cache_dir        = $bsdtar::file_cache_dir
  $install_dir           = $bsdtar::install_dir

  $source_file_path = "${file_cache_dir}\\bsdtar.zip"

  file { $source_file_path:
    source => "puppet:///modules/bsdtar/windows.zip",
    owner => "Administrators",
    group => "Administrator",
    mode => 644
  }

  powershell { "extract-bsdtar":
    content        => template("bsdtar/extract.erb"),
    creates        => "${install_dir}/bin/bsdtar.exe",
    file_cache_dir => $file_cache_dir,
    require        => File[$source_file_path],
  }
}
