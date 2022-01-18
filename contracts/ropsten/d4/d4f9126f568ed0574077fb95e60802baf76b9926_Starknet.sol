// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  This contract provides means to block direct call of an external function.
  A derived contract (e.g. MainDispatcherBase) should decorate sensitive functions with the
  notCalledDirectly modifier, thereby preventing it from being called directly, and allowing only calling
  using delegate_call.

  This Guard contract uses pseudo-random slot, So each deployed contract would have its own guard.
*/
abstract contract BlockDirectCall {
    bytes32 immutable UNIQUE_SAFEGUARD_SLOT; // NOLINT naming-convention.

    constructor() internal {
        // The slot is pseudo-random to allow hierarchy of contracts with guarded functions.
        bytes32 slot = keccak256(abi.encode(this, block.timestamp, gasleft()));
        UNIQUE_SAFEGUARD_SLOT = slot;
        assembly {
            sstore(slot, 42)
        }
    }

    modifier notCalledDirectly() {
        {
            // Prevent too many local variables in stack.
            uint256 safeGuardValue;
            bytes32 slot = UNIQUE_SAFEGUARD_SLOT;
            assembly {
                safeGuardValue := sload(slot)
            }
            require(safeGuardValue == 0, "DIRECT_CALL_DISALLOWED");
        }
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MGovernance.sol";

/*
  Implements Generic Governance, applicable for both proxy and main contract, and possibly others.
  Notes:
   The use of the same function names by both the Proxy and a delegated implementation
   is not possible since calling the implementation functions is done via the default function
   of the Proxy. For this reason, for example, the implementation of MainContract (MainGovernance)
   exposes mainIsGovernor, which calls the internal isGovernor method.
*/
abstract contract Governance is MGovernance {
    event LogNominatedGovernor(address nominatedGovernor);
    event LogNewGovernorAccepted(address acceptedGovernor);
    event LogRemovedGovernor(address removedGovernor);
    event LogNominationCancelled();

    function getGovernanceInfo() internal view virtual returns (GovernanceInfoStruct storage);

    /*
      Current code intentionally prevents governance re-initialization.
      This may be a problem in an upgrade situation, in a case that the upgrade-to implementation
      performs an initialization (for real) and within that calls initGovernance().

      Possible workarounds:
      1. Clearing the governance info altogether by changing the MAIN_GOVERNANCE_INFO_TAG.
         This will remove existing main governance information.
      2. Modify the require part in this function, so that it will exit quietly
         when trying to re-initialize (uncomment the lines below).
    */
    function initGovernance() internal {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(!gub.initialized, "ALREADY_INITIALIZED");
        gub.initialized = true; // to ensure addGovernor() won't fail.
        // Add the initial governer.
        addGovernor(msg.sender);
    }

    function isGovernor(address testGovernor) internal view override returns (bool) {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        return gub.effectiveGovernors[testGovernor];
    }

    /*
      Cancels the nomination of a governor candidate.
    */
    function cancelNomination() internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        gub.candidateGovernor = address(0x0);
        emit LogNominationCancelled();
    }

    function nominateNewGovernor(address newGovernor) internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(!isGovernor(newGovernor), "ALREADY_GOVERNOR");
        gub.candidateGovernor = newGovernor;
        emit LogNominatedGovernor(newGovernor);
    }

    /*
      The addGovernor is called in two cases:
      1. by acceptGovernance when a new governor accepts its role.
      2. by initGovernance to add the initial governor.
      The difference is that the init path skips the nominate step
      that would fail because of the onlyGovernance modifier.
    */
    function addGovernor(address newGovernor) private {
        require(!isGovernor(newGovernor), "ALREADY_GOVERNOR");
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        gub.effectiveGovernors[newGovernor] = true;
    }

    function acceptGovernance() internal {
        // The new governor was proposed as a candidate by the current governor.
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(msg.sender == gub.candidateGovernor, "ONLY_CANDIDATE_GOVERNOR");

        // Update state.
        addGovernor(gub.candidateGovernor);
        gub.candidateGovernor = address(0x0);

        // Send a notification about the change of governor.
        emit LogNewGovernorAccepted(msg.sender);
    }

    /*
      Remove a governor from office.
    */
    function removeGovernor(address governorForRemoval) internal onlyGovernance {
        require(msg.sender != governorForRemoval, "GOVERNOR_SELF_REMOVE");
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(isGovernor(governorForRemoval), "NOT_GOVERNOR");
        gub.effectiveGovernors[governorForRemoval] = false;
        emit LogRemovedGovernor(governorForRemoval);
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IStarknetMessaging {
    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L2 to L1 is consumed.
    event ConsumedMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

struct GovernanceInfoStruct {
    mapping(address => bool) effectiveGovernors;
    address candidateGovernor;
    bool initialized;
}

abstract contract MGovernance {
    function isGovernor(address testGovernor) internal view virtual returns (bool);

    /*
      Allows calling the function only by a Governor.
    */
    modifier onlyGovernance() {
        require(isGovernor(msg.sender), "ONLY_GOVERNANCE");
        _;
    }
}

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

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IStarknetMessaging.sol";
import "NamedStorage.sol";

/**
  Implements sending messages to L2 by adding them to a pipe and consuming messages from L2 by
  removing them from a different pipe. A deriving contract can handle the former pipe and add items
  to the latter pipe while interacting with L2.
*/
contract StarknetMessaging is IStarknetMessaging {
    /**
      Random slot storage elements and accessors.
    */
    string constant L1L2_MESSAGE_MAP_TAG = "STARKNET_1.0_MSGING_L1TOL2_MAPPPING_V2";
    string constant L2L1_MESSAGE_MAP_TAG = "STARKNET_1.0_MSGING_L2TOL1_MAPPPING";

    string constant L1L2_MESSAGE_NONCE_TAG = "STARKNET_1.0_MSGING_L1TOL2_NONCE";

    function l1ToL2Messages(bytes32 msgHash) external view returns (uint256) {
        return l1ToL2Messages()[msgHash];
    }

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256) {
        return l2ToL1Messages()[msgHash];
    }

    function l1ToL2Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_MAP_TAG);
    }

    function l2ToL1Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L2L1_MESSAGE_MAP_TAG);
    }

    function l1ToL2MessageNonce() public view returns (uint256) {
        return NamedStorage.getUintValue(L1L2_MESSAGE_NONCE_TAG);
    }

    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external override returns (bytes32) {
        uint256 nonce = l1ToL2MessageNonce();
        NamedStorage.setUintValue(L1L2_MESSAGE_NONCE_TAG, nonce + 1);
        emit LogMessageToL2(msg.sender, to_address, selector, payload, nonce);
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                uint256(msg.sender),
                to_address,
                nonce,
                selector,
                payload.length,
                payload
            )
        );
        l1ToL2Messages()[msgHash] += 1;

        return msgHash;
    }

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 from_address, uint256[] calldata payload)
        external
        override
        returns (bytes32)
    {
        bytes32 msgHash = keccak256(
            abi.encodePacked(from_address, uint256(msg.sender), payload.length, payload)
        );

        require(l2ToL1Messages()[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        emit ConsumedMessageToL1(from_address, msg.sender, payload);
        l2ToL1Messages()[msgHash] -= 1;
        return msgHash;
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  Common Utility librarries.
  I. Addresses (extending address).
*/
library Addresses {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function performEthTransfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}(""); // NOLINT: low-level-calls.
        require(success, "ETH_TRANSFER_FAILED");
    }

    /*
      Safe wrapper around ERC20/ERC721 calls.
      This is required because many deployed ERC20 contracts don't return a value.
      See https://github.com/ethereum/solidity/issues/4116.
    */
    function safeTokenContractCall(address tokenAddress, bytes memory callData) internal {
        require(isContract(tokenAddress), "BAD_TOKEN_ADDRESS");
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = tokenAddress.call(callData);
        require(success, string(returndata));

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "TOKEN_OPERATION_FAILED");
        }
    }

    /*
      Validates that the passed contract address is of a real contract,
      and that its id hash (as infered fromn identify()) matched the expected one.
    */
    function validateContractId(address contractAddress, bytes32 expectedIdHash) internal {
        require(isContract(contractAddress), "ADDRESS_NOT_CONTRACT");
        (bool success, bytes memory returndata) = contractAddress.call( // NOLINT: low-level-calls.
            abi.encodeWithSignature("identify()")
        );
        require(success, "FAILED_TO_IDENTIFY_CONTRACT");
        string memory realContractId = abi.decode(returndata, (string));
        require(
            keccak256(abi.encodePacked(realContractId)) == expectedIdHash,
            "UNEXPECTED_CONTRACT_IDENTIFIER"
        );
    }
}

