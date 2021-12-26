/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract TestWeb3 {
     uint256[7][5] public allcof;
    struct User {
        uint8 day;
        uint8 coffee;
        uint256[7][5] cof;
    }
    
    mapping(address => User) public users;
    
    function setUser(address _wallet, uint8 _day, uint8 _coffee) external {
        User storage user = users[_wallet];
        user.day = _day;
        user.coffee = _coffee;
        user.cof[_coffee][_day]+=1;
        allcof[_coffee][_day]+=1;
    }
    
    function getUser(address _wallet) view external returns(uint8 _day, uint8 _coffee, uint256[7][5] memory _allcoffee) {
        User memory user = users[_wallet];
        _day = user.day;
        _coffee = user.coffee;
        _allcoffee=user.cof;
    }

    function clearUserTable(address _wallet) external {
        User storage user = users[_wallet];
         delete user.cof;
    }
    function getAllTable() view external returns(uint256[7][5] memory _allcoffee){
        _allcoffee=allcof;
    }
    function clearAllTable() external {
        delete allcof;
    }
}