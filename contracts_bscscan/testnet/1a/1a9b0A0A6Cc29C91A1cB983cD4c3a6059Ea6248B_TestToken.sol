/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0

contract TestToken {

    uint256 public number;

    string  name;

    function serNumber(uint256 num_) public returns(bool){
        number = num_;
        return true;
    }

    function serName(string memory name_) public returns(bool){
        name = name_;
        return true;
    }

    function getName() public view returns(string memory){
        return name;
    }

}