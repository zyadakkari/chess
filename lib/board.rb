# require_relative './king.rb'
require 'pry-byebug'

module Movable
  def self.possible_landing_squares(piecetype, piece, options=[])
    position = piece.position
    moves = piecetype::PIECE_MOVEMENT
    if piece.type == "Pawn" && piece.moved == false
      moves << [moves[0][0]*2, moves[0][1]]
    end
    if piecetype == Queen || piecetype == Rook || piecetype == Bishop
        for move in moves
          for i in (1..7)
            tempvar = []
            tempvar[0] = move[0] * i
            tempvar[1] = move[1] * i
            if (position[0]+tempvar[0]).between?(0,7) && (position[1]+tempvar[1]).between?(0,7)
              options << [position[0]+tempvar[0], position[1]+tempvar[1]]
            end
          end
        end
    else
        for move in moves
          if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
            options << [position[0]+move[0], position[1]+move[1]]
          end
        end

    end
    options
  end

  def self.opponent?(piece, board)
    opposingPiece = board[piece.position[0]][piece.position[1]]
    if opposingPiece != "X" && opposingPiece.team != piece.team
      return true
    end
  end

  # method only used by king to stop it moving into check
  def self.illegal_moves(piece, otherpieces, opponentMoves=[])
    for char in otherpieces
      if char.team != piece.team && char.status == "Active"
        char.moves.each { |move| opponentMoves << move }
      end
    end
    illegalMoves = opponentMoves & piece.moves
  end

  def self.route_finder(piece, destination, path=[])
    curSq = piece.position
    move = []
    if destination[0]-curSq[0] > 0
      move[0] = 1
    elsif destination[0]-curSq[0] < 0
      move[0] = -1
    else
      move[0] = 0
    end
    if destination[1]-curSq[1] > 0
      move[1] = 1
    elsif destination[1]-curSq[1] < 0
      move[1] = -1
    else
      move[1] = 0
    end
    until path.include?(destination)
      path << curSq = [curSq[0]+move[0], curSq[1]+move[1]]
    end
    return path
  end

  def self.attackable_squares(moves, piece, options=[])
    for move in moves
      if (piece.position[0]+move[0]).between?(0,7) && (piece.position[1]+move[1]).between?(0,7)
        options << [piece.position[0]+move[0], piece.position[1]+move[1]]
      end
    end
    options
  end

end

class Game
  include Movable

  attr_reader :teams, :players

  def initialize()
    @teams = ["White", "Black"]
    @players = []
    @moveCounter = 0
    @winner = false
    @checkmate = false
    puts "Welcome to Chess!"
    choose_game_mode
    @gameMode == 1 ? pass_to_play_mode(@teams) : return
  end

  def choose_game_mode()
    puts "Would you like to play against a friend or a computer? Type 1 for friend and 0 for computer: "
    @gameMode = gets.chomp.to_i
  end

  def pass_to_play_mode(teams)
    puts "Great choice! Please enter a name for player 1: "
    playerOneName = gets.chomp
    puts "Welcome #{playerOneName}! Please enter a name for player 2: "
    playerTwoName = gets.chomp
    playerOneTeam = @teams.sample
    playerOneTeam == "White" ? playerTwoTeam = "Black" : playerTwoTeam = "White"
    puts "Great, thanks #{playerTwoName}. #{playerOneName} will be #{playerOneTeam} & #{playerTwoName} will be #{playerTwoTeam}"
    @players << player1 = {:name => playerOneName, :team => playerOneTeam}
    @players << player2 = {:name => playerTwoName, :team => playerTwoTeam}
  end

  def turn_picker(players)
    if players[0][:team] == "White"
      @moveCounter % 2 == 0 ? players[0] : players[1]
    else
      @moveCounter % 2 == 0 ? players[1] : players[0]
    end
  end

  def piece_selector()
    board = @play.board
    puts "#{@turn[:name]} pick a piece to move: "
    input = gets.chomp
    input = input.split(',')
    @piece = [input[0].to_i,input[1].to_i]
    while @play.board[@piece[0]][@piece[1]] == "X" || @play.board[@piece[0]][@piece[1]].team != @turn[:team]
      puts "Please choose a valid piece"
      input = gets.chomp
      input = input.split(',')
      @piece = [input[0].to_i,input[1].to_i]
    end
    @piece

  end

  def move_selector()
    pieceMoves = @play.get_piece_moves(@piece)
    puts "#{@turn[:name]} pick a square to move to: "
    input = gets.chomp
    input = input.split(',')
    move = [input[0].to_i,input[1].to_i]
    while !pieceMoves.include?(move)
      puts "Please choose a valid move combination"
      input = gets.chomp
      input = input.split(',')
      move = [input[0].to_i,input[1].to_i]
      pieceMoves = @play.get_piece_moves(@piece)
    end
    move
  end

  def checkmate()
    if @checkmate == true
      @winner = true
    end
  end

  def play_game()
    @play = Board.new()
    board = @play.board
    @play.show_board
    while @winner == false
      @turn = turn_picker(@players)
      checkers = @play.check?(@turn[:team])
      if !checkers.empty?
    # check the case of multiple checkers
        escapes = @play.escape_check(checkers, @turn[:team])
        if escapes.empty?
          @checkmate = true
        end
        escaped = false
        moveEscapes = escapes[0]
        blockEscapes = escapes[1][0]
        takeEscape = escapes[2]
        while escaped == false
          @piece = piece_selector()
          move = move_selector()
          if board[@piece[0]][@piece[1]].type == "King" && moveEscapes.include?(move)
            escaped = true
          elsif board[@piece[0]][@piece[1]].type != "King" && blockEscapes.include?(move)
            escaped = true
          elsif checkers.length == 1 && takeEscape == move
            escaped = true
          end
        end
      else
        @piece = piece_selector()
        move = move_selector()
      end
      @play.move_piece(@piece, move)
      @play.show_board
      @moveCounter += 1
    end
  end
