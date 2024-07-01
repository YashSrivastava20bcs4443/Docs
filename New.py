import paramiko
import csv

# FortiGate firewall ke details
hostname = 'your_firewall_ip'
username = 'your_username'
password = 'your_password'

# SSH client initialize karna
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    # Firewall se connect karna
    client.connect(hostname, username=username, password=password)

    # Command run karna
    stdin, stdout, stderr = client.exec_command('get system status')

    # Output read karna
    output = stdout.read().decode()

    # CSV file mein save karna
    with open('system_status.csv', 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        
        # CSV file ke headers
        headers = ['Key', 'Value']
        csvwriter.writerow(headers)

        # Output ko lines mein split karna
        lines = output.splitlines()

        # Har line ko key-value pairs mein convert karna aur write karna
        for line in lines:
            if ':' in line:
                key, value = line.split(':', 1)
                csvwriter.writerow([key.strip(), value.strip()])

    print("Data CSV file mein successfully save ho gaya.")
    
finally:
    # SSH connection close karna
    client.close()
