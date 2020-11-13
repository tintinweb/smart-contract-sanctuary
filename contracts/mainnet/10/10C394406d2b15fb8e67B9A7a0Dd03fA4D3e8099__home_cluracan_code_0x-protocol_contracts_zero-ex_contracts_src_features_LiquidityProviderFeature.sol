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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibLiquidityProviderRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibLiquidityProviderStorage.sol";
import "../vendor/v3/IERC20Bridge.sol";
import "./IFeature.sol";
import "./ILiquidityProviderFeature.sol";
import "./libs/LibTokenSpender.sol";


contract LiquidityProviderFeature is
    IFeature,
    ILiquidityProviderFeature,
    FixinCommon
{
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "LiquidityProviderFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev ETH pseudo-token address.
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH contract address.
    IEtherTokenV06 public immutable weth;

    /// @dev Store the WETH address in an immutable.
    /// @param weth_ The weth token.
    constructor(IEtherTokenV06 weth_)
        public
        FixinCommon()
    {
        weth = weth_;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.sellToLiquidityProvider.selector);
        _registerFeatureFunction(this.setLiquidityProviderForMarket.selector);
        _registerFeatureFunction(this.getLiquidityProviderForMarket.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    function sellToLiquidityProvider(
        address makerToken,
        address takerToken,
        address payable recipient,
        uint256 sellAmount,
        uint256 minBuyAmount
    )
        external
        override
        payable
        returns (uint256 boughtAmount)
    {
        address providerAddress = getLiquidityProviderForMarket(makerToken, takerToken);
        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        if (takerToken == ETH_TOKEN_ADDRESS) {
            // Wrap ETH.
            weth.deposit{value: sellAmount}();
            weth.transfer(providerAddress, sellAmount);
        } else {
            LibTokenSpender.spendERC20Tokens(
                IERC20TokenV06(takerToken),
                msg.sender,
                providerAddress,
                sellAmount
            );
        }

        if (makerToken == ETH_TOKEN_ADDRESS) {
            uint256 balanceBefore = weth.balanceOf(address(this));
            IERC20Bridge(providerAddress).bridgeTransferFrom(
                address(weth),
                address(0),
                address(this),
                minBuyAmount,
                ""
            );
            boughtAmount = weth.balanceOf(address(this)).safeSub(balanceBefore);
            // Unwrap wETH and send ETH to recipient.
            weth.withdraw(boughtAmount);
            recipient.transfer(boughtAmount);
        } else {
            uint256 balanceBefore = IERC20TokenV06(makerToken).balanceOf(recipient);
            IERC20Bridge(providerAddress).bridgeTransferFrom(
                makerToken,
                address(0),
                recipient,
                minBuyAmount,
                ""
            );
            boughtAmount = IERC20TokenV06(makerToken).balanceOf(recipient).safeSub(balanceBefore);
        }
        if (boughtAmount < minBuyAmount) {
            LibLiquidityProviderRichErrors.LiquidityProviderIncompleteSellError(
                providerAddress,
                makerToken,
                takerToken,
                sellAmount,
                boughtAmount,
                minBuyAmount
            ).rrevert();
        }
    }

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
        external
        override
        onlyOwner
    {
        LibLiquidityProviderStorage.getStorage()
            .addressBook[xAsset][yAsset] = providerAddress;
        LibLiquidityProviderStorage.getStorage()
            .addressBook[yAsset][xAsset] = providerAddress;
        emit LiquidityProviderForMarketUpdated(
            xAsset,
            yAsset,
            providerAddress
        );
    }

    /// @dev Returns the address of the liquidity provider for a market given
    ///     (xAsset, yAsset), or reverts if pool does not exist.
    /// @param xAsset First asset managed by the liquidity provider.
    /// @param yAsset Second asset managed by the liquidity provider.
    /// @return providerAddress Address of the liquidity provider.
    function getLiquidityProviderForMarket(
        address xAsset,
        address yAsset
    )
        public
        view
        override
        returns (address providerAddress)
    {
        if (xAsset == ETH_TOKEN_ADDRESS) {
            providerAddress = LibLiquidityProviderStorage.getStorage()
                .addressBook[address(weth)][yAsset];
        } else if (yAsset == ETH_TOKEN_ADDRESS) {
            providerAddress = LibLiquidityProviderStorage.getStorage()
                .addressBook[xAsset][address(weth)];
        } else {
            providerAddress = LibLiquidityProviderStorage.getStorage()
                .addressBook[xAsset][yAsset];
        }
        if (providerAddress == address(0)) {
            LibLiquidityProviderRichErrors.NoLiquidityProviderForMarketError(
                xAsset,
                yAsset
            ).rrevert();
        }
    }
}
