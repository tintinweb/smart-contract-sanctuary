/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
  
  enum Status { NoRecord, Processing, Finished }
  
  struct Account {
    string name;
    string email;
	  uint punkId;
    uint[] balance;
  }
  
  address public owner;
  string[] tokens;
  uint public useId;

  mapping (address => Account) public accountInfo;
  mapping (uint => address) public punkOwner;
  mapping (address => bool) public isAdmin;
  mapping (address => uint) public lastUse;
  mapping (uint => Status) public useInfo;

  event RegisterSucceed(address indexed player, string name, string email);
  event Award(address indexed player, uint indexed id, uint amount);
  event Use(uint indexed useId, address indexed player, uint indexed id, uint amount);
  
  constructor() {
    owner = msg.sender;
  }

  function setAdmin(address candidate, bool b) public {
    require(msg.sender == owner, "You are not admin");
    isAdmin[candidate] = b;
  }

  function newToken(string memory tokenName) public {
    require(msg.sender == owner, "You are not admin");
    tokens.push(tokenName);
  }

  function grantPunk(uint punkId, address newOwner) public {
    require(msg.sender == owner, "You are not admin");
    address prevOwner = punkOwner[punkId];
    accountInfo[prevOwner].punkId = 0;
    accountInfo[newOwner].punkId = punkId;
    punkOwner[punkId] = newOwner;
  }

  function balanceOf(address user) public view returns (uint[] memory) {
    return accountInfo[user].balance;
  }
  
  function register(string memory name_, string memory email_) public {
    accountInfo[msg.sender].name = name_;
    accountInfo[msg.sender].email = email_;
    emit RegisterSucceed(msg.sender, name_, email_);
  }

  function award(address player, uint id, uint amount) public {
    require(isAdmin[msg.sender], "You are not admin");
    for(uint i=accountInfo[player].balance.length; i<=id; i++) {
      accountInfo[player].balance.push(0);
    }
    accountInfo[player].balance[id] += amount;
    emit Award(player, id, amount);
  }

  function use(uint id, uint amount) public {
    require(accountInfo[msg.sender].balance[id] >= amount, "No enough balance");
    accountInfo[msg.sender].balance[id] -= amount;
    useId ++;
    useInfo[useId] = Status.Processing;
    lastUse[msg.sender] = useId;
    emit Use(useId, msg.sender, id, amount);
  }

  function setFinish(uint id) public {
    require(msg.sender == owner, "You are not admin");
    useInfo[id] = Status.Finished;
  }

  
}