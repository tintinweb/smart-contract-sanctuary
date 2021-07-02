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
 * @title ERTTokenDataV2.sol
 * @dev Data contract for Specific reward, vesting and account initialization fields
 */
contract ERTTokenDataV2 is DataOwned {

    // Specific field for vested tokens
    mapping (address => bool) internal initializedAccounts_;

    // Specific field for rewards balances
    mapping (address => uint256) internal rewards_;

    // Specific field for vested tokens
    mapping (address => uint256) internal vested_;

    constructor(address _proxyAddress, address _implementationAdress) public{
        proxy = _proxyAddress;
        implementation = _implementationAdress;
    }

    function() external {
        revert();
    }

    /**
     * @dev mark address as initialized
     * @param _target addres to mark as initialized
     */
    function setInitializedAccount(address _target) public onlyContracts {
        initializedAccounts_[_target] = true;
    }

    /**
     * @return true if the address has been already initialized before
     */
    function isInitializedAccount(address _target) public view returns(bool) {
        return initializedAccounts_[_target];
    }

    /**
     * @param _target addres to return its reward balance
     * @return reward balance of the given address
     */
    function rewardBalanceOf(address _target) public view returns(uint256) {
        return rewards_[_target];
    }

    /*
     * @dev Sets a reward balance for a given address
     * @param _target account address to change its reward balance
     * @param _balance new reward balance
     */
    function setRewardBalance(address _target, uint256 _balance) public onlyContracts {
        rewards_[_target] = _balance;
    }

    /**
     * @param _target addres to return its reward balance
     * @return reward balance of the given address
     */
    function vestingBalanceOf(address _target) public view returns(uint256) {
        return vested_[_target];
    }

    /*
     * @dev Sets a tokens balance for a given address
     * @param _target account address to change its balance
     * @param _balance new balance
     */
    function setVestingBalance(address _target, uint256 _balance) public onlyContracts {
        vested_[_target] = _balance;
    }

}