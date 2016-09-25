scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

runtime lib/tag_list.vim
runtime lib/master_document.vim
runtime lib/exnote_session.vim

let g:ExnoteEventManager = {}
function! g:ExnoteEventManager.setEvent(func,object)
    let g:ExnoteEventManager.object = a:object
    let g:ExnoteEventManager.object.func = a:func
    nnoremap <silent> <buffer> <cr> :call g:ExnoteEventManager.gofunc()  <cr>
endfunction
function! g:ExnoteEventManager.gofunc()
    call g:ExnoteEventManager.object.func()
endfunction


function! s:Exnote()
    let self = {}
    let self.name = "exnote"
    let self.exnote_sessions = []
    
    function! self.getSession()
        " ここで開いたバッファがマスター文書クラスで管理しているか調べる
        " マスター文書クラスのリストを全部舐めて、バッファ番号が一致するか調べる
        " 現在のバッファ番号を取得する
        let l:current_buffer = bufnr("")

        let l:is_exnote_session_managed = 0
        let l:exnote_session = {}

        for exnote_session in self.exnote_sessions
            if exnote_session.isManaging(l:current_buffer)
                let l:is_exnote_session_managed = 1
                let l:exnote_session = exnote_session
            endif
        endfor
        " まだ管理してなかったら管理対象に追加する
        if l:is_exnote_session_managed == 0
            let l:exnote_session = g:ExnoteSession()
            call add(self.exnote_sessions,l:exnote_session)
        endif

        " この時点でExnoteを呼び出した文書を管理しているexnote_sessionインスタンスが存在する
        return l:exnote_session
    endfunction
    
    " タグリスト開閉のトグル
    function! self.toggleTagList()
        
        let l:exnote_session = self.getSession()
        
        " exnote_sessionにタグリストをトグルさせる
        call l:exnote_session.toggleTagList()

    endfunction

    function! self.tagSearch(query)
        let l:exnote_session = self.getSession()
        call l:exnote_session.tagSearch(a:query)
    endfunction

    return self
endfunction

let s:exnote = s:Exnote()

command! -nargs=1 ExnoteTagSearch call s:exnote.tagSearch(<args>)
command! -nargs=0 ExnoteTagList call s:exnote.toggleTagList(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo

