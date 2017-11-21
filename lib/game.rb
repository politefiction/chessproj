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

	def snapshot_board # Messing up on pawn_promotion; investigate
		snapshot = []
		ChessPiece.all.select { |pc| pc.current_square != nil }.each do |pc|
			snapshot << [pc.class.to_s, pc.color, pc.current_square]
		end
		@snapshots << snapshot.sort!
	end

	def draw
		puts "Draw due to #{yield}. Game over."
		exit
	end

	def threefold_rep?
		@snapshots.count(@snapshots[-1]) >= 3 ? true : false
	end

	def fifty_move_rule?
		if @full_move_history.length == 50
			unless @full_move_history[-1..-50].any? { |pc| pc[:moved].class == Pawn }
				if @full_move_history[-1..-50].all? { |pc| pc[:captured_piece] == false }
					true
				end
			else
				false
			end
		else
			false
		end
	end

	def seventyfive_move_rule?
		if @full_move_history.length == 75
			unless @full_move_history[-1..-75].any? { |pc| pc[:moved].class == Pawn }
				if @full_move_history[-1..-75].all? { |pc| pc[:captured_piece] == false }
					true
				end
			else
				false
			end
		end
	end

	def ask_for_draw(player, opponent=nil)
		opponent = (player == @p1 ? @p2 : @p1)
		puts threefold_rep? ? "Threefold repetition." : "Fifty-move rule achieved."
		player.confirm_draw do
			draw { "threefold repetition" } if threefold_rep?
			puts "Does #{opponent.color.capitalize} agree to a draw? (Y/N)"
			response = gets.chomp.downcase
			draw { "fifty-move rule" } if response[0] == "y"
		end
	end


	def run_game (current=@p1)
		opponent = (current == @p1 ? @p2 : @p1 )
		[current, opponent].each { |player| player.generate_moves }
		snapshot_board; assess_king_status;
		draw { "seventy-five move rule" } if seventyfive_move_rule?
		ask_for_draw(current) if threefold_rep? or fifty_move_rule?
		process_turn(current)
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
		player.turn; track_moves(player)
	end

	def assess_king_status
		[@p1, @p2].each do |player|
			if player.king.check?
				player.king.protect_king
				king_checkmated if player.king.checkmate?
				puts "#{player.color.capitalize}'s king is in check!"
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
game.p1.move_piece([4,1], [4,3]) 
game.track_moves(game.p1); game.snapshot_board; players.each { |p| p.generate_moves }
game.p2.move_piece([3,6], [3,5])
game.track_moves(game.p2); game.snapshot_board; players.each { |p| p.generate_moves }
game.p1.move_piece([5,0], [1,4])
game.track_moves(game.p1); game.snapshot_board; players.each { |p| p.generate_moves }


p game.p2.king.protect_king
p game.p2.king.check?


#game.ask_for_draw(game.p1, game.p2)

=begin

=end


