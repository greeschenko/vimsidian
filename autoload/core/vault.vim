vim9script

# ----------------------------
# Vault
# ----------------------------

export def GetVaultPath(): string
  var vault = fnamemodify(g:vimsidian_vault_path, ':p')
  return substitute(vault, '/$', '', '')
enddef

export def GetDataPath(): string
  return GetVaultPath() .. '/data'
enddef

export def EnsureDataDir()
  var dir = GetDataPath()
  if !isdirectory(dir)
    mkdir(dir, 'p')
  endif
enddef

export def OpenVaultExplorer()
  var vault = g:vimsidian_vault_path

  if empty(vault)
    echoerr 'Vault path is not configured'
    return
  endif

  var data_dir = vault .. '/data/'

  g:netrw_banner = 0
  g:netrw_liststyle = 3
  g:netrw_browse_split = 4
  g:netrw_winsize = 25

  execute 'Explore ' .. fnameescape(data_dir)
enddef

defcompile
