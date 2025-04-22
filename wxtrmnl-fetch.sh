#!/bin/bash

# Global Variables
HUMIDITY_UNIT="%"
LATITUDE=${WXTRMNL_LAT}
LONGITUDE=${WXTRMNL_LON}
NAME=${WXTRMNL_NAME}
OW_API_KEY=${OPEN_WEATHER_API_KEY}
PRESSURE_UNIT='"'
RAINFALL_UNIT="in."
TEMP_UNIT="°F"
WIND_SPEED_UNIT="MPH"
WL_API_KEY=${WEATHER_LINK_API_KEY}
WL_API_SECRET=${WEATHER_LINK_API_SECRET}
WL_STATION_ID=${WEATHER_LINK_STATION_ID}
WXTRMNL_PLUGIN_ID=${WXTRMNL_PLUGIN_ID}

# Options
dry_run=false
help=false
verbose=false

function check_prerequisites {
  local reqEnvVars=(
    OPEN_WEATHER_API_KEY    
    WEATHER_LINK_API_KEY
    WEATHER_LINK_API_SECRET
    WEATHER_LINK_STATION_ID
    WXTRMNL_LAT
    WXTRMNL_LON
    WXTRMNL_NAME
    WXTRMNL_PLUGIN_ID
  )

  for var in "${reqEnvVars[@]}"; do
    if [[ -z "${!var}" ]]; then
      echo "Error: Environment variable $var is not set."
      exit 1
    fi
  done
}

function format_date {
  local date_input="$1"
  local format="$2"

  if [[ "$OSTYPE" == *"darwin"* ]]; then
    date -j -f %s "$date_input" "$format"
  else
    date -d "@$date_input" "$format"
  fi
}

function get_wind_direction_from_degrees {
  local dir=$1
  local directions=("N" "NNE" "NE" "ENE" "E" "ESE" "SE" "SSE" "S" "SSW" "SW" "WSW" "W" "WNW" "NW" "NNW")
  
  dir=$(( dir * 16 / 360 ))
  dir=$(( (dir + 16) % 16 ))

  echo "${directions[$dir]}"
}

function print_help {
  echo "Usage: $0"
  echo
  echo "Script used to fetch collate weather information about a location"
  echo "  and provide it to a trmnl webhook endpoint." 
  echo
  echo "Required environment variables:"
  echo "  OPEN_WEATHER_API_KEY      Your OpenWeather API Key"
  echo "  WEATHER_LINK_API_KEY      Your WeatherLink API Key"
  echo "  WEATHER_LINK_API_SECRET   Your WeatherLink API Secret"
  echo "  WEATHER_LINK_STATION_ID   Your WeatherLink Station ID"
  echo "  WXTRMNL_LAT               Latitude of your location; decimals accepted (-90; 90)"
  echo "  WXTRMNL_LON               Longitude of your location; decimals accepted (-180; 180)"
  echo "  WXTRMNL_NAME              Name of your location"
  echo
  echo
  echo "Options:"
  echo "  -d      Dry run"
  echo "  -h      Show this help message"
  echo "  -v      Enable verbose output"
  echo
  echo "Example:"
  echo "  OPEN_WEATHER_API_KEY=xxx $0"
  exit 1
}

while getopts ":dhv" opt; do
  case $opt in
    d)
      dry_run=true
      ;;
    h)
      help=true
      ;;
    v)
      verbose=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [[ "$help" == "true" ]]; then
  print_help
fi
check_prerequisites

# Fetch OpenWeather API Current Conditions
open_weather_response=$(curl -sfL -X GET "https://api.openweathermap.org/data/2.5/weather?lat=${LATITUDE}0&lon=${LONGITUDE}&units=standard&lang=en&appid=${OW_API_KEY}")

if [[ "$verbose" == "true" ]]; then
  echo "Response from OpenWeather:"
  echo "$open_weather_response"
fi

# Parse OpenWeather response
conditions=$(echo "$open_weather_response" | jq -r '.weather[0].description')
conditions=$(echo "$conditions" | awk '{ $1 = toupper(substr($1,1,1)) substr($1,2); print }')
icon=$(echo "$open_weather_response" | jq -r '.weather[0].icon')

sunrise_timestamp=$(echo "$open_weather_response" | jq -r '.sys.sunrise')
rise_at=$(format_date "$sunrise_timestamp" '+%I:%M %p')
sunset_timestamp=$(echo "$open_weather_response" | jq -r '.sys.sunset')
set_at=$(format_date "$sunset_timestamp" '+%I:%M %p')

