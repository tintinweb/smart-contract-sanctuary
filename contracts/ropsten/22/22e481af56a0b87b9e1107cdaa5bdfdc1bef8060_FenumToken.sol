/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract FenumToken is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _cap;
  uint256 private _totalSupply;
  uint256 private _totalBurned;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor () public {
    _name = "Fenum Token Ed test";
    _symbol = "FNM";
    _decimals = 18;
    _cap = 1_000_000_000000000000000000;
    _mint(_msgSender(), _cap);
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

  function cap() public view returns (uint256) {
    return _cap;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function totalBurned() public view returns (uint256) {
    return _totalBurned;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "FenumToken: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "FenumToken: decreased allowance below zero"));
    return true;
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
    uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "FenumToken: burn amount exceeds allowance");
    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "FenumToken: transfer from the zero address");
    require(recipient != address(0), "FenumToken: transfer to the zero address");
    _beforeTokenTransfer(sender, recipient, amount);
    _balances[sender] = _balances[sender].sub(amount, "FenumToken: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "FenumToken: mint to the zero address");
    _beforeTokenTransfer(address(0), account, amount);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "FenumToken: burn from the zero address");
    _beforeTokenTransfer(account, address(0), amount);
    _balances[account] = _balances[account].sub(amount, "FenumToken: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    _totalBurned = _totalBurned.add(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "FenumToken: approve from the zero address");
    require(spender != address(0), "FenumToken: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    if (from == address(0)) {
      require(totalSupply().add(amount) <= _cap, "FenumToken: cap exceeded");
    }
  }

  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  receive() external payable {
    revert("FenumToken: contract does not accept Ether.");
  }

  fallback() external {
    revert("FenumToken: contract action not found.");
  }
}