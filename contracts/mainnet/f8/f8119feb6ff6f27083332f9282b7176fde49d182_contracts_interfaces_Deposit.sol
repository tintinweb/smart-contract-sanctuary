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

pragma solidity 0.7.3;

/**
 * @dev Deposit contract interface.
 * Only the functions required for CurveAssetInteractiveAdapter contract are added.
 * The Deposit contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/deposit.vy.
 */
interface Deposit {
    /* solhint-disable func-name-mixedcase */
    function add_liquidity(uint256[2] calldata, uint256) external;

    function add_liquidity(uint256[3] calldata, uint256) external;

    function add_liquidity(uint256[4] calldata, uint256) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
    /* solhint-enable func-name-mixedcase */
}
