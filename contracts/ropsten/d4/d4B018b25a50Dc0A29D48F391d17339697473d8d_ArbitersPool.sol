pragma solidity ^0.5.0;

// File: contracts/ownerships/Roles.sol

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts/ownerships/ClusterRole.sol

contract ClusterRole {
    address private _cluster;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _cluster = msg.sender;
    }

    /**
     * @return the address of the owner.
     */
    function cluster() public view returns (address) {
        return _cluster;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyCluster() {
        require(isCluster());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isCluster() public view returns (bool) {
        return msg.sender == _cluster;
    }
}

// File: contracts/ownerships/ArbiterRole.sol

contract ArbiterRole is ClusterRole {
    using Roles for Roles.Role;

    event ArbiterAdded(address indexed arbiter);
    event ArbiterRemoved(address indexed arbiter);

    Roles.Role private _arbiters;

    constructor () internal {}

    modifier onlyArbiter() {
        require(isArbiter(msg.sender),"onlyArbiter: the sender is not an arbiter");
        _;
    }

    function isArbiter(address account) public view returns (bool) {
        return _arbiters.has(account);
    }

    // -----------------------------------------
    // EXTERNAL
    // -----------------------------------------

    function addArbiter(address arbiter) public onlyCluster {
        _addArbiter(arbiter);
    }

    function renounceArbiter(address arbiter) public onlyCluster {
        _removeArbiter(arbiter);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _addArbiter(address arbiter) internal {
        _arbiters.add(arbiter);
        emit ArbiterAdded(arbiter);
    }

    function _removeArbiter(address arbiter) internal {
        _arbiters.remove(arbiter);
        emit ArbiterRemoved(arbiter);
    }
}

// File: contracts/interfaces/ICluster.sol

interface ICluster {
    function solveDispute(address crowdsale, bytes32 milestoneHash, address investor, bool solvedToInvestor) external;
}

// File: contracts/ArbitersPool.sol

contract ArbitersPool is ArbiterRole {
    uint256 private _disputeId;
    uint256 private _necessaryVoices = 3;

    enum DisputeStatus { WAITING, SOLVED }
    enum Choice { OPERATORWINS, INVESTORWINS }

    ICluster private _clusterInterface;
    Dispute[] public disputes;

    struct Vote {
        address account;
        Choice choice;
    }
    struct Dispute {
        address investor;
        address crowdsale;
        bytes32 milestone;
        bytes32 reason;
        Vote[] votes;
        DisputeStatus status;
        mapping(address => bool) hasVoted;
    }

    mapping(bytes32 => uint256[]) private _disputesByMilestone;
    mapping(uint256 => Dispute) private _disputes;

    event Voted(uint256 indexed disputeId, address indexed arbiter, Choice choice);
    event DisputeClosed(uint256 indexed disputeId, Choice winner);

    constructor () public {
        _clusterInterface = ICluster(msg.sender);
    }

    function createDispute(bytes32 milestoneHash, address crowdsale, address investor, bytes32 reason) public onlyCluster returns (uint) {
        _disputeId = disputes.length++;

        Dispute storage dispute = disputes[_disputeId];
        dispute.investor = investor;
        dispute.crowdsale = crowdsale;
        dispute.milestone = milestoneHash;
        dispute.reason = reason;
        dispute.status = DisputeStatus.WAITING;

        _disputesByMilestone[milestoneHash].push(_disputeId);
        _disputes[_disputeId] = dispute;

        return _disputeId;
    }

    function voteDispute(uint256 disputeId, Choice choice) public onlyArbiter {
        require(_disputeId >= disputeId, "voteDispute: invalid number of dispute");
        require(_disputes[disputeId].crowdsale != address(0), "voteDispute: invalid number of dispute");
        require(_disputes[disputeId].status == DisputeStatus.WAITING, "voteDispute: dispute was already closed");
        require(_disputes[disputeId].hasVoted[msg.sender] == false, "voteDispute: arbiter was already voted");
        require(_disputes[disputeId].votes.length < _necessaryVoices, "voteDispute: dispute was already voted and finished");

        _disputes[disputeId].hasVoted[msg.sender] = true;
        _disputes[disputeId].votes.push(Vote(msg.sender, choice));

        if (_disputes[disputeId].votes.length == 2 && _disputes[disputeId].votes[0].choice == choice) {
            _executeDispute(disputeId, choice);
        } else if (_disputes[disputeId].votes.length == _necessaryVoices) {
            Choice winner = _calculateWinner(disputeId);
            _executeDispute(disputeId, winner);
        }

        emit Voted(disputeId, msg.sender, choice);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _calculateWinner(uint256 disputeId) private view returns (Choice choice) {
        uint8 votesForInvestor = 0;
        for (uint8 i = 0; i < _necessaryVoices; i++) {
            if (_disputes[disputeId].votes[i].choice == Choice.INVESTORWINS) {
                votesForInvestor++;
            }
        }

        return votesForInvestor >= 2 ? Choice.INVESTORWINS : Choice.OPERATORWINS;
    }

    function _executeDispute(uint256 disputeId, Choice choice) private {
        _disputes[disputeId].status = DisputeStatus.SOLVED;
        _clusterInterface.solveDispute(_disputes[disputeId].crowdsale, _disputes[disputeId].milestone, _disputes[disputeId].investor, choice == Choice.INVESTORWINS);

        emit DisputeClosed(disputeId, choice);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------
    
    function getDisputeId() public view returns (uint256) {
        return _disputeId;
    }
    
    function hasDisputeSolved(uint256 disputeId) public view returns (bool) {
        return _disputes[disputeId].status == DisputeStatus.SOLVED;
    }

    function getMilestoneDisputes(bytes32 milestoneHash) public view returns (uint256[] memory disputesIDs) {
        uint256 disputesLength = _disputesByMilestone[milestoneHash].length;
        disputesIDs = new uint256[](disputesLength);

        for (uint8 i = 0; i < disputesLength; i++) {
            disputesIDs[i] = _disputesByMilestone[milestoneHash][i];
        }

        return disputesIDs;
    }

    function howVotesHasDispute(uint256 disputeId) public view returns (uint256) {
        return _disputes[disputeId].votes.length;
    }

    function hasArbiterVoted(uint256 disputeId, address arbiter) public view returns (bool) {
        return _disputes[disputeId].hasVoted[arbiter];
    }
}