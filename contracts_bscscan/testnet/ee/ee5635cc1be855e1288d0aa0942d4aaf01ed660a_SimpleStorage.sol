/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract SimpleStorage {
    string public name;

    function set(string memory _name) public{
        name = _name;
    }

    // function get() public view returns(string memory){
        // return name;
    // }
}