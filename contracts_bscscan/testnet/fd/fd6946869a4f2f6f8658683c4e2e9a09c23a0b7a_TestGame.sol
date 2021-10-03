/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: GPL-MIT

pragma solidity >=0.7.0 <0.9.0;

contract TestGame {
    uint256 public constant balance = 0;
    
    mapping(address => uint256) public  miners;
    
    function buy(uint256 amount) public returns (bool) {
        uint256 newMiners = amount * 10000;
        miners[msg.sender] = miners[msg.sender] + newMiners;
        
        emit BoughtMiners(msg.sender, newMiners, amount);
        
        return true;
    }
    
    event BoughtMiners(address indexed buyer, uint256 newMiners, uint256 amount);
}