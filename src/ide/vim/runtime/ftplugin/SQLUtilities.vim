" SQLUtilities:   Variety of tools for writing SQL
"   Author:	  David Fishburn <fishburn@ianywhere.com>
"   Date:	  Nov 23, 2002
"   Last Changed: Mon Jun 21 2004 10:03:30
"   Version:	  1.3.6
"   Script:	  http://www.vim.org/script.php?script_id=492
"   License:      GPL (http://www.gnu.org/licenses/gpl.html)
"
"   Dependencies:
"        Align.vim - Version 15 (as a minimum)
"                  - Author: Charles E. Campbell, Jr.
"                  - http://www.vim.org/script.php?script_id=294
"   Documentation:
"        :h SQLUtilities.txt 
"

" Prevent duplicate loading
if exists("g:loaded_sqlutilities") || &cp
    finish
endif
let g:loaded_sqlutilities = 1

if !exists('g:sqlutil_align_where')
    let g:sqlutil_align_where = 1
endif

if !exists('g:sqlutil_align_comma')
    let g:sqlutil_align_comma = 0
endif

if !exists('g:sqlutil_align_first_word')
    let g:sqlutil_align_first_word = 1
endif

if !exists('g:sqlutil_cmd_terminator')
    let g:sqlutil_cmd_terminator = ';'
endif

if !exists('g:sqlutil_keyword_case')
    " This controls whether keywords should be made
    " upper or lower case.
    " The default is to leave in current case.
    let g:sqlutil_keyword_case = ''
endif

if !exists('g:sqlutil_col_list_terminators')
    " You can override which keywords will determine
    " when a column list finishes:
    "        CREATE TABLE customer (
    "        	id	INT DEFAULT AUTOINCREMENT,
    "        	last_modified TIMESTAMP NULL,
    "        	first_name     	VARCHAR(30) NOT NULL,
    "        	last_name	VARCHAR(60) NOT NULL,
    "        	balance	        NUMERIC(10,2),
    "        	PRIMARY KEY( id )
    "        );
    " So in the above example, when "primary" is reached, we
    " know the column list is complete.
    let g:sqlutil_col_list_terminators = 
                \ 'primary'    " PRIMARY KEY
                \ ',reference' " foreign keys
                \ ',unique'    " indicies
                \ ',check'     " check contraints
                \ ',foreign'   " foreign keys
endif

" Public Interface:
command! -range -nargs=* SQLUFormatter <line1>,<line2> 
            \ call s:SQLU_Formatter(<f-args>)
command!        -nargs=* SQLUCreateColumnList  
            \ call SQLU_CreateColumnList(<f-args>)
command!        -nargs=* SQLUGetColumnDef 
            \ call SQLU_GetColumnDef(<f-args>)
command!        -nargs=* SQLUGetColumnDataType 
            \ call SQLU_GetColumnDef(expand("<cword>"), 1)
command!        -nargs=* SQLUCreateProcedure 
            \ call SQLU_CreateProcedure(<f-args>)

if !exists("g:sqlutil_load_default_maps")
    let g:sqlutil_load_default_maps = 1
endif 

if(g:sqlutil_load_default_maps == 1)
    if !hasmapto('<Plug>SQLUFormatter')
        nmap <unique> <Leader>sf <Plug>SQLUFormatter
        vmap <unique> <Leader>sf <Plug>SQLUFormatter
    endif 
    if !hasmapto('<Plug>SQLUCreateColumnList')
        nmap <unique> <Leader>scl <Plug>SQLUCreateColumnList
    endif 
    if !hasmapto('<Plug>SQLUGetColumnDef')
        nmap <unique> <Leader>scd <Plug>SQLUGetColumnDef
    endif 
    if !hasmapto('<Plug>SQLUGetColumnDataType')
        nmap <unique> <Leader>scdt <Plug>SQLUGetColumnDataType
    endif 
    if !hasmapto('<Plug>SQLUCreateProcedure')
        nmap <unique> <Leader>scp <Plug>SQLUCreateProcedure
    endif 
endif 

if exists("g:loaded_sqlutilities_global_maps")
    vunmap <unique> <script> <Plug>SQLUFormatter
    nunmap <unique> <script> <Plug>SQLUFormatter
    nunmap <unique> <script> <Plug>SQLUCreateColumnList
    nunmap <unique> <script> <Plug>SQLUGetColumnDef
    nunmap <unique> <script> <Plug>SQLUGetColumnDataType
    nunmap <unique> <script> <Plug>SQLUCreateProcedure
endif

" Global Maps:
vmap <unique> <script> <Plug>SQLUFormatter         :SQLUFormatter<CR>
nmap <unique> <script> <Plug>SQLUFormatter         :SQLUFormatter<CR>
nmap <unique> <script> <Plug>SQLUCreateColumnList  :SQLUCreateColumnList<CR>
nmap <unique> <script> <Plug>SQLUGetColumnDef      :SQLUGetColumnDef<CR>
nmap <unique> <script> <Plug>SQLUGetColumnDataType :SQLUGetColumnDataType<CR>
nmap <unique> <script> <Plug>SQLUCreateProcedure   :SQLUCreateProcedure<CR>
let g:loaded_sqlutilities_global_maps = 1

if has("menu")
    vnoremenu <script> Plugin.SQLUtil.Format\ Statement :SQLUFormatter<CR>
    noremenu  <script> Plugin.SQLUtil.Format\ Statement :SQLUFormatter<CR>
    noremenu  <script> Plugin.SQLUtil.Create\ Procedure :SQLUCreateProcedure<CR>
    inoremenu <script> Plugin.SQLUtil.Create\ Procedure  
                \ <C-O>:SQLUCreateProcedure<CR>
    noremenu  <script> Plugin.SQLUtil.Create\ Column\ List   
                \ :SQLUCreateColumnList<CR>
    inoremenu <script> Plugin.SQLUtil.Create\ Column\ List 
                \ <C-O>:SQLUCreateColumnList<CR>
    noremenu  <script> Plugin.SQLUtil.Column\ Definition 
                \ :SQLUGetColumnDef<CR>
    inoremenu <script> Plugin.SQLUtil.Column\ Definition 
                \ <C-O>:SQLUGetColumnDef<CR>
endif

