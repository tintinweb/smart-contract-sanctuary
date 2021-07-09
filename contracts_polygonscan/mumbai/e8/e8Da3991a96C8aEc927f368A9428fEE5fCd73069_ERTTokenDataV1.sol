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

import './DataOwned.sol';

/**
 * @title ERTTokenDataV1.sol
 * @dev Data contract for ERC20 attributes and some additional data. Those data will be shared
 * between all ERC20 implementations. So when upgrading ERC20 implementations, this data is reused
 * to conserve the data after each upgrade.
 */
contract ERTTokenDataV1 is DataOwned {

    // ERC20 tokens balances
    mapping (address => uint256) internal balances_;

    // ERC20 tokens allowance
    mapping (address => mapping (address => uint256)) internal allowed_;

    // ERC20 token name
    string internal name_;

    // ERC20 token symbol
    string internal symbol_;

    // ERC20 token total supply
    uint256 internal totalSupply_;

    // ERC20 token decimals
    uint8 internal decimals_;

    // Determines whether the ERC20 token attributes was initialized
    bool internal initialized_ = false;

    // Determines if the ERC20 Token is paused (for upgrade by example)
    bool internal paused_ = false;

    // Map of approved and disapproved accounts
    mapping (address => bool) internal approvedAccount_;

    // Map of admin addresses with habilitation level
    mapping (address => uint8) internal admin_;

    // Token sell price in WEI
    uint256 internal sellPrice_;

    constructor() public{
        // Make sure that all funds are sent to owner if it's not null
        uint256 balanceOfContract = address(this).balance;
        if (balanceOfContract > 0) {
            msg.sender.transfer(balanceOfContract);
        }
    }

    /**
     * @return true if the ERC20 token attributes was already initialized once
     */
    function initialized() public view returns(bool){
        return initialized_;
    }

    /**
     * @return ERC20 token name
     */
    function name() public view returns(string memory){
        return name_;
    }

    /**
     * @return ERC20 token symbol
     */
    function symbol() public view returns(string memory){
        return symbol_;
    }

    /**
     * @return ERC20 token decimals
     */
    function decimals() public view returns(uint8){
        return decimals_;
    }

    /**
     * @return ERC20 tokens total supply
     */
    function totalSupply() public view returns(uint256){
        return totalSupply_;
    }

    /**
     * @param _target addres to return its balance
     * @return ERC20 tokens balance of the given address
     */
    function balance(address _target) public view returns(uint256){
        return balances_[_target];
    }

    /**
     * @dev Get the allowed amount that an account can spend on behalf of another account
     * @param _account addres of tokens holders that can be spent
     * @param _spender addres of the account that can spend tokens
     * @return amount of allowed tokens to spend
     */
    function getAllowance(address _account, address _spender) public view returns (uint256){
        return allowed_[_account][_spender];
    }

    /**
     * @dev check if an account is approved
     * @param _target address of account to check
     * @return true if the account is approved
     */
    function isApprovedAccount(address _target) public view returns(bool){
        return approvedAccount_[_target];
    }

    /**
     * @return token sell price in WEI
     */
    function getSellPrice() public view returns(uint256){
        return sellPrice_;
    }

    /**
     * @dev the checked address has to have a level greater or equal to the required
     * level to return true
     * @param _target address of the account to check
     * @param _level habilitation level to check
     * @return true if the account has at minimum the required level of habilitation
     */
    function isAdmin(address _target, uint8 _level) public view returns(bool){
        return admin_[_target] >= _level;
    }

    /**
     * @dev return the habilitation level of an address
     * @param _target address of the account to check
     * @return habilitation level
     */
    function getAdminLevel(address _target) public view returns(uint8){
        return admin_[_target];
    }

    /**
     * @return true if ERC20 methods are frozen
     */
    function isPaused() public view returns (bool){
        return paused_;
    }

    /**
     * @dev set ERC20 token attributes as initialized
     */
    function setInitialized() public onlyContracts{
        initialized_ = true;
    }

    /**
     * @dev sets ERC20 methods frozen or unfrozen
     * @param _paused ERC20 methods pause status
     */
    function setPaused(bool _paused) public onlyContracts{
        paused_ = _paused;
    }

    /*
     * @param _name ERC20 token name
     */
    function setName(string memory _name) public onlyContracts{
        name_ = _name;
    }

    /*
     * @param _symbol ERC20 token symbol
     */
    function setSymbol(string memory _symbol) public onlyContracts{
        symbol_ = _symbol;
    }

    /*
     * @param _totalSupply ERC20 tokens total supply
     */
    function setTotalSupply(uint256 _totalSupply) public onlyContracts{
        totalSupply_ = _totalSupply;
    }

    /*
     * @dev Sets a tokens balance for a given address
     * @param _target account address to change its balance
     * @param _balance new balance
     */
    function setBalance(address _target, uint256 _balance) public onlyContracts{
        balances_[_target] = _balance;
    }

    /*
     * @dev Sets a token decimals for ERC20 tokens
     * @param _decimals number of deciamls with maximum value = 18
     */
    function setDecimals(uint8 _decimals) public onlyContracts{
        require(!initialized_);
        require(_decimals <= 18);
        decimals_ = _decimals;
    }

    /**
     * @dev Sets an amount of tokens that an account allows to another spender account
     * @param _account tokens holder address
     * @param _spender tokens spender address
     * @param _allowance allowed amount to spender to spend on behalf of the first given account
     */
    function setAllowance(address _account, address _spender, uint256 _allowance) public onlyContracts{
        allowed_[_account][_spender] = _allowance;
    }

    /**
     * @dev Approves or disapproves an account to use ERC20 methods
     * @param _target account to approve/disapprove
     * @param _approved if true then approve, else disapprove
     */
    function setApprovedAccount(address _target, bool _approved) public onlyContracts{
        approvedAccount_[_target] = _approved;
    }

    /**
     * @dev Sets token selling price in WEI
     * @param _value token selling price in WEI
     */
    function setSellPrice(uint256 _value) public onlyContracts{
        sellPrice_ = _value;
    }

    /**
     * @dev Sets an admin with an accreditation level. If level = 0, revoke account privileges.
     * @param _target account to set as admin
     * @param _level accreditation level
     */
    function setAdmin(address _target, uint8 _level) public onlyContracts{
        admin_[_target] = _level;
    }

    function() external {
        revert();
    }
}