vim9script

import autoload "core/vault.vim" as vault
import autoload "core/notes.vim" as notes

var reminders_index: list<dict<any>> = []

export def LoadRemindersIndex()
    var index_path = GetIndexPath()

    if filereadable(index_path)
        try
            var content = readfile(index_path)
            if !empty(content)
                reminders_index = json_decode(content[0])
            endif
        catch
            reminders_index = []
        endtry
    endif
enddef

export def SaveRemindersIndex()
    var index_path = GetIndexPath()

    if !filereadable(index_path)
        var dir = fnamemodify(index_path, ':h')
        if !isdirectory(dir)
            mkdir(dir, 'p')
        endif
    endif

    writefile([json_encode(reminders_index)], index_path)
enddef

def GetIndexPath(): string
    return vault.GetVaultPath() .. '/.reminders.json'
enddef

export def GetRemindersFilePath(): string
    return vault.GetDataPath() .. '/reminders.md'
enddef

export def ScanAllNotesForReminders()
    LoadRemindersIndex()

    var files = notes.GetAllNotes()
    var found: list<dict<any>> = []
    var seen: dict<number> = {}

    for f in files
        if f =~ 'reminders\.md$'
            continue
        endif

        var file_reminders = ParseRemindersFromFile(f)
        for r in file_reminders
            var key = r.note_path .. '::' .. r.description
            if has_key(seen, key)
                continue
            endif
            seen[key] = 1
            add(found, r)
        endfor
    endfor

    reminders_index = found
    SaveRemindersIndex()

    ExportRemindersMarkdown()
enddef

def ParseRemindersFromFile(file_path: string): list<dict<any>>
    var result: list<dict<any>> = []

    if !filereadable(file_path)
        return result
    endif

    var lines = readfile(file_path)

    for line in lines
        var reminder = ParseReminderLine(line, file_path)
        if reminder != {}
            add(result, reminder)
        endif
    endfor

    return result
enddef

def ParseReminderLine(line: string, file_path: string): dict<any>
    var trimmed_line = trim(line)

    if trimmed_line !~ '^\[ \]' && trimmed_line !~ '^\s*[-*+]\s*\[ \]'
        return {}
    endif

    var content = substitute(trimmed_line, '^\s*[-*+]\s*\[ \]\s*', '', '')
    content = substitute(content, '^\[ \]\s*', '', '')

    var every_match = matchlist(content, '\vevery:(\d+)([dwms])')
    var on_match = matchlist(content, '\von:(\d{4}-\d{2}-\d{2})')
    var weekday_match = matchlist(content, '\vevery:(monday|tuesday|wednesday|thursday|friday|saturday|sunday)')

    if empty(every_match) && empty(on_match) && empty(weekday_match)
        return {}
    endif

    var description = substitute(content, '\v(every:|on:).*$', '', '')
    description = trim(description)

    if empty(description)
        description = content
    endif

    var reminder: dict<any> = {
        note_path: file_path,
        description: description,
        original_line: trimmed_line,
    }

    if !empty(every_match)
        reminder.interval_value = str2nr(every_match[1])
        reminder.interval_unit = every_match[2]
        reminder.interval_type = 'recurring'
    elseif !empty(weekday_match)
        reminder.weekday = tolower(weekday_match[1])
        reminder.interval_type = 'weekly'
    elseif !empty(on_match)
        reminder.on_date = on_match[1]
        reminder.interval_type = 'once'
    endif

    var existing = GetExistingReminder(reminder)
    if existing != {}
        reminder.last_completed = get(existing, 'last_completed', '')
    endif

    return reminder
enddef

def GetExistingReminder(new_reminder: dict<any>): dict<any>
    for r in reminders_index
        if r.note_path == new_reminder.note_path && r.description == new_reminder.description
            return r
        endif
    endfor
    return {}
enddef

export def GetDueReminders(): list<dict<any>>
    LoadRemindersIndex()

    var today = strftime('%Y-%m-%d')
    var weekday = tolower(strftime('%a'))
    var day_of_month = str2nr(strftime('%d'))
    var result: list<dict<any>> = []
    var seen: dict<number> = {}

    for r in reminders_index
        if r.note_path =~ 'reminders\.md$'
            continue
        endif
        var key = r.note_path .. '::' .. r.description
        if has_key(seen, key)
            continue
        endif
        seen[key] = 1

        if IsReminderDue(r, today, weekday, day_of_month)
            add(result, r)
        endif
    endfor

    return result
