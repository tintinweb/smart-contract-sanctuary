/**
 *Submitted for verification at arbiscan.io on 2022-01-20
*/

pragma solidity 0.5.16;
//pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 0 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) public {   
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    function() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }
}

// contract GovernorAlpha {

//     string public constant name = "Compound Governor Alpha";

//     function quorumVotes() public pure returns (uint) { return 4000000e18; }

//     function proposalThreshold() public pure returns (uint) { return 50000e18; } 

//     function proposalMaxOperations() public pure returns (uint) { return 10; }

//     uint public votingDelay;

//     uint public votingPeriod; 

//     TimelockInterface public timelock;

//     CompInterface public comp;

//     address public guardian;

//     uint public proposalCount;

//     struct Proposal {
//         uint id;

//         address proposer;

//         uint eta;

//         address[] targets;

//         uint[] values;

//         string[] signatures;

//         bytes[] calldatas;

//         uint startBlock;

//         uint endBlock;

//         uint forVotes;

//         uint againstVotes;

//         bool canceled;

//         bool executed;

//         mapping (address => Receipt) receipts;
//     }

//     struct Receipt {
//         bool hasVoted;

//         bool support;

//         uint96 votes;
//     }

//     enum ProposalState {
//         Pending,
//         Active,
//         Canceled,
//         Defeated,
//         Succeeded,
//         Queued,
//         Expired,
//         Executed
//     }

//     mapping (uint => Proposal) public proposals;

//     mapping (address => uint) public latestProposalIds;

//     bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

//     bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

//     event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

//     event VoteCast(address voter, uint proposalId, bool support, uint votes);

//     event ProposalCanceled(uint id);

//     event ProposalQueued(uint id, uint eta);

//     event ProposalExecuted(uint id);

//     constructor(address timelock_, address comp_, address guardian_, uint votingPeriod_, uint votingDelay_) public {
//         timelock = TimelockInterface(timelock_);
//         comp = CompInterface(comp_);
//         guardian = guardian_;
//         votingPeriod = votingPeriod_;
//         votingDelay = votingDelay_;
//     }

//     function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
//         require(comp.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
//         require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
//         require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
//         require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

//         uint latestProposalId = latestProposalIds[msg.sender];
//         if (latestProposalId != 0) {
//           ProposalState proposersLatestProposalState = state(latestProposalId);
//           require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
//           require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
//         }

//         uint startBlock = add256(block.number, votingDelay);
//         uint endBlock = add256(startBlock, votingPeriod);

//         proposalCount++;
//         Proposal memory newProposal = Proposal({
//             id: proposalCount,
//             proposer: msg.sender,
//             eta: 0,
//             targets: targets,
//             values: values,
//             signatures: signatures,
//             calldatas: calldatas,
//             startBlock: startBlock,
//             endBlock: endBlock,
//             forVotes: 0,
//             againstVotes: 0,
//             canceled: false,
//             executed: false
//         });

//         proposals[newProposal.id] = newProposal;
//         latestProposalIds[newProposal.proposer] = newProposal.id;

//         emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
//         return newProposal.id;
//     }

//     function queue(uint proposalId) public {
//         require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
//         Proposal storage proposal = proposals[proposalId];
//         uint eta = add256(block.timestamp, timelock.delay());
//         for (uint i = 0; i < proposal.targets.length; i++) {
//             _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
//         }
//         proposal.eta = eta;
//         emit ProposalQueued(proposalId, eta);
//     }

//     function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
//         require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
//         timelock.queueTransaction(target, value, signature, data, eta);
//     }

//     function execute(uint proposalId) public payable {
//         require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
//         Proposal storage proposal = proposals[proposalId];
//         proposal.executed = true;
//         for (uint i = 0; i < proposal.targets.length; i++) {
//             timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
//         }
//         emit ProposalExecuted(proposalId);
//     }

//     function cancel(uint proposalId) public {
//         ProposalState state = state(proposalId);
//         require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

//         Proposal storage proposal = proposals[proposalId];
//         require(msg.sender == guardian || comp.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "GovernorAlpha::cancel: proposer above threshold");

//         proposal.canceled = true;
//         for (uint i = 0; i < proposal.targets.length; i++) {
//             timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
//         }

//         emit ProposalCanceled(proposalId);
//     }

