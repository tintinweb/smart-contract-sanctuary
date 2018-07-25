pragma solidity ^0.4.18;

/*
           _.-,=_&quot;&quot;&quot;--,_
        .-&quot; =/7&quot;   _  .T &quot;=.
      ,/7  &quot; &quot;  ,//)`d       `.
    ,/ &quot;      4 ,i-/           `.
   /         _)&quot;_sm  =,=T&quot;D      \
  /         (_/&quot;_`;\/gjo D-O      \
 /         ,d&quot;&quot;&quot;O-_.._.)  P.___    \
,        ,&quot;            \\  bi- `\| Y.
|       .d              b\  P&#39;   V  |
|\      &#39;O               O!&quot;,       |
|L.       \__.=_           7        |
&#39;  D.           )         /         &#39;
 \ T             \       |         /
  \D             /       7 /      /
   \             \     ,&quot; /&quot;     /
    `.            \   7&#39;       ,&#39;
      &quot;-_          `&quot;&#39;      ,-&#39;
         &quot;-._           _.-&quot;
             &quot;&quot;&quot;&quot;---&quot;&quot;&quot;&quot;

 The Equal Playing Field Pyramid. New World.
 
 Inspired by https://ExitScam.me/P3D

 Developers:
Blubberhead
SealFace
FatHolocaust
*/

