if re.search(r'fail(?:ed|ure)?', alert_description) and "request" in alert_description:
    failures_menu_locator = "div[data-telemetryname='Menu-failures']"
    WebDriverWait(driver, 20).until(EC.element_to_be_clickable((By.CSS_SELECTOR, failures_menu_locator))).click()
    
else:
    # Default case
    time.sleep(5)

# Rest of the code...
