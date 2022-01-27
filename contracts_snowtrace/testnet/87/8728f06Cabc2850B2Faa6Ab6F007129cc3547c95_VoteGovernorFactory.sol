/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-26
*/

// File contracts/VoteTimelock.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract VoteTimelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    fallback() external payable {}

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
        require(eta >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

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

    function executeTransaction(address target, uint _value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, _value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: _value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, _value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}


// File contracts/VoteGovernorAlpha.sol

pragma solidity ^0.8.2;

contract VoteGovernorAlpha {
    // @notice The name of this contract
    string private name;
    uint256 private votingDelay;
    uint256 private votingPeriod;
    uint256 private proposalThreshold;
    uint256 private votingThreshold;

    function getName() public view returns (string memory) {
        return name;
    }

    // @notice The number of votes required in order for a voter to become a proposer
    function getProposalThreshold() public view returns (uint256) { return proposalThreshold; }

    // @notice The number of votes required in order for a voter to vote on a proposal
    function getVotingThreshold() public view returns (uint256) { return votingThreshold; }

    // @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    // @notice The delay before voting on a proposal may take place, once proposed
    function getVotingDelay() public view returns (uint256) { return votingDelay; }

    // @notice The duration of voting on a proposal, in blocks
    function getVotingPeriod() public view returns (uint256) { return votingPeriod; }

    // @notice The address of the Pangolin Protocol Timelock
    VoteTimelockInterface public timelock;

    // @notice The address of the Pangolin governance token
    VoteTokenInterface public png;

    // @notice The address of the Governor Guardian
    address public guardian;

    // @notice The total number of proposals
    uint256 public proposalCount;

    struct Proposal {
        // @notice Unique id for looking up a proposal
        uint256 id;

        // @notice Creator of the proposal
        address proposer;

        // @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        // @notice the ordered list of target addresses for calls to be made
        address[] targets;

        // @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // @notice The ordered list of function signatures to be called
        string[] signatures;

        // @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // @notice The timestamp at which voting begins: holders must delegate their votes prior to this time
        uint256 startTime;

        // @notice The timestamp at which voting ends: votes must be cast prior to this block
        uint256 endTime;

        // @notice The block at which voting began: holders must have delegated their votes prior to this block
        uint256 startBlock;

        // @notice Current number of votes in favor of this proposal
        uint256 forVotes;

        // @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;

        // @notice Flag marking whether the proposal has been canceled
        bool canceled;

        // @notice Flag marking whether the proposal has been executed
        bool executed;

        // @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    // @notice Ballot receipt record for a voter
    struct Receipt {
        // @notice Whether or not a vote has been cast
        bool hasVoted;

        // @notice Whether or not the voter supports the proposal
        bool support;

        // @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    // @notice Possible states that a proposal may be in
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

    // @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;

    // @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    // @notice An event emitted when a new proposal is created
    event ProposalCreated(address govAddress, uint256 proposalId, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint256 startTime, uint256 endTime, string description);

    // @notice An event emitted when the first vote is cast in a proposal
    event StartBlockSet(address govAddress, uint256 proposalId, uint256 startBlock);

    // @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address govAddress, address voter, uint256 proposalId, bool support, uint256 votes);

    // @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(address govAddress, uint256 proposalId);

    // @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(address govAddress, uint256 proposalId, uint256 eta);

    // @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(address govAddress, uint256 proposalId);

    constructor(string memory _name, address _voteTimelock, address _voteToken, address _guardian, uint256 _votingDelay, 
            uint256 _votingPeriod, uint256 _proposalThreshold, uint256 _votingThreshold) {
        name = _name;
        timelock = VoteTimelockInterface(_voteTimelock);
        png = VoteTokenInterface(_voteToken);
        guardian = _guardian;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        votingThreshold = _votingThreshold;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(png.getPriorVotes(msg.sender, block.number - 1) > proposalThreshold, "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        //for phase one, we will allow non-transaction proposals.
        //require(targets.length != 0, "GovernorAlpha::propose: must provide actions"); 
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = block.timestamp + votingPeriod + votingDelay;

        proposalCount++;
        //Proposal storage newProposal = proposals[proposalCount++];
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer        = msg.sender;
        newProposal.eta             = 0;
        newProposal.targets         = targets;
        newProposal.values          = values;
        newProposal.signatures      = signatures;
        newProposal.calldatas       = calldatas;
        newProposal.startTime       = startTime;
        newProposal.startBlock      = 0;
        newProposal.endTime         = endTime;
        newProposal.forVotes        = 0;
        newProposal.againstVotes    = 0;
        newProposal.canceled        = false;
        newProposal.executed        = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(address(this), newProposal.id, msg.sender, targets, values, signatures, calldatas, startTime, endTime, description);
        return newProposal.id;
    }

    function getProposalData(uint256 proposalId) public view 
        returns (
            uint256 proposalId_,
            address proposer_,
            uint256 startTime_,
            uint256 endTime_,
            uint256 startBlock_,
            uint256 forVotes_,
            uint256 againstVotes_,
            bool canceled_,
            bool executed_,
            ProposalState state_
        ) {
        // this is a dummy change to force a recompile
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::getProposalData: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        proposalId_ = proposal.id;
        proposer_ = proposal.proposer;
        startTime_ = proposal.startTime;
        endTime_ = proposal.endTime;
        startBlock_ = proposal.startBlock;
        forVotes_ = proposal.forVotes;
        againstVotes_ = proposal.againstVotes;
        canceled_ = proposal.canceled;
        executed_ = proposal.executed;
        state_ = state(proposalId);
    }

    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(address(this), proposalId, eta);
    }

    function _queueOrRevert(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(address(this), proposalId);
    }

    function cancel(uint256 proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(png.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold, "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(address(this), proposalId);
    }

    function getActions(uint256 proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint256 proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint256 proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.startBlock == 0) {
            proposal.startBlock = block.number - 1;
            emit StartBlockSet(address(this), proposalId, block.number);
        }
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        uint96 votes = png.getPriorVotes(voter, proposal.startBlock);
        require(votes >= votingThreshold, "Not enough tokens to vote");

        if (support) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(address(this), voter, proposalId, support, votes);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface VoteTimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);
}

interface VoteTokenInterface {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/VoteGovernorFactory.sol

pragma solidity ^0.8.2;



contract VoteGovernorFactory is Ownable {
    event GovernorCreated(address indexed govOwner, address govAddress, string govName);

    address public voteTokenAddr;
    mapping (address => address) public ownerToGovMap;

    constructor(address _voteTokenAddr) {
        voteTokenAddr = _voteTokenAddr;
    }

    function createGovernor(string memory  _governorName, uint256 _timelockDelay, uint256 _votingDelay, uint256 _votingPeriod, 
            uint256 _proposalThreshold, uint256 _votingThreshold) public payable returns (address) {
        require(bytes(_governorName).length > 0, "Governor instance name is empty");
        require(ownerToGovMap[msg.sender] == address(0), "A Governance instance already exists for this address");
        require(_timelockDelay > 0, "Time lock delay parameter is 0");
        require(_votingDelay > 0, "Voting delay parameter is 0");
        require(_votingPeriod > 0, "Voting period parameter is 0");
        require(voteTokenAddr != address(0), "Vote token contract address not set");
        require(_proposalThreshold >= 1, "Proposal threshold can't be less than one");
        require(_votingThreshold >= 1, "Voting threshold can't be less than one");

        VoteTimelock voteTimeLock = new VoteTimelock(msg.sender, _timelockDelay);
        require(address(voteTimeLock) != address(0), "Time lock contract not created");
        //console.log("VoteTimelock created at address: %s", address(voteTimeLock));
        VoteGovernorAlpha governor = new VoteGovernorAlpha(_governorName, address(voteTimeLock), voteTokenAddr, msg.sender, _votingDelay, 
                _votingPeriod, _proposalThreshold, _votingThreshold);
        require(address(governor) != address(0), "Governor Contract not created");
        //console.log("VoteGovernorAlpha created at address: %s", address(governor));
        ownerToGovMap[msg.sender] = address(governor);
        //console.log("ownerToGovMap set for owner: %s --> the governor address is: %s", msg.sender, ownerToGovMap[msg.sender]);
        emit GovernorCreated(msg.sender, address(governor), _governorName);
        //console.log("GovernorCreated event emitted");
        return address(governor);
    }

    function getGovernorAddress(address _owner) public view returns (address) {
        require(_owner != address(0), "Can not use the zero address");
        return ownerToGovMap[_owner];
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send balance to the withdrawal address");
    }
}