end

class Board < Game

  include Movable

  attr_accessor :board, :blackKing, :blackQueen, :blackRook1, :blackRook2,
  :blackKnight1, :blackKnight2, :blackBishop1, :blackBishop2, :blackPawn1,
  :blackPawn2, :blackPawn3, :blackPawn4, :blackPawn5, :blackPawn6, :blackPawn7,
  :blackPawn8, :whiteKing, :whiteQueen, :whiteRook1, :whiteRook2, :whiteKnight1,
  :whiteKnight2, :whiteBishop1, :whiteBishop2, :whitePawn1, :whitePawn2,
  :whitePawn3, :whitePawn4, :whitePawn5, :whitePawn6, :whitePawn7, :whitePawn8, :pieces, :board

  def initialize()
    create_board
    king_maker
    queen_maker
    rook_maker
    bishop_maker
    knight_maker
    pawn_maker
    recalculate_all_moves
  end
  def create_board()
    @@board = Array.new(8) { Array.new(8, "X") }
    @@pieces = []
  end

  def edit_board(square, input)
    @@board[square[0]][square[1]] = input
  end

  def show_board(board=@@board)
    i = 0
    for row in board
      printRow = row.map  { |elem| elem != "X" ? elem = elem.symbol : elem }
      puts "#{i} #{printRow}"
      i += 1
    end
    puts "\n"
  end

  def board()
    @@board
  end

  def get_piece_moves(square)
    piece = @@board[square[0]][square[1]]
    return piece.moves
  end

  def move_piece(piecesquare, move, board=@@board)
    piece = board[piecesquare[0]][piecesquare[1]]
    if castle_check(piece, move)
      castle(piece, move)
    elsif board[move[0]][move[1]] == "X"
        edit_board(piece.position, "X")
        edit_board(move, piece)
        piece.position = move
        piece.moved = true
    else
        attack(piece, move)
    end
    #to ensure new moves are calculating based on the new position
    piece.move_finder
    recalculate_all_moves()
    for char in @@pieces
      if char.status == "Active" && char.type != "King"
        pinned(char)
      end
    end
  end

  def attack(piece, move)
    @@board[move[0]][move[1]].status = "Inactive"
    @@board[move[0]][move[1]].position = []
    edit_board(piece.position, "X")
    edit_board(move, piece)
    piece.position = move
    piece.moved = true
  end

  def castle_check(piece, move)
    if piece.type == "King" && (move[1]+piece.position[1] == 6 || move[1]+piece.position[1] == 10)
      return true
    end
  end

  def castle(piece, move)
    edit_board(piece.position, "X")
    edit_board(move, piece)
    if move[1] == 6
      rook = @@board[piece.position[0]][7]
      edit_board(rook.position, "X")
      edit_board([move[0],move[1]-1], rook)
    else
      rook = @@board[piece.position[0]][0]
      edit_board(rook.position, "X")
      edit_board([move[0],move[1]+1], rook)
    end
  end


  def check?(team, checkers=[])
    team == "White" ? piece = @whiteKing : piece = @blackKing
    position = piece.position
    for char in @@pieces
      if char.team != team && char.moves.include?(position) && char.status == "Active"
        checkers << char
      end
    end
    checkers
  end

  def escape_check(checkers, team)
    escapes = []
    team == "White" ? king = @whiteKing : king = @blackKing
    # this will run into bug with not having the pawn attack covered but all others okay
    escapes << move_check_escape(king, team)
    escapes << block_check_escape(team, checkers, king)
    escapes << take_check_escape(checkers)
    escapes
  end

  def take_check_escape(checkers)
    if checkers.length == 1
      checkers[0].position
    end
  end

  def block_check_escape(team, checkers, escapes=[], king)
    for checker in checkers
      if checker.type == "Bishop" || checker.type == "Queen" || checker.type == "Rook"
        route = Movable.route_finder(checker, king.position)
        route = route - [king.position]
        escapes << route
      end
    end
    escapes
  end

  def move_check_escape(king, team, opponentMoves=[], escapes=[])
    for char in @@pieces
      if char.team != team && char.status == "Active"
        char.moves.each { |move| opponentMoves << move }
      end
    end
    for move in king.moves
      if !opponentMoves.include?(move)
        escapes << move
      end
    end
    escapes.flatten
  end


  def recalculate_all_moves()
    for char in @@pieces
      if char.status == "Active"
        char.move_finder()
      end
    end
  end

  def pinned(chesspiece, pinners=[], move=[])
    pinned = false
    #possible pinners
    for char in @@pieces
      if char.team != @team && char.status == "Active"
        if char.type == "Queen" || char.type == "Bishop" || char.type == "Rook"
          pinners << char
        end
      end
    end
    # actual pinners & their move direction
    for piece in pinners
      if piece.moves.include?(chesspiece.position)
        if piece.position[0] - chesspiece.position[0] < 0
          move[0] = 1
      elsif piece.position[0] - chesspiece.position[0] > 0
          move[0] = -1
        else
          move[0] = 0
        end
        if piece.position[1] - chesspiece.position[1] < 0
          move[1] = 1
      elsif piece.position[1] - chesspiece.position[1] > 0
          move[1] = -1
      else
          move[1] = 0
      end
        positionToCheck = chesspiece.position.clone
        positionToCheck[0] = positionToCheck[0]+move[0]
        positionToCheck[1] = positionToCheck[1]+move[1]
        until board[positionToCheck[0]][positionToCheck[1]] != "X" || !positionToCheck[0].between?(0,7) || !positionToCheck[1].between?(0,7)
          positionToCheck[0] = positionToCheck[0]+move[0]
          positionToCheck[1] = positionToCheck[1]+move[1]
        end
        positionToCheck
        if !positionToCheck[0].between?(0,7) || !positionToCheck[1].between?(0,7)
          next
      elsif @@board[positionToCheck[0]][positionToCheck[1]].type == "King"
