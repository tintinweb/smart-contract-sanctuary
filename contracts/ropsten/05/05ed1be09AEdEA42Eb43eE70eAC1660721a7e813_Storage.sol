/**
 *Submitted for verification at Etherscan.io on 2021-12-16
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
     * @param s value to store
     */
    function store(string memory s) public {
        str = s;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (string memory){
        return str;
    }
}