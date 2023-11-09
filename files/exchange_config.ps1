# Join the computer to the domain
Add-Computer -DomainName "demolabs50.local" -Credential (New-Object System.Management.Automation.PSCredential("adminuser", (ConvertTo-SecureString "Password1234!" -AsPlainText -Force)))

# Install the Web-Server feature
Install-WindowsFeature -Name Web-Server

# Set the execution policy to Unrestricted
Set-ExecutionPolicy Unrestricted -Force

# Install necessary features for Exchange Server 2019
Install-WindowsFeature NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS

# Define the URL for .NET Framework 4.8 offline installer
$downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2088631"
$outputPath = "C:\Temp\dotnet-framework-4.8-offline-installer.exe"
# Download the installer
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath

# Define the URL for UCMA 4.0 Runtime offline installer
$ucmaDownloadUrl = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
$ucmaOutputPath = "C:\Temp\ucma-runtime.exe"
Invoke-WebRequest -Uri $ucmaDownloadUrl -OutFile $ucmaOutputPath


# Define the URLs for the Visual C++ Redistributable Packages for Visual Studio 2013
$vcRedist_x64_Url = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
$vcRedist_x64_Output = "C:\Temp\vcredist_x64.exe"
Invoke-WebRequest -Uri $vcRedist_x64_Url -OutFile $vcRedist_x64_Output

# Define the URLs for Exchange 2019 CU13
$exchange2019_cu13_Url = "https://download.microsoft.com/download/7/5/f/75f4d77e-002c-419c-a03a-948e8eb019f2/ExchangeServer2019-x64-CU13.ISO"
$exchange2019_cu13_Output = "C:\Temp\ExchangeServer2019-x64-CU13.iso"
Invoke-WebRequest -Uri $exchange2019_cu13_Url -OutFile $exchange2019_cu13_Output

# Define the URLs for IIS URL rewrite module
$rewrite_amd64_Url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$rewrite_amd64_Output = "C:\Temp\ExchangeServer2019-x64-CU13.iso"
Invoke-WebRequest -Uri $rewrite_amd64_Url -OutFile $rewrite_amd64_Output

# Restart the computer
Restart-Computer -Force