pragma solidity 0.4.24;

contract InterbetCore {

	/* Global constants */
	uint constant oddsDecimals = 2; // Max. decimal places of odds
	uint constant feeRateDecimals = 1; // Max. decimal places of fee rate

	uint public minMakerBetFund = 100 * 1 finney; // Minimum fund of a maker bet

	uint public maxAllowedTakerBetsPerMakerBet = 100; // Limit the number of taker-bets in 1 maker-bet
	uint public minAllowedStakeInPercentage = 1; // 100 &#247; maxAllowedTakerBetsPerMakerBet

	uint public baseVerifierFee = 1 finney; // Ensure verifier has some minimal profit to cover their gas cost at least

	/* Owner and admins */
	address private owner;
	mapping(address => bool) private admins;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function changeOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function addAdmin(address addr) external onlyOwner {
		admins[addr] = true;
	}

	function removeAdmin(address addr) external onlyOwner {
		admins[addr] = false;
	}

	modifier onlyAdmin() {
		require(admins[msg.sender] == true);
		_;
	}

	function changeMinMakerBetFund(uint weis) external onlyAdmin {
		minMakerBetFund = mul(weis, 1 wei);
	}

	function changeAllowedTakerBetsPerMakerBet(uint maxCount, uint minPercentage) external onlyAdmin {
		maxAllowedTakerBetsPerMakerBet = maxCount;
		minAllowedStakeInPercentage = minPercentage;
	}

	function changeBaseVerifierFee(uint weis) external onlyAdmin {
		baseVerifierFee = mul(weis, 1 wei);
	}

	/* Events */
	event LogUpdateVerifier(address indexed addr, uint oldFeeRate, uint newFeeRate);
	event LogMakeBet(uint indexed makerBetId, address indexed maker);
	event LogAddFund(uint indexed makerBetId, address indexed maker, uint oldTotalFund, uint newTotalFund);
	event LogUpdateOdds(uint indexed makerBetId, address indexed maker, uint oldOdds, uint newOdds);
	event LogPauseBet(uint indexed makerBetId, address indexed maker);
	event LogReopenBet(uint indexed makerBetId, address indexed maker);
	event LogCloseBet(uint indexed makerBetId, address indexed maker);
	event LogTakeBet(uint indexed makerBetId, address indexed maker, uint indexed takerBetId, address taker);
	event LogSettleBet(uint indexed makerBetId, address indexed maker);
	event LogWithdraw(uint indexed makerBetId, address indexed maker, address indexed addr);

	/* Betting Core */
	enum BetStatus {
		Open, 
		Paused, 
		Closed, 
		Settled
	}

	enum BetOutcome {
		NotSettled,
		MakerWin,
		TakerWin,
		Draw,
		Canceled
	}

	struct MakerBet {
		uint makerBetId;
		address maker;
		uint odds;
		uint totalFund;
		Verifier trustedVerifier;
		uint expiry;
		BetStatus status;
		uint reservedFund;
		uint takerBetsCount;
		uint totalStake;
		TakerBet[] takerBets;
		BetOutcome outcome;
		bool makerFundWithdrawn;
		bool trustedVerifierFeeSent;
	}

	struct TakerBet {
		uint takerBetId;
		address taker;
		uint odds;
		uint stake;
        bool settled;
	}

	struct Verifier {
		address addr;
		uint feeRate;
	}

	uint public makerBetsCount;
	mapping(uint => mapping(address => MakerBet)) private makerBets;

	mapping(address => Verifier) private verifiers;

	constructor() public {
		owner = msg.sender;
		makerBetsCount = 0;
	}

	function () external payable {
		revert();
	}

	/// Update verifier&#39;s data
	function updateVerifier(uint feeRate) external {
		require(feeRate >= 0 && feeRate <= ((10 ** feeRateDecimals) * 100));

		Verifier storage verifier = verifiers[msg.sender];

		uint oldFeeRate = verifier.feeRate;

		verifier.addr = msg.sender;
		verifier.feeRate = feeRate;

		emit LogUpdateVerifier(msg.sender, oldFeeRate, feeRate);
	}

	/// Make a bet
	function makeBet(uint makerBetId, uint odds, address trustedVerifier, uint trustedVerifierFeeRate, uint expiry) external payable {
		uint fund = sub(msg.value, baseVerifierFee);

		require(fund >= minMakerBetFund);
		require(odds > (10 ** oddsDecimals) && odds < ((10 ** 8) * (10 ** oddsDecimals)));
		require(expiry > now);

        MakerBet storage makerBet = makerBets[makerBetId][msg.sender];

        require(makerBet.makerBetId == 0);

        Verifier memory verifier = verifiers[trustedVerifier];

        require(verifier.addr != address(0x0));
        require(trustedVerifierFeeRate == verifier.feeRate);

		makerBet.makerBetId = makerBetId;
		makerBet.maker = msg.sender;
		makerBet.odds = odds;
		makerBet.totalFund = fund;
		makerBet.trustedVerifier = Verifier(verifier.addr, verifier.feeRate);
		makerBet.expiry = expiry;
		makerBet.status = BetStatus.Open;
		makerBet.reservedFund = 0;
		makerBet.takerBetsCount = 0;
		makerBet.totalStake = 0;

		makerBetsCount++;

		emit LogMakeBet(makerBetId, msg.sender);
	}

	/// Increase total fund of a bet
    function addFund(uint makerBetId) external payable {
    	MakerBet storage makerBet = makerBets[makerBetId][msg.sender];
		require(makerBet.makerBetId != 0);

    	require(now < makerBet.expiry);

    	require(makerBet.status == BetStatus.Open || makerBet.status == BetStatus.Paused);

    	require(msg.sender == makerBet.maker);

		require(msg.value > 0);

		uint oldTotalFund = makerBet.totalFund;

    	makerBet.totalFund = add(makerBet.totalFund, msg.value);

    	emit LogAddFund(makerBetId, msg.sender, oldTotalFund, makerBet.totalFund);
    }

    /// Update odds of a bet
    function updateOdds(uint makerBetId, uint odds) external {
    	require(odds > (10 ** oddsDecimals) && odds < ((10 ** 8) * (10 ** oddsDecimals)));

		MakerBet storage makerBet = makerBets[makerBetId][msg.sender];
		require(makerBet.makerBetId != 0);

		require(now < makerBet.expiry);

    	require(makerBet.status == BetStatus.Open || makerBet.status == BetStatus.Paused);

    	require(msg.sender == makerBet.maker);

    	require(odds != makerBet.odds);

    	uint oldOdds = makerBet.odds;

    	makerBet.odds = odds;

    	emit LogUpdateOdds(makerBetId, msg.sender, oldOdds, makerBet.odds);
    }

    /// Pause a bet
    function pauseBet(uint makerBetId) external {
    	MakerBet storage makerBet = makerBets[makerBetId][msg.sender];
		require(makerBet.makerBetId != 0);

    	require(makerBet.status == BetStatus.Open);

    	require(msg.sender == makerBet.maker);

		makerBet.status = BetStatus.Paused;

		emit LogPauseBet(makerBetId, msg.sender);
    }

    /// Reopen a bet
    function reopenBet(uint makerBetId) external {
    	MakerBet storage makerBet = makerBets[makerBetId][msg.sender];
		require(makerBet.makerBetId != 0);

    	require(makerBet.status == BetStatus.Paused);

    	require(msg.sender == makerBet.maker);

		makerBet.status = BetStatus.Open;

		emit LogReopenBet(makerBetId, msg.sender);
    }

    /// Close a bet and withdraw unused fund
    function closeBet(uint makerBetId) external {
    	MakerBet storage makerBet = makerBets[makerBetId][msg.sender];
		require(makerBet.makerBetId != 0);

    	require(makerBet.status == BetStatus.Open || makerBet.status == BetStatus.Paused);

    	require(msg.sender == makerBet.maker);

		makerBet.status = BetStatus.Closed;

		// refund unused fund to maker
		uint unusedFund = sub(makerBet.totalFund, makerBet.reservedFund);

		if (unusedFund > 0) {
			makerBet.totalFund = makerBet.reservedFund;

			uint refundAmount = unusedFund;
			if (makerBet.totalStake == 0) {
				refundAmount = add(refundAmount, baseVerifierFee); // Refund base verifier fee too if no taker-bets, because verifier do not need to settle the bet with no takers
				makerBet.makerFundWithdrawn = true;
			}

			if (!makerBet.maker.send(refundAmount)) {
				makerBet.totalFund = add(makerBet.totalFund, unusedFund);
	            makerBet.status = BetStatus.Paused;
	            makerBet.makerFundWithdrawn = false;
	        } else {
	        	emit LogCloseBet(makerBetId, msg.sender);
	        }
		} else {
			emit LogCloseBet(makerBetId, msg.sender);
		}
    }

    /// Take a bet
	function takeBet(uint makerBetId, address maker, uint odds, uint takerBetId) external payable {
		require(msg.sender != maker);

		require(msg.value > 0);

		MakerBet storage makerBet = makerBets[makerBetId][maker];
		require(makerBet.makerBetId != 0);

		require(msg.sender != makerBet.trustedVerifier.addr);

		require(now < makerBet.expiry);

		require(makerBet.status == BetStatus.Open);

		require(makerBet.odds == odds);

		// Avoid too many taker-bets in one maker-bet
		require(makerBet.takerBetsCount < maxAllowedTakerBetsPerMakerBet);

		// Avoid too many tiny bets
		uint minAllowedStake = mul(mul(makerBet.totalFund, (10 ** oddsDecimals)), minAllowedStakeInPercentage) / sub(odds, (10 ** oddsDecimals)) / 100;
		uint maxAvailableStake = mul(sub(makerBet.totalFund, makerBet.reservedFund), (10 ** oddsDecimals)) / sub(odds, (10 ** oddsDecimals));
		if (maxAvailableStake >= minAllowedStake) {
			require(msg.value >= minAllowedStake);
		} else {
			require(msg.value >= sub(maxAvailableStake, (maxAvailableStake / 10)) && msg.value <= maxAvailableStake);
		}

        // If remaining fund is not enough, send the money back.
		require(msg.value <= maxAvailableStake);

        makerBet.takerBets.length++;
		makerBet.takerBets[makerBet.takerBetsCount] = TakerBet(takerBetId, msg.sender, odds, msg.value, false);
		makerBet.reservedFund = add(makerBet.reservedFund, mul(msg.value, sub(odds, (10 ** oddsDecimals))) / (10 ** oddsDecimals));   
		makerBet.totalStake = add(makerBet.totalStake, msg.value);
		makerBet.takerBetsCount++;

		emit LogTakeBet(makerBetId, maker, takerBetId, msg.sender);
	}

	/// Payout to maker
	function payMaker(MakerBet storage makerBet) private returns (bool fullyWithdrawn) {
		fullyWithdrawn = false;

		if (!makerBet.makerFundWithdrawn) {
			makerBet.makerFundWithdrawn = true;

			uint payout = 0;
			if (makerBet.outcome == BetOutcome.MakerWin) {
				uint trustedVerifierFeeMakerWin = mul(makerBet.totalStake, makerBet.trustedVerifier.feeRate) / ((10 ** feeRateDecimals) * 100);
				payout = sub(add(makerBet.totalFund, makerBet.totalStake), trustedVerifierFeeMakerWin);
			} else if (makerBet.outcome == BetOutcome.TakerWin) {
				payout = sub(makerBet.totalFund, makerBet.reservedFund);
			} else if (makerBet.outcome == BetOutcome.Draw || makerBet.outcome == BetOutcome.Canceled) {
				payout = makerBet.totalFund;
			}

			if (payout > 0) {
				fullyWithdrawn = true;

				if (!makerBet.maker.send(payout)) {
	                makerBet.makerFundWithdrawn = false;
	                fullyWithdrawn = false;
	            }
	        }
        }

        return fullyWithdrawn;
	}

	/// Payout to taker
	function payTaker(MakerBet storage makerBet, address taker) private returns (bool fullyWithdrawn) {
		fullyWithdrawn = false;

		uint payout = 0;

		for (uint betIndex = 0; betIndex < makerBet.takerBetsCount; betIndex++) {
			if (makerBet.takerBets[betIndex].taker == taker) {
				if (!makerBet.takerBets[betIndex].settled) {
					makerBet.takerBets[betIndex].settled = true;

					if (makerBet.outcome == BetOutcome.MakerWin) {
						continue;
					} else if (makerBet.outcome == BetOutcome.TakerWin) {
						uint netProfit = mul(mul(makerBet.takerBets[betIndex].stake, sub(makerBet.takerBets[betIndex].odds, (10 ** oddsDecimals))), sub(((10 ** feeRateDecimals) * 100), makerBet.trustedVerifier.feeRate)) / (10 ** oddsDecimals) / ((10 ** feeRateDecimals) * 100);
						payout = add(payout, add(makerBet.takerBets[betIndex].stake, netProfit));
					} else if (makerBet.outcome == BetOutcome.Draw || makerBet.outcome == BetOutcome.Canceled) {
						payout = add(payout, makerBet.takerBets[betIndex].stake);
					}
				}
			}
		}

		if (payout > 0) {
			fullyWithdrawn = true;

			if (!taker.send(payout)) {
				fullyWithdrawn = false;

				for (uint betIndex2 = 0; betIndex2 < makerBet.takerBetsCount; betIndex2++) {
					if (makerBet.takerBets[betIndex2].taker == taker) {
						if (makerBet.takerBets[betIndex2].settled) {
							makerBet.takerBets[betIndex2].settled = false;
						}
					}
				}
            }
        }

		return fullyWithdrawn;
	}

	/// Payout to verifier
	function payVerifier(MakerBet storage makerBet) private returns (bool fullyWithdrawn) {
		fullyWithdrawn = false;

		if (!makerBet.trustedVerifierFeeSent) {
	    	makerBet.trustedVerifierFeeSent = true;

	    	uint payout = 0;
			if (makerBet.outcome == BetOutcome.MakerWin) {
				uint trustedVerifierFeeMakerWin = mul(makerBet.totalStake, makerBet.trustedVerifier.feeRate) / ((10 ** feeRateDecimals) * 100);
				payout = add(baseVerifierFee, trustedVerifierFeeMakerWin);
			} else if (makerBet.outcome == BetOutcome.TakerWin) {
				uint trustedVerifierFeeTakerWin = mul(makerBet.reservedFund, makerBet.trustedVerifier.feeRate) / ((10 ** feeRateDecimals) * 100);
				payout = add(baseVerifierFee, trustedVerifierFeeTakerWin);
			} else if (makerBet.outcome == BetOutcome.Draw || makerBet.outcome == BetOutcome.Canceled) {
				payout = baseVerifierFee;
			}

			if (payout > 0) {
				fullyWithdrawn = true;

		    	if (!makerBet.trustedVerifier.addr.send(payout)) {
		    		makerBet.trustedVerifierFeeSent = false;
		    		fullyWithdrawn = false;
		    	}
	    	}
	    }

	    return fullyWithdrawn;
	}

	/// Settle a bet by trusted verifier
	function settleBet(uint makerBetId, address maker, uint outcome) external {
		require(outcome == 1 || outcome == 2 || outcome == 3 || outcome == 4);

		MakerBet storage makerBet = makerBets[makerBetId][maker];
		require(makerBet.makerBetId != 0);

		require(msg.sender == makerBet.trustedVerifier.addr);

		require(makerBet.totalStake > 0);

		require(makerBet.status != BetStatus.Settled);

		BetOutcome betOutcome = BetOutcome(outcome);
		makerBet.outcome = betOutcome;
		makerBet.status = BetStatus.Settled;

		payMaker(makerBet);
		payVerifier(makerBet);

		emit LogSettleBet(makerBetId, maker);
	}

	/// Manual withdraw fund from a bet after outcome is set
	function withdraw(uint makerBetId, address maker) external {
		MakerBet storage makerBet = makerBets[makerBetId][maker];
		require(makerBet.makerBetId != 0);

		require(makerBet.outcome != BetOutcome.NotSettled);

		require(makerBet.status == BetStatus.Settled);

		bool fullyWithdrawn = false;

		if (msg.sender == maker) {
			fullyWithdrawn = payMaker(makerBet);
		} else if (msg.sender == makerBet.trustedVerifier.addr) {
			fullyWithdrawn = payVerifier(makerBet);
		} else {
			fullyWithdrawn = payTaker(makerBet, msg.sender);
		}

		if (fullyWithdrawn) {
			emit LogWithdraw(makerBetId, maker, msg.sender);
		}
	}

    /* External views */
    function getOwner() external view returns(address) {
        return owner;
    }

    function isAdmin(address addr) external view returns(bool) {
        return admins[addr];
    }

    function getVerifier(address addr) external view returns(address, uint) {
    	Verifier memory verifier = verifiers[addr];
    	return (verifier.addr, verifier.feeRate);
    }

    function getMakerBetBasicInfo(uint makerBetId, address maker) external view returns(uint, address, address, uint, uint) {
    	MakerBet memory makerBet = makerBets[makerBetId][maker];
    	return (makerBet.makerBetId, makerBet.maker, makerBet.trustedVerifier.addr, makerBet.trustedVerifier.feeRate, makerBet.expiry);
    }

    function getMakerBetDetails(uint makerBetId, address maker) external view returns(uint, BetStatus, uint, uint, uint, uint, uint, BetOutcome, bool, bool) {
		MakerBet memory makerBet = makerBets[makerBetId][maker];
    	return (makerBet.makerBetId, makerBet.status, makerBet.odds, makerBet.totalFund, makerBet.reservedFund, makerBet.takerBetsCount, makerBet.totalStake, makerBet.outcome, makerBet.makerFundWithdrawn, makerBet.trustedVerifierFeeSent);
    }

    function getTakerBet(uint makerBetId, address maker, uint takerBetId, address taker) external view returns(uint, address, uint, uint, bool) {
    	MakerBet memory makerBet = makerBets[makerBetId][maker];
    	for (uint betIndex = 0; betIndex < makerBet.takerBetsCount; betIndex++) {
			TakerBet memory takerBet = makerBet.takerBets[betIndex];

			if (takerBet.takerBetId == takerBetId && takerBet.taker == taker) {
				return (takerBet.takerBetId, takerBet.taker, takerBet.odds, takerBet.stake, takerBet.settled);
			}
		}
    }

	/* Math utilities */
	function mul(uint256 _a, uint256 _b) private pure returns(uint256 c) {
	    if (_a == 0) {
	      return 0;
	    }

	    c = _a * _b;
	    assert(c / _a == _b);
	    return c;
  	}

  	function sub(uint256 _a, uint256 _b) private pure returns(uint256) {
    	assert(_b <= _a);
    	return _a - _b;
  	}

  	function add(uint256 _a, uint256 _b) private pure returns(uint256 c) {
   		c = _a + _b;
    	assert(c >= _a);
    	return c;
  	}

}