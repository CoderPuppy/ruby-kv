require File.expand_path("../../store", __FILE__)

class Store::Memory < Store
	def initialize
		@data = {}
	end

	def apply batch
		@data.merge! batch.dup.delete_if { |k, v| v == nil }
		self
	end

	def get key
		@data[key]
	end

	def _range from, to
		@data
			.select { |key, val| key >= from && key <= to }
			.map { |key, val| [key, val] }
	end
end