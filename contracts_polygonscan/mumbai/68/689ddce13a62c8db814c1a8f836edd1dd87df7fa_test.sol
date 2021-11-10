/**
 *Submitted for verification at polygonscan.com on 2021-11-09
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7;


contract test {
    event Go(address indexed _sender);
    uint256 public data;
    
    
    function set_data(uint256 newdata) public {
        data = newdata;
    }
    
    function get_data() public view returns (uint256) {
        return data;
    }
    
    function trigger() public {
        emit Go(msg.sender);
    }
}