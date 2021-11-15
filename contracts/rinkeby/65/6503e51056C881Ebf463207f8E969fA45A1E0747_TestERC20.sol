// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../base/ERC20.sol";


contract TestERC20 is ERC20 {
  mapping(address => address) public delegates;
  event Delegate(address indexed delegator, address indexed delegatee);

  constructor(string memory name_, string memory symbol_) {
    initialize(name_, symbol_);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/************************************************************************************************
Originally from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/ERC20.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 8f2b54f645a7844ae266cc50dc3ae4c125c7b9fc.

Subject to the MIT license
*************************************************************************************************/


contract ERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev The amount of tokens in existence.
   */
  uint256 public totalSupply;
  /**
   * @dev The amount of tokens owned by `account`.
   */
  mapping(address => uint256) public balanceOf;
  /**
   * @dev The remaining number of tokens that `spender` will be allowed
   * to spend on behalf of `owner` through {transferFrom}. This is zero
   * by default.
   */
  mapping(address => mapping(address => uint256)) public allowance;

  /** @dev The name of the token. */
  string public name;

  /** @dev The symbol of the token. */
  string public symbol;

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {balanceOf} and {transfer}.
   */
  uint8 public constant decimals = 18;

  function initialize(
    string memory name_,
    string memory symbol_
  ) public {
    require(keccak256(bytes(name)) == keccak256(bytes("")), "Already Initialised");
    require(keccak256(bytes(name_)) != keccak256(bytes("")), "Name cannot be empty");
    require(keccak256(bytes(symbol_)) != keccak256(bytes("")), "Symbol cannot be empty");

    name = name_;
    symbol = symbol_;
  }

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
    uint256 spenderAllowance = allowance[msg.sender][spender];
    require(spenderAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
    _approve(msg.sender, spender, spenderAllowance - subtractedValue);
    return true;
  }

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 spenderAllowance = allowance[sender][msg.sender];
    require(spenderAllowance >= amount, 'ERC20: transfer amount exceeds allowance');

    _approve(sender, msg.sender, spenderAllowance - amount);
    return true;
  }

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
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    // If `amount` is 0, or `msg.sender` is `to` nothing happens
    if (amount != 0) {
      uint256 srcBalance = balanceOf[sender];
      require(srcBalance >= amount, "ERC20: transfer amount exceeds balance");
      if (sender != recipient) {
        require(recipient != address(0), 'ERC20: transfer to the zero address'); // Moved down so low balance calls safe some gas
        balanceOf[sender] = srcBalance - amount; // Underflow is checked
        balanceOf[recipient] += amount; // Can't overflow because totalSupply would be greater than 2^256-1
      }
    }

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(spender != address(0), "ERC20: approve to the zero address");
    allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    require((totalSupply = totalSupply + amount) >= amount);
    balanceOf[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");
    uint supply = totalSupply;
    uint balance = balanceOf[account];
    require((balanceOf[account] = balance - amount) <= balance, "ERC20: burn amount exceeds balance");
    require((totalSupply = supply - amount) <= supply);

    emit Transfer(account, address(0), amount);
  }
}

