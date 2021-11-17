// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "election.sol";

contract Elections {
    Election[] public electionArray;
    mapping(address => address[]) public ownersElections;

    mapping(address => uint256) contributors;

    function createElection() public {
        Election _election = new Election();
        electionArray.push(_election);
        ownersElections[msg.sender].push(address(_election));
    }

    function fundDevelopment() public payable returns (uint256) {
        return msg.value;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// /*
// Owner -> all right
// Voliantiers -> Add Candidate and Voters, Change their participating status
// Voters -> Right related to voting only
// Candidates -> Right to change Description only

// fucntionalities added :
// 1) Set election name :Done
// 2) Set election state :Done
// 3) withdraw funds by owner :Done
// 4) get balance :Done
// 5) add supporter :Done
// 6) update supporter :Done
// 7) get supporter status :Done
// 8) add voter :Done
// 9) update voter :Done
// 10) add candidate :Done
// 11) update candidate :Done
// 12) get candidate status :Done
// 13) vote :Done
// 14) get winner :Done
// */

contract Election {
    string public electionName = "";
    bool public electionActive = true;

    address public owner;
    mapping(address => bool) public supporters;

    mapping(address => bool) public voters;
    mapping(address => address) public votersVote;
    mapping(address => bool) public voterHasVoted;

    struct Candidate {
        string symbol;
        address candidateAddress;
        bool status;
        string description;
        address[] votedBy;
    }

    Candidate[] public candidates;
    mapping(address => uint256) public candidatesIndex;

    constructor() {
        owner = msg.sender;
    }

    modifier electionIsActive() {
        require(electionActive == true, "Election has been ended!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner has access to this function.");
        _;
    }

    modifier onlySupporters() {
        require(
            supporters[msg.sender] == true,
            "Only supporters have access to this function."
        );
        _;
    }

    modifier onlyAdmins() {
        require(
            (msg.sender == owner) || (supporters[msg.sender] == true),
            "Owner or Supporters can access it."
        );
        _;
    }

    modifier onlyVoter() {
        require(
            voters[msg.sender] == true,
            "Only supporters have access to this function."
        );
        _;
    }

    modifier onlyCandidates() {
        require(
            msg.sender ==
                candidates[candidatesIndex[msg.sender]].candidateAddress,
            "Only supporters have access to this function."
        );
        _;
    }

    function setElectionName(string memory _electionName)
        public
        onlyOwner
        electionIsActive
    {
        electionName = _electionName;
    }

    function electionState(bool _electionActive) public onlyOwner {
        electionActive = _electionActive;
    }

    function withdraw() public payable onlyOwner {
        if (msg.sender == owner) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // adding supporters
    function addSupporter(address _supporters)
        public
        onlyOwner
        electionIsActive
    {
        supporters[_supporters] = true;
    }

    // get supporters supporting status
    function getSupporterStatus(address _supporter) public view returns (bool) {
        return supporters[_supporter];
    }

    // updating supporters status
    function updateSupporterStatus(address _supporters, bool _state)
        public
        onlyOwner
        electionIsActive
    {
        supporters[_supporters] = _state;
    }

    // adding new voter
    function addVoter(address _votersAddress)
        public
        onlyAdmins
        electionIsActive
    {
        voters[_votersAddress] = true;
        voterHasVoted[_votersAddress] = false;
    }

    // updating voters right
    function updateVoter(address _votersAddress, bool _state)
        public
        onlyAdmins
        electionIsActive
    {
        voters[_votersAddress] = _state;
    }

    // adding candidate
    function addCandidate(
        string memory _symbol,
        address _candidateAddress,
        bool _status,
        string memory _description
    ) public onlyAdmins electionIsActive {
        Candidate memory _candidate;

        _candidate.symbol = _symbol;
        _candidate.candidateAddress = _candidateAddress;
        _candidate.status = _status;
        _candidate.description = _description;

        candidates.push(_candidate);
        candidatesIndex[_candidateAddress] = candidates.length - 1;
    }

    function updateCandidate(
        address _candidateAddress,
        bool _status,
        string memory _symbol,
        string memory _description
    ) public onlyAdmins electionIsActive {
        uint256 _candidateIndex = candidatesIndex[_candidateAddress];

        candidates[_candidateIndex].status = _status;

        if (keccak256(bytes(_symbol)) != keccak256(bytes(""))) {
            candidates[_candidateIndex].symbol = _symbol;
        }

        if (keccak256(bytes(_description)) != keccak256(bytes(""))) {
            candidates[_candidateIndex].description = _description;
        }
    }

    function getCandidateStatus(address _candidateAddress)
        public
        view
        returns (bool)
    {
        return candidates[candidatesIndex[_candidateAddress]].status;
    }

    function descriptionUpdateOfCandidate(string memory _description)
        public
        onlyCandidates
    {
        candidates[candidatesIndex[msg.sender]].description = _description;
    }

    function vote(address _candidateAddress)
        public
        onlyVoter
        returns (string memory)
    {
        if (!voterHasVoted[msg.sender]) {
            candidates[candidatesIndex[_candidateAddress]].votedBy.push(
                msg.sender
            );
            voterHasVoted[msg.sender] = true;
            votersVote[msg.sender] = _candidateAddress;
            return "Thank you for voting.";
        }
        return "You have already voted.";
    }

    function getWinner() public view returns (address) {
        address winnersAddress;
        uint256 highestVote = 0;

        for (uint256 index = 0; index < candidates.length; index++) {
            if (candidates[index].votedBy.length > highestVote) {
                winnersAddress = candidates[index].candidateAddress;
                highestVote = candidates[index].votedBy.length;
            }
        }

        return winnersAddress;
    }
}