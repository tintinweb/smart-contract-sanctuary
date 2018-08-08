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

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    require(msg.sender == tech);
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

contract Stelz is ERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "STELZ";
  string public constant symbol = "STELZ";
  uint8 public constant decimals = 5;
  uint256 public constant initial_supply = 300000000 * (10 ** uint256(decimals));

  mapping (address => uint256) balances;

  uint256 totalSupply_;
  uint256 wei_price;
  uint256 min_amount;
  enum States {
    Sale,
    Stop
  }
  States public state;
  
  constructor() public {
    owner = msg.sender;
    tech = msg.sender;
    totalSupply_ = initial_supply;
    balances[owner] = initial_supply;
    wei_price = 1754385960; // equal to 0.1usd per stelz
    min_amount = 1754385964912000000; // equal to 1000usd
    state = States.Sale;
    emit Transfer(0x0, owner, initial_supply);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  function price() public view returns (uint256) {
    return wei_price;
  }
  
  function minAmount() public view returns (uint256) {
    return min_amount;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _balance = balances[msg.sender];
    require(_value <= _balance);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function changePrice(uint256 _new_price) public onlyTech {
    wei_price = _new_price;
  }
  
  function changeMinAmount(uint256 _new_min_amount) public onlyTech {
    min_amount = _new_min_amount;
  }
  
  modifier checkMinAmount(uint256 amount) {
    require(amount >= min_amount);
    _;
  }
  
  modifier requireState(States _requiredState) {
    require(state == _requiredState);
    _;
  }
  
  function changeState(States _newState)
  onlyTech
  public
  {
    state = _newState;
  }
  
  function transferMany(address[] recipients, uint256[] values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      require(balances[msg.sender] >= values[i]);
      require(recipients[i] != address(0));
      balances[msg.sender] = balances[msg.sender].sub(values[i]);
      balances[recipients[i]] = balances[recipients[i]].add(values[i]);
      emit Transfer(msg.sender, recipients[i], values[i]);
    }
  }
  
  function requestPayout(uint256 _amount)
  onlyOwner
  public
  {
    msg.sender.transfer(_amount);
  }
  
  function() payable
  checkMinAmount(msg.value)
  requireState(States.Sale)
  public
  {
    uint256 _coinIncrease = msg.value.div(wei_price);
    require(balances[owner] >= _coinIncrease);
    balances[owner] = balances[owner].sub(_coinIncrease);
    balances[msg.sender] = balances[msg.sender].add(_coinIncrease);
    emit Transfer(owner, msg.sender, _coinIncrease);
  }
}