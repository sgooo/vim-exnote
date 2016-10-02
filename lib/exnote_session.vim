

function! g:ExnoteSession(id)
    let self = {}
    let self.master_document = {}
    let self.tag_list = {}
    let self.id = -1

    function! self.ExnoteSession(id)
        let self.master_document = g:MasterDocument()
        let self.tag_list = g:TagList(a:id)
        let self.id = a:id
        call self.tag_list.addSelectTagEventListener(self.selectTag,self)
    endfunction

    function! self.selectTag(selected_tag)
        call self.tagSearch(a:selected_tag)
    endfunction

    " 自分の管理しているバッファか
    " 基本的にmaster_documentかtaglistか
    function! self.isManaging(buffer_name)
        if self.tag_list.isManaging(a:buffer_name) || self.master_document.isManaging(a:buffer_name)
            return 1
        endif
        return 0
    endfunction

    function! self.isManagingMaster(buffer_name)
        if self.master_document.isManaging(a:buffer_name) == 1
            return 1
        endif
        return 0
    endfunction

    function! self.toggleTagList()
        " すでに開いているとき
        if self.tag_list.isOpen() == 1
            " タグリストを閉じる
            call self.closeTagList()
            return
        endif
        " タグリストを開く
        call self.openTagList()
    endfunction

    " タグリストを閉じる
    function! self.closeTagList()
        call self.tag_list.close()
    endfunction

    " タグリストを開く
    function! self.openTagList()

        let l:debug_fromtime = system("date +%s%3N")



        let l:tags =  self.master_document.getTagsInDocument()
        call self.tag_list.open(l:tags)


        let l:debug_totime = system("date +%s%3N")
        let l:debug_str = "exnote_session:oepnTagList " . (l:debug_totime - l:debug_fromtime) . " nanosec"
        call system("echo " . l:debug_str . " >> ~/debugexnote.log")

    endfunction

    function! self.moveToWin(query)
        let l:bufname = fnamemodify(bufname(""), ':t')   
        let l:first = bufnr("")
        let l:target = -1
        while l:first != l:target
            wincmd w
            let l:target = bufnr("")
            let l:bufname = fnamemodify(bufname(""), ':t')   
            if l:bufname == a:query
                return 1
            endif
        endwhile
        return 0
    endfunction

    function! self.moveToBuffer(query)
        let l:bufname = fnamemodify(bufname(""), ':t')   
        while a:query != l:bufname
            tabn
            let l:flg = self.moveToWin(a:query)
            if l:flg
                break
            endif
            let l:bufname = fnamemodify(bufname(""), ':t')   
        endwhile
    endfunction

    function! self.tagSearch(query)
        
        
        let l:cache_dir = g:exnote_root_path . "/../cache"
        let l:file_path = l:cache_dir . "/".a:query
        
        " TODO:コード改善
        if bufexists(l:file_path) 
            call self.moveToBuffer(a:query)
        else
            tabnew 
        endif

        " チェックの仕組みはこれでいい
        " TODO:すでにあってかつ同じ検索ならそのタブを開く
        " すでにファイルがあることと、vim上のバッファで開いていることは別
        " 両方に対応する必要
        " 同名のバッファが開いているかも確認
        if findfile(l:file_path, "./") != ""
            execute "e! "  . l:file_path
        else
            let l:tags = self.master_document.tagSearch(a:query)
            " 新しいタブを開いて、マッチした文字を挿入する
            call setline(".", l:tags)
            execute "saveas!"  . l:file_path
        endif

        " echom l:command
        " execute l:command
        " redir END
        " e! "~/ex:".a:query
    endfunction
    
    call self.ExnoteSession(a:id)
    return self
endfunction
