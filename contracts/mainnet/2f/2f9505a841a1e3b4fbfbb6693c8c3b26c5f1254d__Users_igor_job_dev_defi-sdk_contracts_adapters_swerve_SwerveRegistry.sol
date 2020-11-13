// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.5;

import { Ownable } from "../../Ownable.sol";


struct PoolInfo {
    address swap;       // stableswap contract address.
    uint256 totalCoins; // Number of coins used in stableswap contract.
    string name;        // Pool name ("... Pool").
}


/**
 * @title Registry for Swerve contracts.
 * @dev Implements two getters - getSwapAndTotalCoins(address) and getName(address).
 * @notice Call getSwapAndTotalCoins(token) and getName(address) function and get address,
 * coins number, and name of stableswap contract for the given token address.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract SwerveRegistry is Ownable {

    mapping (address => PoolInfo) internal poolInfo;

    constructor() public {
        poolInfo[0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059] = PoolInfo({
            swap: 0x329239599afB305DA0A2eC69c58F8a6697F9F88d,
            totalCoins: 4,
            name: "swUSD Pool"
        });
    }

    function setPoolInfo(
        address token,
        address swap,
        uint256 totalCoins,
        string calldata name
    )
        external
        onlyOwner
    {
        poolInfo[token] = PoolInfo({
            swap: swap,
            totalCoins: totalCoins,
            name: name
        });
    }

    function getSwapAndTotalCoins(address token) external view returns (address, uint256) {
        return (poolInfo[token].swap, poolInfo[token].totalCoins);
    }

    function getName(address token) external view returns (string memory) {
        return poolInfo[token].name;
    }
}