" SQLU_Formatter: align selected text based on alignment pattern(s)
function! s:SQLU_Formatter(...) range
    " call Decho("SQLU_Formatter() {")
    call s:SQLU_WrapperStart( a:firstline, a:lastline )
    " Store pervious value of highlight search
    let hlsearch = &hlsearch
    let &hlsearch = 0

    " save previous search string
    let saveSearch = @/ 

    " save previous format options and turn off automatic formating
    let saveFormatOptions = &formatoptions
    silent execute 'setlocal formatoptions-=a'

    " Use the mark locations instead of storing the line numbers
    " since these values can changes based on the reformatting 
    " of the lines
    let ret = s:SQLU_ReformatStatement()
    if ret > -1
        let ret = s:SQLU_IndentNestedBlocks()
        if ret > -1
            let ret = s:SQLU_WrapLongLines()
        endif
    endif

    " Restore default value
    " And restore cursor position
    let &hlsearch = hlsearch
    call s:SQLU_WrapperEnd()

    " restore previous format options 
    let &formatoptions = saveFormatOptions 

    " restore previous search string
    let @/ = saveSearch
    
endfunction


" This function will return a count of unmatched parenthesis
" ie ( this ( funtion ) - will return 1 in this case
function! s:SQLU_CountUnbalancedParan( line, paran_to_check )
    let l = a:line
    let lp = substitute(l, '[^(]', '', 'g')
    let l = a:line
    let rp = substitute(l, '[^)]', '', 'g')

    if a:paran_to_check =~ ')'
        " echom 'SQLU_CountUnbalancedParan ) returning: ' 
        " \ . (strlen(rp) - strlen(lp))
        return (strlen(rp) - strlen(lp))
    elseif a:paran_to_check =~ '('
        " echom 'SQLU_CountUnbalancedParan ( returning: ' 
        " \ . (strlen(lp) - strlen(rp))
        return (strlen(lp) - strlen(rp))
    else
        " echom 'SQLU_CountUnbalancedParan unknown paran to check: ' . 
        " \ a:paran_to_check
        return 0
    endif
endfunction

" WS: wrapper start (internal)   Creates guard lines,
"     stores marks y and z, and saves search pattern
function! s:SQLU_WrapperStart( beginline, endline )
    let b:curline     = line(".")
    let b:curcol      = virtcol(".")
    let b:keepsearch  = @/
    let b:keepline_my = line("'y")
    let b:keepcol_my  = virtcol("'y")
    let b:keepline_mz = line("'z")
    let b:keepcol_mz  = virtcol("'z")
    silent! exec 'norm! '.a:endline."G\<bar>0\<bar>"
    " Add a new line to the bottom of the mark to be removed latter
    put =''
    " silent! exec "norm! mz'<"
    silent! exec "ma z"
    silent! exec 'norm! '.a:beginline."G\<bar>0\<bar>"
    " Add a new line above the mark to be removed latter
    put! = ''
    " silent! exec "norm! my"
    silent! exec "ma y"
    let b:ch= &ch
    set ch=2
    silent! exec "norm! 'zk"
    " echom 'SQLU_WrapperStart'
    " echom 'y-1l: '.(line("'y")-1).' t: '.getline(line("'y")-1)
    " echom 'y: '.line("'y").' t: '.getline(line("'y"))
    " echom 'z: '.line("'z").' t: '.getline(line("'z"))
    " echom 'z+1: '.(line("'z")+1).' t: '.getline(line("'z")+1)

endfunction

" WE: wrapper end (internal)   Removes guard lines,
"     restores marks y and z, and restores search pattern
function! s:SQLU_WrapperEnd()
    " Delete blanks lines added around the visually selected range
    silent! exe "norm! 'yjkdd'zdd"
    silent! exe "set ch=".b:ch
    unlet b:ch
    let @/= b:keepsearch
    " if b:keepline_my != 0
    "     silent! exe 'norm! '.b:keepline_my."G\<bar>".b:keepcol_my."l"
    " endif
    " if b:keepline_mz != 0
    "     silent! exe 'norm! '.b:keepline_mz."G\<bar>".b:keepcol_mz."l"
    " endif
    " silent! exe 'norm! '.b:curline."G\<bar>".b:curcol."l"
    silent! exe 'norm! '.b:curline."G\<bar>".b:curcol."l"
    unlet b:keepline_my b:keepcol_my
    unlet b:keepline_mz b:keepcol_mz
    unlet b:curline     b:curcol
endfunction

" Reformats the statements 
" 1. Keywords (FROM, WHERE, AND, ... ) " are on new lines
" 2. Keywords are right justified
" 3. CASE statements are setup for alignment.
" 4. Operators are lined up
" 
function! s:SQLU_ReformatStatement()
    " Remove any lines that have comments on them since the comments
    " could spill onto new lines and no longer have comment markers
    " which would result in syntax errors
    " Comments could also contain keywords, which would be split
    " on to new lines
    silent! 'y+1,'z-1s/.*\zs--.*//e
    " Join block of text into 1 line
    silent! 'y+1,'z-1j
    " Reformat the commas, to remove any spaces before them
    silent! 'y+1,'z-1s/\s*,/,/ge
    " And add a space following them, this allows the line to be
    " split using gqq
    silent! 'y+1,'z-1s/,\(\w\)/, \1/ge
    " Change more than 1 space with just one except spaces at
    " the beginning of the range
    " silent! 'y+1,'z-1s/\s\+/ /ge
    silent! 'y+1,'z-1s/\(\S\+\)\(\s\+\)/\1 /g
    " Go to the start of the block
    silent! 'y+1

    " Place an UPDATE on a newline, but not if it is preceeded by
    " the existing statement.  Example:
    "           INSERT INTO T1 (...)
    "           ON EXISTING UPDATE
    "           VALUES (...);
    "           SELECT ...
    "           FOR UPDATE
    let sql_update_keywords = '' . 
                \ '\%(\%(\<\%(for\|existing\)\s\+\)\@<!update\)'
    " WINDOW clauses can be used in both the SELECT list
    " and after the HAVING clause.
    let sql_window_keywords = '' . 
                \ 'over\|partition\s\+by\|' .
                \ '\%(rows\|range\)\s\+' .
                \ '\%(between\|unbounded\|current\|preceding\|following\)'
    " INTO clause can be used in a SELECT statement as well 
    " as an INSERT statement.  We do not want to place INTO
    " on a newline if it is preceeded by INSERT
    let sql_into_keywords = '' . 
                \ '\%(\%(\<\%(insert\|merge\)\s\+\)\@<!into\)'
    " Normally you would add put an AND statement on a new
    " line.  But in the cases where you are dealing with
    " a BETWEEN '1963-1-1' AND '1965-3-31', we no not want
    " to put the AND on a new line
    " Do not put AND on a new line if preceeded by
    "      between<space><some text not including space><space>AND
    let sql_and_between_keywords = '' . 
                \ '\%(\%(\<between\s\+[^ ]\+\s\+\)\@<!and\)'
    " For SQL Remote (ASA), this is valid syntax
    "           SUBSCRIBE BY
    "       OLD SUBSCRIBE BY
    "       NEW SUBSCRIBE BY
    let sql_subscribe_keywords = '' . 
                \ '\%(\%(\<\%(old\|new\)\s\+\)\?subscribe\)'
    " Oracle CONNECT BY statement
    let sql_connect_by_keywords = '' . 
                \ 'connect\s\+by\s\+\w\+'
    " Oracle MERGE INTO statement
    "      MERGE INTO ...
    "      WHEN MATCHED THEN ...
    "      WHEN NOT MATCHED THEN ....
    " Match on the WHEN clause (with zero width) if it is followed
    " by [not] matched
    let sql_merge_keywords = '' . 
                \ '\%(merge\s\+into\)\|\%(when\(\s\+\%(not\s\+\)\?matched\)\@=\)'
    " Some additional Oracle keywords from the SQL Reference for SELECT
    let sql_ora_keywords = '' .
                \ '\%(dimension\s\+by\|' .
                \ 'measures\s*(\|' .
                \ 'iterate\s*(\|' .
                \ 'within\s\+group\|' .
                \ '\%(ignore\|keep\)\s\+nav\|' .
                \ 'return\s\+\%(updated\|all\)\|' .
                \ 'rules\s\+\%(upsert\|update\)\)'
    " FROM clause can be used in a DELETE statement as well 
    " as a SELECT statement.  We do not want to place FROM
    " on a newline if it is preceeded by DELETE
    let sql_from_keywords = '' . 
                \ '\%(\%(\<delete\s\+\)\@<!from\)'
    " Only place order on a newline if followed by "by"
    " let sql_order_keywords = '' .  \ '\%(\%(\<order\s\+\)\@<!into\)'

    " join type syntax from ASA help file
    " INNER
    " | LEFT [ OUTER ]
    " | RIGHT [ OUTER ]
    " | FULL [ OUTER ]
    " LEFT, RIGHT, FULL can optional be followed by OUTER
    " The entire expression is optional
    let sql_join_type_keywords = '' . 
                \ '\%(' .
                \ '\%(inner\|' .
                \ '\%(\%(\%(left\|right\|full\)\s*\%(outer\)\?\s*\)\?\)' .
                \ '\)\?\s*\)\?'
    " Decho 'join types: ' . sql_join_type_keywords
    " join operator syntax
    " [ KEY | NATURAL ] [ join_type ] JOIN
    " | CROSS JOIN
    let sql_join_operator = '' .
                \ '\%(' .
                \ '\%(\%(\%(key\|natural\)\?\s*\)\?' .
                \ sql_join_type_keywords .
                \ 'join\)\|' .
                \ '\%(\%(\%(cross\)\?\s*\)\?join\)' .
                \ '\)'
    " force each keyword onto a newline
    let sql_keywords =  '\<\%(create\|drop\|call\|select\|set\|values\|' .
                \ sql_update_keywords . '\|' .
                \ sql_into_keywords . '\|' .
                \ sql_and_between_keywords . '\|' .
                \ sql_from_keywords . '\|' .
                \ sql_join_operator . '\|' .
                \ sql_subscribe_keywords . '\|' .
                \ sql_connect_by_keywords . '\|' .
                \ sql_merge_keywords . '\|' .
                \ sql_ora_keywords . '\|' .
                \ 'on\|where\|or\|order\s\+\%(\w\+\s\+\)\?by\|'.
                \ 'group\s\+by\|' .
                \ sql_window_keywords . '\|' .
                \ 'having\|for\|insert\|using\|' .
                \ 'intersect\|except\|window\|' .
                \ '\%(union\%(\s\+all\)\?\)\|' .
                \ 'start\s\+with\|' .
                \ '\%(\%(\<start\s\+\)\@<!with\)\)\>'
    " The user can specify whether to align the statements based on 
    " the first word, or on the matching string.
    "     let g:sqlutil_align_first_word = 0
    "           select
    "             from
    "         union all
    "     let g:sqlutil_align_first_word = 1
    "           select
    "             from
    "            union all
    let cmd = "'y+1,'z-1".'s/\%(^\s*\)\@<!\zs\<\(' .
                \ sql_keywords .
                \ '\)\>\s\+/' .
                \ '\r\1' .
                \ ( g:sqlutil_align_first_word==0 ? '-@-' : ' ' ) .
                \ '/gei'
    " Decho cmd
    silent! exec cmd

    " Ensure keywords at the beginning of a line have a space after them
    " This will ensure the Align program lines them up correctly
    " silent! 'y+1,'z-1s/^\([a-zA-Z0-9_]*\)(/\1 (/e
    " Delete any non empty lines
    " Do NOT delete empty lines, since that can affect the marks
    " and change which lines get formatted
    " 'y+1,'z-1g/^\s*$/d

    " If g:sqlutil_align_first_word == 0, then we need only add the -@-
    " on the first word, else we need to do it to the first word
    " on each line
    silent! exec "'y+1," .  
                \ ( g:sqlutil_align_first_word==0 ? "'y+1" : "'z-1" ) .  
                \ 's/^\s*\<\w\+\>\zs\s*/-@-'

    " Ensure CASE statements also start on new lines
    " CASE statements can also be nested, but we want these to align
    " with column lists, not keywords, so the -@- is placed BEFORE
    " the CASE keywords, not after
    "
    " The CASE statement and the Oracle MERGE statement are very similar.
    " I have changed the WHEN clause to check to see if it is followed
    " by [NOT] MATCHED, if so, do not match the WHEN
    let sql_case_keywords = '\(\<end\s\+\)\@<!case'.
                \ '\|\<when\>\(\%(-@-\)\?\s*\%(not\s\+\)\?matched\)\@!\|else\|end\( case\)\?'
    " echom 'case: '.sql_case_keywords
    " The case keywords must not be proceeded by a -@-
    silent! exec "'y+1,'z-1".'s/'.
                \ '\%(-@-\)\@<!'.
                \ '\<\('.
                \ sql_case_keywords.
                \ '\)\>/\r-@-\1/gei'

    " AlignPush

    " Using the Align.vim plugin, reformat the lines
    " so that the keywords are RIGHT justified
    AlignCtrl default

    " Replace the space after the first word on each line with 
    " -@- to align on this later
    " silent! 'y+1,'z-1s/^\(\s*\)\([a-zA-Z0-9_]*\) /\1\2-@-

    " if g:sqlutil_keyword_case == 'U'
    "     " If the user has specified, convert keywords to UPPER CASE
    "     let cmd = "'y+1,'z-1".'s/\<\(' .
    "                 \ sql_keywords .
    "                 \ '\|' .
    "                 \ sql_case_keywords .
    "                 \ '\)\>/\U\1/gei'
    "     silent! exec cmd
    " elseif g:sqlutil_keyword_case == 'L'
    "     " If the user has specified, convert keywords to lower case
    "     let cmd = "'y+1,'z-1".'s/\<\(' .
    "                 \ sql_keywords .
    "                 \ '\|' .
    "                 \ sql_case_keywords .
    "                 \ '\)\>/\L\1/gei'
    "     silent! exec cmd
    " endif

    let cmd = "'y+1,'z-1".'s/\<\(' .
                \ sql_keywords .
                \ '\|' .
                \ sql_case_keywords .
                \ '\)\>/' .
                \ g:sqlutil_keyword_case .
                \ '\1/gei'
    silent! exec cmd

    if g:sqlutil_align_comma == 1 
	call s:SQLU_WrapAtCommas()
    endif

    call s:SQLU_WrapFunctionCalls()

    let ret = s:SQLU_SplitUnbalParan()
    if ret < 0
        " Undo any changes made so far since an error occurred
        " silent! exec 'u'
        return ret
    endif

    " Align these based on the special charater
    " and the column names are LEFT justified
    AlignCtrl Ip0P0rl:
    silent! 'y+1,'z-1Align -@-
    silent! 'y+1,'z-1s/-@-/ /ge

    " Now align the operators 
    " and the operators are CENTER justified
    if g:sqlutil_align_where == 1
        AlignCtrl default
        AlignCtrl g [!<>=]
        AlignCtrl Wp1P1l

        " Change this to only attempt to align the last WHERE clause
        " and not the entire SQL statement
        " Valid operators are: 
        "      =, =, >, <, >=, <=, !=, !<, !>, <> 
        " The align below was extended to allow the last character
        " to be either =,<,>
        silent! 'y+1,'z-1Align [!<>=]\(<\|>\|=\)\=
    endif

    " Reset back to defaults
    AlignCtrl default

    " Reset the alignment to what it was prior to 
    " this function
    " AlignPop

    return 1
endfunction

" Check through the selected text for open ( and
" indent if necessary
function! s:SQLU_IndentNestedBlocks()

    let org_textwidth = &textwidth
    if &textwidth == 0 
        " Get the width of the window
        let &textwidth = winwidth(winnr())
    endif
    
    let sql_keywords = '\<\%(select\|set\|\%(insert\s\+\)\?into\|from\|values'.
                \ '\|order\|group\|having\|return\|call\)\>'

    " Indent nested blocks surrounded by ()s.
    let linenum = line("'y+1")
    while linenum <= line("'z-1")
        let line = getline(linenum)
        if line =~ '(\s*$'
            let begin_paran = match( line, '(\s*$' )
            if begin_paran > -1
                let curline     = line(".")
                let curcol      = begin_paran + 1
                " echom 'begin_paran: '.begin_paran.
                "             \ ' line: '.curline.
                "             \ ' col: '.curcol
                silent! exe 'norm! '.linenum."G\<bar>".curcol."l"
                " v  - visual
                " ib - inner block
                " k  - backup on line
                " >  - right shift
                " .  - shift again
                " silent! exe 'norm! vibk>.'
                silent! exe 'norm! vibk>'
                
                " If the following line begins with a keyword, 
                " indent one additional time.  This is necessary since 
                " keywords are right justified, so they need an extra
                " indent
                if getline(linenum+1) =~? '^\s*\('.sql_keywords.'\)'
                    silent! exe 'norm! .'
                endif
                " echom 'SQLU_IndentNestedBlocks - from: '.line("'<").' to: ' .
                "             \ line("'>") 
                " echom 'SQLU_IndentNestedBlocks - no match: '.getline(linenum)
            endif
        endif

        let linenum = linenum + 1
    endwhile

    let ret = linenum

    "
    " Indent nested CASE blocks
    "
    let linenum = line("'y+1")
    " Search for the beginning of a CASE statement
    let begin_case = '\<\(\<end\s\+\)\@<!case\>'

    silent! exe 'norm! '.linenum."G\<bar>0\<bar>"

    while( search( begin_case, 'W' ) > 0 )
        let curline = line(".")
        if( (curline < line("'y+1"))  || (curline > line("'z-1" )) )
            " echom 'No case statements, leaving loop'
            silent! exe 'norm! '.line("'y+1")."G\<bar>0\<bar>"
            break
        endif
        " echom 'begin CASE found at: '.curline
        let curline = curline + 1
        let end_of_case = s:SQLU_IndentNestedCase( begin_case, curline, 
                    \ line("'z-1") )
        let end_of_case = end_of_case + 1
        let ret = end_of_case
        if( ret < 0 )
            break
        endif
        silent! exe 'norm! '.end_of_case."G\<bar>0\<bar>"
    endwhile

    "
    " Indent Oracle nested MERGE blocks
    "
    let linenum = line("'y+1")
    " Search for the beginning of a CASE statement
    let begin_merge = '\<merge\s\+into\>'

    silent! exe 'norm! '.linenum."G\<bar>0\<bar>"

    if( search( begin_merge, 'W' ) > 0 )
        let curline = line(".")
        if( (curline < line("'y+1"))  || (curline > line("'z-1" )) )
            " echom 'No case statements, leaving loop'
            silent! exe 'norm! '.line("'y+1")."G\<bar>0\<bar>"
        else
            " echom 'begin CASE found at: '.curline
            let curline = curline + 1

            while 1==1
                " Find the matching when statement
                " let match_merge = searchpair('\<merge\s\+into\>', 
                let match_merge = searchpair('\<merge\>', '',
                            \ '\<\%(when\s\+\%(not\s\+\)\?matched\)', 
                            \ 'W', '' )
                if( (match_merge < curline) || (match_merge > line("'z-1")) )
                    silent! exec curline . "," . line("'z-1") . ">>"
                    break
                else
                    if match_merge > (curline+1)
                        let savePos = 'normal! '.line(".").'G'.col(".")."\<bar>"
                        silent! exec curline . "," . (match_merge-1) . ">>"
                        silent! exec savePos
                    endif
                    let curline = match_merge + 1
                endif
            endwhile
        endif
    endif

    let &textwidth = org_textwidth
    return ret
endfunction

" Recursively indent nested case statements
function! s:SQLU_IndentNestedCase( begin_case, start_line, end_line )

    " Indent nested CASE blocks
    let linenum = a:start_line

    " Find the matching end case statement
    let end_of_prev_case = searchpair(a:begin_case, '', 
                \ '\<end\( case\)\?\>', 'W', '' )

    if( (end_of_prev_case < a:start_line) || (end_of_prev_case > a:end_line) )
        call s:SQLU_WarningMsg(
                    \ 'No matching end case for: ' .
                    \ getline((linenum-1))
                    \ )
        return -1
    " else
        " echom 'Matching END found at: '.end_of_prev_case
    endif

    silent! exe 'norm! '.linenum."G\<bar>0\<bar>"

    if( search( a:begin_case, 'W' ) > 0 )
        let curline = line(".")
        if( (curline > a:start_line) && (curline < end_of_prev_case) )
            let curline = curline + 1
            let end_of_case = s:SQLU_IndentNestedCase( a:begin_case, curline, 
                        \ line("'z-1") )
            " echom 'SQLU_IndentNestedCase from: '.linenum.' to: '.end_of_case
            silent! exec (curline-1) . "," . end_of_case . ">>"
        " else
        "     echom 'SQLU_IndentNestedCase No case statements, '.
        "                 \ 'leaving SQLU_IndentNestedCase: '.linenum
        endif
    endif

    return end_of_prev_case
endfunction

" For certain keyword lines (SELECT, ORDER BY, GROUP BY, ...)
" Ensure the lines fit in the textwidth (or default 80), wrap
" the lines where necessary and left justify the column names
function! s:SQLU_WrapFunctionCalls()
    " Check if this is a statement that can often by longer than 80 characters
    " (select, set and so on), if so, ensure the column list is broken over as
    " many lines as necessary and lined up with the other columns
    let linenum = line("'y+1")

    let org_textwidth = &textwidth
    if org_textwidth == 0 
        " Get the width of the window
        let curr_textwidth = winwidth(winnr())
    else
        let curr_textwidth = org_textwidth
    endif

    let sql_keywords = '\<\%(select\|set\|\%(insert\(-@-\)\?\)into' .
                \ '\|from\|values'.
                \ '\|order\|group\|having\|return\|with\)\>'

    " Useful in the debugger
    " echo linenum.' '.func_call.' '.virtcol(".").' 
    " '.','.substitute(getline("."), '^ .*\(\%'.(func_call-1).'c...\).*', 
    " '\1', '' ).', '.getline(linenum)

    " call Decho(" Before column splitter 'y+1=".line("'<").
    " \ ":".col("'<")."  'z-1=".line("'>").":".col("'>"))
    while linenum <= line("'z-1")
        let line = getline(linenum)

        if strlen(line) < curr_textwidth
            let linenum = linenum + 1
            continue
        endif

        let get_func_nm = '[a-zA-Z_.]\+\s*('

        " Use a special line textwidth, since if we split function calls
        " any text within the parantheses will be indented 2 &shiftwidths
        " so when calculating where to split, we must take that into
        " account
        let keyword_str = matchstr(
                    \ getline(linenum), '^\s*\('.sql_keywords.'\)' )

        let line_textwidth = curr_textwidth - strlen(keyword_str)
        let func_call = 0
        while( strlen(getline(linenum)) > line_textwidth )

            " Find the column # of the start of the function name
            let func_call = match( getline(linenum), get_func_nm, func_call )
            if func_call < 0 
                " If no functions found, move on to next line
                break
            endif

            let prev_func_call = 0

            " Position cursor at func_call
            silent! exe 'norm! '.linenum."G\<bar>".func_call."l"

            if search('(', 'W') > linenum
                call s:SQLU_WarningMsg(
                            \ 'SQLU_WrapFunctionCalls - should have found a ('
                            \ )
                let linenum = linenum + 1
                break
            endif
            let end_paran = searchpair( '(', '', ')', '' )
            if end_paran < linenum || end_paran > linenum
                " call s:SQLU_WarningMsg(
                "             \ 'SQLU_WrapFunctionCalls - ' . 
                "             \ 'should have found a matching ) for :' .
                "             \ getline(linenum)
                "             \ )
                let linenum = linenum + 1
                break
            endif

            let prev_func_call = func_call

            " If the matching ) is past the textwidth
            if virtcol(".") > line_textwidth
                if (virtcol(".")-func_call) > line_textwidth
                    " Place the closing brace on a new line only if
                    " the entire length of the function call and 
                    " parameters is longer than a line
                    silent! exe "norm! i\r-@-\<esc>"
                endif
                " If the SQL keyword preceeds the function name dont
                " bother placing it on a new line
                let preceeded_by_keyword = 
                            \ '^\s*' .
                            \ '\(' .
                            \ sql_keywords .
                            \ '\|,' .
                            \ '\)' .
                            \ '\(-@-\)\?' .
                            \ '\s*' .
                            \ '\%'.(func_call+1).'c'
                " echom 'preceeded_by_keyword: '.preceeded_by_keyword
                " echom 'func_call:'.func_call.' Current 
                " character:"'.getline(linenum)[virtcol(func_call)].'"  - 
                " '.getline(linenum)
                if getline(linenum) !~? preceeded_by_keyword
                    " if line =~? '^\s*\('.sql_keywords.'\)'
                    " Place the function name on a new line
                    silent! exe linenum.'s/\%'.(func_call+1).'c/\r-@-'
                    let linenum = linenum + 1
                    " These lines will be indented since they are wrapped
                    " in parantheses.  Decrease the line_textwidth by
                    " that amount to determine where to split nested 
                    " function calls
                    let line_textwidth = line_textwidth - (2 * &shiftwidth)
                    let func_call = 0
                    " Get the new offset of this function from the start
                    " of the newline it is on
                    let prev_func_call = match(
                                \ getline(linenum),get_func_nm,func_call)
                endif
            endif

            " Get the name of the previous function
            let prev_func_call_str = matchstr(
                        \ getline(linenum), get_func_nm, prev_func_call )
            " Advance the column by its length to find the next function
            let func_call = prev_func_call +
                        \ strlen(prev_func_call_str) 

        endwhile

        let linenum = linenum + 1
    endwhile

    let &textwidth = org_textwidth
    return linenum
endfunction

" For certain keyword lines (SELECT, SET, INTO, FROM, VALUES)
" put each comma on a new line and align it with the keyword 
"     SELECT c1
"          , c2
"          , c3
function! s:SQLU_WrapAtCommas()
    let linenum = line("'y+1")

    let sql_keywords = '\<\%(select\|set\|into\|from\|values\)\>'

    " call Decho(" Before column splitter 'y+1=".line("'<").
    " \ ":".col("'<")."  'z-1=".line("'>").":".col("'>"))
    while linenum <= line("'z-1")
        let line = getline(linenum)
        " if line =~? '^\s*\('.sql_keywords.'\)'
        if line =~? '\w'
            if line =~? '^\s*\<\('.sql_keywords.'\)\>'
                silent! exec linenum 
		" silent! exec linenum . ',' . linenum . 's/\w\+\zs\s\+/-@-'

                " Mark the start of the wide line
                silent! exec "normal mb"
                " echom "line b - ".getline("'b")
                " Mark the next line
                silent! exec "normal jmek"

		let index = match(getline(linenum), '[,(]')
		while index > -1
		    " Go to character
		    silent! exe 'norm! '.linenum."G\<bar>".
				\ index.(index>0 ? 'l' : '' )

		    if getline(linenum)[col(".")-1] == '('
			if searchpair( '(', '', ')', '' ) > 0
			    if line(".") != linenum
				break
			    else
				let index = col(".")
			    endif
			endif
		    else
			" Given the current cursor position, replace
			" the , and any following whitespace
			" with a newline and the special -@- character
			" for Align
			silent! exec linenum . ',' . linenum . 
				    \ 's/\%' . (index + 1) . 'c,\s*' .
				    \ '/\r,-@-'
			let linenum = linenum + 1
			" Find the index of the first non-white space
			" which should be the , we just put on the 
			" newline
			let index = match(getline(linenum), '\S')
			let index = index + 1
		    endif

		    " then continue on for the remainder of the line
		    " looking for the next , or (
		    "
		    " Must figure out what index value to start from
		    let index = match( getline(linenum), '[,(]', index )
		endwhile

                " AlignCtrl Ip0P0rl:
                " silent! 'b,'e-Align -@-
                " silent! 'b,'e-s/-@-/ /
                " AlignCtrl default

                " Go to the end of the new lines
                silent! exec "'e-" 
            endif
        endif

        let linenum = linenum + 1
    endwhile

    return linenum
endfunction

" For certain keyword lines (SELECT, ORDER BY, GROUP BY, ...)
" Ensure the lines fit in the textwidth (or default 80), wrap
" the lines where necessary and left justify the column names
function! s:SQLU_WrapLongLines()
    " Check if this is a statement that can often by longer than 80 characters
    " (select, set and so on), if so, ensure the column list is broken over as
    " many lines as necessary and lined up with the other columns
    let linenum = line("'y+1")

    let org_textwidth = &textwidth
    if &textwidth == 0 
        " Get the width of the window
        let &textwidth = winwidth(winnr())
    endif

    let sql_keywords = '\<\%(select\|set\|into\|from\|values'.
                \ '\|order\|group\|having\|call\|with\)\>'

    " call Decho(" Before column splitter 'y+1=".line("'<").
    " \ ":".col("'<")."  'z-1=".line("'>").":".col("'>"))
    while linenum <= line("'z-1")
        let line = getline(linenum)
        " if line =~? '^\s*\('.sql_keywords.'\)'
        if line =~? '\w'
            " Set the textwidth to current value
            " minus an adjustment for select and set
            " minus any indent value this may have
            " echo 'tw: '.&textwidth.'  indent: '.indent(line)
            " Decho 'line: '.line
            " Decho 'tw: '.&textwidth.'  match at: '.
            "             \ matchend(line, sql_keywords )
            " let &textwidth = &textwidth - 10 - indent(line)
            if line =~? '^\s*\('.sql_keywords.'\)'
                let &textwidth = &textwidth - matchend(line, sql_keywords ) - 2
                let line_length = strlen(line) - matchend(line, sql_keywords )
            else
                let line_length = strlen(line)
            endif

            if( line_length > &textwidth )
                " Decho 'linenum: ' . linenum . ' strlen: ' .
                " \ strlen(line) . ' textwidth: ' . &textwidth .
                " \ '  line: ' . line
                " go to the current line
                silent! exec linenum 
                " Mark the start of the wide line
                silent! exec "normal mb"
                " echom "line b - ".getline("'b")
                " Mark the next line
                silent! exec "normal jmek"
                " echom "line e - ".getline("'e")
                " echom "line length- ".strlen(getline(".")).
                " \ "  tw=".&textwidth


                if line =~? '^\s*\('.sql_keywords.'\)'
                    " Create a special marker for Align.vim
                    " to line up the columns with
                    silent! exec linenum . ',' . linenum . 's/\(\w\) /\1-@-'

                    " If the line begins with SET then force each
                    " column on a newline, instead of breaking them apart
                    " this will ensure that the col_name = ... is on the
                    " same line
                    if line =~? '^\s*\<set\>'
                        silent! 'b,'e-1s/,/,\r/ge
                    endif
                else
                    " Place the special marker that the first non-whitespace
                    " characeter
                    if g:sqlutil_align_comma == 1 
                        silent! exec linenum . ',' . linenum . 's/^\s*\zs,\s*/,  -@-'
                    else
                        silent! exec linenum . ',' . linenum . 's/\S/-@-&'
                    endif
                endif

                silent! exec linenum
                " Reformat the line based on the textwidth
                silent! exec "normal gqq"

                " echom "normal mb - ".line("'b")
                " echom "normal me - ".line("'e")
                " Sometimes reformatting does not change the line
                " so we need to double check the end range to 
                " ensure it does go backwards
                let begin_line_nbr = (line("'b") + 1)
                let end_line_nbr = (line("'e") - 1)
                " echom "b- ".begin_line_nbr."  e- ".end_line_nbr
                if end_line_nbr < begin_line_nbr
                    let end_line_nbr = end_line_nbr + 1
                    " echom "end_line_nbr adding 1 "
                endif
                " echom "end_line_nbr - ".end_line_nbr
                " echom "normal end_line_nbr - ".line(end_line_nbr)

                " Reformat the commas
                " silent! 'b,'e-s/\s*,/,/ge
                " silent! exec "'b,".end_line_nbr.'s/\s*,/,/ge'
                " Add a space after the comma
                " silent! 'b,'e-s/,\(\w\)/, \1/ge
                silent! exec "'b,".end_line_nbr.'s/,\(\w\)/, \1/ge'

                " Append the special marker to the beginning of the line
                " for Align.vim
                " silent! exec "'b+," .end_line_nbr. 's/\s*\(.*\)/-@-\1'
                silent! exec "'b+," .end_line_nbr. 's/^\s*/-@-'
                " silent! exec "'b+,'e-" . 's/\s*\(.*\)/-@-\1'
                AlignCtrl Ip0P0rl:
                " silent! 'b,'e-Align -@-
                silent! exec "'b,".end_line_nbr.'Align -@-'
                " silent! 'b,'e-s/-@-/ /
                if line =~? '^\s*\('.sql_keywords.'\)'
                    silent! exec "'b,".end_line_nbr.'s/-@-/ /ge'
                else
                    silent! exec "'b,".end_line_nbr.'s/-@-/'.(g:sqlutil_align_comma == 1 ? ' ' : '' ).'/ge'
                endif
                AlignCtrl default

                " Dont move to the end of the reformatted text
                " since we also want to check for CASE statemtns
                " let linenum = line("'e") - 1
                " let linenum = line("'e")
            endif
        endif

        let &textwidth = org_textwidth
        if &textwidth == 0 
            " Get the width of the window
            let &textwidth = winwidth(winnr())
        endif
        let linenum = linenum + 1
    endwhile

    let &textwidth = org_textwidth
    return linenum
endfunction

" Finds unbalanced paranthesis and put each one on a new line
function! s:SQLU_SplitUnbalParan()
    let linenum = line("'y+1")
    while linenum <= line("'z-1")
        let line = getline(linenum)
        " echom 'SQLU_SplitUnbalParan: l: ' . linenum . ' t: '. getline(linenum)
        if line !~ '('
            " echom 'SQLU_SplitUnbalParan: no (s: '.linenum.'  : '.
            " \ getline(linenum)
            let linenum = linenum + 1
            continue
        endif
            
        " echom 'SQLU_SplitUnbalParan: start line: '.linenum.' : '.line

        let begin_paran = match( line, "(" )
        while begin_paran > -1
            " let curcol      = begin_paran + 1
            let curcol      = begin_paran
            " echom 'begin_paran: '.begin_paran.
            "             \ ' line: '.linenum.
            "             \ ' col: '.curcol.
            "             \ ' : '.line

            " Place the cursor on the (
             "silent! exe 'norm! '.linenum."G\<bar>".(curcol-1)."l"
            silent! exe 'norm! '.linenum."G\<bar>".curcol."l"

            " Find the matching closing )
            let indent_to = searchpair( '(', '', ')', '' )

            " If the match is outside of the range, this is an unmatched (
            if indent_to < 1 || indent_to > line("'z-1")
                " Return to previous location
                " echom 'Unmatched parentheses on line: ' . getline(linenum)
                call s:SQLU_WarningMsg(
                            \ 'Unmatched parentheses on line: ' . 
                            \ getline(linenum)
                            \ )
                " echom 'Unmatched parentheses: Returning to: '.
                "             \ linenum."G\<bar>".curcol."l"
                "             \ " #: ".line(".")
                "             \ " text: ".getline(".")
                " silent! exe 'norm! '.linenum."G\<bar>".(curcol-1)."l"
                silent! exe 'norm! '.linenum."G\<bar>".curcol."l"
                return -1
            endif
             
            let matchline     = line(".")
            let matchcol      = virtcol(".")
            " echom 'SQLU_SplitUnbalParan searchpair: ' . indent_to.
            "             \ ' col: '.matchcol.
            "             \ ' line: '.getline(indent_to)

            " If the match is on a DIFFERENT line
            if indent_to != linenum
                " If a ) is NOT the only thing on the line
                " I have relaxed this, so it must be the first
                " thing on the line 
                " if getline(indent_to) !~ '^\s*\(-@-\)\?)\s*$'
                if getline(indent_to) !~ '^\s*\(-@-\)\?)'
                    " Place the paranethesis on a new line
                    silent! exec "normal! i\n\<Esc>"
                    let indent_to = indent_to + 1
                    " echom 'Indented closing line: '.getline(".")
                endif
                " Remove leading spaces
                " echom "Removing leading spaces"
                " exec 'normal! '.indent_to.','.indent_to.
                "             \'s/^\s*//e'."\n"
                silent! exec 's/^\s*//e'."\n"
                
                " Place a marker at the beginning of the line so
                " it can be Aligned with its matching paranthesis
                if getline(".") !~ '^\s*-@-'
                    silent! exec "normal! i-@-\<Esc>"
                endif
                " echom 'Replacing ) with newline: '.line(".").
                "             \ ' indent: '.curcol.' '
                "             \ getline(indent_to)

                " echom 'line:' . linenum . ' col:' . curcol
                "echom linenum . ' ' . getline(linenum) . curcol . 
                "\ ' ' . matchstr( getline(linenum),  
                "\ '^.\{'.(curcol).'}\zs.*' )     


                " Return to the original line
                " Check if the line with the ( needs splitting
                " as well
                " Since the closing ) is on a different line, make sure
                " this ( is the last character on the line, this is 
                " necessary so that the blocks are correctly indented
                " .\{8} - match any characters up to the 8th column
                " \zs   - start the search in column 9
                " \s*$  - If the line only has whitespace dont split

                if getline(linenum) !~ '^.\{'.(curcol+1).'}\zs\s*$'     
                    " Return to previous location
                    silent! exe 'norm! '.linenum."G\<bar>".curcol."l"

                    " Place the paranethesis on a new line
                    " with the marker at the beginning so
                    " it can be Aligned with its matching paranthesis
                    silent! exec "normal! a\n-@-\<Esc>"

                    " Add 1 to the linenum since the remainder of this 
                    " line has been moved 
                    let linenum = linenum + 1
                    " Reset begin_paran since we are on a new line
                    let begin_paran = -1

                endif
            endif

            " We have potentially changed the line we are on
            " so get a new copy of the row to perform the match
            " Add one to the curcol to look for the next (
            let begin_paran = match( getline(linenum), "(", (begin_paran+1) )

        endwhile

        let linenum = linenum + 1
    endwhile

    " Never found matching close parenthesis
    " return end of range
    return linenum
endfunction

" Puts a command separate list of columns given a table name
" Will search through the file looking for the create table command
" It assumes that each column is on a separate line
" It places the column list in unnamed buffer
function! SQLU_CreateColumnList(...)

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")
    let curbuf      = bufnr(expand("<abuf>"))
    let found       = 0

    if(a:0 > 0) 
        let table_name  = a:1
    else
        let table_name  = expand("<cword>")
    endif

    if(a:0 > 1) 
        let only_primary_key = 1
    else
        let only_primary_key = 0
    endif

    " save previous search string
    let saveSearch = @/
    let saveZ      = @z
    let columns    = ""
    
    " ignore case
    if( only_primary_key == 0 )
        let srch_table = '\c^[ \t]*create.*table.*\<'.table_name.'\>'
    else
        " Regular expression breakdown
        " Ingore case and spaces
        " line begins with either create or alter
        " followed by table and table_name (on the same line)
        " Could be other lines inbetween these
        " Look for the primary key clause (must be one)
        " Start the match after the open paran
        " The ccolumn list could span multiple lines
        " End the match on the closing paran
        " Could be other lines inbetween these
        " Remove any newline characters for the command
        " terminator (ie "\ngo" )
        " Besides a CREATE TABLE statement, this expression
        " should find statements like:
        "     ALTER TABLE SSD.D_CENTR_ALLOWABLE_DAYS
        "         ADD PRIMARY KEY (CUST_NBR, CAL_NBR, GRP_NBR,
        "              EVENT_NBR, ALLOW_REVIS_NBR, ROW_REVIS_NBR);
        let srch_table = '\c^[ \t]*' . 
                    \ '\(create\|alter\)' . 
                    \ '.*table.*' . 
                    \ table_name .                
                    \ '\_.\{-}' .    
                    \ '\%(primary key\)\{-1,}' . 
                    \ '\s*(\zs' . 
                    \ '\_.\{-}' . 
                    \ '\ze)' . 
                    \ '\_.\{-}' . 
                    \ substitute( g:sqlutil_cmd_terminator,
                            \ "[\n]", '', "g" )
    endif

    " Loop through all currenly open buffers to look for the 
    " CREATE TABLE statement, if found build the column list
    " or display a message saying the table wasn't found
    " I am assuming a create table statement is of this format
    " CREATE TABLE "cons"."sync_params" (
    "   "id"                            integer NOT NULL,
    "   "last_sync"                     timestamp NULL,
    "   "sync_required"                 char(1) NOT NULL DEFAULT 'N',
    "   "retries"                       smallint NOT NULL ,
    "   PRIMARY KEY ("id")
    " );
    while( 1==1 )
        " Mark the current line to return to
        let buf_curline     = line(".")
        let buf_curcol      = virtcol(".")
        " From the top of the file
        silent! exe "norm! 1G\<bar>0\<bar>"
        if( search( srch_table, "W" ) ) > 0
            if( only_primary_key == 0 )
                " Find the create table statement
                " let cmd = '/'.srch_create_table."\n"
                " Find the opening ( that starts the column list
                let cmd = 'norm! /('."\n".'Vib'."\<ESC>"
                silent! exe cmd
                " Decho 'end: '.getline(line("'>"))
                let start_line = line("'<")
                let end_line = line("'>")
                silent! exe 'noh'
                let found = 1
                
                " Visually select until the following keyword are the beginning
                " of the line, this should be at the bottom of the column list
                " Start visually selecting columns
                " let cmd = 'silent! normal! V'."\n"
                let find_end_of_cols = 
                            \ '\(' .
                            \ ')\?\s*' . g:sqlutil_cmd_terminator .
                            \ substitute(
                            \ g:sqlutil_col_list_terminators,
                            \ '\s*\(\w\+\)\s*\%(,\)\?',
                            \ '\\|\1',
                            \ 'g'
                            \ ) .
                            \ '\)' 
                    
                let separator = ""
                let columns = ""

                " Build comma separated list of input parameters
                while start_line <= end_line
                    let line = getline(start_line)

                    " If the line has no words on it, skip it
                    if line !~ '\w' || line =~ '^\s*$'
                        let start_line = start_line + 1
                        continue
                    endif

                    " if any of the find_end_of_cols is found, leave this loop.
                    " This test is case insensitive.
                    if line =~? find_end_of_cols
                        let end_line = start_line - 1
                        break
                    endif

                    " Decho line
                    let column_name = substitute( line, 
                                \ '[ \t"]*\(\<\w\+\>\).*', '\1', "g" )
                    let column_def = SQLU_GetColumnDatatype( line, 1 )

                    let columns = columns . separator . column_name
                    let separator  = ", "
                    let start_line = start_line + 1
                endwhile

            else
                " Find the primary key statement
                " Visually select all the text until the 
                " closing paranthesis
                silent! exe 'silent! norm! v/)/e-1'."\n".'"zy'
                let columns = @z
                " Strip newlines characters
                let columns = substitute( columns, 
                            \ "[\n]", '', "g" )
                " Strip everything but the column list
                let columns = substitute( columns, 
                            \ '\s*\(.*\)\s*', '\1', "g" )
                " Remove double quotes
                let columns = substitute( columns, '"', '', "g" )
                let columns = substitute( columns, ',\s*', ', ', "g" )
                let columns = substitute( columns, '^\s*', '', "g" )
                let columns = substitute( columns, '\s*$', '', "g" )
                let found = 1
                silent! exe 'noh'
            endif

        endif

        " Return to previous location
        silent! exe 'norm! '.buf_curline."G\<bar>".buf_curcol."l"

        if found == 1
            break
        endif
        
        if &hidden == 0
            call s:SQLU_WarningMsg(
                        \ "Cannot search other buffers with set nohidden"
                        \ )
            break
        endif

        " Switch buffers to check to see if the create table
        " statement exists
        silent! exec "bnext"
        if bufnr(expand("<abuf>")) == curbuf
            break
        endif
    endwhile
    
    silent! exec "buffer " . curbuf

    " Return to previous location
    silent! exe 'norm! '.curline."G\<bar>".curcol."l"
    silent! exe 'noh'

    " restore previous search
    let @/ = saveSearch
    let @z = saveZ

    redraw

    if found == 0
        let @@ = ""
        if( only_primary_key == 0 )
            call s:SQLU_WarningMsg(
                        \ "SQLU_CreateColumnList - Table: " .
                        \ table_name . 
                        \ " was not found"
                        \ )
        else
            call s:SQLU_WarningMsg(
                        \ "SQLU_CreateColumnList - Table: " .
                        \ table_name . 
                        \ " does not have a primary key"
                        \ )
        endif
        return ""
    endif 

    " If clipboard is pointing to the windows clipboard
    " copy the results there.
    if &clipboard == 'unnamed'
        let @* = columns 
    else
        let @@ = columns 
    endif

    echo "Paste register: " . columns

    return columns

endfunction


" Strip the datatype from a column definition line
function! SQLU_GetColumnDatatype( line, need_type )

    let pattern = '\c^\s*'  " case insensitve, white space at start of line
    let pattern = pattern . '\S\+\w\+[ "\t]\+' " non white space (name with 
                                               " quotes)

    if a:need_type == 1
        let pattern = pattern . '\zs'    " Start matching the datatype
        let pattern = pattern . '.\{-}'  " include anything
        let pattern = pattern . '\ze\s*'    " Stop matching when ...
        let pattern = pattern . '\(NOT\|NULL\|DEFAULT\|'
        let pattern = pattern . '\(\s*,\s*$\)' " Line ends with a comma 
        let pattern = pattern . '\)' 
    else
        let pattern = pattern . '\zs'   " Start matching the datatype
        let pattern = pattern . '.\{-}' " include anything
        let pattern = pattern . '\ze'   " Stop matching when ...
        let pattern = pattern . '\s*,\s*$' " Line ends with a comma 
    endif

    let datatype = matchstr( a:line, pattern )

    return datatype
endfunction


" Puts a command separate list of columns given a table name
" Will search through the file looking for the create table command
" It assumes that each column is on a separate line
" It places the column list in unnamed buffer
function! SQLU_GetColumnDef( ... )

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")
    let curbuf      = bufnr(expand("<abuf>"))
    let found       = 0
    
    if(a:0 > 0) 
        let col_name  = a:1
    else
        let col_name  = expand("<cword>")
    endif

    if(a:0 > 1) 
        let need_type = a:2
    else
        let need_type = 0
    endif

    let srch_column_name = '^[ \t]*["]\?\<' . col_name . '\>["]\?\s\+\<\w\+\>'
    let column_def = ""

    " Loop through all currenly open buffers to look for the 
    " CREATE TABLE statement, if found build the column list
    " or display a message saying the table wasn't found
    " I am assuming a create table statement is of this format
    " CREATE TABLE "cons"."sync_params" (
    "   "id"                            integer NOT NULL,
    "   "last_sync"                     timestamp NULL,
    "   "sync_required"                 char(1) NOT NULL DEFAULT 'N',
    "   "retries"                       smallint NOT NULL ,
    "   PRIMARY KEY ("id")
    " );
    while( 1==1 )
        " Mark the current line to return to
        let buf_curline     = line(".")
        let buf_curcol      = virtcol(".")

        " From the top of the file
        silent! exe "norm! 1G\<bar>0\<bar>"

        if( search( srch_column_name, "w" ) ) > 0
            silent! exe 'noh'
            let found = 1
            let column_def = SQLU_GetColumnDatatype( getline("."), need_type )
        endif

        " Return to previous location
        silent! exe 'norm! '.buf_curline."G\<bar>".buf_curcol."l"

        if found == 1
            break
        endif
        
        if &hidden == 0
            call s:SQLU_WarningMsg(
                        \ "Cannot search other buffers with set nohidden"
                        \ )
            break
        endif

        " Switch buffers to check to see if the create table
        " statement exists
        silent! exec "bnext"
        if bufnr(expand("<abuf>")) == curbuf
            break
        endif
    endwhile
    
    silent! exec "buffer " . curbuf

    " Return to previous location
    silent! exe 'norm! '.curline."G\<bar>".curcol."l"

    if found == 0
        let @@ = ""
        echo "Column: " . col_name . " was not found"
        return ""
    endif 

    if &clipboard == 'unnamed'
        let @* = column_def 
    else
        let @@ = column_def 
    endif

    " If a parameter has been passed, this means replace the 
    " current word, with the column list
    " if (a:0 > 0) && (found == 1)
        " exec "silent! normal! viwp"
        " if &clipboard == 'unnamed'
            " let @* = col_name 
        " else
            " let @@ = col_name 
        " endif
        " echo "Paste register: " . col_name
    " else
        echo "Paste register: " . column_def
    " endif

    return column_def

endfunction



" Creates a procedure defintion into the unnamed buffer for the 
" table that the cursor is currently under.
function! SQLU_CreateProcedure(...)

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")
    let curbuf      = bufnr(expand("<abuf>"))
    let found       = 0
    " save previous search string
    let saveSearch=@/ 
    

    if(a:0 > 0) 
        let table_name  = a:1
    else
        let table_name  = expand("<cword>")
    endif

    let i = 0
    let indent_spaces = ''
    while( i < &shiftwidth )
        let indent_spaces = indent_spaces . ' '
        let i = i + 1
    endwhile
    
    " ignore case
    " let srch_create_table = '\c^[ \t]*create.*table.*\<' . table_name . '\>'
    let srch_create_table = '\c^[ \t]*create.*table.*\<' . 
                \ table_name . 
                \ '\>'
    let procedure_def = "CREATE PROCEDURE sp_" . table_name . "(\n"

    " Loop through all currenly open buffers to look for the 
    " CREATE TABLE statement, if found build the column list
    " or display a message saying the table wasn't found
    " I am assuming a create table statement is of this format
    " CREATE TABLE "cons"."sync_params" (
    "   "id"                            integer NOT NULL,
    "   "last_sync"                     timestamp NULL,
    "   "sync_required"                 char(1) NOT NULL DEFAULT 'N',
    "   "retries"                       smallint NOT NULL,
    "   PRIMARY KEY ("id")
    " );
    while( 1==1 )
        " Mark the current line to return to
        let buf_curline     = line(".")
        let buf_curcol      = virtcol(".")

        " From the top of the file
        silent! exe "norm! 1G\<bar>0\<bar>"

        if( search( srch_create_table, "w" ) ) > 0
            " Find the create table statement
            " let cmd = '/'.srch_create_table."\n"
            " Find the opening ( that starts the column list
            let cmd = 'norm! /('."\n".'Vib'."\<ESC>"
            silent! exe cmd
            " Decho 'end: '.getline(line("'>"))
            let start_line = line("'<")
            let end_line = line("'>")
            silent! exe 'noh'
            let found = 1
            
            " Visually select until the following keyword are the beginning
            " of the line, this should be at the bottom of the column list
            " Start visually selecting columns
            " let cmd = 'silent! normal! V'."\n"
            let find_end_of_cols = 
                        \ '\(' .
                        \ ')\?\s*' . g:sqlutil_cmd_terminator .
                        \ substitute(
                        \ g:sqlutil_col_list_terminators,
                        \ '\s*\(\w\+\)\s*\%(,\)\?',
                        \ '\\|\1',
                        \ 'g'
                        \ ) .
                        \ '\)' 
                
            let separator = " "
            let column_list = ""

            " Build comma separated list of input parameters
            while start_line <= end_line
                let line = getline(start_line)

                " If the line has no words on it, skip it
                if line !~ '\w' || line =~ '^\s*$'
                    let start_line = start_line + 1
                    continue
                endif

                " if any of the find_end_of_cols is found, leave this loop.
                " This test is case insensitive.
                if line =~? find_end_of_cols
                    let end_line = start_line - 1
                    break
                endif

                " Decho line
                let column_name = substitute( line, 
                            \ '[ \t"]*\(\<\w\+\>\).*', '\1', "g" )
                let column_def = SQLU_GetColumnDatatype( line, 1 )

                let column_list = column_list . separator . column_name
                let procedure_def = procedure_def . 
                            \ indent_spaces .
                            \ separator .
                            \ "IN @" . column_name .
                            \ ' ' . column_def . "\n"

                let separator  = ","
                let start_line = start_line + 1
            endwhile

            let procedure_def = procedure_def .  ")\n"
            let procedure_def = procedure_def . "RESULT(\n" 

            let start_line = line("'<")
            let separator  = " "
            
            " Build comma separated list of datatypes
            while start_line <= end_line
                let line = getline(start_line)
                
                " If the line has no words on it, skip it
                if line !~ '\w' || line =~ '^\s*$'
                    let start_line = start_line + 1
                    continue
                endif

                let column_def = SQLU_GetColumnDatatype( line, 1 )
                
                let procedure_def = procedure_def .
                            \ indent_spaces .
                            \ separator . 
                            \ column_def .
                            \ "\n"

                let separator  = ","
                let start_line = start_line + 1
            endwhile

            let procedure_def = procedure_def .  ")\n"
            " Strip off any spaces
            let column_list = substitute( column_list, ' ', '', 'g' )
            " Ensure there is one space after each ,
            let column_list = substitute( column_list, ',', ', ', 'g' )
            let pk_column_list = SQLU_CreateColumnList(
                        \ table_name, 'primary_keys')

            let procedure_def = procedure_def . "BEGIN\n\n" 
            
            " Create a sample SELECT statement
            let procedure_def = procedure_def . 
                        \ indent_spaces .
                        \ "SELECT " . column_list . "\n" .
                        \ indent_spaces .
                        \ "  FROM " . table_name . "\n"
            let where_clause = indent_spaces . 
                        \ substitute( column_list, 
                        \ '^\(\<\w\+\>\)\(.*\)', " WHERE \\1 = \@\\1\\2", "g" )
            let where_clause = 
                        \ substitute( where_clause, 
                        \ ', \(\<\w\+\>\)', 
                        \ "\n" . indent_spaces . "   AND \\1 = @\\1", "g" )
            let procedure_def = procedure_def . where_clause . ";\n\n"

            " Create a sample INSERT statement
            let procedure_def = procedure_def . 
                        \ indent_spaces . 
                        \ "INSERT INTO " . table_name . "( " .
                        \ column_list .
                        \ " )\n"
            let procedure_def = procedure_def . 
                        \ indent_spaces .
                        \ "VALUES( " .
                        \ substitute( column_list, '\(\<\w\+\>\)', '@\1', "g" ).
                        \ " );\n\n"

            " Create a sample UPDATE statement
            let procedure_def = procedure_def . 
                        \ indent_spaces .
                        \ "UPDATE " . table_name . "\n" 

            " Now we must remove each of the columns in the pk_column_list
            " from the column_list, to create the no_pk_column_list.  This is
            " used by the UPDATE statement, since we do not SET columns in the
            " primary key.
            " The order of the columns in the pk_column_list is not guaranteed
            " to be in the same order as the table list in the CREATE TABLE
            " statement.  So we must remove each word one at a time.
            let no_pk_column_list = SQLU_RemoveMatchingColumns(
                        \ column_list, pk_column_list )

            " Check for the special case where there is no 
            " primary key for the table (ie ,\? \? )
            let set_clause = 
                        \ indent_spaces .
                        \ substitute( no_pk_column_list, 
                        \ ',\? \?\(\<\w\+\>\)', 
                        \ '   SET \1 = @\1', '' )
            let set_clause = 
                        \ substitute( set_clause, 
                        \ ', \(\<\w\+\>\)', 
                        \ ",\n" . indent_spaces . '       \1 = @\1', "g" )

            " Check for the special case where there is no 
            " primary key for the table
            if strlen(pk_column_list) > 0
                let where_clause = 
                            \ indent_spaces .
                            \ substitute( pk_column_list, 
                            \ '^\(\<\w\+\>\)', ' WHERE \1 = @\1', "" ) 
                let where_clause = 
                            \ substitute( where_clause, 
                            \ ', \(\<\w\+\>\)', 
                            \ "\n" . indent_spaces . '   AND \1 = @\1', "g" )
            else
                " If there is no primary key for the table place
                " all columns in the WHERE clause
                let where_clause = 
                            \ indent_spaces .
                            \ substitute( column_list, 
                            \ '^\(\<\w\+\>\)', ' WHERE \1 = @\1', "" ) 
                let where_clause = 
                            \ substitute( where_clause, 
                            \ ', \(\<\w\+\>\)', 
                            \ "\n" . indent_spaces . '   AND \1 = @\1', "g" )
            endif
            let procedure_def = procedure_def . set_clause . "\n" 
            let procedure_def = procedure_def . where_clause .  ";\n\n"

            " Create a sample DELETE statement
            let procedure_def = procedure_def . 
                        \ indent_spaces .
                        \ "DELETE FROM " . table_name . "\n" 
            let procedure_def = procedure_def . where_clause . ";\n\n"

            let procedure_def = procedure_def . "END;\n\n" 
            
        endif

        " Return to previous location
        silent! exe 'norm! '.buf_curline."G\<bar>".buf_curcol."l"

        if found == 1
            break
        endif
        
        if &hidden == 0
            call s:SQLU_WarningMsg(
                        \ "Cannot search other buffers with set nohidden"
                        \ )
            break
        endif

        " Switch buffers to check to see if the create table
        " statement exists
        silent! exec "bnext"
        if bufnr(expand("<abuf>")) == curbuf
            break
        endif
    endwhile
    
    silent! exec "buffer " . curbuf

    " restore previous search string
    let @/ = saveSearch
    
    " Return to previous location
    silent! exe 'norm! '.curline."G\<bar>".curcol."l"

    if found == 0
        let @@ = ""
        echo "Table: " . table_name . " was not found"
        return ""
    endif 

    echo 'Procedure: sp_' . table_name . ' in unnamed buffer'
    if &clipboard == 'unnamed'
        let @* = procedure_def 
    else
        let @@ = procedure_def 
    endif

    return ""

endfunction



" Compares two strings, and will remove all names from the first 
" parameter, if the same name exists in the second column name.
" The 2 parameters take comma separated lists
function! SQLU_RemoveMatchingColumns( full_col_list, dup_col_list )

    let stripped_col_list = a:full_col_list
    let pos = 0
    " Find the string index position of the first match
    let index = match( a:dup_col_list, '\w\+' )
    while index > -1
        " Get name of column
        let dup_col_name = matchstr( a:dup_col_list, '\w\+', index )
        let stripped_col_list = substitute( stripped_col_list,
                    \ dup_col_name.'[, ]*', '', 'g' )
        " Advance the search after the word we just found and look for
        " others.  
        let index = match( a:dup_col_list, '\w\+', 
                    \ index + strlen(dup_col_name) )
    endwhile

    return stripped_col_list

endfunction

function! s:SQLU_WarningMsg(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}

" vim: ts=4
