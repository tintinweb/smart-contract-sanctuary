/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.8.0;

// abstract contract TicTacToeLobbyInterface {
//     // THIS IS NEEDED ?? OR CAN WE DELETE THIS ???
// }

contract TicTacToe {
    address player1;
    address player2;
    uint256 amount;
    // TicTacToeLobbyInterface GameLobby;
    // TODO: player turn ?
    // uint8 turn; // turn = 1 player1 turn = 2 player2
    uint8[9] gameBoard = [
        // first row
        0,
        0,
        0,
        // second row
        0,
        0,
        0,
        // third row
        0,
        0,
        0
    ];

    constructor(
        address _player1,
        uint256 _amount
        // address gameLobbyAddress,
    ) {
        // GameLobby = TicTacToeLobbyInterface(gameLobbyAddress);
        player1 = _player1;
        amount = _amount;
    }

    function startGame() public payable {
        // TODO: create start game function
        // check if amount == msg.value
        // check if player1 != msg.sender
        // check if player2 is null
    }

    function move(uint8 position) public {
        // TODO: move
        // check if the game is finish
        // check if position is < 8
        // check if position is empty == 0
        // check if its your turn
        // update the board
        // check if the game is finish
        // update turn
    }

    // private finish game ???
    // transfer amount ?
}