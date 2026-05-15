vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local function normalize_plugin_name(name)
  return name:lower():gsub("%.git$", "")
end

local function plugin_name_from_spec(spec)
  local repo = type(spec) == "string" and spec or spec[1]
  if type(repo) ~= "string" then
    return nil
  end

  return normalize_plugin_name(repo:match("([^/]+)$") or repo)
end

local function runtime_plugin_names()
  local names = {}

  for _, rtp_path in ipairs(vim.api.nvim_list_runtime_paths()) do
    names[normalize_plugin_name(vim.fn.fnamemodify(rtp_path, ":t"))] = true
  end

  return names
end

local function filter_lazy_spec(spec, installed_plugins)
  local plugin_name = plugin_name_from_spec(spec)
  if plugin_name and installed_plugins[plugin_name] then
    return nil
  end

  if type(spec) ~= "table" then
    return spec
  end

  local filtered_spec = vim.deepcopy(spec)
  if type(filtered_spec.dependencies) == "table" then
    local filtered_dependencies = {}
    for _, dependency in ipairs(filtered_spec.dependencies) do
      local filtered_dependency = filter_lazy_spec(dependency, installed_plugins)
      if filtered_dependency ~= nil then
        table.insert(filtered_dependencies, filtered_dependency)
      end
    end

    filtered_spec.dependencies = #filtered_dependencies > 0 and filtered_dependencies or nil
  end

  return filtered_spec
end

local function lazy_specs(specs)
  local installed_plugins = runtime_plugin_names()
  local filtered_specs = {}

  for _, spec in ipairs(specs) do
    local filtered_spec = filter_lazy_spec(spec, installed_plugins)
    if filtered_spec ~= nil then
      table.insert(filtered_specs, filtered_spec)
    end
  end

  return filtered_specs
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local ok_lazy, lazy = pcall(require, "lazy")
if ok_lazy then
  lazy.setup(
    lazy_specs({
      { "folke/tokyonight.nvim" },
      { "nvim-tree/nvim-web-devicons" },
      {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
      {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
      {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
      { "lewis6991/gitsigns.nvim" },
      { "sindrets/diffview.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
      { "tpope/vim-fugitive" },
      { "stevearc/conform.nvim" },
      { "folke/which-key.nvim" },
      { "windwp/nvim-autopairs" },
      { "numToStr/Comment.nvim" },
      { "lukas-reineke/indent-blankline.nvim" },
      { "neovim/nvim-lspconfig" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "saadparwaiz1/cmp_luasnip" },
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },
      {
        "zbirenbaum/copilot.lua",
        opts = {
          suggestion = { enabled = false },
          panel = { enabled = false },
        },
      },
      {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        config = function()
          local ok, copilot_cmp = pcall(require, "copilot_cmp")
          if ok then
            copilot_cmp.setup()
          end
        end,
      },
    }),
    {
      performance = {
        reset_packpath = false,
        rtp = {
          reset = false,
        },
      },
    }
  )
end

local opt = vim.opt
opt.number = true
opt.relativenumber = false
opt.numberwidth = 4
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.autoread = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.showtabline = 2
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.undofile = true
opt.completeopt = { "menu", "menuone", "noselect" }

vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, prefix = "●" },
})

local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer toggle" })
map("n", "<leader>o", "<cmd>NvimTreeFocus<CR>", { desc = "Explorer focus" })
map("n", "<Space>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer toggle (Space e)" })
map("n", "<Space>o", "<cmd>NvimTreeFocus<CR>", { desc = "Explorer focus (Space o)" })
map("n", "<leader>E", "<cmd>NvimTreeFindFile<CR>", { desc = "Explorer reveal current file" })
map("n", "<C-h>", "<cmd>NvimTreeFocus<CR>", { desc = "Focus explorer" })
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>confirm tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>t.", "<cmd>tabmove +1<CR>", { desc = "Move tab right" })
map("n", "<leader>t,", "<cmd>tabmove -1<CR>", { desc = "Move tab left" })

local function telescope_call(fn)
  return function()
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok and builtin[fn] then
      builtin[fn]()
      return
    end
    vim.notify("telescope is not available", vim.log.levels.WARN)
  end
