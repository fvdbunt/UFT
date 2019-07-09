# rabo-root-ca-utils

PowerShell utility commands to help you cope with Rabobank's own root certificate authorities.

This has been built and tested on a Rabobank NL OTA VDI, but might work elsewhere too.

## Git

To be able to work with repositories outside Rabobank's network, mostly
[Visual Studio Team Services](https://raboweb.visualstudio.com).

### Easiest way

1.  Download the
    [Powershell script file](https://git.rabobank.nl/projects/DA/repos/rabo-root-ca-utils/raw/Set-RaboRootCaCerts.ps1?at=refs%2Fheads%2Fmaster),
    save it to a local directory
2.  Open a Cmd window as Administrator and `cd` to the directory the file has been downloaded to
3.  Run `powershell -executionpolicy remotesigned .\Set-RaboRootCaCerts.ps1 -FixGit`

This will mark the same root CA certificates that the Rabobank Windows machine trusts, in Git as trusted too.

### More power

1.  Download the
    [Powershell script file](https://git.rabobank.nl/projects/DA/repos/rabo-root-ca-utils/raw/Set-RaboRootCaCerts.ps1?at=refs%2Fheads%2Fmaster),
    save it to a local directory
2.  Open a Cmd window as Administrator and `cd` to the directory the file has been downloaded to
3.  Run `powershell -executionpolicy remotesigned`
4.  In PowerShell import our functions: `. .\Set-RaboRootCaCerts.ps1`
5.  Run `Set-GitRootCAs` with any combination of the following parameters:
    *   `-CertFilePath`: path to an intermediate file that will be created containing all trusted root CAs.
    *   `-GitExePath`: path to Git executable
    *   `-Verbose`: extra logging

## Java

For Java commands that require internet access.

### Easiest way

1.  Download the
    [Powershell script file](https://git.rabobank.nl/projects/DA/repos/rabo-root-ca-utils/raw/Set-RaboRootCaCerts.ps1?at=refs%2Fheads%2Fmaster),
    save it to a local directory
2.  Open a Cmd window as Administrator and `cd` to the directory the file has been downloaded to
3.  Run `powershell -executionpolicy remotesigned .\Set-RaboRootCaCerts.ps1 -FixJre`

This will add the correct certificate from Windows to the JRE's `cacerts` keystore. If an environment variable
`JAVA_HOME` exists that will be used, otherwise the `java` command is searched in the `PATH` and an attempt is made
to find the keystore from there.

### More power

1.  Download the
    [Powershell script file](https://git.rabobank.nl/projects/DA/repos/rabo-root-ca-utils/raw/Set-RaboRootCaCerts.ps1?at=refs%2Fheads%2Fmaster),
    save it to a local directory
2.  Open a Cmd window as Administrator and `cd` to the directory the file has been downloaded to
3.  Run `powershell -executionpolicy remotesigned`
4.  In PowerShell import our functions: `. .\Set-RaboRootCaCerts.ps1`
5.  Run `Add-JreRootCA` with any combination of the following parameters:
    *   `-CertFilePath`: path to an intermediate file that will be created containing all trusted root CAs.
    *   `-KeyStorePath`: path to the Java keystore to modify
    *   `-StorePassword`: password to the Java keystore (default is 'changeit')
    *   `-KeyToolPath`: path to `keytool.exe`, part of JDK and JRE
    *   `-Verbose`: extra logging

### InteliJ

IntelliJ comes with its own bundled JRE, and so with it its own CA keystore.

1.  Download the
    [Powershell script file](https://git.rabobank.nl/projects/DA/repos/rabo-root-ca-utils/raw/Set-RaboRootCaCerts.ps1?at=refs%2Fheads%2Fmaster),
    save it to a local directory
2.  Open a Cmd window as Administrator and `cd` to the directory the file has been downloaded to
3.  Run `powershell -executionpolicy remotesigned`
4.  In PowerShell import our functions: `. .\Set-RaboRootCaCerts.ps1`
5.  Run `Add-JreRootCA -KeyStorePath 'C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2017.3\jre64\lib\security\cacerts'`
    (adapt to your IntelliJ installation path)
