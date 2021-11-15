// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewRegister {
  
  enum Status { NoRecord, Processing, Finished }
  
  struct Account {
    string name;
    string email;
    address wallet;
	uint punkId;
    uint[] balance;
  }

  struct UseInfo {
    uint kind;
    address player;
    uint id;
	uint amount;
    string metaData;
    Status status;
  }
  
  address public owner;
  string[] tokens;
  uint public useId;

  mapping (address => Account) public accountInfo;
  mapping (uint => address) public punkOwner;
  mapping (address => bool) public isAdmin;
  mapping (address => uint) public lastUse;
  mapping (uint => UseInfo) public useInfo;
  mapping (address => mapping (uint => uint)) public oldBalance;

  event RegisterSucceed(address indexed player, string name, string email, address wallet);
  event Award(address indexed player, uint indexed id, uint amount);
  event Use(uint indexed useId, uint indexed kind, address indexed player, uint id, uint amount);
  
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

  function tokenInfo() public view returns (string[] memory) {
    return tokens;
  }

  function punkOf(address user) public view returns (uint) {
    return accountInfo[user].punkId;
  }
  
  function register(string memory name_, string memory email_, address wallet_) public {
    accountInfo[msg.sender].name = name_;
    accountInfo[msg.sender].email = email_;
    accountInfo[msg.sender].wallet = wallet_;
    emit RegisterSucceed(msg.sender, name_, email_, wallet_);
  }

  function award(address player, uint id, uint amount) public {
    require(isAdmin[msg.sender], "You are not admin");
    for(uint i=accountInfo[player].balance.length; i<=id; i++) {
      accountInfo[player].balance.push(0);
    }
    accountInfo[player].balance[id] += amount;
    emit Award(player, id, amount);
  }

  function use(address player, uint id, uint amount, uint kind, string memory metaData) public {
    require(isAdmin[msg.sender] || msg.sender == player, "You cannot use other's token");
    require(accountInfo[player].balance[id] >= amount, "No enough balance");
    accountInfo[player].balance[id] -= amount;
    useId ++;
    useInfo[useId] = UseInfo(kind, player, id, amount, metaData, Status.Processing);
    lastUse[player] = useId;
    emit Use(useId, kind, player, id, amount);
  }

  function setFinish(uint id) public {
    require(isAdmin[msg.sender], "You are not admin");
    useInfo[id].status = Status.Finished;
  }

  
}

