/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string str;

    /**
     * @dev Store value in variable
     * @param str_ value to store
     */
    function store(string memory str_) public {
        str = str_;
    }

    /**
     * @dev Return value 
     * @return value of 'str'
     */
    function retrieve() public view returns (string memory){
        return str;
    }
}