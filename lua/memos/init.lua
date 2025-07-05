local M = {}

M.config = {
	host = nil,
	token = nil,
	pageSize = 50,
	keymaps = {
		start_memos = "<leader>mm",
		-- 在列表窗口中的快捷键
		list = {
			add_memo = "a",
			delete_memo = "d",
			delete_memo_visual = "dd", -- 和 d 功能一样，为了符合习惯
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
		},
	},
}

function M.setup(opts)
	-- 使用 "force" 策略，并将默认配置放在前面，用户的配置在后面
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	if not M.config.host or not M.config.token then
		vim.notify("Memos: `host` and `token` must be configured.", vim.log.levels.ERROR)
	end

	if M.config.keymaps.start_memos then
		vim.api.nvim_set_keymap(
			"n",
			M.config.keymaps.start_memos,
			"<Cmd>Memos<CR>",
			{ noremap = true, silent = true, desc = "Open Memos list" }
		)
	end
end

function M.create_memo()
	require("memos.ui").create_memo_in_buffer()
end

function M.show_list()
	require("memos.ui").show_memos_list()
end

return M
