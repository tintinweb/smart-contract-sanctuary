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

	constructor(bytes32[] proposalNames) public {
		chairperson = msg.sender;
		voters[chairperson].weight = 1;

		for (uint i = 0; i < proposalNames.length; i++) {
			proposals.push(Proposal({
				name: proposalNames[i],
				voteCount: 0
			}));
		}
	}

	function giveRightToVote(address voter) public {
		require(isOpen == true, &quot;This voting is already closed.&quot;);
		require(msg.sender == chairperson, &quot;Only chairperson can give right to vote.&quot;);
		require(!voters[voter].voted, &quot;The voter already voted.&quot;);
		require(voters[voter].weight == 0, &quot;Already granted&quot;);
		voters[voter].weight = 1;
	}

	function vote(uint proposal) public {
		require(isOpen == true, &quot;This voting is already closed.&quot;);
		Voter storage sender = voters[msg.sender];
		require(sender.weight > 0, &quot;No voting right&quot;);
		require(!sender.voted, &quot;Already voted.&quot;);
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
		require(isOpen == true, &quot;This voting is already closed.&quot;);
		require(msg.sender == chairperson, &quot;Only chairperson can close voting.&quot;);
		isOpen = false;
	}

}