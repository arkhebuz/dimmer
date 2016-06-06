-- Program script
-- CHANGE BROKER DATA
USER =
PASSWORD =
ADDRESS =
PORT =

-- Global program variables
LIE_MODE = 2
PREV_VAL = 0
CONNECTED = 0
ADC_TARGET = 200
ERR_SUM = 0
ERR_DIF = 0
kp = 1
ki = 1000000
kd = 1000000


-- init mqtt client with keepalive timer 120sec
m = mqtt.Client("clientid", 120, USER, PASSWORD)
-- on publish message receive event
m:on("message", function(conn, topic, message)
  print(topic .. ":")
  print(message)
  if message ~= nil and topic == "/light_level" then
    LIE_MODE = 3
    -- convert message to duty
    local duty = tonumber(message)
    if duty > 1023 then
      duty = 1023
    end
    pwm.setduty(11, duty)

  elseif message ~= nil and  topic == "/mode" then
    LIE_MODE = tonumber(message)
    if LIE_MODE == 1 then
      pwm.setduty(11, 1023)
    elseif LIE_MODE == 0 then
      pwm.setduty(11, 0)
    end

  elseif message ~= nil and  topic == "/target" then
    if LIE_MODE == 2 then
      ADC_TARGET = tonumber(message)
    end
  end
end)


tmr.alarm(1, 1500, 1, function()
  if wifi.sta.status() == 5 then
    tmr.stop(1)
    -- m:connect(host, port, secure, auto_reconnect, function(client) end)
    m:connect(ADDRESS, PORT, 0, 1, function(conn)
      CONNECTED = 1
      m:subscribe("/light_level", 0)
      m:subscribe("/mode", 0)
      m:subscribe("/target", 0)
    end)
  end
end)


-- PINS:
-- pin index 11 - PWM mosfet
-- pin index 6 - control button
-- pin index 12 - overheat interrupt
pwm.setup(11, 1000, 0)
pwm.start(11)

gpio.mode(6, gpio.INT, gpio.PULLUP)
gpio.trig(6, "down", function(level)
  if LIE_MODE == 0 then
    -- Enable continous lit mode
    LIE_MODE = 1
    pwm.setduty(11, 1023)

  elseif LIE_MODE == 1 then
    -- Enable auto mode
    LIE_MODE = 2

  elseif LIE_MODE == 2 then
    -- Enable shutdown mode
    LIE_MODE = 0
    pwm.setduty(11, 0)

  elseif LIE_MODE == 3 then
    -- Go from MQTT mode to shutdown
    LIE_MODE = 0
    pwm.setduty(11, 0)
  end
end)

gpio.mode(12, gpio.INT, gpio.PULLUP)
gpio.trig(12, "down", function(level)
  LIE_MODE = 0
  pwm.setduty(11, 0)
  if CONNECTED then
    m:publish("/errors", "OVERHEAT", 0, 0)
  end
end)


tmr.alarm(0, 100, tmr.ALARM_AUTO, function()
  if LIE_MODE == 2 then
    local val = adc.read(0)
    val = (PREV_VAL*4 + val)/5   -- filtr na intach

    local auto_error = ADC_TARGET - val
    ERR_SUM = ERR_SUM + 100*auto_error
    ERR_DIF = (auto_error -100*(ADC_TARGET - PREV_VAL))/100
    local pwmff = auto_error/kp + ERR_SUM/ki + ERR_DIF/kd

    PREV_VAL = val
    if pwmff > 1023 then
      pwmff = 1023
    end
    pwm.setduty(11, pwmff)
  end
end)

