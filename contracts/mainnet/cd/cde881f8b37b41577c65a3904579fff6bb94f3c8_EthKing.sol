pragma solidity ^0.4.19;

/* King of the Hill, but with a twist

To with the pot, you must obtain 1 million points.
You obtain points by becoming and staying the King.
To become the King, you must pay 1% of the pot.
As the King, you earn (minutes)^2 points, where minutes
is the amount of time you remain King.

50% of the pot is used as an award, and the other 50%
seeds the pot for the next round.

20% of bids go to the bonus pot, which is given to the
second-place person when someone wins.

*/

contract EthKing {
	using SafeMath for uint256;

	// ------------------ Events -----------------------------

	event NewRound(
		uint _timestamp,
		uint _round,
		uint _initialMainPot,
		uint _initialBonusPot
  );

	event NewKingBid(
		uint _timestamp,
		address _address,
		uint _amount,
		uint _newMainPot,
		uint _newBonusPot
	);

	event PlaceChange(
		uint _timestamp,
		address _newFirst,
		address _newSecond,
		uint _firstPoints,
		uint _secondPoints
	);

	event Winner(
		uint _timestamp,
		address _first,
		uint _firstAmount,
		address _second,
		uint _secondAmount
	);

	event EarningsWithdrawal(
		uint _timestamp,
		address _address,
		uint _amount
	);

	// -------------------------------------------------------

	address owner;

	// ------------------ Game Constants ---------------------

	// Fraction of the previous pot used to seed the next pot
	// Currently 50%
	uint private constant NEXT_POT_FRAC_TOP = 1;
	uint private constant NEXT_POT_FRAC_BOT = 2;

	// Minimum fraction of the pot required to become the King
	// Currently 0.5%
	uint private constant MIN_LEADER_FRAC_TOP = 5;
	uint private constant MIN_LEADER_FRAC_BOT = 1000;

	// Fraction of each bid used for the bonus pot
	uint private constant BONUS_POT_FRAC_TOP = 20;
	uint private constant BONUS_POT_FRAC_BOT = 100;

	// Fractino of each bid used for the developer fee
	uint private constant DEV_FEE_FRAC_TOP = 5;
	uint private constant DEV_FEE_FRAC_BOT = 100;

	// Exponent for point calculation
	// Currently x^2
	uint private constant POINT_EXPONENT = 2;

	// How many points to win?
	uint private constant POINTS_TO_WIN = 1000000;
	
	// Null address for advancing round
    address null_address = address(0x0);

	// ----------------- Game Variables ----------------------

	// The current King, and when he was last put in power
	address public king;
	uint public crownedTime;

	// The current leader and the current 2nd-place leader
	address public first;
	address public second;

	// Player info
	struct Player {
		uint points;
		uint roundLastPlayed;
		uint winnings;
	}

	// Player mapping
	mapping (address => Player) private players;

	// Current round number
	uint public round;

	// Value of pot and bonus pot
	uint public mainPot;
	uint public bonusPot;

	// ----------------- Game Logic -------------------------

	function EthKing() public payable {
		// We should seed the game
		require(msg.value > 0);

		// Set owner and round
		owner = msg.sender;
		round = 1;

		// Calculate bonus pot and main pot
		uint _bonusPot = msg.value.mul(BONUS_POT_FRAC_TOP).div(BONUS_POT_FRAC_BOT);
		uint _mainPot = msg.value.sub(_bonusPot);

		// Make sure we didn&#39;t make a mistake
		require(_bonusPot + _mainPot <= msg.value);

		mainPot = _mainPot;
		bonusPot = _bonusPot;

		// Set owner as King
		// Crowned upon contract creation
		king = owner;
		first = null_address;
		second = null_address;
		crownedTime = now;
		players[owner].roundLastPlayed = round;
        players[owner].points = 0;
	}

	// Calculate and reward points to the current King
	// Should be called when the current King is being kicked out
	modifier payoutOldKingPoints {
		uint _pointsToAward = calculatePoints(crownedTime, now);
		players[king].points = players[king].points.add(_pointsToAward);

		// Check to see if King now is in first or second place.
		// If second place, just replace second place with King.
		// If first place, move first place down to second and King to first
		if (players[king].points > players[first].points) {
			second = first;
			first = king;

			PlaceChange(now, first, second, players[first].points, players[second].points);

		} else if (players[king].points > players[second].points && king != first) {
			second = king;

			PlaceChange(now, first, second, players[first].points, players[second].points);
		}

		_;
	}

	// Check current leader&#39;s points
	// Advances the round if he&#39;s at 1 million or greater
	// Pays out main pot and bonus pot
	modifier advanceRoundIfNeeded {
		if (players[first].points >= POINTS_TO_WIN) {
			// Calculate next pots and winnings
			uint _nextMainPot = mainPot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);
			uint _nextBonusPot = bonusPot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);

			uint _firstEarnings = mainPot.sub(_nextMainPot);
			uint _secondEarnings = bonusPot.sub(_nextBonusPot);

			players[first].winnings = players[first].winnings.add(_firstEarnings);
			players[second].winnings = players[second].winnings.add(_secondEarnings);

			// Advance round
			round++;
			mainPot = _nextMainPot;
			bonusPot = _nextBonusPot;

			// Reset first and second and King
			first = null_address;
			second = null_address;
			players[owner].roundLastPlayed = round;
			players[owner].points = 0;
			players[king].roundLastPlayed = round;
			players[king].points = 0;
			king = owner;
			crownedTime = now;

			NewRound(now, round, mainPot, bonusPot);
			PlaceChange(now, first, second, players[first].points, players[second].points);
		}

		_;
	}

	// Calculates the points a player earned in a given timer interval
	function calculatePoints(uint _earlierTime, uint _laterTime) private pure returns (uint) {
		// Earlier time could be the same as latertime (same block)
		// But it should never be later than laterTime!
		assert(_earlierTime <= _laterTime);

		// If crowned and dethroned on same block, no points
		if (_earlierTime == _laterTime) { return 0; }

		// Calculate points. Less than 1 minute is no payout
		uint timeElapsedInSeconds = _laterTime.sub(_earlierTime);
		if (timeElapsedInSeconds < 60) { return 0; }

		uint timeElapsedInMinutes = timeElapsedInSeconds.div(60);
		assert(timeElapsedInMinutes > 0);

		// 1000 minutes is an automatic win.
		if (timeElapsedInMinutes >= 1000) { return POINTS_TO_WIN; }

		return timeElapsedInMinutes**POINT_EXPONENT;
	}

	// Pays out current King
	// Advances round, if necessary
	// Makes sender King
	// Reverts if bid isn&#39;t high enough
	function becomeKing() public payable
		payoutOldKingPoints
		advanceRoundIfNeeded
	{
		// Calculate minimum bid amount
		uint _minLeaderAmount = mainPot.mul(MIN_LEADER_FRAC_TOP).div(MIN_LEADER_FRAC_BOT);
		require(msg.value >= _minLeaderAmount);

		uint _bidAmountToDeveloper = msg.value.mul(DEV_FEE_FRAC_TOP).div(DEV_FEE_FRAC_BOT);
		uint _bidAmountToBonusPot = msg.value.mul(BONUS_POT_FRAC_TOP).div(BONUS_POT_FRAC_BOT);
		uint _bidAmountToMainPot = msg.value.sub(_bidAmountToDeveloper).sub(_bidAmountToBonusPot);

		assert(_bidAmountToDeveloper + _bidAmountToBonusPot + _bidAmountToMainPot <= msg.value);

		// Transfer dev fee to owner&#39;s winnings
		players[owner].winnings = players[owner].winnings.add(_bidAmountToDeveloper);

		// Set new pot values
		mainPot = mainPot.add(_bidAmountToMainPot);
		bonusPot = bonusPot.add(_bidAmountToBonusPot);

		// Clear out King&#39;s points if they are from last round
		if (players[king].roundLastPlayed != round) {
			players[king].points = 0;	
		}
		
		// Set King
		king = msg.sender;
		players[king].roundLastPlayed = round;
		crownedTime = now;

		NewKingBid(now, king, msg.value, mainPot, bonusPot);
	}

	// Transfer players their winnings
	function withdrawEarnings() public {
		require(players[msg.sender].winnings > 0);
		assert(players[msg.sender].winnings <= this.balance);

		uint _amount = players[msg.sender].winnings;
		players[msg.sender].winnings = 0;

		EarningsWithdrawal(now, msg.sender, _amount);

		msg.sender.transfer(_amount);
	}

	// Fallback function.
	// If 0 ether, triggers tryAdvance()
	// If > 0 ether, triggers becomeKing()
	function () public payable {
		if (msg.value == 0) { tryAdvance(); }
		else { becomeKing(); }
	}

	// Utility function to advance the round / payout the winner
	function tryAdvance() public {
		// Calculate the King&#39;s current points.
		// If he&#39;s won, we payout and advance the round.
		// Equivalent to a bid, but without an actual bid.
		uint kingTotalPoints = calculatePoints(crownedTime, now) + players[king].points;
		if (kingTotalPoints >= POINTS_TO_WIN) { forceAdvance(); }
	}

	// Internal function called by tryAdvance if current King has won
	function forceAdvance() private payoutOldKingPoints advanceRoundIfNeeded { }
	
	// Gets a player&#39;s information
	function getPlayerInfo(address _player) public constant returns(uint, uint, uint) {
		return (players[_player].points, players[_player].roundLastPlayed, players[_player].winnings);
	}
	
	// Gets the sender&#39;s information
	function getMyInfo() public constant returns(uint, uint, uint) {
		return getPlayerInfo(msg.sender);		
	}
	
	// Get the King&#39;s current points
	function getKingPoints() public constant returns(uint) { return players[king].points; }
	
	// Get the first player&#39;s current points
	function getFirstPoints() public constant returns(uint) { return players[first].points; }
	
	// Get the second player&#39;s current points
	function getSecondPoints() public constant returns(uint) { return players[second].points; }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}