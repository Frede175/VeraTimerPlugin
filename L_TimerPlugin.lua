json = require('json')

package.path = '../?.lua;'..package.path

 -- String id for sensor
local Sensor_SID = "urn:micasaverde-com:serviceId:SecuritySensor1"
 -- String id for switch
local S_SID = "urn:upnp-org:serviceId:SwitchPower1"


local tpConfig
local SensorTable = {}

 -- Sets the config from the json
function tpSetConfig(data)
	tpConfig = json.decode(data)
end


 -- Make sure the config is loaded
function GetTpConfig()
	if (tpConfig == nil) then
		tpSetConfig(tpData)
		luup.log("tpConfig is set")
	end
end


function turnOnSwitch(deviceID)
	-- body
end

function turnOffSwitch(deviceID)
	-- body
end

function Timer()
	-- body
end

function SensorWatch(dev_id, service, variable, old_val, new_val)
	-- body
	SensorTable(tonumber(ID)) = new_val
	luup.log("Sensor: " .. dev_id .. ", new value: " .. new_val)
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

end

 -- Table for the sensor with deviceID as index and trigged as value.
