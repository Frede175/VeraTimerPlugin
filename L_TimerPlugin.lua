json = require('json')

package.path = '../?.lua;'..package.path

 -- String id for sensor
local Sensor_SID = "urn:micasaverde-com:serviceId:SecuritySensor1"
 -- String id for switch
local S_SID = "urn:upnp-org:serviceId:SwitchPower1"
 -- Delay for check
local Delay = 10

local tpConfig
local SensorTable = {}
local RoomsOn = {}
local TimeOn = {}

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
  luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", lul_arguments,deviceID)
end

function GetSwitchTargetLevel(deviceID)
	return luup.variable_get(S_SID, "Status", deviceID) == "1"
end

function Timer(room)

	local isSwitchOn = false
	if (RoomsOn[room] ~= true) then
		RoomsOn[room] = true
		SetRoom(room, 1)
		isSwitchOn = true
	end
	if (TimeOn[room] == nil) then TimeOn[room] = 0 end

	for k,value in pairs(tpConfig[room]["switchsID"]) do
		if (GetSwitchTargetLevel(tonumber(value))) then isSwitchOn = true end
	end

	if (isSwitchOn) then
		local isTripped = false
		for k,value in pairs(tpConfig[room]["sensorsID"]) do
			if SensorTable[tonumber(value)] == 1 then isTripped = true end
		end

		if (isTripped) then
			TimeOn[room] = 0
			luup.call_timer("Timer", 1, "10", "", room)
		else
			TimeOn[room] = TimeOn[room] + Delay
			if TimeOn[room] >= tonumber(tpConfig[room]["timeOn"]) then
				RoomsOn[room] = false
				SetRoom(room, 0)
			else
				luup.call_timer("Timer", 1, "10", "", room)
			end
		end

	else
		RoomsOn[room] = false
		SetRoom(room, 0)
	end

end

function SensorWatch(dev_id, service, variable, old_val, new_val)
	SensorTable[dev_id] = tonumber(new_val)
	if (tonumber(new_val) == 1) then
		local rooms = getRoomsFromSensor(dev_id)
		for k,value in pairs(rooms) do
			if RoomsOn[value] ~= true then Timer(value) else TimeOn[value] = 0 end
		end
	end
end


function SetupSensorWatch()
	for k,data in pairs(tpConfig) do
		for k1,ID in pairs(data["sensorsID"]) do
			if (SensorTable[tonumber(ID)] == nil) then
				SensorTable[tonumber(ID)] = 0
				luup.variable_watch("SensorWatch", Sensor_SID, "Tripped",  tonumber(ID))
			end
		end
	end
end

 -- Function called on device startup
function tpStartup()
	luup.log("Startup")
	GetTpConfig()
	SetupSensorWatch()
	luup.log("Startup complete!")
end
