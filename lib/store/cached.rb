class Store::Cached < Store
	attr_reader :db
	attr_reader :cache, :working

	def initialize db, cache = Store::Memory.new
		@db = db
		@cache = cache
		# @working = {}
	end

	def load opts = {}
		@db.range(opts).each do |k, v|
			@cache[k] = v
		end
		self
	end

	def unload opts = {}
		batch = @cache.batch
		@cache.range(opts).each do |k, v|
			batch.del k
		end
		batch.apply
		self
	end

	def apply batch
		@cache.apply batch
		# @working.merge! batch
		self
	end

	def get key
		val = @cache[key]
		if val == nil
			val = @db[key]
			@cache[key] = val
		end
		val
	end

	def _range from, to
		# @data.select { |key, val| key >= from && key <= to }.map { |key, val| [key, val] }
		@cache._range from, to
	end

	def save
		@db.apply Hash[*@cache.range.flatten]
		self
	end
end