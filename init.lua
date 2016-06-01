-- Init script

wifi.setmode(wifi.STATION)
wifi.sta.config("SSID", "PASSWORD")

-- --Uncomment when you test it:
--dofile('main.lua')
