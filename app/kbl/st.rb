module Kbl
	class St < Predicate
		attr_accessor :agent
		def initialize(newAgent)
			super("St")
			self.agent = newAgent
		end

		def to_s
			self.predicate + "(" + self.agent + ")"
		end
	end
end