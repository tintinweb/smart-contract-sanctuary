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

contract Starknet is IIdentity {
    using StarknetState for StarknetState.State;
    StarknetState.State internal state;
    IFactRegistry verifier;
    uint256 programHash;
    mapping(bytes32 => uint256) public l2ToL1Messages;
    mapping(bytes32 => uint256) public l1ToL2Messages;

    // Logs the new state following a state update.
    event LogStateUpdate(uint256 globalRoot, int256 sequenceNumber);

    // Logs a stateTransitionFact that was used to update the state.
    event LogStateTransitionFact(bytes32 stateTransitionFact);

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload
    );

    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    /**
      The Starknet contract constructor.

      Arguments:
        programHash_ - The program hash of the StarkNet OS.
        verifier_ - The address of a SHARP verifier fact registry.
        initialState - The initial state of the system.
    */
    constructor(
        uint256 programHash_,
        IFactRegistry verifier_,
        StarknetState.State memory initialState
    ) public {
        programHash = programHash_;
        verifier = verifier_;
        state = initialState;
    }

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
        return state.globalRoot;
    }

    /**
      Returns the current sequence number.
    */
    function stateSequenceNumber() external view returns (int256) {
        return state.sequenceNumber;
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
    ) public {
        // Validate program output.
        StarknetOutput.validate(programOutput);

        bytes32 stateTransitionFact = OnchainDataFactTreeEncoder.encodeFactWithOnchainData(
            programOutput,
            data_availability_fact
        );
        bytes32 sharpFact = keccak256(abi.encode(programHash, stateTransitionFact));
        require(verifier.isValid(sharpFact), "NO_STATE_TRANSITION_PROOF");
        emit LogStateTransitionFact(stateTransitionFact);

        // Process L2 -> L1 messages.
        uint256 outputOffset = StarknetOutput.HEADER_SIZE;
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            true,
            programOutput[outputOffset:],
            l2ToL1Messages
        );

        // Process L1 -> L2 messages.
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            false,
            programOutput[outputOffset:],
            l1ToL2Messages
        );

        require(outputOffset == programOutput.length, "STARKNET_OUTPUT_TOO_LONG");

        // Perform state update.
        state.update(sequenceNumber, programOutput);
        emit LogStateUpdate(state.globalRoot, state.sequenceNumber);
    }

    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external {
        emit LogMessageToL2(msg.sender, to_address, selector, payload);
        // Note that the selector is prepended to the payload.
        bytes32 msgHash = keccak256(
            abi.encodePacked(uint256(msg.sender), to_address, 1 + payload.length, selector, payload)
        );
        l1ToL2Messages[msgHash] += 1;
    }

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(uint256 from_address, uint256[] calldata payload) external {
        bytes32 msgHash = keccak256(
            abi.encodePacked(from_address, uint256(msg.sender), payload.length, payload)
        );

        require(l2ToL1Messages[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        l2ToL1Messages[msgHash] -= 1;
    }
}