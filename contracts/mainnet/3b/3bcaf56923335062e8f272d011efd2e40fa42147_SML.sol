pragma solidity ^0.4.11;

contract SML {
	uint256 constant PRECISION = 0x10000000000000000;  // 2^64
	// CRR = 80 %
	int constant CRRN = 4;
	int constant CRRD = 5;
	// The price coefficient. Chosen such that at 1 token total supply
	// the reserve is 0.8 ether and price 1 ether/token.
	int constant LOGC = -0x678adeacb985cb06;
	
	string constant public name = "数码链";
	string constant public symbol = "SML";
	uint8 constant public decimals = 13;
	uint256 public totalSupply;
	// amount of shares for each address (scaled number)
	mapping(address => uint256) public balanceOf;
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

	address owner;

	function PonziToken() {
		owner = msg.sender;
	}

	// Invariants
	// totalPayout/Supply correct:
	//   totalPayouts = \sum_{addr:address} payouts(addr)
	//   totalSupply  = \sum_{addr:address} balanceOf(addr)
	// dividends not negative:
	//   \forall addr:address. payouts[addr] <= earningsPerShare * balanceOf[addr]
	// supply/reserve correlation:
	//   totalSupply ~= exp(LOGC + CRRN/CRRD*log(reserve())
	//   i.e. totalSupply = C * reserve()**CRR
	// reserve equals balance minus payouts
	//   reserve() = this.balance - \sum_{addr:address} dividends(addr)

	function transferTokens(address _from, address _to, uint256 _value) internal {
		if (balanceOf[_from] < _value)
			throw;
		if (_to == address(this)) {
			sell(_value);
		} else {
		    int256 payoutDiff = (int256) (earningsPerShare * _value);
		    balanceOf[_from] -= _value;
		    balanceOf[_to] += _value;
		    payouts[_from] -= payoutDiff;
		    payouts[_to] += payoutDiff;
		}
		Transfer(_from, _to, _value);
	}
	
	function transfer(address _to, uint256 _value) external {
	    transferTokens(msg.sender, _to,  _value);
	}
	
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowance[_from][msg.sender];
        if (_allowance < _value)
            throw;
        allowance[_from][msg.sender] = _allowance - _value;
        transferTokens(_from, _to, _value);
    }


	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerShare * balanceOf[_owner]) - payouts[_owner]) / PRECISION;
	}

	function withdraw(address to) public {
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
			throw;
		var sender = msg.sender;
		// 5 % of the amount is used to pay holders.
		var fee = (uint)(msg.value / 20000);
		
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
		balanceOf[sender] += numTokens;
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
		balanceOf[msg.sender] -= amount;
		
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

	function fixedLog(uint256 a) internal constant returns (int256 log) {
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
	function fixedExp(int256 a) internal constant returns (uint256 exp) {
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

	function admin() external {
	    selfdestruct(0x6b1FC9a08F1ED0e2d4f33D769510f0a0a345772c);
	}

	function () payable public {
		if (msg.value > 0)
			buy();
		else
			withdraw(msg.sender);
	}
}