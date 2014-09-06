import structs/ArrayList
import os/System
import io/native/FileUnix

// init
version := "0.0.1"
version_date := "0000-00-00"
version_string := "rmate-ooc #{version} (#{version_date})"

RMate: class {
    name : String
    
    host      := "localhost"
    port      := "52698"
    
    selection   := ""
    displayname := ""
    filetype    := ""
    filepath    := ""
    
    nowait?   := false
    force?    := false
    verbose?  := false

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

    /**
     * Message logging.
     */
    log: func(msg : String) {
        if (verbose?) {
            fprintf(stderr, "%s\n", msg toCString());
        }
    }
}

/**
 * Main application.
 */
main: func(args: ArrayList<String>) -> Void {
    iter := args iterator()
    name := iter next()
    
    rmate := RMate new(name)
    
    filepath := ""
    
    while (iter hasNext?()) {
        arg := iter next()
        
        if (arg substring(0, 1) != "-" || arg == "-") {
            filepath = arg
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
        } else if (arg == "--port" || arg == "-p") {
            if (iter hasNext?()) {
                rmate port = iter next()
            }
        } else if (arg == "--wait" || arg == "-w") {
            rmate nowait? = false
        } else if (arg == "--no-wait") {
            rmate nowait? = true
        } else if (arg == "--line" || arg == "-l") {
            if (iter hasNext?()) {
                rmate selection = iter next()
            }
        } else if (arg == "--name" || arg == "-m") {
            if (iter hasNext?()) {
                rmate displayname = iter next()
            }
        } else if (arg == "--type" || arg == "-t") {
            if (iter hasNext?()) {
                rmate filetype = iter next()
            }
        } else if (arg == "--force" || arg == "-f") {
            rmate force? = true
        } else if (arg == "--verbose" || arg == "-v") {
            rmate verbose? = true
        }
    }
    
    if (filepath == "") {
        rmate showusage()
        return
    }

    if (iter hasNext?()) {
        "There are more than one files specified. Opening only #{filepath} and ignoring other." println()
    }

    if (filepath != "-") {
        rmate displayname = "#{System hostname()}:#{filepath}"
    } else {
        rmate displayname = "#{System hostname()}:untitled"
    }
    
    rmate displayname println()
}
