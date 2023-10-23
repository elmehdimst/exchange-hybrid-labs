import winrm

# Define the connection parameters
server_url = "http://13.72.80.229:5985/wsman"
username = "adminuser"
password = "Password1234!"

# Create a session
session = winrm.Session(server_url, auth=(username, password))

# Run a command
result = session.run_ps("Get-Process")

# Run a command to list the contents of C:\terraform
result = session.run_ps("Get-ChildItem C:\\terraform | Format-Table Name, Length, LastWriteTime")

# Print the output
print(result.status_code)
print(result.std_out.decode().strip())
