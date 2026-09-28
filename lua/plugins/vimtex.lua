return {
  "lervag/vimtex",
  lazy = false, -- Do NOT lazy-load VimTeX; it breaks SyncTeX inverse search
  init = function()
    -- Use latexmk as the default compiler backend
    vim.g.vimtex_compiler_method = "latexmk"

    -- Set LuaLaTeX as the default engine for latexmk
    vim.g.vimtex_compiler_latexmk_engines = {
      _ = "-lualatex",
    }

    -- Set PDF viewer with SyncTeX support
    -- Windows: SumatraPDF is recommended (install via `winget install SumatraPDF.SumatraPDF`)
    --   and supports forward/inverse search. Using "general" falls back to your
    --   default PDF viewer (you have Acrobat.Document.DC) but SyncTeX will be limited.
    -- Linux: "zathura", macOS: "skim", Cross-platform: "sioyek"
    if vim.fn.has("win32") == 1 then
      vim.g.vimtex_view_method = "general"
      -- SumatraPDF 3.6.1 installed at %LOCALAPPDATA%\SumatraPDF\SumatraPDF.exe via winget
      vim.g.vimtex_view_general_viewer = "C:/Users/coffm049/AppData/Local/SumatraPDF/SumatraPDF.exe"
      vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
    else
      vim.g.vimtex_view_method = "zathura"
    end
  end,
}
