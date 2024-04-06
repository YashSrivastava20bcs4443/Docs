import asyncio
from pyppeteer import launch

async def main():
    # Launch browser
    browser = await launch(headless=False)
    
    # Create a new page
    page = await browser.newPage()

    # Navigate to the Azure portal login page
    await page.goto('https://portal.azure.com')

    # Wait for login page to load
    await page.waitForSelector('#cred_userid_inputtext')

    # Enter username
    await page.type('#cred_userid_inputtext', 'your_username')

    # Click Next button
    await page.click('#cred_sign_in_button')

    # Wait for password field to appear
    await page.waitForSelector('#cred_password_inputtext')

    # Enter password
    await page.type('#cred_password_inputtext', 'your_password')

    # Click Sign in button
    await page.click('#cred_sign_in_button')

    # Wait for the Azure dashboard to load
    await page.waitForNavigation()

    # Optionally, you can do further actions here

    # Close the browser
    await browser.close()

# Run the main function
asyncio.get_event_loop().run_until_complete(main())
