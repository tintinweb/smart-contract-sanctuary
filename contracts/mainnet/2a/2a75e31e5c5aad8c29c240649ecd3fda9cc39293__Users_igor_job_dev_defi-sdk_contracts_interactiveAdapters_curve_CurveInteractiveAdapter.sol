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
pragma experimental ABIEncoderV2;

import { InteractiveAdapter } from "../InteractiveAdapter.sol";


/**
 * @title Interactive adapter for Curve protocol (base contract).
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
abstract contract CurveInteractiveAdapter is InteractiveAdapter {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address internal constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address internal constant PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address internal constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant SBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address internal constant HBTC = 0x0316EB71485b0Ab14103307bf65a021042c6d380;

    function getTokenIndex(address token) internal pure returns (int128) {
        if (token == DAI || token == RENBTC || token == HBTC) {
            return int128(0);
        } else if (token == USDC || token == WBTC) {
            return int128(1);
        } else if (token == USDT || token == SBTC) {
            return int128(2);
        } else if (token == TUSD || token == BUSD || token == SUSD || token == PAX) {
            return int128(3);
        } else {
            revert("CIA: bad token");
        }
    }
}
