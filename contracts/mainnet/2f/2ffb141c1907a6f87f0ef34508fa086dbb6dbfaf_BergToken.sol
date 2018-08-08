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

contract ERC20NonTransfer {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BergToken is ERC20NonTransfer {
  using SafeMath for uint256;

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
  address public initialHolder;
  uint256 public price;
  uint256 public min_amount;

  constructor() public {
    totalSupply_ = 0;
    initialHolder = msg.sender;
    state = States.Sale;
    price = 2134107302920000;
    min_amount = 213410730292000000;
  }

  modifier requireState(States _requiredState) {
    require(state == _requiredState);
    _;
  }
  modifier onlyOwner() {
    require(msg.sender == initialHolder);
    _;
  }
  function requestPayout(uint256 _amount, address _address)
  onlyOwner
  public
  {
    _address.transfer(_amount);
  }
  modifier minAmount(uint256 amount) {
    require(amount >= min_amount);
    _;
  }
  function changePrice(uint256 _new_price)
  onlyOwner
  public 
  {
    price = _new_price;
  }
  function changeMinAmount(uint256 _new_min_amount)
  onlyOwner
  public 
  {
    min_amount = _new_min_amount;
  }
  function changeState(States _newState)
  onlyOwner
  public
  {
    state = _newState;
  }
  
  function() payable
  requireState(States.Sale)
  minAmount(msg.value)
  public
  {
    uint256 _coinIncrease = msg.value.mul((10 ** uint256(decimals))).div(price);
    totalSupply_ = totalSupply_.add(_coinIncrease);
    balances[msg.sender] = balances[msg.sender].add(_coinIncrease);
    emit Transfer(initialHolder, msg.sender, _coinIncrease);
  }
  
  function decreaseTokens(address _address, uint256 _amount) 
  onlyOwner
  public {
    balances[_address] = balances[_address].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
  }
  
  function decreaseTokensMulti(address[] _address, uint256[] _amount) 
  onlyOwner
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
  onlyOwner
  public {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_address] = balances[_address].add(_amount);
    emit Transfer(initialHolder, _address, _amount);
  }
  
  function addTokensMulti(address[] _address, uint256[] _amount) 
  onlyOwner
  public {
      for(uint i = 0; i < _address.length; i++){
        totalSupply_ = totalSupply_.add(_amount[i]);
        balances[_address[i]] = balances[_address[i]].add(_amount[i]);
        emit Transfer(initialHolder, _address[i], _amount[i]);
      }
  }

}