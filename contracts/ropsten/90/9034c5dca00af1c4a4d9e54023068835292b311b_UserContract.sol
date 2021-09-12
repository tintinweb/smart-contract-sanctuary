// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import './OnlyOwner.sol';

contract UserContract is OnlyOwner{

  address owner;
  uint256 public totalSupply = 1000000;
  string tokenName = "Szycha";
  mapping(address => uint256) balances;
  event Deposit(
    address from,
    address to,
    uint256 _amount
  );


  /**
  * Add balance constructor
  */
  constructor() public {
    
    balances[msg.sender] = totalSupply;
    owner = msg.sender;  

  }


  /**
  * Read balance for address
  */
  function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
  }

  /**
  * Transefer token to address
  */
  function transfer(address to, uint256 _amount) external isOwner {

      require (balances[msg.sender] >= _amount, 'Not enough Token');

      emit Deposit(
          msg.sender,
          to,
          _amount
      );
      balances[msg.sender] -= _amount;
      balances[to] += _amount;
  } 
}