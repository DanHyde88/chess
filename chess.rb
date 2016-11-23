require 'yaml'

class Game
    attr_accessor :game_set

    def initialize
        @turn_count = 0
        @game_set = Board.new
        @game_set.populate_board
        $game_end = false     
    end

    def menu
        puts "Press s to start game"
        puts "To quit game at any time enter quit"
        input = gets.chomp.downcase
        if input == "s"
            run_game
        end

        if input == "quit"
            puts "goodbye"
            $game_end = true
            return
        end
    end

    def open_menu
        puts"MENU"
        puts "press 1 to save the game"
        puts "press 2 to load a game"
        puts "press 3 to start a new game"
        puts "press 4 to quit game"
        puts "press 5 to return to current game"
        menu_option = gets.chomp
        case menu_option
        when "1"
            save_game
        when "2"
            load_game
        when "3"
            run_game
        when "4"
        when "5"
        else
            puts "not recognised, please enter 1 - 5"
            open_menu
        end
    end

    def run_game
        while $game_end == false do
            run_round
        end
    end

    def save_game
        game_data = [@turn_count, @game_set, $game_end].to_yaml
        puts game_data.to_yaml
        puts "enter game save name:"
        file_name = gets.chomp
        file_directory = "c:/Users/Dan/ruby/chess/saved_games/" + file_name + ".txt"
        f = File.open(file_directory, "w")
        f.write game_data
        f.close
    end

    def load_game
        file_name = ""
        puts "enter name of game to load or press c to cancel:"
        file_name = gets.chomp
        load_data = ""
        file_directory = "c:/Users/Dan/ruby/chess/saved_games/" + file_name + ".txt"
        if file_name != "c"
                if !File.exist?(file_directory)
                    puts "File does not exist, please try again or press c to cancel"
                    load_game
                else
                    f = File.open(file_directory, "r").each { |line| load_data << line}
                    info = YAML.load(load_data)
                    puts "loading"
                    reset_turn_count(info[0])
                    puts info[0]
                    reset_game_set(info[1])
                    puts info[1].inspect
                    reset_game_end(info[2])
                    puts info[2].inspect
                    run_game
                end
        else
            puts "You cancelled the load"
        end
    end

    def reset_turn_count(input)
        @turn_count = input
    end

    def reset_game_end(input)
        $game_end = input
    end

    def reset_game_set(input)
        @game_set = input
    end

    def run_round
        @game_set.show_board(@game_set.board)
        if @turn_count % 2 == 0
            current_color = :white
            opposition_color = :black
            castling_position = 7
            en_passant_modifier = 1
            puts "White turn"
        else
            current_color = :black
            opposition_color = :white
            castling_position = 0
            en_passant_modifier = -1
            puts "Black turn"
        end

        if @game_set.check_for_checkmate(current_color, @game_set.board)
            if @game_set.check_for_check(current_color, @game_set.board)
                puts "Checkmate. #{opposition_color} won."
            else
                puts "Draw"
            end
            open_menu
        else
            puts "Check" if @game_set.check_for_check(current_color, @game_set.board)
            user_moves = solicit_move
            position_1 = [user_moves[0], user_moves[1]]
            position_2 = [user_moves[2], user_moves[3]]
            if @game_set.check_for_legal_move(position_1,position_2, current_color) #sufficient check for most pieces except king
                if position_1 == [castling_position, 4] && position_2 == [castling_position, 6]
                    @game_set.move(position_1,position_2, @game_set.board)
                    @game_set.move([castling_position, 7],[castling_position, 5], @game_set.board)
                    @turn_count += 1
                    @game_set.board[position_2[0]][position_2[1]].moves_made += 1
                elsif position_1 == [castling_position, 4] && position_2 == [castling_position, 2]
                    @game_set.move(position_1,position_2, @game_set.board)
                    @game_set.move([castling_position, 0],[castling_position, 3], @game_set.board)
                    @turn_count += 1
                    @game_set.board[position_2[0]][position_2[1]].moves_made += 1
                elsif position_2 == $en_passant_pos
                    puts "here"
                    puts $en_passant_pos[0] + en_passant_modifier
                    puts @game_set.board[$en_passant_pos[0] + en_passant_modifier][$en_passant_pos[1]]
                    @game_set.move(position_1,position_2, @game_set.board)
                    @game_set.board[$en_passant_pos[0] + 1][$en_passant_pos[1]] = nil
                    @turn_count += 1
                    @game_set.board[position_2[0]][position_2[1]].moves_made += 1
                else
                    @game_set.move(position_1,position_2, @game_set.board)
                    @turn_count += 1
                    @game_set.board[position_2[0]][position_2[1]].moves_made += 1
                end
                @game_set.check_for_pawn_upgrade(position_2, current_color)
                @game_set.check_for_en_passant(position_1, position_2, current_color)
                puts $en_passant_pos.inspect
            else
                puts "Sorry, that move is not allowed."
                run_round
            end
        end
    end

    def solicit_move
        puts "Enter the first coordinates [y,x] and destination coordinates [y,x] separated by a whitespace, where top left corner is [0,0] or enter menu to go to menu"
        digit_array = []
        input = gets.chomp
        open_menu if input == "menu"
        input.scan(/\d/) { |digit| digit_array << digit}

        user_moves = []
        user_moves[0] = digit_array[0].to_i
        user_moves[1] = digit_array[1].to_i
        user_moves[2] = digit_array[2].to_i
        user_moves[3] = digit_array[3].to_i
        return user_moves
    end
