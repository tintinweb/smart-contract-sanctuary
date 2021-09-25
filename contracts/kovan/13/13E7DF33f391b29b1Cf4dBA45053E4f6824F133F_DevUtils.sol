/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetData.sol";
import "@0x/contracts-exchange/contracts/src/interfaces/IExchange.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";


// solhint-disable no-empty-blocks
contract Addresses is
    DeploymentConstants
{
    address public exchangeAddress;
    address public erc20ProxyAddress;
    address public erc721ProxyAddress;
    address public erc1155ProxyAddress;
    address public staticCallProxyAddress;
    address public chaiBridgeAddress;
    address public dydxBridgeAddress;

    constructor (
        address exchange_,
        address chaiBridge_,
        address dydxBridge_
    )
        public
    {
        exchangeAddress = exchange_;
        chaiBridgeAddress = chaiBridge_;
        dydxBridgeAddress = dydxBridge_;
        erc20ProxyAddress = IExchange(exchange_).getAssetProxy(IAssetData(address(0)).ERC20Token.selector);
        erc721ProxyAddress = IExchange(exchange_).getAssetProxy(IAssetData(address(0)).ERC721Token.selector);
        erc1155ProxyAddress = IExchange(exchange_).getAssetProxy(IAssetData(address(0)).ERC1155Assets.selector);
        staticCallProxyAddress = IExchange(exchange_).getAssetProxy(IAssetData(address(0)).StaticCall.selector);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetData.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetProxy.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-erc721/contracts/src/interfaces/IERC721Token.sol";
import "@0x/contracts-erc1155/contracts/src/interfaces/IERC1155.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IChai.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibMath.sol";
import "./Addresses.sol";
import "./LibDydxBalance.sol";


contract AssetBalance is
    Addresses
{
    // 2^256 - 1
    uint256 constant internal _MAX_UINT256 = uint256(-1);

    using LibBytes for bytes;

    /// @dev Returns the owner's balance of the assets(s) specified in
    /// assetData.  When the asset data contains multiple assets (eg in
    /// ERC1155 or Multi-Asset), the return value indicates how many
    /// complete "baskets" of those assets are owned by owner.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Details of asset, encoded per the AssetProxy contract specification.
    /// @return Number of assets (or asset baskets) held by owner.
    function getBalance(address ownerAddress, bytes memory assetData)
        public
        returns (uint256 balance)
    {
        // Get id of AssetProxy contract
        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
            // Get ERC20 token address
            address tokenAddress = assetData.readAddress(16);
            balance = LibERC20Token.balanceOf(tokenAddress, ownerAddress);

        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {
            // Get ERC721 token address and id
            (, address tokenAddress, uint256 tokenId) = LibAssetData.decodeERC721AssetData(assetData);

            // Check if id is owned by ownerAddress
            bytes memory ownerOfCalldata = abi.encodeWithSelector(
                IERC721Token(address(0)).ownerOf.selector,
                tokenId
            );

            (bool success, bytes memory returnData) = tokenAddress.staticcall(ownerOfCalldata);
            address currentOwnerAddress = (success && returnData.length == 32) ? returnData.readAddress(12) : address(0);
            balance = currentOwnerAddress == ownerAddress ? 1 : 0;

        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {
            // Get ERC1155 token address, array of ids, and array of values
            (, address tokenAddress, uint256[] memory tokenIds, uint256[] memory tokenValues,) = LibAssetData.decodeERC1155AssetData(assetData);

            uint256 length = tokenIds.length;
            for (uint256 i = 0; i != length; i++) {
                // Skip over the token if the corresponding value is 0.
                if (tokenValues[i] == 0) {
                    continue;
                }

                // Encode data for `balanceOf(ownerAddress, tokenIds[i])
                bytes memory balanceOfData = abi.encodeWithSelector(
                    IERC1155(address(0)).balanceOf.selector,
                    ownerAddress,
                    tokenIds[i]
                );

                // Query balance
                (bool success, bytes memory returnData) = tokenAddress.staticcall(balanceOfData);
                uint256 totalBalance = success && returnData.length == 32 ? returnData.readUint256(0) : 0;

                // Scale total balance down by corresponding value in assetData
                uint256 scaledBalance = totalBalance / tokenValues[i];
                if (scaledBalance == 0) {
                    return 0;
                }
                if (scaledBalance < balance || balance == 0) {
                    balance = scaledBalance;
                }
            }

        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {
            // Encode data for `staticCallProxy.transferFrom(assetData,...)`
            bytes memory transferFromData = abi.encodeWithSelector(
                IAssetProxy(address(0)).transferFrom.selector,
                assetData,
                address(0),  // `from` address is not used
                address(0),  // `to` address is not used
                0            // `amount` is not used
            );

            // Check if staticcall would be successful
            (bool success,) = staticCallProxyAddress.staticcall(transferFromData);

            // Success means that the staticcall can be made an unlimited amount of times
            balance = success ? _MAX_UINT256 : 0;

        } else if (assetProxyId == IAssetData(address(0)).ERC20Bridge.selector) {
            // Get address of ERC20 token and bridge contract
            (, address tokenAddress, address bridgeAddress, ) = LibAssetData.decodeERC20BridgeAssetData(assetData);
            if (tokenAddress == _getDaiAddress() && bridgeAddress == chaiBridgeAddress) {
                uint256 chaiBalance = LibERC20Token.balanceOf(_getChaiAddress(), ownerAddress);
                // Calculate Dai balance
                balance = _convertChaiToDaiAmount(chaiBalance);
            }
            // Balance will be 0 if bridge is not supported

        } else if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {
            // Get array of values and array of assetDatas
            (, uint256[] memory assetAmounts, bytes[] memory nestedAssetData) = LibAssetData.decodeMultiAssetData(assetData);

            uint256 length = nestedAssetData.length;
            for (uint256 i = 0; i != length; i++) {
                // Skip over the asset if the corresponding amount is 0.
                if (assetAmounts[i] == 0) {
                    continue;
                }

                // Query balance of individual assetData
                uint256 totalBalance = getBalance(ownerAddress, nestedAssetData[i]);

                // Scale total balance down by corresponding value in assetData
                uint256 scaledBalance = totalBalance / assetAmounts[i];
                if (scaledBalance == 0) {
                    return 0;
                }
                if (scaledBalance < balance || balance == 0) {
                    balance = scaledBalance;
                }
            }
        }

        // Balance will be 0 if assetProxyId is unknown
        return balance;
    }

    /// @dev Calls getBalance() for each element of assetData.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Array of asset details, each encoded per the AssetProxy contract specification.
    /// @return Array of asset balances from getBalance(), with each element
    /// corresponding to the same-indexed element in the assetData input.
    function getBatchBalances(address ownerAddress, bytes[] memory assetData)
        public
        returns (uint256[] memory balances)
    {
        uint256 length = assetData.length;
        balances = new uint256[](length);
        for (uint256 i = 0; i != length; i++) {
            balances[i] = getBalance(ownerAddress, assetData[i]);
        }
        return balances;
    }

    /// @dev Returns the number of asset(s) (described by assetData) that
    /// the corresponding AssetProxy contract is authorized to spend.  When the asset data contains
    /// multiple assets (eg for Multi-Asset), the return value indicates
    /// how many complete "baskets" of those assets may be spent by all of the corresponding
    /// AssetProxy contracts.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Details of asset, encoded per the AssetProxy contract specification.
    /// @return Number of assets (or asset baskets) that the corresponding AssetProxy is authorized to spend.
    function getAssetProxyAllowance(address ownerAddress, bytes memory assetData)
        public
        returns (uint256 allowance)
    {
        // Get id of AssetProxy contract
        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {
            // Get array of values and array of assetDatas
            (, uint256[] memory amounts, bytes[] memory nestedAssetData) = LibAssetData.decodeMultiAssetData(assetData);

            uint256 length = nestedAssetData.length;
            for (uint256 i = 0; i != length; i++) {
                // Skip over the asset if the corresponding amount is 0.
                if (amounts[i] == 0) {
                    continue;
                }

                // Query allowance of individual assetData
                uint256 totalAllowance = getAssetProxyAllowance(ownerAddress, nestedAssetData[i]);

                // Scale total allowance down by corresponding value in assetData
                uint256 scaledAllowance = totalAllowance / amounts[i];
                if (scaledAllowance == 0) {
                    return 0;
                }
                if (scaledAllowance < allowance || allowance == 0) {
                    allowance = scaledAllowance;
                }
            }
            return allowance;
        }

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
            // Get ERC20 token address
            address tokenAddress = assetData.readAddress(16);
            allowance = LibERC20Token.allowance(tokenAddress, ownerAddress, erc20ProxyAddress);

        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {
            // Get ERC721 token address and id
            (, address tokenAddress, uint256 tokenId) = LibAssetData.decodeERC721AssetData(assetData);

            // Encode data for `isApprovedForAll(ownerAddress, erc721ProxyAddress)`
            bytes memory isApprovedForAllData = abi.encodeWithSelector(
                IERC721Token(address(0)).isApprovedForAll.selector,
                ownerAddress,
                erc721ProxyAddress
            );

            (bool success, bytes memory returnData) = tokenAddress.staticcall(isApprovedForAllData);

            // If not approved for all, call `getApproved(tokenId)`
            if (!success || returnData.length != 32 || returnData.readUint256(0) != 1) {
                // Encode data for `getApproved(tokenId)`
                bytes memory getApprovedData = abi.encodeWithSelector(IERC721Token(address(0)).getApproved.selector, tokenId);
                (success, returnData) = tokenAddress.staticcall(getApprovedData);

                // Allowance is 1 if successful and the approved address is the ERC721Proxy
                allowance = success && returnData.length == 32 && returnData.readAddress(12) == erc721ProxyAddress ? 1 : 0;
            } else {
                // Allowance is 2^256 - 1 if `isApprovedForAll` returned true
                allowance = _MAX_UINT256;
            }

        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {
            // Get ERC1155 token address
            (, address tokenAddress, , , ) = LibAssetData.decodeERC1155AssetData(assetData);

            // Encode data for `isApprovedForAll(ownerAddress, erc1155ProxyAddress)`
            bytes memory isApprovedForAllData = abi.encodeWithSelector(
                IERC1155(address(0)).isApprovedForAll.selector,
                ownerAddress,
                erc1155ProxyAddress
            );

            // Query allowance
            (bool success, bytes memory returnData) = tokenAddress.staticcall(isApprovedForAllData);
            allowance = success && returnData.length == 32 && returnData.readUint256(0) == 1 ? _MAX_UINT256 : 0;

        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {
            // The StaticCallProxy does not require any approvals
            allowance = _MAX_UINT256;

        } else if (assetProxyId == IAssetData(address(0)).ERC20Bridge.selector) {
            // Get address of ERC20 token and bridge contract
            (, address tokenAddress, address bridgeAddress,) =
                LibAssetData.decodeERC20BridgeAssetData(assetData);
            if (tokenAddress == _getDaiAddress() && bridgeAddress == chaiBridgeAddress) {
                uint256 chaiAllowance = LibERC20Token.allowance(_getChaiAddress(), ownerAddress, chaiBridgeAddress);
                // Dai allowance is unlimited if Chai allowance is unlimited
                allowance = chaiAllowance == _MAX_UINT256 ? _MAX_UINT256 : _convertChaiToDaiAmount(chaiAllowance);
            } else if (bridgeAddress == dydxBridgeAddress) {
                allowance = LibDydxBalance.getDydxMakerAllowance(ownerAddress, bridgeAddress, _getDydxAddress());
            }
            // Allowance will be 0 if bridge is not supported
        }

        // Allowance will be 0 if the assetProxyId is unknown
        return allowance;
    }

    /// @dev Calls getAssetProxyAllowance() for each element of assetData.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Array of asset details, each encoded per the AssetProxy contract specification.
    /// @return An array of asset allowances from getAllowance(), with each
    /// element corresponding to the same-indexed element in the assetData input.
    function getBatchAssetProxyAllowances(address ownerAddress, bytes[] memory assetData)
        public
        returns (uint256[] memory allowances)
    {
        uint256 length = assetData.length;
        allowances = new uint256[](length);
        for (uint256 i = 0; i != length; i++) {
            allowances[i] = getAssetProxyAllowance(ownerAddress, assetData[i]);
        }
        return allowances;
    }

    /// @dev Calls getBalance() and getAllowance() for assetData.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Details of asset, encoded per the AssetProxy contract specification.
    /// @return Number of assets (or asset baskets) held by owner, and number
    /// of assets (or asset baskets) that the corresponding AssetProxy is authorized to spend.
    function getBalanceAndAssetProxyAllowance(
        address ownerAddress,
        bytes memory assetData
    )
        public
        returns (uint256 balance, uint256 allowance)
    {
        balance = getBalance(ownerAddress, assetData);
        allowance = getAssetProxyAllowance(ownerAddress, assetData);
        return (balance, allowance);
    }

    /// @dev Calls getBatchBalances() and getBatchAllowances() for each element of assetData.
    /// @param ownerAddress Owner of the assets specified by assetData.
    /// @param assetData Array of asset details, each encoded per the AssetProxy contract specification.
    /// @return An array of asset balances from getBalance(), and an array of
    /// asset allowances from getAllowance(), with each element
    /// corresponding to the same-indexed element in the assetData input.
    function getBatchBalancesAndAssetProxyAllowances(
        address ownerAddress,
        bytes[] memory assetData
    )
        public
        returns (uint256[] memory balances, uint256[] memory allowances)
    {
        balances = getBatchBalances(ownerAddress, assetData);
        allowances = getBatchAssetProxyAllowances(ownerAddress, assetData);
        return (balances, allowances);
    }

    /// @dev Converts an amount of Chai into its equivalent Dai amount.
    ///      Also accumulates Dai from DSR if called after the last time it was collected.
    /// @param chaiAmount Amount of Chai to converts.
    function _convertChaiToDaiAmount(uint256 chaiAmount)
        internal
        returns (uint256 daiAmount)
    {
        PotLike pot = IChai(_getChaiAddress()).pot();
        // Accumulate savings if called after last time savings were collected
        // solhint-disable-next-line not-rely-on-time
        uint256 chiMultiplier = (now > pot.rho())
            ? pot.drip()
            : pot.chi();
        daiAmount = LibMath.getPartialAmountFloor(chiMultiplier, 10**27, chaiAmount);
        return daiAmount;
    }

    /// @dev Returns an order MAKER's balance of the assets(s) specified in
    ///      makerAssetData. Unlike `getBalanceAndAssetProxyAllowance()`, this
    ///      can handle maker asset types that depend on taker tokens being
    ///      transferred to the maker first.
    /// @param order The order.
    /// @return balance Quantity of assets transferrable from maker to taker.
    function _getConvertibleMakerBalanceAndAssetProxyAllowance(
        LibOrder.Order memory order
    )
        internal
        returns (uint256 balance, uint256 allowance)
    {
        if (order.makerAssetData.length < 4) {
            return (0, 0);
        }
        bytes4 assetProxyId = order.makerAssetData.readBytes4(0);
        // Handle dydx bridge assets.
        if (assetProxyId == IAssetData(address(0)).ERC20Bridge.selector) {
            (, , address bridgeAddress, ) = LibAssetData.decodeERC20BridgeAssetData(order.makerAssetData);
            if (bridgeAddress == dydxBridgeAddress) {
                return (
                    LibDydxBalance.getDydxMakerBalance(order, _getDydxAddress()),
                    getAssetProxyAllowance(order.makerAddress, order.makerAssetData)
                );
            }
        }
        return (
            getBalance(order.makerAddress, order.makerAssetData),
            getAssetProxyAllowance(order.makerAddress, order.makerAssetData)
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibEIP712ExchangeDomain.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibZeroExTransaction.sol";
import "@0x/contracts-utils/contracts/src/LibEIP712.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "./Addresses.sol";
import "./OrderValidationUtils.sol";
import "./EthBalanceChecker.sol";
import "./ExternalFunctions.sol";


// solhint-disable no-empty-blocks
contract DevUtils is
    Addresses,
    OrderValidationUtils,
    LibEIP712ExchangeDomain,
    EthBalanceChecker,
    ExternalFunctions
{
    constructor (
        address exchange_,
        address chaiBridge_,
        address dydxBridge_
    )
        public
        Addresses(
            exchange_,
            chaiBridge_,
            dydxBridge_
        )
        LibEIP712ExchangeDomain(uint256(0), address(0)) // null args because because we only use constants
    {}

    function getOrderHash(
        LibOrder.Order memory order,
        uint256 chainId,
        address exchange
    )
        public
        pure
        returns (bytes32 orderHash)
    {
        return LibOrder.getTypedDataHash(
            order,
            LibEIP712.hashEIP712Domain(_EIP712_EXCHANGE_DOMAIN_NAME, _EIP712_EXCHANGE_DOMAIN_VERSION, chainId, exchange)
        );
    }

    function getTransactionHash(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        uint256 chainId,
        address exchange
    )
        public
        pure
        returns (bytes32 transactionHash)
    {
        return LibZeroExTransaction.getTypedDataHash(
            transaction,
            LibEIP712.hashEIP712Domain(_EIP712_EXCHANGE_DOMAIN_NAME, _EIP712_EXCHANGE_DOMAIN_VERSION, chainId, exchange)
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;


contract EthBalanceChecker {

    /// @dev Batch fetches ETH balances
    /// @param addresses Array of addresses.
    /// @return Array of ETH balances.
    function getEthBalances(address[] memory addresses)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i != addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }

}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Addresses.sol";
import "./LibAssetData.sol";
import "./LibTransactionDecoder.sol";
import "./LibOrderTransferSimulation.sol";


contract ExternalFunctions is
    Addresses
{

    /// @dev Decodes the call data for an Exchange contract method call.
    /// @param transactionData ABI-encoded calldata for an Exchange
    ///     contract method call.
    /// @return The name of the function called, and the parameters it was
    ///     given.  For single-order fills and cancels, the arrays will have
    ///     just one element.
    function decodeZeroExTransactionData(bytes memory transactionData)
        public
        pure
        returns(
            string memory functionName,
            LibOrder.Order[] memory orders,
            uint256[] memory takerAssetFillAmounts,
            bytes[] memory signatures
        )
    {
        return LibTransactionDecoder.decodeZeroExTransactionData(transactionData);
    }

    /// @dev Decode AssetProxy identifier
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20, ERC-721, ERC1155, or MultiAsset asset.
    /// @return The AssetProxy identifier
    function decodeAssetProxyId(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId
        )
    {
        return LibAssetData.decodeAssetProxyId(assetData);
    }

    /// @dev Encode ERC-20 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-20 contract hosting the asset to be traded.
    /// @return AssetProxy-compliant data describing the asset.
    function encodeERC20AssetData(address tokenAddress)
        public
        pure
        returns (bytes memory assetData)
    {
        return LibAssetData.encodeERC20AssetData(tokenAddress);
    }

    /// @dev Decode ERC-20 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20 asset.
    /// @return The AssetProxy identifier, and the address of the ERC-20
    /// contract hosting this asset.
    function decodeERC20AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress
        )
    {
        return LibAssetData.decodeERC20AssetData(assetData);
    }

    /// @dev Encode ERC-721 asset data into the format described in the AssetProxy specification.
    /// @param tokenAddress The address of the ERC-721 contract hosting the asset to be traded.
    /// @param tokenId The identifier of the specific asset to be traded.
    /// @return AssetProxy-compliant asset data describing the asset.
    function encodeERC721AssetData(address tokenAddress, uint256 tokenId)
        public
        pure
        returns (bytes memory assetData)
    {
        return LibAssetData.encodeERC721AssetData(tokenAddress, tokenId);
    }

    /// @dev Decode ERC-721 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-721 asset.
    /// @return The ERC-721 AssetProxy identifier, the address of the ERC-721
    /// contract hosting this asset, and the identifier of the specific
    /// asset to be traded.
    function decodeERC721AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256 tokenId
        )
    {
        return LibAssetData.decodeERC721AssetData(assetData);
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-1155 contract hosting the asset(s) to be traded.
    /// @param tokenIds The identifiers of the specific assets to be traded.
    /// @param tokenValues The amounts of each asset to be traded.
    /// @param callbackData Data to be passed to receiving contracts when a transfer is performed.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeERC1155AssetData(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenValues,
        bytes memory callbackData
    )
        public
        pure
        returns (bytes memory assetData)
    {
        return LibAssetData.encodeERC1155AssetData(
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
    }

    /// @dev Decode ERC-1155 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-1155 set of assets.
    /// @return The ERC-1155 AssetProxy identifier, the address of the ERC-1155
    /// contract hosting the assets, an array of the identifiers of the
    /// assets to be traded, an array of asset amounts to be traded, and
    /// callback data.  Each element of the arrays corresponds to the
    /// same-indexed element of the other array.  Return values specified as
    /// `memory` are returned as pointers to locations within the memory of
    /// the input parameter `assetData`.
    function decodeERC1155AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256[] memory tokenIds,
            uint256[] memory tokenValues,
            bytes memory callbackData
        )
    {
        return LibAssetData.decodeERC1155AssetData(assetData);
    }

    /// @dev Encode data for multiple assets, per the AssetProxy contract specification.
    /// @param amounts The amounts of each asset to be traded.
    /// @param nestedAssetData AssetProxy-compliant data describing each asset to be traded.
    /// @return AssetProxy-compliant data describing the set of assets.
    function encodeMultiAssetData(uint256[] memory amounts, bytes[] memory nestedAssetData)
        public
        pure
        returns (bytes memory assetData)
    {
        return LibAssetData.encodeMultiAssetData(amounts, nestedAssetData);
    }

    /// @dev Decode multi-asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant data describing a multi-asset basket.
    /// @return The Multi-Asset AssetProxy identifier, an array of the amounts
    /// of the assets to be traded, and an array of the
    /// AssetProxy-compliant data describing each asset to be traded.  Each
    /// element of the arrays corresponds to the same-indexed element of the other array.
    function decodeMultiAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            uint256[] memory amounts,
            bytes[] memory nestedAssetData
        )
    {
        return LibAssetData.decodeMultiAssetData(assetData);
    }

    /// @dev Encode StaticCall asset data into the format described in the AssetProxy contract specification.
    /// @param staticCallTargetAddress Target address of StaticCall.
    /// @param staticCallData Data that will be passed to staticCallTargetAddress in the StaticCall.
    /// @param expectedReturnDataHash Expected Keccak-256 hash of the StaticCall return data.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeStaticCallAssetData(
        address staticCallTargetAddress,
        bytes memory staticCallData,
        bytes32 expectedReturnDataHash
    )
        public
        pure
        returns (bytes memory assetData)
    {
        return LibAssetData.encodeStaticCallAssetData(
            staticCallTargetAddress,
            staticCallData,
            expectedReturnDataHash
        );
    }

    /// @dev Decode StaticCall asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing a StaticCall asset
    /// @return The StaticCall AssetProxy identifier, the target address of the StaticCAll, the data to be
    /// passed to the target address, and the expected Keccak-256 hash of the static call return data.
    function decodeStaticCallAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address staticCallTargetAddress,
            bytes memory staticCallData,
            bytes32 expectedReturnDataHash
        )
    {
        return LibAssetData.decodeStaticCallAssetData(assetData);
    }

    /// @dev Decode ERC20Bridge asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC20Bridge asset
    /// @return The ERC20BridgeProxy identifier, the address of the ERC20 token to transfer, the address
    /// of the bridge contract, and extra data to be passed to the bridge contract.
    function decodeERC20BridgeAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            address bridgeAddress,
            bytes memory bridgeData
        )
    {
        return LibAssetData.decodeERC20BridgeAssetData(assetData);
    }

    /// @dev Reverts if assetData is not of a valid format for its given proxy id.
    /// @param assetData AssetProxy compliant asset data.
    function revertIfInvalidAssetData(bytes memory assetData)
        public
        pure
    {
        return LibAssetData.revertIfInvalidAssetData(assetData);
    }

    /// @dev Simulates the maker transfers within an order and returns the index of the first failed transfer.
    /// @param order The order to simulate transfers for.
    /// @param takerAddress The address of the taker that will fill the order.
    /// @param takerAssetFillAmount The amount of takerAsset that the taker wished to fill.
    /// @return The index of the first failed transfer (or 4 if all transfers are successful).
    function getSimulatedOrderMakerTransferResults(
        LibOrder.Order memory order,
        address takerAddress,
        uint256 takerAssetFillAmount
    )
        public
        returns (LibOrderTransferSimulation.OrderTransferResults orderTransferResults)
    {
        return LibOrderTransferSimulation.getSimulatedOrderMakerTransferResults(
            exchangeAddress,
            order,
            takerAddress,
            takerAssetFillAmount
        );
    }

    /// @dev Simulates all of the transfers within an order and returns the index of the first failed transfer.
    /// @param order The order to simulate transfers for.
    /// @param takerAddress The address of the taker that will fill the order.
    /// @param takerAssetFillAmount The amount of takerAsset that the taker wished to fill.
    /// @return The index of the first failed transfer (or 4 if all transfers are successful).
    function getSimulatedOrderTransferResults(
        LibOrder.Order memory order,
        address takerAddress,
        uint256 takerAssetFillAmount
    )
        public
        returns (LibOrderTransferSimulation.OrderTransferResults orderTransferResults)
    {
        return LibOrderTransferSimulation.getSimulatedOrderTransferResults(
            exchangeAddress,
            order,
            takerAddress,
            takerAssetFillAmount
        );
    }

    /// @dev Simulates all of the transfers for each given order and returns the indices of each first failed transfer.
    /// @param orders Array of orders to individually simulate transfers for.
    /// @param takerAddresses Array of addresses of takers that will fill each order.
    /// @param takerAssetFillAmounts Array of amounts of takerAsset that will be filled for each order.
    /// @return The indices of the first failed transfer (or 4 if all transfers are successful) for each order.
    function getSimulatedOrdersTransferResults(
        LibOrder.Order[] memory orders,
        address[] memory takerAddresses,
        uint256[] memory takerAssetFillAmounts
    )
        public
        returns (LibOrderTransferSimulation.OrderTransferResults[] memory orderTransferResults)
    {
        return LibOrderTransferSimulation.getSimulatedOrdersTransferResults(
            exchangeAddress,
            orders,
            takerAddresses,
            takerAssetFillAmounts
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetData.sol";


library LibAssetData {

    using LibBytes for bytes;

    /// @dev Decode AssetProxy identifier
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20, ERC-721, ERC1155, or MultiAsset asset.
    /// @return The AssetProxy identifier
    function decodeAssetProxyId(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Token.selector ||
            assetProxyId == IAssetData(address(0)).ERC721Token.selector ||
            assetProxyId == IAssetData(address(0)).ERC1155Assets.selector ||
            assetProxyId == IAssetData(address(0)).MultiAsset.selector ||
            assetProxyId == IAssetData(address(0)).StaticCall.selector,
            "WRONG_PROXY_ID"
        );
        return assetProxyId;
    }

    /// @dev Encode ERC-20 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-20 contract hosting the asset to be traded.
    /// @return AssetProxy-compliant data describing the asset.
    function encodeERC20AssetData(address tokenAddress)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(IAssetData(address(0)).ERC20Token.selector, tokenAddress);
        return assetData;
    }

    /// @dev Decode ERC-20 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20 asset.
    /// @return The AssetProxy identifier, and the address of the ERC-20
    /// contract hosting this asset.
    function decodeERC20AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        return (assetProxyId, tokenAddress);
    }

    /// @dev Encode ERC-721 asset data into the format described in the AssetProxy specification.
    /// @param tokenAddress The address of the ERC-721 contract hosting the asset to be traded.
    /// @param tokenId The identifier of the specific asset to be traded.
    /// @return AssetProxy-compliant asset data describing the asset.
    function encodeERC721AssetData(address tokenAddress, uint256 tokenId)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC721Token.selector,
            tokenAddress,
            tokenId
        );
        return assetData;
    }

    /// @dev Decode ERC-721 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-721 asset.
    /// @return The ERC-721 AssetProxy identifier, the address of the ERC-721
    /// contract hosting this asset, and the identifier of the specific
    /// asset to be traded.
    function decodeERC721AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256 tokenId
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC721Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        tokenId = assetData.readUint256(36);
        return (assetProxyId, tokenAddress, tokenId);
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-1155 contract hosting the asset(s) to be traded.
    /// @param tokenIds The identifiers of the specific assets to be traded.
    /// @param tokenValues The amounts of each asset to be traded.
    /// @param callbackData Data to be passed to receiving contracts when a transfer is performed.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeERC1155AssetData(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenValues,
        bytes memory callbackData
    )
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC1155Assets.selector,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
        return assetData;
    }

    /// @dev Decode ERC-1155 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-1155 set of assets.
    /// @return The ERC-1155 AssetProxy identifier, the address of the ERC-1155
    /// contract hosting the assets, an array of the identifiers of the
    /// assets to be traded, an array of asset amounts to be traded, and
    /// callback data.  Each element of the arrays corresponds to the
    /// same-indexed element of the other array.  Return values specified as
    /// `memory` are returned as pointers to locations within the memory of
    /// the input parameter `assetData`.
    function decodeERC1155AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256[] memory tokenIds,
            uint256[] memory tokenValues,
            bytes memory callbackData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC1155Assets.selector,
            "WRONG_PROXY_ID"
        );

        assembly {
            // Skip selector and length to get to the first parameter:
            assetData := add(assetData, 36)
            // Read the value of the first parameter:
            tokenAddress := mload(assetData)
            // Point to the next parameter's data:
            tokenIds := add(assetData, mload(add(assetData, 32)))
            // Point to the next parameter's data:
            tokenValues := add(assetData, mload(add(assetData, 64)))
            // Point to the next parameter's data:
            callbackData := add(assetData, mload(add(assetData, 96)))
        }

        return (
            assetProxyId,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
    }

    /// @dev Encode data for multiple assets, per the AssetProxy contract specification.
    /// @param amounts The amounts of each asset to be traded.
    /// @param nestedAssetData AssetProxy-compliant data describing each asset to be traded.
    /// @return AssetProxy-compliant data describing the set of assets.
    function encodeMultiAssetData(uint256[] memory amounts, bytes[] memory nestedAssetData)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).MultiAsset.selector,
            amounts,
            nestedAssetData
        );
        return assetData;
    }

    /// @dev Decode multi-asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant data describing a multi-asset basket.
    /// @return The Multi-Asset AssetProxy identifier, an array of the amounts
    /// of the assets to be traded, and an array of the
    /// AssetProxy-compliant data describing each asset to be traded.  Each
    /// element of the arrays corresponds to the same-indexed element of the other array.
    function decodeMultiAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            uint256[] memory amounts,
            bytes[] memory nestedAssetData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).MultiAsset.selector,
            "WRONG_PROXY_ID"
        );

        // solhint-disable indent
        (amounts, nestedAssetData) = abi.decode(
            assetData.slice(4, assetData.length),
            (uint256[], bytes[])
        );
        // solhint-enable indent
    }

    /// @dev Encode StaticCall asset data into the format described in the AssetProxy contract specification.
    /// @param staticCallTargetAddress Target address of StaticCall.
    /// @param staticCallData Data that will be passed to staticCallTargetAddress in the StaticCall.
    /// @param expectedReturnDataHash Expected Keccak-256 hash of the StaticCall return data.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeStaticCallAssetData(
        address staticCallTargetAddress,
        bytes memory staticCallData,
        bytes32 expectedReturnDataHash
    )
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).StaticCall.selector,
            staticCallTargetAddress,
            staticCallData,
            expectedReturnDataHash
        );
        return assetData;
    }

    /// @dev Decode StaticCall asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing a StaticCall asset
    /// @return The StaticCall AssetProxy identifier, the target address of the StaticCAll, the data to be
    /// passed to the target address, and the expected Keccak-256 hash of the static call return data.
    function decodeStaticCallAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address staticCallTargetAddress,
            bytes memory staticCallData,
            bytes32 expectedReturnDataHash
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).StaticCall.selector,
            "WRONG_PROXY_ID"
        );

        (staticCallTargetAddress, staticCallData, expectedReturnDataHash) = abi.decode(
            assetData.slice(4, assetData.length),
            (address, bytes, bytes32)
        );
    }

    /// @dev Decode ERC20Bridge asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC20Bridge asset
    /// @return The ERC20BridgeProxy identifier, the address of the ERC20 token to transfer, the address
    /// of the bridge contract, and extra data to be passed to the bridge contract.
    function decodeERC20BridgeAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            address bridgeAddress,
            bytes memory bridgeData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Bridge.selector,
            "WRONG_PROXY_ID"
        );

        (tokenAddress, bridgeAddress, bridgeData) = abi.decode(
            assetData.slice(4, assetData.length),
            (address, address, bytes)
        );
    }

    /// @dev Reverts if assetData is not of a valid format for its given proxy id.
    /// @param assetData AssetProxy compliant asset data.
    function revertIfInvalidAssetData(bytes memory assetData)
        public
        pure
    {
        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
            decodeERC20AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {
            decodeERC721AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {
            decodeERC1155AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {
            decodeMultiAssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {
            decodeStaticCallAssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).ERC20Bridge.selector) {
            decodeERC20BridgeAssetData(assetData);
        } else {
            revert("WRONG_PROXY_ID");
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetData.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IDydxBridge.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IDydx.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/D18.sol";
import "./LibAssetData.sol";


library LibDydxBalance {

    using LibBytes for bytes;
    using LibSafeMath for uint256;

    /// @dev Padding % added to the minimum collateralization ratio to
    ///      prevent withdrawing exactly the amount that would make an account
    ///      insolvent. 1 bps.
    int256 private constant MARGIN_RATIO_PADDING = 0.0001e18;

    /// @dev Structure that holds all pertinent info needed to perform a balance
    ///      check.
    struct BalanceCheckInfo {
        IDydx dydx;
        address bridgeAddress;
        address makerAddress;
        address makerTokenAddress;
        address takerTokenAddress;
        int256 orderMakerToTakerRate;
        uint256[] accounts;
        IDydxBridge.BridgeAction[] actions;
    }

    /// @dev Gets the maker asset allowance for a Dydx bridge order.
    /// @param makerAddress The maker of the order.
    /// @param bridgeAddress The address of the Dydx bridge.
    /// @param dydx The Dydx contract address.
    /// @return allowance The maker asset allowance.
    function getDydxMakerAllowance(address makerAddress, address bridgeAddress, address dydx)
        public
        view
        returns (uint256 allowance)
    {
        // Allowance is infinite if the dydx bridge is an operator for the maker.
        return IDydx(dydx).getIsLocalOperator(makerAddress, bridgeAddress)
            ? uint256(-1) : 0;
    }

    /// @dev Gets the maker allowance for a
    /// @dev Get the maker asset balance of an order with a `DydxBridge` maker asset.
    /// @param order An order with a dydx maker asset.
    /// @param dydx The address of the dydx contract.
    /// @return balance The maker asset balance.
    function getDydxMakerBalance(LibOrder.Order memory order, address dydx)
        public
        view
        returns (uint256 balance)
    {
        BalanceCheckInfo memory info = _getBalanceCheckInfo(order, dydx);
        // Actions must be well-formed.
        if (!_areActionsWellFormed(info)) {
            return 0;
        }
        // If the rate we withdraw maker tokens is less than one, the asset
        // proxy will throw because we will always transfer less maker tokens
        // than asked.
        if (_getMakerTokenWithdrawRate(info) < D18.one()) {
            return 0;
        }
        // The maker balance is the smaller of:
        return LibSafeMath.min256(
            // How many times we can execute all the deposit actions.
            _getDepositableMakerAmount(info),
            // How many times we can execute all the actions before the an
            // account becomes undercollateralized.
            _getSolventMakerAmount(info)
        );
    }

    /// @dev Checks that:
    ///      1. Actions are arranged as [...deposits, withdraw].
    ///      2. There is only one deposit for each market ID.
    ///      3. Every action has a valid account index.
    ///      4. There is exactly one withdraw at the end and it is for the
    ///         maker token.
    /// @param info State from `_getBalanceCheckInfo()`.
    /// @return areWellFormed Whether the actions are well-formed.
    function _areActionsWellFormed(BalanceCheckInfo memory info)
        internal
        view
        returns (bool areWellFormed)
    {
        if (info.actions.length == 0) {
            return false;
        }
        uint256 depositCount = 0;
        // Count the number of deposits.
        for (; depositCount < info.actions.length; ++depositCount) {
            IDydxBridge.BridgeAction memory action = info.actions[depositCount];
            if (action.actionType != IDydxBridge.BridgeActionType.Deposit) {
                break;
            }
            // Search all prior actions for the same market ID.
            uint256 marketId = action.marketId;
            for (uint256 j = 0; j < depositCount; ++j) {
                if (info.actions[j].marketId == marketId) {
                    // Market ID is not unique.
                    return false;
                }
            }
            // Check that the account index is within the valid range.
            if (action.accountIdx >= info.accounts.length) {
                return false;
            }
        }
        // There must be exactly one withdraw action at the end.
        if (depositCount + 1 != info.actions.length) {
            return false;
        }
        IDydxBridge.BridgeAction memory withdraw = info.actions[depositCount];
        if (withdraw.actionType != IDydxBridge.BridgeActionType.Withdraw) {
            return false;
        }
        // And it must be for the maker token.
        if (info.dydx.getMarketTokenAddress(withdraw.marketId) != info.makerTokenAddress) {
            return false;
        }
        // Check the account index.
        return withdraw.accountIdx < info.accounts.length;
    }

    /// @dev Returns the rate at which we withdraw maker tokens.
    /// @param info State from `_getBalanceCheckInfo()`.
    /// @return makerTokenWithdrawRate Maker token withdraw rate.
    function _getMakerTokenWithdrawRate(BalanceCheckInfo memory info)
        internal
        pure
        returns (int256 makerTokenWithdrawRate)
    {
        // The last action is always a withdraw for the maker token.
        IDydxBridge.BridgeAction memory withdraw = info.actions[info.actions.length - 1];
        return _getActionRate(withdraw);
    }

    /// @dev Get how much maker asset we can transfer before a deposit fails.
    /// @param info State from `_getBalanceCheckInfo()`.
    function _getDepositableMakerAmount(BalanceCheckInfo memory info)
        internal
        view
        returns (uint256 depositableMakerAmount)
    {
        depositableMakerAmount = uint256(-1);
        // Take the minimum maker amount from all deposits.
        for (uint256 i = 0; i < info.actions.length; ++i) {
            IDydxBridge.BridgeAction memory action = info.actions[i];
            // Only looking at deposit actions.
            if (action.actionType != IDydxBridge.BridgeActionType.Deposit) {
                continue;
            }
            // `depositRate` is the rate at which we convert a maker token into
            // a taker token for deposit.
            int256 depositRate = _getActionRate(action);
            // Taker tokens will be transferred to the maker for every fill, so
            // we reduce the effective deposit rate if we're depositing the taker
            // token.
            address depositToken = info.dydx.getMarketTokenAddress(action.marketId);
            if (info.takerTokenAddress != address(0) && depositToken == info.takerTokenAddress) {
                depositRate = D18.sub(depositRate, info.orderMakerToTakerRate);
            }
            // If the deposit rate is > 0, we are limited by the transferrable
            // token balance of the maker.
            if (depositRate > 0) {
                uint256 supply = _getTransferabeTokenAmount(
                    depositToken,
                    info.makerAddress,
                    address(info.dydx)
                );
                depositableMakerAmount = LibSafeMath.min256(
                    depositableMakerAmount,
                    uint256(D18.div(supply, depositRate))
                );
            }
        }
    }

    /// @dev Get how much maker asset we can transfer before an account
    ///      becomes insolvent.
    /// @param info State from `_getBalanceCheckInfo()`.
    function _getSolventMakerAmount(BalanceCheckInfo memory info)
        internal
        view
        returns (uint256 solventMakerAmount)
    {
        solventMakerAmount = uint256(-1);
        assert(info.actions.length >= 1);
        IDydxBridge.BridgeAction memory withdraw = info.actions[info.actions.length - 1];
        assert(withdraw.actionType == IDydxBridge.BridgeActionType.Withdraw);
        int256 minCr = D18.add(_getMinimumCollateralizationRatio(info.dydx), MARGIN_RATIO_PADDING);
        // Loop through the accounts.
        for (uint256 accountIdx = 0; accountIdx < info.accounts.length; ++accountIdx) {
            (uint256 supplyValue, uint256 borrowValue) =
                _getAccountMarketValues(info, info.accounts[accountIdx]);
            // All accounts must currently be solvent.
            if (borrowValue != 0 && D18.div(supplyValue, borrowValue) < minCr) {
                return 0;
            }
            // If this is the same account used to in the withdraw/borrow action,
            // compute the maker amount at which it will become insolvent.
            if (accountIdx != withdraw.accountIdx) {
                continue;
            }
            // Compute the deposit/collateralization rate, which is the rate at
            // which (USD) value is added to the account across all markets.
            int256 dd = 0;
            for (uint256 i = 0; i < info.actions.length - 1; ++i) {
                IDydxBridge.BridgeAction memory deposit = info.actions[i];
                assert(deposit.actionType == IDydxBridge.BridgeActionType.Deposit);
                if (deposit.accountIdx == accountIdx) {
                    dd = D18.add(
                        dd,
                        _getActionRateValue(
                            info,
                            deposit
                        )
                    );
                }
            }
            // Compute the borrow/withdraw rate, which is the rate at which
            // (USD) value is deducted from the account.
            int256 db = _getActionRateValue(
                info,
                withdraw
            );
            // If the deposit to withdraw ratio is >= the minimum collateralization
            // ratio, then we will never become insolvent at these prices.
            if (D18.div(dd, db) >= minCr) {
                continue;
            }
            // If the adjusted deposit rates are equal, the account will remain
            // at the same level of collateralization.
            if (D18.mul(minCr, db) == dd) {
                continue;
            }
            // The collateralization ratio for this account, parameterized by
            // `t` (maker amount), is given by:
            //      `cr = (supplyValue + t * dd) / (borrowValue + t * db)`
            // Solving for `t` gives us:
            //      `t = (supplyValue - cr * borrowValue) / (cr * db - dd)`
            int256 t = D18.div(
                D18.sub(supplyValue, D18.mul(minCr, borrowValue)),
                D18.sub(D18.mul(minCr, db), dd)
            );
            solventMakerAmount = LibSafeMath.min256(
                solventMakerAmount,
                // `t` is in maker token units, so convert it to maker wei.
                _toWei(info.makerTokenAddress, uint256(D18.clip(t)))
            );
        }
    }

    /// @dev Create a `BalanceCheckInfo` struct.
    /// @param order An order with a `DydxBridge` maker asset.
    /// @param dydx The address of the Dydx contract.
    /// @return info The `BalanceCheckInfo` struct.
    function _getBalanceCheckInfo(LibOrder.Order memory order, address dydx)
        private
        pure
        returns (BalanceCheckInfo memory info)
    {
        bytes memory rawBridgeData;
        (, info.makerTokenAddress, info.bridgeAddress, rawBridgeData) =
            LibAssetData.decodeERC20BridgeAssetData(order.makerAssetData);
        info.dydx = IDydx(dydx);
        info.makerAddress = order.makerAddress;
        if (order.takerAssetData.length == 36) {
            if (order.takerAssetData.readBytes4(0) == IAssetData(0).ERC20Token.selector) {
                (, info.takerTokenAddress) =
                    LibAssetData.decodeERC20AssetData(order.takerAssetData);
            }
        }
        info.orderMakerToTakerRate = D18.div(order.takerAssetAmount, order.makerAssetAmount);
        (IDydxBridge.BridgeData memory bridgeData) =
            abi.decode(rawBridgeData, (IDydxBridge.BridgeData));
        info.accounts = bridgeData.accountNumbers;
        info.actions = bridgeData.actions;
    }

    /// @dev Returns the conversion rate for an action.
    /// @param action A `BridgeAction`.
    function _getActionRate(IDydxBridge.BridgeAction memory action)
        private
        pure
        returns (int256 rate)
    {
        rate = action.conversionRateDenominator == 0
            ? D18.one()
            : D18.div(
                action.conversionRateNumerator,
                action.conversionRateDenominator
            );
    }

    /// @dev Returns the USD value of an action based on its conversion rate
    ///      and market prices.
    /// @param info State from `_getBalanceCheckInfo()`.
    /// @param action A `BridgeAction`.
    function _getActionRateValue(
        BalanceCheckInfo memory info,
        IDydxBridge.BridgeAction memory action
    )
        private
        view
        returns (int256 value)
    {
        address toToken = info.dydx.getMarketTokenAddress(action.marketId);
        uint256 fromTokenDecimals = LibERC20Token.decimals(info.makerTokenAddress);
        uint256 toTokenDecimals = LibERC20Token.decimals(toToken);
        // First express the rate as 18-decimal units.
        value = toTokenDecimals > fromTokenDecimals
            ? int256(
                uint256(_getActionRate(action))
                    .safeDiv(10 ** (toTokenDecimals - fromTokenDecimals))
            )
            : int256(
                uint256(_getActionRate(action))
                    .safeMul(10 ** (fromTokenDecimals - toTokenDecimals))
            );
        // Prices have 18 + (18 - TOKEN_DECIMALS) decimal places because
        // consistency is stupid.
        uint256 price = info.dydx.getMarketPrice(action.marketId).value;
        // Make prices have 18 decimals.
        if (toTokenDecimals > 18) {
            price = price.safeMul(10 ** (toTokenDecimals - 18));
        } else {
            price = price.safeDiv(10 ** (18 - toTokenDecimals));
        }
        // The action value is the action rate times the price.
        value = D18.mul(price, value);
        // Scale by the market premium.
        int256 marketPremium = D18.add(
            D18.one(),
            info.dydx.getMarketMarginPremium(action.marketId).value
        );
        if (action.actionType == IDydxBridge.BridgeActionType.Deposit) {
            value = D18.div(value, marketPremium);
        } else {
            value = D18.mul(value, marketPremium);
        }
    }

    /// @dev Convert a `D18` fraction of 1 token to the equivalent integer wei.
    /// @param token Address the of the token.
    /// @param units Token units expressed with 18 digit precision.
    function _toWei(address token, uint256 units)
        private
        view
        returns (uint256 rate)
    {
        uint256 decimals = LibERC20Token.decimals(token);
        rate = decimals > 18
            ? units.safeMul(10 ** (decimals - 18))
            : units.safeDiv(10 ** (18 - decimals));
    }

    /// @dev Get the global minimum collateralization ratio required for
    ///      an account to be considered solvent.
    /// @param dydx The Dydx interface.
    function _getMinimumCollateralizationRatio(IDydx dydx)
        private
        view
        returns (int256 ratio)
    {
        IDydx.RiskParams memory riskParams = dydx.getRiskParams();
        return D18.add(D18.one(), D18.toSigned(riskParams.marginRatio.value));
    }

    /// @dev Get the total supply and borrow values for an account across all markets.
    /// @param info State from `_getBalanceCheckInfo()`.
    /// @param account The Dydx account identifier.
    function _getAccountMarketValues(BalanceCheckInfo memory info, uint256 account)
        private
        view
        returns (uint256 supplyValue, uint256 borrowValue)
    {
        (IDydx.Value memory supplyValue_, IDydx.Value memory borrowValue_) =
            info.dydx.getAdjustedAccountValues(IDydx.AccountInfo(
                info.makerAddress,
                account
            ));
        // Account values have 36 decimal places because dydx likes to make sure
        // you're paying attention.
        return (supplyValue_.value / 1e18, borrowValue_.value / 1e18);
    }

    /// @dev Get the amount of an ERC20 token held by `owner` that can be transferred
    ///      by `spender`.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param owner The address of the token holder.
    /// @param spender The address of the token spender.
    function _getTransferabeTokenAmount(
        address tokenAddress,
        address owner,
        address spender
    )
        private
        view
        returns (uint256 transferableAmount)
    {
        return LibSafeMath.min256(
            LibERC20Token.allowance(tokenAddress, owner, spender),
            LibERC20Token.balanceOf(tokenAddress, owner)
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


import "@0x/contracts-exchange/contracts/src/interfaces/IExchange.sol";
import "@0x/contracts-exchange/contracts/src/libs/LibExchangeRichErrorDecoder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibExchangeRichErrors.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibFillResults.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";


library LibOrderTransferSimulation {
    using LibBytes for bytes;

    enum OrderTransferResults {
        TakerAssetDataFailed,     // Transfer of takerAsset failed
        MakerAssetDataFailed,     // Transfer of makerAsset failed
        TakerFeeAssetDataFailed,  // Transfer of takerFeeAsset failed
        MakerFeeAssetDataFailed,  // Transfer of makerFeeAsset failed
        TransfersSuccessful       // All transfers in the order were successful
    }

    // NOTE(jalextowle): This is a random address that we use to avoid issues that addresses like `address(1)`
    // may cause later.
    address constant internal UNUSED_ADDRESS = address(0x377f698C4c287018D09b516F415317aEC5919332);

    // keccak256(abi.encodeWithSignature("Error(string)", "TRANSFERS_SUCCESSFUL"));
    bytes32 constant internal _TRANSFERS_SUCCESSFUL_RESULT_HASH = 0xf43f26ea5a94b478394a975e856464913dc1a8a1ca70939d974aa7c238aa0ce0;

    /// @dev Simulates the maker transfers within an order and returns the index of the first failed transfer.
    /// @param order The order to simulate transfers for.
    /// @param takerAddress The address of the taker that will fill the order.
    /// @param takerAssetFillAmount The amount of takerAsset that the taker wished to fill.
    /// @return The index of the first failed transfer (or 4 if all transfers are successful).
    function getSimulatedOrderMakerTransferResults(
        address exchange,
        LibOrder.Order memory order,
        address takerAddress,
        uint256 takerAssetFillAmount
    )
        public
        returns (OrderTransferResults orderTransferResults)
    {
        LibFillResults.FillResults memory fillResults = LibFillResults.calculateFillResults(
            order,
            takerAssetFillAmount,
            IExchange(exchange).protocolFeeMultiplier(),
            tx.gasprice
        );

        bytes[] memory assetData = new bytes[](2);
        address[] memory fromAddresses = new address[](2);
        address[] memory toAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        // Transfer `makerAsset` from maker to taker
        assetData[0] = order.makerAssetData;
        fromAddresses[0] = order.makerAddress;
        toAddresses[0] = takerAddress == address(0) ? UNUSED_ADDRESS : takerAddress;
        amounts[0] = fillResults.makerAssetFilledAmount;

        // Transfer `makerFeeAsset` from maker to feeRecipient
        assetData[1] = order.makerFeeAssetData;
        fromAddresses[1] = order.makerAddress;
        toAddresses[1] = order.feeRecipientAddress == address(0) ? UNUSED_ADDRESS : order.feeRecipientAddress;
        amounts[1] = fillResults.makerFeePaid;

        return _simulateTransferFromCalls(
            exchange,
            assetData,
            fromAddresses,
            toAddresses,
            amounts
        );
    }

    /// @dev Simulates all of the transfers within an order and returns the index of the first failed transfer.
    /// @param order The order to simulate transfers for.
    /// @param takerAddress The address of the taker that will fill the order.
    /// @param takerAssetFillAmount The amount of takerAsset that the taker wished to fill.
    /// @return The index of the first failed transfer (or 4 if all transfers are successful).
    function getSimulatedOrderTransferResults(
        address exchange,
        LibOrder.Order memory order,
        address takerAddress,
        uint256 takerAssetFillAmount
    )
        public
        returns (OrderTransferResults orderTransferResults)
    {
        LibFillResults.FillResults memory fillResults = LibFillResults.calculateFillResults(
            order,
            takerAssetFillAmount,
            IExchange(exchange).protocolFeeMultiplier(),
            tx.gasprice
        );

        // Create input arrays
        bytes[] memory assetData = new bytes[](4);
        address[] memory fromAddresses = new address[](4);
        address[] memory toAddresses = new address[](4);
        uint256[] memory amounts = new uint256[](4);

        // Transfer `takerAsset` from taker to maker
        assetData[0] = order.takerAssetData;
        fromAddresses[0] = takerAddress;
        toAddresses[0] = order.makerAddress;
        amounts[0] = takerAssetFillAmount;

        // Transfer `makerAsset` from maker to taker
        assetData[1] = order.makerAssetData;
        fromAddresses[1] = order.makerAddress;
        toAddresses[1] = takerAddress == address(0) ? UNUSED_ADDRESS : takerAddress;
        amounts[1] = fillResults.makerAssetFilledAmount;

        // Transfer `takerFeeAsset` from taker to feeRecipient
        assetData[2] = order.takerFeeAssetData;
        fromAddresses[2] = takerAddress;
        toAddresses[2] = order.feeRecipientAddress == address(0) ? UNUSED_ADDRESS : order.feeRecipientAddress;
        amounts[2] = fillResults.takerFeePaid;

        // Transfer `makerFeeAsset` from maker to feeRecipient
        assetData[3] = order.makerFeeAssetData;
        fromAddresses[3] = order.makerAddress;
        toAddresses[3] = order.feeRecipientAddress == address(0) ? UNUSED_ADDRESS : order.feeRecipientAddress;
        amounts[3] = fillResults.makerFeePaid;

        return _simulateTransferFromCalls(
            exchange,
            assetData,
            fromAddresses,
            toAddresses,
            amounts
        );
    }

    /// @dev Simulates all of the transfers for each given order and returns the indices of each first failed transfer.
    /// @param orders Array of orders to individually simulate transfers for.
    /// @param takerAddresses Array of addresses of takers that will fill each order.
    /// @param takerAssetFillAmounts Array of amounts of takerAsset that will be filled for each order.
    /// @return The indices of the first failed transfer (or 4 if all transfers are successful) for each order.
    function getSimulatedOrdersTransferResults(
        address exchange,
        LibOrder.Order[] memory orders,
        address[] memory takerAddresses,
        uint256[] memory takerAssetFillAmounts
    )
        public
        returns (OrderTransferResults[] memory orderTransferResults)
    {
        uint256 length = orders.length;
        orderTransferResults = new OrderTransferResults[](length);
        for (uint256 i = 0; i != length; i++) {
            orderTransferResults[i] = getSimulatedOrderTransferResults(
                exchange,
                orders[i],
                takerAddresses[i],
                takerAssetFillAmounts[i]
            );
        }
        return orderTransferResults;
    }

    /// @dev Makes the simulation call with information about the transfers and processes
    ///      the returndata.
    /// @param assetData The assetdata to use to make transfers.
    /// @param fromAddresses The addresses to transfer funds.
    /// @param toAddresses The addresses that will receive funds
    /// @param amounts The amounts involved in the transfer.
    function _simulateTransferFromCalls(
        address exchange,
        bytes[] memory assetData,
        address[] memory fromAddresses,
        address[] memory toAddresses,
        uint256[] memory amounts
    )
        private
        returns (OrderTransferResults orderTransferResults)
    {
        // Encode data for `simulateDispatchTransferFromCalls(assetData, fromAddresses, toAddresses, amounts)`
        bytes memory simulateDispatchTransferFromCallsData = abi.encodeWithSelector(
            IExchange(address(0)).simulateDispatchTransferFromCalls.selector,
            assetData,
            fromAddresses,
            toAddresses,
            amounts
        );

        // Perform call and catch revert
        (, bytes memory returnData) = address(exchange).call(simulateDispatchTransferFromCallsData);

        bytes4 selector = returnData.readBytes4(0);
        if (selector == LibExchangeRichErrors.AssetProxyDispatchErrorSelector()) {
            // Decode AssetProxyDispatchError and return index of failed transfer
            (, bytes32 failedTransferIndex,) = LibExchangeRichErrorDecoder.decodeAssetProxyDispatchError(returnData);
            return OrderTransferResults(uint8(uint256(failedTransferIndex)));
        } else if (selector == LibExchangeRichErrors.AssetProxyTransferErrorSelector()) {
            // Decode AssetProxyTransferError and return index of failed transfer
            (bytes32 failedTransferIndex, ,) = LibExchangeRichErrorDecoder.decodeAssetProxyTransferError(returnData);
            return OrderTransferResults(uint8(uint256(failedTransferIndex)));
        } else if (keccak256(returnData) == _TRANSFERS_SUCCESSFUL_RESULT_HASH) {
            // All transfers were successful
            return OrderTransferResults.TransfersSuccessful;
        } else {
            revert("UNKNOWN_RETURN_DATA");
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange/contracts/src/interfaces/IExchange.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";


library LibTransactionDecoder {

    using LibBytes for bytes;

    /// @dev Decodes the call data for an Exchange contract method call.
    /// @param transactionData ABI-encoded calldata for an Exchange
    ///     contract method call.
    /// @return The name of the function called, and the parameters it was
    ///     given.  For single-order fills and cancels, the arrays will have
    ///     just one element.
    function decodeZeroExTransactionData(bytes memory transactionData)
        public
        pure
        returns(
            string memory functionName,
            LibOrder.Order[] memory orders,
            uint256[] memory takerAssetFillAmounts,
            bytes[] memory signatures
        )
    {
        bytes4 functionSelector = transactionData.readBytes4(0);

        if (functionSelector == IExchange(address(0)).batchCancelOrders.selector) {
            functionName = "batchCancelOrders";
        } else if (functionSelector == IExchange(address(0)).batchFillOrders.selector) {
            functionName = "batchFillOrders";
        } else if (functionSelector == IExchange(address(0)).batchFillOrdersNoThrow.selector) {
            functionName = "batchFillOrdersNoThrow";
        } else if (functionSelector == IExchange(address(0)).batchFillOrKillOrders.selector) {
            functionName = "batchFillOrKillOrders";
        } else if (functionSelector == IExchange(address(0)).cancelOrder.selector) {
            functionName = "cancelOrder";
        } else if (functionSelector == IExchange(address(0)).fillOrder.selector) {
            functionName = "fillOrder";
        } else if (functionSelector == IExchange(address(0)).fillOrKillOrder.selector) {
            functionName = "fillOrKillOrder";
        } else if (functionSelector == IExchange(address(0)).marketBuyOrdersNoThrow.selector) {
            functionName = "marketBuyOrdersNoThrow";
        } else if (functionSelector == IExchange(address(0)).marketSellOrdersNoThrow.selector) {
            functionName = "marketSellOrdersNoThrow";
        } else if (functionSelector == IExchange(address(0)).marketBuyOrdersFillOrKill.selector) {
            functionName = "marketBuyOrdersFillOrKill";
        } else if (functionSelector == IExchange(address(0)).marketSellOrdersFillOrKill.selector) {
            functionName = "marketSellOrdersFillOrKill";
        } else if (functionSelector == IExchange(address(0)).matchOrders.selector) {
            functionName = "matchOrders";
        } else if (
            functionSelector == IExchange(address(0)).cancelOrdersUpTo.selector ||
            functionSelector == IExchange(address(0)).executeTransaction.selector
        ) {
            revert("UNIMPLEMENTED");
        } else {
            revert("UNKNOWN_FUNCTION_SELECTOR");
        }

        if (functionSelector == IExchange(address(0)).batchCancelOrders.selector) {
            // solhint-disable-next-line indent
            orders = abi.decode(transactionData.slice(4, transactionData.length), (LibOrder.Order[]));
            takerAssetFillAmounts = new uint256[](0);
            signatures = new bytes[](0);
        } else if (
            functionSelector == IExchange(address(0)).batchFillOrKillOrders.selector ||
            functionSelector == IExchange(address(0)).batchFillOrders.selector ||
            functionSelector == IExchange(address(0)).batchFillOrdersNoThrow.selector
        ) {
            (orders, takerAssetFillAmounts, signatures) = _makeReturnValuesForBatchFill(transactionData);
        } else if (functionSelector == IExchange(address(0)).cancelOrder.selector) {
            orders = new LibOrder.Order[](1);
            orders[0] = abi.decode(transactionData.slice(4, transactionData.length), (LibOrder.Order));
            takerAssetFillAmounts = new uint256[](0);
            signatures = new bytes[](0);
        } else if (
            functionSelector == IExchange(address(0)).fillOrKillOrder.selector ||
            functionSelector == IExchange(address(0)).fillOrder.selector
        ) {
            (orders, takerAssetFillAmounts, signatures) = _makeReturnValuesForSingleOrderFill(transactionData);
        } else if (
            functionSelector == IExchange(address(0)).marketBuyOrdersNoThrow.selector ||
            functionSelector == IExchange(address(0)).marketSellOrdersNoThrow.selector ||
            functionSelector == IExchange(address(0)).marketBuyOrdersFillOrKill.selector ||
            functionSelector == IExchange(address(0)).marketSellOrdersFillOrKill.selector
        ) {
            (orders, takerAssetFillAmounts, signatures) = _makeReturnValuesForMarketFill(transactionData);
        } else if (functionSelector == IExchange(address(0)).matchOrders.selector) {
            (
                LibOrder.Order memory leftOrder,
                LibOrder.Order memory rightOrder,
                bytes memory leftSignature,
                bytes memory rightSignature
            ) = abi.decode(
                transactionData.slice(4, transactionData.length),
                (LibOrder.Order, LibOrder.Order, bytes, bytes)
            );

            orders = new LibOrder.Order[](2);
            orders[0] = leftOrder;
            orders[1] = rightOrder;

            takerAssetFillAmounts = new uint256[](2);
            takerAssetFillAmounts[0] = leftOrder.takerAssetAmount;
            takerAssetFillAmounts[1] = rightOrder.takerAssetAmount;

            signatures = new bytes[](2);
            signatures[0] = leftSignature;
            signatures[1] = rightSignature;
        }
    }

    function _makeReturnValuesForSingleOrderFill(bytes memory transactionData)
        private
        pure
        returns(
            LibOrder.Order[] memory orders,
            uint256[] memory takerAssetFillAmounts,
            bytes[] memory signatures
        )
    {
        orders = new LibOrder.Order[](1);
        takerAssetFillAmounts = new uint256[](1);
        signatures = new bytes[](1);
        // solhint-disable-next-line indent
        (orders[0], takerAssetFillAmounts[0], signatures[0]) = abi.decode(
            transactionData.slice(4, transactionData.length),
            (LibOrder.Order, uint256, bytes)
        );
    }

    function _makeReturnValuesForBatchFill(bytes memory transactionData)
        private
        pure
        returns(
            LibOrder.Order[] memory orders,
            uint256[] memory takerAssetFillAmounts,
            bytes[] memory signatures
        )
    {
        // solhint-disable-next-line indent
        (orders, takerAssetFillAmounts, signatures) = abi.decode(
            transactionData.slice(4, transactionData.length),
            // solhint-disable-next-line indent
            (LibOrder.Order[], uint256[], bytes[])
        );
    }

    function _makeReturnValuesForMarketFill(bytes memory transactionData)
        private
        pure
        returns(
            LibOrder.Order[] memory orders,
            uint256[] memory takerAssetFillAmounts,
            bytes[] memory signatures
        )
    {
        takerAssetFillAmounts = new uint256[](1);
        // solhint-disable-next-line indent
        (orders, takerAssetFillAmounts[0], signatures) = abi.decode(
            transactionData.slice(4, transactionData.length),
            // solhint-disable-next-line indent
            (LibOrder.Order[], uint256, bytes[])
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibMath.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "./Addresses.sol";
import "./AssetBalance.sol";
import "./LibAssetData.sol";
import "./LibOrderTransferSimulation.sol";


contract OrderValidationUtils is
    Addresses,
    AssetBalance
{
    using LibBytes for bytes;
    using LibSafeMath for uint256;

    /// @dev Fetches all order-relevant information needed to validate if the supplied order is fillable.
    /// @param order The order structure.
    /// @param signature Signature provided by maker that proves the order's authenticity.
    /// `0x01` can always be provided if the signature does not need to be validated.
    /// @return The orderInfo (hash, status, and `takerAssetAmount` already filled for the given order),
    /// fillableTakerAssetAmount (amount of the order's `takerAssetAmount` that is fillable given all on-chain state),
    /// and isValidSignature (validity of the provided signature).
    /// NOTE: If the `takerAssetData` encodes data for multiple assets, `fillableTakerAssetAmount` will represent a "scaled"
    /// amount, meaning it must be multiplied by all the individual asset amounts within the `takerAssetData` to get the final
    /// amount of each asset that can be filled.
    function getOrderRelevantState(LibOrder.Order memory order, bytes memory signature)
        public
        returns (
            LibOrder.OrderInfo memory orderInfo,
            uint256 fillableTakerAssetAmount,
            bool isValidSignature
        )
    {
        // Get info specific to order
        orderInfo = IExchange(exchangeAddress).getOrderInfo(order);

        // Validate the maker's signature
        address makerAddress = order.makerAddress;
        isValidSignature = IExchange(exchangeAddress).isValidOrderSignature(
            order,
            signature
        );

        // Get the transferable amount of the `makerAsset`
        uint256 transferableMakerAssetAmount = _getTransferableConvertedMakerAssetAmount(
            order
        );

        // Get the amount of `takerAsset` that is transferable to maker given the
        // transferability of `makerAsset`, `makerFeeAsset`,
        // and the total amounts specified in the order
        uint256 transferableTakerAssetAmount;
        if (order.makerAssetData.equals(order.makerFeeAssetData)) {
            // If `makerAsset` equals `makerFeeAsset`, the % that can be filled is
            // transferableMakerAssetAmount / (makerAssetAmount + makerFee)
            transferableTakerAssetAmount = LibMath.getPartialAmountFloor(
                transferableMakerAssetAmount,
                order.makerAssetAmount.safeAdd(order.makerFee),
                order.takerAssetAmount
            );
        } else {
            // If `makerFee` is 0, the % that can be filled is (transferableMakerAssetAmount / makerAssetAmount)
            if (order.makerFee == 0) {
                transferableTakerAssetAmount = LibMath.getPartialAmountFloor(
                    transferableMakerAssetAmount,
                    order.makerAssetAmount,
                    order.takerAssetAmount
                );

            // If `makerAsset` does not equal `makerFeeAsset`, the % that can be filled is the lower of
            // (transferableMakerAssetAmount / makerAssetAmount) and (transferableMakerAssetFeeAmount / makerFee)
            } else {
                // Get the transferable amount of the `makerFeeAsset`
                uint256 transferableMakerFeeAssetAmount = getTransferableAssetAmount(
                    makerAddress,
                    order.makerFeeAssetData
                );
                uint256 transferableMakerToTakerAmount = LibMath.getPartialAmountFloor(
                    transferableMakerAssetAmount,
                    order.makerAssetAmount,
                    order.takerAssetAmount
                );
                uint256 transferableMakerFeeToTakerAmount = LibMath.getPartialAmountFloor(
                    transferableMakerFeeAssetAmount,
                    order.makerFee,
                    order.takerAssetAmount
                );
                transferableTakerAssetAmount = LibSafeMath.min256(transferableMakerToTakerAmount, transferableMakerFeeToTakerAmount);
            }
        }

        // `fillableTakerAssetAmount` is the lower of the order's remaining `takerAssetAmount` and the `transferableTakerAssetAmount`
        fillableTakerAssetAmount = LibSafeMath.min256(
            order.takerAssetAmount.safeSub(orderInfo.orderTakerAssetFilledAmount),
            transferableTakerAssetAmount
        );

        // Ensure that all of the asset data is valid. Fee asset data only needs
        // to be valid if the fees are nonzero.
        if (!_areOrderAssetDatasValid(order)) {
            fillableTakerAssetAmount = 0;
        }

        // If the order is not fillable, then the fillable taker asset amount is
        // zero by definition.
        if (orderInfo.orderStatus != LibOrder.OrderStatus.FILLABLE) {
            fillableTakerAssetAmount = 0;
        }

        return (orderInfo, fillableTakerAssetAmount, isValidSignature);
    }

    /// @dev Fetches all order-relevant information needed to validate if the supplied orders are fillable.
    /// @param orders Array of order structures.
    /// @param signatures Array of signatures provided by makers that prove the authenticity of the orders.
    /// `0x01` can always be provided if a signature does not need to be validated.
    /// @return The ordersInfo (array of the hash, status, and `takerAssetAmount` already filled for each order),
    /// fillableTakerAssetAmounts (array of amounts for each order's `takerAssetAmount` that is fillable given all on-chain state),
    /// and isValidSignature (array containing the validity of each provided signature).
    /// NOTE: If the `takerAssetData` encodes data for multiple assets, each element of `fillableTakerAssetAmounts`
    /// will represent a "scaled" amount, meaning it must be multiplied by all the individual asset amounts within
    /// the `takerAssetData` to get the final amount of each asset that can be filled.
    function getOrderRelevantStates(LibOrder.Order[] memory orders, bytes[] memory signatures)
        public
        returns (
            LibOrder.OrderInfo[] memory ordersInfo,
            uint256[] memory fillableTakerAssetAmounts,
            bool[] memory isValidSignature
        )
    {
        uint256 length = orders.length;
        ordersInfo = new LibOrder.OrderInfo[](length);
        fillableTakerAssetAmounts = new uint256[](length);
        isValidSignature = new bool[](length);

        for (uint256 i = 0; i != length; i++) {
            (ordersInfo[i], fillableTakerAssetAmounts[i], isValidSignature[i]) = getOrderRelevantState(
                orders[i],
                signatures[i]
            );
        }

        return (ordersInfo, fillableTakerAssetAmounts, isValidSignature);
    }

    /// @dev Gets the amount of an asset transferable by the maker of an order.
    /// @param ownerAddress Address of the owner of the asset.
    /// @param assetData Description of tokens, per the AssetProxy contract specification.
    /// @return The amount of the asset tranferable by the owner.
    /// NOTE: If the `assetData` encodes data for multiple assets, the `transferableAssetAmount`
    /// will represent the amount of times the entire `assetData` can be transferred. To calculate
    /// the total individual transferable amounts, this scaled `transferableAmount` must be multiplied by
    /// the individual asset amounts located within the `assetData`.
    function getTransferableAssetAmount(address ownerAddress, bytes memory assetData)
        public
        returns (uint256 transferableAssetAmount)
    {
        (uint256 balance, uint256 allowance) = getBalanceAndAssetProxyAllowance(
            ownerAddress,
            assetData
        );
        transferableAssetAmount = LibSafeMath.min256(balance, allowance);
        return transferableAssetAmount;
    }

    /// @dev Gets the amount of an asset transferable by the maker of an order.
    ///      Similar to `getTransferableAssetAmount()`, but can handle maker asset
    ///      types that depend on taker assets being transferred first (e.g., Dydx bridge).
    /// @param order The order.
    /// @return transferableAssetAmount Amount of maker asset that can be transferred.
    function _getTransferableConvertedMakerAssetAmount(
        LibOrder.Order memory order
    )
        internal
        returns (uint256 transferableAssetAmount)
    {
        (uint256 balance, uint256 allowance) = _getConvertibleMakerBalanceAndAssetProxyAllowance(order);
        transferableAssetAmount = LibSafeMath.min256(balance, allowance);
        return LibSafeMath.min256(transferableAssetAmount, order.makerAssetAmount);
    }

    /// @dev Checks that the asset data contained in a ZeroEx is valid and returns
    /// a boolean that indicates whether or not the asset data was found to be valid.
    /// @param order A ZeroEx order to validate.
    /// @return The validatity of the asset data.
    function _areOrderAssetDatasValid(LibOrder.Order memory order)
        internal
        pure
        returns (bool)
    {
        return _isAssetDataValid(order.makerAssetData) &&
            (order.makerFee == 0 || _isAssetDataValid(order.makerFeeAssetData)) &&
            _isAssetDataValid(order.takerAssetData) &&
            (order.takerFee == 0 || _isAssetDataValid(order.takerFeeAssetData));
    }

    /// @dev This function handles the edge cases around taker validation. This function
    ///      currently attempts to find duplicate ERC721 token's in the taker
    ///      multiAssetData.
    /// @param assetData The asset data that should be validated.
    /// @return Whether or not the order should be considered valid.
    function _isAssetDataValid(bytes memory assetData)
        internal
        pure
        returns (bool)
    {
        // Asset data must be composed of an asset proxy Id and a bytes segment with
        // a length divisible by 32.
        if (assetData.length % 32 != 4) {
            return false;
        }

        // Only process the taker asset data if it is multiAssetData.
        bytes4 assetProxyId = assetData.readBytes4(0);
        if (assetProxyId != IAssetData(address(0)).MultiAsset.selector) {
            return true;
        }

        // Get array of values and array of assetDatas
        (, , bytes[] memory nestedAssetData) =
            LibAssetData.decodeMultiAssetData(assetData);

        uint256 length = nestedAssetData.length;
        for (uint256 i = 0; i != length; i++) {
            // TODO(jalextowle): Implement similar validation for non-fungible ERC1155 asset data.
            bytes4 nestedAssetProxyId = nestedAssetData[i].readBytes4(0);
            if (nestedAssetProxyId == IAssetData(address(0)).ERC721Token.selector) {
                if (_isAssetDataDuplicated(nestedAssetData, i)) {
                    return false;
                }
            }
        }

        return true;
    }

    /// Determines whether or not asset data is duplicated later in the nested asset data.
    /// @param nestedAssetData The asset data to scan for duplication.
    /// @param startIdx The index where the scan should begin.
    /// @return A boolean reflecting whether or not the starting asset data was duplicated.
    function _isAssetDataDuplicated(
        bytes[] memory nestedAssetData,
        uint256 startIdx
    )
        internal
        pure
        returns (bool)
    {
        uint256 length = nestedAssetData.length;
        for (uint256 i = startIdx + 1; i < length; i++) {
            if (nestedAssetData[startIdx].equals(nestedAssetData[i])) {
                return true;
            }
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

// solhint-disable
pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


// @dev Interface of the asset proxy's assetData.
// The asset proxies take an ABI encoded `bytes assetData` as argument.
// This argument is ABI encoded as one of the methods of this interface.
interface IAssetData {

    /// @dev Function signature for encoding ERC20 assetData.
    /// @param tokenAddress Address of ERC20Token contract.
    function ERC20Token(address tokenAddress)
        external;

    /// @dev Function signature for encoding ERC721 assetData.
    /// @param tokenAddress Address of ERC721 token contract.
    /// @param tokenId Id of ERC721 token to be transferred.
    function ERC721Token(
        address tokenAddress,
        uint256 tokenId
    )
        external;

    /// @dev Function signature for encoding ERC1155 assetData.
    /// @param tokenAddress Address of ERC1155 token contract.
    /// @param tokenIds Array of ids of tokens to be transferred.
    /// @param values Array of values that correspond to each token id to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param callbackData Extra data to be passed to receiver's `onERC1155Received` callback function.
    function ERC1155Assets(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata callbackData
    )
        external;

    /// @dev Function signature for encoding MultiAsset assetData.
    /// @param values Array of amounts that correspond to each asset to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param nestedAssetData Array of assetData fields that will be be dispatched to their correspnding AssetProxy contract.
    function MultiAsset(
        uint256[] calldata values,
        bytes[] calldata nestedAssetData
    )
        external;

    /// @dev Function signature for encoding StaticCall assetData.
    /// @param staticCallTargetAddress Address that will execute the staticcall.
    /// @param staticCallData Data that will be executed via staticcall on the staticCallTargetAddress.
    /// @param expectedReturnDataHash Keccak-256 hash of the expected staticcall return data.
    function StaticCall(
        address staticCallTargetAddress,
        bytes calldata staticCallData,
        bytes32 expectedReturnDataHash
    )
        external;

    /// @dev Function signature for encoding ERC20Bridge assetData.
    /// @param tokenAddress Address of token to transfer.
    /// @param bridgeAddress Address of the bridge contract.
    /// @param bridgeData Arbitrary data to be passed to the bridge contract.
    function ERC20Bridge(
        address tokenAddress,
        address bridgeAddress,
        bytes calldata bridgeData
    )
        external;
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


contract IAssetProxy {

    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";


contract PotLike {
    function chi() external returns (uint256);
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}


// The actual Chai contract can be found here: https://github.com/dapphub/chai
contract IChai is
    IERC20Token
{
    /// @dev Withdraws Dai owned by `src`
    /// @param src Address that owns Dai.
    /// @param wad Amount of Dai to withdraw.
    function draw(
        address src,
        uint256 wad
    )
        external;

    /// @dev Queries Dai balance of Chai holder.
    /// @param usr Address of Chai holder.
    /// @return Dai balance.
    function dai(address usr)
        external
        returns (uint256);

    /// @dev Queries the Pot contract used by the Chai contract.
    function pot()
        external
        returns (PotLike);

    /// @dev Deposits Dai in exchange for Chai
    /// @param dst Address to receive Chai.
    /// @param wad Amount of Dai to deposit.
    function join(
        address dst,
        uint256 wad
    )
        external;
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IDydx {

    /// @dev Represents the unique key that specifies an account
    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    /// @dev Arguments that are passed to Solo in an ordered list as part of a single operation.
    /// Each ActionArgs has an actionType which specifies which action struct that this data will be
    /// parsed into before being processed.
    struct ActionArgs {
        ActionType actionType;
        uint256 accountIdx;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountIdx;
        bytes data;
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct D256 {
        uint256 value;
    }

    struct Value {
        uint256 value;
    }

    struct Price {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    /// @dev The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Value minBorrowedValue;
    }

    /// @dev The main entry-point to Solo that allows users and contracts to manage accounts.
    ///      Take one or more actions on one or more accounts. The msg.sender must be the owner or
    ///      operator of all accounts except for those being liquidated, vaporized, or traded with.
    ///      One call to operate() is considered a singular "operation". Account collateralization is
    ///      ensured only after the completion of the entire operation.
    /// @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
    ///                   duplicates. In each action, the relevant account will be referred-to by its
    ///                   index in the list.
    /// @param  actions   An ordered list of all actions that will be taken in this operation. The
    ///                   actions will be processed in order.
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    )
        external;

    // @dev Approves/disapproves any number of operators. An operator is an external address that has the
    //      same permissions to manipulate an account as the owner of the account. Operators are simply
    //      addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
    //      Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
    //      operator is a smart contract and implements the IAutoTrader interface.
    // @param args A list of OperatorArgs which have an address and a boolean. The boolean value
    //        denotes whether to approve (true) or revoke approval (false) for that address.
    function setOperators(OperatorArg[] calldata args) external;

    /// @dev Return true if a particular address is approved as an operator for an owner's accounts.
    ///      Approved operators can act on the accounts of the owner as if it were the operator's own.
    /// @param owner The owner of the accounts
    /// @param operator The possible operator
    /// @return isLocalOperator True if operator is approved for owner's accounts
    function getIsLocalOperator(
        address owner,
        address operator
    )
        external
        view
        returns (bool isLocalOperator);

    /// @dev Get the ERC20 token address for a market.
    /// @param marketId The market to query
    /// @return tokenAddress The token address
    function getMarketTokenAddress(
        uint256 marketId
    )
        external
        view
        returns (address tokenAddress);

    /// @dev Get all risk parameters in a single struct.
    /// @return riskParams All global risk parameters
    function getRiskParams()
        external
        view
        returns (RiskParams memory riskParams);

    /// @dev Get the price of the token for a market.
    /// @param marketId The market to query
    /// @return price The price of each atomic unit of the token
    function getMarketPrice(
        uint256 marketId
    )
        external
        view
        returns (Price memory price);

    /// @dev Get the margin premium for a market. A margin premium makes it so that any positions that
    ///      include the market require a higher collateralization to avoid being liquidated.
    /// @param  marketId  The market to query
    /// @return premium The market's margin premium
    function getMarketMarginPremium(uint256 marketId)
        external
        view
        returns (D256 memory premium);

    /// @dev Get the total supplied and total borrowed values of an account adjusted by the marginPremium
    ///      of each market. Supplied values are divided by (1 + marginPremium) for each market and
    ///      borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
    ///      adjusted values gives the margin-ratio of the account which will be compared to the global
    ///      margin-ratio when determining if the account can be liquidated.
    /// @param account The account to query
    /// @return supplyValue The supplied value of the account (adjusted for marginPremium)
    /// @return borrowValue The borrowed value of the account (adjusted for marginPremium)
    function getAdjustedAccountValues(
        AccountInfo calldata account
    )
        external
        view
        returns (Value memory supplyValue, Value memory borrowValue);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


interface IDydxBridge {

    /// @dev This is the subset of `IDydx.ActionType` that are supported by the bridge.
    enum BridgeActionType {
        Deposit,                    // Deposit tokens into dydx account.
        Withdraw                    // Withdraw tokens from dydx account.
    }

    struct BridgeAction {
        BridgeActionType actionType;            // Action to run on dydx account.
        uint256 accountIdx;                     // Index in `BridgeData.accountNumbers` for this action.
        uint256 marketId;                       // Market to operate on.
        uint256 conversionRateNumerator;        // Optional. If set, transfer amount is scaled by (conversionRateNumerator/conversionRateDenominator).
        uint256 conversionRateDenominator;      // Optional. If set, transfer amount is scaled by (conversionRateNumerator/conversionRateDenominator).
    }

    struct BridgeData {
        uint256[] accountNumbers;               // Account number used to identify the owner's specific account.
        BridgeAction[] actions;                 // Actions to carry out on the owner's accounts.
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


/// @title ERC-1155 Multi Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string value,
        uint256 indexed id
    );

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "../src/interfaces/IERC20Token.sol";


library LibERC20Token {
    bytes constant private DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20Token(token).approve()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function approve(
        address token,
        address spender,
        uint256 allowance
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).approve.selector,
            spender,
            allowance
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Calls `IERC20Token(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        if (IERC20Token(token).allowance(address(this), spender) < amount) {
            approve(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20Token(token).transfer()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transfer.selector,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Calls `IERC20Token(token).transferFrom()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transferFrom.selector,
            from,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function decimals(address token)
        internal
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = token.staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length == 32) {
            tokenDecimals = uint8(LibBytes.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance The allowance for a token, owner, and spender.
    function allowance(address token, address owner, address spender)
        internal
        view
        returns (uint256 allowance_)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).allowance.selector,
                owner,
                spender
            )
        );
        if (didSucceed && resultData.length == 32) {
            allowance_ = LibBytes.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function balanceOf(address token, address owner)
        internal
        view
        returns (uint256 balance)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).balanceOf.selector,
                owner
            )
        );
        if (didSucceed && resultData.length == 32) {
            balance = LibBytes.readUint256(resultData, 0);
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(
        address target,
        bytes memory callData
    )
        private
    {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        if (didSucceed) {
            if (resultData.length == 0) {
                return;
            }
            if (resultData.length == 32) {
                uint256 result = LibBytes.readUint256(resultData, 0);
                if (result == 1) {
                    return;
                }
            }
        }
        LibRichErrors.rrevert(resultData);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


contract IERC20Token {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


contract IERC721Token {

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///      This event emits when NFTs are created (`from` == 0) and destroyed
    ///      (`to` == 0). Exception: during contract creation, any number of NFTs
    ///      may be created and assigned without emitting Transfer. At the time of
    ///      any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///      reaffirmed. The zero address indicates there is no approved address.
    ///      When a Transfer event emits, this also indicates that the approved
    ///      address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///      The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      perator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
        external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
        external;

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public;

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address);

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        public
        view
        returns (address);
    
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibEIP712.sol";


contract LibEIP712ExchangeDomain {

    // EIP712 Exchange Domain Name value
    string constant internal _EIP712_EXCHANGE_DOMAIN_NAME = "0x Protocol";

    // EIP712 Exchange Domain Version value
    string constant internal _EIP712_EXCHANGE_DOMAIN_VERSION = "3.0.0";

    // solhint-disable var-name-mixedcase
    /// @dev Hash of the EIP712 Domain Separator data
    /// @return 0 Domain hash.
    bytes32 public EIP712_EXCHANGE_DOMAIN_HASH;
    // solhint-enable var-name-mixedcase

    /// @param chainId Chain ID of the network this contract is deployed on.
    /// @param verifyingContractAddressIfExists Address of the verifying contract (null if the address of this contract)
    constructor (
        uint256 chainId,
        address verifyingContractAddressIfExists
    )
        public
    {
        address verifyingContractAddress = verifyingContractAddressIfExists == address(0) ? address(this) : verifyingContractAddressIfExists;
        EIP712_EXCHANGE_DOMAIN_HASH = LibEIP712.hashEIP712Domain(
            _EIP712_EXCHANGE_DOMAIN_NAME,
            _EIP712_EXCHANGE_DOMAIN_VERSION,
            chainId,
            verifyingContractAddress
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "./LibOrder.sol";


library LibExchangeRichErrors {

    enum AssetProxyDispatchErrorCodes {
        INVALID_ASSET_DATA_LENGTH,
        UNKNOWN_ASSET_PROXY
    }

    enum BatchMatchOrdersErrorCodes {
        ZERO_LEFT_ORDERS,
        ZERO_RIGHT_ORDERS,
        INVALID_LENGTH_LEFT_SIGNATURES,
        INVALID_LENGTH_RIGHT_SIGNATURES
    }

    enum ExchangeContextErrorCodes {
        INVALID_MAKER,
        INVALID_TAKER,
        INVALID_SENDER
    }

    enum FillErrorCodes {
        INVALID_TAKER_AMOUNT,
        TAKER_OVERPAY,
        OVERFILL,
        INVALID_FILL_PRICE
    }

    enum SignatureErrorCodes {
        BAD_ORDER_SIGNATURE,
        BAD_TRANSACTION_SIGNATURE,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        INAPPROPRIATE_SIGNATURE_TYPE,
        INVALID_SIGNER
    }

    enum TransactionErrorCodes {
        ALREADY_EXECUTED,
        EXPIRED
    }

    enum IncompleteFillErrorCode {
        INCOMPLETE_MARKET_BUY_ORDERS,
        INCOMPLETE_MARKET_SELL_ORDERS,
        INCOMPLETE_FILL_ORDER
    }

    // bytes4(keccak256("SignatureError(uint8,bytes32,address,bytes)"))
    bytes4 internal constant SIGNATURE_ERROR_SELECTOR =
        0x7e5a2318;

    // bytes4(keccak256("SignatureValidatorNotApprovedError(address,address)"))
    bytes4 internal constant SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR =
        0xa15c0d06;

    // bytes4(keccak256("EIP1271SignatureError(address,bytes,bytes,bytes)"))
    bytes4 internal constant EIP1271_SIGNATURE_ERROR_SELECTOR =
        0x5bd0428d;

    // bytes4(keccak256("SignatureWalletError(bytes32,address,bytes,bytes)"))
    bytes4 internal constant SIGNATURE_WALLET_ERROR_SELECTOR =
        0x1b8388f7;

    // bytes4(keccak256("OrderStatusError(bytes32,uint8)"))
    bytes4 internal constant ORDER_STATUS_ERROR_SELECTOR =
        0xfdb6ca8d;

    // bytes4(keccak256("ExchangeInvalidContextError(uint8,bytes32,address)"))
    bytes4 internal constant EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR =
        0xe53c76c8;

    // bytes4(keccak256("FillError(uint8,bytes32)"))
    bytes4 internal constant FILL_ERROR_SELECTOR =
        0xe94a7ed0;

    // bytes4(keccak256("OrderEpochError(address,address,uint256)"))
    bytes4 internal constant ORDER_EPOCH_ERROR_SELECTOR =
        0x4ad31275;

    // bytes4(keccak256("AssetProxyExistsError(bytes4,address)"))
    bytes4 internal constant ASSET_PROXY_EXISTS_ERROR_SELECTOR =
        0x11c7b720;

    // bytes4(keccak256("AssetProxyDispatchError(uint8,bytes32,bytes)"))
    bytes4 internal constant ASSET_PROXY_DISPATCH_ERROR_SELECTOR =
        0x488219a6;

    // bytes4(keccak256("AssetProxyTransferError(bytes32,bytes,bytes)"))
    bytes4 internal constant ASSET_PROXY_TRANSFER_ERROR_SELECTOR =
        0x4678472b;

    // bytes4(keccak256("NegativeSpreadError(bytes32,bytes32)"))
    bytes4 internal constant NEGATIVE_SPREAD_ERROR_SELECTOR =
        0xb6555d6f;

    // bytes4(keccak256("TransactionError(uint8,bytes32)"))
    bytes4 internal constant TRANSACTION_ERROR_SELECTOR =
        0xf5985184;

    // bytes4(keccak256("TransactionExecutionError(bytes32,bytes)"))
    bytes4 internal constant TRANSACTION_EXECUTION_ERROR_SELECTOR =
        0x20d11f61;
    
    // bytes4(keccak256("TransactionGasPriceError(bytes32,uint256,uint256)"))
    bytes4 internal constant TRANSACTION_GAS_PRICE_ERROR_SELECTOR =
        0xa26dac09;

    // bytes4(keccak256("TransactionInvalidContextError(bytes32,address)"))
    bytes4 internal constant TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR =
        0xdec4aedf;

    // bytes4(keccak256("IncompleteFillError(uint8,uint256,uint256)"))
    bytes4 internal constant INCOMPLETE_FILL_ERROR_SELECTOR =
        0x18e4b141;

    // bytes4(keccak256("BatchMatchOrdersError(uint8)"))
    bytes4 internal constant BATCH_MATCH_ORDERS_ERROR_SELECTOR =
        0xd4092f4f;

    // bytes4(keccak256("PayProtocolFeeError(bytes32,uint256,address,address,bytes)"))
    bytes4 internal constant PAY_PROTOCOL_FEE_ERROR_SELECTOR =
        0x87cb1e75;

    // solhint-disable func-name-mixedcase
    function SignatureErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return SIGNATURE_ERROR_SELECTOR;
    }

    function SignatureValidatorNotApprovedErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR;
    }

    function EIP1271SignatureErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return EIP1271_SIGNATURE_ERROR_SELECTOR;
    }

    function SignatureWalletErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return SIGNATURE_WALLET_ERROR_SELECTOR;
    }

    function OrderStatusErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return ORDER_STATUS_ERROR_SELECTOR;
    }

    function ExchangeInvalidContextErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR;
    }

    function FillErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return FILL_ERROR_SELECTOR;
    }

    function OrderEpochErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return ORDER_EPOCH_ERROR_SELECTOR;
    }

    function AssetProxyExistsErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return ASSET_PROXY_EXISTS_ERROR_SELECTOR;
    }

    function AssetProxyDispatchErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return ASSET_PROXY_DISPATCH_ERROR_SELECTOR;
    }

    function AssetProxyTransferErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return ASSET_PROXY_TRANSFER_ERROR_SELECTOR;
    }

    function NegativeSpreadErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return NEGATIVE_SPREAD_ERROR_SELECTOR;
    }

    function TransactionErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return TRANSACTION_ERROR_SELECTOR;
    }

    function TransactionExecutionErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return TRANSACTION_EXECUTION_ERROR_SELECTOR;
    }

    function IncompleteFillErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return INCOMPLETE_FILL_ERROR_SELECTOR;
    }

    function BatchMatchOrdersErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return BATCH_MATCH_ORDERS_ERROR_SELECTOR;
    }

    function TransactionGasPriceErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return TRANSACTION_GAS_PRICE_ERROR_SELECTOR;
    }

    function TransactionInvalidContextErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR;
    }

    function PayProtocolFeeErrorSelector()
        internal
        pure
        returns (bytes4)
    {
        return PAY_PROTOCOL_FEE_ERROR_SELECTOR;
    }
    
    function BatchMatchOrdersError(
        BatchMatchOrdersErrorCodes errorCode
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            BATCH_MATCH_ORDERS_ERROR_SELECTOR,
            errorCode
        );
    }

    function SignatureError(
        SignatureErrorCodes errorCode,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SIGNATURE_ERROR_SELECTOR,
            errorCode,
            hash,
            signerAddress,
            signature
        );
    }

    function SignatureValidatorNotApprovedError(
        address signerAddress,
        address validatorAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR,
            signerAddress,
            validatorAddress
        );
    }

    function EIP1271SignatureError(
        address verifyingContractAddress,
        bytes memory data,
        bytes memory signature,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            EIP1271_SIGNATURE_ERROR_SELECTOR,
            verifyingContractAddress,
            data,
            signature,
            errorData
        );
    }

    function SignatureWalletError(
        bytes32 hash,
        address walletAddress,
        bytes memory signature,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SIGNATURE_WALLET_ERROR_SELECTOR,
            hash,
            walletAddress,
            signature,
            errorData
        );
    }

    function OrderStatusError(
        bytes32 orderHash,
        LibOrder.OrderStatus orderStatus
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ORDER_STATUS_ERROR_SELECTOR,
            orderHash,
            orderStatus
        );
    }

    function ExchangeInvalidContextError(
        ExchangeContextErrorCodes errorCode,
        bytes32 orderHash,
        address contextAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR,
            errorCode,
            orderHash,
            contextAddress
        );
    }

    function FillError(
        FillErrorCodes errorCode,
        bytes32 orderHash
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            FILL_ERROR_SELECTOR,
            errorCode,
            orderHash
        );
    }

    function OrderEpochError(
        address makerAddress,
        address orderSenderAddress,
        uint256 currentEpoch
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ORDER_EPOCH_ERROR_SELECTOR,
            makerAddress,
            orderSenderAddress,
            currentEpoch
        );
    }

    function AssetProxyExistsError(
        bytes4 assetProxyId,
        address assetProxyAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ASSET_PROXY_EXISTS_ERROR_SELECTOR,
            assetProxyId,
            assetProxyAddress
        );
    }

    function AssetProxyDispatchError(
        AssetProxyDispatchErrorCodes errorCode,
        bytes32 orderHash,
        bytes memory assetData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ASSET_PROXY_DISPATCH_ERROR_SELECTOR,
            errorCode,
            orderHash,
            assetData
        );
    }

    function AssetProxyTransferError(
        bytes32 orderHash,
        bytes memory assetData,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ASSET_PROXY_TRANSFER_ERROR_SELECTOR,
            orderHash,
            assetData,
            errorData
        );
    }

    function NegativeSpreadError(
        bytes32 leftOrderHash,
        bytes32 rightOrderHash
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            NEGATIVE_SPREAD_ERROR_SELECTOR,
            leftOrderHash,
            rightOrderHash
        );
    }

    function TransactionError(
        TransactionErrorCodes errorCode,
        bytes32 transactionHash
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TRANSACTION_ERROR_SELECTOR,
            errorCode,
            transactionHash
        );
    }

    function TransactionExecutionError(
        bytes32 transactionHash,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TRANSACTION_EXECUTION_ERROR_SELECTOR,
            transactionHash,
            errorData
        );
    }

    function TransactionGasPriceError(
        bytes32 transactionHash,
        uint256 actualGasPrice,
        uint256 requiredGasPrice
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TRANSACTION_GAS_PRICE_ERROR_SELECTOR,
            transactionHash,
            actualGasPrice,
            requiredGasPrice
        );
    }

    function TransactionInvalidContextError(
        bytes32 transactionHash,
        address currentContextAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR,
            transactionHash,
            currentContextAddress
        );
    }

    function IncompleteFillError(
        IncompleteFillErrorCode errorCode,
        uint256 expectedAssetFillAmount,
        uint256 actualAssetFillAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INCOMPLETE_FILL_ERROR_SELECTOR,
            errorCode,
            expectedAssetFillAmount,
            actualAssetFillAmount
        );
    }

    function PayProtocolFeeError(
        bytes32 orderHash,
        uint256 protocolFee,
        address makerAddress,
        address takerAddress,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            PAY_PROTOCOL_FEE_ERROR_SELECTOR,
            orderHash,
            protocolFee,
            makerAddress,
            takerAddress,
            errorData
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "./LibMath.sol";
import "./LibOrder.sol";


library LibFillResults {

    using LibSafeMath for uint256;

    struct BatchMatchedFillResults {
        FillResults[] left;              // Fill results for left orders
        FillResults[] right;             // Fill results for right orders
        uint256 profitInLeftMakerAsset;  // Profit taken from left makers
        uint256 profitInRightMakerAsset; // Profit taken from right makers
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;  // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount;  // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid;            // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid;            // Total amount of fees paid by taker to feeRecipients(s).
        uint256 protocolFeePaid;         // Total amount of fees paid by taker to the staking contract.
    }

    struct MatchedFillResults {
        FillResults left;                // Amounts filled and fees paid of left order.
        FillResults right;               // Amounts filled and fees paid of right order.
        uint256 profitInLeftMakerAsset;  // Profit taken from the left maker
        uint256 profitInRightMakerAsset; // Profit taken from the right maker
    }

    /// @dev Calculates amounts filled and fees paid by maker and taker.
    /// @param order to be filled.
    /// @param takerAssetFilledAmount Amount of takerAsset that will be filled.
    /// @param protocolFeeMultiplier The current protocol fee of the exchange contract.
    /// @param gasPrice The gasprice of the transaction. This is provided so that the function call can continue
    ///        to be pure rather than view.
    /// @return fillResults Amounts filled and fees paid by maker and taker.
    function calculateFillResults(
        LibOrder.Order memory order,
        uint256 takerAssetFilledAmount,
        uint256 protocolFeeMultiplier,
        uint256 gasPrice
    )
        internal
        pure
        returns (FillResults memory fillResults)
    {
        // Compute proportional transfer amounts
        fillResults.takerAssetFilledAmount = takerAssetFilledAmount;
        fillResults.makerAssetFilledAmount = LibMath.safeGetPartialAmountFloor(
            takerAssetFilledAmount,
            order.takerAssetAmount,
            order.makerAssetAmount
        );
        fillResults.makerFeePaid = LibMath.safeGetPartialAmountFloor(
            takerAssetFilledAmount,
            order.takerAssetAmount,
            order.makerFee
        );
        fillResults.takerFeePaid = LibMath.safeGetPartialAmountFloor(
            takerAssetFilledAmount,
            order.takerAssetAmount,
            order.takerFee
        );

        // Compute the protocol fee that should be paid for a single fill.
        fillResults.protocolFeePaid = gasPrice.safeMul(protocolFeeMultiplier);

        return fillResults;
    }

    /// @dev Calculates fill amounts for the matched orders.
    ///      Each order is filled at their respective price point. However, the calculations are
    ///      carried out as though the orders are both being filled at the right order's price point.
    ///      The profit made by the leftOrder order goes to the taker (who matched the two orders).
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    /// @param leftOrderTakerAssetFilledAmount Amount of left order already filled.
    /// @param rightOrderTakerAssetFilledAmount Amount of right order already filled.
    /// @param protocolFeeMultiplier The current protocol fee of the exchange contract.
    /// @param gasPrice The gasprice of the transaction. This is provided so that the function call can continue
    ///        to be pure rather than view.
    /// @param shouldMaximallyFillOrders A value that indicates whether or not this calculation should use
    ///                                  the maximal fill order matching strategy.
    /// @param matchedFillResults Amounts to fill and fees to pay by maker and taker of matched orders.
    function calculateMatchedFillResults(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderTakerAssetFilledAmount,
        uint256 rightOrderTakerAssetFilledAmount,
        uint256 protocolFeeMultiplier,
        uint256 gasPrice,
        bool shouldMaximallyFillOrders
    )
        internal
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        // Derive maker asset amounts for left & right orders, given store taker assert amounts
        uint256 leftTakerAssetAmountRemaining = leftOrder.takerAssetAmount.safeSub(leftOrderTakerAssetFilledAmount);
        uint256 leftMakerAssetAmountRemaining = LibMath.safeGetPartialAmountFloor(
            leftOrder.makerAssetAmount,
            leftOrder.takerAssetAmount,
            leftTakerAssetAmountRemaining
        );
        uint256 rightTakerAssetAmountRemaining = rightOrder.takerAssetAmount.safeSub(rightOrderTakerAssetFilledAmount);
        uint256 rightMakerAssetAmountRemaining = LibMath.safeGetPartialAmountFloor(
            rightOrder.makerAssetAmount,
            rightOrder.takerAssetAmount,
            rightTakerAssetAmountRemaining
        );

        // Maximally fill the orders and pay out profits to the matcher in one or both of the maker assets.
        if (shouldMaximallyFillOrders) {
            matchedFillResults = _calculateMatchedFillResultsWithMaximalFill(
                leftOrder,
                rightOrder,
                leftMakerAssetAmountRemaining,
                leftTakerAssetAmountRemaining,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        } else {
            matchedFillResults = _calculateMatchedFillResults(
                leftOrder,
                rightOrder,
                leftMakerAssetAmountRemaining,
                leftTakerAssetAmountRemaining,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        }

        // Compute fees for left order
        matchedFillResults.left.makerFeePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.left.makerAssetFilledAmount,
            leftOrder.makerAssetAmount,
            leftOrder.makerFee
        );
        matchedFillResults.left.takerFeePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.left.takerAssetFilledAmount,
            leftOrder.takerAssetAmount,
            leftOrder.takerFee
        );

        // Compute fees for right order
        matchedFillResults.right.makerFeePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.right.makerAssetFilledAmount,
            rightOrder.makerAssetAmount,
            rightOrder.makerFee
        );
        matchedFillResults.right.takerFeePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.right.takerAssetFilledAmount,
            rightOrder.takerAssetAmount,
            rightOrder.takerFee
        );

        // Compute the protocol fee that should be paid for a single fill. In this
        // case this should be made the protocol fee for both the left and right orders.
        uint256 protocolFee = gasPrice.safeMul(protocolFeeMultiplier);
        matchedFillResults.left.protocolFeePaid = protocolFee;
        matchedFillResults.right.protocolFeePaid = protocolFee;

        // Return fill results
        return matchedFillResults;
    }

    /// @dev Adds properties of both FillResults instances.
    /// @param fillResults1 The first FillResults.
    /// @param fillResults2 The second FillResults.
    /// @return The sum of both fill results.
    function addFillResults(
        FillResults memory fillResults1,
        FillResults memory fillResults2
    )
        internal
        pure
        returns (FillResults memory totalFillResults)
    {
        totalFillResults.makerAssetFilledAmount = fillResults1.makerAssetFilledAmount.safeAdd(fillResults2.makerAssetFilledAmount);
        totalFillResults.takerAssetFilledAmount = fillResults1.takerAssetFilledAmount.safeAdd(fillResults2.takerAssetFilledAmount);
        totalFillResults.makerFeePaid = fillResults1.makerFeePaid.safeAdd(fillResults2.makerFeePaid);
        totalFillResults.takerFeePaid = fillResults1.takerFeePaid.safeAdd(fillResults2.takerFeePaid);
        totalFillResults.protocolFeePaid = fillResults1.protocolFeePaid.safeAdd(fillResults2.protocolFeePaid);

        return totalFillResults;
    }

    /// @dev Calculates part of the matched fill results for a given situation using the fill strategy that only
    ///      awards profit denominated in the left maker asset.
    /// @param leftOrder The left order in the order matching situation.
    /// @param rightOrder The right order in the order matching situation.
    /// @param leftMakerAssetAmountRemaining The amount of the left order maker asset that can still be filled.
    /// @param leftTakerAssetAmountRemaining The amount of the left order taker asset that can still be filled.
    /// @param rightMakerAssetAmountRemaining The amount of the right order maker asset that can still be filled.
    /// @param rightTakerAssetAmountRemaining The amount of the right order taker asset that can still be filled.
    /// @return MatchFillResults struct that does not include fees paid.
    function _calculateMatchedFillResults(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftMakerAssetAmountRemaining,
        uint256 leftTakerAssetAmountRemaining,
        uint256 rightMakerAssetAmountRemaining,
        uint256 rightTakerAssetAmountRemaining
    )
        private
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        // Calculate fill results for maker and taker assets: at least one order will be fully filled.
        // The maximum amount the left maker can buy is `leftTakerAssetAmountRemaining`
        // The maximum amount the right maker can sell is `rightMakerAssetAmountRemaining`
        // We have two distinct cases for calculating the fill results:
        // Case 1.
        //   If the left maker can buy more than the right maker can sell, then only the right order is fully filled.
        //   If the left maker can buy exactly what the right maker can sell, then both orders are fully filled.
        // Case 2.
        //   If the left maker cannot buy more than the right maker can sell, then only the left order is fully filled.
        // Case 3.
        //   If the left maker can buy exactly as much as the right maker can sell, then both orders are fully filled.
        if (leftTakerAssetAmountRemaining > rightMakerAssetAmountRemaining) {
            // Case 1: Right order is fully filled
            matchedFillResults = _calculateCompleteRightFill(
                leftOrder,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        } else if (leftTakerAssetAmountRemaining < rightMakerAssetAmountRemaining) {
            // Case 2: Left order is fully filled
            matchedFillResults.left.makerAssetFilledAmount = leftMakerAssetAmountRemaining;
            matchedFillResults.left.takerAssetFilledAmount = leftTakerAssetAmountRemaining;
            matchedFillResults.right.makerAssetFilledAmount = leftTakerAssetAmountRemaining;
            // Round up to ensure the maker's exchange rate does not exceed the price specified by the order.
            // We favor the maker when the exchange rate must be rounded.
            matchedFillResults.right.takerAssetFilledAmount = LibMath.safeGetPartialAmountCeil(
                rightOrder.takerAssetAmount,
                rightOrder.makerAssetAmount,
                leftTakerAssetAmountRemaining // matchedFillResults.right.makerAssetFilledAmount
            );
        } else {
            // leftTakerAssetAmountRemaining == rightMakerAssetAmountRemaining
            // Case 3: Both orders are fully filled. Technically, this could be captured by the above cases, but
            //         this calculation will be more precise since it does not include rounding.
            matchedFillResults = _calculateCompleteFillBoth(
                leftMakerAssetAmountRemaining,
                leftTakerAssetAmountRemaining,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        }

        // Calculate amount given to taker
        matchedFillResults.profitInLeftMakerAsset = matchedFillResults.left.makerAssetFilledAmount.safeSub(
            matchedFillResults.right.takerAssetFilledAmount
        );

        return matchedFillResults;
    }

    /// @dev Calculates part of the matched fill results for a given situation using the maximal fill order matching
    ///      strategy.
    /// @param leftOrder The left order in the order matching situation.
    /// @param rightOrder The right order in the order matching situation.
    /// @param leftMakerAssetAmountRemaining The amount of the left order maker asset that can still be filled.
    /// @param leftTakerAssetAmountRemaining The amount of the left order taker asset that can still be filled.
    /// @param rightMakerAssetAmountRemaining The amount of the right order maker asset that can still be filled.
    /// @param rightTakerAssetAmountRemaining The amount of the right order taker asset that can still be filled.
    /// @return MatchFillResults struct that does not include fees paid.
    function _calculateMatchedFillResultsWithMaximalFill(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftMakerAssetAmountRemaining,
        uint256 leftTakerAssetAmountRemaining,
        uint256 rightMakerAssetAmountRemaining,
        uint256 rightTakerAssetAmountRemaining
    )
        private
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        // If a maker asset is greater than the opposite taker asset, than there will be a spread denominated in that maker asset.
        bool doesLeftMakerAssetProfitExist = leftMakerAssetAmountRemaining > rightTakerAssetAmountRemaining;
        bool doesRightMakerAssetProfitExist = rightMakerAssetAmountRemaining > leftTakerAssetAmountRemaining;

        // Calculate the maximum fill results for the maker and taker assets. At least one of the orders will be fully filled.
        //
        // The maximum that the left maker can possibly buy is the amount that the right order can sell.
        // The maximum that the right maker can possibly buy is the amount that the left order can sell.
        //
        // If the left order is fully filled, profit will be paid out in the left maker asset. If the right order is fully filled,
        // the profit will be out in the right maker asset.
        //
        // There are three cases to consider:
        // Case 1.
        //   If the left maker can buy more than the right maker can sell, then only the right order is fully filled.
        // Case 2.
        //   If the right maker can buy more than the left maker can sell, then only the right order is fully filled.
        // Case 3.
        //   If the right maker can sell the max of what the left maker can buy and the left maker can sell the max of
        //   what the right maker can buy, then both orders are fully filled.
        if (leftTakerAssetAmountRemaining > rightMakerAssetAmountRemaining) {
            // Case 1: Right order is fully filled with the profit paid in the left makerAsset
            matchedFillResults = _calculateCompleteRightFill(
                leftOrder,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        } else if (rightTakerAssetAmountRemaining > leftMakerAssetAmountRemaining) {
            // Case 2: Left order is fully filled with the profit paid in the right makerAsset.
            matchedFillResults.left.makerAssetFilledAmount = leftMakerAssetAmountRemaining;
            matchedFillResults.left.takerAssetFilledAmount = leftTakerAssetAmountRemaining;
            // Round down to ensure the right maker's exchange rate does not exceed the price specified by the order.
            // We favor the right maker when the exchange rate must be rounded and the profit is being paid in the
            // right maker asset.
            matchedFillResults.right.makerAssetFilledAmount = LibMath.safeGetPartialAmountFloor(
                rightOrder.makerAssetAmount,
                rightOrder.takerAssetAmount,
                leftMakerAssetAmountRemaining
            );
            matchedFillResults.right.takerAssetFilledAmount = leftMakerAssetAmountRemaining;
        } else {
            // Case 3: The right and left orders are fully filled
            matchedFillResults = _calculateCompleteFillBoth(
                leftMakerAssetAmountRemaining,
                leftTakerAssetAmountRemaining,
                rightMakerAssetAmountRemaining,
                rightTakerAssetAmountRemaining
            );
        }

        // Calculate amount given to taker in the left order's maker asset if the left spread will be part of the profit.
        if (doesLeftMakerAssetProfitExist) {
            matchedFillResults.profitInLeftMakerAsset = matchedFillResults.left.makerAssetFilledAmount.safeSub(
                matchedFillResults.right.takerAssetFilledAmount
            );
        }

        // Calculate amount given to taker in the right order's maker asset if the right spread will be part of the profit.
        if (doesRightMakerAssetProfitExist) {
            matchedFillResults.profitInRightMakerAsset = matchedFillResults.right.makerAssetFilledAmount.safeSub(
                matchedFillResults.left.takerAssetFilledAmount
            );
        }

        return matchedFillResults;
    }

    /// @dev Calculates the fill results for the maker and taker in the order matching and writes the results
    ///      to the fillResults that are being collected on the order. Both orders will be fully filled in this
    ///      case.
    /// @param leftMakerAssetAmountRemaining The amount of the left maker asset that is remaining to be filled.
    /// @param leftTakerAssetAmountRemaining The amount of the left taker asset that is remaining to be filled.
    /// @param rightMakerAssetAmountRemaining The amount of the right maker asset that is remaining to be filled.
    /// @param rightTakerAssetAmountRemaining The amount of the right taker asset that is remaining to be filled.
    /// @return MatchFillResults struct that does not include fees paid or spreads taken.
    function _calculateCompleteFillBoth(
        uint256 leftMakerAssetAmountRemaining,
        uint256 leftTakerAssetAmountRemaining,
        uint256 rightMakerAssetAmountRemaining,
        uint256 rightTakerAssetAmountRemaining
    )
        private
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        // Calculate the fully filled results for both orders.
        matchedFillResults.left.makerAssetFilledAmount = leftMakerAssetAmountRemaining;
        matchedFillResults.left.takerAssetFilledAmount = leftTakerAssetAmountRemaining;
        matchedFillResults.right.makerAssetFilledAmount = rightMakerAssetAmountRemaining;
        matchedFillResults.right.takerAssetFilledAmount = rightTakerAssetAmountRemaining;

        return matchedFillResults;
    }

    /// @dev Calculates the fill results for the maker and taker in the order matching and writes the results
    ///      to the fillResults that are being collected on the order.
    /// @param leftOrder The left order that is being maximally filled. All of the information about fill amounts
    ///                  can be derived from this order and the right asset remaining fields.
    /// @param rightMakerAssetAmountRemaining The amount of the right maker asset that is remaining to be filled.
    /// @param rightTakerAssetAmountRemaining The amount of the right taker asset that is remaining to be filled.
    /// @return MatchFillResults struct that does not include fees paid or spreads taken.
    function _calculateCompleteRightFill(
        LibOrder.Order memory leftOrder,
        uint256 rightMakerAssetAmountRemaining,
        uint256 rightTakerAssetAmountRemaining
    )
        private
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        matchedFillResults.right.makerAssetFilledAmount = rightMakerAssetAmountRemaining;
        matchedFillResults.right.takerAssetFilledAmount = rightTakerAssetAmountRemaining;
        matchedFillResults.left.takerAssetFilledAmount = rightMakerAssetAmountRemaining;
        // Round down to ensure the left maker's exchange rate does not exceed the price specified by the order.
        // We favor the left maker when the exchange rate must be rounded and the profit is being paid in the
        // left maker asset.
        matchedFillResults.left.makerAssetFilledAmount = LibMath.safeGetPartialAmountFloor(
            leftOrder.makerAssetAmount,
            leftOrder.takerAssetAmount,
            rightMakerAssetAmountRemaining
        );

        return matchedFillResults;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "./LibMathRichErrors.sol";


