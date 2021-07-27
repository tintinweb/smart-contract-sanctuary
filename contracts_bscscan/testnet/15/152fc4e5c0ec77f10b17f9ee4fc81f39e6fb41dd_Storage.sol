/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    mapping (address => uint256) number;
    
    function store(uint256 num) public {
        number[msg.sender] = num;
    }
    function retrieve(address _address) public view returns (uint256){
        _address = msg.sender;
        return number[_address];
    }
}