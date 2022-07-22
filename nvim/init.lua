-- Init {{{1

-- Group used for all autocmd's in this file.
local groupInit = vim.api.nvim_create_augroup("my_init", {})

-- Packages {{{1

require("plugins")

vim.api.nvim_create_autocmd("BufWritePost", {
  group = groupInit,
  pattern = "plugins.lua",
  command = "source <afile> | PackerCompile",
})

-- Editor settings {{{1

vim.opt.tabstop = 2 -- Use 2 spaces to represent a tab.
vim.opt.shiftwidth = 0 -- Use the 'tabstop' setting as the number of spaces when indenting.
vim.opt.expandtab = true -- Use spaces instead of tabs.
vim.opt.scrolloff = 2 -- Always keep at least 2 lines visible around the cursor.
vim.opt.ignorecase = true -- Search case insensitive...
vim.opt.smartcase = true -- ... but not if it begins with upper case.
vim.opt.hlsearch = true -- Highlight search matches.
vim.opt.inccommand = "nosplit" -- Show find-replace preview when typing command.
vim.opt.number = true -- Show line numbers.
vim.opt.relativenumber = true -- Use line numbers relative to the current line.
vim.opt.autowrite = true -- Automatically save before :next, :make etc.
vim.opt.showmode = false -- We show the mode with airline or lightline.
vim.opt.fileformats = { "unix", "dos", "mac" } -- Prefer Unix over Windows over OS 9 formats.
vim.opt.lazyredraw = true -- Don't redraw during execution of macros.
vim.opt.termguicolors = true -- Enable 24-bit color support.
vim.opt.signcolumn = "number" -- Show signs in the number column.
vim.opt.diffopt = {
  "internal", -- Use the internal diff library.
  "filler", -- Show filler lines.
  "closeoff", -- Run diffoff automatically when one window is closed.
  "algorithm:patience", -- Use the patience algorithm.
}
vim.opt.clipboard = { -- Copy to "* and "+ for operations like yank, delete, change and put.
  "unnamed", -- "* = PRIMARY selection.
  "unnamedplus", -- "+ = CLIPBOARD selection.
}
vim.opt.undofile = true -- Retain undo history between nvim sessions.
vim.opt.mouse = "a" -- Enable mouse support for all modes.
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.fillchars = {
  fold = "\u{2504}",
  foldopen = "\u{250c}",
  foldclose = "\u{257a}",
  eob = " ",
}

vim.g.mapleader = "," -- Use "," for <Leader> in keybindings.

-- Highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = groupInit,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { timeout = 500, on_visual = false }
  end,
})

-- Use OSC 52 on yank.

---Copy lines using OSC 52.
---@param lines string[] A list of lines to copy.
---@param ...   string Parameters passed as Ps.
local function copy(lines, ...)
  local data = vim.fn.system("base64 | tr -d '\n'", lines)
  for _, sel in ipairs({ ... }) do
    io.stdout:write('\027]52;' .. sel .. ';' .. data .. '\a')
  end
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = groupInit,
  pattern = "*",
  callback = function()
    if vim.v.event.operator ~= "y" then return end
    local reg = vim.v.event.regname
    local lines = vim.v.event.regcontents
    if reg == "" then
      copy(lines, "s", "c")
    elseif reg == "*" then
      copy(lines, "s")
    elseif reg == "+" then
      copy(lines, "c")
    end
  end,
})

-- Settings for LSP {{{1

vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<Leader>q", vim.diagnostic.setloclist)

local function set_buf_keymap_for_lsp(bufnr)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr })
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr })
  vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>f", vim.lsp.buf.formatting, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>k", vim.lsp.buf.signature_help, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, { buffer = bufnr })
  vim.keymap.set("n", "<Leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, { buffer = bufnr })
end

local function enable_buf_autoformat_on_save(bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.formatting_seq_sync()
    end,
  })
end

local function organize_imports(wait_ms)
  local params = vim.lsp.util.make_range_params()
  params.context = {
    only = { vim.lsp.protocol.CodeActionKind.SourceOrganizeImports },
  }
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
      else
        vim.lsp.buf.execute_command(r.command)
      end
    end
  end
end

local function enable_buf_organize_imports_on_save(bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    callback = function()
      organize_imports(1000)
    end,
  })
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

local default_config = {
  capabilities = capabilities,
  on_attach = function(_, bufnr)
    set_buf_keymap_for_lsp(bufnr)
    enable_buf_autoformat_on_save(bufnr)
  end,
}

local function lsp_setup(name, ...)
  local config = vim.tbl_deep_extend("force", {}, default_config)
  for _, fn in ipairs({ ... }) do
    config = fn(config)
  end
  require("lspconfig")[name].setup(config)
end

local function extend_with(extension)
  return function(config)
    return vim.tbl_deep_extend("force", config, extension)
  end
end

lsp_setup("clangd")
lsp_setup("tsserver")
lsp_setup("jsonls")
lsp_setup("cssls")
lsp_setup("stylelint_lsp", extend_with {
  filetypes = { "css", "less", "scss", "sugarss", "vue", "wxss" },
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
    },
  },
})

