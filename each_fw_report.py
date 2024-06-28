import os
import shutil
import time
import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from openpyxl import load_workbook, Workbook
from openpyxl.styles import PatternFill, Font, Border, Side
from openpyxl.utils.dataframe import dataframe_to_rows
from email.message import EmailMessage
import smtplib
import config

# Configure WebDriver options
download_directory = os.path.join(os.getcwd(), "downloads")
temp_directory = os.path.join(os.getcwd(), "temp")
chrome_options = webdriver.ChromeOptions()
chrome_options.add_experimental_option("prefs", {
    "download.default_directory": temp_directory,
    "download.prompt_for_download": False,
    "safebrowsing.enabled": True
})
driver_path = 'C:\\Users\\y.s.va22\\Downloads\\PIC\\chromedriver.exe'

# List of FortiGate firewall IPs
firewall_ips = [
    '172.16.125.10',
]

# Shared FortiGate credentials
username_str = config.FW_USERNAME
password_str = config.FW_PASSWORD

# Microsoft credentials
microsoft_email = config.SENDER_EMAIL
microsoft_password = config.SENDER_PASSWORD

# SMTP email configuration
smtp_server = config.SMTP_SERVER
smtp_port = config.SMTP_PORT
smtp_username = config.SENDER_EMAIL
smtp_password = config.SENDER_PASSWORD

# Email details
email_to = ['yash.srivastava@fareportal.com', 'palak.verma@fareportal.com']
email_cc = ['akshat.jain@fareportal.com']
email_subject = 'Firewall Policy Review & Update'
email_body = '''Hi Team,

Please find the attached firewall policies of NJDC Lab Firewall.

Thanks & Regards,
EMS Team
'''

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
        driver.get('https://login.microsoftonline.com/')
        sign_in(driver, microsoft_email, microsoft_password)

        driver.get(f'https://{ip}:8443/')
        try:
            advanced_button = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, "details-button")))
            advanced_button.click()
            proceed_link = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, "proceed-link")))
            proceed_link.click()
        except Exception as e:
            print(f"No advanced option found or proceed (unsafe) link: {e}")

        # Click "Accept" button if it appears
        try:
            accept_button = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//button[@name='accept']")))
            accept_button.click()
        except Exception as e:
            print(f"No accept button found: {e}")

        time.sleep(3)
        username = driver.find_element(By.ID, 'username')
        password = driver.find_element(By.ID, 'secretkey')
        login_button = driver.find_element(By.ID, 'login_button')
        username.send_keys(username_str)
        password.send_keys(password_str)
        login_button.click()
        time.sleep(5)

        driver.get(f'http://{ip}/ng/firewall/policy/policy/standard')
        time.sleep(30)

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

        options = [
            "Destination Address", "First Used", "Hit Count", "ID", "IPS", "Last Used",
            "Packets", "Source Address", "Status"
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

        try:
            apply_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//button[contains(@class, "standard-button primary") and text()="Apply"]'))
            )
            driver.execute_script("arguments[0].click();", apply_button)
            print("Clicked on Apply button")
        except Exception as e:
            print(f"Failed to click on Apply button: {e}")

        try:
            export_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//span[@class="ng-binding ng-scope" and text()="Export"]'))
            )
            driver.execute_script("arguments[0].click();", export_button)
            time.sleep(2)
            print("Clicked on Export button")
        except Exception as e:
            print(f"Failed to click on Export button: {e}")

        try:
            export_csv_option = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, '//span[@class="ng-scope" and text()="CSV"]'))
            )
            driver.execute_script("arguments[0].click();", export_csv_option)
            print("Clicked on CSV option")
        except Exception as e:
            print(f"Failed to click on CSV option: {e}")

        new_filename = f'firewall_policies_{ip}.csv'
        time.sleep(5)
        wait_for_download_and_rename(temp_directory, new_filename)
    except Exception as e:
        print(f"An error occurred while exporting policies for {ip}: {e}")
        driver.save_screenshot('error_screenshot.png')
    finally:
        driver.quit()

os.makedirs(download_directory, exist_ok=True)
os.makedirs(temp_directory, exist_ok=True)

