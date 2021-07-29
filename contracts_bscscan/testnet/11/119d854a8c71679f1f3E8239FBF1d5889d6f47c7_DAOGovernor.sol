/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ICONS is IBEP20 {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
    function freeCirculation() external view returns (uint96);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract DAOGovernor is Ownable {
    struct Proposal {
        uint id;
        address proposer;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        uint quorumVotes;
        uint minVoters;
        uint voters;
        string description;
        mapping (address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }


    string public constant name = "DAO Governor";
    uint public constant proposalMaxOperations = 10; // 10 actions
    uint public constant votingDelay = 1; // 1 block

    ICONS public immutable CONS;
    uint public proposalCount;

    mapping (uint => Proposal) public proposals;
    mapping (address => bool) public lowerAdmins;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    event ProposalCreated(uint indexed id, address indexed proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);
    event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);
    event ProposalCanceled(uint indexed id);
    event ProposalExecuted(uint indexed id);
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);
    event UpdateLowerAdmin(address indexed newAdmin, bool indexed isAllowed);

    constructor(address cons) {
        CONS = ICONS(cons);
    }

    receive() payable external {
        revert();
    }

    modifier onlyOwnerOrLowerAdmin {
        require(msg.sender == owner || lowerAdmins[msg.sender], "Ownable: Caller is not the owner");
        _;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, uint endBlock, uint quorumVotes, uint minVoters) external onlyOwnerOrLowerAdmin returns (uint) {
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "DAOGovernor::propose: proposal function information arity mismatch");
        require(targets.length != 0, "DAOGovernor::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "DAOGovernor::propose: too many actions");

        uint startBlock = add256(block.number, votingDelay);

        proposalCount++;
        
        uint id = proposalCount;

        proposals[id].id = id;
        proposals[id].proposer = msg.sender;
        proposals[id].targets = targets;
        proposals[id].values = values;
        proposals[id].signatures = signatures;
        proposals[id].calldatas = calldatas;
        proposals[id].startBlock = startBlock;
        proposals[id].endBlock = endBlock;
        proposals[id].quorumVotes = quorumVotes;
        proposals[id].minVoters = minVoters;
        proposals[id].description = description;

        emit ProposalCreated(id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return id;
    }

    function execute(uint proposalId) external payable onlyOwnerOrLowerAdmin {
        require(state(proposalId) == ProposalState.Succeeded, "DAOGovernor::execute: proposal can only be executed if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            bytes memory callData;

            if (bytes(proposal.signatures[i]).length == 0) {
                callData = proposal.calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            }

            (bool success, bytes memory returnData) = proposal.targets[i].call{value :proposal.values[i]}(callData);
            require(success, "DAOGovernor::executeTransaction: Transaction execution reverted.");

            emit ExecuteTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) external onlyOwnerOrLowerAdmin {
        proposals[proposalId].canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function updateDescription(uint proposalId, string memory description) external onlyOwnerOrLowerAdmin { 
        require(state(proposalId) == ProposalState.Active, "DAOGovernor::updateDescription: proposal is not active");
        proposals[proposalId].description = description;
    }

    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "DAOGovernor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes || proposal.voters < proposal.minVoters) {
            return ProposalState.Defeated;
        } else if (!proposal.executed) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Executed;
        }
    }

    function castVote(uint proposalId, bool support) external {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DAOGovernor::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function updateLowerAdmin(address newAdmin, bool isAllowed) external onlyOwner {
        require(newAdmin != address(0), "DAOGovernor::updateLowerAdmin: zero address");
        lowerAdmins[newAdmin] = isAllowed;
        emit UpdateLowerAdmin(newAdmin, isAllowed);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "DAOGovernor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "DAOGovernor::_castVote: voter already voted");
        uint96 votes = CONS.getPriorVotes(voter, proposal.startBlock);

        require(votes > 0, "DAOGovernor::_castVote: no delegate votes for proposal start time");
        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        proposal.voters++;

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
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

    function getChainId() internal view returns (uint) {
        return block.chainid;
    }
}