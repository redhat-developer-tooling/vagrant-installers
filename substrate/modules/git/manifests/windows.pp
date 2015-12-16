# == Class: git::windows
#
# This installs git on Windows.
#
class git::windows(
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  download { "git":
    source => "https://github.com/git-for-windows/git/releases/download/v2.6.4.windows.1/PortableGit-2.6.4-64-bit.7z.exe",
    destination => path("${file_cache_dir}/portable_git.7z.exe"),
    file_cache_dir => $file_cache_dir
  }

  exec { "extract-git":
    command => "cmd.exe /C ${file_cache_dir}\\portable_git.7z.exe -y",
    cwd     => $file_cache_dir,
    require => Download["git"],
  }
}
