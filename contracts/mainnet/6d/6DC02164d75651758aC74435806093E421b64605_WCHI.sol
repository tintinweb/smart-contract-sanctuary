/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/IWCHI.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;


/**
 * @dev Interface for the wrapped CHI (WCHI) token.
 */
interface IWCHI is IERC20
{

  /**
   * @dev Burns the given number of tokens, reducing total supply.
   */
  function burn (uint256 value) external;

  /**
   * @dev Increases the allowance of a given spender by the given amount.
   */
  function increaseAllowance (address spender, uint256 addedValue)
      external returns (bool);

  /**
   * @dev Decreases the allowance of a given spender by the given amount.
   */
  function decreaseAllowance (address spender, uint256 removedValue)
      external returns (bool);

}

// File: contracts/WCHI.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;


/**
 * @dev Wrapped CHI (WCHI) token.  This contract is not upgradable and not
 * owned, but it grants an initial supply to the contract creator.  The Xaya
 * team will hold these tokens, and give them out for CHI locked on the
 * Xaya network.  When WCHI tokens are returned, those CHI will be released
 * again.
 */
contract WCHI is IWCHI
{

  string public constant name = "Wrapped CHI";
  string public constant symbol = "WCHI";

  /** @dev Native CHI has 8 decimals (like BTC), we mimic that here.  */
  uint8 public constant decimals = 8;

  /**
   * @dev Initial supply of tokens minted.  This is a bit larger than the
   * real total supply of CHI.
   */
  uint256 internal constant initialSupply = 78 * 10**6 * 10**decimals;

  /**
   * @dev Total supply of tokens.  This includes tokens that are in the
   * Xaya team's reserve, i.e. do not correspond to real CHI locked
   * in the treasury.
   */
  uint256 public override totalSupply;

  /** @dev Balances of tokens per address.  */
  mapping (address => uint256) public override balanceOf;

  /**
   * @dev Allowances for accounts (second) to spend from the balance
   * of an owner (first).
   */
  mapping (address => mapping (address => uint256)) public override allowance;

  /**
   * @dev In the constructor, we grant the contract creator the initial balance.
   * This is the only place where any address has special rights compared
   * to all others.
   */
  constructor ()
  {
    totalSupply = initialSupply;
    balanceOf[msg.sender] = initialSupply;
    emit Transfer (address (0), msg.sender, initialSupply);
  }

  /**
   * @dev Sets the allowance afforded to the given spender by
   * the message sender.
   */
  function approve (address spender, uint256 value)
      external override returns (bool)
  {
    setApproval (msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Moves a given amount of tokens from the message sender's
   * account to the recipient.  If to is the zero address, then those
   * tokens are burnt and reduce the total supply.
   */
  function transfer (address to, uint256 value) external override returns (bool)
  {
    uncheckedTransfer (msg.sender, to, value);
    return true;
  }

  /**
   * @dev Moves a given amount of tokens from the sender account to the
   * recipient.  If from is not the message sender, then it needs to have
   * sufficient allowance.
   */
  function transferFrom (address from, address to, uint256 value)
      external override returns (bool)
  {
    if (from != msg.sender)
      {
        /* Check for the allowance and reduce it.  */
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type (uint256).max)
          {
            require (allowed >= value, "WCHI: allowance exceeded");
            uint256 newAllowed = allowed - value;
            setApproval (from, msg.sender, newAllowed);
          }
      }

    uncheckedTransfer (from, to, value);
    return true;
  }

  /**
   * @dev Internal transfer implementation.  This is used to implement transfer
   * and transferFrom, and does not check that the sender is actually
   * allowed to spend the tokens.
   */
  function uncheckedTransfer (address from, address to, uint256 value) internal
  {
    require (to != address (0), "WCHI: transfer to zero address");
    require (to != address (this), "WCHI: transfer to contract address");

    deductBalance (from, value);
    balanceOf[to] += value;

    emit Transfer (from, to, value);
  }

  /**
   * @dev Burns tokens from the sender's balance, reducing total supply.
   */
  function burn (uint256 value) external override
  {
    deductBalance (msg.sender, value);
    assert (totalSupply >= value);
    totalSupply -= value;
    emit Transfer (msg.sender, address (0), value);
  }

  /**
   * @dev Increases the allowance of a given spender by a certain
   * amount (rather than explicitly setting the new allowance).  This fails
   * if the new allowance would be at infinity (or overflow).
   */
  function increaseAllowance (address spender, uint256 addedValue)
      external override returns (bool)
  {
    uint256 allowed = allowance[msg.sender][spender];

    uint256 increaseToInfinity = type (uint256).max - allowed;
    require (addedValue < increaseToInfinity,
             "WCHI: increase allowance overflow");

    setApproval (msg.sender, spender, allowed + addedValue);
    return true;
  }

  /**
   * @dev Decreases the allowance of a given spender by a certain value.
   * If the value is more than the current allowance, it is set to zero.
   */
  function decreaseAllowance (address spender, uint256 removedValue)
      external override returns (bool)
  {
    uint256 allowed = allowance[msg.sender][spender];

    if (removedValue >= allowed)
      setApproval (msg.sender, spender, 0);
    else
      setApproval (msg.sender, spender, allowed - removedValue);

    return true;
  }

  /**
   * @dev Internal helper function to check the balance of the given user
   * and deduct the given amount.
   */
  function deductBalance (address from, uint256 value) internal
  {
    uint256 balance = balanceOf[from];
    require (balance >= value, "WCHI: insufficient balance");
    balanceOf[from] = balance - value;
  }

  /**
   * @dev Internal helper function to explicitly set the allowance of
   * a spender without any checks, and emit the Approval event.
   */
  function setApproval (address owner, address spender, uint256 value) internal
  {
    allowance[owner][spender] = value;
    emit Approval (owner, spender, value);
  }

}