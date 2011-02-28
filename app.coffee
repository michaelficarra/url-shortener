def inspect: require('util').inspect.bind require('util')

get '/favicon.ico', ->


view showAlias: ->
	pre (@alias ? '').toString 36

view showUrl: ->
	pre (@url ? '')


include 'mongo.coffee'
include 'riak.coffee'
include 'redis.coffee'
