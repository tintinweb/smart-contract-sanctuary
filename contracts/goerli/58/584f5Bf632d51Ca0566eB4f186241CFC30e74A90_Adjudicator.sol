// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../vendor/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./Channel.sol";
import "./App.sol";
import "./AssetHolder.sol";
import "./SafeMath64.sol";

/**
 * @title The Perun Adjudicator
 * @author The Perun Authors
 * @dev Adjudicator is the contract that decides on the current state of a statechannel.
 */
contract Adjudicator {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    /**
     * @dev Our state machine has three phases.
     * In the DISPUTE phase, all parties have the ability to publish their latest state.
     * In the FORCEEXEC phase, the smart contract is executed on-chain.
     * In the CONCLUDED phase, the channel is considered finalized.
     */
    enum DisputePhase { DISPUTE, FORCEEXEC, CONCLUDED }

    struct Dispute {
        uint64 timeout;
        uint64 challengeDuration;
        uint64 version;
        bool hasApp;
        uint8 phase;
        bytes32 stateHash;
    }

    /**
     * @dev Mapping channelID => Dispute.
     */
    mapping(bytes32 => Dispute) public disputes;

    /**
     * @notice Indicates that a channel has been updated.
     * @param channelID The identifier of the channel.
     * @param version The version of the channel state.
     * @param phase The dispute phase of the channel.
     * @param timeout The dispute phase timeout.
     */
    event ChannelUpdate(bytes32 indexed channelID, uint64 version, uint8 phase, uint64 timeout);

    /**
     * @notice Register registers a non-final state of a channel.
     * If the call was successful a Registered event is emitted.
     *
     * @dev It can only be called if the channel has not been registered yet, or
     * the refutation timeout has not passed.
     * The caller has to provide n signatures on the state.
     *
     * @param params The parameters of the state channel.
     * @param state The current state of the state channel.
     * @param sigs Array of n signatures on the current state.
     */
    function register(
        Channel.Params memory params,
        Channel.State memory state,
        bytes[] memory sigs)
    external
    {
        requireValidParams(params, state);
        Channel.validateSignatures(params, state, sigs);

        // If registered, require newer version and refutation timeout not passed.
        (Dispute memory dispute, bool registered) = getDispute(state.channelID);
        if (registered) {
            require(dispute.version < state.version, "invalid version");
            require(dispute.phase == uint8(DisputePhase.DISPUTE), "incorrect phase");
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp < dispute.timeout, "refutation timeout passed");
        }

        storeChallenge(params, state, DisputePhase.DISPUTE);
    }

    /**
     * @notice Progress is used to advance the state of an app on-chain.
     * If the call was successful, a Progressed event is emitted.
     *
     * @dev The caller has to provide a valid signature from the actor.
     * It is checked whether the new state is a valid transition from the old state,
     * so this method can only advance the state by one step.
     *
     * @param params The parameters of the state channel.
     * @param stateOld The previously stored state of the state channel.
     * @param state The new state to which we want to progress.
     * @param actorIdx Index of the signer in the participants array.
     * @param sig Signature of the participant that wants to progress the contract on the new state.
     */
    function progress(
        Channel.Params memory params,
        Channel.State memory stateOld,
        Channel.State memory state,
        uint256 actorIdx,
        bytes memory sig)
    external
    {
        Dispute memory dispute = requireGetDispute(state.channelID);
        if(dispute.phase == uint8(DisputePhase.DISPUTE)) {
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp >= dispute.timeout, "timeout not passed");
        } else if (dispute.phase == uint8(DisputePhase.FORCEEXEC)) {
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp < dispute.timeout, "timeout passed");
        } else {
            revert("invalid phase");
        }

        require(params.app != address(0), "must have app");
        require(actorIdx < params.participants.length, "actorIdx out of range");
        requireValidParams(params, state);
        require(dispute.stateHash == hashState(stateOld), "wrong old state");
        require(Sig.verify(Channel.encodeState(state), sig, params.participants[actorIdx]), "invalid signature");
        requireValidTransition(params, stateOld, state, actorIdx);

        storeChallenge(params, state, DisputePhase.FORCEEXEC);
    }

    /**
     * @notice Function `conclude` concludes the channel identified by `params` including its subchannels and pushes the accumulated outcome to the assetholders.
     * @dev Assumes:
     * - subchannels of `subStates` have participants `params.participants`
     * Requires:
     * - channel not yet concluded
     * - channel parameters valid
     * - channel states valid and registered
     * - dispute timeouts reached
     * Emits:
     * - event Concluded
     *
     * @param params The parameters of the channel and its subchannels.
     * @param state The previously stored state of the channel.
     * @param subStates The previously stored states of the subchannels in depth-first order.
     */
    function conclude(
        Channel.Params memory params,
        Channel.State memory state,
        Channel.State[] memory subStates)
    external
    {
        Dispute memory dispute = requireGetDispute(state.channelID);
        require(dispute.phase != uint8(DisputePhase.CONCLUDED), "channel already concluded");
        requireValidParams(params, state);

        ensureTreeConcluded(state, subStates);
        pushOutcome(state, subStates, params.participants);
    }

    /**
     * @notice Function `concludeFinal` immediately concludes the channel
     * identified by `params` if the provided state is valid and final.
     * The caller must provide signatures from all participants.
     * Since any fully-signed final state supersedes any ongoing dispute,
     * concludeFinal may skip any registered dispute.
     * The function emits events Concluded and FinalConcluded.
     *
     * @param params The parameters of the state channel.
     * @param state The current state of the state channel.
     * @param sigs Array of n signatures on the current state.
     */
    function concludeFinal(
        Channel.Params memory params,
        Channel.State memory state,
        bytes[] memory sigs)
    external
    {
        require(state.isFinal == true, "state not final");
        require(state.outcome.locked.length == 0, "cannot have sub-channels");
        requireValidParams(params, state);
        Channel.validateSignatures(params, state, sigs);

        // If registered, require not concluded.
        (Dispute memory dispute, bool registered) = getDispute(state.channelID);
        if (registered) {
            require(dispute.phase != uint8(DisputePhase.CONCLUDED), "channel already concluded");
        }

        storeChallenge(params, state, DisputePhase.CONCLUDED);

        Channel.State[] memory subStates = new Channel.State[](0);
        pushOutcome(state, subStates, params.participants);
    }

    /**
     * @notice Calculates the channel's ID from the given parameters.
     * @param params The parameters of the channel.
     * @return The ID of the channel.
     */
    function channelID(Channel.Params memory params) public pure returns (bytes32) {
        return keccak256(Channel.encodeParams(params));
    }

    /**
     * @notice Calculates the hash of a state.
     * @param state The state to hash.
     * @return The hash of the state.
     */
    function hashState(Channel.State memory state) public pure returns (bytes32) {
        return keccak256(Channel.encodeState(state));
    }

    /**
     * @notice Asserts that the given parameters are valid for the given state
     * by computing the channelID from the parameters and comparing it to the
     * channelID stored in state.
     */
    function requireValidParams(
        Channel.Params memory params,
        Channel.State memory state)
    internal pure {
        require(state.channelID == channelID(params), "invalid params");
    }

    /**
     * @dev Updates the dispute state according to the given parameters, state,
     * and phase, and determines the corresponding phase timeout.
     * @param params The parameters of the state channel.
     * @param state The current state of the state channel.
     * @param disputePhase The channel phase.
     */
    function storeChallenge(
        Channel.Params memory params,
        Channel.State memory state,
        DisputePhase disputePhase)
    internal
    {
        (Dispute memory dispute, bool registered) = getDispute(state.channelID);
        
        dispute.challengeDuration = uint64(params.challengeDuration);
        dispute.version = state.version;
        dispute.hasApp = params.app != address(0);
        dispute.phase = uint8(disputePhase);
        dispute.stateHash = hashState(state);

        // Compute timeout.
        if (state.isFinal) {
            // Make channel concludable if state is final.
            // solhint-disable-next-line not-rely-on-time
            dispute.timeout = uint64(block.timestamp);
        } else if (!registered || dispute.phase == uint8(DisputePhase.FORCEEXEC)) {
            // Increment timeout if channel is not registered or in phase FORCEEXEC.
            // solhint-disable-next-line not-rely-on-time
            dispute.timeout = uint64(block.timestamp).add(dispute.challengeDuration);
        }

        setDispute(state.channelID, dispute);
    }

    /**
     * @dev Checks if a transition between two states is valid.
     * This calls the validTransition() function of the app.
     *
     * @param params The parameters of the state channel.
     * @param from The previous state of the state channel.
     * @param to The new state of the state channel.
     * @param actorIdx Index of the signer in the participants array.
     */
    function requireValidTransition(
        Channel.Params memory params,
        Channel.State memory from,
        Channel.State memory to,
        uint256 actorIdx)
    internal pure
    {
        require(to.version == from.version + 1, "version must increment by one");
        require(from.isFinal == false, "cannot progress from final state");
        requireAssetPreservation(from.outcome, to.outcome, params.participants.length);
        App app = App(params.app);
        app.validTransition(params, from, to, actorIdx);
    }

    /**
     * @dev Checks if two allocations are compatible, e.g. if the sums of the
     * allocations are equal.
     * @param oldAlloc The old allocation.
     * @param newAlloc The new allocation.
     * @param numParts length of the participants in the parameters.
     */
    function requireAssetPreservation(
        Channel.Allocation memory oldAlloc,
        Channel.Allocation memory newAlloc,
        uint256 numParts)
    internal pure
    {
        require(oldAlloc.balances.length == newAlloc.balances.length, "balances length mismatch");
        require(oldAlloc.assets.length == newAlloc.assets.length, "assets length mismatch");
        require(oldAlloc.locked.length == 0, "funds locked in old state");
        require(newAlloc.locked.length == 0, "funds locked in new state");
        for (uint256 i = 0; i < newAlloc.assets.length; i++) {
            require(oldAlloc.assets[i] == newAlloc.assets[i], "assets[i] address mismatch");
            uint256 sumOld = 0;
            uint256 sumNew = 0;
            require(oldAlloc.balances[i].length == numParts, "old balances length mismatch");
            require(newAlloc.balances[i].length == numParts, "new balances length mismatch");
            for (uint256 k = 0; k < numParts; k++) {
                sumOld = sumOld.add(oldAlloc.balances[i][k]);
                sumNew = sumNew.add(newAlloc.balances[i][k]);
            }

            require(sumOld == sumNew, "sum of balances mismatch");
        }
    }

    /**
     * @notice Function `ensureTreeConcluded` checks that `state` and
     * `substates` form a valid channel state tree and marks the corresponding
     * channels as concluded. The substates must be in depth-first order.
     * The function emits a Concluded event for every not yet concluded channel.
     * @dev The function works recursively using `ensureTreeConcludedRecursive`
     * and `ensureConcluded` as helper functions.
     *
     * @param state The previously stored state of the channel.
     * @param subStates The previously stored states of the subchannels in
     * depth-first order.
     */
    function ensureTreeConcluded(
        Channel.State memory state,
        Channel.State[] memory subStates)
    internal
    {
        ensureConcluded(state);
        uint256 index = ensureTreeConcludedRecursive(state, subStates, 0);
        require(index == subStates.length, "wrong number of substates");
    }

    /**
     * @notice Function `ensureTreeConcludedRecursive` is a helper function for
     * ensureTreeConcluded. It recursively checks the validity of the subchannel
     * states given a parent channel state. It then sets the channels concluded.
     * @param parentState The sub channels to be checked recursively.
     * @param subStates The states of all subchannels in the tree in depth-first
     * order.
     * @param startIndex The index in subStates of the first item of
     * subChannels.
     * @return The index of the next state to be checked.
     */
    function ensureTreeConcludedRecursive(
        Channel.State memory parentState,
        Channel.State[] memory subStates,
        uint256 startIndex)
    internal
    returns (uint256)
    {
        uint256 channelIndex = startIndex;
        Channel.SubAlloc[] memory locked = parentState.outcome.locked;
        for (uint256 i = 0; i < locked.length; i++) {
            Channel.State memory state = subStates[channelIndex];
            require(locked[i].ID == state.channelID, "invalid channel ID");
            ensureConcluded(state);

            channelIndex++;
            if (state.outcome.locked.length > 0) {
                channelIndex = ensureTreeConcludedRecursive(state, subStates, channelIndex);
            }
        }
        return channelIndex;
    }

    /**
     * @notice Function `ensureConcluded` checks for the given state
     * that it has been registered and its timeout is reached.
     * It then sets the channel as concluded and emits event Concluded.
     * @dev The function is a helper function for `ensureTreeConcluded`.
     * @param state The state of the target channel.
     */
    function ensureConcluded(
        Channel.State memory state)
    internal
    {
        Dispute memory dispute = requireGetDispute(state.channelID);
        require(dispute.stateHash == hashState(state), "invalid channel state");
        
        // Return immediately if already concluded.
        if (dispute.phase == uint8(DisputePhase.CONCLUDED)) { return; }

        // If still in phase DISPUTE and the channel has an app, increase the
        // timeout by one duration to account for phase FORCEEXEC.
        if (dispute.phase == uint8(DisputePhase.DISPUTE) && dispute.hasApp) {
            dispute.timeout = dispute.timeout.add(dispute.challengeDuration);
        }
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= dispute.timeout, "timeout not passed yet");
        dispute.phase = uint8(DisputePhase.CONCLUDED);

        setDispute(state.channelID, dispute);
    }

    /**
     * @notice Function `pushOutcome` pushes the accumulated outcome of the
     * channel identified by `state.channelID` and its subchannels referenced by
     * `subStates` to the assetholder contracts.
     * The following must be guaranteed when calling the function:
     * - state and subStates conform with participants
     * - the outcome has not been pushed yet
     * @param state The state of the channel.
     * @param subStates The states of the subchannels of the channel in
     * depth-first order.
     * @param participants The participants of the channel and the subchannels.
     */
    function pushOutcome(
        Channel.State memory state,
        Channel.State[] memory subStates,
        address[] memory participants)
    internal
    {
        address[] memory assets = state.outcome.assets;

        for (uint256 a = 0; a < assets.length; a++) {
            // accumulate outcome over channel and subchannels
            uint256[] memory outcome = new uint256[](participants.length);
            for (uint256 p = 0; p < outcome.length; p++) {
                outcome[p] = state.outcome.balances[a][p];
                for (uint256 s = 0; s < subStates.length; s++) {
                    Channel.State memory subState = subStates[s];
                    require(subState.outcome.assets[a] == assets[a], "assets do not match");

                    // assumes participants at same index are the same
                    uint256 acc = outcome[p];
                    uint256 val = subState.outcome.balances[a][p];
                    outcome[p] = acc.add(val);
                }
            }

            // push accumulated outcome
            AssetHolder(assets[a]).setOutcome(state.channelID, participants, outcome);
        }
    }

    /**
     * @dev Returns the dispute state for the given channelID. The second return
     * value indicates whether the given channel has been registered yet.
     */
    function getDispute(bytes32 _channelID) internal view returns (Dispute memory, bool) {
        Dispute memory dispute = disputes[_channelID];
        return (dispute, dispute.stateHash != bytes32(0));
    }

    /**
     * @dev Returns the dispute state for the given channelID. Reverts if the
     * channel has not been registered yet.
     */
    function requireGetDispute(bytes32 _channelID) internal view returns (Dispute memory) {
        (Dispute memory dispute, bool registered) = getDispute(_channelID);
        require(registered, "not registered");
        return dispute;
    }

    /**
     * @dev Sets the dispute state for the given channelID. Emits event
     * ChannelUpdate.
     */
    function setDispute(bytes32 _channelID, Dispute memory dispute) internal {
        disputes[_channelID] = dispute;
        emit ChannelUpdate(_channelID, dispute.version, dispute.phase, dispute.timeout);
    }
}

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Channel.sol";

/**
 * @title The App interface
 * @author The Perun Authors
 * @dev Every App that should be played in a state channel needs to implement this interface.
 */
interface App {
    /**
     * @notice ValidTransition checks if there was a valid transition between two states.
     * @dev ValidTransition should revert on an invalid transition.
     * Only App specific checks should be performed.
     * The adjudicator already checks the following:
     * - state corresponds to the params
     * - correct dimensions of the allocation
     * - preservation of balances
     * - params.participants[actorIdx] signed the to state
     * @param params The parameters of the channel.
     * @param from The current state.
     * @param to The potenrial next state.
     * @param actorIdx Index of the actor who signed this transition.
     */
    function validTransition(
        Channel.Params calldata params,
        Channel.State calldata from,
        Channel.State calldata to,
        uint256 actorIdx
    ) external pure;
}

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../vendor/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./Sig.sol";

/**
 * @title The Perun AssetHolder
 * @notice AssetHolder is an abstract contract that holds the funds for a
 * Perun state channel.
 */
abstract contract AssetHolder {
    using SafeMath for uint256;

    /**
     * @dev WithdrawalAuth authorizes an on-chain public key to withdraw from an ephemeral key.
     */
    struct WithdrawalAuth {
        bytes32 channelID;
        address participant; // The account used to sign the authorization which is debited.
        address payable receiver; // The receiver of the authorization.
        uint256 amount; // The amount that can be withdrawn.
    }

    event OutcomeSet(bytes32 indexed channelID);
    event Deposited(bytes32 indexed fundingID, uint256 amount);
    event Withdrawn(bytes32 indexed fundingID, uint256 amount, address receiver);

    /**
     * @notice This mapping stores the balances of participants to their fundingID.
     * @dev Mapping H(channelID||participant) => money
     */
    mapping(bytes32 => uint256) public holdings;

    /**
     * @notice This mapping stores whether a channel was already settled.
     * @dev Mapping channelID => settled
     */
    mapping(bytes32 => bool) public settled;

    /**
     * @notice Address of the adjudicator contract that can call setOutcome.
     * @dev Set by the constructor.
     */
    address public adjudicator;

    /**
     * @notice The onlyAdjudicator modifier specifies functions that can only be called from the adjudicator contract.
     */
    modifier onlyAdjudicator {
        require(msg.sender == adjudicator, "can only be called by the adjudicator"); // solhint-disable-line reason-string
        _;
    }

    /**
     * @notice Sets the adjudicator contract that is able to call setOutcome on this contract.
     * @param _adjudicator Address of the adjudicator contract.
     */
    constructor(address _adjudicator) {
        adjudicator = _adjudicator;
    }

    /**
     * @notice Sets the final outcome of a channel. Can only be called by the adjudicator.
     * @dev This method should not be overwritten by the implementing contract.
     * @param channelID ID of the channel that should be disbursed.
     * @param parts Array of participants of the channel.
     * @param newBals New Balances after execution of the channel.
     */
    function setOutcome(
        bytes32 channelID,
        address[] calldata parts,
        uint256[] calldata newBals)
    external onlyAdjudicator {
        require(parts.length == newBals.length, "participants length should equal balances"); // solhint-disable-line reason-string
        require(settled[channelID] == false, "trying to set already settled channel"); // solhint-disable-line reason-string

        // The channelID itself might already be funded
        uint256 sumHeld = holdings[channelID];
        holdings[channelID] = 0;
        uint256 sumOutcome = 0;

        bytes32[] memory fundingIDs = new bytes32[](parts.length);
        for (uint256 i = 0; i < parts.length; i++) {
            bytes32 id = calcFundingID(channelID, parts[i]);
            // Save calculated ids to save gas.
            fundingIDs[i] = id;
            // Compute old balances.
            sumHeld = sumHeld.add(holdings[id]);
            // Compute new balances.
            sumOutcome = sumOutcome.add(newBals[i]);
        }

        // We allow overfunding channels, who overfunds looses their funds.
        if (sumHeld >= sumOutcome) {
            for (uint256 i = 0; i < parts.length; i++) {
                holdings[fundingIDs[i]] = newBals[i];
            }
        }
        settled[channelID] = true;
        emit OutcomeSet(channelID);
    }

    /**
     * @notice Function that is used to fund a channel.
     * @dev Generic function which uses the virtual functions `depositCheck` and
     * `depositEnact` to execute the user specific code.
     * Requires that:
     *  - `depositCheck` does not revert
     *  - `depositEnact` does not revert
     * Increases the holdings for the participant.
     * Emits a `Deposited` event upon success.
     * @param fundingID Unique identifier for a participant in a channel.
     * Calculated as the hash of the channel id and the participant address.
     * @param amount Amount of money that should be deposited.
     */
    function deposit(bytes32 fundingID, uint256 amount) external payable {
        depositCheck(fundingID, amount);
        holdings[fundingID] = holdings[fundingID].add(amount);
        depositEnact(fundingID, amount);       
        emit Deposited(fundingID, amount);
    }

    /**
     * @notice Sends money from authorization.participant to authorization.receiver.
     * @dev Generic function which uses the virtual functions `withdrawCheck` and
     * `withdrawEnact` to execute the user specific code.
     * Requires that:
     *  - Channel is settled
     *  - Signature is valid
     *  - Enough holdings are available
     *  - `withdrawCheck` does not revert
     *  - `withdrawEnact` does not revert
     * Decreases the holdings for the participant.
     * Emits a `Withdrawn` event upon success.
     * @param authorization WithdrawalAuth that specifies which account receives
     * what amounf of asset from which channel participant.
     * @param signature Signature on the withdrawal authorization.
     */
    function withdraw(WithdrawalAuth calldata authorization, bytes calldata signature) external {
        require(settled[authorization.channelID], "channel not settled");
        require(Sig.verify(abi.encode(authorization), signature, authorization.participant), "signature verification failed");
        bytes32 id = calcFundingID(authorization.channelID, authorization.participant);
        require(holdings[id] >= authorization.amount, "insufficient funds");
        withdrawCheck(authorization, signature);
        holdings[id] = holdings[id].sub(authorization.amount);
        withdrawEnact(authorization, signature);
        emit Withdrawn(id, authorization.amount, authorization.receiver);
    }

    /**
     * @notice Checks a deposit for validity and reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `deposit` before `depositEnact`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function depositCheck(bytes32 fundingID, uint256 amount) internal view virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Enacts a deposit or reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `deposit` after `depositCheck`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function depositEnact(bytes32 fundingID, uint256 amount) internal virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Checks a withdrawal for validity and reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `withdraw` before `withdrawEnact`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function withdrawCheck(WithdrawalAuth calldata authorization, bytes calldata signature) internal view virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Enacts a withdrawal or reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `withdraw` after `withdrawCheck`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function withdrawEnact(WithdrawalAuth calldata authorization, bytes calldata signature) internal virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Internal helper function that calculates the fundingID.
     * @param channelID ID of the channel.
     * @param participant Address of a participant in the channel.
     * @return The funding ID, an identifier used for indexing.
     */
    function calcFundingID(bytes32 channelID, address participant) internal pure returns (bytes32) {
        return keccak256(abi.encode(channelID, participant));
    }
}

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Sig.sol";

library Channel {
    struct Params {
        uint256 challengeDuration;
        uint256 nonce;
        address app;
        address[] participants;
    }

    struct State {
        bytes32 channelID;
        uint64 version;
        Allocation outcome;
        bytes appData;
        bool isFinal;
    }

    struct Allocation {
        address[] assets;
        // Outer dimension are assets, inner dimension are the participants.
        uint256[][] balances;
        SubAlloc[] locked;
    }

    struct SubAlloc {
        // ID is the channelID of the subchannel
        bytes32 ID; // solhint-disable-line var-name-mixedcase
        // balances holds the total balance of the subchannel of every asset.
        uint256[] balances;
    }

    /**
     * @notice Checks that `sigs` contains all signatures on the state
     * from the channel participants. Reverts otherwise.
     * @param params The parameters corresponding to the state.
     * @param state The state of the state channel.
     * @param sigs An array of signatures corresponding to the participants
     * of the channel.
     */
    function validateSignatures(
        Params memory params,
        State memory state,
        bytes[] memory sigs)
    internal pure
    {
        bytes memory encodedState = encodeState(state);
        require(params.participants.length == sigs.length, "signatures length mismatch");
        for (uint256 i = 0; i < sigs.length; i++) {
            require(Sig.verify(encodedState, sigs[i], params.participants[i]), "invalid signature");
        }
    }

    function encodeParams(Params memory params) internal pure returns (bytes memory)  {
        return abi.encode(params);
    }

    function encodeState(State memory state) internal pure returns (bytes memory)  {
        return abi.encode(state);
    }
}

// Copyright 2020 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;

library SafeMath64 {
    /**
     * @dev Function `add` returns the sum of `x` and `y` if less than or equal
     * to the maximum of type uint64. Otherwise, the function reverts.
     */
    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x + y) >= x, "overflow");
    }
}

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;

import "../vendor/openzeppelin-contracts/contracts/cryptography/ECDSA.sol";

// Sig is a library to verify signatures.
library Sig {
    // Verify verifies whether a piece of data was signed correctly.
    function verify(bytes memory data, bytes memory signature, address signer) internal pure returns (bool) {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(data));
        address recoveredAddr = ECDSA.recover(prefixedHash, signature);
        return recoveredAddr == signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}