def apply_styles(sheet):
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="4F81BD", end_color="4F81BD", fill_type="solid")
    thin_border = Border(left=Side(style='thin'), right=Side(style='thin'), top=Side(style='thin'), bottom=Side(style='thin'))
    
    for cell in sheet[1]:
        cell.font = header_font
        cell.fill = header_fill
        cell.border = thin_border

    for row in sheet.iter_rows():
        for cell in row:
            cell.border = thin_border

def create_excel_file_for_firewall(firewall_ip, csv_file):
    output_excel_path = os.path.join(os.getcwd(), f"firewall_policies_{firewall_ip}.xlsx")
    df = pd.read_csv(csv_file)
    
    with pd.ExcelWriter(output_excel_path, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='All Data')
        
        zero_hit_count_df = df[df['Hit Count'] == 0]
        zero_hit_count_df.to_excel(writer, index=False, sheet_name='0 Hit Count')

        workbook = writer.book
        all_data_df = pd.read_excel(output_excel_path, sheet_name='All Data')
        zero_hit_count_df = pd.read_excel(output_excel_path, sheet_name='0 Hit Count')
        
        active_policies_df = all_data_df[all_data_df['Status'] == 'Enabled']
        blocked_policies_df = all_data_df[all_data_df['Status'] == 'Disabled']
        last_used_monthwise_df = all_data_df.groupby('Last Used').size().reset_index(name='Count')
        
        active_policies_df.to_excel(writer, index=False, sheet_name='Active Policies')
        blocked_policies_df.to_excel(writer, index=False, sheet_name='Blocked Policies')
        last_used_monthwise_df.to_excel(writer, index=False, sheet_name='Last Used Month Wise')

        create_dashboard_sheet(workbook, active_policies_df, blocked_policies_df, zero_hit_count_df, last_used_monthwise_df)
        
    workbook = load_workbook(output_excel_path)
    for sheet_name in workbook.sheetnames:
        sheet = workbook[sheet_name]
        apply_styles(sheet)
    workbook.save(output_excel_path)

    return output_excel_path

def send_email_with_attachment(smtp_server, smtp_port, smtp_username, smtp_password, email_to, email_cc, subject, body, attachment_path):
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = smtp_username
    msg['To'] = ', '.join(email_to)
    msg['Cc'] = ', '.join(email_cc)
    msg.set_content(body)

    with open(attachment_path, 'rb') as f:
        file_data = f.read()
        file_name = os.path.basename(attachment_path)
        msg.add_attachment(file_data, maintype='application', subtype='octet-stream', filename=file_name)

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.send_message(msg)
    print(f'Email sent to {", ".join(email_to)} with CC to {", ".join(email_cc)}')

def add_dataframe_to_sheet(sheet, dataframe, start_row, start_col, title):
    title_cell = sheet.cell(row=start_row, column=start_col, value=title)
    title_cell.font = Font(bold=True)
    for r_idx, row in enumerate(dataframe_to_rows(dataframe, index=False, header=True), start_row + 1):
        for c_idx, value in enumerate(row, start_col):
            sheet.cell(row=r_idx, column=c_idx, value=value)

def create_dashboard_sheet(workbook, active_policies_df, blocked_policies_df, zero_hit_count_df, last_used_monthwise_df):
    dashboard_sheet = workbook.create_sheet(title='Dashboard')

    add_dataframe_to_sheet(dashboard_sheet, active_policies_df, start_row=1, start_col=1, title="Active Policies")
    add_dataframe_to_sheet(dashboard_sheet, blocked_policies_df, start_row=1, start_col=10, title="Blocked Policies")
    add_dataframe_to_sheet(dashboard_sheet, zero_hit_count_df, start_row=20, start_col=1, title="0 Hit Count")
    add_dataframe_to_sheet(dashboard_sheet, last_used_monthwise_df, start_row=20, start_col=10, title="Last Used Month Wise")

    return dashboard_sheet

# Main script
for firewall_ip in firewall_ips:
    export_policies(firewall_ip)
    csv_file = os.path.join(download_directory, f'firewall_policies_{firewall_ip}.csv')
    output_excel_path = create_excel_file_for_firewall(firewall_ip, csv_file)
    send_email_with_attachment(smtp_server, smtp_port, smtp_username, smtp_password, email_to, email_cc, email_subject, email_body, output_excel_path)

shutil.rmtree(download_directory)
shutil.rmtree(temp_directory)
