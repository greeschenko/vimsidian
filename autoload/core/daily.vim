vim9script

import autoload 'core/vault.vim'
import autoload 'core/reminders.vim' as reminders

# ----------------------------
# Daily notes domain
# ----------------------------
export def TodayNote()
  var vault_path = vault.GetVaultPath()
  var today = strftime('%Y-%m-%d')
  var year = strftime('%Y')

  var dir = vault_path .. '/data/daily/' .. year
  if !isdirectory(dir)
    mkdir(dir, 'p')
  endif

  var path = dir .. '/' .. today .. '.md'
  if !filereadable(path)
    reminders.ScanAllNotesForReminders()
    var reminder_lines = reminders.GetRemindersForDailyNote()

    var content: list<string> = ['# ' .. today, '']

    if !empty(reminder_lines)
      content = content + ['## Reminders', ''] + reminder_lines + ['']
    endif

    content = content + ['## Tasks', '', '## Notes', '']

    writefile(content, path)
  endif

  execute 'edit ' .. fnameescape(path)
enddef

defcompile
