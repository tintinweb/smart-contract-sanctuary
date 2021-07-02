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

import "./TokenStorage.sol";
import "./Owned.sol";
import "./DataAccess.sol";
import "./Admin.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ApprouvableAccount.sol";
import "./ERC20Abstract.sol";
import "./FundCollection.sol";
import "./GasPayableInToken.sol";
import "./Upgradability.sol";

/**
 * @title ERTTokenV1.sol
 * @dev ERC20 Token implementation
 */
contract ERTTokenV1 is 
  TokenStorage,
  Owned,
  DataAccess,
  Admin,
  SafeMath,
  Pausable,
  ApprouvableAccount,
  ERC20Abstract,
  FundCollection,
  GasPayableInToken,
  Upgradability {

    constructor() public{
        // Pause contract to disallow using it directly without passing by proxy
        paused = true;
        // Make sure that all funds are sent to owner if it's not null
        uint256 balanceOfContract = address(this).balance;
        if (balanceOfContract > 0) {
            msg.sender.transfer(balanceOfContract);
        }
    }

    /**
     * @dev initialize the ERC20 Token attributes when it's the first time that we deploy the first version of contract.
     * Once deployed, this method couldn''t be called again and shouldn't be inherited from future versions of Token
     * contracts
     * @param _initialAmount initial amount of tokens
     * @param _tokenName ERC20 token name
     * @param _decimalUnits token decimals
     * @param _tokenSymbol ERC20 token symbol
     */
    function initialize(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) whenNotPaused public onlyOwner{
        require(!super.initialized());

        super.setName(_tokenName);
        super.setSymbol(_tokenSymbol);
        super._setDecimals(_decimalUnits);
        super._setTotalSupply(_initialAmount);

        super._setBalance(msg.sender, _initialAmount);
        // Default token price
        super.setSellPrice(2 finney);
        // Set owner as approved account
        super.approveAccount(msg.sender);

        super._setInitialized();
    }

    /**
     * @param _target The address from which the balance will be retrieved
     * @return the amount of balance of the address
     */
    function balanceOf(address _target) public view returns (uint256 balance){
        return super._balanceOf(_target);
    }

    /**
     * @param _target The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _target, address _spender) public view returns (uint256 remaining){
        return super._getAllowance(_target, _spender);
    }

    /**
     * @dev send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        uint256 gasLimit = gasleft();
        // The effective checks with modifiers and effective method implementation
        // is added to an internal method to retrieve gas before doing additional checks
        return _transferWithGas(gasLimit, _to, _value);
    }

    /**
     * @dev `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public returns (bool success){
        uint gasLimit = gasleft();
        // The effective checks with modifiers and effective method implementation
        // is added to an internal method to retrieve gas before doing additional checks
        return _approveWithGas(gasLimit, _spender, _value);
    }

    /**
     * @dev send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint gasLimit = gasleft();
        // The effective checks with modifiers and effective method implementation
        // is added to an internal method to retrieve gas before doing additional checks
        return _transferFromWithGas(gasLimit, _from, _to, _value);
    }

    function _transferWithGas(uint256 gasLimit, address _to, uint256 _value) internal whenNotPaused whenApproved(msg.sender) whenApproved(_to) returns (bool success){
        // Make sure that this is not about a fake transaction
        require(msg.sender != _to);
        if (super.isAdmin(msg.sender, 1)) {
            super.approveAccount(_to);
        }
        // This is to avoid calling this function with empty tokens transfer
        // If the user doesn't have enough ethers, he will simply reattempt with empty tokens
        require(super._transfer(msg.sender, _to, _value) == true);
        emit Transfer(msg.sender, _to, _value);
        super._payGasInToken(gasLimit);
        return true;
    }

    function _approveWithGas(uint256 gasLimit, address _spender, uint256 _value) internal whenNotPaused whenApproved(msg.sender) whenApproved(_spender) returns (bool success){
        // Make sure that this is not about a fake transaction
        require(msg.sender != _spender);
        require(super._balanceOf(msg.sender) >= _value);
        if (super.isAdmin(msg.sender, 1)) {
            super.approveAccount(_spender);
        }
        super._setAllowance(msg.sender, _spender,_value);
        emit Approval(msg.sender, _spender, _value);
        super._payGasInToken(gasLimit);
        return true;
    }

    function _transferFromWithGas(uint256 gasLimit, address _from, address _to, uint256 _value) internal whenNotPaused whenApproved(msg.sender) whenApproved(_to) whenApproved(_from) returns (bool success){
        require(super._balanceOf(_from) >= _value);
        uint256 _allowance = super._getAllowance(_from, msg.sender);
        require(_allowance >= _value);
        super._setAllowance(_from, msg.sender, super.safeSubtract(_allowance, _value));
        if (super.isAdmin(msg.sender, 1)) {
            super.approveAccount(_to);
        }
        require(super._transfer(_from, _to, _value) == true);
        emit Transfer(_from, _to, _value);
        super._payGasInToken(gasLimit);
        return true;
    }

}