readlines = require '../'

reader =  new readlines({fileName : "../package.json", encode : "utf8"})
###reader.once 'readable', ()->
    read = ()->
        line = reader.readline()
        if line
            console.log line
            setTimeout read, 100
    read()
reader.on 'end', ()->
    console.log 'bye! bye!'###
reader.on 'line', (line)->
    console.log line
    if 0.5 > Math.random()
        #console.log 'hold'
        reader.pause()
        setTimeout (()-> 
            #console.log 'resume'
            reader.resume()
        ), 1000