# binding.pry
            @pinned = true
            # check legal forward moves
            move[0] = move[0]*-1
            move[1] = move[1]*-1
            positionToCheck = chesspiece.position.clone
            openSquares = []
            positionToCheck[0] = positionToCheck[0]+move[0]
            positionToCheck[1] = positionToCheck[1]+move[1]
            openSquares << positionToCheck.clone
            until @@board[positionToCheck[0]][positionToCheck[1]] != "X"
              openSquares << positionToCheck.clone
              positionToCheck[0] = positionToCheck[0]+move[0]
              positionToCheck[1] = positionToCheck[1]+move[1]
            end
            openSquares << positionToCheck
            # check legal backward moves
            positionToCheck = chesspiece.position.clone
            move[0] = move[0]*-1
            move[1] = move[1]*-1
            positionToCheck[0] = positionToCheck[0]+move[0]
            positionToCheck[1] = positionToCheck[1]+move[1]
            while board[positionToCheck[0]][positionToCheck[1]] == "X"
              openSquares << positionToCheck.clone
              positionToCheck[0] = positionToCheck[0]+move[0]
              positionToCheck[1] = positionToCheck[1]+move[1]
            end
            chesspiece.moves = []
            openSquares.each { |move| chesspiece.moves << move }
        end
      end
    end
  end

  def king_maker(kings=[])
    kings << @whiteKing = King.new("White", "\♔", "King")
    kings << @blackKing = King.new("Black", "\♚", "King")
    for king in kings
      edit_board(king.position, king)
      @@pieces << king
    end
  end

  def queen_maker(queens=[])
    queens << @whiteQueen = Queen.new("White", "\♕", "Queen")
    queens << @blackQueen = Queen.new("Black", "\♛", "Queen")
    for queen in queens
      edit_board(queen.position, queen)
      @@pieces << queen
    end
  end

  def rook_maker(rooks=[])
    rooks << @whiteRook1 = Rook.new("White", "\♖", [7,0], "Rook")
    rooks << @whiteRook2 = Rook.new("White", "\♖", [7,7], "Rook")
    rooks << @blackRook1 = Rook.new("Black", "\♜", [0,0], "Rook")
    rooks << @blackRook2 = Rook.new("Black", "\♜", [0,7], "Rook")
    for rook in rooks
      edit_board(rook.position, rook)
      @@pieces << rook
    end
  end

  def bishop_maker(bishops=[])
    bishops << @whiteBishop1 = Bishop.new("White", "\♗", [7,2], "Bishop")
    bishops << @whiteBishop2 = Bishop.new("White", "\♗", [7,5], "Bishop")
    bishops << @blackBishop1 = Bishop.new("Black", "\♝", [0,2], "Bishop")
    bishops << @blackBishop2 = Bishop.new("Black", "\♝", [0,5], "Bishop")
    for bishop in bishops
      edit_board(bishop.position, bishop)
      @@pieces << bishop
    end
  end

  def knight_maker(knights=[])
    knights << @whiteKnight1 = Knight.new("White", "\♘", [7,1], "Knight")
    knights << @whiteKnight2 = Knight.new("White", "\♘", [7,6], "Knight")
    knights << @blackKnight1 = Knight.new("Black", "\♞", [0,1], "Knight")
    knights << @blackKnight2 = Knight.new("Black", "\♞", [0,6], "Knight")
    for knight in knights
      edit_board(knight.position, knight)
      @@pieces << knight
    end
  end

  def pawn_maker(pawns=[])
    pawns << @whitePawn1 = WhitePawn.new("White", "\♙", [6,0], "Pawn")
    pawns << @whitePawn2 = WhitePawn.new("White", "\♙", [6,1], "Pawn")
    pawns << @whitePawn3 = WhitePawn.new("White", "\♙", [6,2], "Pawn")
    pawns << @whitePawn4 = WhitePawn.new("White", "\♙", [6,3], "Pawn")
    pawns << @whitePawn5 = WhitePawn.new("White", "\♙", [6,4], "Pawn")
    pawns << @whitePawn6 = WhitePawn.new("White", "\♙", [6,5], "Pawn")
    pawns << @whitePawn7 = WhitePawn.new("White", "\♙", [6,6], "Pawn")
    pawns << @whitePawn8 = WhitePawn.new("White", "\♙", [6,7], "Pawn")
    pawns << @blackPawn1 = BlackPawn.new("Black", "\♟", [1,0], "Pawn")
    pawns << @blackPawn2 = BlackPawn.new("Black", "\♟", [1,1], "Pawn")
    pawns << @blackPawn3 = BlackPawn.new("Black", "\♟", [1,2], "Pawn")
    pawns << @blackPawn4 = BlackPawn.new("Black", "\♟", [1,3], "Pawn")
    pawns << @blackPawn5 = BlackPawn.new("Black", "\♟", [1,4], "Pawn")
    pawns << @blackPawn6 = BlackPawn.new("Black", "\♟", [1,5], "Pawn")
    pawns << @blackPawn7 = BlackPawn.new("Black", "\♟", [1,6], "Pawn")
    pawns << @blackPawn8 = BlackPawn.new("Black", "\♟", [1,7], "Pawn")
    for pawn in pawns
      edit_board(pawn.position, pawn)
      @@pieces << pawn
    end
  end

