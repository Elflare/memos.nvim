local M = {}

M.config = {
	host = nil,
	token = nil,
	auto_save = false,
	page_size = 50,
	-- 【新增】窗口配置
	window = {
		enable_float = true, -- 默认为 false，设为 true 则开启浮动窗口
		width = 0.85, -- 宽度占屏幕比例
		height = 0.85, -- 高度占屏幕比例
		border = "rounded", -- 边框样式: "single", "double", "rounded", "solid", "shadow"
	},
	keymaps = {
		start_memos = "<leader>mm",
		-- 在列表窗口中的快捷键
		list = {
			add_memo = "a",
			delete_memo = "d",
			delete_memo_visual = "dd",
			edit_memo = "<CR>",
			vsplit_edit_memo = "<Tab>",
			search_memos = "s",
			refresh_list = "r",
			next_page = ".",
			quit = "q",
		},
		-- 在编辑和创建窗口中的快捷键
		buffer = {
			save = "<leader>ms",
            back_to_list = '<Esc>'
		},
	},
}

local config_dir = vim.fn.stdpath("data") .. "/memos.nvim"
local config_file_path = config_dir .. "/memos_config.json"

-- 【修改】全新的、能处理 host 和 token 的交互式配置函数
local function prompt_for_config()
	local function prompt_for_token()
		vim.ui.input({
			prompt = "Memos Access Token:",
			hide = true,
		}, function(token)
			if token and token ~= "" then
				M.config.token = token
				local choice = vim.fn.confirm("Save host and token for future sessions?", "&Yes\n&No", 2)
				if choice == 1 then
					vim.fn.mkdir(config_dir, "p")
					-- 将 host 和 token 一起存入 JSON 文件
					local config_to_save = {
						host = M.config.host,
						token = M.config.token,
					}
					vim.fn.writefile({ vim.json.encode(config_to_save) }, config_file_path)
					vim.notify("Host and token saved permanently.", vim.log.levels.INFO)
				end
			else
				vim.notify("No token entered. Memos plugin will not work.", vim.log.levels.ERROR)
			end
		end)
	end

	if not M.config.host then
		vim.ui.input({
			prompt = "Memos Host URL (e.g., http://127.0.0.1:5230):",
		}, function(host)
			if host and host ~= "" then
				M.config.host = host
				-- 获取到 host 后，接着获取 token
				prompt_for_token()
			else
				vim.notify("No host entered. Memos plugin will not work.", vim.log.levels.ERROR)
			end
		end)
	else
		-- 如果 host 已存在，只获取 token
		prompt_for_token()
	end
end

function M.setup(opts)
	-- 1. 先加载默认配置
	local final_config = vim.deepcopy(M.config)

	-- 2. 加载文件中的配置
	if vim.fn.filereadable(config_file_path) == 1 then
		local file_content = vim.fn.readfile(config_file_path)
		if file_content and #file_content > 0 and file_content[1] ~= "" then
			local saved_config = vim.json.decode(file_content[1])
			final_config = vim.tbl_deep_extend("force", final_config, saved_config)
		end
	end

	-- 3. 加载环境变量 (优先级高于文件)
	local token_from_env = os.getenv("MEMOS_TOKEN")
	if token_from_env and token_from_env ~= "" then
		final_config.token = token_from_env
	end
	local host_from_env = os.getenv("MEMOS_HOST")
	if host_from_env and host_from_env ~= "" then
		final_config.host = host_from_env
	end

	-- 4. 加载用户在 setup() 中直接提供的配置 (优先级最高)
	final_config = vim.tbl_deep_extend("force", final_config, opts or {})

	M.config = final_config
end

-- 【修改】确保在执行任何操作前，配置是完整的
local function ensure_config(callback)
	if M.config.host and M.config.token then
		callback()
	else
		prompt_for_config()
	end
end

function M.create_memo()
	ensure_config(function()
		require("memos.ui").create_memo_in_buffer()
	end)
end

function M.show_list()
	ensure_config(function()
		require("memos.ui").show_memos_list()
	end)
end

return M
