/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/TicTacToken.sol
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

////// src/TicTacToken.sol
/* pragma solidity ^0.8.0; */

contract TicTacToken {
    uint256[9] public board;

    uint256 internal constant X = 1;
    uint256 internal constant O = 2;
    uint256 internal turns;

    function markSpace(uint256 i, uint256 symbol) public {
        require(_validTurn(symbol), "Not your turn");
        require(_validSpace(i), "Invalid space");
        require(_validSymbol(symbol), "Invalid symbol");
        require(_emptySpace(i), "Already marked");
        turns++;
        board[i] = symbol;
    }

    function getBoard() public view returns (uint256[9] memory) {
        return board;
    }

    function currentTurn() public view returns (uint256) {
        return (turns % 2 == 0) ? X : O;
    }

    function reset() public {
        delete board;
    }

    function winner() public view returns (uint256) {
        return _checkWins();
    }

    function _validSpace(uint256 i) internal pure returns (bool) {
        return i < 9;
    }

    function _validTurn(uint256 symbol) internal view returns (bool) {
        return currentTurn() == symbol;
    }

    function _emptySpace(uint256 i) internal view returns (bool) {
        return board[i] == 0;
    }

    function _validSymbol(uint256 symbol) internal pure returns (bool) {
        return symbol == X || symbol == O;
    }

    function _checkWins() internal view returns (uint256) {
        uint256[8] memory wins = [
            _row(0),
            _row(1),
            _row(2),
            _col(0),
            _col(1),
            _col(2),
            _diag(),
            _antiDiag()
        ];
        for (uint256 i = 0; i < wins.length; i++) {
            if (wins[i] == 1) {
                return X;
            } else if (wins[i] == 8) {
                return O;
            }
        }
        return 0;
    }

    function _row(uint256 row) internal view returns (uint256) {
        require(row <= 2, "Invalid row");
        return board[row] * board[row + 1] * board[row + 2];
    }

    function _col(uint256 col) internal view returns (uint256) {
        require(col <= 2, "Invalid col");
        return board[col] * board[col + 3] * board[col + 6];
    }

    function _diag() internal view returns (uint256) {
        return board[0] * board[4] * board[8];
    }

    function _antiDiag() internal view returns (uint256) {
        return board[2] * board[4] * board[6];
    }
}