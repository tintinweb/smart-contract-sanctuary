// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage3 {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store1(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve1() public view returns (uint256){
        return number;
    }
}