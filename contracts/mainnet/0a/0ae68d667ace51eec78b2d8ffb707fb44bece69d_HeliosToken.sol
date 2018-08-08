pragma solidity ^0.4.20;
library SafeMath { //standard library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

contract HeliosToken { //ERC - 20 token contract
  using SafeMath for uint;

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


  string public constant symbol = "HLC";
  string public constant name = "Helios";

  uint8 public constant decimals = 2;
  uint256 _totalSupply = uint(5000000).mul(uint(10).pow(decimals));

  function HeliosToken () public {
    balances[address(this)] = _totalSupply;
  }
  
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) { //standart ERC-20 function
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {//standart ERC-20 function
    return balances[_address];
  }

  //standart ERC-20 function
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(address(this) != _to && _to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender,_to,_amount);
    return true;
  }
  
  address public crowdsaleContract;

  //connect to crowdsaleContract, can be use once
  function setCrowdsaleContract (address _address) public{
    require(crowdsaleContract == address(0));
    crowdsaleContract = _address;
  }

  uint public crowdsaleTokens = uint(4126213).mul(uint(10).pow(decimals)); //_totalSupply - distributing

  function sendCrowdsaleTokens (address _address, uint _value) public {
    require (msg.sender == crowdsaleContract);
    crowdsaleTokens = crowdsaleTokens.sub(_value);
    balances[address(this)] = balances[address(this)].sub(_value);
    balances[_address] = balances[_address].add(_value);
    emit Transfer(address(this),_address,_value); 
  }

  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    require(address(this) != _to && _to != address(0));
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);
    return true;
  }

  //standart ERC-20 function
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  //standart ERC-20 function
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  address public teamAddress = 0x1367eC0f6f5DEFda7B0f1b7AD234900E23Ee62CF;
  uint public teamDistribute = uint(500000).mul(uint(10).pow(decimals));
  address public reserveAddress = 0xD598350D4D55f72dAb1286Ed0A3a3b7F1A7A54Ce;
  uint public reserveDistribute = uint(250000).mul(uint(10).pow(decimals));
  address public bountyAddress = 0xcBfA29FBe59C83A1130b4957bD41847a2837782E;

  function endIco() public {  
    require (msg.sender == crowdsaleContract);
    require (balances[address(this)] != 0);
    
    uint tokensSold = _totalSupply.sub(crowdsaleTokens);

    balances[teamAddress] = balances[teamAddress].add(teamDistribute);
    balances[reserveAddress] = balances[reserveAddress].add(reserveDistribute);
    balances[bountyAddress] = balances[bountyAddress].add(tokensSold*3/100);

    emit Transfer(address(this), teamAddress, teamDistribute);
    emit Transfer(address(this), reserveAddress, reserveDistribute);
    emit Transfer(address(this), bountyAddress, tokensSold*3/100);

    uint buffer = tokensSold*3/100 + teamDistribute + reserveDistribute;

    emit Transfer(address(this), 0, balances[address(this)].sub(buffer));
    balances[address(this)] = 0;
  }
}