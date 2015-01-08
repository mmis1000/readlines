Read big files or streams with better memory usage.
This currently only works with streams in non-flow mode.

###usage

    readlines = require ("lines-reader")
    reader =  new readlines(options)

###options

    fileName : absolute / relative file path [optional] 
    input : streams [ignored if fileName was set, required]
    output : streams [optional]
    lines : number [prefetch lines before readable event was emited, default to 10]
    preloadLinesRatio : number [a multifier for lines option, default to 2]
    ignoreEmptyLine : boolean [ignore 0 byte lines, default to true]
    macStyleLineEnd : boolean [use \r instead of \r?\n as line separator, default to false]
    encode : null/number [output encode, default to null(buffer)]
    maxBuffer : number [flush lines immediately if output buffer excceed this, default to lines * 256]

###event
    
    line : emit when new line, listen to this cause reader turn into flow mode
    readable : emit when enough lines were prefetched
    end : emit when source was closed and internal buffer flushed

###example(flowMode)

    readlines = require "lines-reader"
    reader =  new readlines({fileName : "../package.json", encode : "utf8"})
    reader.on 'line', (line)->
        console.log line
        reader.pause()
        setTimeout (()-> 
            reader.resume()
        ), 1000
    #print text with delay of each line

example(non-flowMode)

    readlines = require "lines-reader"
    reader =  new readlines({fileName : "../package.json", encode : "utf8"})
    reader.once 'readable', ()->
        read = ()->
            line = reader.readline()
            if line
                console.log line
                setTimeout read, 100
        read()