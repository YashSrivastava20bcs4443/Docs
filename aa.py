        # Click on the specific element based on alert description
        if re.search(r'fail(?:ed|ure)?', alert_description):
            failures_menu_locator = "div[data-telemetryname='Menu-failures']"
            WebDriverWait(driver, 20).until(EC.element_to_be_clickable((By.CSS_SELECTOR, failures_menu_locator))).click()
            if re.search("dependency", alert_description):
                iframe = WebDriverWait(driver, 30).until(EC.presence_of_element_located((By.CLASS_NAME, "fxs-part-frame")))
                driver.switch_to.frame(iframe)
                element = WebDriverWait(driver, 30).until(EC.element_to_be_clickable((By.ID, "Dependencies")))
                element.click()
            elif re.search("exception", alert_description):
                iframe = WebDriverWait(driver, 30).until(EC.presence_of_element_located((By.CLASS_NAME, "fxs-part-frame")))
                driver.switch_to.frame(iframe)
                element = WebDriverWait(driver, 30).until(EC.element_to_be_clickable((By.ID, "Exceptions")))
                element.click()
        else:
            # Default case
            time.sleep(5)

        # Take screenshot after page has loaded properly
        time.sleep(10)  # Additional delay for any dynamic content to load
        screenshot_filename = f"screenshots/{target_resource_name}.png"
        driver.save_screenshot(screenshot_filename)

        # Send email with screenshot
        send_email(target_resource_name, owner_email, screenshot_filename, severity, alert_description)
        print(f"Alert email sent for {target_resource_name}")