//     function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
//         Proposal storage p = proposals[proposalId];
//         return (p.targets, p.values, p.signatures, p.calldatas);
//     }

//     function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
//         return proposals[proposalId].receipts[voter];
//     }

//     function state(uint proposalId) public view returns (ProposalState) {
//         require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
//         Proposal storage proposal = proposals[proposalId];
//         if (proposal.canceled) {
//             return ProposalState.Canceled;
//         } else if (block.number <= proposal.startBlock) {
//             return ProposalState.Pending;
//         } else if (block.number <= proposal.endBlock) {
//             return ProposalState.Active;
//         } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
//             return ProposalState.Defeated;
//         } else if (proposal.eta == 0) {
//             return ProposalState.Succeeded;
//         } else if (proposal.executed) {
//             return ProposalState.Executed;
//         } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
//             return ProposalState.Expired;
//         } else {
//             return ProposalState.Queued;
//         }
//     }

//     function castVote(uint proposalId, bool support) public {
//         return _castVote(msg.sender, proposalId, support);
//     }

//     function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
//         bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
//         bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
//         bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
//         address signatory = ecrecover(digest, v, r, s);
//         require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
//         return _castVote(signatory, proposalId, support);
//     }

//     function _castVote(address voter, uint proposalId, bool support) internal {
//         require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
//         Proposal storage proposal = proposals[proposalId];
//         Receipt storage receipt = proposal.receipts[voter];
//         require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
//         uint96 votes = comp.getPriorVotes(voter, proposal.startBlock);

//         if (support) {
//             proposal.forVotes = add256(proposal.forVotes, votes);
//         } else {
//             proposal.againstVotes = add256(proposal.againstVotes, votes);
//         }

//         receipt.hasVoted = true;
//         receipt.support = support;
//         receipt.votes = votes;

//         emit VoteCast(voter, proposalId, support, votes);
//     }

//     function __acceptAdmin() public {
//         require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
//         timelock.acceptAdmin();
//     }

//     function __abdicate() public {
//         require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
//         guardian = address(0);
//     }

//     function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
//         require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
//         timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
//     }

//     function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
//         require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
//         timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
//     }

//     function add256(uint256 a, uint256 b) internal pure returns (uint) {
//         uint c = a + b;
//         require(c >= a, "addition overflow");
//         return c;
//     }

//     function sub256(uint256 a, uint256 b) internal pure returns (uint) {
//         require(b <= a, "subtraction underflow");
//         return a - b;
//     }

//     function getChainId() internal pure returns (uint) {
//         uint chainId;
//         assembly { chainId := chainid() }
//         return chainId;
//     }
// }

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface CompInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}


contract Forwarder
{
    address public owner;

    constructor(address _owner)
        public
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only owner");
        _;
    }

    event OwnerChanged(address _newOwner);
    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    event Forwarded(
        address indexed _to,
        bytes _data,
        uint _wei,
        bool _success,
        bytes _resultData);
    function forward(address _to, bytes memory _data, uint _wei)
        public
        onlyOwner
        returns (bool, bytes memory)
    {
        (bool success, bytes memory resultData) = _to.call.value(_wei)(_data);
        emit Forwarded(_to, _data, _wei, success, resultData);
        return (success, resultData);
    }

    function ()
        external
        payable
    { }
}


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

