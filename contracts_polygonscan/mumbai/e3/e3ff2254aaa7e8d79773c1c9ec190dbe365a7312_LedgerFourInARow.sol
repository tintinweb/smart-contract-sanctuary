/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;


contract LedgerFourInARow{
    
    event GameCreation(address indexed p1, bytes32 indexed lobby);
    event GameJoin(address indexed p2, bytes32 indexed lobby); 
    event Move(address indexed p, bytes32 indexed lobby, uint8 move); 
    event GameEnd(address indexed winner, address indexed looser, bytes32 lobby); 

    modifier onlyGamers {
        require(lobby[msg.sender][c[msg.sender]] != bytes32(0), "No Game initiated");
        _;
    }
    
    modifier onlyOpenGame(address _addr) {
        require(lobby[_addr][c[_addr]] != bytes32(0), "No Game to join here");
        _;
    }
    
    mapping (address => mapping(uint8 => bytes32)) public lobby;
    mapping (bytes32 => GAME) public games;
    mapping (address => uint8) c;
    
    struct GAME{
        address player1;
        address player2;
        bool alt; // false if its player1's turn
        bool ended;
        uint8 [7][5] board;
    }
    
    
    function initGame() public {
        uint8 i = c[msg.sender];
        require(games[lobby[msg.sender][i]].player1 == address(0), "Game already initiated");
        bytes32 sec = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        lobby[msg.sender][i] = sec;
        GAME storage g = games[sec];
        g.player1 = msg.sender;
        emit GameCreation(msg.sender, sec);
    }
    
    function joinGame(address _addr) public onlyOpenGame(_addr) {
        uint8 i = c[msg.sender];
        uint8 j = c[_addr];
        bytes32 sec = lobby[_addr][j];
        lobby[msg.sender][i] = sec;
        GAME storage g = games[sec];
        require(g.player2 == address(0), "Game already full");
        require(g.player1 != msg.sender, "Player 1 cannot be Player 2");
        g.player2 = msg.sender;
        emit GameJoin(msg.sender, sec);
    }
    
    function getBoard() public view returns(uint8 [7][5] memory, string memory turn) {
        uint8 i = c[msg.sender];
        bytes32 sec = lobby[msg.sender][i];
        GAME storage g = games[sec];
        if(g.alt == false){
            turn = "Player 1";
        } else {
            turn = "Player 2";
        }
        return (g.board, turn);
    }
    
    function getGame() public view returns(address, address, bool, bool) {
        uint8 i = c[msg.sender];
        bytes32 sec = lobby[msg.sender][i];
        GAME storage g = games[sec];
        return (g.player1, g.player2, g.alt,  g.ended);
    }
    
    function move(uint8 _move) public onlyGamers {
        require(_move < 8, "Only 7 columns");
        uint8 _player;
        uint8 i = c[msg.sender];
        bytes32 sec = lobby[msg.sender][i];
        GAME storage g = games[sec];
        if(g.player1 == msg.sender){
            require(g.alt == false, "Other player's turn");
            _player = 1;
            g.alt = true;
        } else {
            require(g.alt == true, "Other player's turn");
            _player = 2;
            g.alt = false;
        }
        uint8 rowcount = 0;
        
        while(g.board[rowcount][_move]!=0){
            rowcount +=1;
        }
        g.board[rowcount][_move]=_player;
        emit Move(msg.sender, sec, _move);
    }
    
    function claimWin() public onlyGamers returns (bool win) {
        uint8 _player;
        address looser;
        uint8 k = c[msg.sender];
        bytes32 sec = lobby[msg.sender][k];
        GAME storage g = games[sec];
        if(g.player1 == msg.sender){
            _player = 1;
            looser = g.player2;
        } else {
            _player = 2;
            looser = g.player1;
        }
        // horizontal
        for (uint i=0; i<5; i++){
            for (uint j=0; j<4; j++){
                if(g.board[i][j]==_player&&g.board[i][j+1]==_player&&g.board[i][j+2]==_player&&g.board[i][j+3]==_player) {
                    g.ended = true;
                }
            }
        }
        // vertical
        for (uint i=0; i<7; i++){
            for (uint j=0; j<2; j++){
                if(g.board[j][i]==_player&&g.board[j+1][i]==_player&&g.board[j+2][i]==_player&&g.board[j+3][i]==_player) {
                    g.ended = true;
                }
            }
        }
        // ascending - diagonal
        for (uint i=0; i<2; i++){
            for (uint j=0; j<4; j++){
                if(g.board[i][j]==_player&&g.board[i+1][j+1]==_player&&g.board[i+2][j+2]==_player&&g.board[i+3][j+3]==_player) {
                    g.ended = true;
                }
            }
        }
        // descending - diagonal
        for (uint i=0; i<2; i++){
            for (uint j=0; j<4; j++){
                if(g.board[i+3][j]==_player&&g.board[i+2][j+1]==_player&&g.board[i+1][j+2]==_player&&g.board[i][j+3]==_player) {
                    g.ended = true;
                }
            }
        }
        if(g.ended == true){
            c[msg.sender] += 1;
            c[looser] += 1;
            emit GameEnd(msg.sender, looser, sec);
            return true;
        }
        return false;
    }
}