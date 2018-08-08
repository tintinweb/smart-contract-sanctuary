pragma solidity ^0.4.24;

interface ERC20 {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function decimals() external view returns (uint8 _decimals);
  function totalSupply() external view returns (uint256 _totalSupply);
  function balanceOf(address _owner) external view returns (uint256 _balance);
  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a / _b;
    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Token is ERC20 {
  using SafeMath for uint256;
  string internal tokenName;
  string internal tokenSymbol;
  uint8 internal tokenDecimals;
  uint256 internal tokenTotalSupply;
  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function name() external view returns (string _name) {
    _name = tokenName;
  }

  function symbol() external view returns (string _symbol) {
    _symbol = tokenSymbol;
  }

  function decimals() external view returns (uint8 _decimals) {
    _decimals = tokenDecimals;
  }

  function totalSupply() external view returns (uint256 _totalSupply) {
    _totalSupply = tokenTotalSupply;
  }

  function balanceOf(address _owner) external view returns (uint256 _balance) {
    _balance = balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  function approve(address _spender, uint256 _value) public returns (bool _success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256 _remaining) {
    _remaining = allowed[_owner][_spender];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    _success = true;
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner public {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Claimable is Ownable {
  address public pendingOwner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function transferOwnership(address _newOwner) onlyOwner public {
    pendingOwner = _newOwner;
  }

  function claimOwnership() public {
    require(msg.sender == pendingOwner);
    address previousOwner = owner;
    owner = pendingOwner;
    pendingOwner = 0;
    emit OwnershipTransferred(previousOwner, owner);
  }
}

contract Changercy is Token, Claimable {
  using SafeMath for uint256;
  bool internal transferEnabled;
  address public crowdsaleAddress;
  event Burn(address indexed _burner, uint256 _value);
  
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    require(_to != address(crowdsaleAddress));
    _;
  }

  modifier onlyWhenTransferAllowed() {
    require(transferEnabled || msg.sender == crowdsaleAddress);
    _;
  }

  constructor() public {
    tokenName = "Changercy";
    tokenSymbol = "XCY";
    tokenDecimals = 18;
    tokenTotalSupply = 1140000000000000000000000000;
    transferEnabled = false;
    balances[owner] = tokenTotalSupply;
    emit Transfer(address(0x0), owner, tokenTotalSupply);
  }

  function transfer(address _to, uint256 _value) onlyWhenTransferAllowed() validDestination(_to) public returns (bool _success) {
    _success = super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyWhenTransferAllowed() validDestination(_to) public returns (bool _success) {
    _success = super.transferFrom(_from, _to, _value);
  }

  function enableTransfer() onlyOwner() external {
    transferEnabled = true;
  }

  function burn(uint256 _value) onlyOwner() external {
    require(_value <= balances[msg.sender]);
    balances[owner] = balances[owner].sub(_value);
    tokenTotalSupply = tokenTotalSupply.sub(_value);
    emit Burn(owner, _value);
    emit Transfer(owner, address(0x0), _value);
  }

  function setCrowdsaleAddress(address crowdsaleAddr) external onlyOwner() {
    crowdsaleAddress = crowdsaleAddr;
  }
}