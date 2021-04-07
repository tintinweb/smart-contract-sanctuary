/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.8;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    function store(uint256) public {
        number = 1;
    }

    function increment(address,address,uint256) public {
        number++;
    }
    
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}