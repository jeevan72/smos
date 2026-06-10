# How to Connect to WiFi

## Quick Steps

1. **Click the network icon** in the top-right corner of your screen (or system tray)
2. **Select your WiFi network** from the list
3. **Enter the password** when prompted
4. **Click Connect**

## If You Don't See Any Networks

- Make sure WiFi is **turned on** (check the toggle in network settings)
- Make sure **Airplane Mode** is off
- Try restarting the network service:
  ```
  sudo systemctl restart NetworkManager
  ```

## Connect via Terminal

If you prefer using the terminal:

```bash
# List available networks
nmcli device wifi list

# Connect to a network
nmcli device wifi connect "YourNetworkName" password "YourPassword"

# Check connection status
nmcli connection show
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No WiFi adapter found | Check if drivers are installed: `lspci \| grep Network` |
| Connected but no internet | Try `ping google.com` to test. Restart router if needed |
| Keeps disconnecting | Update network drivers or check power management settings |
| Slow connection | Move closer to router or check for interference |

## Need More Help?

- Check your router manual for the default password
- Contact your internet service provider if the connection is down
- Try connecting with an ethernet cable to rule out WiFi issues
