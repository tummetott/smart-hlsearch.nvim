-- smart-hlsearch turns 'hlsearch' on while the user is actively searching and
-- restores the previous value when that search flow ends.
--
-- Search flow starts in two ways:
--   1. entering the search cmdline with '/' or '?'
--   2. calling activate() from user mappings
--
-- Search flow stays active while the user continues search navigation with
-- commands such as 'n', 'N', '*', '#', 'g*', and 'g#'.
--
-- Other cursor movement and mode changes end that flow and restore the
-- previous 'hlsearch' value.
local M = {}

local default_opts = {
    hide_in_visual_mode = true,
    clear_after_cmdline_search = false,
}

local search_keys = {
    ['n'] = true,
    ['N'] = true,
    ['*'] = true,
    ['#'] = true,
}

local group = vim.api.nvim_create_augroup('smart-hlsearch', { clear = true })
local opts = vim.deepcopy(default_opts)
local did_setup = false

-- Runtime state:
--   active              true while the plugin currently owns visible search
--                       highlighting
--   current_key         most recent Normal-mode key seen by vim.on_key()
--   last_key            previous Normal-mode key seen by vim.on_key()
--   restore_hlsearch    original 'hlsearch' value from before the current
--                       temporary override chain started; restored when that chain
--                       ends
local state = {
    active = false,
    current_key = nil,
    last_key = nil,
    restore_hlsearch = nil,
}

function M.deactivate()
    if not state.active then
        return
    end

    -- Restores the baseline 'hlsearch' value from before plugin-managed search
    -- highlighting became active.
    vim.opt.hlsearch = state.restore_hlsearch
    state.active = false
    state.restore_hlsearch = nil
end

function M.activate()
    if state.active then
        return
    end

    -- Nested temporary states reuse the same baseline. Visual mode can hide
    -- highlighting before search cmdline is entered, so the first override in
    -- the chain stores the original value and later overrides keep it.
    if state.restore_hlsearch == nil then
        state.restore_hlsearch = vim.o.hlsearch
    end

    vim.opt.hlsearch = true
    state.active = true
end

function M.setup(user_opts)
    if did_setup then
        return
    end

    did_setup = true
    opts = vim.tbl_deep_extend('force', vim.deepcopy(default_opts), user_opts or {})

    -- vim.on_key() records recent Normal-mode keys. Autocmds use those
    -- recorded keys to decide whether the current search flow continues or
    -- ends.
    vim.on_key(function(char)
        if vim.api.nvim_get_mode().mode ~= 'n' then
            return
        end

        state.last_key = state.current_key
        state.current_key = vim.fn.keytrans(char)
    end)

    vim.api.nvim_create_autocmd('CmdlineEnter', {
        group = group,
        pattern = { '/', '\\?' },
        callback = function()
            -- Entering '/' or '?' begins interactive search and shows matches
            -- immediately while the user types.
            M.activate()
        end,
    })

    vim.api.nvim_create_autocmd('CmdlineLeave', {
        group = group,
        pattern = { '/', '\\?' },
        callback = function()
            -- Aborted searches always restore the previous state. Confirmed
            -- searches either keep the highlight alive or stop immediately,
            -- depending on configuration.
            if vim.v.event.abort or opts.clear_after_cmdline_search then
                M.deactivate()
            end
        end,
    })

    vim.api.nvim_create_autocmd('CursorMoved', {
        group = group,
        callback = function()
            if not state.active then
                return
            end

            -- Search continuation commands keep the current search highlight
            -- active. Any other cursor movement is treated as leaving search
            -- flow.
            local current_key = state.current_key

            if search_keys[current_key] then
                return
            end

            if state.last_key == 'g' and (current_key == '*' or current_key == '#') then
                return
            end

            M.deactivate()
        end,
    })

    vim.api.nvim_create_autocmd('InsertEnter', {
        group = group,
        callback = function()
            -- Entering Insert mode always ends search flow.
            M.deactivate()
        end,
    })

    if opts.hide_in_visual_mode then
        vim.api.nvim_create_autocmd('ModeChanged', {
            group = group,
            pattern = '*:[vV\22]',
            callback = function()
                -- Search highlighting and Visual selection often use very
                -- similar highlighting. Visual mode disables 'hlsearch' for
                -- better readability and restores the previous value after
                -- leaving Visual mode.
                if state.restore_hlsearch == nil then
                    state.restore_hlsearch = vim.o.hlsearch
                end

                state.active = false
                vim.opt.hlsearch = false
            end,
        })

        vim.api.nvim_create_autocmd('ModeChanged', {
            group = group,
            pattern = '[vV\22]:[^c]*',
            callback = function()
                -- If Visual mode suppressed search highlighting, restore the
                -- saved value after leaving Visual mode.
                if state.restore_hlsearch ~= nil then
                    vim.opt.hlsearch = state.restore_hlsearch
                    state.restore_hlsearch = nil
                end
            end,
        })
    end
end

return M
