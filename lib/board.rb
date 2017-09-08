class Square
	attr_accessor :coord, :piece

	def initialize(coord)
		@coord = coord
		@piece = nil
	end

end


class ChessBoard
	attr_accessor :squares

	def initialize
		@squares = []
		build_board
	end

	def build_board
		row = (0..7).to_a
		col = (0..7).to_a
		row.each { |x| col.each { |y| @squares << Square.new([x, y]) } }
	end

	def display_board
		count = 7
		while count >= 0
			row = @squares.select { |sq| sq.coord[0] == count }
			count.even? ? checker_black(row) : checker_white(row)
			count -= 1
		end
	end

	def checker_white(row)
		ch_row = []
		row.each do |sq|
			if !sq.piece.nil?
				ch_row << sq.piece
			else
				sq.coord[1].even? ? ch_row << " " : ch_row << "■"
			end
		end
		puts ch_row.join(" ")
	end

	def checker_black(row)
		ch_row = []
		row.each do |sq|
			if !sq.piece.nil?
				ch_row << sq.piece
			else
				sq.coord[1].odd? ? ch_row << " " : ch_row << "■"
			end
		end
		puts ch_row.join(" ")
	end

end

#board = ChessBoard.new
#board.display_board
