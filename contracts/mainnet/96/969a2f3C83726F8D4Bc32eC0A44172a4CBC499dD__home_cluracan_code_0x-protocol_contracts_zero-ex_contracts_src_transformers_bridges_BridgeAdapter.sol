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

import "./mixins/MixinAdapterAddresses.sol";
import "./mixins/MixinBalancer.sol";
import "./mixins/MixinCurve.sol";
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
    MixinAdapterAddresses,
    MixinBalancer,
    MixinCurve,
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

    address private immutable BALANCER_BRIDGE_ADDRESS;
    address private immutable CREAM_BRIDGE_ADDRESS;
    address private immutable CURVE_BRIDGE_ADDRESS;
    address private immutable DODO_BRIDGE_ADDRESS;
    address private immutable KYBER_BRIDGE_ADDRESS;
    address private immutable MOONISWAP_BRIDGE_ADDRESS;
    address private immutable MSTABLE_BRIDGE_ADDRESS;
    address private immutable OASIS_BRIDGE_ADDRESS;
    address private immutable SHELL_BRIDGE_ADDRESS;
    address private immutable SNOW_SWAP_BRIDGE_ADDRESS;
    address private immutable SUSHISWAP_BRIDGE_ADDRESS;
    address private immutable SWERVE_BRIDGE_ADDRESS;
    address private immutable UNISWAP_BRIDGE_ADDRESS;
    address private immutable UNISWAP_V2_BRIDGE_ADDRESS;

    constructor(AdapterAddresses memory addresses)
        public
        MixinBalancer()
        MixinCurve()
        MixinDodo(addresses)
        MixinKyber(addresses)
        MixinMooniswap(addresses)
        MixinMStable(addresses)
        MixinOasis(addresses)
        MixinShell()
        MixinSushiswap(addresses)
        MixinUniswap(addresses)
        MixinUniswapV2(addresses)
        MixinZeroExBridge()
    {
        BALANCER_BRIDGE_ADDRESS = addresses.balancerBridge;
        CURVE_BRIDGE_ADDRESS = addresses.curveBridge;
        KYBER_BRIDGE_ADDRESS = addresses.kyberBridge;
        MOONISWAP_BRIDGE_ADDRESS = addresses.mooniswapBridge;
        MSTABLE_BRIDGE_ADDRESS = addresses.mStableBridge;
        OASIS_BRIDGE_ADDRESS = addresses.oasisBridge;
        SHELL_BRIDGE_ADDRESS = addresses.shellBridge;
        SUSHISWAP_BRIDGE_ADDRESS = addresses.sushiswapBridge;
        SWERVE_BRIDGE_ADDRESS = addresses.swerveBridge;
        UNISWAP_BRIDGE_ADDRESS = addresses.uniswapBridge;
        UNISWAP_V2_BRIDGE_ADDRESS = addresses.uniswapV2Bridge;
        CREAM_BRIDGE_ADDRESS = addresses.creamBridge;
        SNOW_SWAP_BRIDGE_ADDRESS = addresses.snowSwapBridge;
        DODO_BRIDGE_ADDRESS = addresses.dodoBridge;
    }

    function trade(
        bytes calldata makerAssetData,
        IERC20TokenV06 sellToken,
        uint256 sellAmount
    )
        external
        returns (uint256 boughtAmount)
    {
        (
            IERC20TokenV06 buyToken,
            address bridgeAddress,
            bytes memory bridgeData
        ) = abi.decode(
            makerAssetData[4:],
            (IERC20TokenV06, address, bytes)
        );
        require(
            bridgeAddress != address(this) && bridgeAddress != address(0),
            "BridgeAdapter/INVALID_BRIDGE_ADDRESS"
        );

        if (bridgeAddress == CURVE_BRIDGE_ADDRESS ||
            bridgeAddress == SWERVE_BRIDGE_ADDRESS ||
            bridgeAddress == SNOW_SWAP_BRIDGE_ADDRESS) {
            boughtAmount = _tradeCurve(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == SUSHISWAP_BRIDGE_ADDRESS) {
            boughtAmount = _tradeSushiswap(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == UNISWAP_V2_BRIDGE_ADDRESS) {
            boughtAmount = _tradeUniswapV2(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == UNISWAP_BRIDGE_ADDRESS) {
            boughtAmount = _tradeUniswap(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == BALANCER_BRIDGE_ADDRESS ||
                   bridgeAddress == CREAM_BRIDGE_ADDRESS) {
            boughtAmount = _tradeBalancer(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == KYBER_BRIDGE_ADDRESS) {
            boughtAmount = _tradeKyber(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == MOONISWAP_BRIDGE_ADDRESS) {
            boughtAmount = _tradeMooniswap(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == MSTABLE_BRIDGE_ADDRESS) {
            boughtAmount = _tradeMStable(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == OASIS_BRIDGE_ADDRESS) {
            boughtAmount = _tradeOasis(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == SHELL_BRIDGE_ADDRESS) {
            boughtAmount = _tradeShell(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else if (bridgeAddress == DODO_BRIDGE_ADDRESS) {
            boughtAmount = _tradeDodo(
                buyToken,
                sellAmount,
                bridgeData
            );
        } else {
            boughtAmount = _tradeZeroExBridge(
                bridgeAddress,
                sellToken,
                buyToken,
                sellAmount,
                bridgeData
            );
            // Old bridge contracts should emit an `ERC20BridgeTransfer` themselves,
            // otherwise an event will be emitted from `_tradeZeroExBridge`.
            return boughtAmount;
        }

        emit ERC20BridgeTransfer(
            sellToken,
            buyToken,
            sellAmount,
            boughtAmount,
            bridgeAddress,
            address(this)
        );
    }
}
