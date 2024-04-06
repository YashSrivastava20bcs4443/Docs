import time

if __name__ == "__main__":
    # Base URL
    base_url = "https://portal.azure.com/#@fareportal.com"

    # Chrome options for headless mode
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--no-sandbox")

    # WebDriver for Chrome
    service = webdriver.chrome.service.Service(executable_path='./chromedriver.exe')
    options = webdriver.ChromeOptions()
    driver = webdriver.Chrome(service=service, options=options)
    driver.maximize_window()

    try:
        # Fetch alerts
        subscription_id = "7f44f77d-2226-45b0-af98-33e1b75c38b7"
        alerts = fetch_alerts(subscription_id)

        # Saving filtered alerts to JSON file
        save_to_json(alerts)

        # Read CSV file
        with open("api.csv", newline="") as csvfile:
            reader = csv.DictReader(csvfile)
            api_owners = {row["APT Name"]: row["Omer Email"] for row in reader}

        # Create a directory to save screenshots if it doesn't exist
        if not os.path.exists("screenshots"):
            os.makedirs("screenshots")

        # Iterate over alerts
        for alert in alerts:
            # Extract target resource and target resource name
            target_resource = alert.get("targetResource")
            target_resource_name = alert.get("targetResourcefiame")
            severity = alert.get("severity")
            alert_description = alert.get("name")

            # Check if target resource name matches any API name in CSV
            if target_resource_name in api_owners:
                # Get owner email for the matching API name
                owner_email = api_owners[target_resource_name]

                # Create URL for the alert
                full_url = f"{base_url}/resource/{target_resource}"

                try:
                    # Open URL in headless browser
                    driver.get(full_url)

                    # Wait for page to load (adjust the timeout as needed)
                    WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, "//body")))

                    # Sign in to Microsoft account
                    email = "svcems@fareportal.com"
                    password = "Uw60\"1128UW"
                    sign_in(driver, email, password)

                    # Add delay before taking screenshot (adjust the delay time as needed)
                    time.sleep(5)  # Delay of 5 seconds

                    # Take screenshot
                    screenshot_filename = f"screenshots/{target_resource_name}.png"
                    capture_screenshot(driver, screenshot_filename)

                    # Send email with screenshot
                    send_email(target_resource_name, owner_email, screenshot_filename, severity, alert_description)

                    print(f"Alert email sent for {target_resource_name}")

                except TimeoutException:
                    print(f"Timeout occurred while loading {full_url}")

    finally:
        # Quit WebDriver
        driver.quit()
