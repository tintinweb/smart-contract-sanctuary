/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract User {
  string public user;
  address owner;


  constructor(string memory _user) public {
    user = _user;
    owner = msg.sender;
  }

  function getUserName() public view returns (string memory) {
      return user;
  }

  function setUserName(string memory _user) public {
      user = _user;
  }
  
  function getBalance(address owner) public view returns(uint accountBalance) {  
           return accountBalance = owner.balance;
  }
  
  /**
    * @dev Return owner address 
    * @return address of owner
    */
  function getOwner() external view returns (address) {
      return owner;
  }

}