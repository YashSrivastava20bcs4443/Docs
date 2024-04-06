import asyncio
from pyppeteer import launch

async def main():
    browser = await launch()
    page = await browser.newPage()

    await page.goto("https://portal.azure.com")

    await page.type('#i0116', 'your-username')
    await page.click('#idSIButton9')
    await page.waitForSelector('#i0118')
    await page.type('#i0118', 'your-password')
    await page.click('#idSIButton9')

    await browser.close()

print("Starting...")
asyncio.get_event_loop().run_until_complete(main())
print("Screenshot has been taken")
