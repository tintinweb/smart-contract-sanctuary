/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

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

interface IGNBU is IBEP20 {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
    function freeCirculation() external view returns (uint96);
}

interface INimbusStakingPool {
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns (IBEP20);
}

contract NimbusGovernorV1 {
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

    string public constant name = "Nimbus Governor v1";
    uint public constant proposalMaxOperations = 10; // 10 actions
    uint public constant votingDelay = 1; // 1 block
    uint public constant votingPeriod = 80_640; // ~14 days in blocks (assuming 15s blocks)

    uint96 public quorumPercentage = 4000; // 40% from GNBU free circulation, changeable by voting
    uint96 public participationThresholdPercentage = 100; // 1% from GNBU free circulation, changeable by voting
    uint96 public proposalStakeThresholdPercentage = 10; // 0.1% from GNBU free circulation, changeable by voting
    uint96 public maxVoteWeightPercentage = 1000; // 10% from GNBU free circulation, changeable by voting
    IGNBU public immutable GNBU;
    uint public proposalCount;
    INimbusStakingPool[] public stakingPools; 

    mapping (uint => Proposal) public proposals;
    mapping (address => uint) public latestProposalIds;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    event ProposalCreated(uint indexed id, address indexed proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);
    event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);
    event ProposalCanceled(uint indexed id);
    event ProposalExecuted(uint indexed id);
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);

    constructor(address gnbu, address[] memory pools) {
        GNBU = IGNBU(gnbu);
        for (uint i = 0; i < pools.length; i++) {
            stakingPools.push(INimbusStakingPool(pools[i]));
        }
    }

    receive() payable external {
        revert();
    }

    function quorumVotes() public view returns (uint) { 
        return GNBU.freeCirculation() * quorumPercentage / 10000;
    }

    function participationThreshold() public view returns (uint) { 
        return GNBU.freeCirculation() * participationThresholdPercentage / 10000;
    } 

    function proposalStakeThreshold() public view returns (uint) {
        return GNBU.freeCirculation() * proposalStakeThresholdPercentage / 10000;
    }

    function maxVoteWeight() public view returns (uint96) {
        return GNBU.freeCirculation() * maxVoteWeightPercentage / 10000;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint) {
        require(GNBU.getPriorVotes(msg.sender, sub256(block.number, 1)) > participationThreshold(), "NimbusGovernorV1::propose: proposer votes below participation threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "NimbusGovernorV1::propose: proposal function information arity mismatch");
        require(targets.length != 0, "NimbusGovernorV1::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "NimbusGovernorV1::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "NimbusGovernorV1::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "NimbusGovernorV1::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint stakedAmount;
        for (uint i = 0; i < stakingPools.length; i++) {
            stakedAmount = add256(stakedAmount, stakingPools[i].balanceOf(msg.sender));
        }
        require(stakedAmount >= proposalStakeThreshold());

        uint startBlock = add256(block.number, votingDelay);
        uint endBlock = add256(startBlock, votingPeriod);

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

        latestProposalIds[msg.sender] = id;

        emit ProposalCreated(id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return id;
    }

    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Succeeded, "NimbusGovernorV1::execute: proposal can only be executed if it is succeeded");

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
            require(success, "NimbusGovernorV1::executeTransaction: Transaction execution reverted.");

            emit ExecuteTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) external {
        ProposalState proposalState = state(proposalId);
        require(proposalState != ProposalState.Executed, "NimbusGovernorV1::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(GNBU.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < participationThreshold(), "NimbusGovernorV1::cancel: proposer above threshold");

        uint stakedAmount;
        for (uint i = 0; i < stakingPools.length; i++) {
            stakedAmount = add256(stakedAmount, stakingPools[i].balanceOf(proposal.proposer));
        }
        require(stakedAmount < proposalStakeThreshold(), "NimbusGovernorV1::cancel: proposer above threshold");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "NimbusGovernorV1::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
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
        require(signatory != address(0), "NimbusGovernorV1::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "NimbusGovernorV1::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "NimbusGovernorV1::_castVote: voter already voted");
        uint96 votes = GNBU.getPriorVotes(voter, proposal.startBlock);
        require(votes > participationThreshold(), "NimbusGovernorV1::_castVote: voter votes below participation threshold");

        uint96 maxWeight = maxVoteWeight();
        if (votes > maxWeight) votes = maxWeight;

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

    function updateStakingPoolAdd(address newStakingPool) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateStakingPoolAdd: Call must come from Governor");
        INimbusStakingPool pool = INimbusStakingPool(newStakingPool);
        require (pool.stakingToken() == GNBU, "NimbusGovernorV1::updateStakingPoolAdd: Wrong pool staking tokens");

        for (uint i; i < stakingPools.length; i++) {
            require (address(stakingPools[i]) != newStakingPool, "NimbusGovernorV1::updateStakingPoolAdd: Pool exists");
        }
        stakingPools.push(pool);
    }

    function updateStakingPoolRemove(uint poolIndex) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateStakingPoolRemove: Call must come from Governor");
        stakingPools[poolIndex] = stakingPools[stakingPools.length - 1];
        stakingPools.pop();
    }

    function updateQuorumPercentage(uint96 newQuorumPercentage) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateQuorumPercentage: Call must come from Governor");
        quorumPercentage = newQuorumPercentage;
    }

    function updateParticipationThresholdPercentage(uint96 newParticipationThresholdPercentage) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateParticipationThresholdPercentage: Call must come from Governor");
        participationThresholdPercentage = newParticipationThresholdPercentage;
    }

    function updateProposalStakeThresholdPercentage(uint96 newProposalStakeThresholdPercentage) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateProposalStakeThresholdPercentage: Call must come from Governor");
        proposalStakeThresholdPercentage = newProposalStakeThresholdPercentage;
    }

    function updateMaxVoteWeightPercentage(uint96 newMaxVoteWeightPercentage) external {
        require(msg.sender == address(this), "NimbusGovernorV1::updateMaxVoteWeightPercentage: Call must come from Governor");
        maxVoteWeightPercentage = newMaxVoteWeightPercentage;
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