/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract TestWeb3 {
    
    struct User {
        uint256 day;
        uint256 coffee;
    }
    
    mapping(address => User) public users;
    
    function setUser(address _wallet, uint256 _day, uint256 _coffee) external {
        User storage user = users[_wallet];
        user.day = _day;
        user.coffee = _coffee;
    }
    
    function getUser(address _wallet) view external returns(uint256 _day, uint256 _coffee) {
        User memory user = users[_wallet];
        _day = user.day;
        _coffee = user.coffee;
    }
}