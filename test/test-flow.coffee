readlines = require '../'

reader =  new readlines({fileName : "../package.json", encode : "utf8"})

reader.on 'line', (line)->
    console.log line
    
    reader.pause()
    setTimeout (()-> 
        reader.resume()
    ), 200

reader.on 'end', ()->
    console.log 'bye! bye!'