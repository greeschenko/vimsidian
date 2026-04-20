vim9script

import autoload "core/vault.vim" as vault
import autoload "core/notes.vim" as notes

var tags_index: dict<list<string>> = {}

export def LoadTagsIndex()
    var index_path = GetIndexPath()

    if filereadable(index_path)
        try
            var content = readfile(index_path)
            if !empty(content)
                tags_index = json_decode(content[0])
            endif
        catch
            tags_index = {}
        endtry
    endif
enddef

export def SaveTagsIndex()
    var index_path = GetIndexPath()

    if !filereadable(index_path)
        var dir = fnamemodify(index_path, ':h')
        if !isdirectory(dir)
            mkdir(dir, 'p')
        endif
    endif

    writefile([json_encode(tags_index)], index_path)
enddef

def GetIndexPath(): string
    return vault.GetVaultPath() .. '/.tags.json'
enddef

export def ScanAllNotesForTags()
    LoadTagsIndex()

    var files = notes.GetAllNotes()
    tags_index = {}

    for f in files
        if f =~ 'reminders\.md$'
            continue
        endif

        var file_tags = ParseTagsFromFile(f)
        for t in file_tags
            if !has_key(tags_index, t)
                tags_index[t] = []
            endif

            if index(tags_index[t], f) < 0
                add(tags_index[t], f)
            endif
        endfor
    endfor

    SaveTagsIndex()
enddef

def ParseTagsFromFile(file_path: string): list<string>
    var result: list<string> = []

    if !filereadable(file_path)
        return result
    endif

    var lines = readfile(file_path, '', 100)

    for line in lines
        var tags = ExtractTagsFromLine(line)
        for t in tags
            if index(result, t) < 0
                add(result, t)
            endif
        endfor
    endfor

    return result
enddef

def ExtractTagsFromLine(line: string): list<string>
    var result: list<string> = []
    var line_lower = tolower(line)
    var pos = 0

    while pos < strchars(line)
        var match_start = stridx(line_lower, '#', pos)
        if match_start < 0
            break
        endif

        var tag_end = match_start + 1
        while tag_end < strchars(line)
            var ch = line_lower[tag_end]
            if ch !~ '[a-zA-Z0-9_-]'
                break
            endif
            tag_end += 1
        endwhile

        if tag_end > match_start + 1
            var tag = strpart(line, match_start + 1, tag_end - match_start - 1)
            if index(result, tag) < 0
                add(result, tag)
            endif
        endif

        pos = tag_end
    endwhile

    return result
enddef

export def GetAllTags(): list<string>
    LoadTagsIndex()

    var result: list<string> = sort(keys(tags_index))
    return result
enddef

export def SearchByTag(tag_name: string): list<string>
    LoadTagsIndex()

    if has_key(tags_index, tag_name)
        return tags_index[tag_name]
    endif

    return []
enddef

export def GetTagSuggestions(prefix: string): list<string>
    LoadTagsIndex()

    var all_tags = keys(tags_index)
    var result: list<string> = []

    var q = tolower(prefix)

    for t in all_tags
        if stridx(tolower(t), q) >= 0
            add(result, t)
        endif
    endfor

    return sort(result)
enddef

export def GetTagsForNote(file_path: string): list<string>
    LoadTagsIndex()

    var result: list<string> = []

    for [tag, files] in items(tags_index)
        for f in files
            if f == file_path
                add(result, tag)
                break
            endif
        endfor
    endfor

    return result
enddef

defcompile