contract NewWorld {


	uint256 constant scaleFactor = 0x10000000000000000;  // 2^64


	int constant crr_n = 1; // CRR numerator
	int constant crr_d = 2; // CRR denominator
    int constant price_coeff = -0x296ABF784A358468C;
    string constant public name = &quot;NewWorld&quot;;
	string constant public symbol = &quot;NWT&quot;;
	uint8 constant public decimals = 18;


	mapping(address => uint256) public tokenBalance;
		
	
	mapping(address => int256) public payouts;


	uint256 public totalSupply;

	
	int256 totalPayouts;

	
	uint256 earningsPerToken;
	
	
	uint256 public contractBalance;

	function NewWorld() public {}

	


	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return tokenBalance[_owner];
	}

	
	function withdraw() public {
		
		var balance = dividends(msg.sender);
		
		
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
	
		totalPayouts += (int256) (balance * scaleFactor);
		
	
		contractBalance = sub(contractBalance, balance);
		msg.sender.transfer(balance);
	}


	function reinvestDividends() public {
	
		var balance = dividends(msg.sender);
		
		
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		
		totalPayouts += (int256) (balance * scaleFactor);
		
		
		uint value_ = (uint) (balance);
		
		
		if (value_ < 0.000001 ether || value_ > 1000000 ether)
			revert();
			
		
		var sender = msg.sender;
		
	
		var res = reserve() - balance;

		
		var fee = div(value_, 10);
		
	
		var numEther = value_ - fee;
		
		
		var numTokens = calculateDividendTokens(numEther, balance);
		
		
		var buyerFee = fee * scaleFactor;
		
	
		if (totalSupply > 0) {
		
			var bonusCoEff =
			    (scaleFactor - (res + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
		
			var holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

		
			var rewardPerShare = holderReward / totalSupply;
			
		
			earningsPerToken += rewardPerShare;
		}
		
		
		totalSupply = add(totalSupply, numTokens);
		
		
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);
		
		
		var payoutDiff  = (int256) ((earningsPerToken * numTokens) - buyerFee);
		
	
		payouts[sender] += payoutDiff;
		
		
		totalPayouts    += payoutDiff;
		
	}

	
	function sellMyTokens() public {
		var balance = balanceOf(msg.sender);
		sell(balance);
	}

	
    function getMeOutOfHere() public {
		sellMyTokens();
        withdraw();
	}


	function fund() payable public {
		
		if (msg.value > 0.000001 ether) {
		    contractBalance = add(contractBalance, msg.value);
			buy();
		} else {
			revert();
		}
    }


	function buyPrice() public constant returns (uint) {
		return getTokensForEther(1 finney);
	}

	
	function sellPrice() public constant returns (uint) {
        var eth = getEtherForTokens(1 finney);
        var fee = div(eth, 10);
        return eth - fee;
    }

	
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerToken * tokenBalance[_owner]) - payouts[_owner]) / scaleFactor;
	}

	
	function withdrawOld(address to) public {
	
		var balance = dividends(msg.sender);
		
	
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
	
		totalPayouts += (int256) (balance * scaleFactor);
		
	
		contractBalance = sub(contractBalance, balance);
		to.transfer(balance);		
	}

	
	function balance() internal constant returns (uint256 amount) {
	
		return contractBalance - msg.value;
	}

	function buy() internal {
		
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();
						
		
		var sender = msg.sender;
		
		
		var fee = div(msg.value, 10);
		
	
		var numEther = msg.value - fee;
		
	
		var numTokens = getTokensForEther(numEther);
		
		
		var buyerFee = fee * scaleFactor;
		
		
		if (totalSupply > 0) {
		
			var bonusCoEff =
			    (scaleFactor - (reserve() + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
			
			var holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

		
			var rewardPerShare = holderReward / totalSupply;
			
		
			earningsPerToken += rewardPerShare;
			
		}

		
		totalSupply = add(totalSupply, numTokens);

		
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);

		
		var payoutDiff = (int256) ((earningsPerToken * numTokens) - buyerFee);
		
		
		payouts[sender] += payoutDiff;
		
		
		totalPayouts    += payoutDiff;
		
	}


	function sell(uint256 amount) internal {
	    
		var numEthersBeforeFee = getEtherForTokens(amount);
		
	
        var fee = div(numEthersBeforeFee, 10);
		
		
        var numEthers = numEthersBeforeFee - fee;
		
	
		totalSupply = sub(totalSupply, amount);
		
       
		tokenBalance[msg.sender] = sub(tokenBalance[msg.sender], amount);

        
		var payoutDiff = (int256) (earningsPerToken * amount + (numEthers * scaleFactor));
		
       
		payouts[msg.sender] -= payoutDiff;		
		
		
        totalPayouts -= payoutDiff;
		
	
		if (totalSupply > 0) {
		
			var etherFee = fee * scaleFactor;
			
			
			var rewardPerShare = etherFee / totalSupply;
			
			
			earningsPerToken = add(earningsPerToken, rewardPerShare);
		}
	}
	
	
	function reserve() internal constant returns (uint256 amount) {
		return sub(balance(),
			 ((uint256) ((int256) (earningsPerToken * totalSupply) - totalPayouts) / scaleFactor));
	}


	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}

	
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}

	
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
	
		var reserveAmount = reserve();

	
		if (tokens == totalSupply)
			return reserveAmount;

	
	
	        return sub(reserveAmount, fixedExp((fixedLog(totalSupply - tokens) - price_coeff) * crr_d/crr_n));
	}

	
	int256  constant one        = 0x10000000000000000;
	uint256 constant sqrt2      = 0x16a09e667f3bcc908;
	uint256 constant sqrtdot5   = 0x0b504f333f9de6484;
	int256  constant ln2        = 0x0b17217f7d1cf79ac;
	int256  constant ln2_64dot5 = 0x2cb53f09f05cc627c8;
	int256  constant c1         = 0x1ffffffffff9dac9b;
	int256  constant c3         = 0x0aaaaaaac16877908;
	int256  constant c5         = 0x0666664e5e9fa0c99;
	int256  constant c7         = 0x049254026a7630acf;
	int256  constant c9         = 0x038bd75ed37753d68;
	int256  constant c11        = 0x03284a0c14610924f;


	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > sqrt2) {
			a /= 2;
			scale++;
		}
		while (a <= sqrtdot5) {
			a *= 2;
			scale--;
		}
		int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
		var z = (s*s) / one;
		return scale * ln2 +
			(s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
				/one))/one))/one))/one))/one);
	}

	int256 constant c2 =  0x02aaaaaaaaa015db0;
	int256 constant c4 = -0x000b60b60808399d1;
	int256 constant c6 =  0x0000455956bccdd06;
	int256 constant c8 = -0x000001b893ad04b3a;
	
	
	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
		a -= scale*ln2;
		int256 z = (a*a) / one;
		int256 R = ((int256)(2) * one) +
			(z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
		exp = (uint256) (((R + a) * one) / (R - a));
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
	}
	

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
		// msg.value is the amount of Ether sent by the transaction.
		if (msg.value > 0) {
			fund();
		} else {
			withdrawOld(msg.sender);
		}
	}
}