end

class Board
    attr_accessor :board

    def initialize
        $en_passant_pos = nil
        @board = create_board
    end

# creates an 8x8 board, an array 8 elements long with an 8 element array in each, with nil values.
    def create_board
        board = Array.new(8)
        board.map! { |element| element = Array.new(8)}
        board
    end

    def populate_board
        pawn_position = [0,1,2,3,4,5,6,7]
        knight_position = [1,6]
        queen_position = [3]
        bishop_position = [2,5]
        rook_position = [0,7]
        king_position = [4]

        pawn_position.each do |x_position|
            @board[6][x_position] = Pawn.new(:white)
            @board[1][x_position] = Pawn.new(:black)
        end

        knight_position.each do |x_position|
            @board[7][x_position] = Knight.new(:white)
            @board[0][x_position] = Knight.new(:black)
        end

        queen_position.each do |x_position|
            @board[7][x_position] = Queen.new(:white)
            @board[0][x_position] = Queen.new(:black)
        end

        bishop_position.each do |x_position|
            @board[7][x_position] = Bishop.new(:white)
            @board[0][x_position] = Bishop.new(:black)
        end

        rook_position.each do |x_position|
            @board[7][x_position] = Rook.new(:white)
            @board[0][x_position] = Rook.new(:black)
        end

        king_position.each do |x_position|
            @board[7][x_position] = King.new(:white)
            @board[0][x_position] = King.new(:black)
        end
    end

    #turn this into checking if move is legal
    def check_for_legal_move(position_1, position_2, color)
        color == :white ? castling_position = 7 : castling_position = 0
        if @board[position_1[0]][position_1[1]] == nil || @board[position_1[0]][position_1[1]].color != color # i think this line can be reduced
            return false
        else
            if (@board[position_1[0]][position_1[1]].allowable_moves(position_1[0], position_1[1], @board).include?(position_2) && check_for_king_legal_move(position_1, position_2, color)) || ( check_for_castling_right(color) && position_2 == [castling_position, 6] ) || ( check_for_castling_right(color) && position_2 == [castling_position, 2] )
                return true
            else
                return false
            end
        end
    end

    def check_for_king_legal_move(position_1, position_2, color)
        temp_board = Marshal.load(Marshal.dump(@board))
        move(position_1,position_2, temp_board)
        if check_for_check(color, temp_board)
            return false
        else
            return true
        end
    end

    def check_for_castling_right(color)
        castling_array = []
        color == :white ? first_row = 7 : first_row = 0
        begin
            if @board[first_row][4].moves_made == 0 && @board[first_row][7].moves_made == 0 && @board[first_row][5] == nil && @board[first_row][6] == nil
                (4..6).each do |y_position|
                    temp_board = Marshal.load(Marshal.dump(@board))
                    move([first_row, 4], [first_row, y_position], temp_board)
                    if check_for_check(color, temp_board)
                        castling_array << true
                    else
                        castling_array << false
                    end
                end
                if castling_array.any? { |check_pos| check_pos == true}
                else
                    return true
                end
            else
                return false
            end
        rescue
            return false
        end
    end

    def check_for_castling_left(color)
        castling_array = []
        color == :white ? first_row = 7 : first_row = 0
        begin
            if @board[first_row][4].moves_made == 0 && @board[first_row][0].moves_made == 0 && @board[first_row][1] == nil && @board[first_row][2] == nil && @board[first_row][3] == nil
                (2..4).each do |y_position|
                    temp_board = Marshal.load(Marshal.dump(@board))
                    move([first_row, 4], [first_row, y_position], temp_board)
                    if check_for_check(color, temp_board)
                        castling_array << true
                    else
                        castling_array << false
                    end
                end
                if castling_array.any? { |check_pos| check_pos == true}
                else
                    return true
                end
            else
                return false
            end
        rescue
            return false
        end
    end

    #this method just does the mechanics of moving
    def move(position_1, position_2, board)
        piece_to_move = board[position_1[0]][position_1[1]]
        board[position_2[0]][position_2[1]] = piece_to_move
        board[position_1[0]][position_1[1]] = nil
    end

    def show_board(board)
        puts "    0    1    2    3    4    5    6    7"
        board.each_with_index do |x, y|
            print y
            print "  "
            x.each do |y|
                if y == nil
                    print "---"
                    print "  "
                else
                    print y.get_token
                    print "  "
                end
            end
            puts
            puts
        end
    end

    def check_for_check(color, board)
        king_position = []
        attacking_moves = []
        board.each_with_index do |row,x|
            row.each_with_index do |element,y|
                king_position = [x, y] if element.class == King && element.color == color
                #begin
                    if element != nil && element.color != color
                        element.allowable_moves(x,y,board).each { |attacking_move| attacking_moves << attacking_move}
                    end
                #rescue
                #end
            end
        end
        if attacking_moves.any? { |position| position == king_position}
            return true
        else
            return false
        end
    end

    def check_for_checkmate(color, board)
        #begin
        all_moves = []
        check_array = []
        board.each_with_index do |row,x|
            row.each_with_index do |element,y|
                if element == nil
                elsif element.color == color
                    element.allowable_moves(x,y,board).each do |allowable_move| 
                        temp_board = Marshal.load(Marshal.dump(board))
                        move([x, y], allowable_move, temp_board)
                        check_array << check_for_check(color, temp_board)
                    end
                end
            end
        end
        if check_array.include?(false)
            return false
        else
            return true
        end
        #rescue
        #end
    end

    def check_for_en_passant(position_1,position_2, color)
        color == :white ? first_row = 6 : first_row = 1
        color == :white ? en_passant_row = 4 : en_passant_row = 3
        color == :white ? en_passant_take = 5 : en_passant_take = 2
        if @board[position_2[0]][position_2[1]].class == Pawn && position_1[0] == first_row && position_2[0] == en_passant_row
            $en_passant_pos = [en_passant_take, position_2[1]]
        else
            $en_passant_pos = nil
        end
    end


    def check_for_pawn_upgrade(position_2, color)
        color == :white ? end_row = 0 : end_row = 7
        if position_2[0] == end_row && @board[position_2[0]][position_2[1]].class == Pawn
            pick_upgrade_piece(position_2, color)
        end
    end

    def pick_upgrade_piece(position_2, color)
        puts "You have updgraded a pawn. What do you want it to be: que, roo, bis, kni ?"
        upgrade_piece = gets.chomp
        case upgrade_piece
        when "que"
            @board[position_2[0]][position_2[1]] = Queen.new(color)
        when "roo"
            @board[position_2[0]][position_2[1]] = Rook.new(color)
        when "bis"
            @board[position_2[0]][position_2[1]] = Bishop.new(color)
        when "kni"
            @board[position_2[0]][position_2[1]] = Knight.new(color)
        else
            puts "Not recognised, please enter again"
            pick_upgrade_piece
        end
    end
