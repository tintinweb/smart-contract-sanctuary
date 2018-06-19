pragma solidity ^0.4.2;

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	function changeOwner(address newOwner) onlyOwner {
		owner = newOwner;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}
contract CSToken is owned {uint8 public decimals;function mintToken(address target, uint256 mintedAmount, uint agingTime);function addAgingTimesForPool(address poolAddress, uint agingTime);}

contract KICKICOCrowdsale is owned {
	uint[] public preIcoStagePeriod;

	uint[] public IcoStagePeriod;

	bool public PreIcoClosedManually = false;

	bool public IcoClosedManually = false;

	uint[] public thresholdsByState;

	uint public totalCollected = 0;

	uint public allowedForWithdrawn = 0;

	uint[] public prices;

	uint[] public bonuses;

	address public prPool;

	address public founders;

	address public advisory;

	address public bounties;

	address public lottery;

	address public seedInvestors;

	uint public tokensRaised;

	uint[] public etherRaisedByState;

	uint tokenMultiplier = 10;

	CSToken public tokenReward;

	mapping (address => uint256) public balanceOf;

	event FundTransfer(address backer, uint amount, bool isContribution);

	uint[] public agingTimeByStage;

	bool parametersHaveBeenSet = false;

	function KICKICOCrowdsale(address _tokenAddress, address _prPool, address _founders, address _advisory, address _bounties, address _lottery, address _seedInvestors) {
		tokenReward = CSToken(_tokenAddress);

		tokenMultiplier = tokenMultiplier ** tokenReward.decimals();

		// bind pools
		prPool = _prPool;
		founders = _founders;
		advisory = _advisory;
		bounties = _bounties;
		lottery = _lottery;
		seedInvestors = _seedInvestors;
	}

	function setParams() onlyOwner {
		require(!parametersHaveBeenSet);

		parametersHaveBeenSet = true;

		tokenReward.addAgingTimesForPool(prPool, 1513242000);
		tokenReward.addAgingTimesForPool(advisory, 1507366800);
		tokenReward.addAgingTimesForPool(bounties, 1509526800);
		tokenReward.addAgingTimesForPool(lottery, 1512118800);
		tokenReward.addAgingTimesForPool(seedInvestors, 1506762000);

		// mint to pools
		tokenReward.mintToken(founders, 100000000 * tokenMultiplier, 1514797200);
		tokenReward.mintToken(advisory, 10000000 * tokenMultiplier, 0);
		tokenReward.mintToken(bounties, 25000000 * tokenMultiplier, 0);
		tokenReward.mintToken(lottery, 2000000 * tokenMultiplier, 0);
		tokenReward.mintToken(seedInvestors, 20000000 * tokenMultiplier, 0);
		tokenReward.mintToken(prPool, 23000000 * tokenMultiplier, 0);

		preIcoStagePeriod.push(1501246800);
		preIcoStagePeriod.push(1502744400);

		IcoStagePeriod.push(1504011600);
		IcoStagePeriod.push(1506718800);

		// bind maxs thresholds
		thresholdsByState.push(5000 ether);
		thresholdsByState.push(200000 ether);

		etherRaisedByState.push(0);
		etherRaisedByState.push(0);

		// bind aging time for each stages
		agingTimeByStage.push(1507366800);
		agingTimeByStage.push(1508058000);

		// bind prices
		prices.push(1666666);
		prices.push(3333333);

		bonuses.push(1990 finney);
		bonuses.push(2990 finney);
		bonuses.push(4990 finney);
		bonuses.push(6990 finney);
		bonuses.push(9500 finney);
		bonuses.push(14500 finney);
		bonuses.push(19500 finney);
		bonuses.push(29500 finney);
		bonuses.push(49500 finney);
		bonuses.push(74500 finney);
		bonuses.push(99 ether);
		bonuses.push(149 ether);
		bonuses.push(199 ether);
		bonuses.push(299 ether);
		bonuses.push(499 ether);
		bonuses.push(749 ether);
		bonuses.push(999 ether);
		bonuses.push(1499 ether);
		bonuses.push(1999 ether);
		bonuses.push(2999 ether);
		bonuses.push(4999 ether);
		bonuses.push(7499 ether);
		bonuses.push(9999 ether);
		bonuses.push(14999 ether);
		bonuses.push(19999 ether);
		bonuses.push(49999 ether);
		bonuses.push(99999 ether);
	}

	function mint(uint amount, uint tokens, address sender, uint currentStage) internal {
		balanceOf[sender] += amount;
		tokensRaised += tokens;
		etherRaisedByState[currentStage] += amount;
		totalCollected += amount;
		allowedForWithdrawn += amount;
		tokenReward.mintToken(sender, tokens, agingTimeByStage[currentStage]);
		tokenReward.mintToken(prPool, tokens * 10 / 100, 0);
	}

	function processPayment(address from, uint amount) internal {
		uint originalAmount = amount;
		FundTransfer(from, amount, true);
		uint currentStage = 0;
		if (now >= preIcoStagePeriod[0] && now < preIcoStagePeriod[1]) {
			currentStage = 0;
		}
		if (now >= IcoStagePeriod[0] && now < IcoStagePeriod[1]) {
			currentStage = 1;
		}

		uint price = prices[currentStage];
		uint coefficient = 1000;

		for (uint i = 0; i < 15; i++) {
			if (amount >= bonuses[i])
				coefficient = 1000 + ((i + 1 + (i > 11 ? 1 : 0)) * 5);
			if (amount < bonuses[i]) break;
		}
		if (coefficient == 1000) {
			for (uint z = 0; z < 12; z++) {
				if (amount >= bonuses[z + 15])
					coefficient = 1000 + ((8 + z) * 10);
				if (amount < bonuses[z]) break;
			}
		}

		price = price * 1000 / coefficient;

		uint remain = thresholdsByState[currentStage] - etherRaisedByState[currentStage];

		if (remain <= amount) {
			amount = remain;
		}

		uint tokenAmount = amount / price;

		uint currentAmount = tokenAmount * price;
		mint(currentAmount, tokenAmount, from, currentStage);
		uint change = originalAmount - currentAmount;
		if (change > 0) {
			if (from.send(change)) {
				FundTransfer(from, change, false);
			}
			else revert();
		}
	}

	function() payable {
		require(parametersHaveBeenSet);
		require(msg.value >= 50 finney);

		// validate by stage periods
		require((now >= preIcoStagePeriod[0] && now < preIcoStagePeriod[1]) || (now >= IcoStagePeriod[0] && now < IcoStagePeriod[1]));
		// validate if closed manually or reached the threshold
		if(now >= preIcoStagePeriod[0] && now < preIcoStagePeriod[1]) {
			require(!PreIcoClosedManually && etherRaisedByState[0] < thresholdsByState[0]);
		} else {
			require(!IcoClosedManually && etherRaisedByState[1] < thresholdsByState[1]);
		}
		processPayment(msg.sender, msg.value);
	}

	function closeCurrentStage() onlyOwner {
		if (now >= preIcoStagePeriod[0] && now < preIcoStagePeriod[1] && !PreIcoClosedManually) {
			PreIcoClosedManually = true;
		} else {
			if (now >= IcoStagePeriod[0] && now < IcoStagePeriod[1] && !IcoClosedManually) {
				IcoClosedManually = true;
			} else {
				revert();
			}
		}
	}

	function safeWithdrawal(uint amount) onlyOwner {
		require(allowedForWithdrawn >= amount);

		// lock withdraw if stage not closed
//		require((now >= preIcoStagePeriod[1] && now < IcoStagePeriod[0]) || (now >= IcoStagePeriod[1]));
		if(now >= preIcoStagePeriod[0] && now < preIcoStagePeriod[1])
			require(PreIcoClosedManually || etherRaisedByState[0] >= thresholdsByState[0]);
		if(now >= IcoStagePeriod[0] && now < IcoStagePeriod[1])
			require(IcoClosedManually || etherRaisedByState[1] >= thresholdsByState[1]);

		allowedForWithdrawn -= amount;
		if(owner.send(amount)) {
			FundTransfer(msg.sender, amount, false);
		} else {
			allowedForWithdrawn += amount;
		}
	}

	function kill() onlyOwner {
		require(now > IcoStagePeriod[1]);

		tokenReward.changeOwner(owner);
		selfdestruct(owner);
	}
}