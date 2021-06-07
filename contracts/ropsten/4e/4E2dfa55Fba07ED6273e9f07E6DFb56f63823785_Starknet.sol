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
pragma experimental ABIEncoderV2;

import "IFactRegistry.sol";
import "IIdentity.sol";
import "Output.sol";
import "StarknetState.sol";
import "OnchainDataFactTreeEncoder.sol";

contract Starknet is
    IIdentity
{
    using StarknetState for StarknetState.State;
    StarknetState.State internal state;
    IFactRegistry verifier;
    uint256 programHash;

    event LogStateUpdate(
        uint256 globalRoot,
        int256 sequenceNumber
    );

    event LogStateTransitionFact(
        bytes32 stateTransitionFact
    );

    constructor(
        uint256 programHash_, IFactRegistry verifier_, StarknetState.State memory prevState) public
    {
        programHash = programHash_;
        verifier = verifier_;
        state = prevState;
    }

    function identify() external override pure returns (string memory) {
        return "StarkWare_Starknet_2021_1";
    }

    function stateRoot() external view returns (uint256) {
        return state.globalRoot;
    }

    function stateSequenceNumber() external view returns (int256) {
        return state.sequenceNumber;
    }

    function updateState(
        uint256[] calldata programOutput,
        OnchainDataFactTreeEncoder.DataAvailabilityFact calldata data_availability_fact) public
    {
        // Validate program output.
        StarknetOutput.validate(programOutput);

        // Verify transition fact.
        bytes32 stateTransitionFact;
        if(data_availability_fact.onchainDataHash == 0){
            stateTransitionFact = keccak256(abi.encodePacked(programOutput));
        } else {
            stateTransitionFact = OnchainDataFactTreeEncoder.encodeFactWithOnchainData(
                programOutput, data_availability_fact);
        }
        bytes32 sharpFact = keccak256(abi.encode(programHash, stateTransitionFact));
        require(verifier.isValid(sharpFact), "NO_STATE_TRANSITION_PROOF");
        emit LogStateTransitionFact(stateTransitionFact);

        // Perform state update.
        state.update(programOutput);
        emit LogStateUpdate(state.globalRoot, state.sequenceNumber);
    }
}