require 'board'

describe Square do 
	describe '#initialize' do
		subject { Square.new([0, 0]) }
		context 'upon creation' do
			it { is_expected.to respond_to(:coord) }
			it { is_expected.to respond_to(:piece) }
		end
	end
end

describe ChessBoard do 
	subject { ChessBoard.new }
	describe '#initialize' do
		context 'upon creation' do
			it 'should have 64 squares' do
				expect(subject.squares.length).to eq(64)
			end

			it 'should have correctly-placed coordinates' do
				expect(subject.squares[0].coord).to eq([0, 0])
				expect(subject.squares[63].coord).to eq([7, 7])
			end
		end
	end
end