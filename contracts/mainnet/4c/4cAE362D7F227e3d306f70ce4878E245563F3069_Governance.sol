// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./Parameters.sol";

abstract contract Bridge is Parameters {

    mapping(bytes32 => bool) public queuedTransactions;

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal returns (bytes32) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = true;

        return txHash;
    }

    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = false;
    }

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal returns (bytes memory) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);

        require(block.timestamp >= eta, "executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= eta + gracePeriodDuration, "executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, string(returnData));

        return returnData;
    }

    function _getTxHash(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, eta));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract Parameters {
    uint256 public warmUpDuration = 4 days;
    uint256 public activeDuration = 4 days;
    uint256 public queueDuration = 4 days;
    uint256 public gracePeriodDuration = 4 days;

    uint256 public acceptanceThreshold = 60;
    uint256 public minQuorum = 40;

    uint256 constant ACTIVATION_THRESHOLD = 400_000*10**18;
    uint256 constant PROPOSAL_MAX_ACTIONS = 10;

    modifier onlyDAO () {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    function setWarmUpDuration(uint256 period) public onlyDAO {
        warmUpDuration = period;
    }

    function setActiveDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        activeDuration = period;
    }

    function setQueueDuration(uint256 period) public onlyDAO {
        queueDuration = period;
    }

    function setGracePeriodDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        gracePeriodDuration = period;
    }

    function setAcceptanceThreshold(uint256 threshold) public onlyDAO {
        require(threshold <= 100, "Maximum is 100.");
        require(threshold > 50, "Minimum is 50.");

        acceptanceThreshold = threshold;
    }

    function setMinQuorum(uint256 quorum) public onlyDAO {
        require(quorum > 5, "quorum must be greater than 5");
        require(quorum <= 100, "Maximum is 100.");

        minQuorum = quorum;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IBarn.sol";
import "./Bridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Governance is Bridge {
    using SafeMath for uint256;

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Grace,
        Expired,
        Executed,
        Abrogated
    }

    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint256 votes;
        // support
        bool support;
    }

    struct AbrogationProposal {
        address creator;
        uint256 createTime;
        string description;

        uint256 forVotes;
        uint256 againstVotes;

        mapping(address => Receipt) receipts;
    }

    struct ProposalParameters {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    }

    struct Proposal {
        // proposal identifiers
        // unique id
        uint256 id;
        // Creator of the proposal
        address proposer;
        // proposal description
        string description;
        string title;

        // proposal technical details
        // ordered list of target addresses to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // proposal creation time - 1
        uint256 createTime;

        // votes status
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        bool canceled;
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;

        ProposalParameters parameters;
    }

    uint256 public lastProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AbrogationProposal) public abrogationProposals;
    mapping(address => uint256) public latestProposalIds;
    IBarn barn;
    bool isInitialized;
    bool public isActive;

    event ProposalCreated(uint256 indexed proposalId);
    event Vote(uint256 indexed proposalId, address indexed user, bool support, uint256 power);
    event VoteCanceled(uint256 indexed proposalId, address indexed user);
    event ProposalQueued(uint256 indexed proposalId, address caller, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId, address caller);
    event ProposalCanceled(uint256 indexed proposalId, address caller);
    event AbrogationProposalStarted(uint256 indexed proposalId, address caller);
    event AbrogationProposalExecuted(uint256 indexed proposalId, address caller);
    event AbrogationProposalVote(uint256 indexed proposalId, address indexed user, bool support, uint256 power);
    event AbrogationProposalVoteCancelled(uint256 indexed proposalId, address indexed user);

    receive() external payable {}

    // executed only once
    function initialize(address barnAddr) public {
        require(isInitialized == false, "Contract already initialized.");
        require(barnAddr != address(0), "barn must not be 0x0");

        barn = IBarn(barnAddr);
        isInitialized = true;
    }

    function activate() public {
        require(!isActive, "DAO already active");
        require(barn.bondStaked() >= ACTIVATION_THRESHOLD, "Threshold not met yet");

        isActive = true;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory title
    )
    public returns (uint256)
    {
        if (!isActive) {
            require(barn.bondStaked() >= ACTIVATION_THRESHOLD, "DAO not yet active");
            isActive = true;
        }

        require(
            barn.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThreshold(),
            "Creation threshold not met"
        );
        require(
            targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            "Proposal function information arity mismatch"
        );
        require(targets.length != 0, "Must provide actions");
        require(targets.length <= PROPOSAL_MAX_ACTIONS, "Too many actions on a vote");
        require(bytes(title).length > 0, "title can't be empty");
        require(bytes(description).length > 0, "description can't be empty");

        // check if user has another running vote
        uint256 previousProposalId = latestProposalIds[msg.sender];
        if (previousProposalId != 0) {
            require(_isLiveState(previousProposalId) == false, "One live proposal per proposer");
        }

        uint256 newProposalId = lastProposalId + 1;
        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.title = title;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.createTime = block.timestamp - 1;
        newProposal.parameters.warmUpDuration = warmUpDuration;
        newProposal.parameters.activeDuration = activeDuration;
        newProposal.parameters.queueDuration = queueDuration;
        newProposal.parameters.gracePeriodDuration = gracePeriodDuration;
        newProposal.parameters.acceptanceThreshold = acceptanceThreshold;
        newProposal.parameters.minQuorum = minQuorum;

        lastProposalId = newProposalId;
        latestProposalIds[msg.sender] = newProposalId;

        emit ProposalCreated(newProposalId);

        return newProposalId;
    }

    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Accepted, "Proposal can only be queued if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = proposal.createTime + proposal.parameters.warmUpDuration + proposal.parameters.activeDuration + proposal.parameters.queueDuration;
        proposal.eta = eta;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            require(
                !queuedTransactions[_getTxHash(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta)],
                "proposal action already queued at eta"
            );

            queueTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }

        emit ProposalQueued(proposalId, msg.sender, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(_canBeExecuted(proposalId), "Cannot be executed");

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalExecuted(proposalId, msg.sender);
    }

    function cancelProposal(uint256 proposalId) public {
        require(_isCancellableState(proposalId), "Proposal in state that does not allow cancellation");
        require(_canCancelProposal(proposalId), "Cancellation requirements not met");

        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId, msg.sender);
    }

    function castVote(uint256 proposalId, bool support) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        // exit if user already voted
        require(receipt.hasVoted == false || receipt.hasVoted && receipt.support != support, "Already voted this option");

        uint256 votes = barn.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                proposal.forVotes = proposal.forVotes.sub(receipt.votes);
            } else {
                proposal.againstVotes = proposal.againstVotes.sub(receipt.votes);
            }
        }

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit Vote(proposalId, msg.sender, support, votes);
    }

    function cancelVote(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        uint256 votes = barn.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            proposal.forVotes = proposal.forVotes.sub(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.sub(votes);
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit VoteCanceled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // Abrogation proposal methods
    // ======================================================================================================

    // the Abrogation Proposal is a mechanism for the DAO participants to veto the execution of a proposal that was already
    // accepted and it is currently queued. For the Abrogation Proposal to pass, 50% + 1 of the vBOND holders
    // must vote FOR the Abrogation Proposal
    function startAbrogationProposal(uint256 proposalId, string memory description) public {
        require(state(proposalId) == ProposalState.Queued, "Proposal must be in queue");
        require(
            barn.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThreshold(),
            "Creation threshold not met"
        );

        AbrogationProposal storage ap = abrogationProposals[proposalId];

        require(ap.createTime == 0, "Abrogation proposal already exists");
        require(bytes(description).length > 0, "description can't be empty");

        ap.createTime = block.timestamp;
        ap.creator = msg.sender;
        ap.description = description;

        emit AbrogationProposalStarted(proposalId, msg.sender);
    }

    // abrogateProposal cancels a proposal if there's an Abrogation Proposal that passed
    function abrogateProposal(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Abrogated, "Cannot be abrogated");

        Proposal storage proposal = proposals[proposalId];

        require(proposal.canceled == false, "Cannot be abrogated");

        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit AbrogationProposalExecuted(proposalId, msg.sender);
    }

    function abrogationProposal_castVote(uint256 proposalId, bool support) public {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        AbrogationProposal storage abrogationProposal = abrogationProposals[proposalId];
        require(
            state(proposalId) == ProposalState.Queued && abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        Receipt storage receipt = abrogationProposal.receipts[msg.sender];
        require(
            receipt.hasVoted == false || receipt.hasVoted && receipt.support != support,
            "Already voted this option"
        );

        uint256 votes = barn.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                abrogationProposal.forVotes = abrogationProposal.forVotes.sub(receipt.votes);
            } else {
                abrogationProposal.againstVotes = abrogationProposal.againstVotes.sub(receipt.votes);
            }
        }

        if (support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes.add(votes);
        } else {
            abrogationProposal.againstVotes = abrogationProposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit AbrogationProposalVote(proposalId, msg.sender, support, votes);
    }

    function abrogationProposal_cancelVote(uint256 proposalId) public {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        AbrogationProposal storage abrogationProposal = abrogationProposals[proposalId];
        Receipt storage receipt = abrogationProposal.receipts[msg.sender];

        require(
            state(proposalId) == ProposalState.Queued && abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        uint256 votes = barn.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes.sub(votes);
        } else {
            abrogationProposal.againstVotes = abrogationProposal.againstVotes.sub(votes);
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit AbrogationProposalVoteCancelled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // views
    // ======================================================================================================

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (block.timestamp <= proposal.createTime + proposal.parameters.warmUpDuration) {
            return ProposalState.WarmUp;
        }

        if (block.timestamp <= proposal.createTime + proposal.parameters.warmUpDuration + proposal.parameters.activeDuration) {
            return ProposalState.Active;
        }

        if ((proposal.forVotes + proposal.againstVotes) < _getQuorum(proposal) ||
            (proposal.forVotes < _getMinForVotes(proposal))) {
            return ProposalState.Failed;
        }

        if (proposal.eta == 0) {
            return ProposalState.Accepted;
        }

        if (block.timestamp < proposal.eta) {
            return ProposalState.Queued;
        }

        if (_proposalAbrogated(proposalId)) {
            return ProposalState.Abrogated;
        }

        if (block.timestamp <= proposal.eta + proposal.parameters.gracePeriodDuration) {
            return ProposalState.Grace;
        }

        return ProposalState.Expired;
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function getProposalParameters(uint256 proposalId) public view returns (ProposalParameters memory) {
        return proposals[proposalId].parameters;
    }

    function getAbrogationProposalReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return abrogationProposals[proposalId].receipts[voter];
    }

    function getActions(uint256 proposalId) public view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getProposalQuorum(uint256 proposalId) public view returns (uint256) {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        return _getQuorum(proposals[proposalId]);
    }

    // ======================================================================================================
    // internal methods
    // ======================================================================================================

    function _canCancelProposal(uint256 proposalId) internal view returns (bool){
        Proposal storage proposal = proposals[proposalId];

        if (msg.sender == proposal.proposer ||
            barn.votingPower(proposal.proposer) < _getCreationThreshold()
        ) {
            return true;
        }

        return false;
    }

    function _isCancellableState(uint256 proposalId) internal view returns (bool) {
        ProposalState s = state(proposalId);

        return s == ProposalState.WarmUp || s == ProposalState.Active;
    }

    function _isLiveState(uint256 proposalId) internal view returns (bool) {
        ProposalState s = state(proposalId);

        return s == ProposalState.WarmUp ||
        s == ProposalState.Active ||
        s == ProposalState.Accepted ||
        s == ProposalState.Queued ||
        s == ProposalState.Grace;
    }

    function _canBeExecuted(uint256 proposalId) internal view returns (bool) {
        return state(proposalId) == ProposalState.Grace;
    }

    function _getMinForVotes(Proposal storage proposal) internal view returns (uint256) {
        return (proposal.forVotes + proposal.againstVotes).mul(proposal.parameters.acceptanceThreshold).div(100);
    }

    function _getCreationThreshold() internal view returns (uint256) {
        return barn.bondStaked().div(100);
    }

    // Returns the timestamp of the snapshot for a given proposal
    // If the current block's timestamp is equal to `proposal.createTime + warmUpDuration` then the state function
    // will return WarmUp as state which will prevent any vote to be cast which will gracefully avoid any flashloan attack
    function _getSnapshotTimestamp(Proposal storage proposal) internal view returns (uint256) {
        return proposal.createTime + proposal.parameters.warmUpDuration;
    }

    function _getQuorum(Proposal storage proposal) internal view returns (uint256) {
        return barn.bondStakedAtTs(_getSnapshotTimestamp(proposal)).mul(proposal.parameters.minQuorum).div(100);
    }

    function _proposalAbrogated(uint256 proposalId) internal view returns (bool) {
        Proposal storage p = proposals[proposalId];
        AbrogationProposal storage cp = abrogationProposals[proposalId];

        if (cp.createTime == 0 || block.timestamp < p.eta) {
            return false;
        }

        return cp.forVotes >= barn.bondStakedAtTs(cp.createTime - 1).div(2);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBarn {
    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    // deposit allows a user to add more bond to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // balanceOf returns the current BOND balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of BOND that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) external view returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) external view returns (Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // bondStaked returns the total raw amount of BOND staked at the current block
    function bondStaked() external view returns (uint256);

    // bondStakedAtTs returns the total raw amount of BOND users have deposited into the contract
    // it does not include any bonus
    function bondStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp) external view returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("ERC20Mock", "MCK") {
    bool public transferFromCalled = false;

    bool public transferCalled = false;
    address public transferRecipient = address(0);
    uint256 public transferAmount = 0;

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        transferFromCalled = true;

        return super.transferFrom(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        transferCalled = true;
        transferRecipient = recipient;
        transferAmount = amount;

        return super.transfer(recipient, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;

import "../interfaces/IBarn.sol";

contract BarnMock {
    uint256 private _bondStaked;
    mapping(address => uint256) private _votingPowerAtTs;
    bool public lockCreatorBalanceHasBeenCalled;
    bool public withdrawHasBeenCalled;

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256){
        return _votingPowerAtTs[user];
    }

    function votingPower(address user) external view returns (uint256) {
        return _votingPowerAtTs[user];
    }

    function bondStaked() external view returns (uint256) {
        return _bondStaked;
    }

    function bondStakedAtTs(uint256 ts) public view returns (uint256) {
        return _bondStaked;
    }

    function setBondStaked(uint256 val) public {
        _bondStaked = val;
    }

    function setVotingPower(address user, uint256 val) public {
        _votingPowerAtTs[user] = val;
    }

    function withdraw(uint256 amount) external {
        withdrawHasBeenCalled = true;
    }
}