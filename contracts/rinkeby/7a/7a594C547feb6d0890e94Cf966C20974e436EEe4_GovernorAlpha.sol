// SPDX-License-Identifier: MIT;

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./storage/GovernorAlphaStorage.sol";
import "./events/GovernorAlphaEvents.sol";
import "./access/Ownable.sol";

contract GovernorAlpha is GovernorAlphaStorage, GovernorAlphaEvents, Ownable {
    /// @notice The name of this contract
    string public constant name = "Unifarm Governor Alpha";

    /// @notice The minimum proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 25000e18; // 25,000 UNIFARM

    /// @notice The maximum proposal threshold in blocs
    uint256 public constant MAX_PROPOSAL_THRESHOLD = 50000e18; //50,000 UNIFARM

    /// @notice The minimum voting period in blocks
    uint256 public constant MIN_VOTING_PERIOD = 5760; // About 24 hours (assuming 15 seconds each 1 block)

    /// @notice The max voting period
    uint256 public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks (assuming 15 seconds each 1 block)

    /// @notice The min voting delay
    uint256 public constant MIN_VOTING_DELAY = 1; // only 1 block

    /// @notice The max voting delay
    uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week (assuming 15 seconds each 1 block)

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint256 public constant quorumVotes = 100000e18; // 100,000 = 1% of UNIFARM

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions only

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH =
        keccak256("Ballot(uint256 proposalId,uint8 support)");

    constructor() {
        // set the admin to msg.sender
        admin = msg.sender;
    }

    /**
     * @notice Used to initialize the contract during delegator contructor
     * @param _timelock The address of the Timelock
     * @param _unifarm The address of the UNIFARM GOVERNANCE token
     * @param _votingPeriod The initial voting period
     * @param _votingDelay The initial voting delay
     * @param _proposalThreshold The initial proposal threshold
     */
    function initialize(
        address _timelock,
        address _unifarm,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThreshold
    ) external onlyAdmin {
        require(
            address(timelock) == address(0),
            "GovernorAlpha::initialize: can only initialize once"
        );

        require(
            _timelock != address(0),
            "GovernorAlpha::initialize: invalid timelock address"
        );
        require(
            _unifarm != address(0),
            "GovernorAlpha::initialize: invalid unifarm address"
        );
        require(
            _votingPeriod >= MIN_VOTING_PERIOD &&
                _votingPeriod <= MAX_VOTING_PERIOD,
            "GovernorAlpha::initialize: invalid voting period"
        );
        require(
            _votingDelay >= MIN_VOTING_DELAY &&
                _votingDelay <= MAX_VOTING_DELAY,
            "GovernorAlpha::initialize: invalid voting delay"
        );
        require(
            _proposalThreshold >= MIN_PROPOSAL_THRESHOLD &&
                _proposalThreshold <= MAX_PROPOSAL_THRESHOLD,
            "GovernorAlpha::initialize: invalid proposal threshold"
        );

        timelock = Timelock(_timelock);
        unifarm = Unifarm(_unifarm);
        votingPeriod = _votingPeriod;
        votingDelay = _votingDelay;
        proposalThreshold = _proposalThreshold;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            unifarm.getPriorVotes(msg.sender, sub256(block.number, 1)) >
                proposalThreshold,
            "GovernorAlpha::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "GovernorAlpha::propose: invalid purposal information"
        );
        require(targets.length != 0, "GovernorAlpha::propose: invalid actions");
        require(
            targets.length <= proposalMaxOperations,
            "GovernorAlpha::propose: too many actions"
        );

        uint256 latestProposalId = latestProposalIds[msg.sender];

        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState =
                state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "GovernorBravo::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint256 startBlock = add256(block.number, votingDelay);
        uint256 endBlock = add256(startBlock, votingPeriod);

        proposalCount++;

        Proposal memory newProposal =
            Proposal({
                id: proposalCount,
                proposer: msg.sender,
                ETA: 0,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                startBlock: startBlock,
                endBlock: endBlock,
                forVotes: 0,
                againstVotes: 0,
                abstainVotes: 0,
                canceled: false,
                executed: false
            });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return newProposal.id;
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "GovernorAlpha::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <= proposal.againstVotes ||
            proposal.forVotes < quorumVotes
        ) {
            return ProposalState.Defeated;
        } else if (proposal.ETA == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >= add256(proposal.ETA, timelock.GRACE_PERIOD())
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "GovernorAlpha::queue: proposal can only be queued if it is succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = add256(block.timestamp, timelock.delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevert(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.ETA = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !timelock.queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            ),
            "GovernorAlpha::queueOrRevert: identical proposal action already queued at eta"
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external payable {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorAlpha::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.ETA
            );
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
     
    function cancel(uint256 proposalId) external {
        require(
            state(proposalId) != ProposalState.Executed,
            "GovernorAlpha::cancel: cannot cancel executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer ||
                unifarm.getPriorVotes(
                    proposal.proposer,
                    sub256(block.number, 1)
                ) <
                proposalThreshold,
            "GovernorAlpha::cancel: proposer above threshold"
        );

        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.ETA
            );
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage proposalProps = proposals[proposalId];
        return (
            proposalProps.targets,
            proposalProps.values,
            proposalProps.signatures,
            proposalProps.calldatas
        );
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (Receipt memory)
    {
        return receipts[proposalId][voter];
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 proposalId, uint8 support) external {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            _castVote(msg.sender, proposalId, support),
            ""
        );
    }

    /**
     * @notice Cast a vote for a proposal with a reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            _castVote(msg.sender, proposalId, support),
            reason
        );
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     */

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    getChainId(),
                    address(this)
                )
            );
        bytes32 structHash =
            keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "GovernorAlpha::castVoteBySig: invalid signature"
        );
        emit VoteCast(
            signatory,
            proposalId,
            support,
            _castVote(signatory, proposalId, support),
            ""
        );
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function _castVote(
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal returns (uint256) {
        require(
            state(proposalId) == ProposalState.Active,
            "GovernorAlpha::castVoteInternal: voting is closed"
        );
        require(
            support <= 2,
            "GovernorAlpha::castVoteInternal: invalid vote support type"
        );
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[proposalId][voter];
        require(
            receipt.hasVoted == false,
            "GovernorAlpha::castVoteInternal: voter already voted"
        );
        uint256 votes = unifarm.getPriorVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        } else if (support == 1) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else if (support == 2) {
            proposal.abstainVotes = add256(proposal.abstainVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
     * @notice Admin function for setting the voting delay
     * @param newVotingDelay new voting delay, in blocks
     */
    function setVotingDelay(uint256 newVotingDelay) external onlyAdmin {
        require(
            newVotingDelay >= MIN_VOTING_DELAY &&
                newVotingDelay <= MAX_VOTING_DELAY,
            "GovernorAlpha:: setVotingDelay: invalid voting delay"
        );

        uint256 oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param newVotingPeriod new voting period, in blocks
     */
    function setVotingPeriod(uint256 newVotingPeriod) external onlyAdmin {
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD &&
                newVotingPeriod <= MAX_VOTING_PERIOD,
            "GovernorAlpha::setVotingPeriod: invalid voting period"
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold
     * @dev newProposalThreshold must be greater than the hardcoded min
     * @param newProposalThreshold new proposal threshold
     */
    function setProposalThreshold(uint256 newProposalThreshold)
        external
        onlyAdmin
    {
        require(
            newProposalThreshold >= MIN_PROPOSAL_THRESHOLD &&
                newProposalThreshold <= MAX_PROPOSAL_THRESHOLD,
            "GovernorAlpha:: setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT;
pragma solidity ^0.7.6;

import "../interfaces/Timelock.sol";
import "../interfaces/Unifarm.sol";

contract GovernorAlphaStorage {
    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The number of votes required in order for a voter to become a proposer
    uint256 public proposalThreshold;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The address of the UNIFARM Protocol Timelock
    Timelock public timelock;

    /// @notice The address of the UNIFARM Governance Token
    Unifarm public unifarm;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 ETA;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
    }

    mapping(uint256 => mapping(address => Receipt)) receipts;

    /// @notice Ballot receipt record for a voter

    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
}

// SPDX-License-Identifier: MIT;
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract GovernorAlphaEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when proposal threshold is set
    event ProposalThresholdSet(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );
}

// SPDX-License-Identifier: MIT;

pragma solidity >=0.6.0 <=0.8.0;

abstract contract Ownable {
    address public admin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        admin = msg.sender;
        emit OwnershipTransferred(address(0), admin);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(admin == msg.sender, "Ownable: caller is not the Admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyAdmin {
        admin = address(0);
        emit OwnershipTransferred(admin, address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newAdmin) public virtual onlyAdmin {
        require(
            newAdmin != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity ^0.7.6;

interface Timelock {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT;
pragma solidity ^0.7.6;

interface Unifarm {
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}