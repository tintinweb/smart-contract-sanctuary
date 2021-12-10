/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract simple{
    string name;
    function set (string memory _name) public {
        name = _name;
    }
    function get() public view returns (string memory){
        return name;
    }
}