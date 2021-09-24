/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract mFiToken {
    uint256 public count;
    uint256 public lastExecuted;
  
    struct User{
      uint amount;
      address user;
    }
    
    constructor(address _user1){}

     
     mapping(address => User) userStructs;
     address[] public userAddresses;
    
    function request(uint _requestAmount, address _user) external {

    userStructs[msg.sender].amount = _requestAmount;
    
    userStructs[msg.sender].user = _user;
    
    userAddresses.push(msg.sender);
    
    }
    
    function getAllUsers() external view returns (address[] memory) {
       return userAddresses;
    }
    
    function zero(uint amount) external {
    require(((block.timestamp - lastExecuted) > 50), "Counter: increaseCount: Time not elapsed");
    count += amount;
    lastExecuted = block.timestamp;
    }
}