/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

//SPDX-License-Identifier: None
pragma solidity =0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract FlareXGovernorYFLR_V1 {
    using SafeMath for uint;

    struct Checkpoint {
        uint fromBlock;
        uint votes;
    }

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
        string description;
        mapping (address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    string public constant name = "Flare Governor YFLR V1";
    IERC20 public immutable YFLR;

    uint public quorumPercentage;
    uint public proposalThreshold;
    //uint public accelerationThreshold;
    uint public constant proposalMaxOperations = 10;
    uint public constant votingDelay = 1;
    uint public constant votingPeriod = 240; //~7 days in blocks (assuming 15s blocks)
    uint public shortenedPeriod = 20; //~3 days in blocks (assuming 15s blocks)

    uint public proposalCount;
    uint public totalSupply;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (uint => Checkpoint)) public checkpoints;
    mapping (address => uint) public numCheckpoints;
    mapping (uint => Proposal) public proposals;
    mapping (address => uint) public latestProposalIds;

    //bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    //bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    event StakeVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);
    event ProposalAccelerated(uint id, uint newEndBlock);
    event VoteCast(address voter, uint proposalId, bool support, uint votes);
    event ProposalCanceled(uint id);
    event ProposalExecuted(uint id);
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);


    constructor(address yflr) {
        YFLR = IERC20(yflr);
        quorumPercentage = 10;
        proposalThreshold = 100_000e18;
        //accelerationThreshold = 2_000_000 * 10 ** 18;
    }

    function getCurrentVotes(address account) external view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "FlareXGovernorYFLR_V1: not yet determined");

        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function stake(uint amount) external {
        require(amount > 0, "FlareXGovernorYFLR_V1: amount is zero");
        _stake(amount);
    }

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(amount > 0, "LockStakingRewardFixedAPY: Cannot stake 0");
        // permit
        IERC20Permit(address(YFLR)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount);
    }

    function _stake(uint amount) private {
        YFLR.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        
        uint dstRepNum = numCheckpoints[msg.sender];
        uint dstRepOld = dstRepNum > 0 ? checkpoints[msg.sender][dstRepNum - 1].votes : 0;
        uint dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(msg.sender, dstRepNum, dstRepOld, dstRepNew);
    }


    
    function withdraw(uint amount, address recipient) external {
        require(amount > 0, "FlareXGovernorYFLR_V1: amount is zero");
        YFLR.transfer(recipient, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        
        uint srcRepNum = numCheckpoints[msg.sender];
        uint srcRepOld = srcRepNum > 0 ? checkpoints[msg.sender][srcRepNum - 1].votes : 0;
        uint srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(msg.sender, srcRepNum, srcRepOld, srcRepNew);
    }

    function _writeCheckpoint(address user, uint nCheckpoints, uint oldVotes, uint newVotes) internal {
      uint blockNumber = block.number;

      if (nCheckpoints > 0 && checkpoints[user][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[user][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[user][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[user] = nCheckpoints + 1;
      }

      emit StakeVotesChanged(user, oldVotes, newVotes);
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(getPriorVotes(msg.sender, block.number - 1) > proposalThreshold, "FlareXGovernorYFLR_V1: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "FlareXGovernorYFLR_V1: proposal function information arity mismatch");
        require(targets.length != 0, "FlareXGovernorYFLR_V1: must provide actions");
        require(targets.length <= proposalMaxOperations, "FlareXGovernorYFLR_V1: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "FlareXGovernorYFLR_V1: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "FlareXGovernorYFLR_V1: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = block.number + votingDelay;
        uint endBlock = startBlock + votingPeriod;
        
        uint id = ++proposalCount;

        proposals[id].id = id;
        proposals[id].proposer = msg.sender;
        proposals[id].targets = targets;
        proposals[id].values = values;
        proposals[id].signatures = signatures;
        proposals[id].calldatas = calldatas;
        proposals[id].startBlock = startBlock;
        proposals[id].endBlock = endBlock;
        proposals[id].quorumVotes = totalSupply * quorumPercentage / 100;
        proposals[id].description = description;

        latestProposalIds[msg.sender] = id;

        emit ProposalCreated(id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return id;
    }

    function accelerate(uint proposalId) external { 
        require(state(proposalId) == ProposalState.Active, "FlareGovernorV1: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.forVotes > proposal.quorumVotes || proposal.againstVotes > proposal.quorumVotes, "FlareGovernorV1: acceleration threshold is not met");
        require(proposal.endBlock > block.number + shortenedPeriod, "FlareGovernorV1: remaining voting time is less than shortened period");
        uint newEndBlock = block.number + shortenedPeriod;
        proposal.endBlock = newEndBlock;
        emit ProposalAccelerated(proposalId, newEndBlock);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Succeeded, "FlareXGovernorYFLR_V1: proposal can only be executed if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            bytes memory callData;

            if (bytes(proposal.signatures[i]).length == 0) {
                callData = proposal.calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            }

            (bool success, ) = proposal.targets[i].call{value :proposal.values[i]}(callData);
            require(success, "FlareXGovernorYFLR_V1: Transaction execution reverted.");

            emit ExecuteTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState proposalState = state(proposalId);
        require(proposalState != ProposalState.Executed, "FlareXGovernorYFLR_V1: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold, "FlareXGovernorYFLR_V1: proposer above threshold");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function castVote(uint proposalId, bool support) external {
        require(state(proposalId) == ProposalState.Active, "FlareXGovernorYFLR_V1: voting is closed");
        address voter = msg.sender;
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "FlareXGovernorYFLR_V1: voter already voted");
        uint votes = getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }




    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "FlareXGovernorYFLR_V1: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) { 
            return ProposalState.Defeated;
        } else if (!proposal.executed) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } 
    }

    function isAccelerateable(uint proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.forVotes <= proposal.quorumVotes || proposal.againstVotes <= proposal.quorumVotes) return false;
        return proposal.endBlock > block.number + shortenedPeriod;
    }




    function updateProposalThreshold(uint newProposalThreshold) external {
        require(msg.sender == address(this), "FlareXGovernorYFLR_V1: Call must come from Governor");
        proposalThreshold = newProposalThreshold;
    }

    // function updateAccelerationThreshold(uint newAccelerationThreshold) external {
    //     require(msg.sender == address(this), "FlareXGovernorYFLR_V1: Call must come from Governor");
    //     accelerationThreshold = newAccelerationThreshold;
    // }    

    function updateShortenedPeriod(uint newShortenedPeriod) external {
        require(msg.sender == address(this), "FlareXGovernorYFLR_V1: Call must come from Governor");
        shortenedPeriod = newShortenedPeriod;
    }

    function updatQuorumPercentage(uint newQuorumPercentage) external {
        require(msg.sender == address(this), "FlareXGovernorYFLR_V1: Call must come from Governor");
        quorumPercentage = newQuorumPercentage;
    }
}