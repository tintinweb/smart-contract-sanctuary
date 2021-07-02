/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.7.6;
pragma abicoder v2;

interface VoteInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

contract Governor {
    /// @notice The name of this contract
    string public constant name = "MRCH Governor";

    /// @notice Governance token with Vote Interface
    address public token;

    uint public threshold = 15_000_000e18; // 15M votes
    uint public quorum = 150_000_000e18; // 150M votes
    uint public delay = 1; // 1 block
    uint public period = 19710; // ~3 days in blocks (assuming 15s blocks)

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return quorum; }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view returns (uint) { return threshold; }

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public view returns (uint) { return delay; }

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public view virtual returns (uint) { return period; }

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice id Unique id for looking up a proposal
    /// @notice proposer Creator of the proposal
    /// @notice ipfsLinks The links for IPFS
    /// @notice startBlock The block at which voting begins: holders must delegate their votes prior to this block
    /// @notice endBlock The block at which voting ends: votes must be cast prior to this block
    /// @notice forVotes Current number of votes in favor of this proposal
    /// @notice againstVotes Current number of votes in opposition to this proposal
    /// @notice canceled Flag marking whether the proposal has been canceled
    /// @notice executed Flag marking whether the proposal has been executed
    /// @notice receipts Receipts of ballots for the entire set of voters

    struct Proposal {
        uint id;
        address proposer;
        string[] ipfsLinks;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    /// @notice hasVoted Whether or not a vote has been cast
    /// @notice support Whether or not the voter supports the proposal
    /// @notice votes The number of votes the voter had, which were cast

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        string[] ipfsLinks,
        uint startBlock,
        uint endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    event NewQuorum(uint indexed newQuorum);
    event NewThreshold(uint indexed newThreshold);
    event NewVotingDelay(uint indexed newVotingDelay);
    event NewVotingPeriod(uint indexed newVotingPeriod);
    event NewVotingToken(address newVotingToken);

    constructor(address token_, address guardian_) {
        token = token_;
        guardian = guardian_;
    }

    function propose(
        string[] memory ipfsLinks,
        string memory description
    ) public returns (uint) {
        require(VoteInterface(token).getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.ipfsLinks = ipfsLinks;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, ipfsLinks, startBlock, endBlock, description);

        return newProposal.id;
    }

    function cancel(uint proposalId) public {
        ProposalState state_ = state(proposalId);
        require(state_ != ProposalState.Executed, "Governor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || VoteInterface(token).getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "Governor::cancel: proposer above threshold");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    function getIpfsLinks(
        uint proposalId
    ) public view returns (
        string[] memory ipfsLinks
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.ipfsLinks);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function getForVotes(uint proposalId) public view returns (uint) {
        return proposals[proposalId].forVotes;
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else {
            return ProposalState.Succeeded;
        }
    }

    function castVote(uint proposalId, bool support) public {
        _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint96 votes = VoteInterface(token).getPriorVotes(voter, proposal.startBlock);

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

    function setQuorum(uint newQuorum) external {
        require(msg.sender == guardian, "Governor::setQuorum: sender must be gov guardian");
        quorum = newQuorum;

        emit NewQuorum(newQuorum);
    }

    function setThreshold(uint newThreshold) external {
        require(msg.sender == guardian, "Governor::setThreshold: sender must be gov guardian");
        threshold = newThreshold;

        emit NewThreshold(newThreshold);
    }

    function setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == guardian, "Governor::setVotingDelay: sender must be gov guardian");
        delay = newVotingDelay;

        emit NewVotingDelay(newVotingDelay);
    }

    function setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == guardian, "Governor::setVotingPeriod: sender must be gov guardian");
        period = newVotingPeriod;

        emit NewVotingPeriod(newVotingPeriod);
    }

    function setVotingToken(address newVotingToken) external {
        require(msg.sender == guardian, "Governor::setVotingToken: sender must be gov guardian");
        token = newVotingToken;

        emit NewVotingToken(newVotingToken);
    }

    function __abdicate() public {
        require(msg.sender == guardian, "Governor::__abdicate: sender must be gov guardian");
        guardian = address(0);
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