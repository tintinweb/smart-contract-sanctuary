/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TestRB {

    uint256 number;

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
    function retrieve() public view returns (uint256){
        return number;
    }

    // Increments number by 1
    function increment() public {
        number = number + 1;
    }

    // Addition
    function add(uint256 numA, uint256 numB) public pure returns(uint256){
        uint256 prod = numA + numB;
        return prod;
    }

    // Returning 2 values
    function multiplied(uint256 num) public pure returns (uint256 doubled, uint256 tripled){
        uint256 d = num * 2;
        uint256 t = num * 3;
        return (d, t);
    }
}