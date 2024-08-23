import paramiko
import socket
import re
from datetime import datetime

# SFTP server connection details
hostname = '172.23.1.107'
username = 'fwbackup'
password = '2002'
backup_folder_path = '/upload/Network_devices_Backup'
exclude_folder = "monthly_Backup"

# Regex pattern to extract the date and time from the filename
date_pattern = re.compile(r"_(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})\.conf$")

def extract_date_from_filename(filename):
    match = date_pattern.search(filename)
    if match:
        return datetime.strptime(match.group(1), '%Y-%m-%d-%H-%M-%S')
    return None

try:
    # Connect to the SFTP server with a timeout
    transport = paramiko.Transport((hostname, 22))
    transport.banner_timeout = 200  # Increase the banner timeout
    transport.connect(username=username, password=password)
    sftp = paramiko.SFTPClient.from_transport(transport)

    # Get the list of directories in the backup folder
    backup_folders = sftp.listdir(backup_folder_path)

    # Iterate through each folder and manage backups
    for folder in backup_folders:
        # Exclude the "monthly_Backup" folder
        if folder == exclude_folder:
            continue
        
        folder_path = f"{backup_folder_path}/{folder}"
        files = sftp.listdir_attr(folder_path)
        
        # Extract date from filename and sort files by date
        files_with_dates = []
        for file in files:
            date = extract_date_from_filename(file.filename)
            if date:
                files_with_dates.append((file, date))
        
        # Sort files by the extracted date
        files_with_dates.sort(key=lambda x: x[1])
        
        # If there are more than 4 files, delete the oldest ones
        if len(files_with_dates) > 4:
            files_to_delete = files_with_dates[:-4]
            for file, _ in files_to_delete:
                file_path = f"{folder_path}/{file.filename}"
                sftp.remove(file_path)
                print(f"Deleted: {file_path}")

    # Close the SFTP connection
    sftp.close()
    transport.close()

except paramiko.ssh_exception.SSHException as e:
    print(f"SSHException: {str(e)}")
except socket.timeout as e:
    print(f"Connection timed out: {str(e)}")
except Exception as e:
    print(f"An error occurred: {str(e)}")
