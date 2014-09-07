/*
 * rmate-ooc
 * Copyright (C) 2014 by Harald Lapp <harald@octris.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * This software can be found at:
 * https://github.com/aurora/rmate-ooc
 *
 * Thanks very much to all users and contributors! All bug-reports,
 * feature-requests, patches, etc. are greatly appreciated! :-)
 *
 */

import structs/ArrayList
import os/[System, unistd]
import io/[File, FileReader]
import io/native/FileUnix
import net/TCPSocket
import text/Regexp

// init
version := "0.0.1"
version_date := "0000-00-00"
version_string := "rmate-ooc #{version} (#{version_date})"

name := ""
host := "localhost"
port := "52698"

verbose? := false

/* TODO:
   load configuration file
*/

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
-h, --help       Display usage information.
    --version    Show version and exit.
" println()
}

/**
 * Message logging.
 */
log: func(msg: String) {
    if (verbose?) {
        fprintf(stderr, "%s\n", msg toCString());
    }
}

/**
 * Main application.
 */
main: func(args: ArrayList<String>) -> Void {
    iter := args iterator()
    name = iter next()

    selection   := ""
    displayname := ""
    filetype    := ""
    filepath    := ""
    resolvedpath : CString = ""

    nowait?   := false
    force?    := false

    while (iter hasNext?()) {
        arg := iter next()
    
        if (arg substring(0, 1) != "-" || arg == "-") {
            filepath = arg
            break
        }

        if (arg == "--help" || arg == "-h") {
            showusage()
            exit(1)
        } else if (arg == "--version") {
            version_string println()
            exit(1)
        } else if (arg == "--host" || arg == "-H") {
            if (iter hasNext?()) {
                host = iter next()
            }
        } else if (arg == "--port" || arg == "-p") {
            if (iter hasNext?()) {
                port = iter next()
            }
        } else if (arg == "--wait" || arg == "-w") {
            nowait? = false
        } else if (arg == "--no-wait") {
            nowait? = true
        } else if (arg == "--line" || arg == "-l") {
            if (iter hasNext?()) {
                selection = iter next()
            }
        } else if (arg == "--name" || arg == "-m") {
            if (iter hasNext?()) {
                displayname = iter next()
            }
        } else if (arg == "--type" || arg == "-t") {
            if (iter hasNext?()) {
                filetype = iter next()
            }
        } else if (arg == "--force" || arg == "-f") {
            force? = true
        } else if (arg == "--verbose" || arg == "-v") {
            verbose? = true
        }
    }

    if (filepath == "") {
        showusage()
        exit(1)
    }

    if (iter hasNext?()) {
        log("There are more than one files specified. Opening only #{filepath} and ignoring other.")
    }

    if (filepath != "-") {
        realpath(filepath as CString, resolvedpath)

        displayname = "#{System hostname()}:#{filepath}"
    } else {
        displayname = "#{System hostname()}:untitled"
    }

    // communicate with textmate
    socket := TCPSocket new(host, port toInt())

    try {
        socket connect()
    } catch(e: Exception) {
        log("Unable to connect to TextMate on #{host}:#{port}")
        exit(1)
    }
    log(socket in readLine() trim())

    socket out write("open\n")
    socket out write("display-name: #{displayname}\n")
    socket out write("real-path: #{resolvedpath}\n")
    socket out write("data-on-save: yes\n")
    socket out write("re-activate: yes\n")
    socket out write("token: #{filepath}\n")

    if (selection != "") {
        socket out write("selection: #{selection}\n")
    }
    if (filetype != "") {
        "filetype: #{filetype}" println()
        socket out write("file-type: #{filetype}\n")
    }

    if (filepath != "-") {
        file := File new(filepath)
        
        if (file file?()) {
            socket out write("data: #{file getSize()}\n")
            socket out write(file read())
        } else {
            socket out write("data: 0\n");
        }
    } else {
        if (isatty(0)) {
            "Reading from stdin, press ^D to stop" println()
        } else {
            log("Reading from stdin")
        }
        
        file := FileReader new (stdin)
        data := file readAll()
        file close()
        
        socket out write("data: #{data length()}\n")
        socket out write(data);
    }

    socket out write("\n.\n")

    // textmate connection handling

    /* TODO: 
       fork to background if --no-wait is set
    */
    
    pattern := Regexp compile("^([^:]+): *(.+)$")
    
    while (socket in hasNext?()) {
        cmd   := socket in readLine() trim()
        token := ""
        tmp   := ""

        while (socket in hasNext?()) {
            reply   := socket in readLine() trim()
            matches := pattern matches(reply)
            
            if (!matches) {
                break
            }
            
            match (matches group(1)) {
                case "token" =>
                    token = matches group(2)
                case "data" =>
                    size   := matches group(2) toInt()
                    buffer := Buffer new(size)
                
                    socket receive(buffer, size as SizeT)
                    
                    tmp = "#{tmp}#{buffer}"
            }
        }
        
        match (cmd) {
            case "close" =>
                log("Closing #{token}")
            case "save" =>
                log("Saving #{token}")
                
                if (token != "-") {
                    file := File new(filepath)
                    file write(tmp)
                }
        }
    }
    
    log("Done")
    
    exit(0)
}
