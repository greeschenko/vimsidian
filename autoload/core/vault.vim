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

defcompile
