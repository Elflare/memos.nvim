# memos.nvim

English | [简体中文](./README.md#memosnvim-简体中文)

A Neovim plugin to interact with [Memos](https://github.com/usememos/memos) right inside the editor. List, create, edit, and delete your memos without leaving Neovim.

## ✨ Features

-   **List Memos**: View, search, and paginate through your memos in a floating window.
-   **Create & Edit**: Create new memos or edit existing ones in a dedicated buffer with `markdown` filetype support.
-   **Delete Memos**: Delete memos directly from the list.
-   **Customizable**: Configure API endpoints, keymaps, and more.

## 📦 Installation

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

Install with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
-- lua/plugins/memos.lua

return {
  -- Memos.nvim: A plugin to interact with Memos from within Neovim
  {
    -- IMPORTANT: Replace with your actual GitHub username/repo
    "your-github-username/memos.nvim",

    -- Optional, but good for identification in Lazy UI
    name = "memos.nvim",

    dependencies = { "nvim-lua/plenary.nvim" },

    -- Load the plugin on these commands
    cmd = { "Memos", "MemosCreate" },

    config = function()
      require("memos").setup({
        -- REQUIRED: Your Memos host URL
        host = "https://your-memos-host.com",

        -- REQUIRED: Your Memos API token (Open API)
        token = "your-super-secret-token",

        -- Optional: Customize keymaps
        keymaps = {
          -- Keymaps for the editing/creating buffer
          buffer = {
            save = "<leader>ms", -- Save the current memo
          },
          -- Keymaps for the memo list window
          list = {
            add_memo = "a", -- Add a new memo
            edit_memo = "<CR>", -- Edit selected memo
            -- ... other keymaps can be configured here
          }
        },
      })
    end,
  },

  -- Plenary is a required dependency
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
}
```

## 🚀 Usage

### Commands

-   `:Memos`: Opens a floating window to list and search your memos.
-   `:MemosCreate`: Opens a new buffer to create a new memo.
-   `:MemosSave`: (Available in the memo buffer) Saves the memo you are currently creating or editing.

### Default Keymaps

#### In the Memo List Window

| Key                | Action                               |
| ------------------ | ------------------------------------ |
| `a`                | Add a new memo                       |
| `d` or `dd`        | Delete the selected memo             |
| `<CR>`             | Edit the selected memo               |
| `<Tab>`            | Edit the selected memo in a vsplit   |
| `s`                | Search your memos                    |
| `r`                | Refresh the memo list                |
| `.`                | Load the next page of memos          |
| `q`                | Quit the list window                 |

#### In the Edit/Create Buffer

| Key                | Action                               |
| ------------------ | ------------------------------------ |
| `<leader>ms`       | Save the current memo                |

## ⚙️ Configuration

You can override the default settings by passing a table to the `setup()` function.

```lua
require("memos").setup({
  -- REQUIRED: Your Memos host URL
  host = "https://your-memos-host.com",

  -- REQUIRED: Your Memos API token (Open API)
  token = "your-super-secret-token",

  -- Number of memos to fetch per page
  pageSize = 50,

  -- Set to false or nil to disable a keymap
  keymaps = {
    -- Keymaps for the memo list window
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
    -- Keymaps for the editing/creating buffer
    buffer = {
      save = "<leader>ms",
    },
  },
})
```

---

# memos.nvim (简体中文)

[English](./README.md#memosnvim) | 简体中文

一个 Neovim 插件，让你在编辑器内部直接与 [Memos](https://github.com/usememos/memos) 进行交互。无需离开 Neovim 即可列表、创建、编辑和删除你的 memos。

## ✨ 功能

-   **列表 Memos**: 在浮动窗口中查看、搜索和翻页你的 memos。
-   **创建与编辑**: 在专用的、支持 `markdown` 文件类型的缓冲区中创建新 memo 或编辑现有 memo。
-   **删除 Memos**: 直接从列表中删除 memo。
-   **可定制**: 可配置 API 地址、快捷键等。

## 📦 安装

需要 [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) 插件。

使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 安装:

```lua
-- lua/plugins/memos.lua

return {
  -- Memos.nvim: 一个在 Neovim 中与 Memos 交互的插件
  {
    -- 重要: 请将这里替换为你的 GitHub 用户名/仓库名
    "your-github-username/memos.nvim",

    -- 可选，但在 Lazy 管理界面中易于识别
    name = "memos.nvim",

    dependencies = { "nvim-lua/plenary.nvim" },

    -- 在执行这些命令时加载插件
    cmd = { "Memos", "MemosCreate" },

    config = function()
      require("memos").setup({
        -- 必填: 你的 Memos 服务地址
        host = "https://your-memos-host.com",

        -- 必填: 你的 Memos API 令牌 (Open API)
        token = "your-super-secret-token",

        -- 可选: 自定义快捷键
        keymaps = {
          -- 编辑/创建窗口的快捷键
          buffer = {
            save = "<leader>ms", -- 保存当前 memo
          },
          -- memo 列表窗口的快捷键
          list = {
            add_memo = "a", -- 新增 memo
            edit_memo = "<CR>", -- 编辑所选 memo
            -- ... 其他快捷键也可以在这里配置
          }
        },
      })
    end,
  },

  -- Plenary 是一个必要的依赖
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
}
```

## 🚀 使用方法

### 命令

-   `:Memos`: 打开一个浮动窗口，列出并搜索你的 memos。
-   `:MemosCreate`: 打开一个新的缓冲区来创建 memo。
-   `:MemosSave`: (在 memo 编辑缓冲区中可用) 保存你正在创建或编辑的 memo。

### 默认快捷键

#### 在 Memo 列表窗口中

| 按键               | 功能                               |
| ------------------ | ---------------------------------- |
| `a`                | 新增一个 memo                      |
| `d` 或 `dd`        | 删除所选的 memo                    |
| `<CR>`             | 编辑所选的 memo                    |
| `<Tab>`            | 在垂直分屏中编辑所选的 memo        |
| `s`                | 搜索你的 memos                     |
| `r`                | 刷新 memo 列表                     |
| `.`                | 加载下一页 memos                   |
| `q`                | 退出列表窗口                       |

#### 在编辑/创建缓冲区中

| 按键               | 功能                               |
| ------------------ | ---------------------------------- |
| `<leader>ms`       | 保存当前 memo                      |

## ⚙️ 配置

你可以通过向 `setup()` 函数传递一个 table 来覆盖默认设置。

```lua
require("memos").setup({
  -- 必填: 你的 Memos 服务地址
  host = "https://your-memos-host.com",

  -- 必填: 你的 Memos API 令牌 (Open API)
  token = "your-super-secret-token",

  -- 每页获取的 memo 数量
  pageSize = 50,

  -- 设置为 false 或 nil 可以禁用某个快捷键
  keymaps = {
    -- memo 列表窗口的快捷键
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
    -- 编辑/创建窗口的快捷键
    buffer = {
      save = "<leader>ms",
    },
  },
})
