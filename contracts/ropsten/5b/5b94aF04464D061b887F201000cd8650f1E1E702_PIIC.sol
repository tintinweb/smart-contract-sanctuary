// SPDX-License-Identifier: NOLICENSE

pragma solidity 0.8.0;

import './ERC20.sol';

contract PIIC is ERC20 {
  constructor() ERC20("PIIC Token", "PIIC") {
    _mint(msg.sender, 100000);
  }
}

// SPDX-License-Identifier: NOLICENSE

pragma solidity 0.8.0;

import '../interfaces/IERC20.sol';

contract ERC20 is IERC20 {
  mapping(address => uint256) private _balances;
  
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  address private _owner;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  modifier onlyOwner() {
    require(msg.sender == _owner, 'Ownable: caller is not the owner');
    _;
  }

  constructor(string memory name_, string memory symbol_) {
    _owner = msg.sender;
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  function name() public override view returns (string memory) {
    return _name;
  }

  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  function decimals() public override view returns (uint8) {
    return _decimals;
  }

  function getOwner() public override view returns (address) {
    return _owner;
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 amount) public returns (bool) {
    _approve(msg.sender, spender, _allowances[spender][msg.sender] + amount);
    return true;
  }

  function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
    require(_allowances[msg.sender][spender] - amount >= 0, 'ERC20: decreased allowance below zero');
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - amount);
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(msg.sender, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(_balances[sender] >= amount, 'ERC20: transfer amount exceeds balance');
    _balances[sender] -= amount;
    _balances[recipient] += amount;

    emit Tranfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _mint(address account, uint256 amount) internal {
    _totalSupply += amount;
    _balances[account] += amount;
    emit Tranfer(address(0), account, amount);
  }
}

// SPDX-License-Identifier: NOLICENSE

pragma solidity 0.8.0;

interface IERC20 {
  /**
    * @dev Returns the token decimals.
    */
  function decimals() external view returns (uint8);

  /**
    * @dev Returns the token symbol.
    */
  function symbol() external view returns (string memory);

  /**
    * @dev Returns the token name.
    */
  function name() external view returns (string memory);

  /**
    * @dev Returns the erc token owner.
    */
  function getOwner() external view returns (address);

  /**
    * @dev Returns the amount of tokens in existence.
    */
  function totalSupply() external view returns (uint256);

  /**
    * @dev Returns the amount of tokens owned by `account`.
    */
  function balanceOf(address account) external view returns (uint256);

  /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
  event Tranfer(address indexed from, address indexed to, uint256 value);

  /**
    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    * a call to {approve}. `value` is the new allowance.
    */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

