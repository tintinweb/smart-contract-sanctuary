pragma solidity 0.4.20;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    struct Voter {
        bytes32 name;
        uint timesVote;
    }

    // Store accounts that have voted
    mapping(address => Voter) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    function Election () public {
        addCandidate("Candidate CL");
        addCandidate("Candidate 2");
    }

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // require that they haven&#39;t voted before
        require(voters[msg.sender].timesVote < 1);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted once
        voters[msg.sender].timesVote ++;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        votedEvent(_candidateId);
    }
    
    function hasVoted () public view returns (bool) {
        if (voters[msg.sender].timesVote > 0) {
            return true;
        }
    }
}