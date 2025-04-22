# Weather Terminal (wxtrmnl)

![Screenshot of what the Weather Terminal plugin will look like populated with data on a TRMNL device.](/assets/demo.png)

Weather Terminal (wxtrmnl) is a private plugin that can be used on [TRMNL devices](https://usetrmnl.com) to display weather information from a [WeatherLink connected device](https://www.weatherlink.com) and current conditions from [OpenWeather](https://openweathermap.org/city/2643743).

## Getting Started

There are several prerequisite steps you need to take in order to get `wxtrmnl` running on your TRMNL device.

## Create a Private TRMNL Plugin

Follow the steps [here](https://usetrmnl.com/plugin_settings/new?keyname=private_plugin) to create your own private TRMNL plugin.

1. Give your private plugin a name.
1. Set the `Strategy` to `Webhook`.
1. Click `Save`.

Once the page reloads:
1. Change `Refresh rate` to `Every 15 minutes`.
1. Make note of the `Plugin UUID`. That will become your `WXTRMNL_PLUGIN_ID` environment variable.
1. Click `Save`.

Once the page reloads:
1. Click `Edit markup`.
1. Paste the contents of `display.liquid` from this repository into text editor on the page.
1. Click `Save`.

## Sending Data to Webhook

`wxtrmnl` requires that your periodically run `wxtrmnl-fetch.sh`. There are lots of ways to do this. All you need is some sort of VM (or service) that you can run a Bash script in an automated fashion.

Once you have access to that environment continue by:

### Setting Your Environmental Variables
`wxtrmnl` requires several **permanent** environmental variables to be set. The table below specifies the name and value of the environment variables that are required.

| Environment Variable Name | Environment Variable Value                              |
| ------------------------- | ------------------------------------------------------- |
| `OPEN_WEATHER_API_KEY`    | OpenWeather API key.                                    |
| `WEATHER_LINK_API_KEY`    | WeatherLink API key.                                    |
| `WEATHER_LINK_API_SECRET` | WeatherLink API secret.                                 |
| `WXTRMNL_LAT`             | Latitude of your location, decimal (-90; 90).           |
| `WXTRMNL_LON`             | Longitude of your location, decimal (-180; 180).        |
| `WXTRMNL_NAME`            | The city and state of your location. (e.g. Chicago, IL) |
| `WXTRMNL_PLUGIN_ID`       | The ID of your private TRMNL plugin.                    |

### Clone Repo
Navigate to the location where you want to place this project's directory and clone the repository by running the following command:

```
git clone https://github.com/mike-weiner/wxtrmnl.git
```

### Dry Run Fetching Data

You can test the `wxtrmnl-fetch.sh` script by running the following command to do a dry run of fetching data from WeatherLink and OpenWeather and building the JSON payload that would be sent to your TRMNL webhook endpoint:

```
./wxtrmnl-fetch.sh -dv
```

### Create CRON Job

A CRON job is the simplest way to run the Bash script at a set interval. Create a cron job by running:

1. Run `crontab -e`.
1. Append `*/10 * * * * /bin/bash -i -c 'source /home/<user>/.bashrc && /home/<user>/path/to/wxtrmnl/wxtrmnl-fetch.sh'` to the bottom of the file.
1. Save the file.

You can run `grep CRON /var/log/syslog` after 15 (or so) minutes to verify your CRON job is working. (**Note:** You will need `sudo` level permission to run this command.)

## Contributing
All contributions are welcome! 

First, search open issues to see if a ticket has already been created for the issue or feature request that you have. If a ticket does not already exist, open an issue to discuss what contributions you would like to make. 

**All contributions should be developed in a `feature/` or `fix/` branch off of the `main` branch as a PR will be required before any changes are merged back into the `main` branch.**

## License
Distributed under the MIT License. See `LICENSE.txt` for more information.

## References
Below are several references that were used to help find inspiration for this project, get a starting point for the CLI, and serve as a resource for the WeatherLink API.
- [OpenWeather API Docs](https://openweathermap.org/api)
- [TRMNL Developer Docs](https://docs.usetrmnl.com/go)
- [WeatherLink Developer Portal](https://weatherlink.github.io)
- [WeatherLink Portal](https://www.weatherlink.com)