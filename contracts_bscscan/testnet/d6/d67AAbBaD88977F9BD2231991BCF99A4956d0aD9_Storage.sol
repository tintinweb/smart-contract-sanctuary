/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(string memory num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (string memory){
        return number;
    }
}