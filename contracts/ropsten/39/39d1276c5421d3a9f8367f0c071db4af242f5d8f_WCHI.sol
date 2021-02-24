// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;

import "./IWCHI.sol";

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
    allowance[msg.sender][spender] = value;
    emit Approval (msg.sender, spender, value);
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
            allowance[from][msg.sender] = newAllowed;
            emit Approval (from, msg.sender, newAllowed);
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
   * @dev Internal helper function to check the balance of the given user
   * and deduct the given amount.
   */
  function deductBalance (address from, uint256 value) internal
  {
    uint256 balance = balanceOf[from];
    require (balance >= value, "WCHI: insufficient balance");
    balanceOf[from] = balance - value;
  }

}