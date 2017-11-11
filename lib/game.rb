require_relative 'board'
require_relative 'pieces'
require_relative 'player'

# Notes:
# King protection stuff appears to be working now. Castling move fixed.
# Pawn promotion added.
# Need draw conditions.


class ChessGame
	attr_accessor :board, :p1, :p2, :full_move_history, :snapshots

	def initialize
		ChessPiece.clear
		@board = ChessBoard.new
		@p1 = Player.new("white")
		@p2 = Player.new("black")
		@full_move_history = []
		@snapshots = []
		pieces_on_board
	end

	def pieces_on_board
		@board.squares.each do |sq|
			ChessPiece.all.each do |pc|
				if sq.coord == pc.current_square
					sq.piece = pc.token
				else
					sq.piece = nil unless ChessPiece.occupies? sq.coord
				end
			end
		end
		@board.display_board
	end

	def track_moves(player)
		@full_move_history << player.move_history[-1]
	end

	def snapshot_board
		snapshot = []
		ChessPiece.all.select { |pc| pc.current_square != nil }.each do |pc|
			snapshot << [pc.class.to_s, pc.color, pc.current_square]
		end
		@snapshots << snapshot.sort!
	end

	def draw(player)
		p "Draw. Nobody wins!"
		exit
	end

	def threefold_rep?
		@snapshots.count(@snapshots[-1]) >= 3 ? true : false
	end

	def fifty_move_rule?
		unless @full_move_history[-1..-50].any? { |pc| pc[:moved].class == Pawn }
			if @full_move_history[-1..-50].all? { |pc| pc[:captured_piece] == false }
				true
			end
		else
			false
		end
	end

	def seventyfive_move_rule?
		unless @full_move_history[-1..-75].any? { |pc| pc[:moved].class == Pawn }
			if @full_move_history[-1..-75].all? { |pc| pc[:captured_piece] == false }
				true
			end
		else
			false
		end
	end

	def ask_for_draw(player, opponent)
		if fifty_move_rule? or threefold_rep?
			p "Would #{player.color.capitalize} like to draw? (Y/N)"
			answer = gets.chomp.downcase
			if answer[0] == "y" and threefold_rep?
				draw if threefold_rep
				p "Does #{opponent.color.capitalize} agree a draw? (Y/N)"
				response = gets.chomp.downcase
				draw if response[0] == "y"
			end
		end
	end

	def ask_to_resign?(player)
		p "Would #{player.color.capitalize} like to resign? (Y/N)"
		answer = gets.chomp.downcase
		if answer[0] == "y"
			p "#{player.color.capitalize} has resigned. Other player wins!"
			exit
		end
	end


	def run_game (current=@p1)
		2.times { @p1.generate_moves; @p2.generate_moves }
		assess_king_status; process_turn(current)
		puts; pieces_on_board; puts
		if current == @p1
			@p2.subtract_captured_by(@p1)
			run_game(@p2)
		else
			@p1.subtract_captured_by(@p2)
			run_game
		end
	end

	def process_turn(player)
		player.turn; track_moves(player); snapshot_board
	end

	def assess_king_status
		kings = ChessPiece.all.select { |pc| pc.class == King }
		kings.each do |king| 
			if king.check?
				king.protect_king
				king_checkmated if king.checkmate?
				 puts "#{king.color.capitalize}'s king is in check!"
			else
				king_stalemated?
			end
		end
	end

	def king_checkmated
		puts "Checkmate! #{king.color == "white" ? "Black wins!" : "White wins!"}"
		exit
	end

	def king_stalemated?
		kings = ChessPiece.all.select { |pc| pc.class == King }
		kings.each do |king|
			if king.stalemate?
				puts "Stalemate. Game over."
				exit
			end
		end
	end

end




game = ChessGame.new
#game.pieces_on_board
game.run_game

=begin
players = [game.p1, game.p2]
players.each { |p| p.generate_moves }

game.snapshot_board
game.p1.move_piece([6,0], [5,2]) 
game.track_moves(game.p1); game.snapshot_board; players.each { |p| p.generate_moves }
game.p2.move_piece([6,7], [5,5])
game.track_moves(game.p2); game.snapshot_board; players.each { |p| p.generate_moves }
game.p1.move_piece([5,2], [6,0])
game.track_moves(game.p1); game.snapshot_board; players.each { |p| p.generate_moves }
game.p2.move_piece([5,5], [6,7])
game.track_moves(game.p2); game.snapshot_board; players.each { |p| p.generate_moves }

p game.full_move_history # It works!
puts
moved_pieces = []
#game.full_move_history.each { |pc| moved_pieces << pc[:moved].class }
#p moved_pieces
p game.full_move_history[-1..0].all? { |pc| pc[:moved].class == Knight }

p game.snapshots.count(game.snapshots[-1])
p game.threefold_rep?


=end


