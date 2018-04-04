class ocf::packages::brave {
  class { 'ocf::packages::brave::apt':
    stage =>  first,
  }

  package { 'brave':; }

  # On Debian userns is compiled-in but disabled by deafult.
  # This is the recommended way to run Brave (and Chromium)
  # in sandboxed mode. Not running the browser as a sandbox
  # is strongly discouraged as the user is at much greater
  # risk.
  # See more here: https://chromium.googlesource.com/chromium/src/+/lkcr/docs/linux_sandboxing.md#User-namespaces-sandbox
  sysctl { 'kernel.unprivileged_userns_clone': value =>  '1' }
}
