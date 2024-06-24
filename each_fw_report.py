import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import os
import shutil
from openpyxl import load_workbook
from openpyxl.styles import PatternFill, Font, Border, Side
import smtplib
from email.message import EmailMessage

# Configure WebDriver options
download_directory = os.path.join(os.getcwd(), "downloads")
temp_directory = os.path.join(os.getcwd(), "temp")

chrome_options = webdriver.ChromeOptions()
chrome_options.add_experimental_option("prefs", {
    "download.default_directory": temp_directory,
    "download.prompt_for_download": False,
    "safebrowsing.enabled": True
})

# Path to the ChromeDriver executable
driver_path = 'D:\\VS CODE\\python\\chromedriver.exe'

# List of FortiGate firewall IPs
firewall_ips = [
    '192.168.1.11',
    '192.168.1.10',
]

# Shared FortiGate credentials
username_str = 'admin'
password_str = '2002'

# Microsoft credentials
microsoft_email = 'yashsrivastava48@outlook.com'
microsoft_password = ''

# SMTP email configuration
smtp_server = 'smtp.example.com'
smtp_port = 587
smtp_username = 'your_email@example.com'
smtp_password = 'your_email_password'
email_to = ['recipient1@example.com', 'recipient2@example.com']
email_cc = ['cc1@example.com', 'cc2@example.com']
email_subject = 'Filtered Firewall Policies'
email_body = 'Please find attached the filtered firewall policies.'

# Function to sign in to Microsoft
def sign_in(driver, email, password):
    EMAILFIELD = (By.ID, "i0116")
    PASSWORDFIELD = (By.ID, "i0118")
    NEXTBUTTON = (By.ID, "idSIButton9")
    
    WebDriverWait(driver, 10).until(EC.element_to_be_clickable(EMAILFIELD)).send_keys(email)
    WebDriverWait(driver, 10).until(EC.element_to_be_clickable(NEXTBUTTON)).click()
    WebDriverWait(driver, 10).until(EC.element_to_be_clickable(PASSWORDFIELD)).send_keys(password)
    WebDriverWait(driver, 10).until(EC.element_to_be_clickable(NEXTBUTTON)).click()
    
    try:
        stay_signed_in_popup = driver.find_element(By.XPATH, "//div[contains(text(), 'Stay signed in?')]")
        if stay_signed_in_popup:
            no_button = driver.find_element(By.XPATH, "//input[@value='No']")
            no_button.click()
    except:
        pass

# Function to wait for file to be fully downloaded and rename it
def wait_for_download_and_rename(temp_dir, new_name, timeout=30):
    start_time = time.time()
    while True:
        for filename in os.listdir(temp_dir):
            if filename.endswith(".csv") and not filename.endswith(".crdownload"):
                full_path = os.path.join(temp_dir, filename)
                new_path = os.path.join(download_directory, new_name)
                shutil.move(full_path, new_path)
                print(f"File renamed and moved to {new_path}")
                return
        if time.time() - start_time > timeout:
            raise Exception(f"File download timed out after {timeout} seconds.")
        time.sleep(1)

# Function to export firewall policies
def export_policies(ip):
    service = Service(driver_path)
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    try:
        # Open Microsoft sign-in page
        driver.get('https://login.microsoftonline.com/')
        sign_in(driver, microsoft_email, microsoft_password)
        
        # Open FortiGate login page
        driver.get(f'http://{ip}')
        
        # Log in to FortiGate
        time.sleep(3)  # Adjust sleep time if needed to wait for the page to load
        username = driver.find_element(By.ID, 'username')
        password = driver.find_element(By.ID, 'secretkey')
        login_button = driver.find_element(By.ID, 'login_button')
        username.send_keys(username_str)
        password.send_keys(password_str)
        login_button.click()
        
        time.sleep(5)  # Adjust sleep time if needed to wait for login to complete
        
        # Navigate to Firewall Policy page
        driver.get(f'http://{ip}/ng/firewall/policy/policy/standard')
        time.sleep(30)  # Adjust sleep time if needed to wait for the page to load
        
        # Step 1: Click configure table using JavaScript
        try:
            configure_table_button = WebDriverWait(driver, 30).until(
                EC.presence_of_element_located((By.XPATH, '//f-icon[@class="fa-cog"]'))
            )
            driver.execute_script("arguments[0].click();", configure_table_button)
            print("Clicked on configure table button using JavaScript")
        except Exception as e:
            print(f"Failed to click configure table button: {e}")
            driver.save_screenshot('error_screenshot.png')
            return
        
        # Step 2: Select specific options by clicking buttons with exact text
        options = [
            "Destination Address", "First Used", "Hit Count", 
            "ID", "IPS", "Last Used", "Packets", 
            "Source Address", "Status"
        ]
        
        for option in options:
            try:
                button = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, f'//button[.//span[text()="{option}"]]'))
                )
                driver.execute_script("arguments[0].click();", button)
                print(f"Clicked on '{option}' button")
            except Exception as e:
                print(f"Failed to click on '{option}' button: {e}")
        
        # Step 3: Click Apply
        try:
            apply_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//button[contains(@class, "standard-button primary") and text()="Apply"]'))
            )
            driver.execute_script("arguments[0].click();", apply_button)
            print("Clicked on Apply button")
        except Exception as e:
            print(f"Failed to click on Apply button: {e}")
        
        # Locate and click the Export button using JavaScript to avoid interception
        try:
            export_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//span[@class="ng-binding ng-scope" and text()="Export"]'))
            )
            driver.execute_script("arguments[0].click();", export_button)
            time.sleep(2)  # Wait for the dropdown to appear
            print("Clicked on Export button")
        except Exception as e:
            print(f"Failed to click on Export button: {e}")
        
        # Select CSV from the dropdown using JavaScript
        try:
            export_csv_option = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//span[@class="ng-scope" and text()="CSV"]'))
            )
            driver.execute_script("arguments[0].click();", export_csv_option)
            print("Clicked on CSV option")
        except Exception as e:
            print(f"Failed to click on CSV option: {e}")
        
        # Define the new filename based on IP
        new_filename = f'firewall_policies_{ip}.csv'
        time.sleep(5)  # Wait for the file to be fully downloaded and rename it within the temp directory
        wait_for_download_and_rename(temp_directory, new_filename)
    
    except Exception as e:
        print(f"An error occurred while exporting policies for {ip}: {e}")
        driver.save_screenshot('error_screenshot.png')
    finally:
        driver.quit()

