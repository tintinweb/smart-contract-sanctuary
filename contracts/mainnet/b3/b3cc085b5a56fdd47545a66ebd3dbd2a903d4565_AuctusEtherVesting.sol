pragma solidity ^0.4.21;


library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(a <= c);
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(a >= b);
		return a - b;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}
}


contract AuctusStepVesting {
	using SafeMath for uint256;

	address public beneficiary;
	uint256 public start;
	uint256 public cliff;
	uint256 public steps;

	uint256 public releasedSteps;
	uint256 public releasedAmount;
	uint256 public remainingAmount;

	event Released(uint256 step, uint256 amount);

	/**
	* @dev Creates a vesting contract that vests its balance to the _beneficiary
	* The amount is released gradually in steps
	* @param _beneficiary address of the beneficiary to whom vested are transferred
	* @param _start unix time that starts to apply the vesting rules
	* @param _cliff duration in seconds of the cliff in which will begin to vest and between the steps
	* @param _steps total number of steps to release all the balance
	*/
	function AuctusStepVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _steps) public {
		require(_beneficiary != address(0));
		require(_steps > 0);
		require(_cliff > 0);

		beneficiary = _beneficiary;
		cliff = _cliff;
		start = _start;
		steps = _steps;
	}

	function transfer(uint256 amount) internal;

	/**
	* @notice Transfers vested tokens to beneficiary.
	*/
	function release() public {
		uint256 unreleased = getAllowedStepAmount();

		require(unreleased > 0);

		releasedAmount = releasedAmount.add(unreleased);
		remainingAmount = remainingAmount.sub(unreleased);
		if (remainingAmount == 0) {
			releasedSteps = steps;
		} else {
			releasedSteps = releasedSteps + 1;
		}

		transfer(unreleased);

		emit Released(releasedSteps, unreleased);
	}

	function getAllowedStepAmount() public view returns (uint256) {
		if (remainingAmount == 0) {
			return 0;
		} else if (now < start) {
			return 0;
		} else {
			uint256 secondsFromTheBeginning = now.sub(start);
			if (secondsFromTheBeginning < cliff) {
				return 0;
			} else {
				uint256 stepsAllowed = secondsFromTheBeginning.div(cliff);
				if (stepsAllowed >= steps) {
					return remainingAmount;
				} else if (releasedSteps == stepsAllowed) {
					return 0;
				} else {
					return totalControlledBalance().div(steps);
				}
			}
		}
	}

	function totalControlledBalance() public view returns (uint256) {
		return remainingAmount.add(releasedAmount);
	}
}


contract AuctusEtherVesting is AuctusStepVesting {
	function AuctusEtherVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _steps) 
		public 
		AuctusStepVesting(_beneficiary, _start, _cliff, _steps) 
	{
	}

	function transfer(uint256 amount) internal {
		beneficiary.transfer(amount);
	}

	function () payable public {
		remainingAmount = remainingAmount.add(msg.value);
	}
}


contract AuctusToken {
	function transfer(address to, uint256 value) public returns (bool);
}


contract ContractReceiver {
	function tokenFallback(address from, uint256 value, bytes data) public;
}


contract AuctusTokenVesting is AuctusStepVesting, ContractReceiver {
	address public auctusTokenAddress = 0xc12d099be31567add4e4e4d0D45691C3F58f5663;

	function AuctusTokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _steps) 
		public 
		AuctusStepVesting(_beneficiary, _start, _cliff, _steps) 
	{
	}

	function transfer(uint256 amount) internal {
		assert(AuctusToken(auctusTokenAddress).transfer(beneficiary, amount));
	}

	function tokenFallback(address from, uint256 value, bytes) public {
		require(msg.sender == auctusTokenAddress);
		remainingAmount = remainingAmount.add(value);
	}
}