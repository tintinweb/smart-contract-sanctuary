pragma solidity ^0.4.19;

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

contract Ownable { //standard contract to identify owner

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

contract BineuroToken is Ownable { //ERC - 20 token contract
  using SafeMath for uint;
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  string public constant symbol = "BNR";
  string public constant name = "BiNeuro";
  uint8 public constant decimals = 3;
  uint256 _totalSupply = (uint256)(850000000).mul((uint256)(10).pow(decimals));

  function getOwner()public view returns(address) {
    return owner;
  }

  // Balances for each account
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) { //standard ERC-20 function
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {//standard ERC-20 function
    return balances[_address];
  }

  //standard ERC-20 function
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(this != _to);
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

  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);
    return true;
  }

  //standard ERC-20 function
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  //standard ERC-20 function
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  //Constructor
  function BineuroToken() public {
    owner = 0xCe390a89734B2222Ff01c9ac4fD370581DeD82E0;
    // owner = msg.sender;
    
    balances[this] = _totalSupply;
  }

  uint public crowdsaleBalance = 52845528455;

  function sendCrowdsaleTokens(address _address, uint256 _value)  public {
    require(msg.sender == crowdsaleContract);
    crowdsaleBalance = crowdsaleBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    emit Transfer(this,_address,_value);
  }

  function burnTokens(address _address1, address _address2, address _address3, uint _tokensSold) public {
    require(msg.sender == crowdsaleContract);

    balances[this] = balances[this].sub(_tokensSold.mul((uint)(23))/100);
    balances[_address1] = balances[_address1].add(_tokensSold.mul((uint)(75))/1000);
    balances[_address2] = balances[_address2].add(_tokensSold.mul((uint)(75))/1000);
    balances[_address3] = balances[_address2].add(_tokensSold.mul((uint)(8))/100);

    emit Transfer(this,_address1,_tokensSold.mul((uint)(75))/1000);
    emit Transfer(this,_address2,_tokensSold.mul((uint)(75))/1000);
    emit Transfer(this,_address3,_tokensSold.mul((uint)(8))/100);

    _totalSupply = _totalSupply.sub(balances[this]);
    emit Transfer(this,0,balances[this]);

    balances[this] = 0;
  }
}