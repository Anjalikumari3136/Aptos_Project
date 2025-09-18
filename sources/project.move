module MyModule::TicTacToe {
    use aptos_framework::signer;
    use std::vector;
    
    /// Struct representing a tic-tac-toe game
    struct Game has store, key {
        board: vector<u8>,        // 9 positions: 0=empty, 1=player1, 2=player2
        player1: address,         // Address of player 1 (X)
        player2: address,         // Address of player 2 (O)
        current_turn: u8,         // 1 for player1, 2 for player2
        game_status: u8,          // 0=ongoing, 1=player1_wins, 2=player2_wins, 3=draw
    }
    
    /// Error codes
    const E_INVALID_POSITION: u64 = 1;
    const E_POSITION_OCCUPIED: u64 = 2;
    const E_NOT_YOUR_TURN: u64 = 3;
    const E_GAME_ENDED: u64 = 4;
    
    /// Function to create a new tic-tac-toe game
    public fun create_game(player1: &signer, player2_addr: address) {
        let board = vector::empty<u8>();
        let i = 0;
        while (i < 9) {
            vector::push_back(&mut board, 0);
            i = i + 1;
        };
        
        let game = Game {
            board,
            player1: signer::address_of(player1),
            player2: player2_addr,
            current_turn: 1,
            game_status: 0,
        };
        move_to(player1, game);
    }
    
    /// Function to make a move on the board
    public fun make_move(player: &signer, game_owner: address, position: u8) acquires Game {
        let player_addr = signer::address_of(player);
        let game = borrow_global_mut<Game>(game_owner);
        
        // Validate move
        assert!(position < 9, E_INVALID_POSITION);
        assert!(game.game_status == 0, E_GAME_ENDED);
        assert!(*vector::borrow(&game.board, (position as u64)) == 0, E_POSITION_OCCUPIED);
        
        // Check turn
        let player_num = if (player_addr == game.player1) 1 else 2;
        assert!(player_num == game.current_turn, E_NOT_YOUR_TURN);
        
        // Make move
        *vector::borrow_mut(&mut game.board, (position as u64)) = player_num;
        
        // Check for win or draw and update game status
        game.game_status = check_game_end(&game.board);
        
        // Switch turn
        game.current_turn = if (game.current_turn == 1) 2 else 1;
    }
    
    /// Helper function to check if game has ended
    fun check_game_end(board: &vector<u8>): u8 {
        // Check rows, columns, and diagonals for wins
        let win_patterns = vector[
            vector[0,1,2], vector[3,4,5], vector[6,7,8], // rows
            vector[0,3,6], vector[1,4,7], vector[2,5,8], // columns  
            vector[0,4,8], vector[2,4,6]                 // diagonals
        ];
        
        let i = 0;
        while (i < vector::length(&win_patterns)) {
            let pattern = vector::borrow(&win_patterns, i);
            let pos1 = *vector::borrow(board, *vector::borrow(pattern, 0));
            let pos2 = *vector::borrow(board, *vector::borrow(pattern, 1));
            let pos3 = *vector::borrow(board, *vector::borrow(pattern, 2));
            
            if (pos1 != 0 && pos1 == pos2 && pos2 == pos3) {
                return pos1
            };
            i = i + 1;
        };
        
        // Check for draw (all positions filled)
        let filled = 0;
        let j = 0;
        while (j < 9) {
            if (*vector::borrow(board, j) != 0) filled = filled + 1;
            j = j + 1;
        };
        if (filled == 9) 3 else 0
    }
}