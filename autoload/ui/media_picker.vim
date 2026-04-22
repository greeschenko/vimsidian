vim9script

import autoload 'core/media.vim' as media
import autoload 'core/vault.vim' as vault
import autoload 'ui/picker.vim' as picker

export def OpenMediaPicker()
  var files = media.GetAllMedia()
  var file_names = map(files, (_, f) => fnamemodify(f, ':t'))

  picker.Open(file_names, {
    item_paths: files,

    resolve_path: (name: string) => vault.GetMediaPath() .. '/' .. name,

    preview: (name) => {
      var path = vault.GetMediaPath() .. '/' .. name
      if !filereadable(path)
        return ['(file not found)']
      endif
      return ['File: ' .. name]
    },

    on_select: (name) => {
      var path = vault.GetMediaPath() .. '/' .. name
      execute 'edit ' .. fnameescape(path)
    },

    on_insert: (name) => {
      var link = '![' .. fnamemodify(name, ':t:r') .. '](' .. name .. ')'
      var line = getline('.')
      var coln = col('.') - 1
      setline('.', strpart(line, 0, coln) .. link .. strpart(line, coln))
    }
  })
enddef

defcompile