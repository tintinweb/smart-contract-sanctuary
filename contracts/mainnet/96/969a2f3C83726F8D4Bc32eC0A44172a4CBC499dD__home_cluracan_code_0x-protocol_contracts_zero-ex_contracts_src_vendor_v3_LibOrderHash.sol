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

import "./IExchange.sol";


library LibOrderHash {

    using LibOrderHash for IExchange.Order;

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

    /// @dev Calculates the EIP712 typed data hash of an order with a given domain separator.
    /// @param order The order structure.
    /// @param eip712ExchangeDomainHash Domain hash for the Exchange.
    /// @return orderHash EIP712 typed data hash of the order.
    function getTypedDataHash(IExchange.Order memory order, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = _hashEIP712Message(
            eip712ExchangeDomainHash,
            order.getStructHash()
        );
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order struct.
    /// @param order The order structure.
    /// @return result EIP712 hash of the order struct.
    function getStructHash(IExchange.Order memory order)
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

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function _hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
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
