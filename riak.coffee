def riakjs: require 'riak-js'

helper getRiakClient: ->
		db = riakjs.getClient()
		throw new Error "riak: couldn't connect" unless db
		db


get '/riak/shorten/:url', (req, resp) ->
	db = getRiakClient()
	url = @url
	finish = (e) ->
		throw e if e
		render 'showAlias'
	do retry = ->
		db.exists 'aliasCount', 'count', (e, exists) ->
			throw e if e
			if !exists
				db.save 'aliasCount', 'count', {count: 0}, retry
				return
			db.get 'aliasCount', 'count', (e, count, meta) ->
				throw e if e
				nextAlias = +count.count
				count.count = +count.count + 1
				db.save 'aliasCount', 'count', count, meta, (e) ->
					return retry() if e
					params.alias = nextAlias
					db.save 'aliases', nextAlias, {url}, finish
	return


get '/riak/expand/:alias', (req, resp) ->
	db = getRiakClient()
	alias = parseInt @alias, 32
	finish = ->
		render 'showUrl'
	db.exists 'aliases', alias, (e, exists) ->
		throw e if e
		if !exists
			params.url = 'alias not found'
			finish()
			return
		db.get 'aliases', alias, (e, url) ->
			throw e if e
			params.url = url?.url
			finish()
			return
	return


get '/riak/clean', (req, resp) ->
	db = getRiakClient()
	db.keys 'aliases', (e, keys) ->
		throw e if e
		for key in keys
			db.remove 'aliases', key, (e) -> throw e if e
		return
	db.keys 'aliasCount', (e, keys) ->
		throw e if e
		for key in keys
			db.remove 'aliasCount', key, (e) -> throw e if e
		return
	"done"
