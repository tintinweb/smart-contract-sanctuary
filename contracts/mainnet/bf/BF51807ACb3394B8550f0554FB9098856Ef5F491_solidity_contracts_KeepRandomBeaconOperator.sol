/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./TokenStaking.sol";
import "./KeepRegistry.sol";
import "./GasPriceOracle.sol";
import "./cryptography/BLS.sol";
import "./utils/AddressArrayUtils.sol";
import "./utils/PercentUtils.sol";
import "./libraries/operator/GroupSelection.sol";
import "./libraries/operator/Groups.sol";
import "./libraries/operator/DKGResultVerification.sol";
import "./libraries/operator/Reimbursements.sol";
import "./libraries/operator/DelayFactor.sol";

interface ServiceContract {
    function entryCreated(uint256 requestId, bytes calldata entry, address payable submitter) external;
    function fundRequestSubsidyFeePool() external payable;
    function fundDkgFeePool() external payable;
    function callbackSurplusRecipient(uint256 requestId) external view returns(address payable);
}

/// @title KeepRandomBeaconOperator
/// @notice Keep client facing contract for random beacon security-critical operations.
/// Handles group creation and expiration, BLS signature verification and incentives.
/// The contract is not upgradeable. New functionality can be implemented by deploying
/// new versions following Keep client update and re-authorization by the stakers.
contract KeepRandomBeaconOperator is ReentrancyGuard, GasPriceOracleConsumer {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using AddressArrayUtils for address[];
    using GroupSelection for GroupSelection.Storage;
    using Groups for Groups.Storage;
    using DKGResultVerification for DKGResultVerification.Storage;

    event OnGroupRegistered(bytes groupPubKey);
    event DkgResultSubmittedEvent(
        uint256 memberIndex,
        bytes groupPubKey,
        bytes misbehaved
    );
    event RelayEntryRequested(bytes previousEntry, bytes groupPublicKey);
    event RelayEntrySubmitted();
    event GroupSelectionStarted(uint256 newEntry);
    event GroupMemberRewardsWithdrawn(
        address indexed beneficiary,
        address operator,
        uint256 amount,
        uint256 groupIndex
    );
    event RelayEntryTimeoutReported(uint256 indexed groupIndex);
    event UnauthorizedSigningReported(uint256 indexed groupIndex);

    GroupSelection.Storage groupSelection;
    Groups.Storage groups;
    DKGResultVerification.Storage dkgResultVerification;

    address[] internal serviceContracts;

    KeepRegistry internal registry;

    TokenStaking internal stakingContract;

    GasPriceOracle internal gasPriceOracle;

    /// @dev Each signing group member reward expressed in wei.
    uint256 public groupMemberBaseReward = 1000000*1e9; // 1M Gwei

    /// @dev Gas price ceiling value used to calculate the gas price for reimbursement
    /// next to the actual gas price from the transaction. We use gas price
    /// ceiling to defend against malicious miner-submitters who can manipulate
    /// transaction gas price.
    uint256 public gasPriceCeiling = 60*1e9; // (60 Gwei = 60 * 10^9 wei)

    /// @dev Size of a group in the threshold relay.
    uint256 public groupSize = 64;

    /// @dev Minimum number of group members needed to interact according to the
    /// protocol to produce a relay entry.
    uint256 public groupThreshold = 33;

    /// @dev Time in blocks after which the next group member is eligible
    /// to submit the result.
    uint256 public resultPublicationBlockStep = 6;

    /// @dev Timeout in blocks for a relay entry to appear on the chain. Blocks
    /// are counted from the moment relay request occur.
    ///
    /// Timeout is never shorter than the time needed by clients to generate
    /// relay entry and the time it takes for the last group member to become
    /// eligible to submit the result plus at least one block to submit it.
    uint256 public relayEntryTimeout = groupSize.mul(resultPublicationBlockStep);

    /// @dev Gas required to verify BLS signature and produce successful relay
    /// entry. Excludes callback and DKG gas. The worst case (most expensive)
    /// scenario.
    uint256 public entryVerificationGasEstimate = 280000;

    /// @dev Gas required to submit DKG result. Excludes initiation of group selection.
    uint256 public dkgGasEstimate = 1740000;

    /// @dev Gas required to trigger DKG (starting group selection).
    uint256 public groupSelectionGasEstimate = 200000;

    /// @dev Reimbursement for the submitter of the DKG result. This value is set
    /// when a new DKG request comes to the operator contract.
    ///
    /// When submitting DKG result, the submitter is reimbursed with the actual cost
    /// and some part of the fee stored in this field may be returned to the service
    /// contract.
    uint256 public dkgSubmitterReimbursementFee;

    /// @dev Seed value used for the genesis group selection.
    /// https://www.wolframalpha.com/input/?i=pi+to+78+digits
    uint256 internal constant _genesisGroupSeed = 31415926535897932384626433832795028841971693993751058209749445923078164062862;

    /// @dev Service contract that triggered current group selection.
    ServiceContract internal groupSelectionStarterContract;

    // current relay request data
    uint256 internal currentRequestId;
    uint256 public currentRequestStartBlock;
    uint256 public currentRequestGroupIndex;
    bytes public currentRequestPreviousEntry;
    uint256 internal  currentRequestEntryVerificationAndProfitFee;
    uint256 internal currentRequestCallbackFee;
    address internal currentRequestServiceContract;


    /// @notice Triggers group selection if there are no active groups.
    function genesis() public payable {
        // If we run into a very unlikely situation when there are no active
        // groups on the contract because of slashing and groups terminated
        // or because beacon has not been used for a very long time and all
        // groups expired, we first want to make a cleanup.
        groups.expireOldGroups();
        require(numberOfGroups() == 0, "Groups exist");
        // Cleanup after potential failed DKG
        groupSelection.finish();
        // Set latest added service contract as a group selection starter to receive any DKG fee surplus.
        groupSelectionStarterContract = ServiceContract(serviceContracts[serviceContracts.length.sub(1)]);
        startGroupSelection(_genesisGroupSeed, msg.value);
    }

    modifier onlyServiceContract() {
        require(
            serviceContracts.contains(msg.sender),
            "Caller is not a service contract"
        );
        _;
    }

    constructor(
        address _serviceContract,
        address _tokenStaking,
        address _keepRegistry,
        address _gasPriceOracle
    ) public {
        serviceContracts.push(_serviceContract);

        stakingContract = TokenStaking(_tokenStaking);
        registry = KeepRegistry(_keepRegistry);
        gasPriceOracle = GasPriceOracle(_gasPriceOracle);

        groups.stakingContract = stakingContract;
        groups.groupActiveTime = 86400 * 14 / 15; // 14 days equivalent in 15s blocks
        groups.relayEntryTimeout = relayEntryTimeout;

        // There are 78 blocks to submit group selection tickets. To minimize
        // the submitter's cost by minimizing the number of redundant tickets
        // that are not selected into the group, the following approach is
        // recommended:
        //
        // Tickets are submitted in 11 rounds, each round taking 6 blocks.
        // As the basic principle, the number of leading zeros in the ticket
        // value is subtracted from the number of rounds to determine the round
        // the ticket should be submitted in:
        // - in round 0, tickets with 11 or more leading zeros are submitted
        // - in round 1, tickets with 10 or more leading zeros are submitted
        // (...)
        // - in round 11, tickets with no leading zeros are submitted.
        //
        // In each round, group member candidate needs to monitor tickets
        // submitted by other candidates and compare them against tickets of
        // the candidate not yet submitted to determine if continuing with
        // ticket submission still makes sense.
        //
        // After 66 blocks, there is a 12 blocks mining lag allowing all
        // outstanding ticket submissions to have a higher chance of being
        // mined before the deadline.
        groupSelection.ticketSubmissionTimeout = 6 * 11 + 12;

        groupSelection.groupSize = groupSize;

        dkgResultVerification.timeDKG = 5*(1+5) + 2*(1+10) + 20;
        dkgResultVerification.resultPublicationBlockStep = resultPublicationBlockStep;
        dkgResultVerification.groupSize = groupSize;
        dkgResultVerification.signatureThreshold = groupThreshold + (groupSize - groupThreshold) / 2;
    }

    /// @notice Adds service contract
    /// @param serviceContract Address of the service contract.
    function addServiceContract(address serviceContract) public {
        require(
            registry.serviceContractUpgraderFor(address(this)) == msg.sender,
            "Not authorized"
        );

        serviceContracts.push(serviceContract);
    }

    /// @notice Pulls the most recent gas price from gas price oracle.
    function refreshGasPrice() public {
        gasPriceCeiling = gasPriceOracle.gasPrice();
    }

    /// @notice Triggers the selection process of a new candidate group.
    /// @param _newEntry New random beacon value that stakers will use to
    /// generate their tickets.
    /// @param submitter Operator of this contract.
    function createGroup(uint256 _newEntry, address payable submitter) public payable onlyServiceContract {
        uint256 groupSelectionStartFee = groupSelectionGasEstimate.mul(gasPriceCeiling);

        groupSelectionStarterContract = ServiceContract(msg.sender);
        startGroupSelection(_newEntry, msg.value.sub(groupSelectionStartFee));

        // reimbursing a submitter that triggered group selection
        (bool success, ) = stakingContract.beneficiaryOf(submitter).call.value(groupSelectionStartFee)("");
        require(success, "Group selection reimbursement failed");
    }

    function startGroupSelection(uint256 _newEntry, uint256 _payment) internal {
        require(
            _payment >= gasPriceCeiling.mul(dkgGasEstimate),
            "Insufficient DKG fee"
        );

        require(isGroupSelectionPossible(), "Group selection in progress");

        // If previous group selection failed and there is reimbursement left
        // return it to the DKG fee pool.
        if (dkgSubmitterReimbursementFee > 0) {
            uint256 surplus = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            ServiceContract(groupSelectionStarterContract).fundDkgFeePool.value(surplus)();
        }

        groupSelection.minimumStake = stakingContract.minimumStake();
        groupSelection.start(_newEntry);
        emit GroupSelectionStarted(_newEntry);
        dkgSubmitterReimbursementFee = _payment;
    }

    /// @notice Checks if it is possible to fire a new group selection.
    /// Triggering new group selection is only possible when there is no
    /// pending group selection or when the pending group selection timed out.
    function isGroupSelectionPossible() public view returns (bool) {
        if (!groupSelection.inProgress) {
            return true;
        }

        // dkgTimeout is the time after key generation protocol is expected to
        // be complete plus the expected time to submit the result.
        uint256 dkgTimeout = groupSelection.ticketSubmissionStartBlock +
        groupSelection.ticketSubmissionTimeout +
        dkgResultVerification.timeDKG +
        groupSize * resultPublicationBlockStep;

        return block.number > dkgTimeout;
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticket Bytes representation of a ticket that holds the following:
    /// - ticketValue: first 8 bytes of a result of keccak256 cryptography hash
    ///   function on the combination of the group selection seed (previous
    ///   beacon output), staker-specific value (address) and virtual staker index.
    /// - stakerValue: a staker-specific value which is the address of the staker.
    /// - virtualStakerIndex: 4-bytes number within a range of 1 to staker's weight;
    ///   has to be unique for all tickets submitted by the given staker for the
    ///   current candidate group selection.
    function submitTicket(bytes32 ticket) public {
        uint256 stakingWeight = stakingContract.eligibleStake(
            msg.sender, address(this)
        ).div(groupSelection.minimumStake);
        groupSelection.submitTicket(ticket, stakingWeight);
    }

    /// @notice Gets the timeout in blocks after which group candidate ticket
    /// submission is finished.
    function ticketSubmissionTimeout() public view returns (uint256) {
        return groupSelection.ticketSubmissionTimeout;
    }

    /// @notice Gets the submitted group candidate tickets so far.
    function submittedTickets() public view returns (uint64[] memory) {
        return groupSelection.tickets;
    }

    /// @notice Gets selected participants in ascending order of their tickets.
    function selectedParticipants() public view returns (address[] memory) {
        return groupSelection.selectedParticipants();
    }

    /// @notice Submits result of DKG protocol. It is on-chain part of phase 14 of
    /// the protocol.
    /// @param submitterMemberIndex Claimed submitter candidate group member index
    /// @param groupPubKey Generated candidate group public key
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes in ascending order; Indexes reflect positions of
    /// members in the group as outputted by the group selection protocol.
    /// @param signatures Concatenation of signatures from members supporting the
    /// result.
    /// @param signingMembersIndexes Indices of members corresponding to each
    /// signature.
    function submitDkgResult(
        uint256 submitterMemberIndex,
        bytes memory groupPubKey,
        bytes memory misbehaved,
        bytes memory signatures,
        uint[] memory signingMembersIndexes
    ) public nonReentrant {
        address[] memory members = selectedParticipants();

        dkgResultVerification.verify(
            submitterMemberIndex,
            groupPubKey,
            misbehaved,
            signatures,
            signingMembersIndexes,
            members,
            groupSelection.ticketSubmissionStartBlock + groupSelection.ticketSubmissionTimeout
        );

        groups.setGroupMembers(groupPubKey, members, misbehaved);
        groups.addGroup(groupPubKey);
        reimburseDkgSubmitter();
        emit DkgResultSubmittedEvent(submitterMemberIndex, groupPubKey, misbehaved);
        groupSelection.finish();
    }

    /// @notice Compare the reimbursement fee calculated based on the current
    /// transaction gas price and the current price feed estimate with the DKG
    /// reimbursement fee calculated and paid at the moment when the DKG was
    /// requested. If there is any surplus, it will be returned to the DKG fee
    /// pool of the service contract which triggered the DKG.
    function reimburseDkgSubmitter() internal {
        uint256 gasPrice = gasPriceCeiling;
        // We need to check if tx.gasprice is non-zero as a workaround to a bug
        // in go-ethereum:
        // https://github.com/ethereum/go-ethereum/pull/20189
        if (tx.gasprice > 0 && tx.gasprice < gasPriceCeiling) {
            gasPrice = tx.gasprice;
        }

        uint256 reimbursementFee = dkgGasEstimate.mul(gasPrice);
        address payable beneficiary = stakingContract.beneficiaryOf(msg.sender);

        if (reimbursementFee < dkgSubmitterReimbursementFee) {
            uint256 surplus = dkgSubmitterReimbursementFee.sub(reimbursementFee);
            dkgSubmitterReimbursementFee = 0;
            // Reimburse submitter with actual DKG cost.
            beneficiary.call.value(reimbursementFee)("");

            // Return surplus to the contract that started DKG.
            groupSelectionStarterContract.fundDkgFeePool.value(surplus)();
        } else {
            // If submitter used higher gas price reimburse only
            // dkgSubmitterReimbursementFee max.
            reimbursementFee = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            beneficiary.call.value(reimbursementFee)("");
        }
    }

    /// @notice Creates a request to generate a new relay entry, which will include
    /// a random number (by signing the previous entry's random number).
    /// @param requestId Request Id trackable by service contract
    /// @param previousEntry Previous relay entry
    function sign(
        uint256 requestId,
        bytes memory previousEntry
    ) public payable onlyServiceContract {
        uint256 entryVerificationAndProfitFee = groupProfitFee().add(
            entryVerificationFee()
        );
        require(
            msg.value >= entryVerificationAndProfitFee,
            "Insufficient new entry fee"
        );
        uint256 callbackFee = msg.value.sub(entryVerificationAndProfitFee);
        signRelayEntry(
            requestId, previousEntry, msg.sender,
            entryVerificationAndProfitFee, callbackFee
        );
    }

    function signRelayEntry(
        uint256 requestId,
        bytes memory previousEntry,
        address serviceContract,
        uint256 entryVerificationAndProfitFee,
        uint256 callbackFee
    ) internal {
        require(!isEntryInProgress(), "Beacon is busy");

        uint256 groupIndex = groups.selectGroup(uint256(keccak256(previousEntry)));

        currentRequestId = requestId;
        currentRequestStartBlock = block.number;
        currentRequestEntryVerificationAndProfitFee = entryVerificationAndProfitFee;
        currentRequestCallbackFee = callbackFee;
        currentRequestGroupIndex = groupIndex;
        currentRequestPreviousEntry = previousEntry;
        currentRequestServiceContract = serviceContract;

        bytes memory groupPubKey = groups.getGroupPublicKey(groupIndex);
        emit RelayEntryRequested(previousEntry, groupPubKey);
    }

    /// @notice Creates a new relay entry and stores the associated data on the chain.
    /// @param _groupSignature Group BLS signature over the concatenation of the
    /// previous entry and seed.
    function relayEntry(bytes memory _groupSignature) public nonReentrant {
        require(isEntryInProgress(), "Entry was submitted");
        require(!hasEntryTimedOut(), "Entry timed out");

        bytes memory groupPubKey = groups.getGroupPublicKey(currentRequestGroupIndex);

        require(
            BLS.verify(
                groupPubKey,
                currentRequestPreviousEntry,
                _groupSignature
            ),
            "Invalid signature"
        );

        emit RelayEntrySubmitted();

        // Spend no more than groupSelectionGasEstimate + 40000 gas max
        // This will prevent relayEntry failure in case the service contract is compromised
        currentRequestServiceContract.call.gas(groupSelectionGasEstimate.add(40000))(
            abi.encodeWithSignature(
                "entryCreated(uint256,bytes,address)",
                currentRequestId,
                _groupSignature,
                msg.sender
            )
        );

        if (currentRequestCallbackFee > 0) {
            executeCallback(uint256(keccak256(_groupSignature)));
        }

        (uint256 groupMemberReward, uint256 submitterReward, uint256 subsidy) = newEntryRewardsBreakdown();
        groups.addGroupMemberReward(groupPubKey, groupMemberReward);

        stakingContract.beneficiaryOf(msg.sender).call.value(submitterReward)("");

        if (subsidy > 0) {
            currentRequestServiceContract.call.gas(35000).value(subsidy)(
                abi.encodeWithSignature("fundRequestSubsidyFeePool()")
            );
        }

        currentRequestStartBlock = 0;
    }

    /// @notice Executes customer specified callback for the relay entry request.
    /// @param entry The generated random number.
    function executeCallback(uint256 entry) internal {
        // Make sure not to spend more than what was received from the service
        // contract for the callback
        uint256 gasLimit = currentRequestCallbackFee.div(gasPriceCeiling);

        // Make sure not to spend more than 2 million gas on a callback.
        // This is to protect members from relay entry failure and potential
        // slashing in case of any changes in .call() gas limit.
        gasLimit = gasLimit > 2000000 ? 2000000 : gasLimit;

        bytes memory callbackSurplusRecipientData;
        (, callbackSurplusRecipientData) = currentRequestServiceContract.call.gas(
            40000
        )(abi.encodeWithSignature(
            "callbackSurplusRecipient(uint256)",
            currentRequestId
        ));

        uint256 gasBeforeCallback = gasleft();
        currentRequestServiceContract.call.gas(
            gasLimit
        )(abi.encodeWithSignature(
            "executeCallback(uint256,uint256)",
            currentRequestId,
            entry
        ));

        uint256 gasAfterCallback = gasleft();
        uint256 gasSpent = gasBeforeCallback.sub(gasAfterCallback);

        Reimbursements.reimburseCallback(
            stakingContract,
            gasPriceCeiling,
            gasLimit,
            gasSpent,
            currentRequestCallbackFee,
            callbackSurplusRecipientData
        );
    }

    /// @notice Get rewards breakdown in wei for successful entry for the
    /// current signing request.
    function newEntryRewardsBreakdown() internal view returns(
        uint256 groupMemberReward,
        uint256 submitterReward,
        uint256 subsidy
    ) {
        uint256 decimals = 1e16; // Adding 16 decimals to perform float division.

        uint256 delayFactor = DelayFactor.calculate(
            currentRequestStartBlock,
            relayEntryTimeout
        );
        groupMemberReward = groupMemberBaseReward.mul(delayFactor).div(decimals);

        // delay penalty = base reward * (1 - delay factor)
        uint256 groupMemberDelayPenalty = groupMemberBaseReward.mul(decimals.sub(delayFactor));

        // The submitter reward consists of:
        // The callback gas expenditure (reimbursed by the service contract)
        // The entry verification fee to cover the cost of verifying the submission,
        // paid regardless of their gas expenditure
        // Submitter extra reward - 5% of the delay penalties of the entire group
        uint256 submitterExtraReward = groupMemberDelayPenalty.mul(groupSize).percent(5).div(decimals);
        uint256 entryVerificationFee = currentRequestEntryVerificationAndProfitFee.sub(groupProfitFee());
        submitterReward = entryVerificationFee.add(submitterExtraReward);

        // Rewards not paid out to the operators are paid out to requesters to subsidize new requests.
        subsidy = groupProfitFee().sub(groupMemberReward.mul(groupSize)).sub(submitterExtraReward);
    }

    /// @notice Returns true if generation of a new relay entry is currently in
    /// progress.
    function isEntryInProgress() public view returns (bool) {
        return currentRequestStartBlock != 0;
    }

    /// @notice Returns true if the currently ongoing new relay entry generation
    /// operation timed out. There is a certain timeout for a new relay entry
    /// to be produced, see `relayEntryTimeout` value.
    function hasEntryTimedOut() internal view returns (bool) {
        return currentRequestStartBlock != 0 && block.number > currentRequestStartBlock + relayEntryTimeout;
    }

    /// @notice Function used to inform about the fact the currently ongoing
    /// new relay entry generation operation timed out. As a result, the group
    /// which was supposed to produce a new relay entry is immediately
    /// terminated and a new group is selected to produce a new relay entry.
    /// All members of the group are punished by seizing minimum stake of
    /// their tokens. The submitter of the transaction is rewarded with a
    /// tattletale reward which is limited to min(1, 20 / group_size) of the
    /// maximum tattletale reward.
    function reportRelayEntryTimeout() public {
        require(hasEntryTimedOut(), "Entry did not time out");
        groups.reportRelayEntryTimeout(currentRequestGroupIndex, groupSize);
        currentRequestStartBlock = 0;

        // We could terminate the last active group. If that's the case,
        // do not try to execute signing again because there is no group
        // which can handle it.
        if (numberOfGroups() > 0) {
            signRelayEntry(
                currentRequestId,
                currentRequestPreviousEntry,
                currentRequestServiceContract,
                currentRequestEntryVerificationAndProfitFee,
                currentRequestCallbackFee
            );
        }

        emit RelayEntryTimeoutReported(currentRequestGroupIndex);
    }

    /// @notice Gets group profit fee expressed in wei.
    function groupProfitFee() public view returns(uint256) {
        return groupMemberBaseReward.mul(groupSize);
    }

    /// @notice Checks if the specified account has enough active stake to become
    /// network operator and that this contract has been authorized for potential
    /// slashing.
    ///
    /// Having the required minimum of active stake makes the operator eligible
    /// to join the network. If the active stake is not currently undelegating,
    /// operator is also eligible for work selection.
    ///
    /// @param staker Staker's address
    /// @return True if has enough active stake to participate in the network,
    /// false otherwise.
    function hasMinimumStake(address staker) public view returns(bool) {
        return stakingContract.hasMinimumStake(staker, address(this));
    }

    /// @notice Checks if group with the given public key is registered.
    function isGroupRegistered(bytes memory groupPubKey) public view returns(bool) {
        return groups.isGroupRegistered(groupPubKey);
    }

    /// @notice Checks if a group with the given public key is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(bytes memory groupPubKey) public view returns(bool) {
        return groups.isStaleGroup(groupPubKey);
    }

    /// @notice Gets the number of active groups as currently marked in the
    /// contract. This is the state from when the expired groups were last updated
    /// without accounting for recent expirations.
    ///
    /// @dev Even if numberOfGroups() > 0, it is still possible requesting for
    /// a new relay entry will revert with "no active groups" failure message.
    /// This function returns the number of active groups as they are currently
    /// marked on-chain. However, during relay request, before group selection,
    /// we run group expiration and it may happen that some groups seen as active
    /// turns out to be expired.
    function numberOfGroups() public view returns(uint256) {
        return groups.numberOfGroups();
    }

    /// @notice Returns accumulated group member rewards for provided group.
    function getGroupMemberRewards(bytes memory groupPubKey) public view returns (uint256) {
        return groups.groupMemberRewards[groupPubKey];
    }

    /// @notice Return whether the given operator has withdrawn their rewards
    /// from the given group.
    function hasWithdrawnRewards(address operator, uint256 groupIndex)
        public view returns (bool) {
        return groups.hasWithdrawnRewards(operator, groupIndex);
    }

    /// @notice Withdraws accumulated group member rewards for operator
    /// using the provided group index.
    /// Once the accumulated reward is withdrawn from the selected group,
    /// the operator is flagged as withdrawn.
    /// Rewards can be withdrawn only from stale group.
    /// @param operator Operator address
    /// @param groupIndex Group index
    function withdrawGroupMemberRewards(address operator, uint256 groupIndex)
        public nonReentrant {
        uint256 accumulatedRewards = groups.withdrawFromGroup(operator, groupIndex);
        (bool success, ) = stakingContract.beneficiaryOf(operator).call.value(accumulatedRewards)("");
        if (success) {
            emit GroupMemberRewardsWithdrawn(stakingContract.beneficiaryOf(operator), operator, accumulatedRewards, groupIndex);
        }
    }

    /// @notice Gets the index of the first active group.
    function getFirstActiveGroupIndex() public view returns (uint256) {
        return groups.expiredGroupOffset;
    }

    /// @notice Gets public key of the group with the given index.
    function getGroupPublicKey(uint256 groupIndex) public view returns (bytes memory) {
        return groups.getGroupPublicKey(groupIndex);
    }

    /// @notice Returns fee for entry verification in wei. Does not include group
    /// profit fee, DKG contribution or callback fee.
    function entryVerificationFee() public view returns (uint256) {
        return entryVerificationGasEstimate.mul(gasPriceCeiling);
    }

    /// @notice Returns fee for group creation in wei. Includes the cost of DKG
    /// and the cost of triggering group selection.
    function groupCreationFee() public view returns (uint256) {
        return dkgGasEstimate.add(groupSelectionGasEstimate).mul(gasPriceCeiling);
    }

    /// @notice Returns members of the given group by group public key.
    function getGroupMembers(bytes memory groupPubKey) public view returns (address[] memory members) {
        return groups.getGroupMembers(groupPubKey);
    }

    function getNumberOfCreatedGroups() public view returns (uint256) {
        return groups.groups.length;
    }

    function getGroupRegistrationTime(uint256 groupIndex) public view returns (uint256) {
        return groups.getGroupRegistrationTime(groupIndex);
    }

    function isGroupTerminated(uint256 groupIndex) public view returns (bool) {
        return groups.isGroupTerminated(groupIndex);
    }

    /// @notice Reports unauthorized signing for the provided group. Must provide
    /// a valid signature of the tattletale address as a message. Successful signature
    /// verification means the private key has been leaked and all group members
    /// should be punished by seizing their tokens. The submitter of this proof is
    /// rewarded with 5% of the total seized amount scaled by the reward adjustment
    /// parameter and the rest 95% is burned.
    function reportUnauthorizedSigning(
        uint256 groupIndex,
        bytes memory signedMsgSender
    ) public {
        groups.reportUnauthorizedSigning(
            groupIndex,
            signedMsgSender,
            stakingContract.minimumStake()
        );
        emit UnauthorizedSigningReported(groupIndex);
    }
}
