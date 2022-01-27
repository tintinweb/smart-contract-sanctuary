// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "IFactRegistry.sol";
import "IIdentity.sol";
import "Output.sol";
import "StarknetGovernance.sol";
import "StarknetMessaging.sol";
import "StarknetOperator.sol";
import "StarknetState.sol";
import "OnchainDataFactTreeEncoder.sol";
import "GovernedFinalizable.sol";
import "ContractInitializer.sol";
import "ProxySupport.sol";
import "NamedStorage.sol";

contract Starknet is
    IIdentity,
    StarknetMessaging,
    StarknetGovernance,
    GovernedFinalizable,
    StarknetOperator,
    ContractInitializer,
    ProxySupport
{
    using StarknetState for StarknetState.State;

    // Logs the new state following a state update.
    event LogStateUpdate(uint256 globalRoot, int256 blockNumber);

    // Logs a stateTransitionFact that was used to update the state.
    event LogStateTransitionFact(bytes32 stateTransitionFact);

    // Random storage slot tags.
    string internal constant PROGRAM_HASH_TAG = "STARKNET_1.0_INIT_PROGRAM_HASH_UINT";
    string internal constant VERIFIER_ADDRESS_TAG = "STARKNET_1.0_INIT_VERIFIER_ADDRESS";
    string internal constant STATE_STRUCT_TAG = "STARKNET_1.0_INIT_STARKNET_STATE_STRUCT";

    function setProgramHash(uint256 newProgramHash) external notFinalized onlyGovernance {
        programHash(newProgramHash);
    }

    // State variable "programHash" read-access functions.
    function programHash() public view returns (uint256) {
        return NamedStorage.getUintValue(PROGRAM_HASH_TAG);
    }

    // State variable "programHash" write-access functions.
    function programHash(uint256 value) internal {
        NamedStorage.setUintValue(PROGRAM_HASH_TAG, value);
    }

    // State variable "verifier" access functions.
    function verifier() internal view returns (address) {
        return NamedStorage.getAddressValue(VERIFIER_ADDRESS_TAG);
    }

    function setVerifierAddress(address value) internal {
        NamedStorage.setAddressValueOnce(VERIFIER_ADDRESS_TAG, value);
    }

    // State variable "state" access functions.
    function state() internal pure returns (StarknetState.State storage stateStruct) {
        bytes32 location = keccak256(abi.encodePacked(STATE_STRUCT_TAG));
        assembly {
            stateStruct_slot := location
        }
    }

    function isInitialized() internal view override returns (bool) {
        return programHash() != 0;
    }

    function numOfSubContracts() internal pure override returns (uint256) {
        return 0;
    }

    function validateInitData(bytes calldata data) internal pure override {
        require(data.length == 4 * 32, "ILLEGAL_INIT_DATA_SIZE");
        uint256 programHash_ = abi.decode(data[:32], (uint256));
        require(programHash_ != 0, "BAD_INITIALIZATION");
    }

    function processSubContractAddresses(bytes calldata subContractAddresses) internal override {}

    function initializeContractState(bytes calldata data) internal override {
        (uint256 programHash_, address verifier_, StarknetState.State memory initialState) = abi
            .decode(data, (uint256, address, StarknetState.State));

        programHash(programHash_);
        setVerifierAddress(verifier_);
        state().copy(initialState);
    }

    /**
      Returns a string that identifies the contract.
    */
    function identify() external pure override returns (string memory) {
        return "StarkWare_Starknet_2022_1";
    }

    /**
      Returns the current state root.
    */
    function stateRoot() external view returns (uint256) {
        return state().globalRoot;
    }

    /**
      Returns the current block number.
    */
    function stateBlockNumber() external view returns (int256) {
        return state().blockNumber;
    }

    /**
      Updates the state of the StarkNet, based on a proof of the 
      StarkNet OS that the state transition is valid.

      Arguments:
        programOutput - The main part of the StarkNet OS program output.
        data_availability_fact - An encoding of the on-chain data associated
        with the 'programOutput'.
    */
    function updateState(
        uint256[] calldata programOutput,
        uint256 onchainDataHash,
        uint256 onchainDataSize
    ) external onlyOperator {
        // Validate program output.
        StarknetOutput.validate(programOutput);
        bytes32 stateTransitionFact = OnchainDataFactTreeEncoder.encodeFactWithOnchainData(
            programOutput,
            OnchainDataFactTreeEncoder.DataAvailabilityFact(onchainDataHash, onchainDataSize)
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
        state().update(programOutput);
        StarknetState.State memory state_ = state();
        emit LogStateUpdate(state_.globalRoot, state_.blockNumber);
    }
}