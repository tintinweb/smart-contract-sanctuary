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


/// @dev Feature to swap directly with an on-chain liquidity provider.
interface ILiquidityProviderFeature {
    event LiquidityProviderForMarketUpdated(
        address indexed xAsset,
        address indexed yAsset,
        address providerAddress
    );

    function sellToLiquidityProvider(
        address makerToken,
        address takerToken,
        address payable recipient,
        uint256 sellAmount,
        uint256 minBuyAmount
    )
        external
        payable
        returns (uint256 boughtAmount);

    /// @dev Sets address of the liquidity provider for a market given
    ///      (xAsset, yAsset).
    /// @param xAsset First asset managed by the liquidity provider.
    /// @param yAsset Second asset managed by the liquidity provider.
    /// @param providerAddress Address of the liquidity provider.
    function setLiquidityProviderForMarket(
        address xAsset,
        address yAsset,
        address providerAddress
    )
        external;

    /// @dev Returns the address of the liquidity provider for a market given
    ///     (xAsset, yAsset), or reverts if pool does not exist.
    /// @param xAsset First asset managed by the liquidity provider.
    /// @param yAsset Second asset managed by the liquidity provider.
    /// @return providerAddress Address of the liquidity provider.
    function getLiquidityProviderForMarket(
        address xAsset,
        address yAsset
    )
        external
        view
        returns (address providerAddress);
}
