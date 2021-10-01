/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Coin {

  address public minter;
  mapping (address => uint) public balance;
  event Logger(address from, address to, uint amount);

  constructor() {
    minter = msg.sender;
    mint(minter, 100000);   
  }

  
 function mint(address reciver, uint amount) public {
      require(msg.sender == reciver);
      require(amount < 1e60);
      balance[reciver] += amount;
  }

  function send(address reciver, uint amount) public {
      require(amount <= balance[msg.sender]);
      balance[msg.sender] -= amount;
      balance[reciver] += amount;
      emit Logger(msg.sender, reciver, amount); 
  }
}