// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IKernel.sol";
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
    IKernel kernel;
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
    function initialize(address _kernel) public {
        require(isInitialized == false, "Contract already initialized.");
        require(_kernel != address(0), "kernel must not be 0x0");

        kernel = IKernel(_kernel);
        isInitialized = true;
    }

    function activate() public {
        require(!isActive, "DAO already active");
        require(kernel.leagStaked() >= ACTIVATION_THRESHOLD, "Threshold not met yet");

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
            require(kernel.leagStaked() >= ACTIVATION_THRESHOLD, "DAO not yet active");
            isActive = true;
        }

        require(
            kernel.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThreshold(),
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

        uint256 votes = kernel.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));
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

        uint256 votes = kernel.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));

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
    // accepted and it is currently queued. For the Abrogation Proposal to pass, 50% + 1 of the vLEAG holders
    // must vote FOR the Abrogation Proposal
    function startAbrogationProposal(uint256 proposalId, string memory description) public {
        require(state(proposalId) == ProposalState.Queued, "Proposal must be in queue");
        require(
            kernel.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThreshold(),
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

        uint256 votes = kernel.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);
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

        uint256 votes = kernel.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);

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
            kernel.votingPower(proposal.proposer) < _getCreationThreshold()
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
        return kernel.leagStaked().div(100);
    }

    // Returns the timestamp of the snapshot for a given proposal
    // If the current block's timestamp is equal to `proposal.createTime + warmUpDuration` then the state function
    // will return WarmUp as state which will prevent any vote to be cast which will gracefully avoid any flashloan attack
    function _getSnapshotTimestamp(Proposal storage proposal) internal view returns (uint256) {
        return proposal.createTime + proposal.parameters.warmUpDuration;
    }

    function _getQuorum(Proposal storage proposal) internal view returns (uint256) {
        return kernel.leagStakedAtTs(_getSnapshotTimestamp(proposal)).mul(proposal.parameters.minQuorum).div(100);
    }

    function _proposalAbrogated(uint256 proposalId) internal view returns (bool) {
        Proposal storage p = proposals[proposalId];
        AbrogationProposal storage cp = abrogationProposals[proposalId];

        if (cp.createTime == 0 || block.timestamp < p.eta) {
            return false;
        }

        return cp.forVotes >= kernel.leagStakedAtTs(cp.createTime - 1).div(2);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IKernel {
    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    // deposit allows a user to add more LEAG to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // balanceOf returns the current LEAG balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of LEAG that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) external view returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) external view returns (Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // leagStaked returns the total raw amount of LEAG staked at the current block
    function leagStaked() external view returns (uint256);

    // leagStakedAtTs returns the total raw amount of LEAG users have deposited into the contract
    // it does not include any bonus
    function leagStakedAtTs(uint256 timestamp) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract Parameters {
    uint256 public warmUpDuration = 2 days;
    uint256 public activeDuration = 2 days;
    uint256 public queueDuration = 1 days;
    uint256 public gracePeriodDuration = 4 days;

    uint256 public acceptanceThreshold = 60;
    uint256 public minQuorum = 40;

    uint256 constant ACTIVATION_THRESHOLD = 30_000_000 * 10**18;
    uint256 constant PROPOSAL_MAX_ACTIONS = 10;

    modifier onlyDAO() {
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