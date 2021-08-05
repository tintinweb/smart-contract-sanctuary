/**
 *Submitted for verification at Etherscan.io on 2020-08-13
*/

pragma solidity ^0.6.0;

contract Outa{
    uint public userCount;
    uint public earnedCount;
    address payable public owner;
   
   struct User{
       uint id;
       uint balance;
       uint partnersCount;
   }
   mapping(address => User) public users;
   mapping(uint => address) public idToAddress;
   
   constructor(address payable ownerAddress) public{
       owner = ownerAddress;
       userCount = 1;
       users[owner] = User(userCount, 0, 0);
       idToAddress[userCount] = owner;
   }
   
   function registerUser(address payable referral) external payable {
    require(msg.value == 0.05 ether,"Amount should be equal to 0.05 ether");
    require(isUserExists(referral),'Referral does not exists');
    require(!isUserExists(msg.sender),'User already exist');
    userCount++;
    users[msg.sender] = User(userCount, 0, 0);
    idToAddress[userCount] = msg.sender;
    referral.transfer(0.03 ether);
    users[referral].balance = users[referral].balance +  0.03 ether;
    users[referral].partnersCount ++;
    owner.transfer(0.02 ether);
    earnedCount = earnedCount + msg.value;

   }
   
   function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
}
}