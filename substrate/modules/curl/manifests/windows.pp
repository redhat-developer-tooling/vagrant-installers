class curl::windows {
  $file_cache_dir = $curl::file_cache_dir
  $install_dir    = $curl::install_dir

  $source_file_path = "${file_cache_dir}\\curl.zip"

  file { $source_file_path:
    source => "puppet:///modules/curl/windows.zip",
    owner => "Administrators",
    group => "Administrator",
    mode => 644
  }

  powershell { "extract-curl":
    content        => template("curl/extract.erb"),
    creates        => "${install_dir}/curl.exe",
    file_cache_dir => $file_cache_dir,
    require        => File[$source_file_path],
  }
}
