vim9script

import autoload 'core/vault.vim'

export def GetAllMedia(): list<string>
  var dir = vault.GetMediaPath()
  if !isdirectory(dir)
    return []
  endif

  var files = globpath(dir, '*', 0, 1)
  return sort(filter(files, (_, v) => !isdirectory(v)))
enddef

export def CopyToMedia(source_path: string): string
  vault.EnsureMediaDir()

  var source = fnamemodify(source_path, ':p')
  if !filereadable(source)
    throw 'Vimsidian: file not found: ' .. source_path
  endif

  var filename = fnamemodify(source_path, ':t')
  var dest_path = vault.GetMediaPath() .. '/' .. filename

  var counter = 1
  var base_name = fnamemodify(filename, ':t:r')
  var ext = fnamemodify(filename, ':e')
  while filereadable(dest_path)
    filename = base_name .. '_' .. counter .. '.' .. ext
    dest_path = vault.GetMediaPath() .. '/' .. filename
    counter += 1
  endwhile

  var content = readfile(source)
  writefile(content, dest_path)

  return dest_path
enddef

export def InsertMarkdownLink(media_path: string)
  var filename = fnamemodify(media_path, ':t')
  var link = '![' .. fnamemodify(filename, ':t:r') .. '](' .. filename .. ')'

  var line = getline('.')
  var coln = col('.') - 1

  setline('.', strpart(line, 0, coln) .. link .. strpart(line, coln))
enddef

export def DeleteMedia(media_path: string): bool
  if !filereadable(media_path)
    return false
  endif

  var bin_path = vault.GetBinPath() .. '/' .. strftime('%Y-%m-%d') .. '/media'
  if !isdirectory(bin_path)
    mkdir(bin_path, 'p')
  endif

  var filename = fnamemodify(media_path, ':t')
  var dest = bin_path .. '/' .. filename

  var counter = 1
  var base = fnamemodify(filename, ':t:r')
  var ext = fnamemodify(filename, ':e')
  while filereadable(dest) || isdirectory(dest)
    dest = bin_path .. '/' .. base .. '_' .. counter .. (empty(ext) ? '' : '.' .. ext)
    counter += 1
  endwhile

  rename(media_path, dest)
  return true
enddef

defcompile