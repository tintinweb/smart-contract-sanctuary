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

import "FactRegistry.sol";
import "IAvailabilityVerifier.sol";
import "Identity.sol";

contract Committee is FactRegistry, IAvailabilityVerifier, Identity {

    uint256 constant SIGNATURE_LENGTH = 32 * 2 + 1; // r(32) + s(32) +  v(1).
    uint256 public signaturesRequired;
    mapping (address => bool) public isMember;

    /// @dev Contract constructor sets initial members and required number of signatures.
    /// @param committeeMembers List of committee members.
    /// @param numSignaturesRequired Number of required signatures.
    constructor (address[] memory committeeMembers, uint256 numSignaturesRequired)
        public
    {
        require(numSignaturesRequired <= committeeMembers.length, "TOO_MANY_REQUIRED_SIGNATURES");
        for (uint256 idx = 0; idx < committeeMembers.length; idx++) {
            require(!isMember[committeeMembers[idx]], "NON_UNIQUE_COMMITTEE_MEMBERS");
            isMember[committeeMembers[idx]] = true;
        }
        signaturesRequired = numSignaturesRequired;
    }

    function identify()
        external pure override
        returns(string memory)
    {
        return "StarkWare_Committee_2019_1";
    }

    /// @dev Verifies the availability proof. Reverts if invalid.
    /// An availability proof should have a form of a concatenation of ec-signatures by signatories.
    /// Signatures should be sorted by signatory address ascendingly.
    /// Signatures should be 65 bytes long. r(32) + s(32) + v(1).
    /// There should be at least the number of required signatures as defined in this contract
    /// and all signatures provided should be from signatories.
    ///
    /// See :sol:mod:`AvailabilityVerifiers` for more information on when this is used.
    ///
    /// @param claimHash The hash of the claim the committee is signing on.
    /// The format is keccak256(abi.encodePacked(
    ///    newVaultRoot, vaultTreeHeight, newOrderRoot, orderTreeHeight sequenceNumber))
    /// @param availabilityProofs Concatenated ec signatures by committee members.
    function verifyAvailabilityProof(
        bytes32 claimHash,
        bytes calldata availabilityProofs
    )
        external override
    {
        require(
            availabilityProofs.length >= signaturesRequired * SIGNATURE_LENGTH,
            "INVALID_AVAILABILITY_PROOF_LENGTH");

        uint256 offset = 0;
        address prevRecoveredAddress = address(0);
        for (uint256 proofIdx = 0; proofIdx < signaturesRequired; proofIdx++) {
            bytes32 r = bytesToBytes32(availabilityProofs, offset);
            bytes32 s = bytesToBytes32(availabilityProofs, offset + 32);
            uint8 v = uint8(availabilityProofs[offset + 64]);
            offset += SIGNATURE_LENGTH;
            address recovered = ecrecover(
                claimHash,
                v,
                r,
                s
            );
            // Signatures should be sorted off-chain before submitting to enable cheap uniqueness
            // check on-chain.
            require(isMember[recovered], "AVAILABILITY_PROVER_NOT_IN_COMMITTEE");
            require(recovered > prevRecoveredAddress, "NON_SORTED_SIGNATURES");
            prevRecoveredAddress = recovered;
        }
        registerFact(claimHash);
    }

    function bytesToBytes32(bytes memory array, uint256 offset)
        private pure
        returns (bytes32 result) {
        // Arrays are prefixed by a 256 bit length parameter.
        uint256 actualOffset = offset + 32;

        // Read the bytes32 from array memory.
        assembly {
            result := mload(add(array, actualOffset))
        }
    }
}