/*
  II. StarkExTypes - Common data types.
*/
library StarkExTypes {
    // Structure representing a list of verifiers (validity/availability).
    // A statement is valid only if all the verifiers in the list agree on it.
    // Adding a verifier to the list is immediate - this is used for fast resolution of
    // any soundness issues.
    // Removing from the list is time-locked, to ensure that any user of the system
    // not content with the announced removal has ample time to leave the system before it is
    // removed.
    struct ApprovalChainData {
        address[] list;
        // Represents the time after which the verifier with the given address can be removed.
        // Removal of the verifier with address A is allowed only in the case the value
        // of unlockedForRemovalTime[A] != 0 and unlockedForRemovalTime[A] < (current time).
        mapping(address => uint256) unlockedForRemovalTime;
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MOperator.sol";
import "MGovernance.sol";

/**
  The Operator of the contract is the entity entitled to submit state update requests
  by calling :sol:func:`updateState`.

  An Operator may be instantly appointed or removed by the contract Governor
  (see :sol:mod:`Governance`). Typically, the Operator is the hot wallet of the service
  submitting proofs for state updates.
*/
abstract contract Operator is MGovernance, MOperator {
    function registerOperator(address newOperator) external override onlyGovernance {
        getOperators()[newOperator] = true;
        emit LogOperatorAdded(newOperator);
    }

    function unregisterOperator(address removedOperator) external override onlyGovernance {
        getOperators()[removedOperator] = false;
        emit LogOperatorRemoved(removedOperator);
    }

    function isOperator(address testedOperator) public view override returns (bool) {
        return getOperators()[testedOperator];
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MGovernance.sol";

abstract contract MOperator {
    event LogOperatorAdded(address operator);
    event LogOperatorRemoved(address operator);

    function isOperator(address testedOperator) public view virtual returns (bool);

    modifier onlyOperator() {
        require(isOperator(msg.sender), "ONLY_OPERATOR");
        _;
    }

    function registerOperator(address newOperator) external virtual;

    function unregisterOperator(address removedOperator) external virtual;

    function getOperators() internal view virtual returns (mapping(address => bool) storage);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Output.sol";

library StarknetState {
    struct State {
        uint256 globalRoot;
        int256 blockNumber;
    }

    function copy(State storage state, State memory stateFrom) internal {
        state.globalRoot = stateFrom.globalRoot;
        state.blockNumber = stateFrom.blockNumber;
    }

    /**
      Validates that the 'blockNumber' and the previous root are consistent with the
      current state and updates the state.
    */
    function update(State storage state, uint256[] calldata starknetOutput) internal {
        // Check the blockNumber first as the error is less ambiguous then INVALID_PREVIOUS_ROOT.
        state.blockNumber += 1;
        require(
            uint256(state.blockNumber) == starknetOutput[StarknetOutput.BLOCK_NUMBER_OFFSET],
            "INVALID_BLOCK_NUMBER"
        );

        uint256[] calldata commitment_tree_update = StarknetOutput.getMerkleUpdate(starknetOutput);
        require(
            state.globalRoot == CommitmentTreeUpdateOutput.getPrevRoot(commitment_tree_update),
            "INVALID_PREVIOUS_ROOT"
        );
        state.globalRoot = CommitmentTreeUpdateOutput.getNewRoot(commitment_tree_update);
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IIdentity {
    /*
      Allows a caller to ensure that the provided address is of the expected type and version.
    */
    function identify() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Governance.sol";

contract StarknetGovernance is Governance {
    string constant STARKNET_GOVERNANCE_INFO_TAG = "STARKNET_1.0_GOVERNANCE_INFO";

    /*
      Returns the GovernanceInfoStruct associated with the governance tag.
    */
    function getGovernanceInfo() internal view override returns (GovernanceInfoStruct storage gub) {
        bytes32 location = keccak256(abi.encodePacked(STARKNET_GOVERNANCE_INFO_TAG));
        assembly {
            gub_slot := location
        }
    }

    function starknetIsGovernor(address testGovernor) external view returns (bool) {
        return isGovernor(testGovernor);
    }

    function starknetNominateNewGovernor(address newGovernor) external {
        nominateNewGovernor(newGovernor);
    }

    function starknetRemoveGovernor(address governorForRemoval) external {
        removeGovernor(governorForRemoval);
    }

    function starknetAcceptGovernance() external {
        acceptGovernance();
    }

    function starknetCancelNomination() external {
        cancelNomination();
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Governance.sol";
import "Common.sol";
import "BlockDirectCall.sol";
import "ContractInitializer.sol";

/**
  This contract contains the code commonly needed for a contract to be deployed behind
  an upgradability proxy.
  It perform the required semantics of the proxy pattern,
  but in a generic manner.
  Instantiation of the Governance and of the ContractInitializer, that are the app specific
  part of initialization, has to be done by the using contract.
*/
abstract contract ProxySupport is Governance, BlockDirectCall, ContractInitializer {
    using Addresses for address;

    // The two function below (isFrozen & initialize) needed to bind to the Proxy.
    function isFrozen() external view virtual returns (bool) {
        return false;
    }

    /*
      The initialize() function serves as an alternative constructor for a proxied deployment.

      Flow and notes:
      1. This function cannot be called directly on the deployed contract, but only via
         delegate call.
      2. If an EIC is provided - init is passed onto EIC and the standard init flow is skipped.
         This true for both first intialization or a later one.
      3. The data passed to this function is as follows:
         [sub_contracts addresses, eic address, initData].

         When calling on an initialized contract (no EIC scenario), initData.length must be 0.
    */
    function initialize(bytes calldata data) external notCalledDirectly {
        uint256 eicOffset = 32 * numOfSubContracts();
        uint256 expectedBaseSize = eicOffset + 32;
        require(data.length >= expectedBaseSize, "INIT_DATA_TOO_SMALL");
        address eicAddress = abi.decode(data[eicOffset:expectedBaseSize], (address));

        bytes calldata subContractAddresses = data[:eicOffset];

        processSubContractAddresses(subContractAddresses);

        bytes calldata initData = data[expectedBaseSize:];

        // EIC Provided - Pass initData to EIC and the skip standard init flow.
        if (eicAddress != address(0x0)) {
            callExternalInitializer(eicAddress, initData);
            return;
        }

        if (isInitialized()) {
            require(initData.length == 0, "UNEXPECTED_INIT_DATA");
        } else {
            // Contract was not initialized yet.
            validateInitData(initData);
            initializeContractState(initData);
            initGovernance();
        }
    }

    function callExternalInitializer(address externalInitializerAddr, bytes calldata eicData)
        private
    {
        require(externalInitializerAddr.isContract(), "EIC_NOT_A_CONTRACT");

        // NOLINTNEXTLINE: low-level-calls, controlled-delegatecall.
        (bool success, bytes memory returndata) = externalInitializerAddr.delegatecall(
            abi.encodeWithSelector(this.initialize.selector, eicData)
        );
        require(success, string(returndata));
        require(returndata.length == 0, string(returndata));
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Operator.sol";
import "NamedStorage.sol";

abstract contract StarknetOperator is Operator {
    string constant OPERATORS_MAPPING_TAG = "STARKNET_1.0_ROLES_OPERATORS_MAPPING_TAG";

    function getOperators() internal view override returns (mapping(address => bool) storage) {
        return NamedStorage.addressToBoolMapping(OPERATORS_MAPPING_TAG);
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

library OnchainDataFactTreeEncoder {
    struct DataAvailabilityFact {
        uint256 onchainDataHash;
        uint256 onchainDataSize;
    }

    // The number of additional words appended to the public input when using the
    // OnchainDataFactTreeEncoder format.
    uint256 internal constant ONCHAIN_DATA_FACT_ADDITIONAL_WORDS = 2;

    /*
      Encodes a GPS fact Merkle tree where the root has two children.
      The left child contains the data we care about and the right child contains
      on-chain data for the fact.
    */
    function encodeFactWithOnchainData(
        uint256[] calldata programOutput,
        DataAvailabilityFact memory factData
    ) internal pure returns (bytes32) {
        // The state transition fact is computed as a Merkle tree, as defined in
        // GpsOutputParser.
        //
        // In our case the fact tree looks as follows:
        //   The root has two children.
        //   The left child is a leaf that includes the main part - the information regarding
        //   the state transition required by this contract.
        //   The right child contains the onchain-data which shouldn't be accessed by this
        //   contract, so we are only given its hash and length
        //   (it may be a leaf or an inner node, this has no effect on this contract).

        // Compute the hash without the two additional fields.
        uint256 mainPublicInputLen = programOutput.length;
        bytes32 mainPublicInputHash = keccak256(abi.encodePacked(programOutput));

        // Compute the hash of the fact Merkle tree.
        bytes32 hashResult = keccak256(
            abi.encodePacked(
                mainPublicInputHash,
                mainPublicInputLen,
                factData.onchainDataHash,
                mainPublicInputLen + factData.onchainDataSize
            )
        );
        // Add one to the hash to indicate it represents an inner node, rather than a leaf.
        return bytes32(uint256(hashResult) + 1);
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  Library to provide basic storage, in storage location out of the low linear address space.

  New types of storage variables should be added here upon need.
*/
library NamedStorage {
    function bytes32ToUint256Mapping(string memory tag_)
        internal
        pure
        returns (mapping(bytes32 => uint256) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function bytes32ToAddressMapping(string memory tag_)
        internal
        pure
        returns (mapping(bytes32 => address) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function addressToBoolMapping(string memory tag_)
        internal
        pure
        returns (mapping(address => bool) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function getUintValue(string memory tag_) internal view returns (uint256 retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setUintValue(string memory tag_, uint256 value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }

    function setUintValueOnce(string memory tag_, uint256 value) internal {
        require(getUintValue(tag_) == 0, "ALREADY_SET");
        setUintValue(tag_, value);
    }

    function getAddressValue(string memory tag_) internal view returns (address retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setAddressValue(string memory tag_, address value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }

    function setAddressValueOnce(string memory tag_, address value) internal {
        require(getAddressValue(tag_) == address(0x0), "ALREADY_SET");
        setAddressValue(tag_, value);
    }

    function getBoolValue(string memory tag_) internal view returns (bool retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setBoolValue(string memory tag_, bool value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/**
  Interface for contract initialization.
  The functions it exposes are the app specific parts of the contract initialization,
  and are called by the ProxySupport contract that implement the generic part of behind-proxy
  initialization.
*/
abstract contract ContractInitializer {
    function numOfSubContracts() internal pure virtual returns (uint256);

    function isInitialized() internal view virtual returns (bool);

    function validateInitData(bytes calldata data) internal pure virtual;

    function processSubContractAddresses(bytes calldata subContractAddresses) internal virtual;

    function initializeContractState(bytes calldata data) internal virtual;
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

library CommitmentTreeUpdateOutput {
    /**
      Returns the previous commitment tree root.
    */
    function getPrevRoot(uint256[] calldata commitment_tree_update_data)
        internal
        pure
        returns (uint256)
    {
        return commitment_tree_update_data[0];
    }

    /**
      Returns the new commitment tree root.
    */
    function getNewRoot(uint256[] calldata commitment_tree_update_data)
        internal
        pure
        returns (uint256)
    {
        return commitment_tree_update_data[1];
    }
}

library StarknetOutput {
    uint256 internal constant MERKLE_UPDATE_OFFSET = 0;
    uint256 internal constant BLOCK_NUMBER_OFFSET = 2;
    uint256 internal constant HEADER_SIZE = 3;

    uint256 constant MESSAGE_TO_L1_FROM_ADDRESS_OFFSET = 0;
    uint256 constant MESSAGE_TO_L1_TO_ADDRESS_OFFSET = 1;
    uint256 constant MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET = 2;
    uint256 constant MESSAGE_TO_L1_PREFIX_SIZE = 3;

    uint256 constant MESSAGE_TO_L2_FROM_ADDRESS_OFFSET = 0;
    uint256 constant MESSAGE_TO_L2_TO_ADDRESS_OFFSET = 1;
    uint256 constant MESSAGE_TO_L2_NONCE_OFFSET = 2;
    uint256 constant MESSAGE_TO_L2_SELECTOR_OFFSET = 3;
    uint256 constant MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET = 4;
    uint256 constant MESSAGE_TO_L2_PREFIX_SIZE = 5;

    // An event that is raised when a message is sent from L2 to L1.
    event LogMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    /**
      Does a sanity check of the output_data length.
    */
    function validate(uint256[] calldata output_data) internal pure {
        require(output_data.length > HEADER_SIZE, "STARKNET_OUTPUT_TOO_SHORT");
    }

    /**
      Returns a slice of the 'output_data' with the commitment tree update information.
    */
    function getMerkleUpdate(uint256[] calldata output_data)
        internal
        pure
        returns (uint256[] calldata)
    {
        return output_data[MERKLE_UPDATE_OFFSET:MERKLE_UPDATE_OFFSET + 2];
    }

    /**
      Processes a message segment from the program output.
      The format of a message segment is the length of the messages in words followed
      by the concatenation of all the messages.

      The 'messages' mapping is updated according to the messages and the direction ('isL2ToL1').
    */
    function processMessages(
        bool isL2ToL1,
        uint256[] calldata programOutputSlice,
        mapping(bytes32 => uint256) storage messages
    ) internal returns (uint256) {
        uint256 message_segment_size = programOutputSlice[0];
        require(message_segment_size < 2**30, "INVALID_MESSAGE_SEGMENT_SIZE");

        uint256 offset = 1;
        uint256 message_segment_end = offset + message_segment_size;

        uint256 payloadSizeOffset = (
            isL2ToL1 ? MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET : MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET
        );
        while (offset < message_segment_end) {
            uint256 payloadLengthOffset = offset + payloadSizeOffset;
            require(payloadLengthOffset < programOutputSlice.length, "MESSAGE_TOO_SHORT");

            uint256 payloadLength = programOutputSlice[payloadLengthOffset];
            require(payloadLength < 2**30, "INVALID_PAYLOAD_LENGTH");

            uint256 endOffset = payloadLengthOffset + 1 + payloadLength;
            require(endOffset <= programOutputSlice.length, "TRUNCATED_MESSAGE_PAYLOAD");

            if (isL2ToL1) {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(programOutputSlice[offset:endOffset])
                );

                emit LogMessageToL1(
                    // from=
                    programOutputSlice[offset + MESSAGE_TO_L1_FROM_ADDRESS_OFFSET],
                    // to=
                    address(programOutputSlice[offset + MESSAGE_TO_L1_TO_ADDRESS_OFFSET]),
                    // payload=
                    (uint256[])(programOutputSlice[offset + MESSAGE_TO_L1_PREFIX_SIZE:endOffset])
                );
                messages[messageHash] += 1;
            } else {
                {
                    bytes32 messageHash = keccak256(
                        abi.encodePacked(programOutputSlice[offset:endOffset])
                    );

                    require(messages[messageHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
                    messages[messageHash] -= 1;
                }

                uint256 nonce = programOutputSlice[offset + MESSAGE_TO_L2_NONCE_OFFSET];
                // Note that in the case of a message from L1 to L2, the selector (a single integer)
                // is prepended to the payload.
                emit ConsumedMessageToL2(
                    // from=
                    address(programOutputSlice[offset + MESSAGE_TO_L2_FROM_ADDRESS_OFFSET]),
                    // to=
                    programOutputSlice[offset + MESSAGE_TO_L2_TO_ADDRESS_OFFSET],
                    // selector=
                    programOutputSlice[offset + MESSAGE_TO_L2_SELECTOR_OFFSET],
                    // payload=
                    (uint256[])(programOutputSlice[offset + MESSAGE_TO_L2_PREFIX_SIZE:endOffset]),
                    // nonce =
                    nonce
                );
            }

            offset = endOffset;
        }
        require(offset == message_segment_end, "INVALID_MESSAGE_SEGMENT_SIZE");

        return offset;
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MGovernance.sol";
import "NamedStorage.sol";

/**
  A Governor controlled finalizable contract.
  The inherited contract (the one that is GovernedFinalizable) implements the Governance.
*/
abstract contract GovernedFinalizable is MGovernance {
    string constant STORAGE_TAG = "STARKWARE_CONTRACTS_GOVERENED_FINALIZABLE_1.0_TAG";

    function isFinalized() public view returns (bool) {
        return NamedStorage.getBoolValue(STORAGE_TAG);
    }

    modifier notFinalized() {
        require(!isFinalized(), "FINALIZED");
        _;
    }

    function finalize() external onlyGovernance {
        NamedStorage.setBoolValue(STORAGE_TAG, true);
    }
}