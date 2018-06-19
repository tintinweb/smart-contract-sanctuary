pragma solidity ^0.4.2;


contract owned {
	address public owner;
	address public server;

	function owned() {
		owner = msg.sender;
		server = msg.sender;
	}

	function changeOwner(address newOwner) onlyOwner {
		owner = newOwner;
	}

	function changeServer(address newServer) onlyOwner {
		server = newServer;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier onlyServer {
		require(msg.sender == server);
		_;
	}
}


contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}


contract CSToken is owned {uint8 public decimals;

	uint[] public agingTimes;

	address[] public addressByIndex;

	function balanceOf(address _owner) constant returns (uint256 balance);

	function mintToken(address target, uint256 mintedAmount, uint agingTime);

	function addAgingTime(uint time);

	function allAgingTimesAdded();

	function addAgingTimesForPool(address poolAddress, uint agingTime);

	function countAddresses() constant returns (uint256 length);
}


contract KickicoCrowdsale is owned {
	uint[] public IcoStagePeriod;

	bool public IcoClosedManually = false;

	uint public threshold = 200000 ether;
	uint public goal = 50000 ether;

	uint public totalCollected = 0;

	uint public pricePerTokenInWei = 3333333;

	uint public agingTime = 1539594000;

	uint prPoolAgingTime = 1513242000;

	uint advisoryPoolAgingTime = 1535533200;

	uint bountiesPoolAgingTime = 1510736400;

	uint lotteryPoolAgingTime = 1512118800;

	uint angelInvestorsPoolAgingTime = 1506848400;

	uint foundersPoolAgingTime = 1535533200;

	uint chinaPoolAgingTime = 1509526800;

	uint[] public bonuses;

	uint[] public bonusesAfterClose;

	address public prPool;

	address public founders;

	address public advisory;

	address public bounties;

	address public lottery;

	address public angelInvestors;

	address public china;

	uint tokenMultiplier = 10;

	CSToken public tokenReward;
	CSToken public oldTokenReward;

	mapping (address => uint256) public balanceOf;

	event FundTransfer(address backer, uint amount, bool isContribution);

	bool parametersHaveBeenSet = false;

	function KickicoCrowdsale(address _tokenAddress, address _prPool, address _founders, address _advisory, address _bounties, address _lottery, address _angelInvestors, address _china, address _oldTokenAddress) {
		tokenReward = CSToken(_tokenAddress);
		oldTokenReward = CSToken(_oldTokenAddress);

		tokenMultiplier = tokenMultiplier ** tokenReward.decimals();

		// bind pools
		prPool = _prPool;
		founders = _founders;
		advisory = _advisory;
		bounties = _bounties;
		lottery = _lottery;
		angelInvestors = _angelInvestors;
		china = _china;
	}

	function setParams() onlyOwner {
		require(!parametersHaveBeenSet);

		parametersHaveBeenSet = true;

		tokenReward.addAgingTimesForPool(prPool, prPoolAgingTime);
		tokenReward.addAgingTimesForPool(advisory, advisoryPoolAgingTime);
		tokenReward.addAgingTimesForPool(bounties, bountiesPoolAgingTime);
		tokenReward.addAgingTimesForPool(lottery, lotteryPoolAgingTime);
		tokenReward.addAgingTimesForPool(angelInvestors, angelInvestorsPoolAgingTime);

		// mint to pools
		tokenReward.mintToken(advisory, 10000000 * tokenMultiplier, 0);
		tokenReward.mintToken(bounties, 25000000 * tokenMultiplier, 0);
		tokenReward.mintToken(lottery, 1000000 * tokenMultiplier, 0);
		tokenReward.mintToken(angelInvestors, 30000000 * tokenMultiplier, 0);
		tokenReward.mintToken(prPool, 23000000 * tokenMultiplier, 0);
		tokenReward.mintToken(china, 8000000 * tokenMultiplier, 0);

		tokenReward.addAgingTime(agingTime);
		tokenReward.addAgingTime(prPoolAgingTime);
		tokenReward.addAgingTime(advisoryPoolAgingTime);
		tokenReward.addAgingTime(bountiesPoolAgingTime);
		tokenReward.addAgingTime(lotteryPoolAgingTime);
		tokenReward.addAgingTime(angelInvestorsPoolAgingTime);
		tokenReward.addAgingTime(foundersPoolAgingTime);
		tokenReward.addAgingTime(chinaPoolAgingTime);
		tokenReward.allAgingTimesAdded();

		IcoStagePeriod.push(1504011600);
		IcoStagePeriod.push(1506718800);

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

		bonusesAfterClose.push(200);
		bonusesAfterClose.push(100);
		bonusesAfterClose.push(75);
		bonusesAfterClose.push(50);
		bonusesAfterClose.push(25);
	}

	function mint(uint amount, uint tokens, address sender) internal {
		balanceOf[sender] += amount;
		totalCollected += amount;
		tokenReward.mintToken(sender, tokens, agingTime);
		tokenReward.mintToken(founders, tokens / 10, foundersPoolAgingTime);
	}

	function contractBalance() constant returns (uint256 balance) {
		return this.balance;
	}

	function processPayment(address from, uint amount, bool isCustom) internal {
		if(!isCustom)
		FundTransfer(from, amount, true);
		uint original = amount;

		uint _price = pricePerTokenInWei;
		uint remain = threshold - totalCollected;
		if (remain < amount) {
			amount = remain;
		}

		for (uint i = 0; i < bonuses.length; i++) {
			if (amount < bonuses[i]) break;

			if (amount >= bonuses[i] && (i == bonuses.length - 1 || amount < bonuses[i + 1])) {
				if (i < 15) {
					_price = _price * 1000 / (1000 + ((i + 1 + (i > 11 ? 1 : 0)) * 5));
				}
				else {
					_price = _price * 1000 / (1000 + ((8 + i - 14) * 10));
				}
			}
		}

		uint tokenAmount = amount / _price;
		uint currentAmount = tokenAmount * _price;
		mint(currentAmount, tokenAmount + tokenAmount * getBonusByRaised() / 1000, from);
		uint change = original - currentAmount;
		if (change > 0 && !isCustom) {
			if (from.send(change)) {
				FundTransfer(from, change, false);
			}
			else revert();
		}
	}

	function getBonusByRaised() internal returns (uint256) {
		uint raisedInPercent = totalCollected * 100 / goal;
		if (raisedInPercent > 50) return 0;
		for (uint i = 0; i < bonusesAfterClose.length; i++) {
			if (i * 10 <= raisedInPercent && (i + 1) * 10 > raisedInPercent) {
				return bonusesAfterClose[i];
			}
		}
		return 0;
	}

	function closeICO() onlyOwner {
		require(now >= IcoStagePeriod[0] && now < IcoStagePeriod[1] && !IcoClosedManually);
		IcoClosedManually = true;
	}

	function safeWithdrawal(uint amount) onlyOwner {
		require(this.balance >= amount);

		// lock withdraw if stage not closed
		if (now >= IcoStagePeriod[0] && now < IcoStagePeriod[1])
		require(IcoClosedManually || isReachedThreshold());

		if (owner.send(amount)) {
			FundTransfer(msg.sender, amount, false);
		}
	}

	function isReachedThreshold() internal returns (bool reached) {
		return pricePerTokenInWei > (threshold - totalCollected);
	}

	function isIcoClosed() constant returns (bool closed) {
		return (now >= IcoStagePeriod[1] || IcoClosedManually || isReachedThreshold());
	}

	function customPayment(address _recipient, uint256 _amount) onlyServer {
		require(parametersHaveBeenSet);
		require(_amount >= 10 finney);

		// validate by stage periods
		require(now >= IcoStagePeriod[0] && now < IcoStagePeriod[1]);
		// validate if closed manually or reached the threshold
		require(!IcoClosedManually);
		require(!isReachedThreshold());
		processPayment(_recipient, _amount, true);
	}

	bool public allowManuallyMintTokens = true;
	function mintTokens(address[] recipients) onlyServer {
		require(allowManuallyMintTokens);
		for(uint i = 0; i < recipients.length; i++) {
			tokenReward.mintToken(recipients[i], oldTokenReward.balanceOf(recipients[i]), 1538902800);
		}
	}

	function disableManuallyMintTokens() onlyOwner {
		allowManuallyMintTokens = false;
	}

	function() payable {
		require(parametersHaveBeenSet);
		require(msg.value >= 50 finney);

		// validate by stage periods
		require(now >= IcoStagePeriod[0] && now < IcoStagePeriod[1]);
		// validate if closed manually or reached the threshold
		require(!IcoClosedManually);
		require(!isReachedThreshold());

		processPayment(msg.sender, msg.value, false);
	}

	function changeTokenOwner(address _owner) onlyOwner {
		tokenReward.changeOwner(_owner);
	}

	function kill() onlyOwner {
		require(isIcoClosed());
		if(this.balance > 0) {
			owner.transfer(this.balance);
		}
		changeTokenOwner(owner);
		selfdestruct(owner);
	}
}