pragma solidity ^0.4.24;

/* COOPEX Smart Contract */
/* This is the smart &#39;hotwallet&#39; for the Cooperative Exchange. All Ethereum assets will be stored on this smart contract. This smart contract will be used while we work on a fully decentralized exchange. */
/* Visit us at https://coopex.market */

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract Exchange {
    
    

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  
  constructor() {
    owner = msg.sender;
    locked = false;
  }
  
  address public owner;
  mapping (address => bool) public admins;
  bool locked;
  
  event SetOwner(address indexed previousOwner, address indexed newOwner);
  event Deposit(address token, address user, uint256 amount);
  event Withdraw(address token, address user, uint256 amount);
  event Lock(bool lock);
  
  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin {
    require(msg.sender != owner && !admins[msg.sender]);
    _;
  }
  
  function setOwner(address newOwner) onlyOwner {
    SetOwner(owner, newOwner);
    owner = newOwner;
  }
  
  function getOwner() view returns (address out) {
    return owner;
  }

  function setAdmin(address admin, bool isAdmin) onlyOwner {
    admins[admin] = isAdmin;
  }



  function() public payable {
    Deposit(0, msg.sender, msg.value);
  }

 

  function withdraw(address token, uint256 amount) onlyAdmin returns (bool success) {
    require(!locked);
    if (token == address(0)) {
      require(msg.sender.send(amount));
    } else {
      require(amount <= Token(token).balanceOf(this));
      require(Token(token).transfer(msg.sender, amount));
    }
    Withdraw(token, msg.sender, amount);
    return true;
  }

  function lock() onlyOwner{
      locked = true;
      Lock(true);
  }
  
  function unlock() onlyOwner{
      locked = false;
      Lock(false);
  }
  
  function getBalance(address token) view returns (uint256 balance){
      if(token == address(0)){
          return this.balance;
      }
      else{
          return Token(token).balanceOf(this);
      }
  }

}