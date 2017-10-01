require_relative 'pieces'

class Player
	attr_accessor :color, :board, :pieces, :captured

	def initialize(color, board=nil)
		@color = color
		@pieces = []; @captured = []
		@color == "white" ? generate_pieces(0, 1) : generate_pieces(7, 6)
		generate_moves
		match_board(board)
	end

	def generate_pieces(a, b)
		@pieces << Queen.new(@color, [3, a]) << King.new(@color, [4, a])
		[0, 7].each { |x| @pieces << Rook.new(@color, [x, a]) }
		[1, 6].each { |x| @pieces << Knight.new(@color, [x,a]) }
		[2, 5].each { |x| @pieces << Bishop.new(@color, [x, a]) }
		(0..7).to_a.each { |x| @pieces << Pawn.new(@color, [x, b]) }
	end


	def generate_moves
		@pieces.each do |pc|
			pc.queen_moves if pc.class == Queen
			pc.king_moves if pc.class == King
			pc.rook_moves if pc.class == Rook
			pc.knight_moves if pc.class == Knight
			pc.bishop_moves if pc.class == Bishop
			pc.pawn_moves if pc.class == Pawn
		end
	end

	def match_board(board)
		@board = board
	end

end
