pragma solidity ^0.4.18;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

contract Ownable {
  address public owner;
  address public tech;
  
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyTech() {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
  function transferTech(address newTech) public onlyOwner {
    require(newTech != address(0));
    tech = newTech;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IceRockPay is ERC20Basic, Ownable {
  event Payout(address indexed from, address indexed to, uint256 value);
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  string public name = "Rock2Pay";
  string public symbol = "Rock2Pay";
  uint256 totalSupply_;
  uint8 public constant decimals = 18;
  enum States {
    Sale,
    Stop
  }
  States public state;        
  
  constructor() public {
    totalSupply_ = 0;
    state = States.Sale;
  }

  modifier requireState(States _requiredState) {
    require(state == _requiredState);
    _;
  }
  
  function requestPayout(uint256 _amount, address _address)
  onlyTech
  public
  {
    _address.transfer(_amount);
  }
  
  function changeState(States _newState)
  onlyTech
  public
  {
    state = _newState;
  }
  
  function decreaseTokens(address _address, uint256 _amount) 
  onlyTech
  public {
    balances[_address] = balances[_address].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
  }
  
  function decreaseTokensMulti(address[] _address, uint256[] _amount) 
  onlyTech
  public {
      for(uint i = 0; i < _address.length; i++){
        balances[_address[i]] = balances[_address[i]].sub(_amount[i]);
        totalSupply_ = totalSupply_.sub(_amount[i]);
      }
  }
  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function addTokens(address _address, uint256 _amount) 
  onlyTech
  public {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_address] = balances[_address].add(_amount);
    emit Transfer(msg.sender, _address, _amount);
  }
  
  function addTokensMulti(address[] _address, uint256[] _amount) 
  onlyTech
  public {
      for(uint i = 0; i < _address.length; i++){
        totalSupply_ = totalSupply_.add(_amount[i]);
        balances[_address[i]] = balances[_address[i]].add(_amount[i]);
        emit Transfer(msg.sender, _address[i], _amount[i]);
      }
  }
  
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    if (to == owner) {
        totalSupply_ = totalSupply_.sub(tokens);
        msg.sender.transfer(tokens);
        emit Payout(msg.sender, to, tokens);
    } else {
        balances[to] = balances[to].add(tokens);
    }
    emit Transfer(msg.sender, to, tokens);
  }
  
  function() payable
  public
  {
    
  }

}