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

import "MainStorage.sol";
import "IFactRegistry.sol";
import "IQueryableFactRegistry.sol";
import "Identity.sol";
import "MApprovalChain.sol";
import "MFreezable.sol";
import "MGovernance.sol";
import "Common.sol";

/*
  Implements a data structure that supports instant registration
  and slow time-locked removal of entries.
*/
contract ApprovalChain is MainStorage, MApprovalChain, MGovernance, MFreezable {

    using Addresses for address;

    function addEntry(
        StarkExTypes.ApprovalChainData storage chain,
        address entry, uint256 maxLength, string memory identifier)
        internal
        onlyGovernance()
        notFrozen()
    {
        address[] storage list = chain.list;
        require(entry.isContract(), "ADDRESS_NOT_CONTRACT");
        bytes32 hash_real = keccak256(abi.encodePacked(Identity(entry).identify()));
        bytes32 hash_identifier = keccak256(abi.encodePacked(identifier));
        require(hash_real == hash_identifier, "UNEXPECTED_CONTRACT_IDENTIFIER");
        require(list.length < maxLength, "CHAIN_AT_MAX_CAPACITY");
        require(findEntry(list, entry) == ENTRY_NOT_FOUND, "ENTRY_ALREADY_EXISTS");

        // Verifier must have at least one fact registered before adding to chain,
        // unless it's the first verifier in the chain.
        require(
            list.length == 0 || IQueryableFactRegistry(entry).hasRegisteredFact(),
            "ENTRY_NOT_ENABLED");
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

    function safeFindEntry(address[] storage list, address entry)
        internal view returns (uint256 idx)
    {
        idx = findEntry(list, entry);

        require(idx != ENTRY_NOT_FOUND, "ENTRY_DOES_NOT_EXIST");
    }

    function announceRemovalIntent(
        StarkExTypes.ApprovalChainData storage chain, address entry, uint256 removalDelay)
        internal
        onlyGovernance()
        notFrozen()
    {
        safeFindEntry(chain.list, entry);
        require(now + removalDelay > now, "INVALID_REMOVAL_DELAY"); // NOLINT: timestamp.
        // solium-disable-next-line security/no-block-members
        chain.unlockedForRemovalTime[entry] = now + removalDelay;
    }

    function removeEntry(StarkExTypes.ApprovalChainData storage chain, address entry)
        internal
        onlyGovernance()
        notFrozen()
    {
        address[] storage list = chain.list;
        // Make sure entry exists.
        uint256 idx = safeFindEntry(list, entry);
        uint256 unlockedForRemovalTime = chain.unlockedForRemovalTime[entry];

        // solium-disable-next-line security/no-block-members
        require(unlockedForRemovalTime > 0, "REMOVAL_NOT_ANNOUNCED");
        // solium-disable-next-line security/no-block-members
        require(now >= unlockedForRemovalTime, "REMOVAL_NOT_ENABLED_YET"); // NOLINT: timestamp.

        uint256 n_entries = list.length;

        // Removal of last entry is forbidden.
        require(n_entries > 1, "LAST_ENTRY_MAY_NOT_BE_REMOVED");

        if (idx != n_entries - 1) {
            list[idx] = list[n_entries - 1];
        }
        list.pop();
        delete chain.unlockedForRemovalTime[entry];
    }
}
