// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBEP20 {
 
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
  function totalSupply() external view returns (uint256);
  function totalLock() external view returns (uint256);
  function totalAvailable() external view returns (uint256);
  // function buyToken(address investor, uint256 amount) external returns (bool);
  // function disbursement(address owner,uint256 amount) external returns (bool);
  // function lockSupply(address owner) external returns (bool);
  // function unlockSupply(address owner) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ContractTokenTest is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  uint256 private _totalLock;
  uint256 private _totalAvailable;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  bool private _statusLock;
  constructor() public {
    _name = "BIDVTEST2";
    _symbol = "BIDVTEST2";
    _decimals = 8;
    _totalSupply = 200000000000000 * 10 ** 8;
    _totalLock =  160000000000000 * 10 ** 8;
   _statusLock = true;
   _totalAvailable = 40000000000000 * 10 ** 8;

  }
 function name() external override view returns (string memory) {
    return _name;
  }
 function symbol() external override view returns (string memory) {
    return _symbol;
  }
  function decimals() external override view returns (uint8) {
    return _decimals;
  }
 function getOwner() external override view returns (address) {
    return owner();
  }
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }
 function totalLock() external override view returns (uint256) {
    return _totalLock;
  }
 function totalAvailable() external override view returns (uint256) {
    return _totalAvailable;
  }
 function buyToken(address investor, uint256 amount) public returns (bool) {
    _buyToken(investor,amount);
    return true;
  }
 function disbursement(uint256 amount) public returns (bool) {
    _disbursement(amount);
    return true;
  }
 function lockSupply() public returns (bool) {
    _lock();
    return true;
  }
 function unlockSupply() public returns (bool) {
    _unlock();
    return true;
  }
 function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }
 function transfer(address recipient, uint256 amount) external override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
    return true;
  }
 function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }
 function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
 function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }
 function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
 function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
 function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
 function _buyToken(address investor, uint256 amount) internal {
    require(_msgSender() == address(0), "Ownable: caller is not the owner");
    require(amount <= _totalAvailable, "Token not enough to buy");
    _balances[investor] = _balances[investor].add(amount);
    _totalAvailable = _totalAvailable.sub(amount);
    emit Transfer(address(0), investor, amount);
  }
 function _disbursement(uint256 amount) internal {
     require(_msgSender() == address(0), "Ownable: caller is not the owner");
     require(_statusLock == false, "BEP20: Token was locked");
     require(amount <=  _totalLock, "BEP20: Token not enough");
     _totalAvailable = _totalAvailable.add(amount);
     _totalLock = _totalLock.sub(amount);
     
  }
 function _lock() internal {
      require(_msgSender() == address(0), "Ownable: caller is not the owner");
     _statusLock = true;
  }
 function _unlock() internal {
    require(_msgSender() == address(0), "Ownable: caller is not the owner");
     _statusLock = false;
  }
  function _burn(address account, uint256 amount) internal {
    require(_msgSender() == address(0), "Ownable: caller is not the owner");
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
 function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}