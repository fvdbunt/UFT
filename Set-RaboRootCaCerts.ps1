[CmdletBinding()]
param (
    [switch]
    $FixJre,

    [switch]
    $FixGit
)

$DefaultSingleCertFilePath = Join-Path $env:USERPROFILE 'RabobankNederlandITN.pem'
$DefaultAllCertsFilePath = Join-Path $env:USERPROFILE 'RaboRootCAs.crt'
$JreCertAlias = 'rabobanknederlanditn'

function Write-Certificates($certs, [string] $CertFilePath) {
    $certs |
        ForEach-Object {
            Write-Output "-----BEGIN CERTIFICATE-----`n$([System.Convert]::ToBase64String($_.RawData, 'InsertLineBreaks'))`n-----END CERTIFICATE-----"
        } |
        Set-Content -Encoding ASCII -Path $CertFilePath

    Write-Verbose "Wrote $CertFilePath"
}

function Get-JavaHome {
    if ($env:JAVA_HOME) {
        Write-Verbose "Using JAVA_HOME ($env:JAVA_HOME)"
        $env:JAVA_HOME
    } else {
        Write-Verbose "JAVA_HOME not set, trying to determine with 'java' path..."
        # strip bin\java.exe
        Split-Path (Split-Path (Get-Command java).Path)
    }
}

function Find-KeyStorePath {
    $javaHome = Get-JavaHome
    $libSecurityCacerts = Join-Path 'lib' (Join-Path 'security' 'cacerts')
    $paths = (Join-Path $javaHome $libSecurityCacerts),
        (Join-Path $javaHome (Join-Path jre $libSecurityCacerts)) |
            Where-Object {Test-Path $_}
    if (-not $paths) {
        throw "No cacerts file found under $javaHome"
    }
    $paths
}

function Find-KeyToolPath {
    $kt = Get-Command keytool -ErrorAction SilentlyContinue
    if ($kt) {
        $kt.Path
    } else {
        Write-Verbose "'keytool' not in PATH, trying to find..."
        $javaHome = Get-JavaHome
        $ktPath = Join-Path $javaHome (Join-Path bin keytool.exe)
        if (-not (Test-Path $ktPath)) {
            throw "keytool.exe not found in PATH and not relative to $javaHome"
        }
        $ktPath
    }
}

function Get-RaboProxyRootCA {
    [CmdletBinding()]
    param (
        [string]
        $CertFilePath = $DefaultSingleCertFilePath
    )

    Write-Certificates (
        Get-ChildItem Cert:\LocalMachine\Root |
        Where-Object Subject -eq 'E=nfo@rabobank.nl, CN=Rabobank Nederland ITN, OU=INF ISEU DCNS, O=Rabobank Nederland, C=NL'
    ) $CertFilePath
}

function Get-AllRootCAs {
    [CmdletBinding()]
    param (
        [string]
        $CertFilePath = $DefaultAllCertsFilePath
    )

    Write-Certificates (Get-ChildItem Cert:\LocalMachine\Root) $CertFilePath
}

function Set-GitRootCAs {
    [CmdletBinding()]
    param (
        [string]
        $CertFilePath = $DefaultAllCertsFilePath,

        [string]
        $GitExePath = (Get-Command git).Path
    )

    Get-AllRootCAs $CertFilePath

    Write-Verbose "Setting http.sslcainfo=$CertFilePath"
    & $GitExePath config --global --path http.sslcainfo "$CertFilePath"

    # Make sure git uses OpenSSL and not the Windows certificates.
    # (it would have been nice if that worked, but unfortunately it doesn't)
    Write-Verbose "Setting http.sslBackend=openssl"
    & $GitExePath config --global http.sslBackend openssl

    # Now that we have the correct certificates, make sure SSL verification is on.
    Write-Verbose "Setting http.sslVerify=true"
    & $GitExePath config --global http.sslVerify true
}

function Add-JreRootCA {
    [CmdletBinding()]
    param (
        [string]
        $CertFilePath = $DefaultSingleCertFilePath,

        [string]
        $KeyStorePath = (Find-KeyStorePath),

        [string]
        $KeyToolPath = (Find-KeyToolPath),

        [securestring]
        $StorePassword = (ConvertTo-SecureString -AsPlainText -Force 'changeit')
    )

    function ConvertFrom-SecureStringToPlainText([securestring] $str) {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($str)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

    function Invoke-KeyTool([string[]] $options) {
        Write-Verbose "'$KeyToolPath' -keystore `"$KeyStorePath`" -storepass **** -noprompt $($options -join ' ')"
        $options += '-keystore', "`"$KeyStorePath`"", '-storepass', "`"$(ConvertFrom-SecureStringToPlainText $StorePassword)`"", '-noprompt'

        Invoke-Expression "& `"$KeyToolPath`" $options" | Out-Null
        $ec = $LASTEXITCODE
        Write-Verbose "Keytool exited with status $ec"
        $ec
    }

    # check if the keystore already has the certificate in question
    if ((Invoke-KeyTool '-list', '-alias', $JreCertAlias) -eq 0) {
        Write-Host "Certificate already exists in $KeyStorePath, removing it..."
        Invoke-KeyTool '-delete', '-alias', $JreCertAlias | Out-Null
    }
    Get-RaboProxyRootCA $CertFilePath

    Write-Host "Importing $CertFilePath to $KeyStorePath..."
    Invoke-KeyTool '-importcert', '-alias', $JreCertAlias, '-file', "`"$CertFilePath`"" | Out-Null
}

if ($FixJre) {
    Add-JreRootCA
}
if ($FixGit) {
    Set-GitRootCAs
}