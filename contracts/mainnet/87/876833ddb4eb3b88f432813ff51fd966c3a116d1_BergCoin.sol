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

contract ERC20NonTransfer {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BergCoin is ERC20NonTransfer, Ownable {
  using SafeMath for uint256;
  address public trade;
  address public withdrawal;
  mapping(address => uint256) balances;
  string public name = "Berg";
  string public symbol = "BERG";
  uint256 totalSupply_;
  uint8 public constant decimals = 18;
  enum States {
    Sale,
    Stop
  }
  States public state;        
  uint256 public price;
  uint256 public min_amount;

  constructor() public {
    totalSupply_ = 0;
    state = States.Sale;
    price = 2472383427000000;
    min_amount = 0;
    owner = msg.sender;
    withdrawal = 0x8F28FDc5ee8256Ca656654FDFd3142D00cC7C81a;
    tech = 0x8F28FDc5ee8256Ca656654FDFd3142D00cC7C81a;
    trade = 0x5072C2dE837D83784ffBD1831c288D1Bd7C151c8;
  }

  modifier requireState(States _requiredState) {
    require(state == _requiredState);
    _;
  }
  
  function changeTrade(address _address)
  onlyTech
  public
  {
    trade = _address;
  }
  
  function changeWithdrawal(address _address)
  onlyTech
  public
  {
    withdrawal = _address;
  }
  
  function requestPayout(uint256 _amount, address _address)
  onlyTech
  public
  {
    _address.transfer(_amount);
  }
  
  modifier minAmount(uint256 amount) {
    require(amount >= min_amount);
    _;
  }
  
  function changePrice(uint256 _new_price)
  onlyTech
  public 
  {
    price = _new_price;
  }
  
  function changeMinAmount(uint256 _new_min_amount)
  onlyTech
  public 
  {
    min_amount = _new_min_amount;
  }
  
  function changeState(States _newState)
  onlyTech
  public
  {
    state = _newState;
  }
  
  function() payable
  requireState(States.Sale)
  minAmount(msg.value)
  public
  {
    uint256 _get = msg.value.mul(975).div(1000);
    uint256 _coinIncrease = _get.mul((10 ** uint256(decimals))).div(price);
    totalSupply_ = totalSupply_.add(_coinIncrease);
    balances[msg.sender] = balances[msg.sender].add(_coinIncrease);
    withdrawal.transfer(msg.value.sub(_get));
    trade.transfer(_get);
    emit Transfer(address(0), msg.sender, _coinIncrease);
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
    emit Transfer(address(0), _address, _amount);
  }
  
  function addTokensMulti(address[] _address, uint256[] _amount) 
  onlyTech
  public {
      for(uint i = 0; i < _address.length; i++){
        totalSupply_ = totalSupply_.add(_amount[i]);
        balances[_address[i]] = balances[_address[i]].add(_amount[i]);
        emit Transfer(address(0), _address[i], _amount[i]);
      }
  }
}