pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;FINX&#39; &#39;FINX Token&#39; token contract
//
// Symbol	: FINX
// Name		: FINX Token
// Total supply: 100,000,000,000.000000000000000000
// Decimals	: 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}
	function sub(uint a, uint b) internal pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}
	function div(uint a, uint b) internal pure returns (uint c) {
		require(b > 0);
		c = a / b;
	}
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public constant returns (uint);
	function balanceOf(address tokenOwner) public constant returns (uint balance);
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract FINXToken is ERC20Interface {
	using SafeMath for uint;

	string constant public symbol = "FINX";
	string constant public name = "FINX";
	uint8 constant public decimals = 18;
	uint public _totalSupply = 100000000000e18;

	uint constant endTime = 1543622400; // 2018-12-01 00:00:00 GMT+00:00
	uint constant unlockTime = 1622505600; // 2021-06-01 00:00:00 GMT+00:00

	address founder1 = 0x0e85a9faB7D61b6cbbf1ccafA8144E23009a60AF;
	address founder2 = 0xFcEa27D04354aD5f20B5dbaf5C314e4f143eAe48;
	address founder3 = 0xa0eC2A32bd678DFbD3d359Be8075093f36B2c0aa;
	address founder4 = 0xC93324C26ce4221d187FEeeaf54bC047Bbddd26a;

	address mgmtTeam = 0xb3495892fB336D81dBAb4650c2291Bfd7A52c1C1;
	address advsTeam = 0x72C1A4670a97a6A2BD106cA3341f059123a4F381;

	address crowdSale = 0x9940bd75d32a0544750eed5EfC208453F4ae31ab;

	uint constant founderTokens = 250000000e18;
	uint constant mgmtTokens = 20000000e18;
	uint constant advsTokens = 40000000e18;
	uint constant crowdSaleTokens = 98940000000e18;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;


	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	function FINXToken() public {
		preSale(founder1, founderTokens);
		preSale(founder2, founderTokens);
		preSale(founder3, founderTokens);
		preSale(founder4, founderTokens);

		preSale(mgmtTeam, mgmtTokens);
		preSale(advsTeam, advsTokens);

		preSale(crowdSale, crowdSaleTokens);
	}


	function preSale(address _address, uint _amount) internal returns (bool) {
		balances[_address] = _amount;
		emit Transfer(address(0x0), _address, _amount);
	}


	function transferPermissions(address spender) internal constant returns (bool) {
		if (spender == crowdSale) {
			return true;
		}

		if (now < endTime) {
			return false;
		}

		if (now < unlockTime) {
			if (spender == founder1 || spender == founder2 || spender == founder3 || spender == founder4) {
				return false;
			}
		}

		return true;
	}


	// ------------------------------------------------------------------------
	// Total supply
	// ------------------------------------------------------------------------
	function totalSupply() public constant returns (uint) {
		return _totalSupply;
	}


	// ------------------------------------------------------------------------
	// Get the token balance for account `tokenOwner`
	// ------------------------------------------------------------------------
	function balanceOf(address tokenOwner) public constant returns (uint balance) {
		return balances[tokenOwner];
	}


	// ------------------------------------------------------------------------
	// Transfer the balance from token owner&#39;s account to `to` account
	// - Owner&#39;s account must have sufficient balance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transfer(address to, uint tokens) public returns (bool success) {
		require(transferPermissions(msg.sender));
		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}


	// ------------------------------------------------------------------------
	// Token owner can approve for `spender` to transferFrom(...) `tokens`
	// from the token owner&#39;s account
	//
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	// recommends that there are no checks for the approval double-spend attack
	// as this should be implemented in user interfaces
	// ------------------------------------------------------------------------
	function approve(address spender, uint tokens) public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}


	// ------------------------------------------------------------------------
	// Transfer `tokens` from the `from` account to the `to` account
	//
	// The calling account must already have sufficient tokens approve(...)-d
	// for spending from the `from` account and
	// - From account must have sufficient balance to transfer
	// - Spender must have sufficient allowance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		require(transferPermissions(from));
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
		return true;
	}


	// ------------------------------------------------------------------------
	// Returns the amount of tokens approved by the owner that can be
	// transferred to the spender&#39;s account
	// ------------------------------------------------------------------------
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}


	// ------------------------------------------------------------------------
	// Don&#39;t accept ETH
	// ------------------------------------------------------------------------
	function () public payable {
		revert();
	}
}