pragma solidity 0.4.24;

contract Election {
		// Model a Candidate
		struct Candidate {
				uint id;
				string name;
				uint voteCount;
		}

		// Read/write Candidates
    mapping(uint => Candidate) public candidates;

		// Store accounts that have voted
		mapping(address => bool) public voters;

    // Store Candidates Count
    uint public candidatesCount;

    // Constructor
    constructor () public {
				addCandidate("Candidate 1");
				addCandidate("Candidate 2");
    }

		function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

		function vote (uint _candidateId) public {
			// require that user hasn&#39;t voted before
			require(!voters[msg.sender]);

			// require a valid candidate
			require(_candidateId > 0 && _candidateId <= candidatesCount);

			// record that voter has voted
			voters[msg.sender] = true;

			// update candidate vote count
			candidates[_candidateId].voteCount++;

			// trigger voted event
			emit votedEvent(_candidateId);

		}

		event votedEvent(uint indexed _candidateId)






;




}