end

class King < Board

  include Movable

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

  PIECE_MOVEMENT =  [[1,0], [1,1], [1,-1], [-1,0], [-1,1], [-1,-1], [0,1], [0,-1]]

  # def attack_move_finder(position=@position)
  #   targets = []
  #   board
  #   moves = PIECE_MOVEMENT
  #   attackableSquares = Movable.possible_landing_squares(self.class, self)
  #   for square in attackableSquares
  #     if Movable.opponent?(self, board)
  #       targets << square
  #     end
  #   end
  #   targets
  # end
  def attack_move_finder(position=@position)
    targets = []
    board
    movesList = PIECE_MOVEMENT
    for move in movesList
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
    elsif Movable.opponent?(self, board)
        targets << currentSquare
      else
        next
      end
    end
    targets
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
    pieces
    moves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
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
    illegalMoves = Movable.illegal_moves(self, pieces)
    @moves = @moves - illegalMoves
    king_side_castle()
    queen_side_castle()
    @moves
  end

end

class Queen < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moves = []
    @moved = false
    @pinned = false
    @value = 9
    @team == "White" ? @position = [7,3] : @position = [0,3]
  end

  def board()
    @@board
  end

  def pieces()
    @@pieces
  end

  PIECE_MOVEMENT = [[1,1], [1,-1], [-1,1], [-1,-1], [1,0], [-1,0], [0,1], [0,-1]]

  def attack_move_finder(position)
    targets = []
    board
    movesList = PIECE_MOVEMENT
    for move in movesList
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
    elsif Movable.opponent?(self, board)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
    for destination in possibleDestinations
      route = Movable.route_finder(self, destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(position=@position)
    @moves = @moves + targets
  end
end

class Rook < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moves = []
    @moved = false
    @value = 5
    @position = position
  end

  def board()
    @@board
  end

  PIECE_MOVEMENT = [[1,0], [-1,0], [0,1], [0,-1]]

  def attack_move_finder(position)
    targets = []
    board
    movesList = PIECE_MOVEMENT
    for move in movesList
        # binding.pry
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
    elsif Movable.opponent?(self, board)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
    for destination in possibleDestinations
      route = Movable.route_finder(self, destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(@position)
    @moves = @moves + targets
  end
end

class Bishop < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moved = false
    @moves = []
    @value = 3
    @position = position
  end

  def board()
    @@board
  end

  PIECE_MOVEMENT = [[1,1], [1,-1], [-1,1], [-1,-1]]

  def attack_move_finder(position)
    targets = []
    board
    movesList = PIECE_MOVEMENT
    for move in movesList
        # binding.pry
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
    elsif Movable.opponent?(self, board)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
    for destination in possibleDestinations
      route = Movable.route_finder(self, destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(@position)
    @moves = @moves + targets
  end
end

class Knight < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
      @team = team
      @type = type
      @symbol = symbol
      @status = "Active"
      @moved = false
      @moves = []
      @value = 3
      @position = position
  end

  def board()
    @@board
  end

  PIECE_MOVEMENT = [[2,1], [2,-1], [-2,1], [-2,-1], [1,2], [-1,2], [1,-2], [-1,-2]]

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = PIECE_MOVEMENT
    attackableSquares = Movable.possible_landing_squares(self.class, self)
    for square in attackableSquares
      if Movable.opponent?(self, board)
        targets << square
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    moves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
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
  end
end

class BlackPawn < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
      @team = team
      @type = type
      @symbol = symbol
      @status = "Active"
      @moves = []
      @moved = false
      @value = 1
      @position = position
  end

  def board()
    @@board
  end

  PIECE_MOVEMENT = [[1,0]]

  ATTACK_MOVEMENTS = [[1, 1], [1, -1]]

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = ATTACK_MOVEMENTS
    attackableSquares = Movable.attackable_squares(moves, self)
    for square in attackableSquares
      if Movable.opponent?(self, board)
        targets << square
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    # binding.pry
    board
    pieceMoves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
    for destination in possibleDestinations
      route = Movable.route_finder(self, destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
  end
end

class WhitePawn < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
      @team = team
      @type = type
      @symbol = symbol
      @status = "Active"
      @moves = []
      @moved = false
      @value = 1
      @position = position
  end

  def board()
    @@board
  end

  PIECE_MOVEMENT = [[-1,0]]

  ATTACK_MOVEMENTS = [[-1, 1], [-1,-1]]

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = ATTACK_MOVEMENTS
    attackableSquares = Movable.attackable_squares(moves, self)
    for square in attackableSquares
      if Movable.opponent?(self, board)
        targets << square
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    pieceMoves = PIECE_MOVEMENT
    possibleDestinations = Movable.possible_landing_squares(self.class, self)
    for destination in possibleDestinations
      route = Movable.route_finder(self, destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
  end
end




newgame = Game.new
p newgame.play_game
p newgame.possible_landing_squares(whiteKing)
