// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Governance
 * @dev The Governance contract allows to execute certain actions via majority of votes.
 */
contract Governance {
    mapping(bytes32 => Proposal) public proposals;
    bytes32[] public proposalsHashes;
    uint256 public proposalsCount;

    mapping(address => bool) public isVoter;
    address[] public voters;
    uint256 public votersCount;

    struct Proposal {
        bool finished;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVoters;
        mapping(address => bool) votedFor;
        mapping(address => bool) votedAgainst;
        address targetContract;
        bytes data;
    }

    event ProposalStarted(bytes32 proposalHash);
    event ProposalFinished(bytes32 proposalHash);
    event ProposalExecuted(bytes32 proposalHash);
    event Vote(bytes32 proposalHash, bool vote, uint256 yesVotes, uint256 noVotes, uint256 votersCount);
    event VoterAdded(address voter);
    event VoterDeleted(address voter);

    /**
     * @dev The Governance constructor adds sender to voters list.
     */
    constructor(address[] memory _voters) {
        for (uint256 i=0; i<_voters.length; i++){
            voters.push(_voters[i]);
            isVoter[_voters[i]] = true;
        }
        proposalsCount = 0;
        votersCount = _voters.length;
    }

    /**
     * @dev Throws if called by any account other than the voter.
     */
    modifier onlyVoter() {
        require(isVoter[msg.sender], "Should be voter");
        _;
    }

    /**
     * @dev Throws if called by any account other than the Governance contract.
     */
    modifier onlyMe() {
        require(msg.sender == address(this), "Call only via Governance");
        _;
    }

    /**
     * @dev Creates a new voting proposal for the execution `_data` of `_targetContract`.
     * Only voter can create a new proposal.
     *
     * Requirements:
     *
     * - `_targetContract` cannot be the zero address.
     * - `_data` length must not be less than 4 bytes.
     *
     * @notice Create a new voting proposal for the execution `_data` of `_targetContract`. You must be voter.
     * @param _targetContract Target contract address that can execute target `_data`
     * @param _data Target calldata to execute
     */
    function newProposal(address _targetContract, bytes memory _data) public onlyVoter {
        require(_targetContract != address(0), "Address must be non-zero");
        require(_data.length >= 4, "Tx must be 4+ bytes");
        // solhint-disable not-rely-on-time
        bytes32 _proposalHash = keccak256(abi.encodePacked(_targetContract, _data, block.timestamp));
        require(proposals[_proposalHash].data.length == 0, "The poll has already been initiated");
        proposals[_proposalHash].targetContract = _targetContract;
        proposals[_proposalHash].data = _data;
        proposals[_proposalHash].totalVoters = votersCount;
        proposalsHashes.push(_proposalHash);
        proposalsCount = proposalsCount + 1;
        emit ProposalStarted(_proposalHash);
    }

    /**
     * @dev Adds sender's vote to the proposal and then follows the majority voting algoritm.
     *
     * Requirements:
     *
     * - proposal with `_proposalHash` must not be finished.
     * - sender must not be already voted.
     *
     * @notice Vote "for" or "against" in proposal with `_proposalHash` hash.
     * @param _proposalHash Unique mapping key of proposal
     * @param _yes 1 is vote "for" and 0 is "against"
     */
    function vote(bytes32 _proposalHash, bool _yes) public onlyVoter {
        // solhint-disable code-complexity
        require(!proposals[_proposalHash].finished, "Already finished");
        require(!proposals[_proposalHash].votedFor[msg.sender], "Already voted");
        require(!proposals[_proposalHash].votedAgainst[msg.sender], "Already voted");
        if (proposals[_proposalHash].totalVoters != votersCount) proposals[_proposalHash].totalVoters = votersCount;
        if (_yes) {
            proposals[_proposalHash].yesVotes = proposals[_proposalHash].yesVotes + 1;
            proposals[_proposalHash].votedFor[msg.sender] = true;
        } else {
            proposals[_proposalHash].noVotes = proposals[_proposalHash].noVotes + 1;
            proposals[_proposalHash].votedAgainst[msg.sender] = true;
        }
        emit Vote(
            _proposalHash,
            _yes,
            proposals[_proposalHash].yesVotes,
            proposals[_proposalHash].noVotes,
            votersCount
        );
        if (proposals[_proposalHash].yesVotes > votersCount / 2) {
            executeProposal(_proposalHash);
            finishProposal(_proposalHash);
        } else if (proposals[_proposalHash].noVotes >= (votersCount + 1) / 2) {
            finishProposal(_proposalHash);
        }
    }

    /**
     * @dev Returns true in first output if `_address` is already voted in
     * proposal with `_proposalHash` hash.
     * Second output shows, if voter is voted for (true) or against (false).
     *
     * @param _proposalHash Unique mapping key of proposal
     * @param _address Address of the one who is checked
     */
    function getVoted(bytes32 _proposalHash, address _address) public view returns (bool, bool) {
        bool isVoted = proposals[_proposalHash].votedFor[_address] || proposals[_proposalHash].votedAgainst[_address];
        bool side = proposals[_proposalHash].votedFor[_address];
        return (isVoted, side);
    }

    /**
     * @dev Adds `_address` to the voters list.
     * This method can be executed only via proposal of this Governance contract.
     *
     * Requirements:
     *
     * - `_address` cannot be the zero address.
     * - `_address` cannot be already in voters list.
     *
     * @param _address Address of voter to add
     */
    function addVoter(address _address) public onlyMe {
        require(_address != address(0), "Need non-zero address");
        require(!isVoter[_address], "Already in voters list");
        voters.push(_address);
        isVoter[_address] = true;
        votersCount = votersCount + 1;
        emit VoterAdded(_address);
    }

    /**
     * @dev Removes `_address` from the voters list.
     * This method can be executed only via proposal of this Governance contract.
     *
     * Requirements:
     *
     * - `_address` must be in voters list.
     * - Num of voters must be more than one.
     *
     * @param _address Address of voter to delete
     */
    function delVoter(address _address) public onlyMe {
        require(isVoter[_address], "Not in voters list");
        require(votersCount > 1, "Can not delete single voter");
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _address) {
                if (voters.length > 1) {
                    voters[i] = voters[voters.length - 1];
                }
                voters.pop(); // Implicitly recovers gas from last element storage
                isVoter[_address] = false;
                votersCount = votersCount - 1;
                emit VoterDeleted(_address);
                break;
            }
        }
    }

    /**
     * @dev Executes data in proposal with `_proposalHash` hash.
     * This method can be executed only from vote() method.
     */
    function executeProposal(bytes32 _proposalHash) internal {
        require(!proposals[_proposalHash].finished, "Already finished");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(proposals[_proposalHash].targetContract).call(
            proposals[_proposalHash].data
        );
        require(success, string(returnData));
        emit ProposalExecuted(_proposalHash);
    }

    /**
     * @dev Finishes proposal with `_proposalHash` hash.
     * This method can be executed only from vote() method.
     */
    function finishProposal(bytes32 _proposalHash) internal {
        require(!proposals[_proposalHash].finished, "Already finished");
        proposals[_proposalHash].finished = true;
        emit ProposalFinished(_proposalHash);
    }
}