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

import "Common.sol";

/*
  Implements a data structure that supports instant registration
  and slow time-locked removal of entries.
*/
contract MApprovalChain {
    uint256 constant ENTRY_NOT_FOUND = uint256(~0);

    /*
      Adds the given verifier (entry) to the chain.
      Fails if the size of the chain is already >= maxLength.
      Fails if identifier is not identical to the value returned from entry.identify().
    */
    function addEntry(
        StarkExTypes.ApprovalChainData storage chain,
        address entry, uint256 maxLength, string memory identifier)
        internal;

    /*
      Returns the index of the verifier in the list if it exists and returns ENTRY_NOT_FOUND
      otherwise.
    */
    function findEntry(address[] storage list, address entry)
        internal view returns (uint256);

    /*
      Same as findEntry(), except that it reverts if the verifier is not found.
    */
    function safeFindEntry(address[] storage list, address entry)
        internal view returns (uint256 idx);

    /*
      Updates the unlockedForRemovalTime field of the given verifier to
        current time + removalDelay.
      Reverts if the verifier is not found.
    */
    function announceRemovalIntent(
        StarkExTypes.ApprovalChainData storage chain, address entry, uint256 removalDelay)
        internal;

    /*
      Removes a verifier assuming the expected time has passed.
    */
    function removeEntry(StarkExTypes.ApprovalChainData storage chain, address entry)
        internal;
}
