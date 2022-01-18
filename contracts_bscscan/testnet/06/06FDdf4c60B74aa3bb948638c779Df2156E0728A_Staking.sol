// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Staking {

    struct User {
        uint time;
        uint index;
    }
    // User[] public users;
    mapping(address => User[])  users;    

    
    function manipulateArrayMap(address _user) public {
        users[_user].push(User({
            time: block.timestamp,
            index: 1
        }));           //assign a value; 
    }
    function getUserTxs(address userAddr) public view returns(
        User[30] memory trxs
    ){
        for(uint256 i = 0; i < users[userAddr].length; i++){
            trxs[i] = users[userAddr][i];
        }
    }
    
}