library LibMath {

    using LibSafeMath for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorFloor(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorCeil(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.safeSub(remainder) % denominator;
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }
}

pragma solidity ^0.5.9;


library LibMathRichErrors {

    // bytes4(keccak256("DivisionByZeroError()"))
    bytes internal constant DIVISION_BY_ZERO_ERROR =
        hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 internal constant ROUNDING_ERROR_SELECTOR =
        0x339f3de2;

    // solhint-disable func-name-mixedcase
    function DivisionByZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ROUNDING_ERROR_SELECTOR,
            numerator,
            denominator,
            target
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibEIP712.sol";


library LibOrder {

    using LibOrder for Order;

    // Hash for the EIP712 Order Schema:
    // keccak256(abi.encodePacked(
    //     "Order(",
    //     "address makerAddress,",
    //     "address takerAddress,",
    //     "address feeRecipientAddress,",
    //     "address senderAddress,",
    //     "uint256 makerAssetAmount,",
    //     "uint256 takerAssetAmount,",
    //     "uint256 makerFee,",
    //     "uint256 takerFee,",
    //     "uint256 expirationTimeSeconds,",
    //     "uint256 salt,",
    //     "bytes makerAssetData,",
    //     "bytes takerAssetData,",
    //     "bytes makerFeeAssetData,",
    //     "bytes takerFeeAssetData",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_ORDER_SCHEMA_HASH =
        0xf80322eb8376aafb64eadf8f0d7623f22130fd9491a221e902b713cb984a7534;

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's status is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    // solhint-disable max-line-length
    /// @dev Canonical order structure.
    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee;               // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    /// @dev Order information returned by `getOrderInfo()`.
    struct OrderInfo {
        OrderStatus orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }

    /// @dev Calculates the EIP712 typed data hash of an order with a given domain separator.
    /// @param order The order structure.
    /// @return EIP712 typed data hash of the order.
    function getTypedDataHash(Order memory order, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = LibEIP712.hashEIP712Message(
            eip712ExchangeDomainHash,
            order.getStructHash()
        );
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order struct.
    /// @param order The order structure.
    /// @return EIP712 hash of the order struct.
    function getStructHash(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_ORDER_SCHEMA_HASH;
        bytes memory makerAssetData = order.makerAssetData;
        bytes memory takerAssetData = order.takerAssetData;
        bytes memory makerFeeAssetData = order.makerFeeAssetData;
        bytes memory takerFeeAssetData = order.takerFeeAssetData;

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     uint256(order.makerAddress),
        //     uint256(order.takerAddress),
        //     uint256(order.feeRecipientAddress),
        //     uint256(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.makerFee,
        //     order.takerFee,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData),
        //     keccak256(order.makerFeeAssetData),
        //     keccak256(order.takerFeeAssetData)
        // ));

        assembly {
            // Assert order offset (this is an internal error that should never be triggered)
            if lt(order, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)
            let pos4 := add(order, 384)
            let pos5 := add(order, 416)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)
            let temp4 := mload(pos4)
            let temp5 := mload(pos5)

            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, keccak256(add(makerAssetData, 32), mload(makerAssetData)))        // store hash of makerAssetData
            mstore(pos3, keccak256(add(takerAssetData, 32), mload(takerAssetData)))        // store hash of takerAssetData
            mstore(pos4, keccak256(add(makerFeeAssetData, 32), mload(makerFeeAssetData)))  // store hash of makerFeeAssetData
            mstore(pos5, keccak256(add(takerFeeAssetData, 32), mload(takerFeeAssetData)))  // store hash of takerFeeAssetData
            result := keccak256(pos1, 480)

            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
            mstore(pos4, temp4)
            mstore(pos5, temp5)
        }
        return result;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibEIP712.sol";


library LibZeroExTransaction {

    using LibZeroExTransaction for ZeroExTransaction;

    // Hash for the EIP712 0x transaction schema
    // keccak256(abi.encodePacked(
    //    "ZeroExTransaction(",
    //    "uint256 salt,",
    //    "uint256 expirationTimeSeconds,",
    //    "uint256 gasPrice,",
    //    "address signerAddress,",
    //    "bytes data",
    //    ")"
    // ));
    bytes32 constant internal _EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH = 0xec69816980a3a3ca4554410e60253953e9ff375ba4536a98adfa15cc71541508;

    struct ZeroExTransaction {
        uint256 salt;                   // Arbitrary number to ensure uniqueness of transaction hash.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which transaction expires.
        uint256 gasPrice;               // gasPrice that transaction is required to be executed with.
        address signerAddress;          // Address of transaction signer.
        bytes data;                     // AbiV2 encoded calldata.
    }

    /// @dev Calculates the EIP712 typed data hash of a transaction with a given domain separator.
    /// @param transaction 0x transaction structure.
    /// @return EIP712 typed data hash of the transaction.
    function getTypedDataHash(ZeroExTransaction memory transaction, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 transactionHash)
    {
        // Hash the transaction with the domain separator of the Exchange contract.
        transactionHash = LibEIP712.hashEIP712Message(
            eip712ExchangeDomainHash,
            transaction.getStructHash()
        );
        return transactionHash;
    }

    /// @dev Calculates EIP712 hash of the 0x transaction struct.
    /// @param transaction 0x transaction structure.
    /// @return EIP712 hash of the transaction struct.
    function getStructHash(ZeroExTransaction memory transaction)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH;
        bytes memory data = transaction.data;
        uint256 salt = transaction.salt;
        uint256 expirationTimeSeconds = transaction.expirationTimeSeconds;
        uint256 gasPrice = transaction.gasPrice;
        address signerAddress = transaction.signerAddress;

        // Assembly for more efficiently computing:
        // result = keccak256(abi.encodePacked(
        //     schemaHash,
        //     salt,
        //     expirationTimeSeconds,
        //     gasPrice,
        //     uint256(signerAddress),
        //     keccak256(data)
        // ));

        assembly {
            // Compute hash of data
            let dataHash := keccak256(add(data, 32), mload(data))

            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, schemaHash)                                                                // hash of schema
            mstore(add(memPtr, 32), salt)                                                             // salt
            mstore(add(memPtr, 64), expirationTimeSeconds)                                            // expirationTimeSeconds
            mstore(add(memPtr, 96), gasPrice)                                                         // gasPrice
            mstore(add(memPtr, 128), and(signerAddress, 0xffffffffffffffffffffffffffffffffffffffff))  // signerAddress
            mstore(add(memPtr, 160), dataHash)                                                        // hash of data

            // Compute hash
            result := keccak256(memPtr, 192)
        }
        return result;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


contract IAssetProxyDispatcher {

    // Logs registration of new asset proxy
    event AssetProxyRegistered(
        bytes4 id,              // Id of new registered AssetProxy.
        address assetProxy      // Address of new registered AssetProxy.
    );

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        external;

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./IExchangeCore.sol";
import "./IProtocolFees.sol";
import "./IMatchOrders.sol";
import "./ISignatureValidator.sol";
import "./ITransactions.sol";
import "./IAssetProxyDispatcher.sol";
import "./IWrapperFunctions.sol";
import "./ITransferSimulator.sol";


// solhint-disable no-empty-blocks
contract IExchange is
    IProtocolFees,
    IExchangeCore,
    IMatchOrders,
    ISignatureValidator,
    ITransactions,
    IAssetProxyDispatcher,
    ITransferSimulator,
    IWrapperFunctions
{}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibFillResults.sol";


contract IExchangeCore {

    // Fill event is emitted whenever an order is filled.
    event Fill(
        address indexed makerAddress,         // Address that created the order.
        address indexed feeRecipientAddress,  // Address that received fees.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        bytes makerFeeAssetData,              // Encoded data specific to makerFeeAsset.
        bytes takerFeeAssetData,              // Encoded data specific to takerFeeAsset.
        bytes32 indexed orderHash,            // EIP712 hash of order (see LibOrder.getTypedDataHash).
        address takerAddress,                 // Address that filled the order.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        uint256 makerAssetFilledAmount,       // Amount of makerAsset sold by maker and bought by taker.
        uint256 takerAssetFilledAmount,       // Amount of takerAsset sold by taker and bought by maker.
        uint256 makerFeePaid,                 // Amount of makerFeeAssetData paid to feeRecipient by maker.
        uint256 takerFeePaid,                 // Amount of takerFeeAssetData paid to feeRecipient by taker.
        uint256 protocolFeePaid               // Amount of eth or weth paid to the staking contract.
    );

    // Cancel event is emitted whenever an individual order is cancelled.
    event Cancel(
        address indexed makerAddress,         // Address that created the order.
        address indexed feeRecipientAddress,  // Address that would have recieved fees if order was filled.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        bytes32 indexed orderHash             // EIP712 hash of order (see LibOrder.getTypedDataHash).
    );

    // CancelUpTo event is emitted whenever `cancelOrdersUpTo` is executed succesfully.
    event CancelUpTo(
        address indexed makerAddress,         // Orders cancelled must have been created by this address.
        address indexed orderSenderAddress,   // Orders cancelled must have a `senderAddress` equal to this address.
        uint256 orderEpoch                    // Orders with specified makerAddress and senderAddress with a salt less than this value are considered cancelled.
    );

    /// @dev Cancels all orders created by makerAddress with a salt less than or equal to the targetOrderEpoch
    ///      and senderAddress equal to msg.sender (or null address if msg.sender == makerAddress).
    /// @param targetOrderEpoch Orders created with a salt less or equal to this value will be cancelled.
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        external
        payable;

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signature Proof that order has been created by maker.
    /// @return Amounts filled and fees paid by maker and taker.
    function fillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(LibOrder.Order memory order)
        public
        payable;

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return OrderInfo Information about the order and its state.
    ///                   See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibFillResults.sol";


contract IMatchOrders {

    /// @dev Match complementary orders that have a profitable spread.
    ///      Each order is filled at their respective price point, and
    ///      the matcher receives a profit denominated in the left maker asset.
    /// @param leftOrders Set of orders with the same maker / taker asset.
    /// @param rightOrders Set of orders to match against `leftOrders`
    /// @param leftSignatures Proof that left orders were created by the left makers.
    /// @param rightSignatures Proof that right orders were created by the right makers.
    /// @return batchMatchedFillResults Amounts filled and profit generated.
    function batchMatchOrders(
        LibOrder.Order[] memory leftOrders,
        LibOrder.Order[] memory rightOrders,
        bytes[] memory leftSignatures,
        bytes[] memory rightSignatures
    )
        public
        payable
        returns (LibFillResults.BatchMatchedFillResults memory batchMatchedFillResults);

    /// @dev Match complementary orders that have a profitable spread.
    ///      Each order is maximally filled at their respective price point, and
    ///      the matcher receives a profit denominated in either the left maker asset,
    ///      right maker asset, or a combination of both.
    /// @param leftOrders Set of orders with the same maker / taker asset.
    /// @param rightOrders Set of orders to match against `leftOrders`
    /// @param leftSignatures Proof that left orders were created by the left makers.
    /// @param rightSignatures Proof that right orders were created by the right makers.
    /// @return batchMatchedFillResults Amounts filled and profit generated.
    function batchMatchOrdersWithMaximalFill(
        LibOrder.Order[] memory leftOrders,
        LibOrder.Order[] memory rightOrders,
        bytes[] memory leftSignatures,
        bytes[] memory rightSignatures
    )
        public
        payable
        returns (LibFillResults.BatchMatchedFillResults memory batchMatchedFillResults);

    /// @dev Match two complementary orders that have a profitable spread.
    ///      Each order is filled at their respective price point. However, the calculations are
    ///      carried out as though the orders are both being filled at the right order's price point.
    ///      The profit made by the left order goes to the taker (who matched the two orders).
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    /// @param leftSignature Proof that order was created by the left maker.
    /// @param rightSignature Proof that order was created by the right maker.
    /// @return matchedFillResults Amounts filled and fees paid by maker and taker of matched orders.
    function matchOrders(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        payable
        returns (LibFillResults.MatchedFillResults memory matchedFillResults);

    /// @dev Match two complementary orders that have a profitable spread.
    ///      Each order is maximally filled at their respective price point, and
    ///      the matcher receives a profit denominated in either the left maker asset,
    ///      right maker asset, or a combination of both.
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    /// @param leftSignature Proof that order was created by the left maker.
    /// @param rightSignature Proof that order was created by the right maker.
    /// @return matchedFillResults Amounts filled by maker and taker of matched orders.
    function matchOrdersWithMaximalFill(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        payable
        returns (LibFillResults.MatchedFillResults memory matchedFillResults);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


contract IProtocolFees {

    // Logs updates to the protocol fee multiplier.
    event ProtocolFeeMultiplier(uint256 oldProtocolFeeMultiplier, uint256 updatedProtocolFeeMultiplier);

    // Logs updates to the protocolFeeCollector address.
    event ProtocolFeeCollectorAddress(address oldProtocolFeeCollector, address updatedProtocolFeeCollector);

    /// @dev Allows the owner to update the protocol fee multiplier.
    /// @param updatedProtocolFeeMultiplier The updated protocol fee multiplier.
    function setProtocolFeeMultiplier(uint256 updatedProtocolFeeMultiplier)
        external;

    /// @dev Allows the owner to update the protocolFeeCollector address.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector)
        external;

    /// @dev Returns the protocolFeeMultiplier
    function protocolFeeMultiplier()
        external
        view
        returns (uint256);

    /// @dev Returns the protocolFeeCollector address
    function protocolFeeCollector()
        external
        view
        returns (address);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibZeroExTransaction.sol";


contract ISignatureValidator {

   // Allowed signature types.
    enum SignatureType {
        Illegal,                     // 0x00, default value
        Invalid,                     // 0x01
        EIP712,                      // 0x02
        EthSign,                     // 0x03
        Wallet,                      // 0x04
        Validator,                   // 0x05
        PreSigned,                   // 0x06
        EIP1271Wallet,               // 0x07
        NSignatureTypes              // 0x08, number of signature types. Always leave at end.
    }

    event SignatureValidatorApproval(
        address indexed signerAddress,     // Address that approves or disapproves a contract to verify signatures.
        address indexed validatorAddress,  // Address of signature validator contract.
        bool isApproved                    // Approval or disapproval of validator contract.
    );

    /// @dev Approves a hash on-chain.
    ///      After presigning a hash, the preSign signature type will become valid for that hash and signer.
    /// @param hash Any 32-byte hash.
    function preSign(bytes32 hash)
        external
        payable;

    /// @dev Approves/unnapproves a Validator contract to verify signatures on signer's behalf.
    /// @param validatorAddress Address of Validator contract.
    /// @param approval Approval or disapproval of  Validator contract.
    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external
        payable;

    /// @dev Verifies that a hash has been signed by the given signer.
    /// @param hash Any 32-byte hash.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid `true` if the signature is valid for the given hash and signer.
    function isValidHashSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);

    /// @dev Verifies that a signature for an order is valid.
    /// @param order The order.
    /// @param signature Proof that the order has been signed by signer.
    /// @return isValid true if the signature is valid for the given order and signer.
    function isValidOrderSignature(
        LibOrder.Order memory order,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);

    /// @dev Verifies that a signature for a transaction is valid.
    /// @param transaction The transaction.
    /// @param signature Proof that the order has been signed by signer.
    /// @return isValid true if the signature is valid for the given transaction and signer.
    function isValidTransactionSignature(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);

    /// @dev Verifies that an order, with provided order hash, has been signed
    ///      by the given signer.
    /// @param order The order.
    /// @param orderHash The hash of the order.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if the signature is valid for the given order and signer.
    function _isValidOrderWithHashSignature(
        LibOrder.Order memory order,
        bytes32 orderHash,
        bytes memory signature
    )
        internal
        view
        returns (bool isValid);

    /// @dev Verifies that a transaction, with provided order hash, has been signed
    ///      by the given signer.
    /// @param transaction The transaction.
    /// @param transactionHash The hash of the transaction.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if the signature is valid for the given transaction and signer.
    function _isValidTransactionWithHashSignature(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes32 transactionHash,
        bytes memory signature
    )
        internal
        view
        returns (bool isValid);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibZeroExTransaction.sol";


contract ITransactions {

    // TransactionExecution event is emitted when a ZeroExTransaction is executed.
    event TransactionExecution(bytes32 indexed transactionHash);

    /// @dev Executes an Exchange method call in the context of signer.
    /// @param transaction 0x transaction containing salt, signerAddress, and data.
    /// @param signature Proof that transaction has been signed by signer.
    /// @return ABI encoded return data of the underlying Exchange function call.
    function executeTransaction(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes memory signature
    )
        public
        payable
        returns (bytes memory);

    /// @dev Executes a batch of Exchange method calls in the context of signer(s).
    /// @param transactions Array of 0x transactions containing salt, signerAddress, and data.
    /// @param signatures Array of proofs that transactions have been signed by signer(s).
    /// @return Array containing ABI encoded return data for each of the underlying Exchange function calls.
    function batchExecuteTransactions(
        LibZeroExTransaction.ZeroExTransaction[] memory transactions,
        bytes[] memory signatures
    )
        public
        payable
        returns (bytes[] memory);

    /// @dev The current function will be called in the context of this address (either 0x transaction signer or `msg.sender`).
    ///      If calling a fill function, this address will represent the taker.
    ///      If calling a cancel function, this address will represent the maker.
    /// @return Signer of 0x transaction if entry point is `executeTransaction`.
    ///         `msg.sender` if entry point is any other function.
    function _getCurrentContextAddress()
        internal
        view
        returns (address);
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


contract ITransferSimulator {

    /// @dev This function may be used to simulate any amount of transfers
    /// As they would occur through the Exchange contract. Note that this function
    /// will always revert, even if all transfers are successful. However, it may
    /// be used with eth_call or with a try/catch pattern in order to simulate
    /// the results of the transfers.
    /// @param assetData Array of asset details, each encoded per the AssetProxy contract specification.
    /// @param fromAddresses Array containing the `from` addresses that correspond with each transfer.
    /// @param toAddresses Array containing the `to` addresses that correspond with each transfer.
    /// @param amounts Array containing the amounts that correspond to each transfer.
    /// @return This function does not return a value. However, it will always revert with
    /// `Error("TRANSFERS_SUCCESSFUL")` if all of the transfers were successful.
    function simulateDispatchTransferFromCalls(
        bytes[] memory assetData,
        address[] memory fromAddresses,
        address[] memory toAddresses,
        uint256[] memory amounts
    )
        public;
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibFillResults.sol";


contract IWrapperFunctions {

    /// @dev Fills the input order. Reverts if exact takerAssetFillAmount not filled.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signature Proof that order has been created by maker.
    function fillOrKillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev Executes multiple calls of fillOrder.
    /// @param orders Array of order specifications.
    /// @param takerAssetFillAmounts Array of desired amounts of takerAsset to sell in orders.
    /// @param signatures Proofs that orders have been created by makers.
    /// @return Array of amounts filled and fees paid by makers and taker.
    function batchFillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults[] memory fillResults);

    /// @dev Executes multiple calls of fillOrKillOrder.
    /// @param orders Array of order specifications.
    /// @param takerAssetFillAmounts Array of desired amounts of takerAsset to sell in orders.
    /// @param signatures Proofs that orders have been created by makers.
    /// @return Array of amounts filled and fees paid by makers and taker.
    function batchFillOrKillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults[] memory fillResults);

    /// @dev Executes multiple calls of fillOrder. If any fill reverts, the error is caught and ignored.
    /// @param orders Array of order specifications.
    /// @param takerAssetFillAmounts Array of desired amounts of takerAsset to sell in orders.
    /// @param signatures Proofs that orders have been created by makers.
    /// @return Array of amounts filled and fees paid by makers and taker.
    function batchFillOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults[] memory fillResults);

    /// @dev Executes multiple calls of fillOrder until total amount of takerAsset is sold by taker.
    ///      If any fill reverts, the error is caught and ignored.
    ///      NOTE: This function does not enforce that the takerAsset is the same for each order.
    /// @param orders Array of order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signatures Proofs that orders have been signed by makers.
    /// @return Amounts filled and fees paid by makers and taker.
    function marketSellOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev Executes multiple calls of fillOrder until total amount of makerAsset is bought by taker.
    ///      If any fill reverts, the error is caught and ignored.
    ///      NOTE: This function does not enforce that the makerAsset is the same for each order.
    /// @param orders Array of order specifications.
    /// @param makerAssetFillAmount Desired amount of makerAsset to buy.
    /// @param signatures Proofs that orders have been signed by makers.
    /// @return Amounts filled and fees paid by makers and taker.
    function marketBuyOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev Calls marketSellOrdersNoThrow then reverts if < takerAssetFillAmount has been sold.
    ///      NOTE: This function does not enforce that the takerAsset is the same for each order.
    /// @param orders Array of order specifications.
    /// @param takerAssetFillAmount Minimum amount of takerAsset to sell.
    /// @param signatures Proofs that orders have been signed by makers.
    /// @return Amounts filled and fees paid by makers and taker.
    function marketSellOrdersFillOrKill(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev Calls marketBuyOrdersNoThrow then reverts if < makerAssetFillAmount has been bought.
    ///      NOTE: This function does not enforce that the makerAsset is the same for each order.
    /// @param orders Array of order specifications.
    /// @param makerAssetFillAmount Minimum amount of makerAsset to buy.
    /// @param signatures Proofs that orders have been signed by makers.
    /// @return Amounts filled and fees paid by makers and taker.
    function marketBuyOrdersFillOrKill(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

    /// @dev Executes multiple calls of cancelOrder.
    /// @param orders Array of order specifications.
    function batchCancelOrders(LibOrder.Order[] memory orders)
        public
        payable;
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibExchangeRichErrors.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";


library LibExchangeRichErrorDecoder {

    using LibBytes for bytes;

    /// @dev Decompose an ABI-encoded SignatureError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode The error code.
    /// @return signerAddress The expected signer of the hash.
    /// @return signature The full signature.
    function decodeSignatureError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.SignatureErrorCodes errorCode,
            bytes32 hash,
            address signerAddress,
            bytes memory signature
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.SignatureErrorSelector());
        uint8 _errorCode;
        (_errorCode, hash, signerAddress, signature) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, bytes32, address, bytes)
        );
        errorCode = LibExchangeRichErrors.SignatureErrorCodes(_errorCode);
    }

    /// @dev Decompose an ABI-encoded SignatureValidatorError.
    /// @param encoded ABI-encoded revert error.
    /// @return signerAddress The expected signer of the hash.
    /// @return signature The full signature bytes.
    /// @return errorData The revert data thrown by the validator contract.
    function decodeEIP1271SignatureError(bytes memory encoded)
        internal
        pure
        returns (
            address verifyingContractAddress,
            bytes memory data,
            bytes memory signature,
            bytes memory errorData
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.EIP1271SignatureErrorSelector());
        (verifyingContractAddress, data, signature, errorData) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (address, bytes, bytes, bytes)
        );
    }

    /// @dev Decompose an ABI-encoded SignatureValidatorNotApprovedError.
    /// @param encoded ABI-encoded revert error.
    /// @return signerAddress The expected signer of the hash.
    /// @return validatorAddress The expected validator.
    function decodeSignatureValidatorNotApprovedError(bytes memory encoded)
        internal
        pure
        returns (
            address signerAddress,
            address validatorAddress
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.SignatureValidatorNotApprovedErrorSelector());
        (signerAddress, validatorAddress) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (address, address)
        );
    }

    /// @dev Decompose an ABI-encoded SignatureWalletError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode The error code.
    /// @return signerAddress The expected signer of the hash.
    /// @return signature The full signature bytes.
    /// @return errorData The revert data thrown by the validator contract.
    function decodeSignatureWalletError(bytes memory encoded)
        internal
        pure
        returns (
            bytes32 hash,
            address signerAddress,
            bytes memory signature,
            bytes memory errorData
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.SignatureWalletErrorSelector());
        (hash, signerAddress, signature, errorData) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes32, address, bytes, bytes)
        );
    }

    /// @dev Decompose an ABI-encoded OrderStatusError.
    /// @param encoded ABI-encoded revert error.
    /// @return orderHash The order hash.
    /// @return orderStatus The order status.
    function decodeOrderStatusError(bytes memory encoded)
        internal
        pure
        returns (
            bytes32 orderHash,
            LibOrder.OrderStatus orderStatus
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.OrderStatusErrorSelector());
        uint8 _orderStatus;
        (orderHash, _orderStatus) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes32, uint8)
        );
        orderStatus = LibOrder.OrderStatus(_orderStatus);
    }

    /// @dev Decompose an ABI-encoded OrderStatusError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode Error code that corresponds to invalid maker, taker, or sender.
    /// @return orderHash The order hash.
    /// @return contextAddress The maker, taker, or sender address
    function decodeExchangeInvalidContextError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.ExchangeContextErrorCodes errorCode,
            bytes32 orderHash,
            address contextAddress
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.ExchangeInvalidContextErrorSelector());
        uint8 _errorCode;
        (_errorCode, orderHash, contextAddress) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, bytes32, address)
        );
        errorCode = LibExchangeRichErrors.ExchangeContextErrorCodes(_errorCode);
    }

    /// @dev Decompose an ABI-encoded FillError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode The error code.
    /// @return orderHash The order hash.
    function decodeFillError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.FillErrorCodes errorCode,
            bytes32 orderHash
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.FillErrorSelector());
        uint8 _errorCode;
        (_errorCode, orderHash) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, bytes32)
        );
        errorCode = LibExchangeRichErrors.FillErrorCodes(_errorCode);
    }

    /// @dev Decompose an ABI-encoded OrderEpochError.
    /// @param encoded ABI-encoded revert error.
    /// @return makerAddress The order maker.
    /// @return orderSenderAddress The order sender.
    /// @return currentEpoch The current epoch for the maker.
    function decodeOrderEpochError(bytes memory encoded)
        internal
        pure
        returns (
            address makerAddress,
            address orderSenderAddress,
            uint256 currentEpoch
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.OrderEpochErrorSelector());
        (makerAddress, orderSenderAddress, currentEpoch) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (address, address, uint256)
        );
    }

    /// @dev Decompose an ABI-encoded AssetProxyExistsError.
    /// @param encoded ABI-encoded revert error.
    /// @return assetProxyId Id of asset proxy.
    /// @return assetProxyAddress The address of the asset proxy.
    function decodeAssetProxyExistsError(bytes memory encoded)
        internal
        pure
        returns (
            bytes4 assetProxyId, address assetProxyAddress)
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.AssetProxyExistsErrorSelector());
        (assetProxyId, assetProxyAddress) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes4, address)
        );
    }

    /// @dev Decompose an ABI-encoded AssetProxyDispatchError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode The error code.
    /// @return orderHash Hash of the order being dispatched.
    /// @return assetData Asset data of the order being dispatched.
    function decodeAssetProxyDispatchError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.AssetProxyDispatchErrorCodes errorCode,
            bytes32 orderHash,
            bytes memory assetData
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.AssetProxyDispatchErrorSelector());
        uint8 _errorCode;
        (_errorCode, orderHash, assetData) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, bytes32, bytes)
        );
        errorCode = LibExchangeRichErrors.AssetProxyDispatchErrorCodes(_errorCode);
    }

    /// @dev Decompose an ABI-encoded AssetProxyTransferError.
    /// @param encoded ABI-encoded revert error.
    /// @return orderHash Hash of the order being dispatched.
    /// @return assetData Asset data of the order being dispatched.
    /// @return errorData ABI-encoded revert data from the asset proxy.
    function decodeAssetProxyTransferError(bytes memory encoded)
        internal
        pure
        returns (
            bytes32 orderHash,
            bytes memory assetData,
            bytes memory errorData
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.AssetProxyTransferErrorSelector());
        (orderHash, assetData, errorData) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes32, bytes, bytes)
        );
    }

    /// @dev Decompose an ABI-encoded NegativeSpreadError.
    /// @param encoded ABI-encoded revert error.
    /// @return leftOrderHash Hash of the left order being matched.
    /// @return rightOrderHash Hash of the right order being matched.
    function decodeNegativeSpreadError(bytes memory encoded)
        internal
        pure
        returns (
            bytes32 leftOrderHash,
            bytes32 rightOrderHash
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.NegativeSpreadErrorSelector());
        (leftOrderHash, rightOrderHash) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes32, bytes32)
        );
    }

    /// @dev Decompose an ABI-encoded TransactionError.
    /// @param encoded ABI-encoded revert error.
    /// @return errorCode The error code.
    /// @return transactionHash Hash of the transaction.
    function decodeTransactionError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.TransactionErrorCodes errorCode,
            bytes32 transactionHash
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.TransactionErrorSelector());
        uint8 _errorCode;
        (_errorCode, transactionHash) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, bytes32)
        );
        errorCode = LibExchangeRichErrors.TransactionErrorCodes(_errorCode);
    }

    /// @dev Decompose an ABI-encoded TransactionExecutionError.
    /// @param encoded ABI-encoded revert error.
    /// @return transactionHash Hash of the transaction.
    /// @return errorData Error thrown by exeucteTransaction().
    function decodeTransactionExecutionError(bytes memory encoded)
        internal
        pure
        returns (
            bytes32 transactionHash,
            bytes memory errorData
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.TransactionExecutionErrorSelector());
        (transactionHash, errorData) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (bytes32, bytes)
        );
    }

    /// @dev Decompose an ABI-encoded IncompleteFillError.
    /// @param encoded ABI-encoded revert error.
    /// @return orderHash Hash of the order being filled.
    function decodeIncompleteFillError(bytes memory encoded)
        internal
        pure
        returns (
            LibExchangeRichErrors.IncompleteFillErrorCode errorCode,
            uint256 expectedAssetFillAmount,
            uint256 actualAssetFillAmount
        )
    {
        _assertSelectorBytes(encoded, LibExchangeRichErrors.IncompleteFillErrorSelector());
        uint8 _errorCode;
        (_errorCode, expectedAssetFillAmount, actualAssetFillAmount) = abi.decode(
            encoded.sliceDestructive(4, encoded.length),
            (uint8, uint256, uint256)
        );
        errorCode = LibExchangeRichErrors.IncompleteFillErrorCode(_errorCode);
    }

    /// @dev Revert if the leading 4 bytes of `encoded` is not `selector`.
    function _assertSelectorBytes(bytes memory encoded, bytes4 selector)
        private
        pure
    {
        bytes4 actualSelector = LibBytes.readBytes4(encoded, 0);
        require(
            actualSelector == selector,
            "BAD_SELECTOR"
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.16;


/// @dev A library for working with 18 digit, base 10 decimals.
library D18 {

    /// @dev Decimal places for dydx value quantities.
    uint256 private constant PRECISION = 18;
    /// @dev 1.0 in base-18 decimal.
    int256 private constant DECIMAL_ONE = int256(10 ** PRECISION);
    /// @dev Minimum signed integer value.
    int256 private constant MIN_INT256_VALUE = int256(0x8000000000000000000000000000000000000000000000000000000000000000);

    /// @dev Return `1.0`
    function one()
        internal
        pure
        returns (int256 r)
    {
        r = DECIMAL_ONE;
    }

    /// @dev Add two decimals.
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        r = _add(a, b);
    }

    /// @dev Add two decimals.
    function add(uint256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _add(int256(a), b);
    }

    /// @dev Add two decimals.
    function add(int256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _add(a, int256(b));
    }

    /// @dev Add two decimals.
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _add(int256(a), int256(b));
    }

    /// @dev Subract two decimals.
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        r = _add(a, -b);
    }

    /// @dev Subract two decimals.
    function sub(uint256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _add(int256(a), -b);
    }

    /// @dev Subract two decimals.
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _add(int256(a), -int256(b));
    }

    /// @dev Multiply two decimals.
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        r = _div(_mul(a, b), DECIMAL_ONE);
    }

    /// @dev Multiply two decimals.
    function mul(uint256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(int256(a), b), DECIMAL_ONE);
    }

    /// @dev Multiply two decimals.
    function mul(int256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(a, int256(b)), DECIMAL_ONE);
    }

    /// @dev Multiply two decimals.
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(int256(a), int256(b)), DECIMAL_ONE);
    }

    /// @dev Divide two decimals.
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        r = _div(_mul(a, DECIMAL_ONE), b);
    }

    /// @dev Divide two decimals.
    function div(uint256 a, int256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(int256(a), DECIMAL_ONE), b);
    }

    /// @dev Divide two decimals.
    function div(int256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(a, DECIMAL_ONE), int256(b));
    }

    /// @dev Divide two decimals.
    function div(uint256 a, uint256 b)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        require(int256(b) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = _div(_mul(int256(a), DECIMAL_ONE), int256(b));
    }

    /// @dev Safely convert an unsigned integer into a signed integer.
    function toSigned(uint256 a)
        internal
        pure
        returns (int256 r)
    {
        require(int256(a) >= 0, "D18/DECIMAL_VALUE_TOO_BIG");
        r = int256(a);
    }

    /// @dev Clip a signed value to be positive.
    function clip(int256 a)
        internal
        pure
        returns (int256 r)
    {
        r = a < 0 ? 0 : a;
    }

    /// @dev Safely multiply two signed integers.
    function _mul(int256 a, int256 b)
        private
        pure
        returns (int256 r)
    {
        if (a == 0 || b == 0) {
            return 0;
        }
        r = a * b;
        require(r / a == b && r / b == a, "D18/DECIMAL_MUL_OVERFLOW");
        return r;
    }

    /// @dev Safely divide two signed integers.
    function _div(int256 a, int256 b)
        private
        pure
        returns (int256 r)
    {
        require(b != 0, "D18/DECIMAL_DIV_BY_ZERO");
        require(a != MIN_INT256_VALUE || b != -1, "D18/DECIMAL_DIV_OVERFLOW");
        r = a / b;
    }

    /// @dev Safely add two signed integers.
    function _add(int256 a, int256 b)
        private
        pure
        returns (int256 r)
    {
        r = a + b;
        require(
            !((a < 0 && b < 0 && r > a) || (a > 0 && b > 0 && r < a)),
            "D18/DECIMAL_ADD_OVERFLOW"
        );
    }

}

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

