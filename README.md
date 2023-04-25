# S57Parser

A parser for ENC S57 files and directories

Follows IHO S-57 specifications:

    https://iho.int/uploads/user/pubs/standards/s-57/31Main.pdf
    https://iho.int/uploads/user/pubs/standards/s-57/31ApAch1.pdf
    https://iho.int/uploads/user/pubs/standards/s-57/31ApAch2.pdf
    
Has 3 levels :
    - Parser may return a Feature list with all references resolved with Swift Data Types.
        It is easier to use
        
    - Parser may return an intermediate model where you may use Swift subscript notation
        but is not guaranteed to succeed
        
    - Finally you may access de model directly based in dictionaries and arrays and
        having to typecast values.
        


Some ideas from https://github.com/tburke/iso8211.git
