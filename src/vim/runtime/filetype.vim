" my filetype file
if exists("did_load_filetypes")
    finish
endif
augroup filetypedetect
    au! BufRead,BufNewFile *.go setfiletype go
    au! BufRead,BufNewFile *.conf setfiletype conf
augroup END