# Fetch WeatherLink API Current Conditions
weather_link_response=$(curl -sfL -X GET -H "X-Api-Secret: ${WL_API_SECRET}" "https://api.weatherlink.com/v2/current/${WL_STATION_ID}?api-key=${WL_API_KEY}")

if [[ "$verbose" == "true" ]]; then
  echo "Response from WeatherLink:"
  echo "$weather_link_response"
fi

# Parse WeatherLink response
datetime_epoch=$(echo "$weather_link_response" | jq -r '.generated_at')
datetime=$(format_date "$datetime_epoch" '+%A, %B %-d, %Y @ %-I:%M %p')
heat_index=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].heat_index')
humidity=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].hum')
pressure="$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 242) | .data[0].bar_absolute')"
rain_day="$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].rainfall_last_24_hr_in')"
rain_month="$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].rainfall_monthly_in')"
rain_year="$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].rainfall_year_in')"
trend="$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 242) | .data[0].bar_trend')"
temp=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].temp')
wind_chill=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].wind_chill')
wind_dir=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].wind_dir_scalar_avg_last_10_min')
wind_dir=$(get_wind_direction_from_degrees "$wind_dir")
wind_speed=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].wind_speed_avg_last_10_min')
wind_gust_dir=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].wind_dir_at_hi_speed_last_10_min')
wind_gust_dir=$(get_wind_direction_from_degrees "$wind_gust_dir")
wind_gust_speed=$(echo "$weather_link_response" | jq -r '.sensors[] | select(.sensor_type == 37) | .data[0].wind_speed_hi_last_10_min')

# Build JSON payload for webhook endpoint
payload=$(jq -n \
  --arg conditions "$conditions" \
  --arg datetime "$datetime" \
  --argjson heat_index "$heat_index" \
  --argjson humidity "$humidity" \
  --arg humidity_unit "$HUMIDITY_UNIT" \
  --arg icon "$icon" \
  --arg name "$NAME" \
  --argjson pressure "$pressure" \
  --arg pressure_unit "$PRESSURE_UNIT" \
  --argjson rain_day "$rain_day" \
  --argjson rain_month "$rain_month" \
  --argjson rain_year "$rain_year" \
  --arg rainfall_unit "$RAINFALL_UNIT" \
  --arg rise_at "$rise_at" \
  --arg set_at "$set_at" \
  --argjson trend $trend \
  --argjson temp "$temp" \
  --arg temp_unit "$TEMP_UNIT" \
  --argjson wind_chill "$wind_chill" \
  --arg wind_dir "$wind_dir" \
  --argjson wind_speed "$wind_speed" \
  --arg wind_gust_dir "$wind_gust_dir" \
  --argjson wind_gust_speed "$wind_gust_speed" \
  --arg wind_speed_unit "$WIND_SPEED_UNIT" \
  '{
    "merge_variables": {
      conditions: $conditions,
      datetime: $datetime,
      humidity: { value: $humidity, unit: $humidity_unit },
      icon: $icon,
      name: $name,
      pressure: {
        relative: $pressure,
        trend: $trend,
        unit: $pressure_unit
      },
      rainfall: {
        day: $rain_day,
        month: $rain_month,
        year: $rain_year,
        unit: $rainfall_unit
      },
      sun: {
        rise_at: $rise_at,
        set_at: $set_at
      },
      temp: {
        current: $temp,
        heat_index: $heat_index,
        wind_chill: $wind_chill,
        unit: $temp_unit
      },
      wind: {
        current: {
          direction: $wind_dir,
          speed: $wind_speed,
          unit: $wind_speed_unit
        },
        gust: {
          direction: $wind_gust_dir,
          speed: $wind_gust_speed,
          unit: $wind_speed_unit
        }
      }
    }
  }'
)

if [[ "$verbose" == "true" ]]; then
  echo "JSON payload:"
  echo "$payload"
fi

if [[ "$dry_run" == false ]]; then
  # Send payload into trmnl webhook endpoint
  curl "https://usetrmnl.com/api/custom_plugins/${WXTRMNL_PLUGIN_ID}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    -X POST

  if [[ "$verbose" == "true" ]]; then
    echo "Successfully sent payload into webhook endpoint."
  fi
fi
