/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// 1. solidify file must start with licence

// 2. range of compiler version to use?

/**
 * @title Sumeet001Storage
 * @dev Store & retrieve value in a variable
 */
contract Sumeet001Storage {

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
}