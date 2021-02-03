// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./IBridgeAdapter.sol";
import "./BridgeSource.sol";
import "./mixins/MixinBalancer.sol";
import "./mixins/MixinBancor.sol";
import "./mixins/MixinCoFiX.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCryptoCom.sol";
import "./mixins/MixinDodo.sol";
import "./mixins/MixinKyber.sol";
import "./mixins/MixinMooniswap.sol";
import "./mixins/MixinMStable.sol";
import "./mixins/MixinOasis.sol";
import "./mixins/MixinShell.sol";
import "./mixins/MixinSushiswap.sol";
import "./mixins/MixinUniswap.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinZeroExBridge.sol";

contract BridgeAdapter is
    IBridgeAdapter,
    MixinBalancer,
    MixinBancor,
    MixinCoFiX,
    MixinCurve,
    MixinCryptoCom,
    MixinDodo,
    MixinKyber,
    MixinMooniswap,
    MixinMStable,
    MixinOasis,
    MixinShell,
    MixinSushiswap,
    MixinUniswap,
    MixinUniswapV2,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth)
        public
        MixinBalancer()
        MixinBancor(weth)
        MixinCoFiX()
        MixinCurve()
        MixinCryptoCom()
        MixinDodo()
        MixinKyber(weth)
        MixinMooniswap(weth)
        MixinMStable()
        MixinOasis()
        MixinShell()
        MixinSushiswap()
        MixinUniswap(weth)
        MixinUniswapV2()
        MixinZeroExBridge()
    {}

    function trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount
    )
        public
        override
        returns (uint256 boughtAmount)
    {
        if (order.source == BridgeSource.CURVE ||
            order.source == BridgeSource.SWERVE ||
            order.source == BridgeSource.SNOWSWAP) {
            boughtAmount = _tradeCurve(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.SUSHISWAP) {
            boughtAmount = _tradeSushiswap(
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.UNISWAPV2) {
            boughtAmount = _tradeUniswapV2(
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.UNISWAP) {
            boughtAmount = _tradeUniswap(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.BALANCER ||
                   order.source == BridgeSource.CREAM) {
            boughtAmount = _tradeBalancer(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.KYBER) {
            boughtAmount = _tradeKyber(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.MOONISWAP) {
            boughtAmount = _tradeMooniswap(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.MSTABLE) {
            boughtAmount = _tradeMStable(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.OASIS) {
            boughtAmount = _tradeOasis(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.SHELL) {
            boughtAmount = _tradeShell(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.DODO) {
            boughtAmount = _tradeDodo(
                sellToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.CRYPTOCOM) {
            boughtAmount = _tradeCryptoCom(
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.BANCOR) {
            boughtAmount = _tradeBancor(
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else if (order.source == BridgeSource.COFIX) {
            boughtAmount = _tradeCoFiX(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        } else {
            boughtAmount = _tradeZeroExBridge(
                sellToken,
                buyToken,
                sellAmount,
                order.bridgeData
            );
        }

        emit BridgeFill(
            order.source,
            sellToken,
            buyToken,
            sellAmount,
            boughtAmount
        );
    }
}