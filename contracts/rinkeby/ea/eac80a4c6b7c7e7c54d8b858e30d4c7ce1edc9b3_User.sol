/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract User {
  struct Member{
    uint256 balance;
    bool active;
    string id;
  }
  mapping(address => Member) private _members;
  address private _owner;
  
  event RegisterOk(address);
  event RechargeOk(address, uint256);
  event WithdrawOk(address, uint256);
    
  constructor() {
    _owner = msg.sender;
  }

  modifier allowRegisterMember(address account) {
    Member memory mb = _members[account];
    require(!mb.active, "This member has already exist");
    _;
  }

  modifier hasMember(address account) {
    Member memory mb = _members[account];
    require(mb.active, "Account not found");
    _;
  }

  modifier onlyPositive(uint256 value) {
    require(value > 0, "Value must be positive");
    _;
  }

  function owner() view public returns (address) {
    return _owner;
  }
  function register(string memory id) public allowRegisterMember(msg.sender) returns (address){
    _members[msg.sender] = Member(0, true, id);
    emit RegisterOk(msg.sender);
    return msg.sender;
  }

  function getBalance() public hasMember(msg.sender) view returns (uint256) {
    return _members[msg.sender].balance;
  }

  function recharge() public payable hasMember(msg.sender) onlyPositive(msg.value) {
    Member storage mb = _members[msg.sender];
    mb.balance = mb.balance + msg.value;
    emit RechargeOk(msg.sender, msg.value);
  }
  
  function withdraw(uint amount) public payable hasMember(msg.sender) onlyPositive(amount) {
      Member storage mb = _members[msg.sender];
      require(amount <= mb.balance, "Not enough balance");
      
      mb.balance = mb.balance - amount;
      payable(msg.sender).transfer(amount);
      
      emit WithdrawOk(msg.sender, amount);
  }
}