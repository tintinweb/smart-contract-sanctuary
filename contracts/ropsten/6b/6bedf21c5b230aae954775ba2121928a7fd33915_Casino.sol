pragma solidity ^0.4.24;

contract Casino{

	struct Option {
		uint256 optionReward;
		BetInfo[] betInfo;
	}

	struct BetInfo {
		address betAddress;
		uint256 amount;
	}

	Option[2] public options;
	uint256 public bettingTime;
	uint256 public totalReward;
	uint256 public winner;
	bool public winnerRevealed;

	Option tempOption;
	BetInfo tempBetInfo;

	// Stage 0: Create
	// Initialize
	constructor (uint256 _betTimePeriodInMinutes) public {
		bettingTime = now + _betTimePeriodInMinutes * 1 minutes;
		winnerRevealed = false;
	}

	// Stage 1: Betting
	function bet(uint256 _option) public payable returns (bool){
		require(now <= bettingTime);
		require(_option < options.length);
		options[_option].betInfo.push(BetInfo(msg.sender, msg.value));
		options[_option].optionReward += msg.value;
		totalReward += msg.value;

		return true;
	}

	// Stage 2: Getting Result
	function revealWinner() public {
		require(now >= bettingTime);
		require(!winnerRevealed);
		winner = 1;  //fixed winner
		winnerRevealed = true;
	}

	// Stage 3: Dispatch the reward
	function dispatch() public{
		require(winnerRevealed);
		assert(winner < options.length);

		for(uint256 i = 0; i < options[winner].betInfo.length; i++){
			address receiver = options[winner].betInfo[i].betAddress;
			uint256 value = totalReward * options[winner].betInfo[i].amount / options[winner].optionReward;
			require(receiver.send(value));
		}

	}
}