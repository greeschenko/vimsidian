vim9script

import autoload 'core/media.vim' as media
import autoload 'core/vault.vim' as vault

var media_win = -1
var media_buf = -1
var line_to_file: dict<string> = {}

export def OpenMediaPicker()
  if media_win != -1 && win_gotoid(media_win)
    CloseMediaPickerWindow()
    return
  endif

  execute 'topleft vertical :30new'

  media_win = win_getid()
  media_buf = bufnr()

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal winfixwidth
  setlocal nobuflisted
  setlocal modifiable
  setlocal filetype=vimsidian-media

RenderMedia()

  nnoremap <buffer> r <ScriptOpen><SID>RenderMedia()<CR>
enddef

def RenderMedia()
  var files = media.GetAllMedia()
  if empty(files)
    setline(1, ['(no media files)', '', 'Drop files here or press i to insert'])
    return
  endif

  line_to_file = {}
  var lines: list<string> = []

  for f in files
    var filename = fnamemodify(f, ':t')
    var ext = fnamemodify(f, ':e')
    var icon = GetFileIcon(ext)
    add(lines, icon .. ' ' .. filename)
    line_to_file[len(lines)] = f
  endfor

  setline(1, lines)
  setline(len(lines) + 1, '')
  setline(len(lines) + 2, ['<CR> open | i insert link | d delete | r refresh | q quit'])
enddef

def GetFileIcon(ext: string): string
  if ext =~? 'png\|jpg\|jpeg\|gif\|webp\|svg'
    return '🖼'
  elseif ext =~? 'mp4\|webm\|mov\|avi'
    return '🎬'
  elseif ext =~? 'mp3\|wav\|ogg\|flac'
    return '🎵'
  elseif ext =~? 'pdf'
    return '📄'
  elseif ext =~? 'doc\|docx'
    return '📝'
  elseif ext =~? 'xls\|xlsx'
    return '📊'
  endif
  return '📎'
enddef

def OpenMedia()
  var line = line('.')
  if !has_key(line_to_file, line)
    return
  endif

  var file_path = line_to_file[line]
  CloseMediaPickerWindow()
  execute 'edit ' .. fnameescape(file_path)
enddef

def InsertMediaLink()
  var line = line('.')
  if !has_key(line_to_file, line)
    return
  endif

  var file_path = line_to_file[line]
  media.InsertMarkdownLink(file_path)
  CloseMediaPickerWindow()
enddef

def DeleteMediaFile()
  var line = line('.')
  if !has_key(line_to_file, line)
    return
  endif

  var file_path = line_to_file[line]
  var confirm = confirm('Delete ' .. fnamemodify(file_path, ':t') .. '?', '&Yes\n&No', 2)
  if confirm != 1
    return
  endif

  media.DeleteMedia(file_path)
  RenderMedia()
enddef

def CloseMediaPicker()
  CloseMediaPickerWindow()
enddef

def CloseMediaPickerWindow()
  if media_win != -1
    var wid = media_win
    media_win = -1
    media_buf = -1
    line_to_file = {}
    if win_gotoid(wid)
      close
    endif
  endif
enddef

def AddMediaFile(source_path: string): string
  var dest = media.CopyToMedia(source_path)
  if media_win != -1 && win_gotoid(media_win)
    RenderMedia()
  endif
  return dest
enddef

defcompile