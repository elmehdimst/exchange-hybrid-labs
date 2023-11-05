# Join the computer to the domain
Add-Computer -DomainName "demolabs50.local" -Credential (New-Object System.Management.Automation.PSCredential("adminuser", (ConvertTo-SecureString "Password1234!" -AsPlainText -Force)))

# Install the Web-Server feature
Install-WindowsFeature -Name Web-Server

# Set the execution policy to Unrestricted
Set-ExecutionPolicy Unrestricted -Force

# Restart the computer
Restart-Computer -Force