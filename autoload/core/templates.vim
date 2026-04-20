vim9script

import autoload "core/vault.vim" as vault


export def GetTemplatePath(name: string): string
    var template_dir = vault.GetDataPath() .. '/templates'
    return template_dir .. '/' .. name .. '.md'
enddef

export def ApplyTemplate(file_path: string, template_name: string): bool
    var template_path = GetTemplatePath(template_name)

    if !filereadable(template_path)
        echoerr 'Template not found: ' .. template_name
        return false
    endif

    echom file_path

    var title = fnamemodify(file_path, ':t:r')

    var replacements = {
        '{{TITLE}}': title,
        '{{DATE}}': strftime('%Y-%m-%d'),
        '{{TIME}}': strftime('%H:%M'),
        '{{DATETIME}}': strftime('%Y-%m-%d %H:%M'),
        '{{YEAR}}': strftime('%Y'),
        '{{MONTH}}': strftime('%m'),
        '{{DAY}}': strftime('%d'),
        '{{WEEKDAY}}': strftime('%A'),
        '{{VAULT}}': vault.GetVaultPath(),
        '{{TEMPLATE}}': template_name,
    }

    var content = readfile(template_path)

    content = map(content, (_, original_line) => {
        var line = original_line

        for [placeholder, value] in items(replacements)
            line = substitute(line, '\V' .. placeholder, value, 'g')
        endfor

        return line
    })

    writefile(content, file_path)

    return true
enddef

export def ListTemplates(): list<string>
    var template_dir = vault.GetDataPath() .. '/templates'
    if !isdirectory(template_dir)
        mkdir(template_dir, 'p')
    endif

    return map(
        split(globpath(template_dir, '*.md'), '\n'),
        (_, v) => fnamemodify(v, ':t:r')
    )
enddef

