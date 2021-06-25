/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract LabDemoVoting {
	struct Vote {
		bool available;

		bool eligible;
		bool jury;

		int8[3] votes;
	}

	mapping(address => Vote) public votes;
	address[] public voters;

	mapping(uint8 => string) public teams;
	uint8 teamsSize;

	mapping(uint8 => uint256) public ranking;

	address public owner = msg.sender;

	bool public started = false;
	bool public ended = false;

	uint256 public counter = 0;

	constructor() public {
		string[13] memory teamNames = ["Bakery", "Burger", "Yam", "Taco", "Shrimp", "Grape", "Sushi", "Meme", "Spaghetti", "Hotdog", "Kimchi", "Chop", "Salmon" ];
		teamsSize = uint8(teamNames.length);

		for(uint8 i = 0; i < teamsSize; i++) {
			teams[i] = teamNames[i];
		}
	}

	function resetVotes() public {
		require(!started, "Cannot reset votes once the official voting has started.");

		for(uint256 i = 0; i < voters.length; i++) {
			address voterAddress = voters[i];

			for(uint8 j = 0; j < 3; j++) {
				votes[voterAddress].votes[j] = -1;
			}
		}

		counter = 0;
	}

	function start() public {
		require(!ended, "The voting already ended and therefore cannot be started again.");
		require(msg.sender == owner, "Only Rob can start the voting.");

		resetVotes();

		started = true;
	}

	function end() public {
		require(started, "The voting has not started, yet.");
		require(!ended, "The voting already ended and therefore cannot be ended again.");
		require(msg.sender == owner, "Only Rob can end the voting.");

		refreshRanking();

		ended = true;
	}

	function makeEligible(address[] memory _participants) public {
		require(msg.sender == owner, "Only Rob can make addresses eligible.");

		for(uint i = 0; i < _participants.length; i++) {
			address participant = _participants[i];

			if(!votes[participant].available) {
				votes[participant] = Vote(true, true, false, [-1, -1, -1]);
				voters.push(participant);
			} else {
				votes[participant].eligible = true;
			}
		}

	}

	function makeJury(address _participant) public {
		require(msg.sender == owner, "Only Rob can add jury members.");

		if(!votes[_participant].available) {
			votes[_participant] = Vote(true, true, true, [-1, -1, -1]);
			voters.push(_participant);
		} else {
			votes[_participant].eligible = true;
			votes[_participant].jury = true;
		}
	}

	function proxyJuryVote(uint8 _juryId, uint8 _team1, uint8 _team2, uint8 _team3) public {
		require(msg.sender == owner, "Only Rob can make proxy jury votes.");
		require(_team1 != _team2 && _team1 != _team3 && _team2 != _team3, "Teams have to be different.");

		address juryProxyAddress = address(_juryId);
		if(!votes[juryProxyAddress].available) {
			votes[juryProxyAddress] = Vote(true, true, true, [int8(_team1), int8(_team2), int8(_team3)]);
			voters.push(juryProxyAddress);
		} else {
			votes[juryProxyAddress].jury = true;
			votes[juryProxyAddress].votes[0] = int8(_team1);
			votes[juryProxyAddress].votes[1] = int8(_team2);
			votes[juryProxyAddress].votes[2] = int8(_team3);
		}

	}

	function voteOnce(int8 _team1, int8 _team2, int8 _team3) public {
		vote(-1);
		vote(-1);
		vote(-1);
		vote(_team1);
		vote(_team2);
		vote(_team3);
	}

	function vote(int8 _team) public {
		require(_team < int8(teamsSize), "Invalid team id.");
		require(_team >= -1, "Invalid team id.");
		require(!ended || msg.sender == owner || votes[msg.sender].jury == true, "Voting already ended.");

		require(started || counter < 256, "The testing phase ended for performance reasons, sorry."); // Security switch

		if(!votes[msg.sender].available) {
			votes[msg.sender] = Vote(true, false, false, [-1, -1, -1]);
			voters.push(msg.sender);
		}

		for(uint256 i = 0; i < 3; i++) {
			require(_team == -1 || votes[msg.sender].votes[i] != int8(_team), "You've already voted for that team.");
		}

		votes[msg.sender].votes[0] = votes[msg.sender].votes[1];
		votes[msg.sender].votes[1] = votes[msg.sender].votes[2];
		votes[msg.sender].votes[2] = int8(_team); 

		counter++;
	}

	function refreshRanking() public {
		require(!ended || msg.sender == owner, "Voting already ended.");

		// Clear last ranking
		for(uint8 i = 0; i < teamsSize; i++) {
			ranking[i] = 0;
		}

		// Add all votes
		for(uint256 i = 0; i < voters.length; i++) {
			Vote memory v = votes[voters[i]];
			
			if(!v.eligible)
				continue;

			for(uint8 j = 0; j < 3; j++) {
				int8 votedTeam = v.votes[j];

				if(votedTeam != -1) {
					if(v.jury)
						ranking[uint8(votedTeam)] += 5;
					else 
						ranking[uint8(votedTeam)] += 1;
				}
			}
		}
	}

	function kill() public {
		require(msg.sender == owner, "Disculpe, usted no es Roberto. Lo siento.");
		selfdestruct(payable(owner));
	}

	function changeOwner(address _newOwner) public {
		require(msg.sender == owner, "Disculpe, usted no es Roberto. Lo siento.");
		owner = _newOwner;
	}

	function voteFor_Bakery() 		public { vote(0); }
	function voteFor_Burger() 		public { vote(1); }
	function voteFor_Yam() 			public { vote(2); }
	function voteFor_Taco() 		public { vote(3); }
	function voteFor_Shrimp() 		public { vote(4); }
	function voteFor_Grape() 		public { vote(5); }
	function voteFor_Sushi() 		public { vote(6); }
	function voteFor_Meme() 		public { vote(7); }
	function voteFor_Spaghetti() 	public { vote(8); }
	function voteFor_Hotdog() 		public { vote(9); }
	function voteFor_Kimchi() 		public { vote(10); }
	function voteFor_Chop() 		public { vote(11); }
	function voteFor_Salmon() 		public { vote(12); }
}