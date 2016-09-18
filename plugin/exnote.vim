scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

let s:Exnote = {}
" タグリストを開いているかフラグ
let s:Exnote.is_exnote_tag_list_open = 0
" タグリストを開いているバッファ
let s:Exnote.tag_list_buffer_name = -1

" タグリストを閉じる
function! s:Exnote.closeTagList()
    if s:Exnote.tag_list_buffer_name >= 0
        " タグリストが開いているバッファのウィンドウ番号
        let s:tag_list_win_name = bufwinnr(s:Exnote.tag_list_buffer_name)
        " ウィンドウ移動
        exec(s:tag_list_win_name.' wincmd w')
        " 閉じる
        " close
        q!
    endif
endfunction

" タグリストを開く
function! s:Exnote.openTagList()
    let l:tag_list =  s:Exnote.createTagList()
    echo l:tag_list
    vnew
    vertical resize 30

    let l:tag_list_count = 0
    for tag in l:tag_list
        call setline(l:tag_list_count, tag[0]." (".tag[1].")")
        let l:tag_list_count += 1
    endfor
    " タグリストを開いたバッファ番号を保存
    let s:Exnote.tag_list_buffer_name = bufnr("")
endfunction

" タグリスト開閉のトグル
function! s:Exnote.toggleTagList()
    " すでに開いているとき
    if s:Exnote.is_exnote_tag_list_open == 1
        " タグリストを閉じる
        call s:Exnote.closeTagList()
        " タグリストを開いているフラグを落とす
        let s:Exnote.is_exnote_tag_list_open = 0
        return
    endif
    " タグリストを開く
    call s:Exnote.openTagList()
    " タグリストを開いているフラグを立てる
    let s:Exnote.is_exnote_tag_list_open = 1
endfunction

function! s:CheckMatchLine(line, query)
    " * [xx,xx]にマッチさせる
    let s:tag_space = matchstr(a:line, '\* \[.*\]', 0)
    " [or, query ]or,にマッチさせる
    let s:query = '[\[\,]'. a:query . '[\]\,]'
    let s:matched_str = matchstr(s:tag_space, s:query)
    let s:is_matched = ( s:matched_str != '' )
    return s:is_matched
endfunction

function! s:GetTagsInStr(line)
    " * [xx,xx]にマッチさせる
    let l:tag_space = matchstr(a:line, '\* \[.*\]', 0)
    " [xx,xx]にマッチさせる
    let l:frame = matchstr(l:tag_space, '\[.*\]', 0)
    " xx,xxにマッチさせる
    let l:tags_str = strpart(l:frame,1,strlen(l:frame)-2)
    " echom "matche_str".l:tags_str
    " リストに入れる
    let l:tags = split(l:tags_str,",")

    return l:tags
endfunction

function! s:Exnote.allLineInDocument()
    " 開いているファイルの行数を調べる
    let l:line_count = line("$")
    " 全行をリストに入れる
    let l:lines = getline(1,l:line_count)
    return l:lines
endfunction

" let s:Exnote.tag_list = []

function! s:Exnote.createTagList()
    let l:saved_tag_list = []
    let l:lines = s:Exnote.allLineInDocument()
    " 全行を調べる
    for l:line in l:lines
        " 一行でマッチしたタグ
        let l:tags_in_line = s:GetTagsInStr(l:line)
        for searched_tag in l:tags_in_line
            let l:is_saved = 0
            for saved_tag in l:saved_tag_list
                if saved_tag[0] == searched_tag
                    let l:is_saved = 1
                endif
            endfor
            if l:is_saved
                let saved_tag[1] = saved_tag[1] + 1
            else
                call add(l:saved_tag_list, [searched_tag, 1])
            endif
        endfor
    endfor
    return l:saved_tag_list
endfunction

" query 検索するタグ文字列
function! s:Exnote.tagSearch(query)
    
    let l:lines = s:Exnote.allLineInDocument()
    
    " マッチした行を入れるためのリスト
    let l:list = []
    let l:add_flag = 0

    " 全行を調べる
    for l:line in l:lines
    
        " 行がマッチしたか
        let l:is_matched = s:CheckMatchLine(l:line, a:query)

        " マッチしてたらフラグを上げる
        if l:is_matched
            let l:add_flag = 1
        endif
    
        " フラグが上がってたら追加
        " フラグは次に空白列が来るまで上がっている
        if l:add_flag == 1
            call add(l:list, l:line)
        endif
    
        " 空白列が来たらフラグをさげる
        if l:line == ''
            let l:add_flag = 0
        endif
    endfor
    
    " 新しいタブを開いて、マッチした文字を挿入する
    tabnew
    call setline(".", l:list)
endfunction


command! -nargs=1 ExnoteTagSearch call s:Exnote.tagSearch(<args>)
command! -nargs=0 ExnoteTagList call s:Exnote.toggleTagList(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo

