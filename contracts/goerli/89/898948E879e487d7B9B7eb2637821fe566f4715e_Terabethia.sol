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

// import "./IFactRegistry.sol";
import "./IIdentity.sol";
import "./Output.sol";
import "./StarknetGovernance.sol";
import "./StarknetMessaging.sol";
import "./StarknetOperator.sol";
import "./NamedStorage.sol";
import "./ContractInitializer.sol";
import "./ProxySupport.sol";

import "./TerabethiaState.sol";

contract Terabethia is
    IIdentity,
    StarknetGovernance,
    StarknetMessaging,
    StarknetOperator,
    ContractInitializer,
    ProxySupport
{
    using TerabethiaState for TerabethiaState.State;

    // Logs the new state following a state update.
    event LogStateUpdate(int256 sequenceNumber);

    string internal constant STATE_STRUCT_TAG = "TERABETHIA_1.0_STATE_STRUCT";

    // State variable "state" access functions.
    function state()
        internal
        pure
        returns (TerabethiaState.State storage stateStruct)
    {
        bytes32 location = keccak256(abi.encodePacked(STATE_STRUCT_TAG));
        assembly {
            stateStruct_slot := location
        }
    }

    function isInitialized() internal view override returns (bool) {
        return state().sequenceNumber > 0;
    }

    function validateInitData(bytes calldata data) internal pure override {
        require(data.length == 32, "ILLEGAL_INIT_DATA_SIZE");
    }

    function initializeContractState(bytes calldata data) internal override {
        TerabethiaState.State memory initialState = abi.decode(
            data,
            (TerabethiaState.State)
        );

        state().copy(initialState);
        initGovernance();
    }

    /**
      Returns a string that identifies the contract.
    */
    function identify() external pure override returns (string memory) {
        return "Terabethia_2021_1";
    }

    /**
      Returns the current state root.
    */
    // function stateRoot() external view returns (bytes32) {
    //     return state().globalRoot;
    // }

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

        OnchainDataFactTreeEncoder.DataAvailabilityFact
        calldata data_availability_fact
    */
    function updateState(int256 sequenceNumber, bytes32[] calldata output)
        external
        onlyOperator
    {
        // Validate program output.
        StarknetOutput.validate(output);

        // Process L2 -> L1 messages.
        uint256 outputOffset = 0;
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            true,
            output[outputOffset:],
            l2ToL1Messages()
        );

        // Process L1 -> L2 messages.
        outputOffset += StarknetOutput.processMessages(
            // isL2ToL1=
            false,
            output[outputOffset:],
            l1ToL2Messages()
        );

        require(outputOffset == output.length, "STARKNET_OUTPUT_TOO_LONG");

        // Perform state update.
        state().update(sequenceNumber);
        TerabethiaState.State memory state_ = state();
        emit LogStateUpdate(state_.sequenceNumber);
    }
}

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

interface IIdentity {
    /*
      Allows a caller to ensure that the provided address is of the expected type and version.
    */
    function identify() external pure returns (string memory);
}

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

library StarknetOutput {
    uint256 internal constant HEADER_SIZE = 0;

    // An event that is raised when a message is sent from L2 to L1.
    event LogMessageToL1(bytes32 indexed hash);

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(bytes32 indexed hash);

    /**
      Does a sanity check of the output_data length.
    */
    function validate(bytes32[] calldata output_data) internal pure {
        require(output_data.length > HEADER_SIZE, "STARKNET_OUTPUT_TOO_SHORT");
    }

    /**
      Processes a message hashes received from the L2
      The 'messages' mapping is updated according to the messages and the direction ('isL2ToL1').
    */
    function processMessages(
        bool isL2ToL1,
        bytes32[] calldata hashes,
        mapping(bytes32 => uint256) storage messages
    ) internal returns (uint256) {
        // int256 tmp_message_segment_size = int256(programOutputSlice[0]);
        uint256 message_segment_size = uint256(hashes[0]);
        require(message_segment_size < 2**30, "INVALID_MESSAGE_SEGMENT_SIZE");

        uint256 offset = 1;
        uint256 message_segment_end = offset + message_segment_size;

        while (offset < message_segment_end) {
            // uint256 payloadLengthOffset = offset + MESSAGE_PAYLOAD_SIZE_OFFSET;
            require(offset <= hashes.length, "MESSAGE_TOO_SHORT");

            bytes32 messageHash = hashes[offset];

            if (isL2ToL1) {
                emit LogMessageToL1(messageHash);
                messages[messageHash] += 1;
            } else {
                require(
                    messages[messageHash] > 0,
                    "INVALID_MESSAGE_TO_CONSUME"
                );

                // Note that in the case of a message from L1 to L2, the selector (a single integer)
                // is prepended to the payload.
                emit ConsumedMessageToL2(messageHash);
                messages[messageHash] -= 1;
            }

            offset += 1;
        }

        require(offset == message_segment_end, "INVALID_MESSAGE_SEGMENT_SIZE");
        return offset;
    }
}

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

