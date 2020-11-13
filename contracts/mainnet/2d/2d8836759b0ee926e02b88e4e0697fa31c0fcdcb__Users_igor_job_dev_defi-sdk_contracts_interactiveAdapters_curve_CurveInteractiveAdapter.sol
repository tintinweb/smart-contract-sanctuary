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

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { InteractiveAdapter } from "../InteractiveAdapter.sol";


/**
 * @title Interactive adapter for Curve protocol (base contract).
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
abstract contract CurveInteractiveAdapter is InteractiveAdapter {

    address internal constant C_SWAP = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address internal constant T_SWAP = 0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C;
    address internal constant Y_SWAP = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address internal constant B_SWAP = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address internal constant S_SWAP = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address internal constant P_SWAP = 0x06364f10B501e868329afBc005b3492902d6C763;
    address internal constant REN_SWAP = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address internal constant SBTC_SWAP = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;

    address internal constant C_DEPOSIT = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    address internal constant T_DEPOSIT = 0xac795D2c97e60DF6a99ff1c814727302fD747a80;
    address internal constant Y_DEPOSIT = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address internal constant B_DEPOSIT = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    address internal constant S_DEPOSIT = 0xFCBa3E75865d2d561BE8D220616520c171F12851;
    address internal constant P_DEPOSIT = 0xA50cCc70b6a011CffDdf45057E39679379187287;

    address internal constant C_CRV = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address internal constant T_CRV = 0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23;
    address internal constant Y_CRV = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address internal constant B_CRV = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address internal constant S_CRV = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address internal constant P_CRV = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;
    address internal constant REN_CRV = 0x7771F704490F9C0C3B06aFe8960dBB6c58CBC812;
    address internal constant SBTC_CRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;

    uint256 internal constant C_COINS = 2;
    uint256 internal constant T_COINS = 3;
    uint256 internal constant Y_COINS = 4;
    uint256 internal constant B_COINS = 4;
    uint256 internal constant S_COINS = 4;
    uint256 internal constant P_COINS = 4;
    uint256 internal constant REN_COINS = 2;
    uint256 internal constant SBTC_COINS = 3;

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

    function getTokenIndex(address token) internal pure returns (int128) {
        if (token == DAI || token == RENBTC) {
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

    function getSwap(address token) internal pure returns (address) {
        if (token == C_CRV) {
            return C_SWAP;
        } else if (token == T_CRV) {
            return T_SWAP;
        } else if (token == Y_CRV) {
            return Y_SWAP;
        } else if (token == B_CRV) {
            return B_SWAP;
        } else if (token == S_CRV) {
            return S_SWAP;
        } else if (token == P_CRV) {
            return P_SWAP;
        } else if (token == REN_CRV) {
            return REN_SWAP;
        } else if (token == SBTC_CRV) {
            return SBTC_SWAP;
        } else {
            revert("CIA: bad token");
        }
    }

    function getDeposit(address token) internal pure returns (address) {
        if (token == C_CRV) {
            return C_DEPOSIT;
        } else if (token == T_CRV) {
            return T_DEPOSIT;
        } else if (token == Y_CRV) {
            return Y_DEPOSIT;
        } else if (token == B_CRV) {
            return B_DEPOSIT;
        } else if (token == S_CRV) {
            return S_DEPOSIT;
        } else if (token == P_CRV) {
            return P_DEPOSIT;
        } else if (token == REN_CRV) {
            return REN_SWAP;
        } else if (token == SBTC_CRV) {
            return SBTC_SWAP;
        } else {
            revert("CIA: bad token");
        }
    }

    function getTotalCoins(address token) internal pure returns (uint256) {
        if (token == C_CRV) {
            return C_COINS;
        } else if (token == T_CRV) {
            return T_COINS;
        } else if (token == Y_CRV) {
            return Y_COINS;
        } else if (token == B_CRV) {
            return B_COINS;
        } else if (token == S_CRV) {
            return S_COINS;
        } else if (token == P_CRV) {
            return P_COINS;
        } else if (token == REN_CRV) {
            return REN_COINS;
        } else if (token == SBTC_CRV) {
            return SBTC_COINS;
        } else {
            revert("CIA: bad token");
        }
    }
}
