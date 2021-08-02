/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// NYP FYP
// File: Election.sol
// By: Lam Yi Xuen

pragma solidity >0.5.0;

contract Election {

	// Model a candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}

	// Store accouunts that have voted
	mapping(address => bool) public voters;

	// Store & Fetch Candidate
	mapping(uint => Candidate) public candidates;

	// Store candidate count
	uint public candidatesCount;

	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	event votedEvent(
		uint indexed _candidateId
	);

	function addCandidate(string memory _name) public {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	function vote(uint _candidateId) public {
		// require that the user has not voted before
		require(!voters[msg.sender]);

		// require a valid candidate
		require(_candidateId > 0 && _candidateId <= candidatesCount);

		// record that the voter has voted
		voters[msg.sender] = true;

		// update candidate vote count
		candidates[_candidateId].voteCount++;

		emit votedEvent(_candidateId);
	}
}