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

import "ExternalInitializer.sol";
import "Identity.sol";
import "MainStorage.sol";
import "Common.sol";
import "LibConstants.sol";

/*
  This contract is simple impelementation of an external initializing contract
  that removes all existing verifiers and committees and insall the ones provided in parameters.
*/
contract ChangeVerifiersExternalInitializer is
    ExternalInitializer,
    MainStorage,
    LibConstants
{
    using Addresses for address;
    uint256 constant ENTRY_NOT_FOUND = uint256(~0);

    /*
      The initiatialize function gets four parameters in the bytes array:
      1. New verifier address,
      2. Keccak256 of the expected verifier id.
      3. New availability verifier address,
      4. Keccak256 of the expected availability verifier id.
    */
    function initialize(bytes calldata data) external {
        require(data.length == 128, "UNEXPECTED_DATA_SIZE");
        address newVerifierAddress;
        bytes32 verifierIdHash;
        address newAvailabilityVerifierAddress;
        bytes32 availabilityVerifierIdHash;

        // Extract sub-contract address and hash of verifierId.
        (
            newVerifierAddress,
            verifierIdHash,
            newAvailabilityVerifierAddress,
            availabilityVerifierIdHash
        ) = abi.decode(data, (address, bytes32, address, bytes32));

        // Flush the entire verifiers list.
        delete verifiersChain.list;
        delete availabilityVerifiersChain.list;

        // ApprovalChain addEntry performs all the required checks for us.
        addEntry(verifiersChain, newVerifierAddress, MAX_VERIFIER_COUNT, verifierIdHash);
        addEntry(
            availabilityVerifiersChain, newAvailabilityVerifierAddress,
            MAX_VERIFIER_COUNT, availabilityVerifierIdHash);

        emit LogExternalInitialize(data);
    }

    /*
      The functions below are taken from ApprovalChain.sol, with minor changes:
      1. No governance needed (we are under the context where proxy governance is granted).
      2. The verifier ID is passed as hash, and not as string.
    */
    function addEntry(
        StarkExTypes.ApprovalChainData storage chain,
        address entry, uint256 maxLength, bytes32 hashExpectedId)
        internal
    {
        address[] storage list = chain.list;
        require(entry.isContract(), "ADDRESS_NOT_CONTRACT");
        bytes32 hashRealId = keccak256(abi.encodePacked(Identity(entry).identify()));
        require(hashRealId == hashExpectedId, "UNEXPECTED_CONTRACT_IDENTIFIER");
        require(list.length < maxLength, "CHAIN_AT_MAX_CAPACITY");
        require(findEntry(list, entry) == ENTRY_NOT_FOUND, "ENTRY_ALREADY_EXISTS");
        chain.list.push(entry);
        chain.unlockedForRemovalTime[entry] = 0;
    }

    function findEntry(address[] storage list, address entry)
        internal view returns (uint256)
    {
        uint256 n_entries = list.length;
        for (uint256 i = 0; i < n_entries; i++) {
            if (list[i] == entry) {
                return i;
            }
        }
        return ENTRY_NOT_FOUND;
    }
}
