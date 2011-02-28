using 'redis'

helper getRedisClient: ->
		db = redis.createClient()
		throw new Error "redis: couldn't connect" unless db
		db


get '/redis/shorten/:url', (req, resp) ->
	db = getRedisClient()
	url = @url
	finish = (e) ->
		throw e if e
		db.end()
		render 'showAlias'
	do retry = ->
		db.get 'aliasCount:count', (e, reply) ->
			throw e if e
			if reply is null
				db.set 'aliasCount:count', 0, retry
				return
			nextAlias = +reply
			db.incr 'aliasCount:count', (e, reply) ->
				throw e if e
				params.alias = nextAlias
				db.set 'aliases:'+nextAlias, url, finish


get '/redis/expand/:alias', (req, resp) ->
	db = getRedisClient()
	alias = parseInt @alias, 32
	db.get 'aliases:'+alias, (e, reply) ->
		throw e if e
		params.url = reply
		if reply is null
			params.url = 'alias not found'
		db.end()
		render 'showUrl'
	return


get '/redis/clean', (req, resp) ->
	db = getRedisClient()
	db.keys '*', (e, keys) ->
		throw e if e
		for key in keys
			db.del key, (e) -> throw e if e
		db.quit()
		return
	"done"
