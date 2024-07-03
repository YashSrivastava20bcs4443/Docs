def export_policies(ip, location):
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

        # Process data for the first link
        if ip == '10.255.255.65':
            links = [
                f'https://{ip}:8443/ng/firewall/policy/policy/standard?vdom=root',
                f'https://{ip}:8443/ng/firewall/policy/policy/standard?vdom=inside'
            ]
        else:
            links = [f'https://{ip}:8443/ng/firewall/policy/policy/standard']

        for link in links:
            driver.get(link)
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
                "Destination Address",
                "First Used",
                "Hit Count",
                "ID",
                "IPS",
                "Last Used",
                "Packets",
                "Source Address",
                "Status",
                "Comments"
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

            new_filename = f'firewall_policies_{location}_{link.split("=")[-1]}.csv'
            time.sleep(5)
            wait_for_download_and_rename(temp_directory, new_filename)

    except Exception as e:
        print(f"An error occurred while exporting policies for {ip}: {e}")
        driver.save_screenshot('error_screenshot.png')
    finally:
        driver.quit()
