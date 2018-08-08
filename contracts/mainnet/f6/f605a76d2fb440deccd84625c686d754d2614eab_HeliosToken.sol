pragma solidity ^0.4.18;

/**
 *Owner address = 0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2
 *Parts of this code have been modified from code by BokkyPooBah:
 *(c) by Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
 */
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20 {
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
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract HeliosToken is ERC20, Owned, SafeMath {
	/*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
	uint public _yearTwoSupply;
	uint public _yearThreeSupply;
	bool public _yearTwoClaimed;
	bool public _yearThreeClaimed;
	//March 1, 2018
	uint256 public startTime = 1519862400;
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function HeliosToken() public {
        symbol = "HLS";
        name = "Helios Token";
        decimals = 18;
        _totalSupply = 350000000000000000000000000;
		_yearTwoSupply = 30000000000000000000000000;
		_yearThreeSupply = 20000000000000000000000000;
        
		//send 1st year team tokens, exchange tokens, incubator tokens
		balances[0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2] = (_totalSupply - _yearTwoSupply - _yearThreeSupply);
        Transfer(address(0), 0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2, (_totalSupply - _yearTwoSupply - _yearThreeSupply));
		
		_yearTwoClaimed = false;
		_yearThreeClaimed = false;
    }

	// ------------------------------------------------------------------------
    // Team can claim their tokens after lock up period
    // ------------------------------------------------------------------------
	function teamClaim(uint year) public onlyOwner returns (bool success) {
		if(year == 2)
		{
			require (now > (startTime + 31536000)  && _yearTwoClaimed == false);
			balances[0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2] = safeAdd(balances[0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2], _yearTwoSupply);
			Transfer(address(0), 0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2, _yearTwoSupply);
			_yearTwoClaimed = true;
			
		}
		if(year == 3)
		{
			require (now > (startTime + 63072000) && _yearThreeClaimed == false);
			balances[0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2] = safeAdd(balances[0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2], _yearThreeSupply);
			Transfer(address(0), 0x6BFAf995ffce7Be6e3073dC8AAf45E445cf234e2, _yearThreeSupply);
			_yearThreeClaimed = true;
		}
		return true;
	}
	
	
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

  
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
	// - If the sender is a locked token storage address then do not allow
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
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
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}