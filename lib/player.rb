require_relative 'pieces'

class Player
	attr_accessor :color, :pieces, :captured

	def initialize(color)
		@color = color
		@pieces = []; @captured = []
		@color == "white" ? generate_pieces(0, 1) : generate_pieces(7, 6)
		generate_moves
	end

	def generate_pieces(a, b)
		@pieces << Queen.new(@color, [3, a]) << King.new(@color, [4, a])
		[0, 7].each { |x| @pieces << Rook.new(@color, [x, a]) }
		[1, 6].each { |x| @pieces << Knight.new(@color, [x,a]) }
		[2, 5].each { |x| @pieces << Bishop.new(@color, [x, a]) }
		(0..7).to_a.each { |x| @pieces << Pawn.new(@color, [x, b]) }
	end


	def generate_moves
		@pieces.each { |pc| pc.set_moves }
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

	def convert_coord(coord)
		split_coord = coord.downcase.split(//)
		num_coord = []
		if split_coord[0].between?('a','h') and split_coord[1].to_i.between?(1,8)
			('a'..'h').to_a.each_with_index { |n, i| num_coord << i if n == split_coord[0] }
			num_coord << (split_coord[1].to_i - 1)
			num_coord
		else
			false
		end
	end

	def hint(movepc)
		alphanums = []
		movepc.potential_moves.each do |coord|
			anc = ""
			('a'..'h').to_a.each_with_index { |let, i| anc << let.upcase if coord[0] == i }
			anc << (coord[1]+1).to_s
			alphanums << anc
		end
		puts "Potential moves for #{movepc.class}: #{alphanums.join(", ")}"
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
			puts "Invalid move. Would you like to see potential moves? (Y/N)"
			answer = gets.chomp.downcase
			hint(movepc) if answer[0] == "y"; turn
			#puts "Potential_moves: #{movepc.potential_moves.inspect}"
			#turn
		end
	end

	def subtract_captured(captured)
		@pieces -= captured
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
				puts "This piece has no available moves. Please choose another piece."; turn
			end
		else
			puts from == false ? "That coordinate is not valid. Please try again." : "Please choose a square occupied by a #{@color} piece."
			turn
		end
	end

end




=begin

=end 
