# Vagrant Installer

## Windows Steps

 * Install Puppet for 64bit Windows (https://downloads.puppetlabs.com/windows/puppet-3.8.4-x64.msi)
 * Open Powershell with Administrator privileges
 * Run 'substrate/run.ps1'
 * Specify any valid directory as OutputDir
 * It should now build the substrate without error
 * Run 'install/install.ps1'
 * Specify 'c:\vagrant-substrate\staging' as SubstrateDir
 * Specify '1.7.4' as VagrantRevision
 * Vagrant will now be installed into the substrate
