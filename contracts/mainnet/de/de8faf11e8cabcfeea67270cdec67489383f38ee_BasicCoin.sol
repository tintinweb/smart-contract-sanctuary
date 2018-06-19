//! BasicCoin ECR20-compliant token contract
//! By Parity Team (Ethcore), 2016.
//! Released under the Apache Licence 2.

pragma solidity ^0.4.1;

// ECR20 standard token interface
contract Token {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

// Owner-specific contract interface
contract Owned {
  event NewOwner(address indexed old, address indexed current);

  modifier only_owner {
    if (msg.sender != owner) throw;
    _;
  }

  address public owner = msg.sender;

  function setOwner(address _new) only_owner {
    NewOwner(owner, _new);
    owner = _new;
  }
}

// TokenReg interface
contract TokenReg {
  function register(address _addr, string _tla, uint _base, string _name) payable returns (bool);
  function registerAs(address _addr, string _tla, uint _base, string _name, address _owner) payable returns (bool);
  function unregister(uint _id);
  function setFee(uint _fee);
  function tokenCount() constant returns (uint);
  function token(uint _id) constant returns (address addr, string tla, uint base, string name, address owner);
  function fromAddress(address _addr) constant returns (uint id, string tla, uint base, string name, address owner);
  function fromTLA(string _tla) constant returns (uint id, address addr, uint base, string name, address owner);
  function meta(uint _id, bytes32 _key) constant returns (bytes32);
  function setMeta(uint _id, bytes32 _key, bytes32 _value);
  function transferTLA(string _tla, address _to) returns (bool success);
  function drain();
  uint public fee;
}

// BasicCoin, ECR20 tokens that all belong to the owner for sending around
contract BasicCoin is Owned, Token {
  // this is as basic as can be, only the associated balance & allowances
  struct Account {
    uint balance;
    mapping (address => uint) allowanceOf;
  }

  // the balance should be available
  modifier when_owns(address _owner, uint _amount) {
    if (accounts[_owner].balance < _amount) throw;
    _;
  }

  // an allowance should be available
  modifier when_has_allowance(address _owner, address _spender, uint _amount) {
    if (accounts[_owner].allowanceOf[_spender] < _amount) throw;
    _;
  }

  // no ETH should be sent with the transaction
  modifier when_no_eth {
    if (msg.value > 0) throw;
    _;
  }

  // a value should be > 0
  modifier when_non_zero(uint _value) {
    if (_value == 0) throw;
    _;
  }

  // the base, tokens denoted in micros
  uint constant public base = 1000000;

  // available token supply
  uint public totalSupply;

  // storage and mapping of all balances & allowances
  mapping (address => Account) accounts;

  // constructor sets the parameters of execution, _totalSupply is all units
  function BasicCoin(uint _totalSupply, address _owner) when_no_eth when_non_zero(_totalSupply) {
    totalSupply = _totalSupply;
    owner = _owner;
    accounts[_owner].balance = totalSupply;
  }

  // balance of a specific address
  function balanceOf(address _who) constant returns (uint256) {
    return accounts[_who].balance;
  }

  // transfer
  function transfer(address _to, uint256 _value) when_no_eth when_owns(msg.sender, _value) returns (bool) {
    Transfer(msg.sender, _to, _value);
    accounts[msg.sender].balance -= _value;
    accounts[_to].balance += _value;

    return true;
  }

  // transfer via allowance
  function transferFrom(address _from, address _to, uint256 _value) when_no_eth when_owns(_from, _value) when_has_allowance(_from, msg.sender, _value) returns (bool) {
    Transfer(_from, _to, _value);
    accounts[_from].allowanceOf[msg.sender] -= _value;
    accounts[_from].balance -= _value;
    accounts[_to].balance += _value;

    return true;
  }

  // approve allowances
  function approve(address _spender, uint256 _value) when_no_eth returns (bool) {
    Approval(msg.sender, _spender, _value);
    accounts[msg.sender].allowanceOf[_spender] += _value;

    return true;
  }

  // available allowance
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return accounts[_owner].allowanceOf[_spender];
  }

  // no default function, simple contract only, entry-level users
  function() {
    throw;
  }
}

// Manages BasicCoin instances, including the deployment & registration
contract BasicCoinManager is Owned {
  // a structure wrapping a deployed BasicCoin
  struct Coin {
    address coin;
    address owner;
    address tokenreg;
  }

  // a new BasicCoin has been deployed
  event Created(address indexed owner, address indexed tokenreg, address indexed coin);

  // a list of all the deployed BasicCoins
  Coin[] coins;

  // all BasicCoins for a specific owner
  mapping (address => uint[]) ownedCoins;

  // the base, tokens denoted in micros (matches up with BasicCoin interface above)
  uint constant public base = 1000000;

  // return the number of deployed
  function count() constant returns (uint) {
    return coins.length;
  }

  // get a specific deployment
  function get(uint _index) constant returns (address coin, address owner, address tokenreg) {
    Coin c = coins[_index];

    coin = c.coin;
    owner = c.owner;
    tokenreg = c.tokenreg;
  }

  // returns the number of coins for a specific owner
  function countByOwner(address _owner) constant returns (uint) {
    return ownedCoins[_owner].length;
  }

  // returns a specific index by owner
  function getByOwner(address _owner, uint _index) constant returns (address coin, address owner, address tokenreg) {
    return get(ownedCoins[_owner][_index]);
  }

  // deploy a new BasicCoin on the blockchain
  function deploy(uint _totalSupply, string _tla, string _name, address _tokenreg) payable returns (bool) {
    TokenReg tokenreg = TokenReg(_tokenreg);
    BasicCoin coin = new BasicCoin(_totalSupply, msg.sender);

    uint ownerCount = countByOwner(msg.sender);
    uint fee = tokenreg.fee();

    ownedCoins[msg.sender].length = ownerCount + 1;
    ownedCoins[msg.sender][ownerCount] = coins.length;
    coins.push(Coin(coin, msg.sender, tokenreg));
    tokenreg.registerAs.value(fee)(coin, _tla, base, _name, msg.sender);

    Created(msg.sender, tokenreg, coin);

    return true;
  }

  // owner can withdraw all collected funds
  function drain() only_owner {
    if (!msg.sender.send(this.balance)) {
      throw;
    }
  }
}