# Ensure download and temp directories exist
os.makedirs(download_directory, exist_ok=True)
os.makedirs(temp_directory, exist_ok=True)

# Function to create an Excel file with filtered sheets
def create_filtered_excel(input_csv, output_excel):
    df = pd.read_csv(input_csv)
    
    # Filter DataFrame for 'Disable' policies
    disable_df = df[df['Status'] == 'Disable'][['Name', 'First Used', 'Hit Count', 'ID', 'Last Used', 'Packets', 'Status']]
    
    # Filter DataFrame for '0 Hit Count' policies
    zero_hit_count_df = df[df['Hit Count'] == 0][['Name', 'First Used', 'Hit Count', 'ID', 'Last Used', 'Packets', 'Status']]
    
    # Prepare DataFrame for 'Last Used Month wise'
    df['Last Used'] = pd.to_datetime(df['Last Used'], errors='coerce')
    last_used_monthwise_df = df.groupby(df['Last Used'].dt.to_period('M')).apply(
        lambda x: x[['Name', 'First Used', 'Hit Count', 'ID', 'Last Used', 'Packets', 'Status']]
    ).reset_index(drop=True)
    
    # Create Excel file with the filtered DataFrames
    with pd.ExcelWriter(output_excel, engine='openpyxl') as writer:
        disable_df.to_excel(writer, sheet_name='Disable Policies', index=False)
        zero_hit_count_df.to_excel(writer, sheet_name='0 Hit Count Policies', index=False)
        last_used_monthwise_df.to_excel(writer, sheet_name='Last Used Month Wise', index=False)
    
    print(f"Filtered Excel file created at {output_excel}")

# Function to send an email with the attached Excel file
def send_email_with_attachment(smtp_server, smtp_port, smtp_username, smtp_password, email_to, email_cc, subject, body, attachment_path):
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = smtp_username
    msg['To'] = ', '.join(email_to)
    msg['Cc'] = ', '.join(email_cc)
    msg.set_content(body)
    
    with open(attachment_path, 'rb') as file:
        file_data = file.read()
        file_name = os.path.basename(file.name)
        msg.add_attachment(file_data, maintype='application', subtype='octet-stream', filename=file_name)
    
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.send_message(msg)
    
    print(f"Email sent with attachment {attachment_path}")

# Function to clean up downloaded files
def clean_up_downloaded_files(directory):
    for file_name in os.listdir(directory):
        file_path = os.path.join(directory, file_name)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
                print(f"Deleted file: {file_path}")
        except Exception as e:
            print(f"Failed to delete file {file_path}: {e}")

# Process each firewall IP
for firewall_ip in firewall_ips:
    # Export policies for the current firewall IP
    export_policies(firewall_ip)
    
    # Define the path to the downloaded CSV file
    csv_path = os.path.join(download_directory, f'firewall_policies_{firewall_ip}.csv')
    
    # Define the path to the output Excel file
    excel_path = os.path.join(download_directory, f'filtered_firewall_policies_{firewall_ip}.xlsx')
    
    # Create filtered Excel file
    create_filtered_excel(csv_path, excel_path)
    
    # Send email with the attached Excel file
    send_email_with_attachment(
        smtp_server, smtp_port, smtp_username, smtp_password,
        email_to, email_cc, email_subject, email_body, excel_path
    )
    
    # Clean up downloaded files
    clean_up_downloaded_files(download_directory)
    clean_up_downloaded_files(temp_directory)