pragma solidity ^0.5.9;


contract DeploymentConstants {

    // solhint-disable separate-by-one-line-in-contract

    // Mainnet addresses ///////////////////////////////////////////////////////
    /// @dev Mainnet address of the WETH contract.
    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// @dev Mainnet address of the KyberNetworkProxy contract.
    address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
    /// @dev Mainnet address of the KyberHintHandler contract.
    address constant private KYBER_HINT_HANDLER_ADDRESS = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C;
    /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    /// @dev Mainnet address of the `UniswapV2Router01` contract.
    address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    address constant private ETH2DAI_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0x8ED95d1746bf1E4dAb58d8ED4724f1Ef95B20Db0;
    ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    address constant private DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /// @dev Mainnet address of the `Chai` contract
    address constant private CHAI_ADDRESS = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;
    /// @dev Mainnet address of the 0x DevUtils contract.
    address constant private DEV_UTILS_ADDRESS = 0x74134CF88b21383713E096a5ecF59e297dc7f547;
    /// @dev Kyber ETH pseudo-address.
    address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Mainnet address of the dYdX contract.
    address constant private DYDX_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    /// @dev Mainnet address of the GST2 contract
    address constant private GST_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    /// @dev Mainnet address of the GST Collector
    address constant private GST_COLLECTOR_ADDRESS = 0x000000D3b08566BE75A6DB803C03C85C0c1c5B96;
    /// @dev Mainnet address of the mStable mUSD contract.
    address constant private MUSD_ADDRESS = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    /// @dev Mainnet address of the Mooniswap Registry contract
    address constant private MOONISWAP_REGISTRY = 0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303;
    /// @dev Mainnet address of the DODO Registry (ZOO) contract
    address constant private DODO_REGISTRY = 0x3A97247DF274a17C59A3bd12735ea3FcDFb49950;
    /// @dev Mainnet address of the DODO Helper contract
    address constant private DODO_HELPER = 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb;

    // // Ropsten addresses ///////////////////////////////////////////////////////
    // /// @dev Mainnet address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // /// @dev Mainnet address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0xd719c34261e099Fdb33030ac8909d5788D3039C4;
    // /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351;
    // /// @dev Mainnet address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0xb344afeD348de15eb4a9e180205A2B0739628339;
    // ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0xC812AF3f3fBC62F76ea4262576EC0f49dB8B7f1c;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Mainnet address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = 0x4E1000616990D83e56f4b5fC6CC8602DcfD20459;

    // // Rinkeby addresses ///////////////////////////////////////////////////////
    // /// @dev Mainnet address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // /// @dev Mainnet address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x0d5371e5EE23dec7DF251A8957279629aa79E9C5;
    // /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36;
    // /// @dev Mainnet address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0xA2AA4bEFED748Fba27a3bE7Dfd2C4b2c6DB1F49B;
    // ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0x46B5BC959e8A754c0256FFF73bF34A52Ad5CdfA9;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Mainnet address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = address(0);

    // // Kovan addresses /////////////////////////////////////////////////////////
    // /// @dev Kovan address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // /// @dev Kovan address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    // /// @dev Kovan address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30;
    // /// @dev Kovan address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Kovan address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = 0xe325acB9765b02b8b418199bf9650972299235F4;
    // /// @dev Kovan address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0x3577552C1Fb7A44aD76BeEB7aB53251668A21F8D;
    // /// @dev Kovan address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Kovan address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    // /// @dev Kovan address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0x9402639A828BdF4E9e4103ac3B69E1a6E522eB59;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Kovan address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Kovan address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Kovan address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = address(0);

    /// @dev Overridable way to get the `KyberNetworkProxy` address.
    /// @return kyberAddress The `IKyberNetworkProxy` address.
    function _getKyberNetworkProxyAddress()
        internal
        view
        returns (address kyberAddress)
    {
        return KYBER_NETWORK_PROXY_ADDRESS;
    }

    /// @dev Overridable way to get the `KyberHintHandler` address.
    /// @return kyberAddress The `IKyberHintHandler` address.
    function _getKyberHintHandlerAddress()
        internal
        view
        returns (address hintHandlerAddress)
    {
        return KYBER_HINT_HANDLER_ADDRESS;
    }

    /// @dev Overridable way to get the WETH address.
    /// @return wethAddress The WETH address.
    function _getWethAddress()
        internal
        view
        returns (address wethAddress)
    {
        return WETH_ADDRESS;
    }

    /// @dev Overridable way to get the `UniswapExchangeFactory` address.
    /// @return uniswapAddress The `UniswapExchangeFactory` address.
    function _getUniswapExchangeFactoryAddress()
        internal
        view
        returns (address uniswapAddress)
    {
        return UNISWAP_EXCHANGE_FACTORY_ADDRESS;
    }

    /// @dev Overridable way to get the `UniswapV2Router01` address.
    /// @return uniswapRouterAddress The `UniswapV2Router01` address.
    function _getUniswapV2Router01Address()
        internal
        view
        returns (address uniswapRouterAddress)
    {
        return UNISWAP_V2_ROUTER_01_ADDRESS;
    }

    /// @dev An overridable way to retrieve the Eth2Dai `MatchingMarket` contract.
    /// @return eth2daiAddress The Eth2Dai `MatchingMarket` contract.
    function _getEth2DaiAddress()
        internal
        view
        returns (address eth2daiAddress)
    {
        return ETH2DAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `ERC20BridgeProxy` contract.
    /// @return erc20BridgeProxyAddress The `ERC20BridgeProxy` contract.
    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address erc20BridgeProxyAddress)
    {
        return ERC20_BRIDGE_PROXY_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `Dai` contract.
    /// @return daiAddress The `Dai` contract.
    function _getDaiAddress()
        internal
        view
        returns (address daiAddress)
    {
        return DAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `Chai` contract.
    /// @return chaiAddress The `Chai` contract.
    function _getChaiAddress()
        internal
        view
        returns (address chaiAddress)
    {
        return CHAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the 0x `DevUtils` contract address.
    /// @return devUtils The 0x `DevUtils` contract address.
    function _getDevUtilsAddress()
        internal
        view
        returns (address devUtils)
    {
        return DEV_UTILS_ADDRESS;
    }

    /// @dev Overridable way to get the DyDx contract.
    /// @return exchange The DyDx exchange contract.
    function _getDydxAddress()
        internal
        view
        returns (address dydxAddress)
    {
        return DYDX_ADDRESS;
    }

    /// @dev An overridable way to retrieve the GST2 contract address.
    /// @return gst The GST contract.
    function _getGstAddress()
        internal
        view
        returns (address gst)
    {
        return GST_ADDRESS;
    }

    /// @dev An overridable way to retrieve the GST Collector address.
    /// @return collector The GST collector address.
    function _getGstCollectorAddress()
        internal
        view
        returns (address collector)
    {
        return GST_COLLECTOR_ADDRESS;
    }

    /// @dev An overridable way to retrieve the mStable mUSD address.
    /// @return musd The mStable mUSD address.
    function _getMUsdAddress()
        internal
        view
        returns (address musd)
    {
        return MUSD_ADDRESS;
    }

    /// @dev An overridable way to retrieve the Mooniswap registry address.
    /// @return registry The Mooniswap registry address.
    function _getMooniswapAddress()
        internal
        view
        returns (address)
    {
        return MOONISWAP_REGISTRY;
    }

    /// @dev An overridable way to retrieve the DODO Registry contract address.
    /// @return registry The DODO Registry contract address.
    function _getDODORegistryAddress()
        internal
        view
        returns (address)
    {
        return DODO_REGISTRY;
    }

    /// @dev An overridable way to retrieve the DODO Helper contract address.
    /// @return registry The DODO Helper contract address.
    function _getDODOHelperAddress()
        internal
        view
        returns (address)
    {
        return DODO_HELPER;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "./LibBytesRichErrors.sol";
import "./LibRichErrors.sol";


library LibBytes {

    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


library LibBytesRichErrors {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


library LibEIP712 {

    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    )
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
        internal
        pure
        returns (bytes32 result)
    {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

pragma solidity ^0.5.9;

import "./LibRichErrors.sol";
import "./LibSafeMathRichErrors.sol";


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

pragma solidity ^0.5.9;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

{
  "remappings": [],
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": true,
      "peephole": true,
      "yul": true,
      "yulDetails": {
        "stackAllocation": true
      }
    },
    "runs": 1000000
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/Users/sgu/4k/dev-utils/contracts/dev-utils/src/LibAssetData.sol": {
      "LibAssetData": "0xB59be90511370d924015AB043E871ffCC5f955Ed"
    },
    "/Users/sgu/4k/dev-utils/contracts/dev-utils/src/LibDydxBalance.sol": {
      "LibDydxBalance": "0x45e7138a68064c9985EC13007E17D785895a9844"
    },
    "/Users/sgu/4k/dev-utils/contracts/dev-utils/src/LibOrderTransferSimulation.sol": {
      "LibOrderTransferSimulation": "0xfF29c5A98054ddbcccfa0135bAb02F96943b4597"
    },
    "/Users/sgu/4k/dev-utils/contracts/dev-utils/src/LibTransactionDecoder.sol": {
      "LibTransactionDecoder": "0x73949785668BBB31Dd01c84b6Dd9Aaf84515d35f"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}