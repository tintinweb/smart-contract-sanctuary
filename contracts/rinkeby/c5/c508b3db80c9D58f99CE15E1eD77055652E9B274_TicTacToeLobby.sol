pragma solidity ^0.8.0;

import "./TicTacToe.sol";

contract TicTacToeLobby {
    mapping(address => TicTacToe[]) userGames;

    // create a list of PENDING games ???
    // create a list of FINISHED games ???

    // create a game Leaderboard for users

    function createNewGame() public payable returns (TicTacToe) {
        // we create the new Tic Tac Toe game
        TicTacToe newTicTacToeGame = new TicTacToe(
            address(this),
            msg.sender,
            msg.value
        );

        // we update de game list of this user
        userGames[msg.sender].push(newTicTacToeGame);

        return newTicTacToeGame;
    }

    function findUserGames(address userAddress)
        public
        view
        returns (TicTacToe[] memory)
    {
        return userGames[userAddress];
    }
}