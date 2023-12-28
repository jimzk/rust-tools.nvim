local rt = require("rust-tools")
local M = {}

local function handler(err, result, ctx)
  -- vim.print("err:", err, "result:", result)
  if err then
    -- vim.print("Could not execute request to server: ", err)
    return
  end
  if result == nil then
    return
  end
  vim.lsp.util.apply_text_edits(
    result,
    ctx.bufnr,
    vim.lsp.get_client_by_id(ctx.client_id).offset_encoding
  )
end

local function on_type()
  if not M.trigger_characters then
    local capabilities = vim.lsp.get_clients { name = "rust_analyzer" }[1].server_capabilities
        .documentOnTypeFormattingProvider
    if not capabilities then
      return
    end
    local chars = { capabilities.firstTriggerCharacter }
    vim.list_extend(chars, capabilities.moreTriggerCharacter or {})
    M.trigger_characters = chars
    -- vim.notify("M.trigger_characters: " .. vim.inspect(M.trigger_characters))
  end

  local char = vim.v.char
  if #char ~= 1 then
    return
  end

  -- vim.print("checking: " .. char, M.trigger_characters)
  if not vim.list_contains(M.trigger_characters, char) then
    return
  end
  -- vim.notify("on_type: " .. char .. ", sending request")

  -- Provides textDocument and position
  local params = vim.lsp.util.make_position_params()
  -- Move right by one because we just typed a character
  -- R-a throws an assertion error otherwise
  params.position.character = params.position.character + 1
  -- Provides ch
  params.ch = char
  -- Provides textDocument and options
  local formatting_opts = vim.lsp.util.make_formatting_params().options
  params.options = formatting_opts
  -- vim.print(params)
  vim.schedule(function()
    rt.utils.request(0, "textDocument/onTypeFormatting", params, handler)
  end)
end

function M.setup_on_type_assist()
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = require 'rust-tools.lsp'.group,
    callback = on_type,
  })
end

return M