end

local function gitsigns_call(fn)
  return function()
    local ok, gs = pcall(require, "gitsigns")
    if ok and gs[fn] then
      gs[fn]()
      return
    end
    vim.notify("gitsigns is not available", vim.log.levels.WARN)
  end
end

map("n", "<leader>ff", telescope_call("find_files"), { desc = "Find files" })
map("n", "<leader>fg", telescope_call("live_grep"), { desc = "Live grep" })
map("n", "<leader>fb", telescope_call("buffers"), { desc = "Find buffers" })
map("n", "<leader>fh", telescope_call("help_tags"), { desc = "Help tags" })
map("n", "<leader>f", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ async = true, lsp_fallback = true })
  else
    vim.lsp.buf.format({ async = true })
  end
end, { desc = "Format file" })
map("n", "]h", gitsigns_call("next_hunk"), { desc = "Next git hunk" })
map("n", "[h", gitsigns_call("prev_hunk"), { desc = "Previous git hunk" })
map("n", "<leader>hp", gitsigns_call("preview_hunk"), { desc = "Preview hunk" })
map("n", "<leader>ha", gitsigns_call("stage_hunk"), { desc = "Accept hunk (stage)" })
map("n", "<leader>hr", gitsigns_call("reset_hunk"), { desc = "Reject hunk (reset)" })
map("n", "<leader>do", "<cmd>DiffviewOpen<CR>", { desc = "Diffview open" })
map("n", "<leader>dc", "<cmd>DiffviewClose<CR>", { desc = "Diffview close" })
map("n", "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history" })
map("n", "<leader>gv", "<cmd>Gdiffsplit<CR>", { desc = "Fugitive diff split" })

local checktime_group = vim.api.nvim_create_augroup("opencode_checktime", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = checktime_group,
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

pcall(vim.cmd.colorscheme, "tokyonight-night")

local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
  bufferline.setup({
    options = {
      mode = "buffers",
      always_show_bufferline = true,
      close_command = "confirm bdelete %d",
      right_mouse_command = "confirm bdelete %d",
      separator_style = "slant",
      show_buffer_close_icons = true,
      show_close_icon = false,
      diagnostics = "nvim_lsp",
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "center",
          separator = true,
        },
      },
      -- don't show nvim-tree as a tab
      custom_filter = function(buf_number)
        local ft = vim.bo[buf_number].filetype
        return ft ~= "NvimTree"
      end,
    },
  })
end

-- Buffer navigation
map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>confirm bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin buffer" })

local ok_which_key, which_key = pcall(require, "which-key")
if ok_which_key then
  which_key.setup({})
end

local ok_avante_lib, avante_lib = pcall(require, "avante_lib")
if ok_avante_lib then
  avante_lib.load()
end

local ok_avante, avante = pcall(require, "avante")
if ok_avante then
  avante.setup({
    provider = "opencode",
    acp_providers = {
      opencode = {
        command = "opencode",
        args = { "acp" },
      },
    },
  })
end

local ok_comment, comment = pcall(require, "Comment")
if ok_comment then
  comment.setup({})
end

local ok_autopairs, autopairs = pcall(require, "nvim-autopairs")
if ok_autopairs then
  autopairs.setup({})
end

local ok_ibl, ibl = pcall(require, "ibl")
if ok_ibl then
  ibl.setup({})
end

