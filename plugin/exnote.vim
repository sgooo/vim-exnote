scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script
"
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
        " 本文の開いている
    let self.body_buffer_name = -1
    let self.name = "exnote"
    let self.exnote_sessions = []
    
    
    " タグリスト開閉のトグル
    function! self.toggleTagList()
        " ここで開いたバッファがマスター文書クラスで管理しているか調べる
        " マスター文書クラスのリストを全部舐めて、バッファ番号が一致するか調べる
        " 現在のバッファ番号を取得する
        let l:current_buffer = bufnr("")

        let l:is_exnote_session_managed = 0
        let l:exnote_session = {}
        " ここを、ここにロジックを書くのではなく、exnoteSessionに自分の管理しているバッファか調べさせる
        for exnote_session in self.exnote_sessions
            if exnote_session.isManaging(l:current_buffer)
                let l:is_exnote_session_managed = 1
                let l:exnote_session = exnote_session
            endif
        endfor
        " まだ管理してなかったら管理対象に追加する
        if l:is_exnote_session_managed == 0
            let l:exnote_session = s:ExnoteSession()
            call add(self.exnote_sessions,l:exnote_session)
        endif

        " この時点でExnoteを呼び出した文書を管理しているexnote_sessionインスタンスが存在する
        
        " exnote_sessionにタグリストをトグルさせる
        call l:exnote_session.toggleTagList()

    endfunction




    return self
endfunction

function! s:MasterDocument()
    let self = {}

    let self.buffer_name = -1

    function! self.MasterDocument()
        " 生成されるときは常に管理対象のバッファで
        let self.buffer_name = bufnr("")
    endfunction

    function! self.isManaging(buffer_name)
        if self.buffer_name == a:buffer_name
            return 1
        endif
        return 0
    endfunction

    call self.MasterDocument()
    return self
endfunction

function! s:TagList()
    let self = {}
    " タグリストを開いているバッファ
    let self.tag_list_buffer_name = -1
    let self.callbackfunc = {}
    let self.callbackobj = {}

    " 自分の管理しているバッファまで移動して、自分で閉じる
    function! self.close()
        if self.tag_list_buffer_name >= 0
            " タグリストが開いているバッファのウィンドウ番号
            let s:tag_list_win_name = bufwinnr(self.tag_list_buffer_name)
            " ウィンドウ移動
            exec(s:tag_list_win_name.' wincmd w')
            " 閉じる
            " close
            q!
        endif
    endfunction

    function! self.open(tag_list)
        let l:tag_list = a:tag_list
        vnew
        vertical resize 30
    
        " １行目から追加する
        let l:tag_list_count = 1
        for tag in l:tag_list
            call setline(l:tag_list_count, tag[0]." (".tag[1].")")
            let l:tag_list_count += 1
        endfor
        " タグリストを開いたバッファ番号を保存
        let self.tag_list_buffer_name = bufnr("")

        " ここはsessionがコールバックを受けるような作りにしたい
        " call g:ExnoteEventManager.setEvent(self.TagSearchExt,self)
        call g:ExnoteEventManager.setEvent(self.callbackfunc,self.callbackobj)
    endfunction

    function! self.addSelectTagEvent(func,instance)
        let self.callbackfunc = a:func
        let self.callbackobj = a:instance
    endfunction

    function! self.isManaging(buffer_name)
        if self.tag_list_buffer_name == a:buffer_name
            return 1
        endif
        return 0
    endfunction

    return self
endfunction

