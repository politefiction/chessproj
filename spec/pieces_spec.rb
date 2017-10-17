require 'pieces'


describe ChessPiece do 
	subject { ChessPiece.new("black", [5,4]) }
	context 'upon creation' do
		it { is_expected.to respond_to(:color) }
		it { is_expected.to respond_to(:token) }
		it { is_expected.to respond_to(:current_square) }
		it { is_expected.to respond_to(:potential_moves) }
	end

	describe '#set_token' do
		before { subject.set_token("♧", "♣") }
		it 'assigns the token matching the color' do
			expect(subject.token).to eq("♣")
		end
	end
end

describe Pawn do
	subject { Pawn.new("white", [1,1]) }
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♙")
		end

		it 'should have two potential moves' do
			expect(subject.potential_moves.length).to eq(2)
		end
	end

	describe '#pawn_moves' do
		context 'after pawn has had first move' do
			before do 
				subject.first_move = false 
				subject.set_moves
			end

			it 'should have one potential move' do
				expect(subject.potential_moves.length).to eq(1)
			end
		end

		context 'when an opposing piece is diagonal to pawn' do
			let(:knight) { Knight.new("black", [2,2]) }
			before do
				knight.inspect # test does not work without this, for some reason
				subject.set_moves
			end
			it 'should add a diagonal move' do
				expect(subject.potential_moves).to include([2,2])
			end
		end
	end
end

describe Rook do
	subject { Rook.new("white", [7,0]) }
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♖")
		end
		it 'generates correct potential moves' do
			pm = subject.potential_moves
			expect(pm).to include([5,0], [7,3], [4,0])
			expect(pm).not_to include(nil)
		end
	end
end

describe Knight do
	subject { Knight.new("black", [6,7]) }
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♞")
		end
		it 'generates correct potential moves' do
			pm = subject.potential_moves
			expect(pm).to include([5,5], [7,5], [4,6])
			expect(pm).not_to include(nil)
		end
	end
end

describe Bishop do
	subject { Bishop.new("white", [0,2]) }
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♗")
		end
		it 'generates correct potential moves' do
			pm = subject.potential_moves
			expect(pm).to include([1,3], [3,5], [4,6])
			expect(pm).not_to include(nil)
		end
	end
end

describe Queen do
	subject { Queen.new("black", [3, 7]) }
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♛")
		end
		it 'generates correct potential moves' do
			pm = subject.potential_moves
			expect(pm).to include([3, 4], [2, 7], [6, 4], [1,5])
			expect(pm).not_to include(nil)
		end
	end
end

describe King do
	subject { King.new("white", [4, 0])}
	before(:each) { subject.set_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♔")
		end

		it 'generates correct potential moves' do
			pm = subject.potential_moves
			expect(pm).to include([4, 1], [5, 0])
			expect(pm).not_to include(nil)
		end
	end

	describe '#check?' do
		context 'when king is threatened by an opposing piece' do
			let(:rook) { Rook.new("black", [0,0]) }
			before { rook.set_moves }
			it 'triggers a check' do
				expect(subject.check?).to eq(true)
			end
		end
	end

	describe '#checkmate?' do
		let(:bishop) { Bishop.new("black", [7,2]) }
		let(:queen) { Queen.new("black", [3,3]) }
		let(:pawn) { Pawn.new("black", [4,2]) }
		
		context 'when pawn is two squares ahead and king is threatened on all other sides' do
			before { bishop.set_moves; queen.set_moves; pawn.set_moves }
			it 'does not trigger a checkmate' do
				expect(subject.checkmate?).to eq(false)
			end
		end

		context 'when king is threatened on all sides' do
			let(:knight) { Knight.new("black", [6, 2]) }
			before { knight.set_moves }
			it 'triggers a checkmate' do
				expect(subject.checkmate?).to eq(true)
			end
		end

		context 'when king has threats on all sides including a diagonal pawn' do
			before do
				pawn.current_square = [3, 1]; queen.current_square = [4, 2]
				pawn.set_moves; queen.set_moves
			end
			it 'triggers a checkmate' do
				expect(subject.checkmate?).to eq(true)
			end
		end
	end
end