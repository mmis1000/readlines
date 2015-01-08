readlines = require '../'

reader =  new readlines({fileName : "../package.json", encode : "utf8"})
reader.once 'readable', ()->
    read = ()->
        while line = reader.readline()
            console.log line if line
        if !reader.exited
            setTimeout read, 200
    read()

reader.on 'end', ()->
    console.log 'bye! bye!'