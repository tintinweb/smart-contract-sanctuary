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
pragma solidity ^0.5.2;

import "MerkleStatementContract.sol";

contract MerkleStatementVerifier is IMerkleVerifier {
    MerkleStatementContract merkleStatementContract;

    constructor(address merkleStatementContractAddress) internal {
        merkleStatementContract = MerkleStatementContract(merkleStatementContractAddress);
    }

    // Computes the hash of the Merkle statement, and verifies that it is registered in the
    // Merkle Fact Registry. Receives as input the queuePtr (as address), its length
    // the numbers of queries n, and the root. The channelPtr is is ignored.
    function verify(uint256 /*channelPtr*/, uint256 queuePtr, bytes32 root, uint256 n) internal view
        returns(bytes32) {
        bytes32 statement;
        require(n <= MAX_N_MERKLE_VERIFIER_QUERIES, "TOO_MANY_MERKLE_QUERIES");

        assembly {
            let dataToHashPtrStart := mload(0x40) // freePtr.
            let dataToHashPtrCur := dataToHashPtrStart

            let queEndPtr := add(queuePtr, mul(n, 0x40))

            for { } lt(queuePtr, queEndPtr) { } {
                mstore(dataToHashPtrCur, mload(queuePtr))
                dataToHashPtrCur := add(dataToHashPtrCur, 0x20)
                queuePtr := add(queuePtr, 0x20)
            }

            mstore(dataToHashPtrCur, root)
            dataToHashPtrCur := add(dataToHashPtrCur, 0x20)
            mstore(0x40, dataToHashPtrCur)

            statement := keccak256(dataToHashPtrStart, sub(dataToHashPtrCur, dataToHashPtrStart))
        }
        require(merkleStatementContract.isValid(statement), "INVALIDATED_MERKLE_STATEMENT");
        return root;
    }

}