end

class Piece
    attr_accessor :color, :moves_made

    def initialize(color)
        @color = color
        self.color == :white ? @opposite_color = :black : @opposite_color = :white
        @moves_made = 0
    end

    def allowable_moves_in_line(array, board, moves)
        begin #added to handle exception
            array.each_with_index do |position, final_index|
	            piece_array = []
	            array[0..final_index].each_with_index do |b,c|
                    piece_array << board[array[c][0]][array[c][1]]
	            end
	            if piece_array[0...-1].all? { |element| element == nil} && (piece_array[-1] == nil || piece_array[-1].color == @opposite_color)
                    moves << position
                end
            end
        rescue
            #puts "error in allowable_moves_in_line." #I think this error occurs because there are no positions in the array and so it is NilClass rather than an array
        end 
    end

end
#Piece sub classes
class Pawn < Piece
    def get_token
        #color == :white ? token = "\u{2659}" : token = "\u{265f}"
        #image = token.encode('utf-8')
        color == :white ? token = "PAW" : token = "paw"
    end

    def allowable_moves(x, y, board, for_king = nil)
        self.color == :white ? en_passant_row = 3 : en_passant_row = 4
        self.color == :white ? modifier = -1 : modifier = 1
        #self.color == :white ? opposite_color = :black : opposite_color = :white
        self.color == :white ? starting_row = 6 : starting_row = 1
        moves = []
        #basic move. the king symbol is when checking if the king can move because the king would bloke the pawn.
        moves << [x + modifier, y] if board[x + modifier][y] == nil && x < 7
        #take opponents piece move
        moves << [x + modifier, y - 1] if board[x + modifier][y - 1] != nil && board[x + modifier][y - 1].color == @opposite_color && x < 7 && y >= 1
        moves << [x + modifier, y + 1] if board[x + modifier][y + 1] != nil && board[x + modifier][y + 1].color == @opposite_color && x < 7 && y <= 6
        #starting position double move
        begin
            moves << [x + modifier * 2, y] if board[x + modifier][y] == nil && board[x + modifier * 2][y] == nil && x = starting_row
        rescue
            #puts "error with big moves and nil ?? dont fully understand"
        end
            #en passant take opponent piece move
        moves << $en_passant_pos if x == en_passant_row && (y == $en_passant_pos[1] +1 || y == $en_passant_pos[1] -1)
        return moves
    end 
