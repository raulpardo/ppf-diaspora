module Kbl
	class Ment < Predicate
		attr_accessor :mentioned
		attr_accessor :mentioner
		def initialize(initialMentioner, initialMentioned)
			super("Ment")
			self.mentioner = initialMentioner
			self.mentioned = initialMentioned
		end

		def to_s
			self.predicate + "(" + self.mentioner + ", " + self.mentioned + ")"
		end
	end
end