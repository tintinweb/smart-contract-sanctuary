/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256[3][3] grid;
    uint256 nextCase = 1;

    function setCase(uint256 x, uint256 y) public returns (uint256[3][3] memory) {
        require(grid[y][x] == 0, "case already set");

        grid[y][x] = nextCase;

        if (nextCase == 1) {
            nextCase = 2;
        } else {
            nextCase = 1;
        }

        return grid;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256[3][3] memory){
        return grid;
    }
}