enddef

def IsReminderDue(r: dict<any>, today: string, weekday: string, day_of_month: number): bool
    var interval_type = get(r, 'interval_type', '')

    if interval_type == 'once'
        var on_date = get(r, 'on_date', '')
        if on_date == today
            return true
        endif
        if on_date < today
            return true
        endif
        return false
    endif

    if interval_type == 'weekly'
        var r_weekday = get(r, 'weekday', '')
        if r_weekday == weekday
            return true
        endif
        return false
    endif

    if interval_type == 'recurring'
        var last_completed = get(r, 'last_completed', '')

        if empty(last_completed)
            return true
        endif

        var value = get(r, 'interval_value', 0)
        var unit = get(r, 'interval_unit', 'd')

        var days_since = DaysBetween(last_completed, today)

        if unit == 'd'
            return days_since >= value
        elseif unit == 'w'
            return days_since >= value * 7
        elseif unit == 'm'
            return day_of_month >= value
        elseif unit == 's'
            return day_of_month == value
        endif
    endif

    return false
enddef

def DaysBetween(date1: string, date2: string): number
    var d1 = ParseDate(date1)
    var d2 = ParseDate(date2)

    if d1.year == d2.year && d1.month == d2.month
        return abs(d2.day - d1.day)
    endif

    var time1 = str2nr(printf('%04d%02d%02d', d1.year, d1.month, d1.day))
    var time2 = str2nr(printf('%04d%02d%02d', d2.year, d2.month, d2.day))

    return abs(time2 - time1)
enddef

def ParseDate(date_str: string): dict<number>
    var parts = split(date_str, '-')
    return {
        year: str2nr(parts[0]),
        month: str2nr(parts[1]),
        day: str2nr(parts[2]),
    }
enddef

export def MarkReminderComplete(note_path: string, description: string)
    LoadRemindersIndex()

    var today = strftime('%Y-%m-%d')

    for r in reminders_index
        if r.note_path == note_path && r.description == description
            r.last_completed = today
            break
        endif
    endfor

    SaveRemindersIndex()
    ExportRemindersMarkdown()
enddef

export def ExportRemindersMarkdown()
    LoadRemindersIndex()

    var lines: list<string> = [
        '# Reminders',
        '',
    ]

    var due = GetDueReminders()

    if empty(due)
        lines = lines + ['(no due reminders)', '']
    else
        lines = lines + ['## Due Today', '']

        for r in due
            var note_link = notes.GetNoteLinkId(r.note_path)
            var line = '- [ ] ' .. r.description .. ' (from [[' .. note_link .. ']])'

            if has_key(r, 'interval_type')
                if r.interval_type == 'recurring'
                    line ..= ' every:' .. r.interval_value .. r.interval_unit
                elseif r.interval_type == 'weekly'
                    line ..= ' every:' .. r.weekday
                elseif r.interval_type == 'once'
                    line ..= ' on:' .. r.on_date
                endif
            endif

            add(lines, line)
        endfor

        add(lines, '')
    endif

    var all_notes = filter(copy(reminders_index), (_, r) => get(r, 'interval_type', '') == 'recurring')

    if !empty(all_notes)
        lines = lines + ['## All Recurring', '']

        for r in all_notes
            var note_title = notes.GetNoteTitle(r.note_path)
            var line = '- [ ] ' .. r.description .. ' (from [[' .. note_title .. ']])'

            if has_key(r, 'interval_type')
                if r.interval_type == 'recurring'
                    line ..= ' every:' .. r.interval_value .. r.interval_unit
                elseif r.interval_type == 'weekly'
                    line ..= ' every:' .. r.weekday
                endif
            endif

            add(lines, line)
        endfor
    endif

    writefile(lines, GetRemindersFilePath())
enddef

export def GetRemindersForDailyNote(): list<string>
    var due = GetDueReminders()

    var lines: list<string> = []

    for r in due
        var note_link = notes.GetNoteLinkId(r.note_path)
        var line = '- [ ] ' .. r.description .. ' (from [[' .. note_link .. ']])'

        if has_key(r, 'interval_type')
            if r.interval_type == 'recurring'
                line ..= ' every:' .. r.interval_value .. r.interval_unit
            elseif r.interval_type == 'weekly'
                line ..= ' every:' .. r.weekday
            elseif r.interval_type == 'once'
                line ..= ' on:' .. r.on_date
            endif
        endif

        add(lines, line)
    endfor

    return lines
enddef

defcompile
