------------------------------------------------
-- This file is part of the luci-app-ssr-plus subscribe.lua
-- @author William Chan <root@williamchan.me>
-- 2020/03/15 by chongshengB
-- 2021/05/13 by zusterben
------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local tinsert = table.insert
local ssub, slen, schar, sbyte, sformat, sgsub = string.sub, string.len, string.char, string.byte, string.format, string.gsub
local b64decode = nixio.bin.b64decode
local cache = {}
local nodeResult = setmetatable({}, {__index = cache}) -- update result
local subscribe_url = {}
local i = 1
-- base64
local function base64Decode(text)
	local raw = text
	if not text then return '' end
	text = text:gsub("%z", "")
	text = text:gsub("_", "/")
	text = text:gsub("-", "+")
	local mod4 = #text % 4
	text = text .. string.sub('====', mod4 + 1)
	local result = b64decode(text)
	
	if result then
		return result:gsub("%z", "")
	else
		return raw
	end
end
local ssrindext = io.popen('dbus list ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -rn|head -n1')
local ssrindex = ssrindext:read("*all")
if #ssrindex == 0 then
	ssrindex = 1
else
	ssrindex = tonumber(ssrindex) + 1
end
local ssrmodet = io.popen('dbus get ssr_subscribe_mode')
local ssrmode = tonumber(ssrmodet:read("*all")) 
local tfilter_words = io.popen("dbus get ss_basic_exclude")
local filter_words = tfilter_words:read("*all")
local tsave_words = io.popen("dbus get ss_basic_include")
local save_words = tsave_words:read("*all")
local tsubscribe_url = io.popen("dbus get ss_online_links | base64 -d")
local subscribe_url2 = tsubscribe_url:read("*all")
for w in subscribe_url2:gmatch("%C+") do 
table.insert(subscribe_url, w) 
i = i+1
end

local log = function(...)
	print(os.date("%Y-%m-%d %H:%M:%S ") .. table.concat({...}, " "))
