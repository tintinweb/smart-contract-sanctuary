pragma solidity ^0.8.0;

import "./TicTacToe.sol";

contract TicTacToeLobby {
    mapping(address => TicTacToe[]) userGames;
    event NewGame(address gameAddress, uint256 amount, address player1);

    // create a list of PENDING games ???
    // create a list of FINISHED games ???

    // create a game Leaderboard for users

    function createNewGame() public payable {
        // we create the new Tic Tac Toe game
        TicTacToe newTicTacToeGame = new TicTacToe(
            msg.sender,
            msg.value
            // address(this),
        );

        // we update de game list of this user
        userGames[msg.sender].push(newTicTacToeGame);

        emit NewGame(address(newTicTacToeGame), msg.value, msg.sender);
    }

    function findUserGames(address userAddress)
        public
        view
        returns (TicTacToe[] memory)
    {
        return (userGames[userAddress]);
    }
}