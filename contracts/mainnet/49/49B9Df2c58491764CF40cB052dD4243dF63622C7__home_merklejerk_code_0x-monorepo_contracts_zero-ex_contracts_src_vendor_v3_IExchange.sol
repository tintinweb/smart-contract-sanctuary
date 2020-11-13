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


/// @dev Interface to the V3 Exchange.
interface IExchange {

    /// @dev V3 Order structure.
    struct Order {
        // Address that created the order.
        address makerAddress;
        // Address that is allowed to fill the order.
        // If set to 0, any address is allowed to fill the order.
        address takerAddress;
        // Address that will recieve fees when order is filled.
        address feeRecipientAddress;
        // Address that is allowed to call Exchange contract methods that affect this order.
        // If set to 0, any address is allowed to call these methods.
        address senderAddress;
        // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 makerAssetAmount;
        // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 takerAssetAmount;
        // Fee paid to feeRecipient by maker when order is filled.
        uint256 makerFee;
        // Fee paid to feeRecipient by taker when order is filled.
        uint256 takerFee;
        // Timestamp in seconds at which order expires.
        uint256 expirationTimeSeconds;
        // Arbitrary number to facilitate uniqueness of the order's hash.
        uint256 salt;
        // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes makerAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;
    }

    /// @dev V3 `fillOrder()` results.`
    struct FillResults {
        // Total amount of makerAsset(s) filled.
        uint256 makerAssetFilledAmount;
        // Total amount of takerAsset(s) filled.
        uint256 takerAssetFilledAmount;
        // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 makerFeePaid;
        // Total amount of fees paid by taker to feeRecipients(s).
        uint256 takerFeePaid;
        // Total amount of fees paid by taker to the staking contract.
        uint256 protocolFeePaid;
    }

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signature Proof that order has been created by maker.
    /// @return fillResults Amounts filled and fees paid by maker and taker.
    function fillOrder(
        Order calldata order,
        uint256 takerAssetFillAmount,
        bytes calldata signature
    )
        external
        payable
        returns (FillResults memory fillResults);

    /// @dev Returns the protocolFeeMultiplier
    /// @return multiplier The multiplier for protocol fees.
    function protocolFeeMultiplier()
        external
        view
        returns (uint256 multiplier);

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return proxyAddress The asset proxy registered to assetProxyId.
    ///         Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address proxyAddress);
}
