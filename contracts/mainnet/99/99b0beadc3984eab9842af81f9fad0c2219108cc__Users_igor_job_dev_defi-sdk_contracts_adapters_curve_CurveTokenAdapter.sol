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

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../ERC20.sol";
import { TokenMetadata, Component } from "../../Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";

/**
 * @dev CurveRegistry contract interface.
 * Only the functions required for CurveTokenAdapter contract are added.
 * The CurveRegistry contract is available here
 * github.com/zeriontech/defi-sdk/blob/master/contracts/adapters/curve/CurveRegistry.sol.
 */
interface CurveRegistry {
    function getSwapAndTotalCoins(address) external view returns (address, uint256);
    function getName(address) external view returns (string memory);
}


/**
 * @dev stableswap contract interface.
 * Only the functions required for CurveTokenAdapter contract are added.
 * The stableswap contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/stableswap.vy.
 */
// solhint-disable-next-line contract-name-camelcase
interface stableswap {
    function coins(int128) external view returns (address);
    function coins(uint256) external view returns (address);
    function balances(int128) external view returns (uint256);
    function balances(uint256) external view returns (uint256);
}


/**
 * @title Token adapter for Curve pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract CurveTokenAdapter is TokenAdapter {

    address internal constant REGISTRY = 0x86A1755BA805ecc8B0608d56c22716bd1d4B68A8;

    address internal constant CDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant CUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address internal constant YDAIV2 = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
    address internal constant YUSDCV2 = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
    address internal constant YUSDTV2 = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
    address internal constant YTUSDV2 = 0x73a052500105205d34Daf004eAb301916DA8190f;
    address internal constant YDAIV3 = 0xC2cB1040220768554cf699b0d863A3cd4324ce32;
    address internal constant YUSDCV3 = 0x26EA744E5B887E5205727f55dFBE8685e3b21951;
    address internal constant YUSDTV3 = 0xE6354ed5bC4b393a5Aad09f21c46E101e692d447;
    address internal constant YBUSDV3 = 0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE;
    address internal constant YCDAI = 0x99d1Fa417f94dcD62BfE781a1213c092a47041Bc;
    address internal constant YCUSDC = 0x9777d7E2b60bB01759D0E2f8be2095df444cb07E;
    address internal constant YCUSDT = 0x1bE5d71F2dA660BFdee8012dDc58D024448A0A59;

    address internal constant C_CRV = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address internal constant T_CRV = 0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23;
    address internal constant Y_CRV = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address internal constant B_CRV = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address internal constant S_CRV = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address internal constant P_CRV = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;
    address internal constant RENBTC_CRV = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
    address internal constant SBTC_CRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        (address swap, uint256 totalCoins) = CurveRegistry(REGISTRY).getSwapAndTotalCoins(token);
        Component[] memory underlyingComponents= new Component[](totalCoins);

        address underlyingToken;
        if (token == C_CRV || token == T_CRV || token == Y_CRV || token == B_CRV ||
            token == S_CRV || token == P_CRV || token == RENBTC_CRV || token == SBTC_CRV) {
            for (uint256 i = 0; i < totalCoins; i++) {
                underlyingToken = stableswap(swap).coins(int128(i));
                underlyingComponents[i] = Component({
                    token: underlyingToken,
                    tokenType: getTokenType(underlyingToken),
                    rate: stableswap(swap).balances(int128(i)) * 1e18 / ERC20(token).totalSupply()
                });
            }
        } else {
            for (uint256 i = 0; i < totalCoins; i++) {
                underlyingToken = stableswap(swap).coins(i);
                underlyingComponents[i] = Component({
                    token: underlyingToken,
                    tokenType: getTokenType(underlyingToken),
                    rate: stableswap(swap).balances(i) * 1e18 / ERC20(token).totalSupply()
                });
            }
        }

        return underlyingComponents;
    }

    /**
     * @return Pool name.
     */
    function getPoolName(address token) internal view returns (string memory) {
        return CurveRegistry(REGISTRY).getName(token);
    }

    function getTokenType(address token) internal pure returns (string memory) {
        if (token == CDAI || token == CUSDC) {
            return "CToken";
        } else if (
            token == YDAIV2 ||
            token == YUSDCV2 ||
            token == YUSDTV2 ||
            token == YTUSDV2 ||
            token == YDAIV3 ||
            token == YUSDCV3 ||
            token == YUSDTV3 ||
            token == YBUSDV3 ||
            token == YCDAI ||
            token == YCUSDC ||
            token == YCUSDT
        ) {
            return "YToken";
        } else {
            return "ERC20";
        }
    }
}
