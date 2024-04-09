from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import time
import pyautogui

# Set up the WebDriver
driver = webdriver.Chrome()
driver.get("http://your-grafana-url.com")
time.sleep(2)  # Wait for the page to fully load

# Scroll to the graph in Grafana
driver.find_element_by_tag_name('body').send_keys(Keys.END)
time.sleep(2)  # Wait for the graph to appear

# Take a screenshot
driver.save_screenshot("grafana_screenshot.png")

# Minimize the WebDriver window
driver.minimize_window()

# Open Microsoft Teams
pyautogui.hotkey('win', 's')  # Press Win+S to open Windows search
time.sleep(1)  # Wait for the search box to open
pyautogui.write("Microsoft Teams")  # Type "Microsoft Teams" in the search box
time.sleep(1)  # Wait for the search results to appear
pyautogui.press('enter')  # Press Enter to open Microsoft Teams
time.sleep(10)  # Wait for Microsoft Teams to fully open (adjust this time as needed)

# Type and search for the group chat
group_name = "Your Group Name"  # Replace "Your Group Name" with the name of your group chat
pyautogui.write(group_name)  # Type the name of the group chat
time.sleep(1)  # Wait for the search results to appear
pyautogui.press('enter')  # Press Enter to open the group chat
time.sleep(5)  # Wait for the group chat window to fully open (adjust this time as needed)

# Paste the screenshot into the Microsoft Teams group chat
pyautogui.hotkey('ctrl', 'v')  # Press Ctrl+V to paste
pyautogui.press('enter')  # Press Enter to send the message

# Close the WebDriver
driver.quit()
