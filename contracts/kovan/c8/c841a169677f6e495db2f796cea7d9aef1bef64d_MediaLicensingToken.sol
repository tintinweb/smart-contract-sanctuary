/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
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

interface IERC20Metadata is IERC20 {

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {

  // Holds the owner address
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// Our main contract which implements all ERC20 standard methods
contract MediaLicensingToken is Context, IERC20, IERC20Metadata, Ownable {

  // Holds all the balances
  mapping (address => uint256) private _balances;

  // Holds all allowances
  mapping (address => mapping (address => uint256)) private _allowances;

  // Holds all blacklisted addresses
  mapping (address => bool) private _blocklist;

  // They can only be decreased
  uint256 private _totalSupply;

  // Immutable they can only be set once during construction
  string private _name;
  string private _symbol;
  uint256 private _maxTokens;

  // Events
  event Blocklist(address indexed account, bool indexed status);

  // The initializer of our contract
  constructor () {
    _name = "Media Licensing Token";
    _symbol = "MLT";

    // Holds max mintable limit, 200 million tokens
    _maxTokens = 200000000000000000000000000;
    _mint(_msgSender(), _maxTokens);
  }

  /*
   * PUBLIC RETURNS
   */

  // Returns the name of the token.
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  // Returns the symbol of the token
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  // Returns the number of decimals used
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  // Returns the total supply
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  // Returns the balance of a given address
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  // Returns the allowances of the given addresses
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  // Returns a blocked address of a given address
  function isBlocked(address account) public view virtual returns (bool) {
    return _blocklist[account];
  }

  /*
   * PUBLIC FUNCTIONS
   */

  // Calls the _transfer function for a given recipient and amount
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  // Calls the _transfer function for a given array of recipients and amounts
  function transferArray(address[] calldata recipients, uint256[] calldata amounts) public virtual returns (bool) {
    for (uint8 count = 0; count < recipients.length; count++) {
      _transfer(_msgSender(), recipients[count], amounts[count]);
    }
    return true;
  }

  // Calls the _approve function for a given spender and amount
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  // Calls the _transfer and _approve function for a given sender, recipient and amount
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  // Calls the _approve function for a given spender and added value (amount)
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  // Calls the _approve function for a given spender and substracted value (amount)
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  /*
   * PUBLIC (Only Owner)
   */

  // Calls the _burn internal function for a given amount
  function burn(uint256 amount) public virtual onlyOwner {
    _burn(_msgSender(), amount);
  }

  function blockAddress (address account) public virtual onlyOwner {
    _block(account, true);
  }

  function unblockAddress (address account) public virtual onlyOwner {
    _block(account, false);
  }

  /*
   * INTERNAL (PRIVATE)
   */

  function _block (address account, bool status) internal virtual {
    require(account != _msgSender(), "ERC20: message sender can not block or unblock himself");
    _blocklist[account] = status;

    emit Blocklist(account, status);
  }

  // Implements the transfer function for a given sender, recipient and amount
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  // Implements the mint function for a given account and amount
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    // Paranoid security
    require(_totalSupply <= _maxTokens, "ERC20: mint exceeds total supply limit");

    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  // Implements the burn function for a given account and amount
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  // Implements the approve function for a given owner, spender and amount
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /*
   * INTERNAL (PRIVATE) HELPERS
   */

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    require(_blocklist[from] == false && _blocklist[to] == false, "MLTERC20: transfer not allowed");
    require(amount > 0, "ERC20: amount must be above zero");
  }
}