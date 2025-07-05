-- 创建 :MemosCreate 命令
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

-- 创建 :Memos 命令
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

-- 【新增】创建启动快捷键
-- 使用 vim.schedule 确保在所有插件加载后执行，避免 require('memos') 失败
vim.schedule(function()
  -- 我们需要先加载 memos 模块才能读取它的配置
  local memos_config = require('memos').config
  local key = memos_config.keymaps.start_memos
  if key and key ~= "" then
    vim.keymap.set('n', key, '<Cmd>Memos<CR>', {
      noremap = true,
      silent = true,
      desc = "Open Memos list"
    })
  end
end)
