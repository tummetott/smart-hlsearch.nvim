# smart-hlsearch.nvim

Do you also find it annoying to enable `hlsearch` when you start searching, and disable it again once you're done? This plugin does that for you and handles the edge cases that show up along the way.

In simple terms:

- you start a search with `/` or `?` → you want `hlsearch`
- you step through search results with `n`, `N`, `*`, `#`, `g*`, `g#` → you still want `hlsearch`
- you press any other key → you're done searching and don't want `hlsearch`
- you explicitly enable `hlsearch` → this plugin does not fight that decision and leaves it enabled until you disable it

Why another plugin, when similar plugins already exist? See [Comparison](#comparison).

## Features

- Automatically enables `hlsearch` when starting a search and clears it again when the search flow ends.
- Keeps highlight active while continuing search navigation with `n`, `N`, `*`, `#`, `g*`, and `g#`.
- Leaves mapping ownership with the user. The plugin does not define mappings, which keeps it compatible with lazy loading and custom keymaps.
- Preserves the user's original `hlsearch` setting instead of permanently taking over the option.
- Optionally hides `hlsearch` in Visual mode for better readability and restores it afterward.
- Lets you choose whether search highlight stays active after confirming a `/` or `?` search.

## API

```lua
require('smart-hlsearch').setup(opts)
require('smart-hlsearch').activate()
require('smart-hlsearch').deactivate()
```

### Options

```lua
{
    -- Disable `hlsearch` in Visual mode and restore the value after leaving it.
    hide_in_visual_mode = true,

    -- Did you know that `<C-g>` and `<C-t>` navigate matches while staying in
    -- the search cmdline? This keeps the jumplist clean! If that is your
    -- usual workflow, the next setting is for you: pressing `<CR>` means the
    -- search is done and `hlsearch` should be disabled.
    clear_after_cmdline_search = false,
}
```

## Requirements

Neovim `0.8.0` or newer

## Installation with `lazy.nvim`

```lua
{
    'tummetott/smart-hlsearch.nvim',
    opts = {
        -- Your config overwrites
    },
    keys = {
        {
            '/',
            function()
                require('smart-hlsearch').activate()
                return '/'
            end,
            mode = 'n',
            expr = true,
        },
        {
            '?',
            function()
                require('smart-hlsearch').activate()
                return '?'
            end,
            mode = 'n',
            expr = true,
        },
        {
            'n',
            function()
                require('smart-hlsearch').activate()
                return 'n'
            end,
            mode = 'n',
            expr = true,
        },
        {
            'N',
            function()
                require('smart-hlsearch').activate()
                return 'N'
            end,
            mode = 'n',
            expr = true,
        },
        {
            '*',
            function()
                require('smart-hlsearch').activate()
                return '*'
            end,
            mode = 'n',
            expr = true,
        },
        {
            '#',
            function()
                require('smart-hlsearch').activate()
                return '#'
            end,
            mode = 'n',
            expr = true,
        },
        {
            'g*',
            function()
                require('smart-hlsearch').activate()
                return 'g*'
            end,
            mode = 'n',
            expr = true,
        },
        {
            'g#',
            function()
                require('smart-hlsearch').activate()
                return 'g#'
            end,
            mode = 'n',
            expr = true,
        },
    },
}
```

## Comparison

- [`asiryk/auto-hlsearch.nvim`](https://github.com/asiryk/auto-hlsearch.nvim)

This plugin behaves very similarly. I mostly didn’t like that it defines keymaps for you, which don’t play well with custom mappings or lazy loading. It also treats the `hlsearch` setting as plugin-owned state instead of preserving the user’s original configuration.

It also doesn’t support `g*` and `g#`, and its `<CR>` handling isn’t quite right.

- [`nvimdev/hlsearch.nvim`](https://github.com/nvimdev/hlsearch.nvim)

It checks whether the current search pattern matches at the current cursor position. It does not distinguish between actively being in a search flow and merely being on text that matches the current search pattern.

That behavior always confused me a bit, because it can make `hlsearch` reappear in situations where I do not think of myself as actively searching anymore.

- [`lwflwf1/vim-smart-hlsearch`](https://github.com/lwflwf1/vim-smart-hlsearch)

This plugin also defines mappings for you. It does not respect your existing `hlsearch` setting, and it disables and re-enables `hlsearch` around search navigation like `n` and `N` instead of modeling a persistent search flow.

Vimscript... good old times. But not anymore.

## Caveats

Guess what? Neovim `:mkview` writes the current `hlsearch` state into the view file. That is awkward behavior that is not documented anywhere, and you cannot disable it because `viewoptions` do not cover it. Why is this awkward? Because there are basically two kinds of users:

- You disable `hlsearch` while you're not searching → you probably don't want active `hlsearch` on startup
- You always have `hlsearch` enabled → you put `vim.opt.hlsearch = true` in your config

For neither of these cases does it make sense to persist this setting in the `viewdir`.

Why do I mention this here? This plugin controls the `hlsearch` setting for you. If you use `:mkview` and `:loadview` in autocmds like I do, it can happen that `vim.opt.hlsearch = true` gets persisted into your view file. This is an edge case that took me a while to debug. A simple workaround is to set `vim.opt.hlsearch = false` right before `:mkview`, and you won't be bothered anymore.
