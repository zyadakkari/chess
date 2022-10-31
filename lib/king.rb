# require_relative './board.rb'


class King < Board

  attr_reader :team, :symbol, :type, :pinned
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @pinned = false
    @moves = []
    @moved = false
    @team == "White" ? @position = [7,4] : @position = [0,4]
  end

  def board()
    @@board
  end

  def pieces()
    @@pieces
  end



  def piece_movement()
    return [[1,0], [1,1], [1,-1], [-1,0], [-1,1], [-1,-1], [0,1], [0,-1]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
    for move in moves
      if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
        options << [position[0]+move[0], position[1]+move[1]]
      end
    end
    options
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = piece_movement()
    attackableSquares = possible_landing_squares(moves)
    for square in attackableSquares
      if opponent?(square)
        targets << square
      end
    end
    targets
  end

  def illegal_moves(moves, opponentMoves=[])
    pieces
    for char in pieces
      if char.team != @team && char.status == "Active"
        char.moves.each { |move| opponentMoves << move }
      end
    end
    illegalMoves = opponentMoves & @moves
  end

  def king_side_castle(position=@position)
    board()
    pieces()
    castleSquares = [position, [position[0],position[1]+1], [position[0],position[1]+2]]
    # if king moved return
    if @moved
      return
    end
    # if rook moved return
    if @@board[position[0]][position[1]+3] == "X" || @@board[position[0]][position[1]+3].moved
      return
    end
    # check every enemy piece attackable positions to see if include king and two squares to the king left or right
    for piece in @@pieces
      if piece.team != @team
        shared = piece.moves & castleSquares
        if !shared.empty?
          return
        end
      end
    end
    # check if squares between king and rook all empty
    for square in castleSquares[1..]
      if @@board[square[0]][square[1]] != "X"
        return
      end
    end
    @moves << [position[0],position[1]+2]
    # if all the above passes, king can castle

  end
  def queen_side_castle(position=@position)
    board()
    pieces()
    castleSquares = [position, [position[0],position[1]-1], [position[0],position[1]-2], [position[0], position[1]-3]]
    # if king moved return
    if @moved
      return
    end
    # if rook moved return
    if @@board[position[0]][position[1]-4] == "X" || @@board[position[0]][position[1]-4].moved
      return
    end
    # check every enemy piece attackable positions to see if include king and two squares to the king left or right
    for piece in @@pieces
      if piece.team != @team
        shared = piece.moves & castleSquares[0..2]
        if !shared.empty?
          return
        end
      end
    end
    # check if squares between king and rook all empty
    for square in castleSquares[1..]
      if @@board[square[0]][square[1]] != "X"
        return
      end
    end
    @moves << [position[0],position[1]-2]
    # if all the above passes, king can castle

  end

  def move_finder(position=@position)
    @moves = []
    board
    moves = piece_movement()
    possibleDestinations = possible_landing_squares(moves)
    for destination in possibleDestinations
      obstructed = false
      if board[destination[0]][destination[1]] != "X"
          obstructed = true
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
    illegalMoves = illegal_moves(@moves)
    @moves = @moves - illegalMoves
    king_side_castle()
    queen_side_castle()
    @moves
  end

end
