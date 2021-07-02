/*
 * This file is part of the Meeds project (https://meeds.io/).
 * Copyright (C) 2020 Meeds Association
 * [email protected]
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
pragma solidity ^0.5.0;

import "./ERTTokenV1.sol";
import "./AccountRewarding.sol";
import "./TokenVesting.sol";
import "./AccountInitialization.sol";

/**
 * @title ERTTokenV2.sol
 * @dev ERC20 Token implementation V2 with Rewarding, Vesting and simplified wallet Initialization
 */
contract ERTTokenV2 is ERTTokenV1, AccountInitialization, AccountRewarding, TokenVesting {

    /**
     * @dev send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        uint256 gasLimit = gasleft();

        // This assertion is already made in super._transfer operation
        // require(_value > 0);
        // Make sure that this is not about a fake transaction
        require(msg.sender != _to);

        // Update vesting balance if sender or receiver aren't approved
        bool approvedSender = super.isApprovedAccount(msg.sender);
        if (!approvedSender || !super.isApprovedAccount(_to)) {
          super._transferVesting(_to, _value);
        }

        // This is to avoid calling this function with empty tokens transfer
        // If the user doesn't have enough ethers, he will simply reattempt with empty tokens
        require(super._transfer(msg.sender, _to, _value) == true);

        // Emit ERC-20 event
        emit Transfer(msg.sender, _to, _value);

        // Make sure that vested balance is <= token balance
        super._adjustVestingBalance(msg.sender);

        // Pay gas with tokens
        if (approvedSender) {
          super._payGasInToken(gasLimit);
        }
        return true;
    }

    /**
     * @dev `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public whenNotPaused whenApproved(msg.sender) whenApproved(_spender) returns (bool success) {
        uint gasLimit = gasleft();
        // Make sure that this is not about a fake transaction
        require(msg.sender != _spender);

        // Test if allowed balance is less than balance of sender
        require(super._balanceOf(msg.sender) >= _value);

        // Change allowed tokens
        super._setAllowance(msg.sender, _spender, _value);

        // Emit ERC-20 event
        emit Approval(msg.sender, _spender, _value);

        // Pay gas with tokens
        super._payGasInToken(gasLimit);
        return true;
    }

    /**
     * @dev send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused whenApproved(msg.sender) whenApproved(_to) whenApproved(_from) returns (bool success) {
        uint gasLimit = gasleft();

        // Make sure that the receiver is different from sender
        require(_from != _to);

        require(super._balanceOf(_from) >= _value);

        // Ensure that msg.sender has sufficient allowed amount to transfer
        uint256 _allowance = super._getAllowance(_from, msg.sender);
        require(_allowance >= _value);

        // substract allowed amount to msg.sender
        super._setAllowance(_from, msg.sender, super.safeSubtract(_allowance, _value));

        // Transfer tokens
        require(super._transfer(_from, _to, _value) == true);

        // emit ERC-20 event
        emit Transfer(_from, _to, _value);

        // Make sure that vested balance is <= token balance
        uint256 vestingBalance = super.vestingBalanceOf(msg.sender);
        uint256 newTokenBalance = super.balanceOf(msg.sender);
        if (newTokenBalance < vestingBalance) {
            super._setVestingBalance(msg.sender, newTokenBalance);
        }

        // Pay gas with token
        super._payGasInToken(gasLimit);
        return true;
    }

}