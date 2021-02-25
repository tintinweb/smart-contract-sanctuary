/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.7.0 <0.8.0;



 
 
 
contract TicTacToe {
    enum Symbol {EMPTY, X, O}
    enum State {WAITING2, WAITING1, TURNO, TURNX, WINNERX, WINNERO, DRAW}
    
    struct Player {
        address addr;
        Symbol symbol;
    }
    
    State state = State.WAITING2;
    Player playerX;
    Player playerO;
    
    Symbol[] board = new Symbol[](9);
    
    
    
    function register() public returns (Symbol) {
        require((state == State.WAITING2 || state == State.WAITING1) && playerX.addr != msg.sender);
        if(state == State.WAITING2) {
            playerX = Player(msg.sender, Symbol.O);
            state = State.WAITING1;
            return Symbol.O;
        } else if(state == State.WAITING1) {
            playerO = Player(msg.sender, Symbol.X);
            state = State.TURNO;
            return Symbol.X;
        }
            return Symbol.EMPTY;
    }
    
    function reset() public {
        state = State.WAITING2;
        for(uint i = 0; i < board.length; i++) {
            board[i] = Symbol.EMPTY;
        }
        playerX.addr = address(0);
        playerO.addr = address(0);
    }
    
    function getState() public view returns (State) {
        return state;
    }
    
    function getBoard() public view returns (Symbol[] memory) {
        return board;
    }
    
    function getSymbol() public view returns (Symbol) {
        if(playerX.addr == msg.sender) return Symbol.X;
        if(playerO.addr == msg.sender) return Symbol.O;
        return Symbol.EMPTY;
    }
    
    function checkWin(Symbol s) private view returns (bool) {
        // horizontals
        if(board[0] == s && board[1] == s && board[2] == s) return true;
        if(board[3] == s && board[4] == s && board[5] == s) return true;
        if(board[6] == s && board[7] == s && board[8] == s) return true;
        // verticals
        if(board[0] == s && board[3] == s && board[6] == s) return true;
        if(board[1] == s && board[4] == s && board[7] == s) return true;
        if(board[2] == s && board[5] == s && board[8] == s) return true;
        // diagonals
        if(board[0] == s && board[4] == s && board[8] == s) return true;
        if(board[2] == s && board[4] == s && board[6] == s) return true;
        return false;
    }
    
    function fullBoard() private view returns (bool) {
        for(uint i = 0; i < board.length; i++) {
            if (board[i] == Symbol.EMPTY) return false;
        }
        return true;
    }
    
    function doMove(uint coord) public returns (bool success) {
        require(state == State.TURNO && msg.sender == playerO.addr || state == State.TURNX && msg.sender == playerX.addr);
        require(board[coord] == Symbol.EMPTY);
        if(state == State.TURNO) { 
            board[coord] = Symbol.O;
            if(checkWin(Symbol.O)) {
                state = State.WINNERO;
                return true;
            }
        }
        if(state == State.TURNX) {
            board[coord] = Symbol.X;
            if(checkWin(Symbol.X)) {
                state = State.WINNERX;
                return true;
            }
        }
        if(fullBoard()) {
            state = State.DRAW;
            return true;
        }
        if(state == State.TURNX) state = State.TURNO;
        else if(state == State.TURNO) state = State.TURNX;
        return true;
    }
    
}