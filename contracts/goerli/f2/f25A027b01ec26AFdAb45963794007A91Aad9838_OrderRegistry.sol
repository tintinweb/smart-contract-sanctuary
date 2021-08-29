/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "MessageRegistry.sol";

contract OrderRegistry is MessageRegistry {
    event LogL1LimitOrderRegistered(
        address userAddress,
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    );

    uint256 constant MASK_32 = 0xFFFFFFFF;
    uint256 constant MASK_64 = 0xFFFFFFFFFFFFFFFF;
    uint256 constant LIMIT_ORDER_TYPE = 0x3;

    function identify() external pure override returns (string memory) {
        return "StarkWare_OrderRegistry_2021_1";
    }

    function calcL1LimitOrderHash(
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) public pure returns (bytes32) {
        uint256 packed_word0 = amountSell & MASK_64;
        packed_word0 = (packed_word0 << 64) + (amountBuy & MASK_64);
        packed_word0 = (packed_word0 << 64) + (amountFee & MASK_64);
        packed_word0 = (packed_word0 << 32) + (nonce & MASK_32);

        uint256 packed_word1 = LIMIT_ORDER_TYPE;
        packed_word1 = (packed_word1 << 64) + (vaultIdFee & MASK_64);
        packed_word1 = (packed_word1 << 64) + (vaultIdSell & MASK_64);
        packed_word1 = (packed_word1 << 64) + (vaultIdBuy & MASK_64);
        packed_word1 = (packed_word1 << 32) + (expirationTimestamp & MASK_32);
        packed_word1 = packed_word1 << 17;

        return
            keccak256(
                abi.encode(
                    [
                        bytes32(tokenIdSell),
                        bytes32(tokenIdBuy),
                        bytes32(tokenIdFee),
                        bytes32(packed_word0),
                        bytes32(packed_word1)
                    ]
                )
            );
    }

    function registerLimitOrder(
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) external {
        bytes32 orderHash =
            calcL1LimitOrderHash(
                tokenIdSell,
                tokenIdBuy,
                tokenIdFee,
                amountSell,
                amountBuy,
                amountFee,
                vaultIdSell,
                vaultIdBuy,
                vaultIdFee,
                nonce,
                expirationTimestamp
            );
        registerMessage(exchangeAddress, orderHash);

        emit LogL1LimitOrderRegistered(
            msg.sender,
            exchangeAddress,
            tokenIdSell,
            tokenIdBuy,
            tokenIdFee,
            amountSell,
            amountBuy,
            amountFee,
            vaultIdSell,
            vaultIdBuy,
            vaultIdFee,
            nonce,
            expirationTimestamp
        );
    }
}