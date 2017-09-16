require_relative 'board'

# Can assign black/white to pieces when creating objects for Player class.
# Will need to create a way for potential moves to account 
# for squares that are aleady occupied by other pieces.


class MoveSet
	attr_accessor :current_square, :potential_moves

	def initialize(current_square, potential_moves=[])
		@current_square = current_square
		@potential_moves = potential_moves
	end

end

class ChessPiece
	attr_accessor :color, :move_set, :token
	@@all = []

	def initialize(color, current_square)
		@color = color
		@move_set = MoveSet.new(current_square)
		@@all << self
	end

	def set_token(wt, bt)
		@color == "white" ? @token = wt : @token = bt
	end

	def self.all
		@@all
	end# refine self.all, find way to make attributes accessible
end


class Pawn < ChessPiece
	attr_accessor :first_move
	@@wt = "♙"
	@@bt = "♟"

	def initialize(color, current_square)
		super
		@first_move = true
		set_token(@@wt, @@bt) 
		pawn_moves
	end

	def pawn_moves
		cs = @move_set.current_square
		pm = @move_set.potential_moves
		pm << [cs[0], cs[1]+1]
		pm << [cs[0], cs[1]+2] if @first_move
		#@move_set.potential_moves << [cs.coord[-1], cs.coord[1]+1] if that square's the current square for any opp color piece? Hmm
		# will add diagonal move later	
	end# pawn_moves still needs diagonal
end

class Rook < ChessPiece
	@@wt = "♖"
	@@bt = "♜"

	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt) 
		rook_moves
	end

	def rook_moves
		cs = @move_set.current_square
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			pm << [cs[0]+n, cs[1]] if (cs[0]+n) < 8
			pm << [cs[0], cs[1]+n] if (cs[1]+n) < 8
			pm << [cs[0]-n, cs[1]] if (cs[0]-n) >= 0
			pm << [cs[0], cs[1]-n] if (cs[1]-n) >= 0
		end
	end
end

class Knight < ChessPiece
	@@wt = "♘"
	@@bt = "♞"
	
	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
		knight_moves
	end

	def knight_base(a, b)
		cs = @move_set.current_square; x = cs[0]; y = cs[1]
		pm = @move_set.potential_moves
		(pm << ([x+a, y+b] if y+a < 8) << ([x+a, y-b] if y-a >= 0)) if x + a < 8
		(pm << ([x-a, y+b] if y+a < 8) << ([x-a, y-b] if y-a >= 0)) if x - a >= 0
	end

	def knight_moves
		knight_base(1, 2)
		knight_base(2, 1)
	end
end

class Bishop < ChessPiece
	@@wt = "♗"
	@@bt = "♝"

	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
		bishop_moves
	end

	def bishop_moves
		cs = @move_set.current_square
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			pm << [cs[0] + n, cs[1] + n] if (cs[0]+n) < 8 and (cs[1]+n) < 8
			pm << [cs[0] + n, cs[1] - n] if (cs[0]+n) < 8 and (cs[1]-n) >= 0
			pm << [cs[0] - n, cs[1] + n] if (cs[0]-n) >= 0 and (cs[1]+n) < 8
			pm << [cs[0] - n, cs[1] - n] if (cs[0]-n) >= 0 and (cs[1]-n) >= 0
		end
	end
end

class Queen < ChessPiece
	@@wt = "♕"
	@@bt = "♛"
	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
		queen_moves
	end

	def queen_moves
		cs = @move_set.current_square
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			pm << [cs[0]+n, cs[1]] if (cs[0]+n) < 8
			pm << [cs[0], cs[1]+n] if (cs[1]+n) < 8
			pm << [cs[0]-n, cs[1]] if (cs[0]-n) >= 0
			pm << [cs[0], cs[1]-n] if (cs[1]-n) >= 0
		end
		(1..7).to_a.each do |n|
			pm << [cs[0] + n, cs[1] + n] if (cs[0]+n) < 8 and (cs[1]+n) < 8
			pm << [cs[0] + n, cs[1] - n] if (cs[0]+n) < 8 and (cs[1]-n) >= 0
			pm << [cs[0] - n, cs[1] + n] if (cs[0]-n) >= 0 and (cs[1]+n) < 8
			pm << [cs[0] - n, cs[1] - n] if (cs[0]-n) >= 0 and (cs[1]-n) >= 0
		end
	end
end

class King < ChessPiece # investigate king_moves; also need move for rook swap
	@@wt = "♔"
	@@bt = "♚"
	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
		king_moves
	end

	def king_moves # pushing nil values as is; knight_moves has same set up, but is fine...?
		cs = @move_set.current_square; x = cs[0]; y = cs[1]
		pm = @move_set.potential_moves
		pm << ([x + 1, y] if x+1 < 8) << ([x - 1, y] if x-1 >= 0)
		pm << ([x, y + 1] if y+1 < 8) << ([x, y - 1] if y-1 >= 0)
		(pm << ([x + 1, y + 1] if y+1 < 8) << ([x + 1, y - 1] if y-1 >= 0)) if x+1 < 8
		(pm << ([x - 1, y + 1] if y+1 < 8) << ([x - 1, y - 1] if y-1 >= 0)) if x-1 >= 0

	end
end

=begin
knight = Knight.new("white", [0, 2])
p knight.move_set.potential_moves

king = King.new("black", [0, 2])
p king.move_set.potential_moves
=end