/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

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

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve1() public view returns (uint256){
        return number;
    }

        /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve2() public view returns (uint256){
        return number;
    }
}