local ok_tree, nvim_tree = pcall(require, "nvim-tree")
if ok_tree then
  local ok_tree_actions, tree_actions = pcall(require, "nvim-tree.actions.tree")
  if ok_tree_actions and tree_actions.modifiers then
    tree_actions.collapse = tree_actions.collapse or tree_actions.modifiers.collapse
    tree_actions.expand = tree_actions.expand or tree_actions.modifiers.expand
  end

  nvim_tree.setup({
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      api.config.mappings.default_on_attach(bufnr)
      vim.keymap.set("n", "<C-l>", "<cmd>wincmd l<CR>", {
        buffer = bufnr,
        desc = "Tree: focus editor",
        noremap = true,
        silent = true,
      })
    end,
    actions = { open_file = { resize_window = true } },
    filters = { dotfiles = false },
    git = { ignore = false },
    renderer = { group_empty = true, highlight_git = true },
    update_focused_file = { enable = true, update_root = true },
    view = { width = 35 },
  })

  local tree_startup_group = vim.api.nvim_create_augroup("opencode_nvim_tree_startup", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = tree_startup_group,
    callback = function(data)
      if vim.fn.isdirectory(data.file) == 1 then
        return
      end

      local tree_was_opened = false
      if vim.fn.argc() > 0 then
        tree_was_opened = pcall(vim.cmd, "NvimTreeFindFile")
      end

      if not tree_was_opened then
        pcall(vim.cmd, "NvimTreeOpen")
      end

      if vim.bo.filetype == "NvimTree" and vim.fn.winnr("$") > 1 then
        vim.cmd("wincmd p")
      end
    end,
  })
end

local ok_lualine, lualine = pcall(require, "lualine")
if ok_lualine then
  lualine.setup({
    options = {
      component_separators = "",
      section_separators = "",
      globalstatus = true,
      theme = "tokyonight",
    },
  })
end

local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
  gitsigns.setup({})
end

local ok_treesitter, treesitter = pcall(require, "nvim-treesitter.configs")
if ok_treesitter then
  treesitter.setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
end

local ok_telescope, telescope = pcall(require, "telescope")
if ok_telescope then
  telescope.setup({
    defaults = {
      file_ignore_patterns = { ".git/", "node_modules/" },
      layout_strategy = "horizontal",
    },
  })
end

local ok_conform, conform = pcall(require, "conform")
if ok_conform then
  conform.setup({
    formatters_by_ft = {
      javascript = { "prettierd", "prettier" },
      json = { "prettierd", "prettier" },
      lua = { "stylua" },
      markdown = { "prettierd", "prettier" },
      python = { "ruff_format", "black" },
      typescript = { "prettierd", "prettier" },
      yaml = { "prettierd", "prettier" },
    },
    format_on_save = function()
      return { lsp_fallback = true, timeout_ms = 1000 }
    end,
  })
end

local ok_cmp_lsp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local capabilities = vim.lsp.protocol.make_client_capabilities()
if ok_cmp_lsp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

local function lsp_on_attach(_, bufnr)
  local function lmap(lhs, rhs, desc, mode)
    vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc })
  end
  lmap("gd", vim.lsp.buf.definition, "LSP definition")
  lmap("gD", vim.lsp.buf.declaration, "LSP declaration")
  lmap("gr", vim.lsp.buf.references, "LSP references")
  lmap("gi", vim.lsp.buf.implementation, "LSP implementation")
  lmap("K", vim.lsp.buf.hover, "LSP hover")
  lmap("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
  lmap("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
end

local function setup_lsp(name, opts)
  opts = vim.tbl_deep_extend("force", {
    capabilities = capabilities,
    on_attach = lsp_on_attach,
  }, opts or {})

  if vim.lsp and vim.lsp.config and vim.lsp.enable then
    vim.lsp.config(name, opts)
    vim.lsp.enable(name)
    return
  end

  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
  if ok_lspconfig and lspconfig[name] then
    lspconfig[name].setup(opts)
  end
end

for _, server in ipairs({ "bashls", "jsonls", "marksman", "pyright", "yamlls" }) do
  setup_lsp(server)
end

setup_lsp("lua_ls", {
  settings = {
    Lua = {
      completion = { callSnippet = "Replace" },
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  local ok_luasnip, luasnip = pcall(require, "luasnip")
  if ok_luasnip then
    local ok_loader, loader = pcall(require, "luasnip.loaders.from_vscode")
    if ok_loader then
      loader.lazy_load()
    end
  end

  cmp.setup({
    snippet = {
      expand = function(args)
        if ok_luasnip then
          luasnip.lsp_expand(args.body)
        end
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
        elseif ok_luasnip and luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif ok_luasnip and luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    experimental = {
      ghost_text = true,
    },
    sources = cmp.config.sources({
      { name = "copilot" },
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "path" },
      { name = "buffer" },
    }),
  })

  local ok_cmp_autopairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
  if ok_cmp_autopairs then
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
end
