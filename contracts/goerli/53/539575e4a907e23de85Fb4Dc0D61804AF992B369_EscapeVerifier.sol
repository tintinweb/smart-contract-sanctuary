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

import "IFactRegistry.sol";

/*
  An escapeVerifier is a fact registry contract for claims of the form:
  (starkKey, assetId, quantizedAmount) is the leaf in index vaultId of a Merkle tree with
  specific height and root.
*/
contract EscapeVerifier is IFactRegistry {

    // Note that those values are hardcoded in the assembly.
    uint256 constant internal N_TABLES = 63;

    address[N_TABLES] lookupTables;
    constructor(address[N_TABLES] memory tables) public {
        lookupTables = tables;

        assembly {
            if gt(lookupTables_slot, 0) {
                // The address of the lookupTables must be 0.
                // This is guaranteed by the ABI, as long as it is the first storage variable.
                // This is an assumption in the implementation, and can be removed if
                // the lookup table address is taken into account.
                revert(0, 0)
            }

        }
    }

    /**
      Verifies that the contents of a vault belong to a certain Merkle commitment (root).

      The Merkle commitment uses the Pedersen hash variation described next:

      - **Hash constants:** A sequence :math:`p_i` of 504 points on an elliptic curve and an additional :math:`ec_{shift}` point
      - **Input:** A vector of 504 bits :math:`b_i`
      - **Output:** The 252 bits x coordinate of :math:`(ec_{shift} + \sum_i b_i*p_i)`

      The following table describes the expected `escapeProof` format. Note that unlike a standard
      Merkle proof, the `escapeProof` contains both the nodes along the Merkle path and their
      siblings. The proof ends with the expected root and the ID of the vault for which the proof is
      submitted (which implies the location of the nodes within the Merkle tree).

          +-------------------------------+---------------------------+-----------+
          | starkKey (252)                | assetId (252)             | zeros (8) |
          +-------------------------------+---------------------------+-----------+
          | hash(starkKey, assetId) (252) | quantizedAmount (252)     | zeros (8) |
          +-------------------------------+---------------------------+-----------+
          | left_node_0 (252)             | right_node_0 (252)        | zeros (8) |
          +-------------------------------+---------------------------+-----------+
          | ...                                                                   |
          +-------------------------------+---------------------------+-----------+
          | left_node_n (252)             | right_node_n (252)        | zeros (8) |
          +-------------------------------+-----------+---------------+-----------+
          | root (252)                    | zeros (4) | vaultId (248) | zeros (8) |
          +-------------------------------+-----------+---------------+-----------+

      If the proof is accepted, this is registered under the following claim hash that may later
      be queried for validity:

        `claimHash = keccak256(starkKey, assetId, quantizedAmount, vaultRoot, treeHeight, vaultId)`

      For information about when this module is to be used, see :sol:mod:`Escapes`.

    */
    /*
      Implementation details:
      The EC sum required for the hash computation is computed using lookup tables and EC additions.
      There are 63 lookup tables and each table contains all the possible subset sums of the
      corresponding 8 EC points in the hash definition.

      Both the full subset sum and the tables are shifted to avoid a special case for the 0 point.
      lookupTables[0] uses the offset 2^62*ec_shift and lookupTables[k] for k > 0 uses
      the offset 2^(62-k)*(-ec_shift).
      Note that the sum of the shifts of all the tables is exactly the shift required for the
      hash. Moreover, the partial sums of those shifts are never 0.

      The calls to the lookup table contracts are batched to save on gas cost.
      We allocate a table of N_HASHES by N_TABLES EC elements.
      Fill the i'th row by calling the i'th lookup contract to lookup the i'th byte in each hash and
      then compute the j'th hash by summing the j'th column.

                  N_HASHES
              --------------
              |            |
              |            |
              |            |
              |            | N_TABLES
              |            |
              |            |
              |            |
              |            |
              --------------

      The batched lookup is facilitated by the fact that the escapeProof includes nodes along the
      Merkle path.
      However having this redundant information requires us to do consistency checks
      to ensure we indeed verify a coherent authentication path:

          hash((left_node_{i-1}, right_node_{i-1})) ==
            (vaultId & (1<<i)) == 0 ? left_node_i : right_node_i.
    */
    function verifyEscape(uint256[] calldata escapeProof) external {
        uint256 proofLength = escapeProof.length;

        // The minimal supported proof length is for a tree height of 31 in a 68 word representation as follows:
        // 1. 2 word pairs representing the vault contents + one hash of the 1st pair.
        // 2. 31  word pairs representing the authentication path.
        // 3. 1 word pair representing the root and the leaf index.
        require(proofLength >= 68, "Proof too short.");

        // The contract supports verification paths of lengths up to 97 in a 200 word representation as described above.
        // This limitation is imposed in order to avoid potential attacks.
        require(proofLength < 200, "Proof too long.");

        // Ensure proofs are always a series of word pairs.
        require((proofLength & 1) == 0, "Proof length must be even.");

        // Each hash takes 2 256bit words and the last two words are the root and vaultId.
        uint256 nHashes = (proofLength - 2) / 2; // NOLINT: divide-before-multiply.

        // We use 2 hashes to compute the leaf.
        uint256 height = nHashes - 2;

        // Note that it is important to limit the range of vault id, to make sure
        // we use the node = Merkle_root in the last iteration of the loop below.
        uint256 vaultId = escapeProof[proofLength - 1] >> 8;
        require(vaultId < 2**height, "vaultId not in tree.");

        uint256 rowSize = (2 * nHashes) * 0x20;
        uint256[] memory proof = escapeProof;
        assembly {
            // Skip the length of the proof array.
            proof := add(proof, 0x20)

            function raise_error(message, msg_len) {
                // Solidity generates reverts with reason that look as follows:
                // 1. 4 bytes with the constant 0x08c379a0 (== Keccak256(b'Error(string)')[:4]).
                // 2. 32 bytes offset bytes (typically 0x20).
                // 3. 32 bytes with the length of the revert reason.
                // 4. Revert reason string.

                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x4, 0x20)
                mstore(0x24, msg_len)
                mstore(0x44, message)
                revert(0, add(0x44, msg_len))
            }

            let starkKey := shr(4, mload(proof))
            let assetId := and(mload(add(proof, 0x1f)),
                               0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)

            let primeMinusOne := 0x800000000000011000000000000000000000000000000000000000000000000
            if or(gt(starkKey, primeMinusOne), gt(assetId, primeMinusOne)) {
                raise_error("Bad starkKey or assetId.", 24)
            }

            // hash(starkKey, assetId) is on the left of the second hash.
            let nodeSelectors := shl(1, vaultId)

            // Allocate EC points table with dimensions N_TABLES by N_HASHES.
            let table := mload(0x40)
            let tableEnd := add(table, mul(rowSize, /*N_TABLES*/63))

            // for i = 0..N_TABLES-1, fill the i'th row in the table.
            for { let i := 0 } lt(i, 63) { i := add(i, 1)} {
                if iszero(staticcall(gas(), sload(i), add(proof, i), rowSize,
                                     add(table, mul(i, rowSize)), rowSize)) {
                   returndatacopy(0, 0, returndatasize())
                   revert(0, returndatasize())
                }
            }

            // The following variables are allocated above PRIME to avoid the stack too deep error.
            // Byte offset used to access the table and proof.
            let offset := 0
            let ptr
            let aZ

            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001

            // For k = 0..HASHES-1, Compute the k'th hash by summing the k'th column in table.
            // Instead of k we use offset := k * sizeof(EC point).
            // Additonally we use ptr := offset + j * rowSize to ge over the EC points we want
            // to sum.
            for { } lt(offset, rowSize) { } {
                // Init (aX, aY, aZ) to the first value in the current column and sum over the
                // column.
                ptr := add(table, offset)
                aZ := 1
                let aX := mload(ptr)
                let aY := mload(add(ptr, 0x20))

                for { ptr := add(ptr, rowSize) } lt(ptr, tableEnd)
                    { ptr:= add(ptr, rowSize) } {

                    let bX := mload(ptr)
                    let bY := mload(add(ptr, 0x20))

                    // Set (aX, aY, aZ) to be the sum of the EC points (aX, aY, aZ) and (bX, bY, 1).
                    let minusAZ := sub(PRIME, aZ)
                    // Slope = sN/sD =  {(aY/aZ) - (bY/1)} / {(aX/aZ) - (bX/1)}.
                    // sN = aY - bY * aZ.
                    let sN := addmod(aY, mulmod(minusAZ, bY, PRIME), PRIME)

                    let minusAZBX := mulmod(minusAZ, bX, PRIME)
                    // sD = aX - bX * aZ.
                    let sD := addmod(aX, minusAZBX, PRIME)

                    let sSqrD := mulmod(sD, sD, PRIME)

                    // Compute the (affine) x coordinate of the result as xN/xD.

                    // (xN/xD) = ((sN)^2/(sD)^2) - (aX/aZ) - (bX/1).
                    // xN = (sN)^2 * aZ - aX * (sD)^2 - bX * (sD)^2 * aZ.
                    // = (sN)^2 * aZ + (sD^2) (bX * (-aZ) - aX).
                    let xN := addmod(mulmod(mulmod(sN, sN, PRIME), aZ, PRIME),
                                    mulmod(sSqrD,
                                            add(minusAZBX, sub(PRIME, aX)),
                                            PRIME),
                                    PRIME)

                    // xD = (sD)^2 * aZ.
                    let xD := mulmod(sSqrD, aZ, PRIME)

                    // Compute (aX', aY', aZ') for the next iteration and assigning them to (aX, aY, aZ).
                    // (y/z) = (sN/sD) * {(bX/1) - (xN/xD)} - (bY/1).
                    // aZ' = sD*xD.
                    aZ := mulmod(sD, xD, PRIME)
                    // aY' = sN*(bX * xD - xN) - bY*z = -bY * z + sN * (-xN + xD*bX).
                    aY := addmod(sub(PRIME, mulmod(bY, aZ, PRIME)),
                                    mulmod(sN,
                                    add(sub(PRIME, xN),
                                        mulmod(xD, bX, PRIME)),
                                    PRIME),
                                PRIME)

                    // As the value of the affine x coordinate is xN/xD and z=sD*xD,
                    // the projective x coordinate is xN*sD.
                    aX := mulmod(xN, sD, PRIME)
                }

                // At this point proof[offset + 0x40] holds the next input to be hashed.
                // This input is typically in the form left_node||right_node||0 and
                // we need to extract the relevant node for the consistent check below.
                // Note that the same logic is reused for the leaf computation and
                // for the consistent check with the final root.
                offset := add(offset, 0x40)

                // Init expected_hash to left_node.
                // It will be replaced by right_node if necessary.
                let expected_hash := shr(4, mload(add(proof, offset)))

                let other_node := and(  // right_node
                    mload(add(proof, add(offset, 0x1f))),
                    0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)

                // Make sure both nodes are in the range [0, PRIME - 1].
                // TODO(ilya): Do we actually want to enforce the condition above, or do we want
                // to accept any path that the AIR would accept, including paths where we have
                // 252 bits X coordinates that are larger than PRIME.
                if or(gt(expected_hash, primeMinusOne), gt(other_node, primeMinusOne)) {
                    raise_error("Value out of range.", 19)
                }

                if and(nodeSelectors, 1) {
                    expected_hash := other_node
                }

                // Make sure the result is consistent with the Merkle path.
                // I.e (aX/aZ) == expected_hash,
                // where expected_hash = (nodeSelectors & 1) == 0 ? left_node : right_node.
                // We also make sure aZ is not 0. I.e. during the summation we never tried
                // to add two points with the same x coordinate.
                // This is not strictly necessary because knowing how to trigger this condition
                // implies knowing a non-trivial linear equation on the random points defining the
                // hash function.
                if iszero(aZ) {
                   raise_error("aZ is zero.", 11)
                }

                if sub(aX, mulmod(expected_hash, aZ, PRIME))/*!=0*/ {
                   raise_error("Bad Merkle path.", 16)
                }
                nodeSelectors := shr(1, nodeSelectors)
            }

            mstore(0, starkKey)
            mstore(0x20,  assetId)
            mstore(0x40,  // quantizedAmount
                   and(mload(add(proof, 0x5f)),
                       0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
            mstore(0x60, shr(4, mload(add(proof, rowSize)))) // vaultRoot
            mstore(0x80, height)
            mstore(0xa0, vaultId)

            // claimHash := keccak256(
            //      starkKey, assetId, quantizedAmount, vaultRoot, height, vaultId).
            // storage[claimHash] := 1.
            sstore(keccak256(0, 0xc0), 1)
        }
    }


    /*
      Checks the validity status of the claim corresponding to:
      keccak256(abi.encode(starkKey, assetId, quantizedAmount, root, height, vaultId)).
    */
    function isValid(bytes32 hash)
    external view override returns(bool val)
    {
        assembly {
            val := sload(hash)
        }
    }
}