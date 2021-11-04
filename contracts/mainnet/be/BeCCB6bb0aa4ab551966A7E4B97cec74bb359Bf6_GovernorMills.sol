pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface InvInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
    function totalSupply() external view returns (uint256);
}

interface XinvInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
    function totalSupply() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint);
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function setDelay(uint256 delay_) external;
    function acceptAdmin() external;
    function setPendingAdmin(address pendingAdmin_) external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes memory);
}

contract GovernorMills {
    /// @notice The name of this contract
    string public constant name = "Inverse Governor Mills";

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 20; } // 20 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

    /// @notice The address of the Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the governance token A
    InvInterface public inv;

    /// @notice The address of the governance token B
    XinvInterface public xinv;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The guardian
    address public guardian;

    /// @notice proposal threshold
    uint256 public proposalThreshold = 1000 ether; // 1k INV

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint256 public quorumVotes = 4000 ether; // 4k INV

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
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

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice Addresses that can propose without voting power
    mapping (address => bool) public proposerWhitelist;

    /// @notice proposal id => xinv.exchangeRateCurrent
    mapping (uint => uint) public xinvExchangeRates;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    /// @notice An event emitted when a new guardian has been set
    event NewGuardian(address guardian);

    /// @notice An event emitted when proposal threshold is updated
    event ProposalThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    /// @notice An event emitted when proposal quorum is updated
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    /// @notice An event emitted when an address is added or removed from the proposer whitelist
    event ProposerWhitelistUpdated(address proposer, bool value);

    constructor(TimelockInterface timelock_, InvInterface inv_, XinvInterface xinv_) public {
        timelock = timelock_;
        inv = inv_;
        xinv = xinv_;
        guardian = msg.sender;
    }

    function _getPriorVotes(address _proposer, uint256 _blockNumber, uint256 _exchangeRate) internal view returns (uint96) {
        uint96 invPriorVotes = inv.getPriorVotes(_proposer, _blockNumber);
        uint96 xinvPriorVotes = uint96(
            (
                uint256(
                    xinv.getPriorVotes(_proposer, _blockNumber)
                ) * _exchangeRate
            ) / 1 ether
        );
        
        return add96(invPriorVotes, xinvPriorVotes);
    }

    function setGuardian(address _newGuardian) public {
        require(msg.sender == guardian, "GovernorMills::setGuardian: only guardian");
        guardian = _newGuardian;
        
        emit NewGuardian(guardian);
    }

    /**
     * @notice Add new pending admin to queue
     * @param newPendingAdmin The new admin
     * @param eta ETA
     */
    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorMills::__queueSetTimelockPendingAdmin: only guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorMills::__executeSetTimelockPendingAdmin: only guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(_getPriorVotes(msg.sender, sub256(block.number, 1), xinv.exchangeRateCurrent()) > proposalThreshold || proposerWhitelist[msg.sender], "GovernorMills::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorMills::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorMills::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorMills::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorMills::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorMills::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;
        xinvExchangeRates[newProposal.id] = xinv.exchangeRateCurrent();
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorMills::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorMills::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public {
        require(state(proposalId) == ProposalState.Queued, "GovernorMills::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "GovernorMills::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || (_getPriorVotes(proposal.proposer, sub256(block.number, 1), xinvExchangeRates[proposal.id]) < proposalThreshold && !proposerWhitelist[proposal.proposer]), "GovernorMills::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Update the threshold value required to create a new proposal.
     * @param newThreshold The new threshold to set.
     */
    function updateProposalThreshold(uint256 newThreshold) public {
        require(msg.sender == guardian || msg.sender == address(timelock), "GovernorMills::updateProposalThreshold: sender must be gov guardian or timelock");
        require(newThreshold <= inv.totalSupply(), "GovernorMills::updateProposalThreshold: threshold too large");
        require(newThreshold != proposalThreshold, "GovernorMills::updateProposalThreshold: no change in value");

        uint256 oldThreshold = proposalThreshold;
        proposalThreshold = newThreshold;

        emit ProposalThresholdUpdated(oldThreshold, newThreshold);
    }

    /**
     * @notice Update the quorum value required to pass a proposal.
     * @param newQuorum The new quorum to set.
     */
    function updateProposalQuorum(uint256 newQuorum) public {
        require(msg.sender == guardian || msg.sender == address(timelock), "GovernorMills::newQuorum: sender must be gov guardian or timelock");
        require(newQuorum <= inv.totalSupply(), "GovernorMills::newQuorum: threshold too large");
        require(newQuorum != quorumVotes, "GovernorMills::newQuorum: no change in value");

        uint256 oldQuorum = quorumVotes;
        quorumVotes = newQuorum;

        emit QuorumUpdated(oldQuorum, newQuorum);
    }

    function acceptAdmin() public {
        require(msg.sender == guardian, "GovernorMills::acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    /**
     * @notice Add or remove an address to the proposerWhitelist
     * @param proposer address to be updated on the whitelist
     * @param value true to add, false to remove
     */
    function updateProposerWhitelist(address proposer, bool value) public {
        require(msg.sender == address(timelock), "GovernorMills::updateProposerWhitelist: sender must be timelock");

        proposerWhitelist[proposer] = value;

        emit ProposerWhitelistUpdated(proposer, value);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorMills::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorMills::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorMills::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorMills::_castVote: voter already voted");
        uint96 votes = _getPriorVotes(voter, proposal.startBlock, xinvExchangeRates[proposal.id]);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function add96(uint96 a, uint96 b) internal pure returns(uint96) {
        uint96 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}