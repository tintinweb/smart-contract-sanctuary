/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract TicTacToe {
    
    enum Symbol { EMPTY, X, O }
    enum Status { WAITING_FOR_PLAYER, IN_PROGRESS, HOST_PLAYER_WON, OTHER_PLAYER_WON, DRAW }
    enum GameType { BOT, PLAYER }
    
    struct PlayerBoard {
        address host_player; // Player 1 X
        address other_player; // Player 2 O
        
        Symbol host_player_symbol;
        Symbol other_player_symbol;
        
        Status status;
        GameType game_type;
        
        // _,_,_
        // _,_,_
        // _,_,_
        Symbol[9] gameboard;
    }
    
    // mapping to store the player's board
    mapping(address => PlayerBoard) public gameboards;
    address[] public players;

    function start_game(bool isBot) public returns (bool) {
        
        gameboards[msg.sender] = PlayerBoard({
            host_player: msg.sender,
            other_player: address(0),
            host_player_symbol: Symbol.EMPTY,
            other_player_symbol: Symbol.EMPTY,
            status: Status.WAITING_FOR_PLAYER,
            game_type: GameType.PLAYER,
            gameboard: [Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY]
        });

        players.push(msg.sender);
        
        if (isBot) {
            PlayerBoard storage board = gameboards[msg.sender];
            board.game_type = GameType.BOT;
            board.status = Status.IN_PROGRESS; 
            
            //TODO Randomised
            if (generate_random_start() == 1) {
                board.other_player_symbol = Symbol.X;
                board.host_player_symbol = Symbol.O;
                
                int move = bot_move(board.gameboard, board.other_player_symbol, board.host_player_symbol);
                board.gameboard[uint256(move)] = board.other_player_symbol;
            } else {
                board.other_player_symbol = Symbol.O;
                board.host_player_symbol = Symbol.X;
            }
        }
        
        return true;
    }
    
    function get_board() public view returns (Symbol[9] memory) {
        return gameboards[msg.sender].gameboard;
    }

    function bot_move(Symbol[9] memory gameboard, Symbol bot_symbol, Symbol player_symbol) pure internal returns(int) {
        
        // Put centre if possible
        if (gameboard[4] == Symbol.EMPTY) {
            return 4;
        }
        
        for(int i = 0; i < int(gameboard.length); i++) {
            if (gameboard[uint256(i)] == Symbol.EMPTY) {
                gameboard[uint256(i)] = bot_symbol;
                
                // If can win, win
                int score = evaluate(gameboard, bot_symbol, player_symbol);
                if (score == 1) {
                    return i;
                }
                
                // Remove
                gameboard[uint256(i)] = Symbol.EMPTY;
            }
        }
        
        // If opponent is 1 away from winning
        for(int i = 0; i < int(gameboard.length); i++) {
            if (gameboard[uint256(i)] == Symbol.EMPTY) {
                // Opponent move
                gameboard[uint256(i)] = player_symbol;
                
                int opp_score = evaluate(gameboard, player_symbol, bot_symbol);
                
                // If opponent can win with one more move, block it
                if (opp_score == 1) {
                    return i;
                }
            }
        }
        
        // Place it somewhere along the path of the opponents move
        for(int i = 0; i < int(gameboard.length); i++) {
            if (gameboard[uint256(i)] == player_symbol) {
                for (int j = -4; i < 5; j++) {
                    if (j + i >= 0 && j + i < 9) {
                        return j + i;
                    }
                }
            }
        }
        
        return -1;
    } 
    

    function make_move(uint8 position) public returns (string memory) {
        
        PlayerBoard storage board = gameboards[msg.sender];
        
        // Check that game is still in IN_PROGRESS
        require(board.status == Status.IN_PROGRESS);
        
        // Check if it is a valid position
        require(position >= 0 && position <= 8);
        
        // Check if a piece is already there
        Symbol board_position = board.gameboard[position];
        require(board_position == Symbol.EMPTY);
        
        // Make the move
        board.gameboard[position] = board.host_player_symbol;
        
        //check win
        if (evaluate(board.gameboard, board.host_player_symbol, board.other_player_symbol) == 1) {
            board.status = Status.HOST_PLAYER_WON;
            return "win";
        } else if (is_moves_left(board.gameboard) == false) {
            return "draw";
        } else if (board.game_type == GameType.BOT) {
            
            //bot move
            int move = bot_move(board.gameboard, board.other_player_symbol, board.host_player_symbol);
            //need to check if this is valid
            board.gameboard[uint256(move)] = board.other_player_symbol;
            if (evaluate(gameboards[msg.sender].gameboard, board.other_player_symbol, board.host_player_symbol) == 1) {
                board.status = Status.OTHER_PLAYER_WON;
                return "lost";
            }
            
            if (is_moves_left(board.gameboard) == false) {
                board.status = Status.DRAW;
                return "draw";
            }
        }
            
        return "next move";
    }
    
    
    function evaluate(Symbol[9] memory gameboard, Symbol player, Symbol opponent) internal pure returns(int) {
                uint8[3][8] memory winning_states = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [6, 4, 2]
            ];
        
        for (uint8 i = 0; i < winning_states.length; i++) {
            uint8[3] memory winning_state = winning_states[i];
            if (
                gameboard[winning_state[0]] == player && 
                gameboard[winning_state[1]] == player && 
                gameboard[winning_state[2]] == player) {
                    return 1;
            } else if (
                gameboard[winning_state[0]] == opponent && 
                gameboard[winning_state[1]] == opponent && 
                gameboard[winning_state[2]] == opponent) {
                    return -1;
            }
        }
        return 0;
    }
    
    function is_moves_left(Symbol[9] memory gameboard) internal pure returns(bool) {
        for(uint8 i = 0; i < gameboard.length; i++) {
            if (gameboard[i] == Symbol.EMPTY) {
                return true;
            }
        }
        return false;
    }
    
    function generate_random_start() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % 2;
    }
}