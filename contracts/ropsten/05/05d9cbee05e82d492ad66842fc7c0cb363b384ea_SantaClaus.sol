pragma solidity >0.4.99 <0.6.0;

// File: contracts/ChristmasStocking.sol

contract ChristmasStocking {
  using SafeMath for uint256;

  bool private _isOpen;
  mapping(address => uint256) private _balances;

  constructor() public {
    _isOpen = false;
  }

  function isOpen() public view returns (bool) {
    return _isOpen;
  }

  function balanceOf(address who) public view returns (uint256) {
    return _balances[who];
  }

  function deposit() payable public {
    _isOpen = true;
    (bool success,) = msg.sender.call.value(msg.value)(abi.encodePacked());
    require(success);
    _isOpen = false;
  }

  function bribe() payable public {
    require(_isOpen);
    _balances[tx.origin] = _balances[tx.origin].add(msg.value);
  }

  function withdraw() public {
    uint256 balance = _balances[msg.sender];
    _balances[msg.sender] = 0;
    msg.sender.transfer(balance);
  }
}

// File: contracts/ChristmasTree.sol

contract ChristmasTree {
  using SafeMath for uint256;

  mapping(address => uint256) private _powers;
  mapping(address => uint256[]) private _decorations;

  function powerOf(address who) public view returns (uint256) {
    return _powers[who];
  }

  function decorationAt(address who, uint256 index) public view returns (uint256) {
    return _decorations[who][index];
  }

  function pray() public {
    _powers[msg.sender] = _powers[msg.sender].add(1);
  }

  function pushDecoration(uint256 decoration) public {
    _decorations[msg.sender].push(decoration);
  }

  function popDecoration() public {
    require(_decorations[msg.sender].length >= 0);
    _decorations[msg.sender].length--;
  }

  function replaceDecoration(uint256 index, uint256 decoration) public {
    require(index < _decorations[msg.sender].length);
    _decorations[msg.sender][index] = decoration;
  }
}

// File: contracts/Letter.sol

contract Letter {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => bool) private _isSealeds;

  function balanceOf(address who) public view returns (uint256) {
    return _balances[who];
  }

  function isSealed(address who) public view returns (bool) {
    return _isSealeds[who];
  }

  function () payable external {
    require(!_isSealeds[msg.sender]);
    _balances[msg.sender] = _balances[msg.sender].add(msg.value);
  }

  function seal() public {
    require(_balances[msg.sender] > 0);
    _isSealeds[msg.sender] = true;
  }

  function discard() public {
    uint256 balance = _balances[msg.sender];
    _balances[msg.sender] = 0;
    _isSealeds[msg.sender] = false;
    msg.sender.transfer(balance);
  }
}

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

// File: contracts/SantaClaus.sol

contract SantaClaus is Ownable {
  ChristmasStocking private _christmasStocking;
  ChristmasTree private _christmasTree;
  Letter private _letter;
  SantaClausToken private _token;

  constructor(address stocking, address tree, address payable letter, address token) Ownable() public {
    _christmasStocking = ChristmasStocking(stocking);
    _christmasTree = ChristmasTree(tree);
    _letter = Letter(letter);
    _token = SantaClausToken(token);
  }

  function christmasStocking() public view returns (address) {
    return address(_christmasStocking);
  }

  function christmasTree() public view returns (address) {
    return address(_christmasTree);
  }

  function letter() public view returns (address) {
    return address(_letter);
  }

  function token() public view returns (address) {
    return address(_token);
  }

  function requestToken() public {
    require(_letter.isSealed(msg.sender));
    require(_christmasStocking.balanceOf(msg.sender) > 0);
    require(_christmasTree.powerOf(msg.sender) > 99999999);
    require(_token.balanceOf(msg.sender) == 0);

    // Congratulations!!
    _token.mint(msg.sender, 1);
  }

  function renounceTokenOwnership() public onlyOwner {
    _token.renounceOwnership();
  }

  function transferTokenOwnership(address newOwner) public onlyOwner {
    _token.transferOwnership(newOwner);
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