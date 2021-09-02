/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract StorageString {

    string _ss;
    
    constructor(string memory ss) 
    public {
        store(ss);
    }

    function store(string memory ss) public {
        _ss = ss;
    }

    function retrieve() public view returns (string memory){
        return _ss;
    }
}