import "./Governance.sol";

contract StarknetGovernance is Governance {
    string constant STARKNET_GOVERNANCE_INFO_TAG =
        "STARKNET_1.0_GOVERNANCE_INFO";

    /*
      Returns the GovernanceInfoStruct associated with the governance tag.
    */
    function getGovernanceInfo()
        internal
        view
        override
        returns (GovernanceInfoStruct storage gub)
    {
        bytes32 location = keccak256(
            abi.encodePacked(STARKNET_GOVERNANCE_INFO_TAG)
        );
        assembly {
            gub_slot := location
        }
    }

    function starknetIsGovernor(address testGovernor)
        external
        view
        returns (bool)
    {
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
pragma solidity ^0.6.12;

import "./IStarknetMessaging.sol";
import "./NamedStorage.sol";

/**
  Implements sending messages to L2 by adding them to a pipe and consuming messages from L2 by
  removing them from a different pipe. A deriving contract can handle the former pipe and add items
  to the latter pipe while interacting with L2.
*/
contract StarknetMessaging is IStarknetMessaging {
    /**
      Random slot storage elements and accessors.
    */
    string constant L1L2_MESSAGE_MAP_TAG =
        "TERABETHIA_1.0_MSGING_L1TOL2_MAPPPING";
    string constant L2L1_MESSAGE_MAP_TAG =
        "TERABETHIA_1.0_MSGING_L2TOL1_MAPPPING";

    function l1ToL2Messages(bytes32 msgHash) external view returns (uint256) {
        return l1ToL2Messages()[msgHash];
    }

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256) {
        return l2ToL1Messages()[msgHash];
    }

    function l1ToL2Messages()
        internal
        pure
        returns (mapping(bytes32 => uint256) storage)
    {
        return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_MAP_TAG);
    }

    function l2ToL1Messages()
        internal
        pure
        returns (mapping(bytes32 => uint256) storage)
    {
        return NamedStorage.bytes32ToUint256Mapping(L2L1_MESSAGE_MAP_TAG);
    }

    /**
      Sends a message to an L2 contract.
    */
    function sendMessage(uint256 to_address, uint256[] calldata payload)
        external
        override
        returns (bytes32)
    {
        emit LogMessageToL2(msg.sender, to_address, payload);
        // Note that the selector (a single integer) is prepended to the payload.
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                uint256(uint160(msg.sender)),
                to_address,
                uint256(payload.length),
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
    function consumeMessage(uint256 from_address, uint256[] calldata payload)
        external
        override
        returns (bytes32)
    {
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                from_address,
                uint256(uint160(msg.sender)),
                uint256(payload.length),
                payload
            )
        );

        require(l2ToL1Messages()[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        emit ConsumedMessageToL1(from_address, msg.sender, payload);
        l2ToL1Messages()[msgHash] -= 1;
        return msgHash;
    }
}

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

import "./NamedStorage.sol";
import "./Operator.sol";

abstract contract StarknetOperator is Operator {
    string constant OPERATORS_MAPPING_TAG =
        "STARKNET_1.0_ROLES_OPERATORS_MAPPING_TAG";

    function getOperators()
        internal
        view
        override
        returns (mapping(address => bool) storage)
    {
        return NamedStorage.addressToBoolMapping(OPERATORS_MAPPING_TAG);
    }
}

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

    function getUintValue(string memory tag_)
        internal
        view
        returns (uint256 retVal)
    {
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

    function getAddressValue(string memory tag_)
        internal
        view
        returns (address retVal)
    {
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
}

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

/**
  Interface for contract initialization.
  The functions it exposes are the app specific parts of the contract initialization,
  and are called by the ProxySupport contract that implement the generic part of behind-proxy
  initialization.
*/
abstract contract ContractInitializer {
    function isInitialized() internal view virtual returns (bool);

    function validateInitData(bytes calldata data) internal pure virtual;

    function initializeContractState(bytes calldata data) internal virtual;
}

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

import "./Governance.sol";
import "./Common.sol";
import "./BlockDirectCall.sol";
import "./ContractInitializer.sol";

/**
  This contract contains the code commonly needed for a contract to be deployed behind
  an upgradability proxy.
  It perform the required semantics of the proxy pattern,
  but in a generic manner.
  Instantiation of the Governance and of the ContractInitializer, that are the app specific
  part of initialization, has to be done by the using contract.
*/
abstract contract ProxySupport is ContractInitializer {
    using Addresses for address;

    // The two function below (isFrozen & initialize) needed to bind to the Proxy.
    function isFrozen() external pure returns (bool) {
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
    function initialize(bytes calldata data) external {
        if (isInitialized()) {
            require(data.length == 0, "UNEXPECTED_INIT_DATA");
        } else {
            // Contract was not initialized yet.
            validateInitData(data);
            initializeContractState(data);
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

import "./Output.sol";

library TerabethiaState {
    struct State {
        // bytes32 globalRoot;
        int256 sequenceNumber;
    }

    function copy(State storage state, State memory stateFrom) internal {
        state.sequenceNumber = stateFrom.sequenceNumber;
    }

    /**
      Validates that the 'sequenceNumber'
    */
    function update(State storage state, int256 sequenceNumber) internal {
        // Check the sequenceNumber first as the error is less ambiguous then INVALID_PREVIOUS_ROOT.
        state.sequenceNumber += 1;
        require(
            state.sequenceNumber == sequenceNumber,
            "INVALID_SEQUENCE_NUMBER"
        );
    }
}

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

import "./MGovernance.sol";

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

    function getGovernanceInfo()
        internal
        view
        virtual
        returns (GovernanceInfoStruct storage);

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

    function isGovernor(address testGovernor)
        internal
        view
        override
        returns (bool)
    {
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
    function removeGovernor(address governorForRemoval)
        internal
        onlyGovernance
    {
        require(msg.sender != governorForRemoval, "GOVERNOR_SELF_REMOVE");
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(isGovernor(governorForRemoval), "NOT_GOVERNOR");
        gub.effectiveGovernors[governorForRemoval] = false;
        emit LogRemovedGovernor(governorForRemoval);
    }
}

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

struct GovernanceInfoStruct {
    mapping(address => bool) effectiveGovernors;
    address candidateGovernor;
    bool initialized;
}

abstract contract MGovernance {
    function isGovernor(address testGovernor)
        internal
        view
        virtual
        returns (bool);

    /*
      Allows calling the function only by a Governor.
    */
    modifier onlyGovernance() {
        require(isGovernor(msg.sender), "ONLY_GOVERNANCE");
        _;
    }
}

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
        uint256[] payload
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
        uint256[] payload
    );

    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessage(uint256 to_address, uint256[] calldata payload)
        external
        returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessage(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

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

import "./MOperator.sol";
import "./MGovernance.sol";

/**
  The Operator of the contract is the entity entitled to submit state update requests
  by calling :sol:func:`updateState`.

  An Operator may be instantly appointed or removed by the contract Governor
  (see :sol:mod:`Governance`). Typically, the Operator is the hot wallet of the service
  submitting proofs for state updates.
*/
abstract contract Operator is MOperator, MGovernance {
    function registerOperator(address newOperator)
        external
        override
        onlyGovernance
    {
        getOperators()[newOperator] = true;
        emit LogOperatorAdded(newOperator);
    }

    function unregisterOperator(address removedOperator)
        external
        override
        onlyGovernance
    {
        getOperators()[removedOperator] = false;
        emit LogOperatorRemoved(removedOperator);
    }

    function isOperator(address testedOperator)
        public
        view
        override
        returns (bool)
    {
        return getOperators()[testedOperator];
    }
}

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

abstract contract MOperator {
    event LogOperatorAdded(address operator);
    event LogOperatorRemoved(address operator);

    function isOperator(address testedOperator)
        public
        view
        virtual
        returns (bool);

    modifier onlyOperator() {
        require(isOperator(msg.sender), "ONLY_OPERATOR");
        _;
    }

    function registerOperator(address newOperator) external virtual;

    function unregisterOperator(address removedOperator) external virtual;

    function getOperators()
        internal
        view
        virtual
        returns (mapping(address => bool) storage);
}

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
    function safeTokenContractCall(address tokenAddress, bytes memory callData)
        internal
    {
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
    function validateContractId(address contractAddress, bytes32 expectedIdHash)
        internal
    {
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

    /*
      Similar to safeTokenContractCall, but always ignores the return value.

      Assumes some other method is used to detect the failures
      (e.g. balance is checked before and after the call).
    */
    function uncheckedTokenContractCall(
        address tokenAddress,
        bytes memory callData
    ) internal {
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = tokenAddress.call(callData);
        require(success, string(returndata));
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