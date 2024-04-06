                    # Wait for body element to be present
                    WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
