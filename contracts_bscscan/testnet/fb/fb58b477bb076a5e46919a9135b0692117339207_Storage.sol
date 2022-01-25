/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number1;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store1(uint256 num) public {
        number1 = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve21() public view returns (uint256){
        return number1;
    }
}