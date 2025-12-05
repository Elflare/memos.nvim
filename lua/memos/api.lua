local Job = require("plenary.job")
local config = require("memos").config

local M = {}

-- 【新增】URL 编码辅助函数
local function url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = string.gsub(str, " ", "%%20")
	end
	return str
end

local function run_curl(args, on_exit)
	table.insert(args, "-H")
	table.insert(args, "Authorization: Bearer " .. config.token)
	Job:new({ command = "curl", args = args, on_exit = on_exit }):start()
end

function M.get_current_user(callback)
	run_curl({
		"-s",
		"--fail",
		"-X",
		"POST",
		config.host .. "/api/v1/auth/status",
	}, function(job, return_val)
		if return_val == 0 then
			local result_string = table.concat(job:result(), "")
			local data = vim.json.decode(result_string)
			callback(data or nil)
		else
			vim.schedule(function()
				vim.notify("Failed to get user info.", vim.log.levels.ERROR)
			end)
			callback(nil)
		end
	end)
end

function M.list_memos(parent, filter, page_size, pageToken, callback)
	local list_url = config.host .. "/api/v1/memos"
	local params = {}
	table.insert(params, "parent=" .. parent)
	table.insert(params, "page_size=" .. tostring(page_size))
	if pageToken and pageToken ~= "" then
		table.insert(params, "pageToken=" .. pageToken)
	end
	if filter and filter ~= "" then
		-- 1. 构造原始的过滤字符串，例如：content.contains("hello world")
		local raw_filter = 'content.contains("' .. vim.fn.escape(filter, '"') .. '")'
		-- 2. 对整个值进行 URL 编码，变成：content.contains%28%22hello%20world%22%29
		table.insert(params, "filter=" .. url_encode(raw_filter))
	end
	list_url = list_url .. "?" .. table.concat(params, "&")

	run_curl({
		"-s",
		"--fail",
		"-X",
		"GET",
		list_url,
	}, function(job, return_val)
		if return_val == 0 then
			local result_string = table.concat(job:result(), "")
			local data = vim.json.decode(result_string)
			callback({ memos = data.memos or {}, nextPageToken = data.nextPageToken or "" })
		else
			vim.schedule(function()
				vim.notify("Failed to fetch memos.", vim.log.levels.ERROR)
			end)
			callback(nil)
		end
	end)
end

-- 【修改】让 create_memo 的回调函数返回新创建的 memo 对象
function M.create_memo(content, callback)
	local create_url = config.host .. "/api/v1/memos"
	local json_data = vim.json.encode({ content = content })
	run_curl({
		"-s",
		"--fail",
		"-X",
		"POST",
		create_url,
		"-H",
		"Content-Type: application/json",
		"--data",
		json_data,
	}, function(job, return_val)
		if return_val == 0 then
			local result_string = table.concat(job:result(), "")
			local new_memo = vim.json.decode(result_string)
			callback(new_memo)
		else
			callback(nil)
		end
	end)
end

function M.update_memo(memo_name, content, callback)
	local update_url = config.host .. "/api/v1/" .. memo_name
	local json_data = vim.json.encode({ content = content })
	run_curl({
		"-s",
		"--fail",
		"-X",
		"PATCH",
		update_url,
		"-H",
		"Content-Type: application/json",
		"--data",
		json_data,
	}, function(job, return_val)
		callback(return_val == 0)
	end)
end

function M.delete_memo(memo_name, callback)
	local delete_url = config.host .. "/api/v1/" .. memo_name
	run_curl({
		"-s",
		"--fail",
		"-X",
		"DELETE",
		delete_url,
	}, function(job, return_val)
		callback(return_val == 0)
	end)
end

return M
