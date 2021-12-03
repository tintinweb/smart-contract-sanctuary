/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Tictactoe {

    uint256 number;
    uint256[3][3] grid;
    uint256 nextCase = 1;
    address lastTransaction; 

    function setCase(uint256 x, uint256 y) public returns (uint256[3][3] memory) {
        require(lastTransaction != tx.origin, "same origin");
        require(grid[y][x] == 0, "case already set");

        grid[y][x] = nextCase;

        if (nextCase == 1) {
            nextCase = 2;
        } else {
            nextCase = 1;
        }

        lastTransaction = tx.origin;

        return grid;
    }

    function checkVictory() public view returns (uint256) {

        for (uint i=0; i<3; i++) {
            if (grid[i][0] == grid[i][1] && grid[i][1] == grid[i][2] && grid[i][0] != 0) {
                return grid[i][0];
            }

            if (grid[0][i] == grid[1][i] && grid[1][i] == grid[2][i] && grid[0][i] != 0) {
                return grid[0][i];
            }
        }

        if (grid[0][0] == grid[1][1] && grid[1][1] == grid[2][2] && grid[0][0] != 0) {
            return grid[0][0];
        }

        if (grid[0][2] == grid[1][1] && grid[1][1] == grid[2][0] && grid[0][2] != 0) {
            return grid[0][2];
        }

        return 0;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256[3][3] memory){
        return grid;
    }
}