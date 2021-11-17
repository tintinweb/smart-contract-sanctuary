/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

/**
* 
* T R U T H   S T A K I N G
*
* www.truthstaking.com
*
* Stake Ether on claims made by the media. If your peers agree with you, you win.
* This smart contract allows users to do 2 things:
* 1) Submit statements that are TRUE or FALSE.
* 2) Stake on submitted statements.
* After the staking period for the statement ends, the TRUE and FALSE pots of ether are counted. 
* The larger pot wins, and the smaller pot is distributed amongst the winners, proportional to the size of their stakes.
* The "market maker" (the address that submitted the statement) receives an extra reward proportional to her first stake.
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract TruthStaking {

	using SafeMath for uint;

	////////////////////// STRUCTS //////////////////////

	struct Statement {
		uint id;
		string statement;
		uint stakeDuration;
		uint stakeBeginningTime;
		uint stakeEndTime;
		address marketMaker;
		uint numStakes;
		uint ethStaked;
		bool stakeEnded;
		string source;
		uint verdict;
		mapping(uint => Stake) stakes; // TODO: Make private?
	}

	struct Stake {
		address addr; // Staker's address
		uint amount; // Value staked
		uint position; // Staker's position (1 true or 0 false)
	}

	struct Pot {
		uint T;
		uint F;
	}

	////////////////////// MAPPINGS AND ARRAYS //////////////////////

	mapping(uint => Statement) public statements;
	mapping(uint => Pot) private pots;
	mapping(address => uint) public beneficiaryShares;

	address[] public beneficiaryAddresses;

	////////////////////// STATE VARIABLES //////////////////////

	// Information Trackers
	uint public absNumStatements;
	uint public absNumStakes;
	uint public absEthStaked;

	// Logistics
	uint pctTimeRemainingThreshold;

	uint minTimeAddPct;
	uint maxTimeAddPct;

	uint minPotPctThreshold;
	uint maxPotPctThreshold;

	address private owner;
	uint public serviceFeeTenThousandths; // int range [0, 10000] to accomodate precision of ten-thosaundths. eg. 1.25% is represented as 125

	////////////////////// EVENTS //////////////////////

    // Events that will be emitted on changes.
    event NewStake(uint statementID, uint amount);
    event StakeEnded(uint statementID, uint TruePotFinal, uint FalsePotFinal, uint winningPosition, uint numStakes);
    event CurrentPot(uint statementID, uint totalPot);
   	event NewStatement(uint statementID, string statement, uint stakeEndTime, string source);

	// Constructor executes once when contract is created
	constructor () public {
		owner = msg.sender;
		pctTimeRemainingThreshold = 20;

		minTimeAddPct = 0;
		maxTimeAddPct = 40;

		minPotPctThreshold = 20;
		maxPotPctThreshold = 180;
	}

	////////////////////// MODIFIERS //////////////////////
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

	////////////////////// FUNCTIONS //////////////////////

	function newStatement(string _statement, uint _position, uint _stakeDuration, string _source) public payable returns(uint statementID) {
		/**
		* creates a new statement with an initial stake
		*/

		require(bytes(_statement).length > 0, "requires bytes(statement) > 0. Possibly empty string given.");
		require(msg.value > 0, "Insufficient stake value.");
		require(_position == 0 || _position == 1, "Invalid position to stake on."); 
		require(_stakeDuration > 60 && _stakeDuration < 315360000, "Stake duration must be at least 60 seconds and less than 10 years.");

		uint stakeEndTime = now.add(_stakeDuration);

		statementID = absNumStatements++; //sets statementID and THEN increases absNumStatements by 1
		statements[statementID] = Statement(statementID, _statement, _stakeDuration, now, stakeEndTime, msg.sender, 0, 0, false, _source, 3);

		emit NewStatement(statementID, _statement, stakeEndTime, _source);

		stake(statementID, _position);

	}


	function stake(uint _statementID, uint _position) public payable { 
		/**
		* Stakes an amount of ethereum on a statement
		*/

	    // Revert the call if the staking period is over or if insufficient value transacted
		require(msg.value > 0, "Insufficient stake value.");
		require(_position == 0 || _position == 1, "Invalid position to stake on."); 
		require(_statementID < absNumStatements && _statementID >= 0, "Invalid Statement ID.");

		Statement storage s = statements[_statementID];
		require(now <= s.stakeEndTime, "Stake already ended for this statement.");

		// Map Stake with statement AND THEN add one to numStakes
		s.stakes[s.numStakes++] = Stake({addr:msg.sender, amount:msg.value, position:_position});

		// If it is near the end of the stake and someone stakes a large amount, time is added.
		uint pctTimeRemaining = 100 * s.stakeEndTime.sub(now) / s.stakeDuration;

		if (pctTimeRemaining <= pctTimeRemainingThreshold) {

		    uint percentOfCurrentPot = 100 * msg.value / s.ethStaked;
		    
		    if (percentOfCurrentPot > minPotPctThreshold) {
		        
    			// extraTime = stakeDuration * size of stake * time added per stake size ratio. More generally, extraTime = stakeDuration * x * slope
    			uint extraTimeRaw = s.stakeDuration * (percentOfCurrentPot.sub(minPotPctThreshold)) * (maxTimeAddPct.sub(minTimeAddPct)) / (maxPotPctThreshold.sub(minPotPctThreshold)) / 100;
    
    			// Cap the amount of extra time added.
    			uint extraTime = Math.min(extraTimeRaw, s.stakeDuration * maxTimeAddPct / 100);
    
    			// Add time to the stake
    			s.stakeEndTime += extraTime;

		    }
		}

		// Update Statement value
		s.ethStaked += msg.value;
		emit NewStake(_statementID, msg.value);

		// Add to global trackers
		absNumStakes++;
		absEthStaked += msg.value;

		// Add the stake to total pot
		addToPot(msg.value, _position, _statementID);

	}

	function addToPot(uint _amount, uint _position, uint _statementID) private {
		/**
		* Private function keeps track of pots
		*/

		Pot storage p = pots[_statementID];

		if (_position == 1) {
			p.T += _amount;
		}
		else {
			p.F += _amount;
		}

		emit CurrentPot(_statementID, p.T.add(p.F));

	}

	function endStake(uint _statementID) public {
		/**
		* End the stake. Only callable after stake end time.
		*/

		Statement storage s = statements[_statementID];

		// 1. Conditions
		// Require that sufficient time has passed and endStake has not already been called
		require(_statementID < absNumStatements, "Invalid statementID");
		require(now >= s.stakeEndTime, "There is still staking time remaining.");
		require(!s.stakeEnded, "endStake has already been called.");

		// 2. Effects
		s.stakeEnded = true; 

		// 3. Interactions
		// distribute pot between winners, proportional to their stake
		distribute(_statementID);
	}

	function distribute(uint _statementID) private {
		/**
		* This function distributes all rewards to the winners for this statement
		*/

		uint profit;
		uint reward; 
		uint winningPot;
		uint losingPot;
		uint winningPosition;

		Statement storage s = statements[_statementID];
		Pot storage p = pots[_statementID];

		if (p.T >= p.F) {
			winningPot = p.T;
			losingPot = p.F;
			winningPosition = 1;
			s.verdict = 1;
		}
		else {
			winningPot = p.F;
			losingPot = p.T;
			winningPosition = 0;
			s.verdict = 0;
		}

		// Emit the total pot value and winning position at end of stake
		emit StakeEnded(_statementID,  p.T, p.F, winningPosition, s.numStakes);

		// Platform Service Fee
		uint fee = losingPot.mul(serviceFeeTenThousandths) / 10000;
		uint potRemaining = losingPot.sub(fee);

		// Beneficiaries 
		for (uint i = 0; i < beneficiaryAddresses.length; i++) {
			address beneficiary = beneficiaryAddresses[i];
			beneficiary.transfer(losingPot.mul(beneficiaryShares[beneficiary]) / 10000);
			potRemaining -= losingPot.mul(beneficiaryShares[beneficiary]) / 10000;
		}

		// Reward marketMaker for submitting the statement
		uint marketMakerReward = potRemaining.mul(s.stakes[0].amount) / winningPot.add(potRemaining);

		s.stakes[0].addr.transfer(marketMakerReward);

		potRemaining -= marketMakerReward;

		// Stakers Rewards
		for (uint j = 0; j < s.numStakes; j++) {

			// If the staker's position matched the majority, they receive their original stake + proportion of loser's stakes
			if (s.stakes[j].position == winningPosition) {

				// Calculate profit for correct staker
				profit = potRemaining.mul(s.stakes[j].amount) / winningPot;

				// Their reward is original stake + profit
				reward = profit.add(s.stakes[j].amount);

				// Send the winner their reward
				s.stakes[j].addr.transfer(reward);

			}

		}

		owner.transfer(fee);

	}

	function setServiceFeeTenThousandths(uint _newServiceFeeTenThousandths) public onlyOwner {
	/**
	* _newServiceFeeTenThousandths should be desired fee percentage * 100.
	* e.g. if service fee of 1.75% is desired, _newServiceFeeTenThousandths = 175
	*/	
		require(_newServiceFeeTenThousandths >= 0, 'Service Fee cannot be less than 0%.');
		require(_newServiceFeeTenThousandths <= 10000, 'Service Fee cannot be greater than 100%.');
		serviceFeeTenThousandths = _newServiceFeeTenThousandths;
	}

	function addBeneficiary(address _beneficiaryAddress, uint _beneficiaryShareTenThousandths) public onlyOwner {
		/**
		* _potProportionTenThousandths should be desired percentage * 100.
		* e.g. if a pot cut of 0.35% is desired, _potProportionTenThousandths = 35
		*/
		require(_beneficiaryShareTenThousandths >= 0, 'Beneficiary cut cannot be less than 0%.');
		require(_beneficiaryShareTenThousandths <= 10000, 'Beneficiary cut cannot be greater than 100%.');
		beneficiaryAddresses.push(_beneficiaryAddress);
		beneficiaryShares[_beneficiaryAddress] = _beneficiaryShareTenThousandths;
	}

	function removeBeneficiary(uint _index, address _beneficiaryAddress) public onlyOwner {
		/**
		* Remove a beneficiary
		*/
		require(beneficiaryAddresses.length > 0, 'There are no beneficiaries to remove.');
		require(_beneficiaryAddress == beneficiaryAddresses[_index], "The beneficiary address must match beneficiaryAddresses[index].");

		beneficiaryShares[_beneficiaryAddress] = 0; // set beneficiary shares to 0
		delete beneficiaryAddresses[_index]; // remove the beneficiary
		beneficiaryAddresses[_index] = beneficiaryAddresses[beneficiaryAddresses.length - 1]; // replace the empty spot with most recently added
		delete beneficiaryAddresses[beneficiaryAddresses.length - 1]; // delete the redundant copy
	}

	function setAddTimeParameters(uint _newPctTimeRemainingThreshold, 
								  uint _newMinTimeAddPct, 
								  uint _newMaxTimeAddPct, 
								  uint _newMinPotPctThreshold, 
								  uint _newMaxPotPctThreshold )
								  public onlyOwner {
		/**
		* The time addition function is a linear function defined by 2 points (i.e. 4 coordinates)
		* extraTime = stakeDuration * x * slope
		* The pctTimeRemainingThreshold sets the time limit where the function becomes active. 
		*/
		pctTimeRemainingThreshold = _newPctTimeRemainingThreshold;
		minTimeAddPct = _newMinTimeAddPct;
		maxTimeAddPct = _newMaxTimeAddPct;
		minPotPctThreshold = _newMinPotPctThreshold;
		maxPotPctThreshold = _newMaxPotPctThreshold;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	function SELF_DESTRUCT(bytes _confirm) public onlyOwner {
			
		if (keccak256(_confirm) == keccak256('Yes, I really want to destroy this contract forever.')) {
			selfdestruct(owner);
		}

	}

}