pragma solidity ^0.4.23;
///////////////////////////////////////////////////
//  
//  `iCashweb` ICW Token Contract
//
//  Total Tokens: 300,000,000.000000000000000000
//  Name: iCashweb
//  Symbol: ICWeb
//  Decimal Scheme: 18
//  
//  by Nishad Vadgama
///////////////////////////////////////////////////

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC01Basic {
  function totalSupply() public view returns(uint256);
  function balanceOf(address who) public view returns(uint256);
  function transfer(address to, uint256 value) public returns(bool);
  function changeRate(uint256 value) public returns(bool);
  function startIco(bool status) public returns(bool);
  function changeOwnerShip(address toWhom) public returns(bool);
  function transferTokens() public payable;
  function releaseIcoTokens() public returns(bool);
  function transferICOTokens(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC01Basic {
  function allowance(address owner, address spender) public view returns(uint256);
  function transferFrom(address from, address to, uint256 value) public returns(bool);
  function approve(address spender, uint256 value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICWToken is ERC01Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  address public contractModifierAddress;
  uint256 _totalSupply;
  uint256 _totalICOSupply;
  uint256 _maxICOSupply;
  uint256 RATE = 100;
  bool _status;
  bool _released;

  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 150000000 * (10 ** uint256(decimals));
  uint256 public constant ICO_SUPPLY = 150000000 * (10 ** uint256(decimals));

  modifier onlyByOwned() {
    require(msg.sender == contractModifierAddress);
    _;
  }

  function getReleased() public view returns(bool) {
    return _released;
  }
  
  function getOwner() public view returns(address) {
    return contractModifierAddress;
  }
  
  function getICOStatus() public view returns(bool) {
    return _status;
  }
  
  function getRate() public view returns(uint256) {
    return RATE;
  }

  function totalSupply() public view returns(uint256) {
    return _totalSupply;
  }

  function totalICOSupply() public view returns(uint256) {
    return _totalICOSupply;
  }

  function destroyContract() public onlyByOwned {
    selfdestruct(contractModifierAddress);
  }

  function changeOwnerShip(address _to) public onlyByOwned returns(bool) {
    address oldOwner = contractModifierAddress;
    uint256 balAmount = balances[oldOwner];
    balances[_to] = balances[_to].add(balAmount);
    balances[oldOwner] = 0;
    contractModifierAddress = _to;
    emit Transfer(oldOwner, contractModifierAddress, balAmount);
    return true;
  }

  function releaseIcoTokens() public onlyByOwned returns(bool) {
    require(_released == false);
    uint256 realeaseAmount = _maxICOSupply.sub(_totalICOSupply);
    uint256 totalReleased = _totalICOSupply.add(realeaseAmount);
    require(_maxICOSupply >= totalReleased);
    _totalSupply = _totalSupply.add(realeaseAmount);
    balances[contractModifierAddress] = balances[contractModifierAddress].add(realeaseAmount);
    emit Transfer(contractModifierAddress, contractModifierAddress, realeaseAmount);
    return true;
  }

  function changeRate(uint256 _value) public onlyByOwned returns(bool) {
    require(_value > 0);
    RATE = _value;
    return true;
  }

  function startIco(bool status_) public onlyByOwned returns(bool) {
    _status = status_;
    return true;
  }

  function transferTokens() public payable {
    require(_status == true && msg.value > 0);
    uint tokens = msg.value.mul(RATE);
    uint totalToken = _totalICOSupply.add(tokens);
    require(_maxICOSupply >= totalToken);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    _totalICOSupply = _totalICOSupply.add(tokens);
    contractModifierAddress.transfer(msg.value);
  }
  
  function transferICOTokens(address _to, uint256 _value) public onlyByOwned returns(bool) {
    uint totalToken = _totalICOSupply.add(_value);
    require(_maxICOSupply >= totalToken);
    balances[_to] = balances[_to].add(_value);
    _totalICOSupply = _totalICOSupply.add(_value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns(bool) {
    require(_to != msg.sender);
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns(uint256 balance) {
    return balances[_owner];
  }
}

contract iCashwebToken is ERC20, ICWToken {

  mapping(address => mapping(address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    require(_to != msg.sender);
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns(bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns(uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract iCashweb is iCashwebToken {

  string public constant name = "iCashweb";
  string public constant symbol = "ICWeb";

  constructor() public {
    _status = false;
    _released = false;
    contractModifierAddress = msg.sender;
    _totalSupply = INITIAL_SUPPLY;
    _maxICOSupply = ICO_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  function () public payable {
    transferTokens();
  }
}