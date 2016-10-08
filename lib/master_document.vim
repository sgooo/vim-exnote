
function! g:MasterDocument()
    let self = {}

    let self.buffer_name = -1

    function! self.MasterDocument()
        " 生成されるときは常に管理対象のバッファで
        let self.buffer_name = bufnr("")
    endfunction

    function! self.isManaging(buffer_name)
        " echom "isManagin mybuffer: " . self.buffer_name . " querybuffer: " . a:buffer_name
        if self.buffer_name == a:buffer_name
            return 1
        endif
        return 0
    endfunction

    function! self.moveOwnPosition()
        let s:body_win_name = bufwinnr(self.buffer_name)
        " ウィンドウ移動
        exec(s:body_win_name.' wincmd w')
    endfunction

    function! self.getTagsInDocument()
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
    function! self.createNotes(query)
        call self.moveOwnPosition()

        let l:notes = []
        let l:saved_tag_list = []
        let l:lines = self.allLineInDocument()
        " 全行を調べる
        for l:line in l:lines
            " 一行でマッチしたタグ
            let l:tags_in_line = self.getTagsInStr(l:line)
            let l:is_start = 0
            if len(l:tags_in_line) > 0
                let l:is_start = 1
            endif

            " 空白列が来たらフラグをさげる
            if l:line == ''
                let l:add_flag = 0
            endif
        endfor


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
        
        return l:list
    endfunction

    " query 検索するタグ文字列
    function! self.tagSearch(query)
        call self.moveOwnPosition()
        
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
        
        return l:list
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


    call self.MasterDocument()
    return self
endfunction