lsp_setup("html", extend_with {
  on_attach = function(_, bufnr)
    set_buf_keymap_for_lsp(bufnr)
    -- Don't enable auto-formatting on save.
  end
})

lsp_setup("gopls", extend_with {
  init_options = {
    usePlaceholders = true,
    gofumpt = true,
  },
  on_attach = function(_, bufnr)
    set_buf_keymap_for_lsp(bufnr)
    enable_buf_autoformat_on_save(bufnr)
    enable_buf_organize_imports_on_save(bufnr)
  end
})

lsp_setup("sumneko_lua", extend_with {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
        -- Setup your lua path
        path = (function()
          local path = vim.split(package.path, ";")
          table.insert(path, "lua/?.lua")
          table.insert(path, "lua/?/init.lua")
          return path
        end)(),
        pathStrict = true,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Settings for nvim-cmp / luasnip {{{1

local luasnip = require("luasnip")
local cmp = require("cmp")

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-k>"]   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<C-j>"]   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<C-u>"]   = cmp.mapping.scroll_docs(-4),
    ["<C-d>"]   = cmp.mapping.scroll_docs(4),
    ["<Esc>"]   = cmp.mapping.abort(),
    ["<CR>"]    = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ["<Tab>"]   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
  }, {
    { name = "path" },
  })
}

-- Settings for lightline {{{1

vim.g.lightline = {
  colorscheme = "gruvbox",
  subseparator = {
    left  = "\u{2502}",
    right = "\u{2502}",
  },
  active = {
    left = {
      { "mode", "paste", "snippet" },
      { "gitbranch", "filename", "readonly", "modified" },
    },
  },
  component_function = {
    gitbranch = "FugitiveHead",
    snippet = "my#lightline#snippet",
    filename = "my#lightline#filename",
  },
}

vim.g["my#lightline#filename"] = function()
  local root = vim.fn.FugitiveWorkTree()
  if #root > 0 then
    local path = vim.fn.expand("%:p")
    if path:sub(1, #root + 1) == root .. "/" then
      return path:sub(#root + 2)
    end
  end
  return vim.fn.expand("%")
end

vim.g["my#lightline#snippet"] = function()
  return luasnip.in_snippet() and "SNIP" or ""
end

-- Refresh lightline colorscheme after the background option changes.
vim.api.nvim_create_autocmd("OptionSet", {
  group = groupInit,
  pattern = "background",
  callback = function()
    vim.cmd("source " .. vim.fn.globpath(
      vim.o.runtimepath, "plugin/lightline-gruvbox.vim"))
    vim.fn["lightline#colorscheme"]()
    vim.fn["lightline#update"]()
  end,
})

-- Fix for https://github.com/itchyny/lightline.vim/issues/390
vim.api.nvim_create_autocmd("FileType", {
  group = groupInit,
  pattern = "netrw",
  callback = function()
    vim.fn["lightline#enable"]()
  end,
})

-- Colorscheme {{{1

local hour = os.date("*t").hour
if hour >= 7 and hour < 19 then
  vim.opt.background = "light"
else
  vim.opt.background = "dark"
end

vim.g.one_allow_italics = 1

vim.g.gruvbox_italic = 1

vim.g.neosolarized_bold = 1
vim.g.neosolarized_underline = 1
vim.g.neosolarized_italic = 1

vim.cmd("colorscheme gruvbox")

-- Key mappings {{{1

-- Use space to open/close folds in normal mode.
vim.keymap.set("n", "<Space>", function()
  return vim.fn.foldlevel(".") > 0 and "za" or "<Space>"
end, { expr = true })

-- Maintain a visual selection while indenting.
vim.keymap.set("v", "<", "<gv", { silent = true })
vim.keymap.set("v", ">", ">gv", { silent = true })

-- F3 retabs the buffer and removes any trailing whitespace.
vim.keymap.set("n", "<F3>", function()
  local last_search = vim.fn.getreg("/")
  local last_pos    = vim.fn.getcurpos()
  vim.cmd("retab")
  vim.cmd("%s/\\s\\+$//e")
  vim.fn.setreg("/", last_search)
  vim.fn.setpos(".", last_pos)
end)

-- Keybindings to simplify editing of init.vim.
vim.keymap.set("n", "<Leader>ev", "<Cmd>edit $MYVIMRC<CR>", { silent = true })
vim.keymap.set("n", "<Leader>sv", "<Cmd>source $MYVIMRC<CR>", { silent = true })

-- Filetype specific settings {{{1

local filetypes = {
  ["c,cpp"] = {
    tabstop = 4,
  },
  ["make"] = {
    tabstop = 8,
    expandtab = false,
  },
}

for pattern, options in pairs(filetypes) do
  vim.api.nvim_create_autocmd("FileType", {
    group = groupInit,
    pattern = pattern,
    callback = function()
      for name, value in pairs(options) do
        vim.bo[name] = value
      end
    end
  })
end

-- }}}1
