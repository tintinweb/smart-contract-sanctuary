pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
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

interface AmtDiviesInterface {
    function receiveEth(uint roundId) external payable;
}

contract Gambling {
	using SafeMath for uint256;

	struct roundStruct {
		uint curKeyNo;
		uint jackPot;
		uint bonusPot;
		uint winnerPot;
		uint luckyPot;
		uint amtPot;
		uint start;
		uint end;
		bool ended;
	}
	struct keyStruct {
		uint no;
		uint curNo;
	}
	uint initialKeyPrice = 1000000000;
	uint dividedKeyNo = 100;
	uint duration = 600;
	uint addedTime = 120;
	uint curRoundId;
	address feeAddress = 0x70Fa3a5a5F92934593f5884f67A0EBa546F8385e;
	AmtDiviesInterface amtDivies = AmtDiviesInterface(0xb3570834C9d9F67c7928De37e1B73e4bfB2bfd5d);
	mapping (uint => roundStruct) rounds;
	mapping (uint => mapping (address => keyStruct[])) roundPlayers;
	mapping (uint => mapping (address => uint[])) roundPlayerKeys;

	event Started(uint curRoundId);
	event Ended(uint roundId, bool ended);
	event DivideToAmToken(uint roundId, uint amtPot);
	event EthAmount(uint roundId, uint ethAmount);
	event WithDrawCompleted(uint roundId, uint jackDrawAmount, uint bonusDrawAmount, uint winnerDrawAmount);
	event revokeCompleted(uint roundId, uint revokeAmount);

	function getRoundStart(uint roundId) public view returns(uint) {
		return rounds[roundId].start;
	}

	function getRoundEnd(uint roundId) public view returns(uint) {
		return rounds[roundId].end;
	}

	function getRoundCurKeyNo(uint roundId) public view returns(uint) {
		return rounds[roundId].curKeyNo;
	}

	function getRoundJackPot(uint roundId) public view returns(uint) {
		return rounds[roundId].jackPot;
	}

	function getRoundBonusPot(uint roundId) public view returns(uint) {
		return rounds[roundId].bonusPot;
	}

	function getRoundWinnerPot(uint roundId) public view returns(uint) {
		return rounds[roundId].winnerPot;
	}

	function getRoundLuckyPot(uint roundId) public view returns(uint) {
		return rounds[roundId].luckyPot;
	}

	function getRoundAmtPot(uint roundId) public view returns(uint) {
		return rounds[roundId].amtPot;
	}

	function getRoundKeyPrice(uint roundId) public view returns(uint) {
		if (rounds[roundId].curKeyNo.add(1) < dividedKeyNo) {
			return initialKeyPrice;
		} else {
			return rounds[roundId].curKeyNo.add(1).mul(initialKeyPrice);
		}
	}

	function getRoundPlayerKeys(uint roundId) public view returns(uint[]) {
		return roundPlayerKeys[roundId][msg.sender];
	}

	function isRoundEnded(uint roundId) public view returns(bool) {
		return rounds[roundId].ended;
	}

	function startRound() public payable returns(uint) {
		curRoundId++;
		rounds[curRoundId].start = now;
		rounds[curRoundId].end = now.add(duration);
		rounds[curRoundId].ended = false;
		buyRoundKey(curRoundId);
		emit Started(curRoundId);
		return curRoundId;
	}

	function buyRoundKey(uint roundId) public payable {
		require(rounds[roundId].start > 0, &#39;this round does not exist&#39;);
		require(rounds[roundId].ended == false, &#39;this round is actived&#39;);
		rounds[roundId].curKeyNo++;
		if (rounds[roundId].curKeyNo < dividedKeyNo) {
			require(msg.value == initialKeyPrice);
			rounds[roundId].jackPot = rounds[roundId].jackPot + msg.value.mul(9).div(10);
			feeAddress.transfer(msg.value.mul(1).div(10));
		} else {
			require(msg.value == rounds[roundId].curKeyNo.mul(initialKeyPrice));
			rounds[roundId].jackPot = rounds[roundId].jackPot.add(msg.value.mul(47).div(100));
			rounds[roundId].bonusPot = rounds[roundId].bonusPot.add(msg.value.mul(50).div(100));
			feeAddress.transfer(msg.value.mul(3).div(100));
			rounds[roundId].winnerPot = rounds[roundId].jackPot.div(2);
			rounds[roundId].luckyPot = rounds[roundId].jackPot.mul(2).div(5);
			rounds[roundId].amtPot = rounds[roundId].jackPot.mul(1).div(10);
		}
		keyStruct memory key;
		key.no = rounds[roundId].curKeyNo;
		key.curNo = rounds[roundId].curKeyNo;
		roundPlayers[roundId][msg.sender].push(key);
		roundPlayerKeys[roundId][msg.sender].push(rounds[roundId].curKeyNo);
		emit EthAmount(roundId, msg.value);
		uint current = now.add(1);
		if (current > rounds[roundId].start && current < rounds[roundId].end) {
			updateRoundEndTime(roundId);
		} else {
			endRound(roundId);
		}
	}

	function updateRoundEndTime(uint roundId) private {
		rounds[roundId].end = rounds[roundId].end.add(addedTime);
	}

	function endRound(uint roundId) private {
		require(rounds[roundId].start > 0, &#39;this round does not exist&#39;);
		require(rounds[roundId].ended == false, &#39;this round is ended&#39;);
		rounds[roundId].ended = true;
		emit Ended(roundId, rounds[roundId].ended);
		if (rounds[roundId].amtPot > 0) {
			amtDivies.receiveEth.value(rounds[roundId].amtPot)(roundId);
			rounds[roundId].jackPot = rounds[roundId].jackPot.sub(rounds[roundId].amtPot);
			emit DivideToAmToken(roundId, rounds[roundId].amtPot);
		}
	}

	function roundWithdraw(uint roundId) public {
		require(rounds[roundId].start > 0, &#39;this round does not exist&#39;);
		uint current = now;
		uint jackDrawAmount;
		uint bonusDrawAmount;
		uint winnerDrawAmount;
		uint luckyKeyIndex;
		uint luckyDrawAmount;
		uint calculatedDrawAmount;
		if (current >= rounds[roundId].end && rounds[roundId].ended == false) {
			endRound(roundId);
		}
		if (rounds[roundId].curKeyNo >= dividedKeyNo && rounds[roundId].ended == true) {
			if(rounds[roundId].curKeyNo.mod(2) == 1) {
				luckyKeyIndex = 1;
				luckyDrawAmount = rounds[roundId].luckyPot.div(rounds[roundId].curKeyNo.add(1).div(2));
			} else {
				luckyDrawAmount = rounds[roundId].luckyPot.div(rounds[roundId].curKeyNo.div(2));
			}
		}
		for (uint index; index < roundPlayers[roundId][msg.sender].length; index++) {
			if (rounds[roundId].curKeyNo >= dividedKeyNo) {
				if (roundPlayers[roundId][msg.sender][index].curNo >= dividedKeyNo) {
					bonusDrawAmount = bonusDrawAmount.add(rounds[roundId].curKeyNo.sub(roundPlayers[roundId][msg.sender][index].curNo).mul(initialKeyPrice.div(2)));
				} else {
					bonusDrawAmount = bonusDrawAmount.add(rounds[roundId].curKeyNo.sub(dividedKeyNo.sub(1)).mul(initialKeyPrice.div(2)));
				}
				roundPlayers[roundId][msg.sender][index].curNo = rounds[roundId].curKeyNo;
				if (rounds[roundId].ended == true) {
					if (luckyKeyIndex == 1 && roundPlayers[roundId][msg.sender][index].no.mod(2) == 1) {
						jackDrawAmount = jackDrawAmount.add(luckyDrawAmount);
					} else if (luckyKeyIndex == 0 && roundPlayers[roundId][msg.sender][index].no.mod(2) == 0) {
						jackDrawAmount = jackDrawAmount.add(luckyDrawAmount);
					}
					if (rounds[roundId].curKeyNo == roundPlayers[roundId][msg.sender][index].no) {
						winnerDrawAmount = rounds[roundId].winnerPot;
					}
				}
			}
		}
		require(bonusDrawAmount <= rounds[roundId].bonusPot, &#39;this round bonusPot is not enough&#39;);
		require(jackDrawAmount.add(winnerDrawAmount) <= rounds[roundId].jackPot, &#39;this round jackPot is not enough&#39;);
		rounds[roundId].bonusPot = rounds[roundId].bonusPot.sub(bonusDrawAmount);
		rounds[roundId].jackPot = rounds[roundId].jackPot.sub(jackDrawAmount).sub(winnerDrawAmount);
		calculatedDrawAmount = bonusDrawAmount.add(jackDrawAmount).add(winnerDrawAmount);
		require(calculatedDrawAmount > 0, &#39;calculatedDrawAmount is illegal&#39;);
		msg.sender.transfer(calculatedDrawAmount);
		emit WithDrawCompleted(roundId, jackDrawAmount, bonusDrawAmount, winnerDrawAmount);
	}

	function revokeRound(uint roundId) public {
		require(rounds[roundId].start > 0, &#39;this round does not exist&#39;);
		require(rounds[roundId].curKeyNo < dividedKeyNo, &#39;ico is successful&#39;);
		uint current = now;
		if (current >= rounds[roundId].end && rounds[roundId].ended == false) {
			endRound(roundId);
		}
		require(rounds[roundId].ended == true, &#39;this round is actived&#39;);
		uint revokedAmount;
		for (uint index; index < roundPlayerKeys[roundId][msg.sender].length; index++) {
			if (roundPlayerKeys[roundId][msg.sender][index] != 0) {
				require(revokedAmount.add(initialKeyPrice.mul(9).div(10)) <= rounds[roundId].jackPot, &#39;this round jackPot is not enough&#39;);
				revokedAmount = revokedAmount.add(initialKeyPrice.mul(9).div(10));
				delete roundPlayerKeys[roundId][msg.sender][index];
			}
		}
		require(revokedAmount <= rounds[roundId].jackPot, &#39;this round jackPot is not enough&#39;);
		rounds[roundId].jackPot = rounds[roundId].jackPot.sub(revokedAmount);
		require(revokedAmount > 0, &#39;revokedAmount is illegal&#39;);
		msg.sender.transfer(revokedAmount);
		emit revokeCompleted(roundId, revokedAmount);
	}
}