MemDOWN = `require('memdown')`

require File.expand_path("../../store", __FILE__)

class Store::NodeMemory < Store
	def initialize loc
		@db = `#{MemDOWN}(#{loc})`
	end

	def apply batch
		`#@db.batch(#{batch.map{|kv|`{type: 'put', key: #{kv.first}, value: #{kv.last}}`}}, function(err){if(err) throw err})`
		self
	end

	def get key
		`#@db._store[#@db._location].get(#{key}) || #{nil}`
	end

	def _range from, to
		Iterator.new `#@db.iterator({gte: #{from}, lte: #{to}})`
	end

	class Iterator
		include Enumerable

		def initialize iter
			@iter = iter
		end

		def each
			return self unless block_given?
			while true
				break if `#@iter._done++ >= #@iter._limit`
				break unless `#@iter._tree.valid`
				yield `#@iter._tree.key`, `#@iter._tree.value`
			end
		end
	end
end