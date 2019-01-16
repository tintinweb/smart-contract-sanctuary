pragma solidity >0.4.99 <0.6.0;

// File: contracts/Ownable.sol

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner {
    require(isOwner());
    _;
  }

  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/SafeMath.sol

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(a >= b);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a % b;
    return c;
  }
}

// File: contracts/SantaClausToken.sol

contract SantaClausToken is Ownable {
  using SafeMath for uint256;

  string private _name = "SantaClausToken";
  string private _symbol = "SCT";
  uint256 private _decimals = 0;

  uint256 private _totalSupply;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() Ownable() public {}

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint256) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address who) public view returns (uint256) {
    return _balances[who];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public onlyOwner returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public onlyOwner returns (bool) {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    emit Approval(from, msg.sender, _allowed[from][msg.sender]);
    return true;
  }

  function mint(address to, uint256 value) public onlyOwner returns (bool) {
    _mint(to, value);
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function _mint(address to, uint256 value) internal {
    require(to != address(0));
    _totalSupply = _totalSupply.add(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(address(0), to, value);
  }
}