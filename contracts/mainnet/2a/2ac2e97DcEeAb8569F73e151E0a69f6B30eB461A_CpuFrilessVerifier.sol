/*
  Copyright 2019-2022 StarkWare Industries Ltd.

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
pragma solidity ^0.6.12;

import "CpuVerifier.sol";
import "FriStatementVerifier.sol";
import "MerkleStatementVerifier.sol";

contract CpuFrilessVerifier is CpuVerifier, MerkleStatementVerifier, FriStatementVerifier {
    constructor(
        address[] memory auxPolynomials,
        address oodsContract,
        address memoryPageFactRegistry_,
        address merkleStatementContractAddress,
        address friStatementContractAddress,
        uint256 numSecurityBits_,
        uint256 minProofOfWorkBits_
    )
        public
        MerkleStatementVerifier(merkleStatementContractAddress)
        FriStatementVerifier(friStatementContractAddress)
        CpuVerifier(
            auxPolynomials,
            oodsContract,
            memoryPageFactRegistry_,
            numSecurityBits_,
            minProofOfWorkBits_
        )
    {}

    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view override(MerkleStatementVerifier, MerkleVerifier) returns (bytes32) {
        return MerkleStatementVerifier.verifyMerkle(channelPtr, queuePtr, root, n);
    }

    function friVerifyLayers(uint256[] memory ctx)
        internal
        view
        override(FriStatementVerifier, Fri)
    {
        FriStatementVerifier.friVerifyLayers(ctx);
    }
}