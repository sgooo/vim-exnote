scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

function! Q(query)
    return '\[' . a:query . '\]'
endfunction

function! Exnote(query)
    let line_count = line("$")
    let s:lines = getline(1,line_count)
    
    let s:query = Q(a:query)
    
    let s:list = []
    let s:add_flag = 0

    for s:line in s:lines
    
        let s:is_matched = ( matchstr(s:line, s:query) != '' )
        if s:is_matched
            let s:add_flag = 1
        endif
    
        if s:add_flag == 1
            call add(s:list, s:line)
        endif
    
        if s:line == ''
            let s:add_flag = 0
        endif
    endfor
    
    tabnew
    call setline(".", s:list)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

