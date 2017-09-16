require 'pieces'

describe MoveSet do
end

describe ChessPiece do 
	subject { ChessPiece.new("black", [2,2]) }
	context 'upon creation' do
		it { is_expected.to respond_to(:color) }
		it { is_expected.to respond_to(:token) }
		it { is_expected.to respond_to(:move_set) }
	end
end

describe Pawn do 
	subject { Pawn.new("white", [1,0]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♙")
		end

		it 'should have two potential moves' do
			expect(subject.move_set.potential_moves.length).to eq(2)
		end
	end

	context 'after pawn has had first move' do
		before do 
			subject.move_set.potential_moves = []
			subject.first_move = false 
			subject.pawn_moves
		end
		
		it 'should have one potential move' do
			expect(subject.move_set.potential_moves.length).to eq(1)
		end
	end
end

describe Rook do
	subject { Rook.new("white", [0,0]) }
end

describe Knight do
	subject { Knight.new("black", [6,7]) }
end

describe Bishop do
	subject { Bishop.new("white", [0,2]) }
end

describe Queen do
	subject { Queen.new("black", [3, 7]) }
end

describe King do
	subject { King.new("white") [4, 0]}
end