pragma solidity ^0.4.24;

contract Lot {
	uint8 private state = 0;	 //  0: Not start voting
								 //  1: Start Voting
								 //  2: Close voting
	uint32 public winner_count;
	uint32 private preferred_participant_count;
	uint32 private preferred_selection_count;	// Approximately how many times the winning selection will be done
	uint32 private total_participant_count;
	uint256 public win_seed;
	bool public start_selection;
	address owner;
	mapping(uint256 => address[]) public votes;
	mapping(address => bool) public voted;

	constructor (uint32 winners, uint32 preferred_participants, uint32 preferred_selections) public {
		 owner = msg.sender;
		 winner_count = winners;
		 preferred_participant_count = preferred_participants;
		 preferred_selection_count = preferred_selections;
		 total_participant_count = 0;
	}

	function startLottery() public {
		 require(msg.sender == owner, &quot;You don’t have a permission.&quot;);
		 require(state == 0, &quot;The lottery was already started.&quot;);
		 state = 1;
	}

	function participate() public returns(uint256) {
		 require(state == 1, &quot;The lottery isn’t running.&quot;);
		 require(!voted[msg.sender], &quot;You already participated.&quot;);
		 uint32 divisor = preferred_participant_count * preferred_selection_count / winner_count;
		 uint256 vote_number = uint256(msg.sender) % divisor;
		 votes[vote_number].push(msg.sender);
		 voted[msg.sender] = true;
		 total_participant_count++;
		 return vote_number;
	}

	function generateRand(uint256 seed) view private returns (uint) {
		 // Seeds
		 uint256 privSeed = (seed*3 + 1) / 2;
		 uint32 divisor = preferred_participant_count * preferred_selection_count / winner_count;
		 privSeed = privSeed % 10**9;
		 uint number = block.number; // ~ 10**5 ; 60000
		 uint diff = block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
		 uint time = block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273
		 uint gas = block.gaslimit; // ~ 3 Mega = 3*10**6
		 // Rand Number in Percent
		 uint total = privSeed + number + diff + time + gas;
		 uint rand = total % divisor;
		 return rand;
	}

	function close() public {
		 require(msg.sender == owner, &quot;You don’t have a permission.&quot;);
		 require(state == 1, &quot;The lottery isn’t running.&quot;);
		 state = 2;
	}

	function startSelection() public{
		 require(state == 2, &quot;The lottery hasn’t finished.&quot;);
		 require(msg.sender == owner, &quot;You don’t have a permission.&quot;);
		 win_seed = uint256(blockhash(block.number - 1));
		 start_selection = true;
	}

	function selectWinners(uint256 previous_win_num) view public returns(uint256, address[]) {
		 require(state == 2, &quot;The lottery hasn’t finished.&quot;);
		 uint256 win_num = generateRand(previous_win_num);
		 return (win_num, votes[win_num]);
	}
}