end

class Knight < Piece
    def get_token
        #color == :white ? token = "\u{2658}" : token = "\u{265e}"
        #image = token.encode('utf-8')
        color == :white ? token = "KNI" : token = "kni"
    end

    def allowable_moves(x, y, board, for_king = nil)
        moves = []
        array = [[x+2,y+1],[x+2,y-1],[x+1,y-2],[x-1,y-2],[x-2,y-1],[x-2,y+1],[x-1,y+2],[x+1,y+2]]
        array.delete_if { |pos| pos[0] > 7 || pos[1] > 7 || pos[0] < 0 || pos[1] < 0 }
        array.each do |position|
            if position[0] > 7 || position[1] > 7
                next
            end
            if board[position[0]][position[1]] == nil || board[position[0]][position[1]].color == @opposite_color
                moves << position
            end
        end
        return moves
    end
end

class Queen < Piece
    def get_token
        #color == :white ? token = "\u{2655}" : token = "\u{265b}"
        #image = token.encode('utf-8')
        color == :white ? token = "QUE" : token = "que"
    end

    def allowable_moves(x, y, board, for_king = nil)
        moves = []
        array = []
        up(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        down(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_up_right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_up_left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_down_right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_down_left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        #puts moves.inspect
        return moves
    end

    def up(x, y, array)
        a = x
        b = y
        (a-1).downto(0) do |element| 
            array << [element, b]
        end
        return array
    end

    def down(x, y, array)
        a = x
        b = y
        ((a+1)..7).each do |element|
            array << [element, b]
        end
        return array
    end

    def left(x, y, array)
        a = x
        b = y
        (b-1).downto(0) do |element| 
            array << [a, element]
        end
        return array
    end

    def right(x, y, array)
        a = x
        b = y
        ((b+1)..7).each do |element|
            array << [a, element]
        end
        return array
    end

    def diagonal_up_right(x, y, array) # x- y+
        a = x
        b = y
        while a >= 1 && b <= 6 do
	        a -=1
	        b +=1
	        array << [a, b]
        end
    end

    def diagonal_up_left(x, y, array) # x- y-
        a = x
        b = y
        while a >= 1 && b >= 1 do
	        a -=1
	        b -=1
	        array << [a, b]
        end
    end

    def diagonal_down_right(x, y, array) # x+ y+
        a = x
        b = y
        while a <= 6 && b <= 6 do
	        a +=1
	        b +=1
	        array << [a, b]
        end
    end

    def diagonal_down_left(x, y, array) # x+ y
        a = x
        b = y
        while a <= 6 && b >= 1 do
	        a +=1
	        b -=1
	        array << [a, b]
        end
    end
end

class Bishop < Piece
    def get_token
        #color == :white ? token = "\u{2657}" : token = "\u{265d}"
        #image = token.encode('utf-8')
        color == :white ? token = "BIS" : token = "bis"
    end

    def allowable_moves(x, y, board, for_king = nil)
        moves = []
        array = []
        diagonal_up_right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_up_left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_down_right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        diagonal_down_left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        #puts moves.inspect
        return moves
    end

    def diagonal_up_right(x, y, array) # x- y+
        a = x
        b = y
        while a >= 1 && b <= 6 do
	        a -=1
	        b +=1
	        array << [a, b]
        end
    end

    def diagonal_up_left(x, y, array) # x- y-
        a = x
        b = y
        while a >= 1 && b >= 1 do
	        a -=1
	        b -=1
	        array << [a, b]
        end
    end

    def diagonal_down_right(x, y, array) # x+ y+
        a = x
        b = y
        while a <= 6 && b <= 6 do
	        a +=1
	        b +=1
	        array << [a, b]
        end
    end

    def diagonal_down_left(x, y, array) # x+ y
        a = x
        b = y
        while a <= 6 && b >= 1 do
	        a +=1
	        b -=1
	        array << [a, b]
        end
    end
end

class Rook < Piece
    def get_token
        #color == :white ? token = "\u{2656}" : token = "\u{265c}"
        #image = token.encode('utf-8')
        color == :white ? token = "ROO" : token = "roo"
    end

    def allowable_moves(x, y, board, for_king = nil)
        moves = []
        array = []
        up(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        down(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        left(x, y, array)
        allowable_moves_in_line(array, board, moves)
        array = []
        right(x, y, array)
        allowable_moves_in_line(array, board, moves)
        #puts moves.inspect
        return moves
    end

    def up(x, y, array)
        a = x
        b = y
        (a-1).downto(0) do |element| 
            array << [element, b]
        end
        return array
    end

    def down(x, y, array)
        a = x
        b = y
        ((a+1)..7).each do |element|
            array << [element, b]
        end
        return array
    end

    def left(x, y, array)
        a = x
        b = y
        (b-1).downto(0) do |element| 
            array << [a, element]
        end
        return array
    end

    def right(x, y, array)
        a = x
        b = y
        ((b+1)..7).each do |element|
            array << [a, element]
        end
        return array
    end
end

class King < Piece
    def get_token
        #color == :white ? token = "\u{2654}" : token = "\u{265a}"
        #image = token.encode('utf-8')
        color == :white ? token = "KIN" : token = "kin"
    end

    def allowable_moves(x, y, board, for_king = nil)
        moves = []
        array = [[x+1, y+1],[x+1, y],[x+1, y-1],[x, y-1],[x-1, y-1],[x-1, y+1],[x, y+1],[x-1, y]] #need to add that these need to be checked so they are only positive. This must apply to knights as well!!!!!    
        array.delete_if { |pos| pos[0] > 7 || pos[1] > 7 || pos[0] < 0 || pos[1] < 0 }
        array.each do |position|
            allowable_moves_in_line([position], board, moves)
        end
        return moves
    end

    def castling(x, y, board, moves)
        # castling section - start
        self.color == :white ? first_row = 0 : first_row = 7
        puts first_row
        if @moves_made == 0 && board[first_row][7].moves_made == 0 && board[first_row][5] == nil && board[first_row][6] == nil
            check_array = []
            (4..6).each do |y_position|
                temp_board = Marshal.load(Marshal.dump(board))
                temp_board[first_row][y_position] = self #here i can use the mechanical move methosd to tide things up
                temp_board[first_row][4] = nil
            end
        end
        moves << [x, y+2]
        return moves
    end
end

a = Game.new.open_menu