contract Comp {
   
    string public constant name = "Compound";

    string public constant symbol = "COMP";

    uint8 public constant decimals = 18;

    uint public constant totalSupply = 10000000e18;

    mapping (address => mapping (address => uint96)) internal allowances;

    mapping (address => uint96) internal balances;

    mapping (address => address) public delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed _delegate, uint _previousBalance, uint _newBalance);

    event Transfer(address indexed from, address indexed _to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address account) public {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Comp::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Comp::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Comp::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Comp::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Comp::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Comp::delegateBySig: invalid nonce");
        require(now <= expiry, "Comp::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Comp::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
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

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Comp::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Comp::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Comp::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Comp::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Comp::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Comp::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Comp::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract gFRY is Comp 
{
    address public governator;
    string public constant name = "Governance FRY";
    string public constant symbol = "gFRY";
    uint public totalSupply  = 10000000e18;

    constructor() 
        public 
        Comp(msg.sender)
    {
        governator = msg.sender;
        burn(balances[msg.sender]);
        require(totalSupply == 0, "no tokens should exist"); 
    }

    function mint(address _to, uint96 _amount) 
        public 
    {
        require(msg.sender == governator, "Comp::_mint: That account cannot mint");
        require(_to != address(0), "Comp::_mint: cannot mint to the zero address");
        
        balances[_to] = add96(balances[_to], _amount, "Comp::_mint: user balance overflows");
        totalSupply = add96(uint96(totalSupply), _amount, "Comp::_mint: totalSupply overflows");
        emit Transfer(address(0x0), _to, _amount);

        _moveDelegates(delegates[address(0x0)], delegates[_to], _amount);
    }

    function burn(uint96 _amount) 
        public 
    {
        require(msg.sender != address(0), "Comp::_burn: cannot burn from the zero address");

        balances[msg.sender] = sub96(balances[msg.sender], _amount, "Comp::_burn: burn underflows");
        totalSupply = sub96(uint96(totalSupply), _amount, "Comp::_burn: totalSupply underflows");
        
        emit Transfer(msg.sender, address(0), _amount);

        _moveDelegates(delegates[msg.sender], delegates[address(0)], _amount);
    }

    function transferFrom(address _src, address _dst, uint _rawAmount) 
        external 
        returns (bool) 
    {
        address spender = msg.sender;
        uint96 spenderAllowance = msg.sender == governator ? uint96(-1) : allowances[_src][spender];
        uint96 amount = safe96(_rawAmount, "Comp::approve: amount exceeds 96 bits");

        if (spender != _src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Comp::transferFrom: transfer amount exceeds spender allowance");
            allowances[_src][spender] = newAllowance;

            emit Approval(_src, spender, newAllowance);
        }

        _transferTokens(_src, _dst, amount);
        return true;
    }
}

contract Governator
{
    using SafeMath for uint;

    IERC20 public FRY;
    gFRY public gFry;

    constructor(IERC20 _FRY) 
        public 
    {
        gFry = new gFRY();
        FRY = _FRY;
    }

    function governate(uint _amount) 
        public 
    {
        FRY.transferFrom(msg.sender, address(this), _amount);
        gFry.mint(msg.sender, safe96(_amount, "Governator: uint96 overflows"));
    }

    function degovernate(uint _amount)
        public
    {
        uint share = _amount.mul(10**18).div(gFry.totalSupply());

        uint fryToReturn = FRY.balanceOf(address(this))
            .mul(share)
            .div(10**18);

        gFry.transferFrom(msg.sender, address(this), _amount);

        gFry.burn(safe96(_amount, "Governator: uint96 overflows"));

        FRY.transfer(msg.sender, fryToReturn);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
}

contract GovernanceDeployer {

	event Deployed(address _timelockAddress, address _forwarderAddress, address _governatorAddress, address _gFryAddress, address _governorAlphaAddress);
    
    constructor() 
        public 
    {
        uint fourTwenty = 420;
        address _guardian = 0x7E1d0353063F01CfFa92f4a9C8A100cFE37d8264;
        IERC20 _FRY = IERC20(0x0c03Cbda17a4FbdA5F95aB0787c2A242DC14313e);
        uint _votingPeriod = 5;
        uint _votingDelay = 5;

        // Timelock timelock = new Timelock(address(this), 0);
        // Forwarder forwarder = new Forwarder(address(timelock));
        // Governator governator = new Governator(_FRY);
        // gFRY gFry = governator.gFry();
		// GovernorAlpha governorAlpha = new GovernorAlpha(address(timelock), address(gFry), _guardian, _votingPeriod, _votingDelay);
        
		// emit Deployed(address(timelock), address(forwarder), address(governator), address(gFry), address(governorAlpha));
        
        // bytes memory adminPayload = abi.encodeWithSignature("setPendingAdmin(address)", address(governorAlpha));
        
        // uint256 eta = block.timestamp + timelock.delay(); 
        // timelock.queueTransaction(address(timelock), 0, "", adminPayload, eta);
        
        // bytes memory delayPayload = abi.encodeWithSignature("setDelay(uint256)", 2 );
        
        // timelock.queueTransaction(address(timelock), 0, "", delayPayload, eta);
        
        // timelock.executeTransaction(address(timelock), 0, "", adminPayload, eta);
        // timelock.executeTransaction(address(timelock), 0, "", delayPayload, eta);
         
     }
}