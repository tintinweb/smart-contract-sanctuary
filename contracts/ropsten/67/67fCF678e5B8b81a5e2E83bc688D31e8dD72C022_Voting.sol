//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Voting {
    struct Candidate {
        address candidateAddress;
        uint256 voteCount;
        string name;
    }
    struct Voter {
        bool voted;
        uint256 candidateIndex;
    }

    uint256 public electionId;
    uint256 public registrationEndPeriod;
    uint256 public votingEndPeriod;
    bool public locked;
    address private owner;

    Candidate[] public candidates;
    mapping(address => mapping(uint256 => bool)) public registeredCandidates;
    mapping(address => mapping(uint256 => Voter)) public voters;

    event StartElection(
        uint256 indexed electionId,
        uint256 registrationEndPeriod,
        uint256 votingEndPeriod,
        address starter
    );
    event ArchivePastElection(
        uint256 indexed electionId,
        string winnerName,
        uint256 voteCount,
        address winnerAddress
    );
    event RegisterCandidate(
        uint256 indexed electionId,
        uint256 candidateId,
        string name
    );
    event VoteForCandidate(
        uint256 indexed electionId,
        uint256 candidateId,
        uint256 voteCount
    );

    constructor() {
        owner = msg.sender;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev startElection start a new election passing in a _registrationEndPeriod
     * and a _votingEndPeriod. This also allows starting a new election if the
     * conditions allow it.
     */
    function startElection(
        uint256 _registrationEndPeriod,
        uint256 _votingEndPeriod
    ) external {
        require(
            _registrationEndPeriod >= block.timestamp &&
                _votingEndPeriod >= _registrationEndPeriod,
            "Registration end period must be > voting end period > registration end period."
        );
        bool hasElectionEnded =
            (registrationEndPeriod == 0 && votingEndPeriod == 0) ||
                block.timestamp > votingEndPeriod;
        require(
            hasElectionEnded,
            "There is an active election currently, please wait until it is over."
        );

        // delete the previous election data and save the data
        if (registrationEndPeriod != 0 || votingEndPeriod != 0) {
            (string memory name, uint256 voteCount, address winnerAddress) =
                winningCandidateDetails();
            emit ArchivePastElection(
                electionId,
                name,
                voteCount,
                winnerAddress
            );
            delete candidates;
            electionId++;
        }

        // start a new election
        registrationEndPeriod = _registrationEndPeriod;
        votingEndPeriod = _votingEndPeriod;

        emit StartElection(
            electionId,
            _registrationEndPeriod,
            _votingEndPeriod,
            msg.sender
        );
    }

    function updateTime(
        uint256 _registrationEndPeriod,
        uint256 _votingEndPeriod
    ) external {
        require(_registrationEndPeriod < _votingEndPeriod);
        registrationEndPeriod = _registrationEndPeriod;
        votingEndPeriod = _votingEndPeriod;
    }

    /**
     * @dev registerCandidate allows anyone to sign up as a candidate in an
     * active election.
     */
    function registerCandidate(string memory _name) external {
        require(
            registrationEndPeriod != 0,
            "There are no elections currently."
        );
        require(
            getKeccak(_name) != getKeccak(""),
            "Please register with a name."
        );
        require(
            block.timestamp < registrationEndPeriod,
            "The registration period has ended."
        );
        require(
            registeredCandidates[msg.sender][electionId] == false,
            "You have already registered for an election."
        );
        registeredCandidates[msg.sender][electionId] = true;
        candidates.push(Candidate(msg.sender, 0, _name));

        emit RegisterCandidate(electionId, candidates.length - 1, _name);
    }

    /**
     * @dev voteForCandidate allows anyone to vote for a candidate in the current
     * active election.
     */
    function voteForCandidate(uint256 _candidateId) external noReentrancy {
        require(
            !voters[msg.sender][electionId].voted,
            "You have already voted for a candidate."
        );
        require(
            candidates.length >= _candidateId + 1,
            "This candidate doesn't exist."
        );
        require(
            block.timestamp > registrationEndPeriod &&
                block.timestamp < votingEndPeriod,
            "Voting is not allowed now."
        );
        candidates[_candidateId].voteCount++;
        voters[msg.sender][electionId].voted = true;
        voters[msg.sender][electionId].candidateIndex = _candidateId;

        emit VoteForCandidate(
            electionId,
            _candidateId,
            candidates[_candidateId].voteCount
        );
    }

    /**
     * @dev getWinnerResults a view function to see who the winner of the
     * active election is.
     */
    function getWinnerResults()
        public
        view
        returns (uint256 _winningCandidate, bool isOver)
    {
        uint256 winningCount = 0;
        isOver = block.timestamp > votingEndPeriod;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningCount) {
                winningCount = candidates[i].voteCount;
                _winningCandidate = i;
            }
        }
    }

    function destroyContract() public {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }

    /**
     * @dev winningCandidateDetails an internal view function to get the details of the
     * winning candidate.
     */
    function winningCandidateDetails()
        internal
        view
        returns (
            string memory _name,
            uint256 _voteCount,
            address _address
        )
    {
        (uint256 winningCandidate, ) = getWinnerResults();
        return (
            candidates[winningCandidate].name,
            candidates[winningCandidate].voteCount,
            candidates[winningCandidate].candidateAddress
        );
    }

    function getKeccak(string memory _string) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}