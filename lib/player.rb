require_relative 'pieces'

class Player
	attr_accessor :color, :pieces, :captured#, :board

	def initialize(color)
		@color = color
		@pieces = []; @captured = []
		@color == "white" ? generate_pieces(0, 1) : generate_pieces(7, 6)
		generate_moves
		#match_board(board)
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

	def move_piece(from, to)
		movepc = @pieces.select { |pc| pc.current_square == from }[0]
		if movepc.potential_moves.include? to
			if ChessPiece.occupies? to
				oppospc = ChessPiece.all.select { |pc| pc.current_square == to }[0]
				oppospc.current_square = nil; oppospc.potential_moves = []
				@captured << oppospc
			end
			castling?(movepc, to) if movepc.class == King
			movepc.current_square = to
			movepc.first_move = false if movepc.class == (Pawn || Rook || King)
		else
			puts "Please choose a valid move." # maybe have a hint option that shows possible moves?
			puts "Potential_moves: #{movepc.potential_moves.inspect}"
			turn
		end
	end

	def castling?(king, to)
		y = king.current_square[1]
		if king.first_move and king.potential_moves.include? ([1,y] or [6,y])
			rook1 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [0, y] }[0]
			rook2 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [7, y] }[0]
			rook1.current_square = [2,y] if to == [1,y]
			rook2.current_square = [5,y] if to == [6,y]
		end
	end

	def turn
		puts "#{@color.capitalize}\'s turn. Where is the piece you'd like to move? (e.g., 'A4', 'G2', etc.): "
		fromalpha = gets.chomp; from = convert_coord(fromalpha)
		if @pieces.any? { |pc| pc.current_square == from }
			piece = @pieces.select { |pc| pc.current_square == from }[0]
			if !piece.potential_moves.empty?
				puts "Where would you like to move this piece?"
				toalpha = gets.chomp; to = convert_coord(toalpha)
				move_piece(from, to)
			else
				puts "This piece has no available moves. Please choose another piece."
				turn
			end
		else
			puts "Please choose a square occupied by a #{@color} piece."
			turn
		end
	end

	def convert_coord(coord)
		split_coord = coord.downcase.split(//)
		new_coord = []
		if split_coord[0].between?('a','h') and split_coord[1].to_i.between?(1,8)
			('a'..'h').to_a.each_with_index { |n, i| new_coord << i if n == split_coord[0] }
			new_coord << (split_coord[1].to_i - 1)
			new_coord
		else
			puts "That coordinate is not valid. Please try again."
			turn
		end
	end

	def subtract_captured(captured)
		@pieces -= captured
	end

end




=begin

player1 = Player.new("white")
player2 = Player.new("black")

player2.pieces[8].current_square = [2, 2]
player1.generate_moves
player1.move_piece([1, 1], [2,2])

player1.pieces.select { |pc| pc.class == Pawn }.each do |pc|
	p "#{pc.class}: #{pc.current_square}, #{pc.first_move}"
end

p player1.captured




	def turn
		puts "#{@color.capitalize}\'s turn. Where is the piece you'd like to move? (e.g., 'A4', 'G2', etc.): "
		fromalpha = gets.chomp; from = convert_coord(fromalpha)
		if @pieces.any? { |pc| pc.current_square == from }
			puts "Where would you like to move this piece?"
			toalpha = gets.chomp; to = convert_coord(toalpha)
			move_piece(from, to)
		else
			puts "Please choose a square occupied by a #{@color} piece."
			turn
		end
	end

	def convert_coord(coord)
		split_coord = coord.downcase.split(//)
		new_coord = []
		if split_coord[0].between?('a','h') and split_coord[1].to_i.between?(1,8)
			('a'..'h').to_a.each_with_index { |n, i| new_coord << i if n == split_coord[0] }
			new_coord << (split_coord[1].to_i - 1)
			new_coord
		else
			puts "That coordinate is not valid. Please try again."
			turn
		end
	end

=end 
