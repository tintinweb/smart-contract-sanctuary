// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TicTacToe {
    address[] public players;
    // Either 0 or 1, in reference to the array above
    uint8 public currentPlayer;
    address public winner;
    mapping(uint8 => string) internal currentPlayerToSymbol;
    string constant defaultCellContent = "-";
    string[3][3] public board;

    constructor() {
        // No entrance fee for now, but could be fun to let the winner take all
        players.push(msg.sender);
        for (uint256 x = 0; x < board.length; x++) {
            for (uint256 y = 0; y < board[x].length; y++) {
                board[x][y] = defaultCellContent;
            }
        }
        currentPlayerToSymbol[0] = "X";
        currentPlayerToSymbol[1] = "O";
    }

    function getBoard() public view returns (string[3][3] memory) {
        return board;
    }

    function joinGame() external {
        require(players.length == 1, "There are already 2 players in the game");
        require(players[0] != msg.sender, "You can't play against yourself");
        players.push(msg.sender);
        currentPlayer = 0;
    }

    event GameOver(address winner);

    function playTurn(uint8 x, uint8 y) external {
        require(winner == address(0), "The game is over");
        require(players.length == 2, "You can't play alone");
        require(
            msg.sender == players[currentPlayer],
            "It's not your turn to play!"
        );
        require(x < 3 && x >= 0, "x must be between 0 and 2");
        require(y < 3 && y >= 0, "x must be between 0 and 2");
        require(
            keccak256(bytes(board[x][y])) ==
                keccak256(bytes(defaultCellContent)),
            "Someone has already played here"
        );
        board[x][y] = currentPlayerToSymbol[currentPlayer];
        bool hasWon = checkWin();
        if (hasWon) {
            emit GameOver(players[currentPlayer]);
            winner = players[currentPlayer];
        } else {
            currentPlayer = currentPlayer == 0 ? 1 : 0;
        }
    }

    function checkWin() internal view returns (bool) {
        string memory currentPlayerSymbol = currentPlayerToSymbol[
            currentPlayer
        ];
        bool isDiagonalWin1 = true;
        bool isDiagonalWin2 = true;
        uint8 diagonalY = 2;
        for (uint256 x = 0; x < board.length; x++) {
            if (
                keccak256(bytes(board[x][x])) !=
                keccak256(bytes(currentPlayerSymbol))
            ) {
                isDiagonalWin1 = false;
            }
            if (
                keccak256(bytes(board[x][diagonalY])) !=
                keccak256(bytes(currentPlayerSymbol))
            ) {
                isDiagonalWin2 = false;
            }
            bool isHorizontalWin = true;
            bool isVerticalWin = true;
            for (uint256 y = 0; y < board[x].length; y++) {
                if (
                    keccak256(bytes(board[x][y])) !=
                    keccak256(bytes(currentPlayerSymbol))
                ) {
                    isHorizontalWin = false;
                }
                if (
                    keccak256(bytes(board[y][x])) !=
                    keccak256(bytes(currentPlayerSymbol))
                ) {
                    isVerticalWin = false;
                }
            }
            if (isHorizontalWin || isVerticalWin) return true;
            if (diagonalY != 0) diagonalY--;
        }
        if (isDiagonalWin1 || isDiagonalWin2) return true;
        return false;
    }
}