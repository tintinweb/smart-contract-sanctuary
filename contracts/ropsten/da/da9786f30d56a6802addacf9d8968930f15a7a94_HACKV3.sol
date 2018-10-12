pragma solidity ^0.4.18;

// If you wanna escape this contract REALLY FAST
// 1. open MEW/METAMASK
// 2. Put this as data: 0xb1e35242
// 3. send 150000+ gas
// That calls the getMeOutOfHere() method

// Wacky version, 0-1 tokens takes 10eth (should be avg 200% gains), 1-2 takes another 30eth (avg 100% gains), and beyond that who the fuck knows but it&#39;s 50% gains
// 10% fees, price goes up crazy fast
contract HACKV3 {
	uint256 constant PRECISION = 0x10000000000000000;  // 2^64
	// CRR = 80 %
	int constant CRRN = 1;
	int constant CRRD = 2;
	// The price coefficient. Chosen such that at 1 token total supply
	// the reserve is 0.8 ether and price 1 ether/token.
	int constant LOGC = -0x296ABF784A358468C;
	
	string constant public name = "ProofOfWeakHands";
	string constant public symbol = "POWH";
	uint8 constant public decimals = 18;
	uint256 public totalSupply;
	// amount of shares for each address (scaled number)
	mapping(address => uint256) public balanceOfOld;
	// allowance map, see erc20
	mapping(address => mapping(address => uint256)) public allowance;
	// amount payed out for each address (scaled number)
	mapping(address => int256) payouts;
	// sum of all payouts (scaled number)
	int256 totalPayouts;
	// amount earned for each share (scaled number)
	uint256 earningsPerShare;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//address owner;

	function PonziTokenV3() public {
		//owner = msg.sender;
	}
	
	// These are functions solely created to appease the frontend
	function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfOld[_owner];
    }

	function withdraw(uint tokenCount) // the parameter is ignored, yes
      public
      returns (bool)
    {
		var balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * PRECISION);
		totalPayouts += (int256) (balance * PRECISION);
		msg.sender.transfer(balance);
		return true;
    }
	
	function sellMyTokensDaddy() public {
		var balance = balanceOf(msg.sender);
		transferTokens(msg.sender, address(this),  balance); // this triggers the internal sell function
	}

    function getMeOutOfHere() public {
		sellMyTokensDaddy();
        withdraw(1); // parameter is ignored
	}
	
	function fund()
      public
      payable 
      returns (bool)
    {
      if (msg.value > 0.000001 ether)
			buy();
		else
			return false;
	  
      return true;
    }

	function buyPrice() public constant returns (uint) {
		return getTokensForEther(1 finney);
	}
	
	function sellPrice() public constant returns (uint) {
		return getEtherForTokens(1 finney);
	}

	// End of useless functions

	// Invariants
	// totalPayout/Supply correct:
	//   totalPayouts = \sum_{addr:address} payouts(addr)
	//   totalSupply  = \sum_{addr:address} balanceOfOld(addr)
	// dividends not negative:
	//   \forall addr:address. payouts[addr] <= earningsPerShare * balanceOfOld[addr]
	// supply/reserve correlation:
	//   totalSupply ~= exp(LOGC + CRRN/CRRD*log(reserve())
	//   i.e. totalSupply = C * reserve()**CRR
	// reserve equals balance minus payouts
	//   reserve() = this.balance - \sum_{addr:address} dividends(addr)

	function transferTokens(address _from, address _to, uint256 _value) internal {
		if (balanceOfOld[_from] < _value)
			revert();
		if (_to == address(this)) {
			sell(_value);
		} else {
		    int256 payoutDiff = (int256) (earningsPerShare * _value);
		    balanceOfOld[_from] -= _value;
		    balanceOfOld[_to] += _value;
		    payouts[_from] -= payoutDiff;
		    payouts[_to] += payoutDiff;
		}
		Transfer(_from, _to, _value);
	}
	
	function transfer(address _to, uint256 _value) public {
	    transferTokens(msg.sender, _to,  _value);
	}
	
    function transferFrom(address _from, address _to, uint256 _value) public {
        var _allowance = allowance[_from][msg.sender];
        if (_allowance < _value)
            revert();
        allowance[_from][msg.sender] = _allowance - _value;
        transferTokens(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) revert();
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerShare * balanceOfOld[_owner]) - payouts[_owner]) / PRECISION;
	}

	function withdrawOld(address to) public {
		var balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * PRECISION);
		totalPayouts += (int256) (balance * PRECISION);
		to.transfer(balance);
	}

	function balance() internal constant returns (uint256 amount) {
		return this.balance - msg.value;
	}
	function reserve() public constant returns (uint256 amount) {
		return balance()
			- ((uint256) ((int256) (earningsPerShare * totalSupply) - totalPayouts) / PRECISION) - 1;
	}

	function buy() internal {
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();
		var sender = msg.sender;
		// 5 % of the amount is used to pay holders.
		var fee = (uint)(msg.value / 10);
		
		// compute number of bought tokens
		var numEther = msg.value - fee;
		var numTokens = getTokensForEther(numEther);

		var buyerfee = fee * PRECISION;
		if (totalSupply > 0) {
			// compute how the fee distributed to previous holders and buyer.
			// The buyer already gets a part of the fee as if he would buy each token separately.
			var holderreward =
			    (PRECISION - (reserve() + numEther) * numTokens * PRECISION / (totalSupply + numTokens) / numEther)
			    * (uint)(CRRD) / (uint)(CRRD-CRRN);
			var holderfee = fee * holderreward;
			buyerfee -= holderfee;
		
			// Fee is distributed to all existing tokens before buying
			var feePerShare = holderfee / totalSupply;
			earningsPerShare += feePerShare;
		}
		// add numTokens to total supply
		totalSupply += numTokens;
		// add numTokens to balance
		balanceOfOld[sender] += numTokens;
		// fix payouts so that sender doesn&#39;t get old earnings for the new tokens.
		// also add its buyerfee
		var payoutDiff = (int256) ((earningsPerShare * numTokens) - buyerfee);
		payouts[sender] += payoutDiff;
		totalPayouts += payoutDiff;
	}
	
	function sell(uint256 amount) internal {
		var numEthers = getEtherForTokens(amount);
		// remove tokens
		totalSupply -= amount;
		balanceOfOld[msg.sender] -= amount;
		
		// fix payouts and put the ethers in payout
		var payoutDiff = (int256) (earningsPerShare * amount + (numEthers * PRECISION));
		payouts[msg.sender] -= payoutDiff;
		totalPayouts -= payoutDiff;
	}

	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return fixedExp(fixedLog(reserve() + ethervalue)*CRRN/CRRD + LOGC) - totalSupply;
	}

	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		if (tokens == totalSupply)
			return reserve();
		return reserve() - fixedExp((fixedLog(totalSupply - tokens) - LOGC) * CRRD/CRRN);
	}

	int256 constant one       = 0x10000000000000000;
	uint256 constant sqrt2    = 0x16a09e667f3bcc908;
	uint256 constant sqrtdot5 = 0x0b504f333f9de6484;
	int256 constant ln2       = 0x0b17217f7d1cf79ac;
	int256 constant ln2_64dot5= 0x2cb53f09f05cc627c8;
	int256 constant c1        = 0x1ffffffffff9dac9b;
	int256 constant c3        = 0x0aaaaaaac16877908;
	int256 constant c5        = 0x0666664e5e9fa0c99;
	int256 constant c7        = 0x049254026a7630acf;
	int256 constant c9        = 0x038bd75ed37753d68;
	int256 constant c11       = 0x03284a0c14610924f;

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
		// The polynomial R = c1*x + c3*x^3 + ... + c11 * x^11
		// approximates the function log(1+x)-log(1-x)
		// Hence R(s) = log((1+s)/(1-s)) = log(a)
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
		// The polynomial R = 2 + c2*x^2 + c4*x^4 + ...
		// approximates the function x*(exp(x)+1)/(exp(x)-1)
		// Hence exp(x) = (R(x)+x)/(R(x)-x)
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

	/*function destroy() external {
	    selfdestruct(owner);
	}*/

	function () payable public {
		if (msg.value > 0)
			buy();
		else
			withdrawOld(msg.sender);
	}
}