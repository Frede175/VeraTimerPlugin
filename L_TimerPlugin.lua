json = require('json')


local tpConfig

 -- Sets the config from the json
function tpSetConfig(data)
	tpConfig = json.decode(data)
end


 -- Make sure the config is loaded
function GetTpConfig()
	if (tpConfig == nil) then
		tpConfig = tpSetConfig(tpData)
	end
end


 -- Function called on device startup
function tpStartup()
	GetTpConfig()

	

end