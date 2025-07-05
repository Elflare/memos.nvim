-- 创建新 Memo 的命令
vim.api.nvim_create_user_command(
  'MemosCreate',
  function()
    require('memos').create_memo()
  end,
  {
    nargs = 0,
    desc = "Create a new Memos entry"
  }
)

-- 【新增】查看 Memos 列表的命令
vim.api.nvim_create_user_command(
  'Memos',
  function()
    require('memos').show_list()
  end,
  {
    nargs = 0,
    desc = "List and search your Memos"
  }
)