end
local encrypt_methods_ss = {
	-- aead
	"aes-128-gcm",
	"aes-192-gcm",
	"aes-256-gcm",
	"chacha20-ietf-poly1305",
	"xchacha20-ietf-poly1305"
	--[[ stream
	"table",
	"rc4",
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",
	"bf-cfb",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf" ]]
}
-- 分割字符串
local function split(full, sep)
	full = full:gsub("%z", "") -- 这里不是很清楚 有时候结尾带个\0
	local off, result = 1, {}
	while true do
		local nStart, nEnd = full:find(sep, off)
		if not nEnd then
			local res = ssub(full, off, slen(full))
			if #res > 0 then -- 过滤掉 \0
				tinsert(result, res)
			end
			break
		else
			tinsert(result, ssub(full, off, nStart - 1))
			off = nEnd + 1
		end
	end
	return result
end
-- urlencode
local function get_urlencode(c)
	return sformat("%%%02X", sbyte(c))
end

local function urlEncode(szText)
	local str = szText:gsub("([^0-9a-zA-Z ])", get_urlencode)
	str = str:gsub(" ", "+")
	return str
end

local function get_urldecode(h)
	return schar(tonumber(h, 16))
end
local function UrlDecode(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", get_urldecode)
end

-- trim
local function trim(text)
	if not text or text == "" then
		return ""
	end
	return (sgsub(text, "^%s*(.-)%s*$", "%1"))
end
-- md5
local function md5(content)
	local stdout = io.popen("echo -n '" .. urlEncode(content) .. "'|md5sum|cut -d ' ' -f1")
	local stdout2 = stdout:read("*all")
	-- assert(nixio.errno() == 0)
	return trim(stdout2)
end
-- 检查数组(table)中是否存在某个字符值
-- https://www.04007.cn/article/135.html
local function checkTabValue(tab)
	local revtab = {}
	for k,v in pairs(tab) do
		revtab[v] = true
	end
	return revtab
end
-- 处理数据
local function processData(szType, content)
	local result = {type = szType, local_port = 3333, kcp_param = '--nocomp'}
	if szType == 'ssr' then
		local dat = split(content, "/%?")
		local hostInfo = split(dat[1], ':')
		result.server = hostInfo[1]
		result.server_port = hostInfo[2]
		result.protocol = hostInfo[3]
		result.encrypt_method = hostInfo[4]
		result.obfs = hostInfo[5]
		result.password = nixio.bin.b64encode(base64Decode(hostInfo[6]))
		local params = {}
		for _, v in pairs(split(dat[2], '&')) do
			local t = split(v, '=')
			params[t[1]] = t[2]
		end
		result.obfs_param = base64Decode(params.obfsparam)
		result.protocol_param = base64Decode(params.protoparam)
		local group = base64Decode(params.group)
		if group then
			result.alias = "[" .. group .. "] "
		end
		result.alias = result.alias .. base64Decode(params.remarks)
	elseif szType == 'vmess' then
		local info = cjson.decode(content)
		result.type = 'v2ray'
		result.v2ray_protocol = 'vmess'
		result.server = info.add
		result.server_port = info.port
		if info.net == 'kcp' then
			info.net = 'mkcp'
		end
		result.transport = info.net
		result.alter_id = info.aid or "0"
		result.vmess_id = info.id
		result.alias = info.ps
		-- result.mux = 1
		-- result.concurrency = 8
		if info.net == 'ws' then
			result.ws_host = info.host and info.host or ""
			result.ws_path = info.path and info.path or ""
		end
		if info.net == 'h2' then
			result.h2_host = info.host and info.host or ""
			result.h2_path = info.path and info.path or ""
		end
		if info.net == 'tcp' then
			if info.type and info.type ~= "http" then
				info.type = "none"
			end
			result.tcp_guise = info.type
			result.http_host = info.host and info.host or ""
			result.http_path = info.path and info.path or ""
		end
		if info.net == 'mkcp' then
			result.kcp_guise = info.type
			result.mtu = 1350
			result.tti = 50
			result.uplink_capacity = 5
			result.downlink_capacity = 20
			result.read_buffer_size = 2
			result.write_buffer_size = 2
		end
		if info.net == 'quic' then
			result.quic_guise = info.type
			result.quic_key = info.key
			result.quic_security = info.securty
		end
		if info.security then
			result.security = info.security
		elseif info.scy then
			result.security = info.scy
		else
			result.security = "auto"
		end
		if info.tls == "tls" or info.tls == "1" then
			result.tls = "1"
			result.tls_host = info.host and info.host or (info.sni and info.sni or "")
			result.insecure = 1
		else
			result.tls = "0"
		end
	elseif szType == "ss" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(base64Decode(info), "@")
		local hostInfoLen = #hostInfo
		local host = nil
		local userinfo = nil
		if hostInfoLen > 2 then
			host = split(hostInfo[hostInfoLen], ":")
			userinfo = {}
			for i = 1, hostInfoLen - 1 do
				tinsert(userinfo, hostInfo[i])
			end
			userinfo = table.concat(userinfo, '@')
		else
			host = split(hostInfo[2], ":")
			userinfo = base64Decode(hostInfo[1])
		end
		local method = userinfo:sub(1, userinfo:find(":") - 1)
		local password = userinfo:sub(userinfo:find(":") + 1, #userinfo)
		result.alias = UrlDecode(alias)
		result.type = "ss"
		result.server = host[1]
		if host[2]:find("/%?") then
			local query = split(host[2], "/%?")
			result.server_port = query[1]
			local params = {}
			for _, v in pairs(split(query[2], '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			if params.plugin then
				local plugin_info = UrlDecode(params.plugin)
				local idx_pn = plugin_info:find(";")
				if idx_pn then
					result.plugin = plugin_info:sub(1, idx_pn - 1)
					result.plugin_opts = plugin_info:sub(idx_pn + 1, #plugin_info)
				else
					result.plugin = plugin_info
				end
				if result.plugin == "simple-obfs" then
					result.plugin = "obfs-local"
				end
			end
		else
			result.server_port = host[2]:gsub("/","")
		end
		if not result.plugin then
			result.plugin = "none"
			result.plugin_opts = ""
		end
		if checkTabValue(encrypt_methods_ss)[method] then
			result.encrypt_method_ss = method
			result.password = nixio.bin.b64encode(password)
		else
			-- 1202 年了还不支持 SS AEAD 的屑机场
			--result = nil
			result.encrypt_method_ss = method
			result.password = nixio.bin.b64encode(password)
		end
	elseif szType == "sip008" then
		result.type = "ss"
		result.server = content.server
		result.server_port = content.server_port
		result.password = nixio.bin.b64encode(content.password)
		result.encrypt_method_ss = content.method
		result.plugin = content.plugin or "none"
		result.plugin_opts = content.plugin_opts and content.plugin_opts or ""
		result.alias = content.remarks
	elseif szType == "ssd" then
		result.type = "ss"
		result.server = content.server
		result.server_port = content.port
		result.password = nixio.bin.b64encode(base64Decode(content.password))
		result.encrypt_method_ss = content.encryption
		result.plugin = content.plugin
		result.plugin_opts = content.plugin_options
		if result.plugin == "simple-obfs" then
			result.plugin = "obfs-local"
		end
		result.alias = "[" .. content.airport .. "] " .. content.remarks
	elseif szType == "trojan" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(info, "@")
		local host = split(hostInfo[2], ":")
		local userinfo = hostInfo[1]
		local password = UrlDecode(userinfo)
		result.alias = UrlDecode(alias)
		result.type = "v2ray"
		result.v2ray_protocol = "trojan"
		result.server = host[1]
		-- 按照官方的建议 默认验证ssl证书
		result.insecure = "0"
		result.tls = "1"
		if host[2]:find("?") then
			local query = split(host[2], "?")
			result.server_port = query[1]
			local params = {}
			for _, v in pairs(split(query[2], '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			if params.sni then
				-- 未指定peer（sni）默认使用remote addr
				result.tls_host = params.sni
			end
		else
			result.server_port = host[2]
			result.tls_host = ""
		end
		result.password = nixio.bin.b64encode(password)
		result.transport = "tcp"
	elseif szType == "vless" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(info, "@")
		local host = split(hostInfo[2], ":")
		local uuid = UrlDecode(hostInfo[1])
		if host[2]:find("?") then
			local query = split(host[2], "?")
			local params = {}
			for _, v in pairs(split(UrlDecode(query[2]), '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			result.alias = UrlDecode(alias)
			result.type = 'v2ray'
			result.v2ray_protocol = 'vless'
			result.server = host[1]
			result.server_port = query[1]
			result.vmess_id = uuid
			result.vless_encryption = params.encryption and params.encryption or "none"
			if params.type == 'kcp' then
				params.type = 'mkcp'
			end
			result.transport = params.type and (params.type == 'http' and 'h2' or params.type) or "tcp"
			if not params.type or params.type == "tcp" then
				if params.security == "xtls" then
					result.xtls = "1"
					result.tls_host = params.sni and params.sni or host[1]
					result.vless_flow = params.flow
				else
					result.xtls = "0"
				end
			end
			if params.type == 'ws' then
				result.ws_host = params.host
				result.ws_path = params.path and params.path or ""
			end
			if params.type == 'http' then
				result.h2_host = params.host and params.host or host[1]
				result.h2_path = params.path and params.path or ""
			end
			if params.type == 'mkcp' then
				result.kcp_guise = params.headerType and params.headerType or "none"
				result.mtu = 1350
				result.tti = 50
				result.uplink_capacity = 5
				result.downlink_capacity = 20
				result.read_buffer_size = 2
				result.write_buffer_size = 2
				result.seed = params.seed
			end
			if params.type == 'quic' then
				result.quic_guise = params.headerType and params.headerType or "none"
				result.quic_key = params.key
				result.quic_security = params.quicSecurity and params.quicSecurity or "none"
			end
			if params.type == 'grpc' then
				result.serviceName = params.serviceName
			end
			
			if params.security == "tls" then
				result.tls = "1"
				result.tls_host = params.sni and params.sni or host[1]
			else
				result.tls = "0"
			end
		else
			result.server_port = host[2]
		end
	end
	if not result.alias then
		if result.server and result.server_port then
			result.alias = result.server .. ':' .. result.server_port
		else
			result.alias = "NULL"
		end
	end
	-- alias 不参与 hashkey 计算
	local alias = result.alias
	result.alias = nil
	local switch_enable = result.switch_enable
	result.switch_enable = nil
	--print(result)
	result.hashkey = md5(cjson.encode(result))
	--哪个智障居然用'"\%$
	result.alias = alias:gsub("\"", "_"):gsub("'", "_"):gsub("\\", "_"):gsub("%%", "_"):gsub("%$", "_"):gsub("	", "_")
	result.switch_enable = switch_enable
	return result
end
-- wget
local function wget(url)
	local stdout = io.popen('curl -k -s --connect-timeout 15 --retry 5 "' .. url .. '"')
	local sresult = stdout:read("*all")
	return trim(sresult)
end

local function check_filer(result)
	do
		-- 过滤的关键词列表
		local filter_word = split(filter_words, ",")
		-- 保留的关键词列表
		local check_save = false
		if save_words ~= nil and save_words ~= "" and save_words ~= "NULL" and save_words ~= "\n" then
			check_save = true
		end
		local save_word = split(save_words, ",")
		-- 检查结果
		local filter_result = false
		local save_result = true

		-- 检查是否存在过滤关键词
		for i, v in pairs(filter_word) do
			if tostring(result.alias):find(v) then
				filter_result = true
			end
		end
		-- 检查是否打开了保留关键词检查，并且进行过滤
		if check_save == true then
			for i, v in pairs(save_word) do
				if tostring(result.alias):find(v) then
					save_result = false
				end
			end
		else
			save_result = false
		end
		-- 不等时返回
		if filter_result == true or save_result == true then
			return true
		else
			return false
		end
	end
end

--local execute = function()
	-- exec
	local add, del = 0, 0
	do
		for k, url in ipairs(subscribe_url) do
			local raw = wget(url)
			if #raw > 0 then
				local nodes, szType
				local groupHash = md5(url)
				cache[groupHash] = {}
				tinsert(nodeResult, {})
				local index = #nodeResult
				-- SSD 似乎是这种格式 ssd:// 开头的
				if raw:find('ssd://') then
					szType = 'ssd'
					local nEnd = select(2, raw:find('ssd://'))
					nodes = base64Decode(raw:sub(nEnd + 1, #raw))
					nodes = cjson.decode(nodes)
					local extra = {airport = nodes.airport, port = nodes.port, encryption = nodes.encryption, password = nodes.password}
					local servers = {}
					-- SS里面包着 干脆直接这样
					for _, server in ipairs(nodes.servers) do
						tinsert(servers, setmetatable(server, {__index = extra}))
					end
					nodes = servers
				-- SS SIP008 直接使用 Json 格式
				elseif raw:find('{"configs"') then
					nodes = cjson.decode(raw).configs
					if nodes[1].server and nodes[1].method then
						szType = 'sip008'
					end
				else
					-- ssd 外的格式
					nodes = split(base64Decode(raw):gsub(" ", "_"), "\n")
				end

				for _, v in ipairs(nodes) do
					if v then
						local result
						if szType then
							result = processData(szType, v)
						elseif not szType then
							local node = trim(v)
							local dat = split(node, "://")
							if dat and dat[1] and dat[2] then
								local dat3 = ""
								if dat[3] then
									dat3 = "://" .. dat[3]
								end
								if dat[1] == 'ss' or dat[1] == 'trojan' then
									result = processData(dat[1], dat[2] .. dat3)
								else
									result = processData(dat[1], base64Decode(dat[2]))
								end
							end
						else
							log('跳过未知类型: ' .. szType)
						end
						-- log(result)
						if result then
							-- 中文做地址的 也没有人拿中文域名搞，就算中文域也有Puny Code SB 机场
							if not result.server or not result.server_port or result.alias == "NULL" or check_filer(result) or result.server:match("[^0-9a-zA-Z%-%.%s]") then
								log('丢弃无效节点: ' .. result.type .. ' 节点, ' .. result.alias)
							else
								log('成功解析: ' .. result.type ..' 节点, ' .. result.alias)
								result.grouphashkey = groupHash
								tinsert(nodeResult[index], result)
								cache[groupHash][result.hashkey] = nodeResult[index][#nodeResult[index]]
								if result.type == "ss" then
									os.execute("dbus set ssconf_basic_type_" .. ssrindex .. "='0'")
									os.execute("dbus set ssconf_basic_group_" .. ssrindex .. "='subscribe'")
									os.execute("dbus set ssconf_basic_name_" .. ssrindex .. "='".. result.alias .. "'")
									os.execute("dbus set ssconf_basic_mode_" .. ssrindex .. "='".. ssrmode .. "'")
									os.execute("dbus set ssconf_basic_server_" .. ssrindex .. "='".. result.server .. "'")
									os.execute("dbus set ssconf_basic_port_" .. ssrindex .. "='".. result.server_port .. "'")
									os.execute("dbus set ssconf_basic_method_" .. ssrindex .. "='".. result.encrypt_method_ss .. "'")
									os.execute("dbus set ssconf_basic_password_" .. ssrindex .. "='".. result.password .. "'")
									os.execute("dbus set ssconf_basic_ss_obfs_" .. ssrindex .. "='".. result.plugin .. "'")
									os.execute("dbus set ssconf_basic_ss_obfs_host_" .. ssrindex .. "='".. result.plugin_opts .. "'")
								elseif result.type == "ssr" then
									os.execute("dbus set ssconf_basic_type_" .. ssrindex .. "='1'")
									os.execute("dbus set ssconf_basic_group_" .. ssrindex .. "='subscribe'")
									os.execute("dbus set ssconf_basic_name_" .. ssrindex .. "='".. result.alias .. "'")
									os.execute("dbus set ssconf_basic_mode_" .. ssrindex .. "='".. ssrmode .. "'")
									os.execute("dbus set ssconf_basic_server_" .. ssrindex .. "='".. result.server .. "'")
									os.execute("dbus set ssconf_basic_port_" .. ssrindex .. "='".. result.server_port .. "'")
									os.execute("dbus set ssconf_basic_method_" .. ssrindex .. "='".. result.encrypt_method .. "'")
									os.execute("dbus set ssconf_basic_password_" .. ssrindex .. "='".. result.password .. "'")
									os.execute("dbus set ssconf_basic_ssr_obfs_" .. ssrindex .. "='".. result.obfs .. "'")
									os.execute("dbus set ssconf_basic_ssr_obfs_param_" .. ssrindex .. "='".. result.obfs_param .. "'")
									os.execute("dbus set ssconf_basic_ssr_protocol_" .. ssrindex .. "='".. result.protocol .. "'")
									os.execute("dbus set ssconf_basic_ssr_protocol_param_" .. ssrindex .. "='".. result.protocol_param .. "'")
								elseif result.type == "v2ray" then
									os.execute("dbus set ssconf_basic_type_" .. ssrindex .. "='2'")
									os.execute("dbus set ssconf_basic_group_" .. ssrindex .. "='subscribe'")
									os.execute("dbus set ssconf_basic_name_" .. ssrindex .. "='".. result.alias .. "'")
									os.execute("dbus set ssconf_basic_mode_" .. ssrindex .. "='".. ssrmode .. "'")
									os.execute("dbus set ssconf_basic_server_" .. ssrindex .. "='".. result.server .. "'")
									os.execute("dbus set ssconf_basic_port_" .. ssrindex .. "='".. result.server_port .. "'")
									os.execute("dbus set ssconf_basic_v2ray_mux_enable_" .. ssrindex .. "='0'")
									os.execute("dbus set ssconf_basic_v2ray_use_json_" .. ssrindex .. "='0'")
									if result.v2ray_protocol ~= "trojan" then
										os.execute("dbus set ssconf_basic_v2ray_uuid_" .. ssrindex .. "='".. result.vmess_id .. "'")
									end
									os.execute("dbus set ssconf_basic_v2ray_network_" .. ssrindex .. "='".. result.transport .. "'")
									if result.v2ray_protocol == "vmess" then
										os.execute("dbus set ssconf_basic_v2ray_protocol_" .. ssrindex .. "='".. result.v2ray_protocol .. "'")
										os.execute("dbus set ssconf_basic_v2ray_alterid_" .. ssrindex .. "='".. result.alter_id .. "'")
										os.execute("dbus set ssconf_basic_v2ray_security_" .. ssrindex .. "='".. result.security .. "'")
										if result.transport == "ws" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.ws_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_network_path_" .. ssrindex .. "='".. result.ws_path .. "'")
										elseif result.transport == "h2" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.h2_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_network_path_" .. ssrindex .. "='".. result.h2_path .. "'")
										elseif result.transport == "tcp" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.http_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_headtype_tcp_" .. ssrindex .. "='".. result.tcp_guise .. "'")
										elseif result.transport == "mkcp" then
											os.execute("dbus set ssconf_basic_v2ray_headtype_kcp_" .. ssrindex .. "='".. result.kcp_guise .. "'")
										elseif result.transport == "quic" then
											os.execute("dbus set ssconf_basic_v2ray_quic_guise_" .. ssrindex .. "='".. result.quic_guise .. "'")
											os.execute("dbus set ssconf_basic_v2ray_quic_key_" .. ssrindex .. "='".. result.quic_key .. "'")
											os.execute("dbus set ssconf_basic_v2ray_quic_security_" .. ssrindex .. "='".. result.quic_security .. "'")
										end
										if result.tls == "1" then
											os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='tls'")
											os.execute("dbus set ssconf_basic_v2ray_fingerprint_" .. ssrindex .. "='disable'")
											os.execute("dbus set ssconf_basic_v2ray_network_tlshost_" .. ssrindex .. "='".. result.tls_host .. "'")
										else
											os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='none'")
										end
									elseif result.v2ray_protocol == "vless" then
										os.execute("dbus set ssconf_basic_v2ray_protocol_" .. ssrindex .. "='".. result.v2ray_protocol .. "'")
										--os.execute("dbus set ssconf_basic_v2ray_encryption_" .. ssrindex .. "='".. result.vless_encryption .. "'")
										if result.transport == "ws" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.ws_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_network_path_" .. ssrindex .. "='".. result.ws_path .. "'")
										elseif result.transport == "h2" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.h2_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_network_path_" .. ssrindex .. "='".. result.h2_path .. "'")
										elseif result.transport == "tcp" then
											os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "='".. result.http_host .. "'")
											os.execute("dbus set ssconf_basic_v2ray_headtype_tcp_" .. ssrindex .. "='".. result.tcp_guise .. "'")
										elseif result.transport == "mkcp" then
											os.execute("dbus set ssconf_basic_v2ray_headtype_kcp_" .. ssrindex .. "='".. result.kcp_guise .. "'")
										elseif result.transport == "quic" then
											os.execute("dbus set ssconf_basic_v2ray_quic_guise_" .. ssrindex .. "='".. result.quic_guise .. "'")
											os.execute("dbus set ssconf_basic_v2ray_quic_key_" .. ssrindex .. "='".. result.quic_key .. "'")
											os.execute("dbus set ssconf_basic_v2ray_quic_security_" .. ssrindex .. "='".. result.quic_security .. "'")
										elseif result.transport == "grpc" then
											os.execute("dbus set ssconf_basic_v2ray_grpc_serviceName_" .. ssrindex .. "='".. result.serviceName .. "'")
										end
										if result.xtls == "1" then
											os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='xtls'")
											os.execute("dbus set ssconf_basic_v2ray_network_flow_" .. ssrindex .. "='".. result.vless_flow .. "'")
											os.execute("dbus set ssconf_basic_v2ray_network_tlshost_" .. ssrindex .. "='".. result.tls_host .. "'")
										elseif result.tls == "1" then
											os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='tls'")
											os.execute("dbus set ssconf_basic_v2ray_fingerprint_" .. ssrindex .. "='disable'")
											os.execute("dbus set ssconf_basic_v2ray_network_tlshost_" .. ssrindex .. "='".. result.tls_host .. "'")
										else
											os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='none'")
										end
									elseif result.v2ray_protocol == "trojan" then
										os.execute("dbus set ssconf_basic_v2ray_protocol_" .. ssrindex .. "='".. result.v2ray_protocol .. "'")
										os.execute("dbus set ssconf_basic_password_" .. ssrindex .. "='".. result.password .. "'")
										os.execute("dbus set ssconf_basic_v2ray_network_host_" .. ssrindex .. "=''")
										os.execute("dbus set ssconf_basic_v2ray_headtype_tcp_" .. ssrindex .. "='none'")
										os.execute("dbus set ssconf_basic_v2ray_network_security_" .. ssrindex .. "='tls'")
										os.execute("dbus set ssconf_basic_v2ray_fingerprint_" .. ssrindex .. "='disable'")
										os.execute("dbus set ssconf_basic_v2ray_network_tlshost_" .. ssrindex .. "='".. result.tls_host .. "'")
									else
										log('保存节点信息错误: ' .. result.v2ray_protocol)
									end
								elseif result.type == "trojan" then
									os.execute("dbus set ssconf_basic_type_" .. ssrindex .. "='3'")
									os.execute("dbus set ssconf_basic_group_" .. ssrindex .. "='subscribe'")
									os.execute("dbus set ssconf_basic_name_" .. ssrindex .. "='".. result.alias .. "'")
									os.execute("dbus set ssconf_basic_mode_" .. ssrindex .. "='".. ssrmode .. "'")
									os.execute("dbus set ssconf_basic_server_" .. ssrindex .. "='".. result.server .. "'")
									os.execute("dbus set ssconf_basic_port_" .. ssrindex .. "='".. result.server_port .. "'")
									os.execute("dbus set ssconf_basic_password_" .. ssrindex .. "='".. result.password .. "'")
									os.execute("dbus set ssconf_basic_trojan_sni_" .. ssrindex .. "='".. result.tls_host .. "'")
									os.execute("dbus set ssconf_basic_trojan_mp_enable_" .. ssrindex .. "='0'")
								end
								ssrindex = ssrindex + 1
							end
						end
					end

				end
				log('成功解析节点数量: ' .. #nodes)
			else
				log(url .. ': 获取内容为空')
			end
		end
	end
	-- diff
	do
		if next(nodeResult) == nil then
			log("更新失败，没有可用的节点信息")
			return
		end
		local add = 0
		for k, v in ipairs(nodeResult) do
			for kk, vv in ipairs(v) do
				if not vv._ignore then
					add = add + 1
				end
			end
		end
		log('新增节点数量: ' .. add, '删除节点数量: ' .. del)
		log('订阅更新成功')
	end
--end