function! s:ExnoteSession()
    let self = {}
    " タグリストを開いているかフラグ
    let self.is_exnote_tag_list_open = 0
        let self.master_document = {}
    let self.tag_list = {}

    function! self.ExnoteSession()
        echom "exnotesession construct"
        let self.master_document = s:MasterDocument()
        let self.tag_list = s:TagList()
        call self.tag_list.addSelectTagEvent(self.callbacktest,self)
    endfunction

    function! self.callbacktest()
        echom "コールバック"
        call self.TagSearchExt()
    endfunction

    " 自分の管理しているバッファか
    " 基本的にmaster_documentかtaglistか
    function! self.isManaging(buffer_name)
        if self.tag_list.isManaging(a:buffer_name) || self.master_document.isManaging(a:buffer_name)
            return 1
        endif
        return 0
    endfunction

    function! self.toggleTagList()
        " すでに開いているとき
        if self.is_exnote_tag_list_open == 1
            " タグリストを閉じる
            call self.closeTagList()
            " タグリストを開いているフラグを落とす
            let self.is_exnote_tag_list_open = 0
            return
        endif
        " タグリストを開く
        call self.openTagList()
        " タグリストを開いているフラグを立てる
        let self.is_exnote_tag_list_open = 1
    endfunction

    " タグリストを閉じる
    function! self.closeTagList()
        call self.tag_list.close()
    endfunction

    " タグリストを開く
    function! self.openTagList()
        let l:tag_list =  self.createTagList()
        " 本文を開いているバッファ番号を保存
        
        let self.body_buffer_name = bufnr("")
        call self.tag_list.open(l:tag_list)
    endfunction

    function! self.createTagList()
        let l:saved_tag_list = []
        let l:lines = self.allLineInDocument()
        " 全行を調べる
        for l:line in l:lines
            " 一行でマッチしたタグ
            let l:tags_in_line = self.getTagsInStr(l:line)
            " 一行中のタグを全部ループで回す
            for searched_tag in l:tags_in_line
                let l:is_saved = 0
                " 保存しているタグを全部ループで回す
                for saved_tag in l:saved_tag_list
                    " マッチしたら
                    if saved_tag[0] == searched_tag
                        " すでに保存されている
                        let l:is_saved = 1
                        " 保存しているタグ数を１追加
                        let saved_tag[1] += 1
                    endif
                endfor
                " 保存されていなければ
                if !l:is_saved
                    " 保存するタグリストにタグを追加
                    call add(l:saved_tag_list, [searched_tag, 1])
                endif
            endfor
        endfor
        return l:saved_tag_list
    endfunction

    function! self.allLineInDocument()
        " 開いているファイルの行数を調べる
        let l:line_count = line("$")
        " 全行をリストに入れる
        let l:lines = getline(1,l:line_count)
        return l:lines
    endfunction

    function! self.getTagsInStr(line)
        " * [xx,xx]にマッチさせる
        let l:tag_space = matchstr(a:line, '\* \[[^\]]*\]', 0)
        " [xx,xx]にマッチさせる
        let l:frame = matchstr(l:tag_space, '\[.*\]', 0)
        " xx,xxにマッチさせる
        let l:tags_str = strpart(l:frame,1,strlen(l:frame)-2)
        " リストに入れる
        let l:tags = split(l:tags_str,",")
    
        return l:tags
    endfunction

    " query 検索するタグ文字列
    function! self.tagSearch(query)
        
        let l:lines = self.allLineInDocument()
        
        " マッチした行を入れるためのリスト
        let l:list = []
        let l:add_flag = 0
    
        " 全行を調べる
        for l:line in l:lines
        
            " 行がマッチしたか
            let l:is_matched = self.CheckMatchLine(l:line, a:query)
    
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

    function! self.TagSearchExt()
        echom "TagSearchExt"
        " 選択した行の文字列を取得
        let l:selected_line = getline(".")
        let l:query = split(l:selected_line," ")[0]
        let l:query = split(l:selected_line," ")[0]
        let s:body_win_name = bufwinnr(self.body_buffer_name)
        " ウィンドウ移動
        exec(s:body_win_name.' wincmd w')
    
        call self.tagSearch(l:query)
    endfunction


    function! self.CheckMatchLine(line, query)
        let l:is_matched = 0
        let l:tags = self.getTagsInStr(a:line)
        for tag in l:tags
            if tag == a:query
                let l:is_matched = 1
            endif
        endfor
        return l:is_matched
    endfunction

    call self.ExnoteSession()
    return self
endfunction

let s:exnote = s:Exnote()

command! -nargs=1 ExnoteTagSearch call s:exnote.tagSearch(<args>)
command! -nargs=0 ExnoteTagList call s:exnote.toggleTagList(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo

