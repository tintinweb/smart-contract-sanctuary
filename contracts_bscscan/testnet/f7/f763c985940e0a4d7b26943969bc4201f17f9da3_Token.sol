/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.0;

contract Token{
    string store;
    
    function setStorage(string memory _newString) public {
        store = _newString;
    }
    
    function getString() public view returns(string memory){
        return store;
    }
}