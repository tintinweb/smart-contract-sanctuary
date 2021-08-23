/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract User {
  string public user;
  address owner;
  address private minter;
  mapping (address => uint) public balance;
  event SendBlockChain(address from, address to, uint amount);



  constructor(string memory _user) public {
    user = _user;
    owner = msg.sender;
    minter = msg.sender;
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

  function mint(address reciver, uint amount) public {
    require(msg.sender == minter);
    require(amount < 1e60);
    balance[reciver] += amount;
  }

  function send(address reciver, uint amount) public {
    require(amount <= balance[msg.sender],"Brak Kasy");
    balance[msg.sender] -= amount; // odejmuje z adresu srodki wysłane
    balance[reciver] += amount; // dodaje do konta nowego adresu
    //msg.sender z jakiego adresu jest wysylany , emit wysyla do blockchaina 
    emit SendBlockChain(msg.sender,reciver,amount);
  }

}