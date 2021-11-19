/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed


contract Election {
    // State Variables
    uint256 id;
    Candidate[] private candidates;
    address[] private voters;

    struct Candidate {
        string name;
        uint256 id;
        string party;
        address _address;
        uint256 numOfVotes;
    }

    // Mappings
    mapping(address => bool) private isRegisteredCandidate;
    mapping(address => bool) private isRegisteredVoter;
    mapping(address => bool) private hasVoted;

    // Events
    event candidateRegistered(uint256 id, string name, string party);
    event voterRegistered(address _address);
    event voteRegistered(uint256 candidateId, string msg);

    // It restricts the function for registered people.
    modifier onlyUnregistered(address caller) {
        require(
            isRegisteredCandidate[caller] == false &&
                isRegisteredVoter[caller] == false,
            "You are already registered"
        );
        _;
    }

    // FUNCTIONS

    // This function registers a new candidate.
    function candidateRegistration(string memory _name, string memory _party)
        public
        onlyUnregistered(msg.sender)
    {
        Candidate memory cand = Candidate(
            _name,
            id += 1,
            _party,
            msg.sender,
            0
        );
        candidates.push(cand);
        isRegisteredCandidate[msg.sender] = true;
        emit candidateRegistered(id, _name, _party);
    }

    // Function to get all the candidates.
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // This function resgisters a new voter.
    function voterRegistration() public onlyUnregistered(msg.sender) {
        isRegisteredVoter[msg.sender] = true;
        voters.push(msg.sender);
        emit voterRegistered(msg.sender);
    }

    // This function registers the vote from the voter for a particular candidate.
    function Vote(uint256 _candidateId) public {
        require(
            isRegisteredVoter[msg.sender] == true &&
                isRegisteredCandidate[msg.sender] == false,
            "You are not a registerd voter"
        );
        require(hasVoted[msg.sender] == false, "You can vote only once");

        candidates[_candidateId - 1].numOfVotes++;
        hasVoted[msg.sender] = true;
        emit voteRegistered(_candidateId, "Your vote has been registered");
    }

    // This function is called to declare the winner of the election.
    function declareWinner()
        external
        view
        returns (
            string memory _name,
            string memory _party,
            address _address
        )
    {
        uint256 maxVotes = candidates[0].numOfVotes;
        Candidate memory winner = candidates[0];
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].numOfVotes > maxVotes) {
                maxVotes = candidates[i].numOfVotes;
                winner = candidates[i];
            }
        }
        return (winner.name, winner.party, winner._address); // returns name, part and id of the winning candidate
    }

}