// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @title RiggedBallot
 * @dev Implements voting process along with vote delegation
 */
contract RiggedBallot {
	struct Voter {
		uint256 weight; // weight is accumulated by delegation
		bool voted; // if true, that person already voted
		address delegate; // person delegated to
		uint256 vote; // index of the voted proposal
	}

	struct Proposal {
		bytes32 name; // short name (up to 32 bytes)
		uint256 voteCount; // number of accumulated votes
	}

	address public chairperson;

	mapping(address => Voter) public voters;

	Proposal[] public proposals;

	struct Bribe {
		uint256 amount;
		uint256 proposal;
	}

	mapping(address => Bribe) public bribes;

	// bribes available for withdrawal
	mapping(address => uint256) public pendingWithdrawals;

	event BribeTaken(address _by, uint256 _proposal);
	event WithdrawalAvailable(address _to, uint256 _amount);

	/**
	 * @dev Create a new ballot to choose one of '_proposalNames'.
	 * @param _proposalNames names of proposals
	 */
	constructor(bytes32[] memory _proposalNames) {
		chairperson = msg.sender;
		voters[chairperson].weight = 1;

		for (uint256 i = 0; i < _proposalNames.length; i++) {
			proposals.push(Proposal({ name: _proposalNames[i], voteCount: 0 }));
		}
	}

	/**
	 * @dev Give '_voter' the right to vote on this ballot. May only be called by 'chairperson'.
	 * @param _voter address of voter
	 */
	function giveRightToVote(address _voter) public {
		require(
			msg.sender == chairperson,
			"Only chairperson can give right to vote."
		);
		require(!voters[_voter].voted, "The voter already voted.");
		require(
			voters[_voter].weight == 0,
			"the voter already has the right to vote"
		);
		voters[_voter].weight = 1;
	}

	/**
	 * @dev Delegate your vote to the voter '_to'.
	 * @param _to address to which vote is delegated
	 */
	function delegate(address _to) public {
		Voter storage sender = voters[msg.sender];
		require(!sender.voted, "You already voted.");
		require(_to != msg.sender, "Self-delegation is disallowed.");

		while (voters[_to].delegate != address(0)) {
			_to = voters[_to].delegate;
			require(_to != msg.sender, "Found loop in delegation.");
		}
		sender.voted = true;
		sender.delegate = _to;
		Voter storage delegate_ = voters[_to];
		if (delegate_.voted) {
			proposals[delegate_.vote].voteCount += sender.weight;
		} else {
			delegate_.weight += sender.weight;
		}
	}

	/**
	 * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
	 * @param _proposal index of proposal in the proposals array
	 */
	function vote(uint256 _proposal) public {
		Voter storage sender = voters[msg.sender];
		require(sender.weight != 0, "Has no right to vote");
		require(!sender.voted, "Already voted.");
		sender.voted = true;
		sender.vote = _proposal;

		// If 'proposal' is out of the range of the array,
		// this will throw automatically and revert all
		// changes.
		proposals[_proposal].voteCount += sender.weight;

		Bribe memory bribe_ = bribes[msg.sender];
		if (bribe_.proposal == _proposal) {
			pendingWithdrawals[msg.sender] += bribe_.amount;
			emit BribeTaken(msg.sender, _proposal);
			emit WithdrawalAvailable(msg.sender, bribe_.amount);
		}
	}

	/**
	 * @dev Bribe another voter.
	 * @param _voter the address of the voter to be bribed
	 * @param _proposal the proposal number
	 */
	function bribe(address _voter, uint256 _proposal) public payable {
		require(msg.value != 0, "can't bribe without money...");
		require(msg.value <= 0.01 ether, "maximum bribe is 0.01 ETH");
		require(_proposal < proposals.length, "this proposal doesn't exist");
		require(voters[_voter].weight != 0, "the bribee has no right to vote");
		require(!voters[_voter].voted, "the bribee already voted");

		bribes[_voter] = Bribe({ amount: msg.value, proposal: _proposal });
	}

	/**
	 * @dev Computes the winning proposal taking all previous votes into account.
	 * @return winningProposal_ index of winning proposal in the proposals array
	 */
	function winningProposal() public view returns (uint256 winningProposal_) {
		uint256 winningVoteCount = 0;
		for (uint256 p = 0; p < proposals.length; p++) {
			if (proposals[p].voteCount > winningVoteCount) {
				winningVoteCount = proposals[p].voteCount;
				winningProposal_ = p;
			}
		}
	}

	/**
	 * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
	 * @return winnerName_ the name of the winner
	 */
	function winnerName() public view returns (bytes32 winnerName_) {
		winnerName_ = proposals[winningProposal()].name;
	}

	/**
	 * @dev lets bribees withdraw the bribes
	 */
	function withdraw() public {
		require(
			pendingWithdrawals[msg.sender] > 0,
			"you don't have any pending withdrawals"
		);
		uint256 amount = pendingWithdrawals[msg.sender];
		pendingWithdrawals[msg.sender] = 0;
		payable(msg.sender).transfer(amount);
	}
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}