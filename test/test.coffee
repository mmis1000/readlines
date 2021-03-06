readlines = require '../'

reader =  new readlines({fileName : "../package.json", encode : "utf8"})
reader.once 'readable', ()->
    read = ()->
        line = reader.readline()
        if !reader.exited
            console.log line if line
            setTimeout read, 200
    read()

reader.on 'end', ()->
    console.log 'bye! bye!'