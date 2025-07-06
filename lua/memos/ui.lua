local api = require("memos.api")
local config = require("memos").config

local M = {}

local memos_cache = {}
local buf_id = nil
local current_page_token = nil
local current_user = nil
local current_filter = nil

function M.render_memos(data, append)
	vim.schedule(function()
		if not buf_id or not vim.api.nvim_buf_is_valid(buf_id) then
			return
		end
		local new_memos = data.memos or {}
		current_page_token = data.nextPageToken or ""
		if append then
			memos_cache = vim.list_extend(memos_cache, new_memos)
		else
			memos_cache = new_memos
		end
		local lines = {}
		local k = config.keymaps.list
		if #memos_cache == 0 then
			local help = string.format(
				"No memos found. Press '%s' to refresh, '%s' to add, or '%s' to quit.",
				k.refresh_list,
				k.add_memo,
				k.quit
			)
			table.insert(lines, help)
		else
			for i, memo in ipairs(memos_cache) do
				local first_line = memo.content:match("^[^\n]*")
				local display_time = memo.displayTime:sub(1, 10)
				table.insert(lines, string.format("%d. [%s] %s", i, display_time, first_line))
			end
		end
		if current_page_token ~= "" then
			table.insert(lines, "...")
			table.insert(lines, string.format("(Press '%s' to load more)", k.next_page))
		end
		vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(buf_id, "modifiable", false)
	end)
end

function M.setup_buffer_for_editing()
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.buflisted = true
	vim.bo.filetype = "markdown"

	vim.b.memos_original_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

	local save_key_string = ""
	if config.keymaps.buffer.save and config.keymaps.buffer.save ~= "" then
		save_key_string = string.format(" or %s", config.keymaps.buffer.save)
	end

	if vim.b.memos_memo_name then
		vim.notify("Editing memo. Use :MemosSave" .. save_key_string .. " to save.")
	else
		vim.notify("📝 New memo. Use :MemosSave" .. save_key_string .. " to create.")
	end

	vim.api.nvim_buf_create_user_command(0, "MemosSave", 'lua require("memos.ui").save_or_create_dispatcher()', {})
	if config.keymaps.buffer.save and config.keymaps.buffer.save ~= "" then
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			config.keymaps.buffer.save,
			"<Cmd>MemosSave<CR>",
			{ noremap = true, silent = true }
		)
	end

	if config.auto_save then
		local group = vim.api.nvim_create_augroup("MemosAutoSave", { clear = true })
		vim.api.nvim_create_autocmd("InsertLeave", {
			group = group,
			buffer = 0,
			callback = function()
				M.check_and_auto_save()
			end,
		})
		vim.api.nvim_create_autocmd("CursorHold", {
			group = group,
			buffer = 0,
			callback = function()
				M.check_and_auto_save()
			end,
		})
	end
end

function M.open_memo_for_edit(memo, open_cmd)
	local first_line = memo.content:match("^[^\n]*")
	local buffer_name = "memos/"
		.. memo.name:gsub("memos/", "")
		.. "/"
		.. first_line:gsub("[/\\]", "_"):sub(1, 50)
		.. ".md"
	local existing_bufnr = vim.fn.bufnr(buffer_name)

	if existing_bufnr ~= -1 and vim.api.nvim_buf_is_loaded(existing_bufnr) then
		local win_id = vim.fn.bufwinid(existing_bufnr)
		if win_id ~= -1 then
			vim.api.nvim_set_current_win(win_id)
		else
			vim.api.nvim_set_current_buf(existing_bufnr)
		end
	else
		vim.cmd(open_cmd)
		vim.api.nvim_buf_set_name(0, buffer_name)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(memo.content, "\n"))
		vim.b.memos_memo_name = memo.name
		M.setup_buffer_for_editing()
	end
end

function M.check_and_auto_save()
	if vim.b.memos_original_content == nil then
		return
	end
	local current_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	if vim.b.memos_original_content ~= current_content then
		M.save_or_create_dispatcher()
	end
end

function M.save_or_create_dispatcher()
	local bufnr_to_save = vim.api.nvim_get_current_buf()
	local memo_name = vim.b.memos_memo_name
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr_to_save, 0, -1, false), "\n")

	if content == "" then
		vim.notify("Memo is empty, not sending.", vim.log.levels.WARN)
		return
	end

	if memo_name then
		-- 更新逻辑 (保持不变，工作正常)
		api.update_memo(memo_name, content, function(success)
			if success then
				vim.schedule(function()
					vim.notify("✅ Memo updated successfully!")
					if vim.api.nvim_buf_is_valid(bufnr_to_save) then
						vim.b[bufnr_to_save].memos_original_content = content
					end
				end)
				M.refresh_list_silently()
			end
		end)
	else
		api.create_memo(content, function(new_memo)
			if new_memo and new_memo.name then
				vim.schedule(function()
					vim.notify("✅ Memo created successfully!")
					M.show_memos_list(current_filter)
					-- 立即重新打开刚刚创建的 memo，进入编辑模式
					vim.schedule(function()
						M.open_memo_for_edit(new_memo, "enew")
					end)
				end)
			else
				vim.schedule(function()
					vim.notify("❌ Failed to create memo.", vim.log.levels.ERROR)
				end)
			end
		end)
	end
