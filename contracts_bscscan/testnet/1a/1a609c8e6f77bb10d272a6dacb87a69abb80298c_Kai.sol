/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

pragma solidity ^0.4.26;

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


	/**
	ERC Token Standard #20 Interface
	https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	*/
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


	/**
	Contract function to receive approval and execute function in one call

	Borrowed from MiniMeToken
	*/
	contract ApproveAndCallFallFIREk {
		function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
	}

	/**
	ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
	*/
	contract Kai is ERC20Interface, SafeMath {
		string public symbol;
		string public  name;
		uint8 public decimals;
		uint public _totalSupply;

		mapping(address => uint) balances;
		mapping(address => mapping(address => uint)) allowed;


    uint256 BURN_FEE = safeDiv(5, 100);
    uint TAX_SUPPORT_FEE = safeDiv(5, 100);
    address public owner;
    mapping(address => bool) public excludedFromTax;

		// ------------------------------------------------------------------------
		// Constructor
		// ------------------------------------------------------------------------
		constructor() public {
    		symbol = "KAI";
    		name = "Kai";
			decimals = 18;
			_totalSupply = 10 * 10 ** 12 * 10 ** 18;
			owner =  msg.sender;
			balances[msg.sender] = _totalSupply;
			emit Transfer(address(0), msg.sender, _totalSupply);
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
		// Transfer the balance from token owner's account to to account
		// - Owner's account must have sufficient balance to transfer
		// - 0 value transfers are allowed
		// ------------------------------------------------------------------------
		function transfer(address to, uint value) public returns (bool success) {
// 			balances[msg.sender] = safeSub(balances[msg.sender], tokens);
// 			balances[to] = safeAdd(balances[to], tokens);
			
			
			
			
			     
        if(excludedFromTax[msg.sender]==true){
          
          balances[msg.sender] -= value;  
          balances[to] += value;
        
        }else{
            
            uint burnAmount =safeMul(value, BURN_FEE);
            
            uint devSupportAmount = safeMul(value, TAX_SUPPORT_FEE ) ;
            
            uint tot =safeAdd(burnAmount, devSupportAmount);
            
            uint  receipientAmount = safeSub(value,tot);
            
            balances[msg.sender] -= value;
             
            balances[address(0)] += burnAmount;
           
            balances[owner] += devSupportAmount;
           
            balances[to] += receipientAmount;
          
            
        }
     
		
			emit Transfer(msg.sender, to, value);
			return true;
		}


		// ------------------------------------------------------------------------
		// Token owner can approve for spender to transferFrom(...) tokens
		// from the token owner's account
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
			emit Transfer(from, to, tokens);
			return true;
		}


		// ------------------------------------------------------------------------
		// Returns the amount of tokens approved by the owner that can be
		// transferred to the spender's account
		// ------------------------------------------------------------------------
		function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
			return allowed[tokenOwner][spender];
		}


		// ------------------------------------------------------------------------
		// Token owner can approve for spender to transferFrom(...) tokens
		// from the token owner's account. The spender contract function
		// receiveApproval(...) is then executed
		// ------------------------------------------------------------------------
		function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
			allowed[msg.sender][spender] = tokens;
			emit Approval(msg.sender, spender, tokens);
			ApproveAndCallFallFIREk(spender).receiveApproval(msg.sender, tokens, this, data);
			return true;
		}


		// ------------------------------------------------------------------------
		// Don't accept ETH
		// ------------------------------------------------------------------------
		function () public payable {
			revert();
		}
	}