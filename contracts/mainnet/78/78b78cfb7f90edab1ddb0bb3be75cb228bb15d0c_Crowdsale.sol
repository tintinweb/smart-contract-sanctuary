pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * Crowdsale has a life span during which investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to beneficiary
 * as they arrive.
 *
 * A crowdsale is defined by:
 *	offset (required) - crowdsale start, unix timestamp
 *	length (required) - crowdsale length in seconds
 *  price (required) - token price in wei
 *	soft cap (optional) - minimum amount of funds required for crowdsale success, can be zero (if not used)
 *	hard cap (optional) - maximum amount of funds crowdsale can accept, can be zero (unlimited)
 *  quantum (optional) - enables value accumulation effect to reduce value transfer costs, usually is not used (set to zero)
 *    if non-zero value passed specifies minimum amount of wei to transfer to beneficiary
 *
 * This crowdsale doesn&#39;t own tokens and doesn&#39;t perform any token emission.
 * It expects enough tokens to be available on its address:
 * these tokens are used for issuing them to investors.
 * Token redemption is done in opposite way: tokens accumulate back on contract&#39;s address
 * Beneficiary is specified by its address.
 * This implementation can be used to make several crowdsales with the same token being sold.
 */
contract Crowdsale {
	/**
	* Descriptive name of this Crowdsale. There could be multiple crowdsales for same Token.
	*/
	string public name;

	// contract creator, owner of the contract
	// creator is also supplier of tokens
	address private creator;

	// crowdsale start (unix timestamp)
	uint public offset;

	// crowdsale length in seconds
	uint public length;

	// one token price in wei
	uint public price;

	// crowdsale minimum goal in wei
	uint public softCap;

	// crowdsale maximum goal in wei
	uint public hardCap;

	// minimum amount of value to transfer to beneficiary in automatic mode
	uint private quantum;

	// how much value collected (funds raised)
	uint public collected;

	// how many different addresses made an investment
	uint public investorsCount;

	// how much value refunded (if crowdsale failed)
	uint public refunded;

	// how much tokens issued to investors
	uint public tokensIssued;

	// how much tokens redeemed and refunded (if crowdsale failed)
	uint public tokensRedeemed;

	// how many successful transactions (with tokens being send back) do we have
	uint public transactions;

	// how many refund transactions (in exchange for tokens) made (if crowdsale failed)
	uint public refunds;

	// The token being sold
	DetailedERC20 private token;

	// decimal coefficient (k) enables support for tokens with non-zero decimals
	uint k;

	// address where funds are collected
	address public beneficiary;

	// investor&#39;s mapping, required for token redemption in a failed crowdsale
	// making this field public allows to extend investor-related functionality in the future
	mapping(address => uint) public balances;

	// events to log
	event InvestmentAccepted(address indexed holder, uint tokens, uint value);
	event RefundIssued(address indexed holder, uint tokens, uint value);

	// a crowdsale is defined by a set of parameters passed here
	// make sure _end timestamp is in the future in order for crowdsale to be operational
	// _price must be positive, this is a price of one token in wei
	// _hardCap must be greater then _softCap or zero, zero _hardCap means unlimited crowdsale
	// _quantum may be zero, in this case there will be no value accumulation on the contract
	function Crowdsale(
		string _name,
		uint _offset,
		uint _length,
		uint _price,
		uint _softCap,
		uint _hardCap,
		uint _quantum,
		address _beneficiary,
		address _token
	) public {

		// validate crowdsale settings (inputs)
		// require(_offset > 0); // we don&#39;t really care
		require(_length > 0);
		require(now < _offset + _length); // crowdsale must not be already finished
		// softCap can be anything, zero means crowdsale doesn&#39;t fail
		require(_hardCap > _softCap || _hardCap == 0);
		// hardCap must be greater then softCap
		// quantum can be anything, zero means no accumulation
		require(_price > 0);
		require(_beneficiary != address(0));
		require(_token != address(0));

		name = _name;

		// setup crowdsale settings
		offset = _offset;
		length = _length;
		softCap = _softCap;
		hardCap = _hardCap;
		quantum = _quantum;
		price = _price;
		creator = msg.sender;

		// define beneficiary
		beneficiary = _beneficiary;

		// allocate tokens: link and init coefficient
		__allocateTokens(_token);
	}

	// accepts crowdsale investment, requires
	// crowdsale to be running and not reached its goal
	function invest() public payable {
		// perform validations
		assert(now >= offset && now < offset + length); // crowdsale is active
		assert(collected + price <= hardCap || hardCap == 0); // its still possible to buy at least 1 token
		require(msg.value >= price); // value sent is enough to buy at least one token

		// call &#39;sender&#39; nicely - investor
		address investor = msg.sender;

		// how much tokens we must send to investor
		uint tokens = msg.value / price;

		// how much value we must send to beneficiary
		uint value = tokens * price;

		// ensure we are not crossing the hardCap
		if (value + collected > hardCap || hardCap == 0) {
			value = hardCap - collected;
			tokens = value / price;
			value = tokens * price;
		}

		// update crowdsale status
		collected += value;
		tokensIssued += tokens;

		// transfer tokens to investor
		__issueTokens(investor, tokens);

		// transfer the change to investor
		investor.transfer(msg.value - value);

		// accumulate the value or transfer it to beneficiary
		if (collected >= softCap && this.balance >= quantum) {
			// transfer all the value to beneficiary
			__beneficiaryTransfer(this.balance);
		}

		// log an event
		InvestmentAccepted(investor, tokens, value);
	}

	// refunds an investor of failed crowdsale,
	// requires investor to allow token transfer back
	function refund() public payable {
		// perform validations
		assert(now >= offset + length); // crowdsale ended
		assert(collected < softCap); // crowdsale failed

		// call &#39;sender&#39; nicely - investor
		address investor = msg.sender;

		// find out how much tokens should be refunded
		uint tokens = __redeemAmount(investor);

		// calculate refund amount
		uint refundValue = tokens * price;

		// additional validations
		require(tokens > 0);

		// update crowdsale status
		refunded += refundValue;
		tokensRedeemed += tokens;
		refunds++;

		// transfer the tokens back
		__redeemTokens(investor, tokens);

		// make a refund
		investor.transfer(refundValue + msg.value);

		// log an event
		RefundIssued(investor, tokens, refundValue);
	}

	// sends all the value to the beneficiary
	function withdraw() public {
		// perform validations
		assert(creator == msg.sender || beneficiary == msg.sender); // only creator or beneficiary can initiate this call
		assert(collected >= softCap); // crowdsale must be successful
		assert(this.balance > 0); // there should be something to transfer

		// how much to withdraw (entire balance obviously)
		uint value = this.balance;

		// perform the transfer
		__beneficiaryTransfer(value);
	}

	// performs an investment, refund or withdrawal,
	// depending on the crowdsale status
	function() public payable {
		// started or finished
		require(now >= offset);

		if(now < offset + length) {
			// crowdsale is running, invest
			invest();
		}
		else if(collected < softCap) {
			// crowdsale failed, try to refund
			refund();
		}
		else {
			// crowdsale is successful, investments are not accepted anymore
			// but maybe poor beneficiary is begging for change...
			withdraw();
		}
	}

	// ----------------------- internal section -----------------------

	// allocates token source (basically links token)
	function __allocateTokens(address _token) internal {
		// link tokens, tokens are not owned by a crowdsale
		// should be transferred to crowdsale after the deployment
		token = DetailedERC20(_token);

		// obtain decimals and calculate coefficient k
		k = 10 ** uint(token.decimals());
	}

	// transfers tokens to investor, validations are not required
	function __issueTokens(address investor, uint tokens) internal {
		// if this is a new investor update investor count
		if (balances[investor] == 0) {
			investorsCount++;
		}

		// for open crowdsales we track investors balances
		balances[investor] += tokens;

		// issue tokens, taking into account decimals
		token.transferFrom(creator, investor, tokens * k);
	}

	// calculates amount of tokens available to redeem from investor, validations are not required
	function __redeemAmount(address investor) internal view returns (uint amount) {
		// round down allowance taking into account token decimals
		uint allowance = token.allowance(investor, this) / k;

		// for open crowdsales we check previously tracked investor balance
		uint balance = balances[investor];

		// return allowance safely by checking also the balance
		return balance < allowance ? balance : allowance;
	}

	// transfers tokens from investor, validations are not required
	function __redeemTokens(address investor, uint tokens) internal {
		// for open crowdsales we track investors balances
		balances[investor] -= tokens;

		// redeem tokens, taking into account decimals coefficient
		token.transferFrom(investor, creator, tokens * k);
	}

	// transfers a value to beneficiary, validations are not required
	function __beneficiaryTransfer(uint value) internal {
		beneficiary.transfer(value);
	}

	// !---------------------- internal section ----------------------!
}