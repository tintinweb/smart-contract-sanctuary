/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
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
    require(_owner == _msgSender(), "e0");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "e0");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "e0");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'e0');
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "e0");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "e0");
    uint256 c = a / b;
    return c;
  }
}

contract CHG is Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor (string memory name, string memory symbol, uint256 _maxSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
    _totalSupply = _maxSupply.mul(1e18);
    _balances[_msgSender()] = _totalSupply;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "e0");
    require(recipient != address(0), "e1");
    _beforeTokenTransfer(sender, recipient, amount);
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "e0");
    require(spender != address(0), "e1");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}