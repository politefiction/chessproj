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
	end 
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
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		pm << [x, y+1]
		pm << [x, y+2] if @first_move
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
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			pm << ([x+n, y] if x+n < 8) << ([x-n, y] if x-n >= 0)
			pm << ([x, y+n] if y+n < 8) << ([x, y-n] if y-n >= 0)
		end
		pm.compact!
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
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		(pm << ([x+a, y+b] if y+a < 8) << ([x+a, y-b] if y-a >= 0)) if x+a < 8
		(pm << ([x-a, y+b] if y+a < 8) << ([x-a, y-b] if y-a >= 0)) if x-a >= 0
		pm.compact!
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
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			(pm << ([x+n, y+n] if y+n < 8) << ([x+n, y-n] if y-n >= 0)) if x+n < 8
			(pm << ([x-n, y+n] if y+n < 8) << ([x-n, y-n] if y-n >= 0)) if x-n >= 0
		end
		pm.compact!
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
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		(1..7).to_a.each do |n|
			pm << ([x+n, y] if x+n < 8) << ([x-n, y] if x-n >= 0)
			pm << ([x, y+n] if y+n < 8) << ([x, y-n] if y-n >= 0)
			(pm << ([x+n, y+n] if y+n < 8) << ([x+n, y-n] if y-n >= 0)) if x+n < 8
			(pm << ([x-n, y+n] if y+n < 8) << ([x-n, y-n] if y-n >= 0)) if x-n >= 0
		end
		pm.compact!
	end
end

class King < ChessPiece # need move for rook swap
	@@wt = "♔"
	@@bt = "♚"
	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
		king_moves
	end

	def king_moves 
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		pm << ([x, y+1] if y+1 < 8) << ([x, y-1] if y-1 >= 0)
		(pm << [x+1, y] << ([x+1, y+1] if y+1 < 8) << ([x+1, y-1] if y-1 >= 0)) if x+1 < 8
		(pm << [x-1, y] << ([x-1, y+1] if y+1 < 8) << ([x-1, y-1] if y-1 >= 0)) if x-1 >= 0
		pm.compact!

	end
end



knight = Knight.new("black", [1,2])
#p knight.move_set.potential_moves
king = King.new("white", [4, 0])
#p king.move_set.potential_moves
pawn = Pawn.new("white", [0, 1])

p ChessPiece.all.select { |piece| piece.color == "white" }