end

function M.refresh_list_silently()
	if not current_user or not current_user.name then
		return
	end
	api.list_memos(current_user.name, current_filter, config.pageSize, nil, function(data)
		M.render_memos(data, false)
	end)
end

function M.create_memo_in_buffer()
	vim.cmd("enew")
	vim.b.memos_memo_name = nil
	-- 使用一个带时间戳的、独一无二的临时名字，防止冲突
	vim.api.nvim_buf_set_name(0, "memos/new_memo_" .. vim.fn.strftime("%s"))
	M.setup_buffer_for_editing()
end

function M.show_memos_list(filter)
	current_filter = filter
	local should_create_buf = true
	if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
		should_create_buf = false
	else
		buf_id = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_name(buf_id, " Memos")
		vim.bo[buf_id].buftype = "nofile"
		vim.bo[buf_id].swapfile = false
		vim.bo[buf_id].filetype = "memos_list"
		vim.bo[buf_id].modifiable = false
	end

	local win_id = vim.fn.bufwinid(buf_id)
	if win_id ~= -1 then
		vim.api.nvim_set_current_win(win_id)
	else
		vim.api.nvim_set_current_buf(buf_id)
	end

	vim.schedule(function()
		vim.notify("Getting user info...")
	end)
	api.get_current_user(function(user)
		if user and user.name then
			current_user = user
			vim.schedule(function()
				vim.notify("Fetching memos for " .. user.name .. "...")
			end)
			api.list_memos(user.name, current_filter, config.pageSize, nil, function(data)
				M.render_memos(data, false)
			end)
		else
			vim.schedule(function()
				vim.notify("Could not get user, aborting fetch.", vim.log.levels.ERROR)
			end)
		end
	end)

	local function set_keymap(key, command)
		if key and key ~= "" then
			vim.api.nvim_buf_set_keymap(buf_id, "n", key, command, { noremap = true, silent = true })
		end
	end

	if config.keymaps and config.keymaps.list then
		local list_keymaps = config.keymaps.list
		set_keymap(list_keymaps.edit_memo, '<Cmd>lua require("memos.ui").edit_selected_memo()<CR>')
		set_keymap(list_keymaps.vsplit_edit_memo, '<Cmd>lua require("memos.ui").edit_selected_memo_in_vsplit()<CR>')
		set_keymap(list_keymaps.quit, "<Cmd>bdelete!<CR>")
		set_keymap(list_keymaps.search_memos, '<Cmd>lua require("memos.ui").search_memos()<CR>')
		set_keymap(list_keymaps.refresh_list, '<Cmd>lua require("memos.ui").show_memos_list()<CR>')
		set_keymap(list_keymaps.next_page, '<Cmd>lua require("memos.ui").load_next_page()<CR>')
		set_keymap(list_keymaps.add_memo, '<Cmd>lua require("memos.ui").create_memo_in_buffer()<CR>')
		set_keymap(list_keymaps.delete_memo, '<Cmd>lua require("memos.ui").confirm_delete_memo()<CR>')
		set_keymap(list_keymaps.delete_memo_visual, '<Cmd>lua require("memos.ui").confirm_delete_memo()<CR>')
	end
end

function M.load_next_page()
	if not current_page_token or current_page_token == "" then
		vim.notify("No more pages to load.", vim.log.levels.INFO)
		return
	end
	if not current_user or not current_user.name then
		vim.notify("User info not available.", vim.log.levels.WARN)
		return
	end
	vim.schedule(function()
		vim.notify("Loading next page...")
	end)
	api.list_memos(current_user.name, current_filter, config.pageSize, current_page_token, function(data)
		M.render_memos(data, true)
	end)
end

function M.edit_selected_memo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local selected_memo = memos_cache[line_num]
	if selected_memo then
		M.open_memo_for_edit(selected_memo, "enew")
	end
end

function M.edit_selected_memo_in_vsplit()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local selected_memo = memos_cache[line_num]
	if selected_memo then
		M.open_memo_for_edit(selected_memo, "vsplit | enew")
	end
end

function M.confirm_delete_memo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local selected_memo = memos_cache[line_num]
	if not selected_memo then
		return
	end
	local choice = vim.fn.confirm("Delete this memo?\n[" .. selected_memo.content:sub(1, 50) .. "...]", "&Yes\n&No", 2)
	if choice == 1 then
		api.delete_memo(selected_memo.name, function(success)
			if success then
				vim.schedule(function()
					vim.notify("✅ Memo deleted.")
					M.show_memos_list(current_filter)
				end)
			else
				vim.schedule(function()
					vim.notify("❌ Failed to delete memo.", vim.log.levels.ERROR)
				end)
			end
		end)
	end
end

function M.search_memos()
	vim.ui.input({ prompt = "Search Memos: " }, function(input)
		M.show_memos_list(input or "")
	end)
end

return M
