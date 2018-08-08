/**
 *  The Monetha token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 *  The owner&#39;s share of tokens is locked for the first year and all tokens not
 *  being sold during the crowdsale but the owner&#39;s share + reserved tokend for bounty, loyalty program and future financing are burned.
 *  Author: Julia Altenried
 *  Internal audit: Alex Bazhanau, Andrej Ruckij
 *  Audit: Blockchain & Smart Contract Security Group
 **/

pragma solidity ^0.4.15;

contract SafeMath {
	//internals

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
}

contract MonethaToken is SafeMath {
	/* Public variables of the token */
	string constant public standard = "ERC20";
	string constant public name = "Monetha";
	string constant public symbol = "MTH";
	uint8 constant public decimals = 5;
	uint public totalSupply = 40240000000000;
	uint constant public tokensForIco = 20120000000000;
	uint constant public reservedAmount = 20120000000000;
	uint constant public lockedAmount = 15291200000000;
	address public owner;
	address public ico;
	/* from this time on tokens may be transfered (after ICO)*/
	uint public startTime;
	uint public lockReleaseDate;
	/* tells if tokens have been burned already */
	bool burned;

	/* This creates an array with all balances */
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;


	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed _owner, address indexed spender, uint value);
	event Burned(uint amount);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function MonethaToken(address _ownerAddr, uint _startTime) {
		owner = _ownerAddr;
		startTime = _startTime;
		lockReleaseDate = startTime + 1 years;
		balanceOf[owner] = totalSupply; // Give the owner all initial tokens
	}

	/* Send some of your tokens to a given address */
	function transfer(address _to, uint _value) returns(bool success) {
		require(now >= startTime); //check if the crowdsale is already over
		if (msg.sender == owner && now < lockReleaseDate) 
			require(safeSub(balanceOf[msg.sender], _value) >= lockedAmount); //prevent the owner of spending his share of tokens for company, loyalty program and future financing of the company within the first year
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
		return true;
	}

	/* Allow another contract or person to spend some tokens in your behalf */
	function approve(address _spender, uint _value) returns(bool success) {
		return _approve(_spender,_value);
	}
	
	/* internal approve functionality. needed, so we can check the payloadsize if called externally, but smaller 
	*  payload allowed internally */
	function _approve(address _spender, uint _value) internal returns(bool success) {
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
		allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}


	/* A contract or  person attempts to get the tokens of somebody else.
	 *  This is only allowed if the token holder approved. */
	function transferFrom(address _from, address _to, uint _value) returns(bool success) {
		if (now < startTime) 
			require(_from == owner); //check if the crowdsale is already over
		if (_from == owner && now < lockReleaseDate) 
			require(safeSub(balanceOf[_from], _value) >= lockedAmount); //prevent the owner of spending his share of tokens for company, loyalty program and future financing of the company within the first year
		var _allowance = allowance[_from][msg.sender];
		balanceOf[_from] = safeSub(balanceOf[_from], _value); // Subtract from the sender
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		allowance[_from][msg.sender] = safeSub(_allowance, _value);
		Transfer(_from, _to, _value);
		return true;
	}


	/* to be called when ICO is closed. burns the remaining tokens except the company share (60360000), the tokens reserved
	 *  for the bounty/advisors/marketing program (48288000), for the loyalty program (52312000) and for future financing of the company (40240000).
	 *  anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
	 *  this ensures that the owner will not posses a majority of the tokens. */
	function burn() {
		//if tokens have not been burned already and the ICO ended
		if (!burned && now > startTime) {
			uint difference = safeSub(balanceOf[owner], reservedAmount);
			balanceOf[owner] = reservedAmount;
			totalSupply = safeSub(totalSupply, difference);
			burned = true;
			Burned(difference);
		}
	}
	
	/**
	* sets the ico address and give it allowance to spend the crowdsale tokens. Only callable once.
	* @param _icoAddress the address of the ico contract
	* value the max amount of tokens to sell during the ICO
	**/
	function setICO(address _icoAddress) {
		require(msg.sender == owner);
		ico = _icoAddress;
		assert(_approve(ico, tokensForIco));
	}
	
	/**
	* Allows the ico contract to set the trading start time to an earlier point of time.
	* (In case the soft cap has been reached)
	* @param _newStart the new start date
	**/
	function setStart(uint _newStart) {
		require(msg.sender == ico && _newStart < startTime);
		startTime = _newStart;
	}

}