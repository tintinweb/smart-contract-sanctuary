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

pragma solidity 0.7.1;


/**
 * @dev yVault contract interface.
 * Only the functions required for YearnVaultAssetInteractiveAdapter contract are added.
 * The yVault contract is available here
 * github.com/iearn-finance/yearn-protocol/blob/develop/contracts/vaults/yVault.sol.
 */
interface YVault {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function token() view external returns (address);
}
