pragma solidity ^0.4.24;

contract Voting {
	struct Voter {
		uint weight;
		bool voted;
	}

	struct Proposal {
		bytes32 name;
		uint voteCount;
	}

	bool public isOpen = true;
	address public chairperson;

	mapping(address => Voter) public voters;

	Proposal[] public proposals;
	bytes32[] public tmpProposalNames;
	string public aiueo2;

	constructor(bytes32[] proposalNames, string aiueo) public {
		chairperson = msg.sender;
		voters[chairperson].weight = 1;
		aiueo2 = aiueo;
		for (uint i = 0; i < proposalNames.length; i++) {
			proposals.push(Proposal({
				name: proposalNames[i],
				voteCount: 0
			}));
			tmpProposalNames.push(proposalNames[i]);
		}
	}

	function giveRightToVote(address voter) public {
	    require(isOpen == true, "This voting is already closed.");
		require(msg.sender == chairperson, "Only chairperson can give right to vote.");
		require(!voters[voter].voted, "The voter already voted.");
		require(voters[voter].weight == 0, "Already granted");
		voters[voter].weight = 1;
	}

	function vote(uint proposal) public {
	    require(isOpen == true, "This voting is already closed.");
		Voter storage sender = voters[msg.sender];
		require(sender.weight > 0, "No voting right");
		require(!sender.voted, "Already voted.");
		sender.voted = true;

		proposals[proposal].voteCount += sender.weight;
	}

	function winningProposal() public view returns (uint winningProposal_) {
		uint winningVoteCount = 0;
		for (uint p = 0; p < proposals.length; p++) {
			if (proposals[p].voteCount > winningVoteCount) {
				winningVoteCount = proposals[p].voteCount;
				winningProposal_ = p;
			}
		}
	}

	function winnerName() public view returns (bytes32 winnerName_) {
		winnerName_ = proposals[winningProposal()].name;
	}

	function closeVoting() public {
	    require(isOpen == true, "This voting is already closed.");
		require(msg.sender == chairperson, "Only chairperson can close voting.");
		isOpen = false;
	}

}