module Kbl
	class Loc < Predicate
		attr_accessor :agent
		def initialize(newAgent)
			super("Loc")
			self.agent = newAgent
		end

		def to_s
			self.predicate + "(" + self.agent + ")"
		end
	end
end