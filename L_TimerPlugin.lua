json = require('json')

package.path = '../?.lua;'..package.path

 -- String id for sensor
local Sensor_SID = "urn:micasaverde-com:serviceId:SecuritySensor1"
 -- String id for switch
local S_SID = "urn:upnp-org:serviceId:SwitchPower1"
 -- Delay for check
local Delay = 10

local tpConfig
local RoomsOn = {}
local SensorTime = {}

 -- Sets the config from the json
function tpSetConfig(data)
	tpConfig = json.decode(data)
end


 -- Make sure the config is loaded
function GetTpConfig()
	if (tpConfig == nil) then
		tpSetConfig(tpData)
	end
end

function getRoomsFromSensor(sensorID)
	local table = {}
	local index = 1
	for k,data in pairs(tpConfig) do
		for k1,ID in pairs(data["sensorsID"]) do
			if tonumber(ID) == sensorID then
				table[index] = k
				index = index + 1
			end
		end
	end
	return table
end

 -- Turns the room on or off.
function SetRoom(room, value)
	for k,ID in pairs(tpConfig[room]["switchsID"]) do
		SetSwitch(tonumber(ID), value)
	end
end


function SetSwitch(deviceID, value)
	lul_arguments = {}
  lul_arguments["newTargetValue"] = value
  --luup.log("Setting device: " .. deviceID .. " to " .. value)
  luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", lul_arguments,deviceID)
end

function GetSwitchTargetLevel(deviceID)
	return luup.variable_get(S_SID, "Status", deviceID) == "1"
end

function IsSensorTriped(deviceID)
	return luup.variable_get(Sensor_SID, "Tripped", deviceID) == "1"
end


function Timer(room)

	local isSwitchOn = false
	if (RoomsOn[room] ~= true) then
		RoomsOn[room] = true
		SetRoom(room, 1)
		isSwitchOn = true
	end

	for k,value in pairs(tpConfig[room]["switchsID"]) do
		if (GetSwitchTargetLevel(tonumber(value))) then isSwitchOn = true end
	end
	if (isSwitchOn) then
		local currentTime = os.time()
		--luup.log("Current time is " .. currentTime)
		
		local shouldBeOn = -1
		for k,value in pairs(tpConfig[room]["sensorsID"]) do
			local isTriped = IsSensorTriped(tonumber(value))
			if (isTriped == true) then
				shouldBeOn = 0
				break
			end
			local lastUpdate = SensorTime[tonumber(value)]
			--luup.log("Last trip on sensor " .. value .. " is " .. lastUpdate)
			if ((currentTime - lastUpdate) < tonumber(tpConfig[room]["timeOn"])) then
				if (shouldBeOn < currentTime - lastUpdate) then
					shouldBeOn = currentTime - lastUpdate
				end
			end
		end

		if (shouldBeOn == -1) then
			RoomsOn[room] = false
			SetRoom(room, 0)
		else 
			--luup.log("Calling timer with delay of: " .. (tonumber(tpConfig[room]["timeOn"]) - shouldBeOn) .. " for room " .. room)
			luup.call_timer("Timer", 1, tostring(tonumber(tpConfig[room]["timeOn"]) - shouldBeOn), "", room)
		end
	else
		RoomsOn[room] = false
		SetRoom(room, 0)
	end

end

function SensorWatch(dev_id, service, variable, old_val, new_val)
	if (tonumber(new_val) == 1) then
		local rooms = getRoomsFromSensor(dev_id)
		for k,value in pairs(rooms) do
			if RoomsOn[value] ~= true then Timer(value) end
		end
	end
	if (tonumber(old_val) == 1 and tonumber(new_val) == 0) then
		--luup.log("Setting sensor lastUpdate to " .. os.time())
		SensorTime[tonumber(dev_id)] = os.time()
	end
end

function SetupSensorWatch()
	for k,data in pairs(tpConfig) do
		for k1,ID in pairs(data["sensorsID"]) do
			luup.variable_watch("SensorWatch", Sensor_SID, "Tripped",  tonumber(ID))
		end
	end
end

 -- Function called on device startup
function tpStartup()
	luup.log("Time - Startup")
	GetTpConfig()
	SetupSensorWatch()
	luup.log("Time - Startup complete!")
end
