/*
  Copyright 2019,2020 StarkWare Industries Ltd.

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

import "PedersenMerkleVerifier.sol";
import "FactRegistry.sol";
import "ProgramOutputOffsets.sol";

/*
  A PerpetualEscapeVerifier is a fact registry contract for claims of the form:
    The owner of 'publicKey' may withdraw 'withdrawalAmount' qunatized collateral units
    from 'positionId' assuming the hash of the shared state is 'sharedStateHash'

  The fact is encoded as:
    keccak256(abi.encodePacked(
        publicKey, withdrawalAmount, sharedStateHash, positionId).
*/
contract PerpetualEscapeVerifier is PedersenMerkleVerifier, FactRegistry, ProgramOutputOffsets {
    uint256 internal constant N_ASSETS_BITS = 16;
    uint256 internal constant BALANCE_BITS = 64;
    uint256 internal constant FUNDING_BITS = 64;
    uint256 internal constant BALANCE_BIAS = 2**63;
    uint256 internal constant FXP_BITS = 32;

    uint256 internal constant FUNDING_ENTRY_SIZE = 2;
    uint256 internal constant PRICE_ENTRY_SIZE = 2;

    constructor(address[N_TABLES] memory tables)
        PedersenMerkleVerifier(tables)
        public
    {
    }

    /*
      Finds an entry corresponding to assetId in the slice array[startIdx:endIdx].
      Assumes that size of each entry is 2 and that the key is in offset 0 of an entry.
    */
    function findAssetId(
        uint256 assetId, uint256[] memory array, uint256 startIdx, uint256 endIdx)
        internal pure returns (uint256 idx) {
        idx = startIdx;
        while(array[idx] != assetId) {
            idx += /*entry_size*/2;
            require(idx < endIdx, "assetId not found.");
        }
    }


    /*
      Computes the balance of the position according to the sharedState.

      Assumes the position is given as
      [
       positionAsset_0, positionAsset_1, ..., positionAsset_{n_assets},
       publicKey, biasedBalance << N_ASSETS_BITS | nAssets,
      ]
      where positionAsset_{i} is encoded as
         assedId << 128 | cachedFunding << BALANCE_BITS | biased_asset_balance.

    */
    function computeFxpBalance(
        uint256[] memory position, uint256[] memory sharedState)
        internal pure returns (int256) {

        uint256 nAssets;
        uint256 fxpBalance;

        {
            // Decode collateral_balance and nAssets.
            uint256 lastWord = position[position.length - 1];
            nAssets = lastWord & ((1 << N_ASSETS_BITS) - 1);
            uint256 biasedBalance = lastWord >> N_ASSETS_BITS;

            require(position.length == nAssets + 2, "Bad number of assets.");
            require(biasedBalance < 2**BALANCE_BITS, "Bad balance.");

            fxpBalance = (biasedBalance - BALANCE_BIAS) << FXP_BITS;
        }

        uint256 fundingIndicesOffset = STATE_OFFSET_FUNDING;
        uint256 nFundingIndices = sharedState[fundingIndicesOffset - 1];

        uint256 fundingEnd = fundingIndicesOffset + FUNDING_ENTRY_SIZE * nFundingIndices;

        // Skip global_funding_indices.timestamp and nPrices.
        uint256 pricesOffset = fundingEnd + 2;
        uint256 nPrices = sharedState[pricesOffset - 1];
        uint256 pricesEnd = pricesOffset + PRICE_ENTRY_SIZE * nPrices;
        // Copy sharedState ptr to workaround stack too deep.
        uint256[] memory sharedStateCopy = sharedState;

        uint256 fundingTotal = 0;
        for (uint256 i = 0; i < nAssets; i++) {
            // Decodes a positionAsset (See encoding in the function description).
            uint256 positionAsset = position[i];
            uint256 assedId = positionAsset >> 128;

            // Note that the funding_indices in both the position and the shared state
            // are biased by the same amount.
            uint256 cachedFunding = (positionAsset >> BALANCE_BITS) & (2**FUNDING_BITS - 1);
            uint256 assetBalance = positionAsset & (2**BALANCE_BITS - 1) - BALANCE_BIAS;

            fundingIndicesOffset = findAssetId(
                assedId, sharedStateCopy, fundingIndicesOffset, fundingEnd);
            fundingTotal -= assetBalance *
                (sharedStateCopy[fundingIndicesOffset + 1] - cachedFunding);

            pricesOffset = findAssetId(assedId, sharedStateCopy, pricesOffset, pricesEnd);
            fxpBalance += assetBalance * sharedStateCopy[pricesOffset + 1];
        }

        uint256 truncatedFunding = fundingTotal & ~(2**FXP_BITS - 1);
        return int256(fxpBalance + truncatedFunding);
    }


    /*
      Extracts the position from the escapeProof.

      Assumes the position is encoded in the first (nAssets + 2) right nodes in the merkleProof.
      and that each pair of nodes is encoded in 2 256bits words as follows:
      +-------------------------------+---------------------------+-----------+
      | left_node_i (252)             | right_node_i (252)        | zeros (8) |
      +-------------------------------+---------------------------+-----------+

      See PedersenMerkleVerifier.sol for more details.
    */
    function extractPosition(uint256[] memory merkleProof, uint256 nAssets)
        internal pure
        returns (uint256 positionId, uint256[] memory position) {

        require((merkleProof[0] >> 8) == 0, 'Position hash-chain must start with 0.');

        uint256 positionLength = nAssets + 2;
        position = new uint256[](positionLength);
        uint256 nodeIdx = merkleProof[merkleProof.length - 1] >> 8;

        // Check that the merkleProof starts with a hash_chain of 'positionLength' elements.
        require(
            (nodeIdx & ((1 << positionLength) - 1)) == 0,
            "merkleProof is inconsistent with nAssets.");
        positionId = nodeIdx >> positionLength;

        assembly {
            let positionPtr := add(position, 0x20)
            let positionEnd := add(positionPtr, mul(mload(position), 0x20))
            let proofPtr := add(merkleProof, 0x3f)

            for { } lt(positionPtr, positionEnd)  { positionPtr := add(positionPtr, 0x20) } {
                mstore(positionPtr, and(mload(proofPtr),
                       0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
                proofPtr := add(proofPtr, 0x40)
            }
        }
    }


    /*
      Verifies an escape and registers the corresponding fact as
        keccak256(abi.encodePacked(
            publicKey, withdrawalAmount, sharedStateHash, positionId)).

      The escape verification has two parts:
        a. verifying that a certain position belongs to the position tree in the shared state.
        b. computing the amount that may be withdrawan from that position.

      Part a is delegated to the PedersenMerkleVerifier.
      To this end the position is encoded in the prefix of the merkleProof and the node_selector at
      the end of the merkleProof is adjusted accordingly.
    */
    function verifyEscape(
        uint256[] calldata merkleProof, uint256 nAssets, uint256[] calldata sharedState) external {
        (uint256 positionId, uint256[] memory position) = extractPosition(merkleProof, nAssets);

        int256 withdrawalAmount = computeFxpBalance(position, sharedState) >> FXP_BITS;

        // Each hash takes 2 256bit words and the last two words are the root and nodeIdx.
        uint256 nHashes = (merkleProof.length - 2) / 2; // NOLINT: divide-before-multiply.
        uint256 positionTreeHeight = nHashes - position.length;

        require(
            sharedState[STATE_OFFSET_VAULTS_ROOT] == (merkleProof[merkleProof.length - 2] >> 4),
            "merkleProof is inconsistent with the root in the sharedState.");

        require(
            sharedState[STATE_OFFSET_VAULTS_HEIGHT] == positionTreeHeight,
            "merkleProof is inconsistent with the height in the sharedState.");

        require(withdrawalAmount > 0, "Withdrawal amount must be positive.");
        bytes32 sharedStateHash = keccak256(abi.encodePacked(sharedState));

        uint256 publicKey = position[nAssets];
        bytes32 fact = keccak256(
            abi.encodePacked(
            publicKey, withdrawalAmount, sharedStateHash, positionId));

        verifyMerkle(merkleProof);

        registerFact(fact);
    }
}