import structs/ArrayList

// init
version := "0.0.1"
version_date := "0000-00-00"
version_string := "rmate-ooc #{version} (#{version_date})"

RMate: class {
    name : String
    
    host := "localhost"
    port := "52698"

    init: func(=name)

    /**
     * Show usage information.
     */
    showusage: func {
        "usage: #{name} [arguments] file-path  edit specified file
   or: #{name} [arguments] -          read text from stdin

-H, --host HOST  Connect to HOST. Use 'auto' to detect the host from
                 SSH. Defaults to #{host}.
-p, --port PORT  Port number to use for connection. Defaults to #{port}.
-w, --[no-]wait  Wait for file to be closed by TextMate.
-l, --line LINE  Place caret on line number after loading file.
-m, --name NAME  The display name shown in TextMate.
-t, --type TYPE  Treat file as having specified type.
-f, --force      Open even if file is not writable.
-v, --verbose    Verbose logging messages.
-h, --help       Display this usage information.
    --version    Show version and exit.
" println()
    }

    
}

/**
 * Main application.
 */
main: func (args: ArrayList<String>) {
    iter := args iterator()
    name := iter next()
    
    rmate := RMate new(name)
    
    while (iter hasNext?()) {
        arg := iter next()
        
        if (arg substring(0, 1) != "-") {
            break
        }
    
        if (arg == "--help" || arg == "-h") {
            rmate showusage()
        } else if (arg == "--version") {
            version_string println()
        } else if (arg == "--host" || arg == "-H") {
            if (iter hasNext?()) {
                rmate host = iter next()
            }
        }
    }
    
    rmate showusage()
}

