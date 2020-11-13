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

import "MApprovalChain.sol";
import "LibConstants.sol";
import "MainStorage.sol";

/**
  A :sol:mod:`Committee` contract is a contract that the exchange service sends committee member
  signatures to attesting that they have a copy of the data over which a new Merkel root is to be
  accepted as the new state root. In addition, the exchange contract can call an availability
  verifier to check if such signatures were indeed provided by a sufficient number of committee
  members as hard coded in the :sol:mod:`Committee` contract for a given state transition
  (as reflected by the old and new vault and order roots).

  The exchange contract will normally query only one :sol:mod:`Committee` contract for data
  availability checks. However, in the event that the committee needs to be updated, additional
  availability verifiers may be registered with the exchange contract by the
  contract :sol:mod:`MainGovernance`. Such new availability verifiers are then also be required to
  attest to the data availability for state transitions and only if all the availability verifiers
  attest to it, the state transition is accepted.

  Removal of availability verifiers is also the responsibility of the :sol:mod:`MainGovernance`.
  The removal process is more sensitive than availability verifier registration as it may affect the
  soundness of the system. Hence, this is performed in two steps:

  1. The :sol:mod:`MainGovernance` first announces the intent to remove an availability verifier by calling :sol:func:`announceAvailabilityVerifierRemovalIntent`
  2. After the expiration of a `VERIFIER_REMOVAL_DELAY` time lock, actual removal may be performed by calling :sol:func:`removeAvailabilityVerifier`

  The removal delay ensures that a user concerned about the soundness of the system has ample time
  to leave the exchange.
*/
contract AvailabilityVerifiers is MainStorage, LibConstants, MApprovalChain {
    function getRegisteredAvailabilityVerifiers()
        external view
        returns (address[] memory _verifers)
    {
        return availabilityVerifiersChain.list;
    }

    function isAvailabilityVerifier(address verifierAddress)
        external view
        returns (bool)
    {
        return findEntry(availabilityVerifiersChain.list, verifierAddress) != ENTRY_NOT_FOUND;
    }

    function registerAvailabilityVerifier(address verifier, string calldata identifier)
        external
    {
        addEntry(availabilityVerifiersChain, verifier, MAX_VERIFIER_COUNT, identifier);
    }

    function announceAvailabilityVerifierRemovalIntent(address verifier)
        external
    {
        announceRemovalIntent(availabilityVerifiersChain, verifier, VERIFIER_REMOVAL_DELAY);
    }

    function removeAvailabilityVerifier(address verifier)
        external
    {
        removeEntry(availabilityVerifiersChain, verifier);
    }
}
