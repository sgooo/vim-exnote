scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

let s:Exnote = {}
let s:Exnote.is_exnote_tag_list_open = 0
let s:Exnote.tag_list_buffer_name = -1

function! s:Exnote.closeTagList()
    if s:Exnote.tag_list_buffer_name >= 0
        let s:tag_list_win_name = bufwinnr(s:Exnote.tag_list_buffer_name)
        exec(s:tag_list_win_name.' wincmd w')
        close
    endif
endfunction

function! s:Exnote.openTagList()
    vnew
    vertical resize 30
    let s:Exnote.tag_list_buffer_name = bufnr("")
endfunction

function! s:Exnote.toggleTagList()
    " すでに開いているとき
    if s:Exnote.is_exnote_tag_list_open == 1
        call s:Exnote.closeTagList()
        let s:Exnote.is_exnote_tag_list_open = 0
        return
    endif
    call s:Exnote.openTagList()
    let s:Exnote.is_exnote_tag_list_open = 1
endfunction

function! MatchLine(line, query)
    " * [xx,xx]にマッチさせる
    let s:tag_space = matchstr(a:line, '\* \[.*\]', 0)
    " [or, query ]or,にマッチさせる
    let s:query = '[\[\,]'. a:query . '[\]\,]'
    let s:matched_str = matchstr(s:tag_space, s:query)
    let s:is_matched = ( s:matched_str != '' )
    return s:is_matched
endfunction

" query 検索するタグ文字列
function! s:Exnote.tagSearch(query)
    " 開いているファイルの行数を調べる
    let line_count = line("$")
    " 全行をリストに入れる
    let s:lines = getline(1,line_count)
    
    " マッチした行を入れるためのリスト
    let s:list = []
    let s:add_flag = 0

    " 全行を調べる
    for s:line in s:lines
    
        " 行がマッチしたか
        let s:is_matched = MatchLine(s:line, a:query)

        " マッチしてたらフラグを上げる
        if s:is_matched
            let s:add_flag = 1
        endif
    
        " フラグが上がってたら追加
        " フラグは次に空白列が来るまで上がっている
        if s:add_flag == 1
            call add(s:list, s:line)
        endif
    
        " 空白列が来たらフラグをさげる
        if s:line == ''
            let s:add_flag = 0
        endif
    endfor
    
    " 新しいタブを開いて、マッチした文字を挿入する
    tabnew
    call setline(".", s:list)
endfunction


command! -nargs=1 ExnoteTagSearch call s:Exnote.tagSearch(<args>)
" command! -nargs=0 ExnoteTagList call ExnoteTagList(<args>)
command! -nargs=0 ExnoteTagList call s:Exnote.toggleTagList(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo

