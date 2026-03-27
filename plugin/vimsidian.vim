vim9script

import autoload "vimsidian.vim" as vimsidian

command! -nargs=+ VimsidianNew call vimsidian.OpenOrCreateNote(<q-args>)
command! -nargs=+ VimsidianOpen call vimsidian.OpenNote(<q-args>)
command! -nargs=0 VimsidianFollowLink call vimsidian.FollowLink()
command! VimsidianToday call vimsidian.TodayNote()
command! VimsidianBacklinks call vimsidian.Backlinks()
command! VimsidianPicker call vimsidian.VimsidianPicker()
