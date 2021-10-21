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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "IFactRegistry.sol";
import "IIdentity.sol";
import "Output.sol";
import "ProxySupport.sol";
import "StarknetMessaging.sol";
import "StarknetOperator.sol";
import "StarknetState.sol";
import "OnchainDataFactTreeEncoder.sol";

contract Starknet is IIdentity, StarknetMessaging, StarknetOperator, ProxySupport {
    using StarknetState for StarknetState.State;

    // Logs the new state following a state update.
    event LogStateUpdate(uint256 globalRoot, int256 sequenceNumber);

    // Logs a stateTransitionFact that was used to update the state.
    event LogStateTransitionFact(bytes32 stateTransitionFact);

    /**
      Returns a string that identifies the contract.
    */
    function identify() external pure override returns (string memory) {
        return "StarkWare_Starknet_2021_1";
    }

    /**
      Returns the current state root.
    */
    function stateRoot() external view returns (uint256) {
        return state().globalRoot;
    }

    /**
      Returns the current sequence number.
    */
    function stateSequenceNumber() external view returns (int256) {
        return state().sequenceNumber;
    }

    /**
      Updates the state of the StarkNet, based on a proof of the 
      StarkNet OS that the state transition is valid.

      Arguments:
        sequenceNumber - The expected sequence number of the new block.
        programOutput - The main part of the StarkNet OS program output.
        data_availability_fact - An encoding of the on-chain data associated
        with the 'programOutput'.
    */
    function updateState(
        int256 sequenceNumber,
        uint256[] calldata programOutput,
        OnchainDataFactTreeEncoder.DataAvailabilityFact calldata data_availability_fact
    ) external onlyOperator {
        // Validate program output.
        StarknetOutput.validate(programOutput);

        bytes32 stateTransitionFact = OnchainDataFactTreeEncoder.encodeFactWithOnchainData(
            programOutput,
            data_availability_fact
        );
        bytes32 sharpFact = keccak256(abi.encode(programHash(), stateTransitionFact));
        require(IFactRegistry(verifier()).isValid(sharpFact), "NO_STATE_TRANSITION_PROOF");
        emit LogStateTransitionFact(stateTransitionFact);

        // Process L2 -> L1 messages.
        uint256 outputOffset = StarknetOutput.HEADER_SIZE;
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            true,
            programOutput[outputOffset:],
            l2ToL1Messages()
        );

        // Process L1 -> L2 messages.
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            false,
            programOutput[outputOffset:],
            l1ToL2Messages()
        );

        require(outputOffset == programOutput.length, "STARKNET_OUTPUT_TOO_LONG");

        // Perform state update.
        state().update(sequenceNumber, programOutput);
        StarknetState.State memory state_ = state();
        emit LogStateUpdate(state_.globalRoot, state_.sequenceNumber);
    }
}