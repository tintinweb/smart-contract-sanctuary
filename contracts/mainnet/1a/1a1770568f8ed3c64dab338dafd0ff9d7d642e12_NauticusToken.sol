pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;NTS&#39; Nauticus Token Fixed Supply
//
// Symbol      : NTS
// Name        : NauticusToken
// Total supply: 2,500,000,000.000000000000000000
// Decimals    : 18
//
// (c) Nauticus 
// ----------------------------------------------------------------------------

/**
 * @dev the Permission contract provides basic access control.
 */
contract Permission {
    address public owner;
	function Permission() public {
        owner = msg.sender;
    }

	modifier onlyOwner() { 
		require(msg.sender == owner);
		_;
	}

	function changeOwner(address newOwner) onlyOwner public returns (bool) {
		require(newOwner != address(0));
		owner = newOwner;
        return true;
	}
		
}	

/**
 * @dev maintains the safety of mathematical operations.
 */
library Math {

	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		//require(c >= a);
		//require(c >= b);
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


/**
 * @dev implements ERC20 standard, contains the token logic.
 */
contract NauticusToken is Permission {

    //Transfer and Approval events
    event Approval(address indexed owner, address indexed spender, uint val);
    event Transfer(address indexed sender, address indexed recipient, uint val);

    //implement Math lib for safe mathematical transactions.
    using Math for uint;
    
    //Inception and Termination of Nauticus ICO
    //          DD/MM/YYYY
    // START    18/03/2018 NOON GMT
    // END      18/05/2018 NOON GMT
    //          
    uint public constant inception = 1521331200;
    uint public constant termination = 1526601600;

    //token details
    string public constant name = "NauticusToken";
	string public constant symbol = "NTS";
	uint8 public constant decimals = 18;

    //number of tokens that exist, totally.
    uint public totalSupply;
    
    //if the tokens have been minted.
    bool public minted = false;

    //hardcap, maximum amount of tokens that can exist
    uint public constant hardCap = 2500000000000000000000000000;
    
    //if if users are able to transfer tokens between each toher.
    bool public transferActive = false;
    
    //mappings for token balances and allowances.
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /*
        MODIFIERS
    */
	modifier canMint(){
	    require(!minted);
	    _;
	}
	
	/*modifier ICOActive() { 
		require(now > inception * 1 seconds && now < termination * 1 seconds); 
		_; 
	}*/
	
	modifier ICOTerminated() {
	    require(now > termination * 1 seconds);
	    _;
	}

	modifier transferable() { 
		//if you are NOT owner
		if(msg.sender != owner) {
			require(transferActive);
		}
		_;
	}
	
    /*
        FUNCTIONS
    */  
    /**
        @dev approves a spender to spend an amount.
        @param spender address of the spender
        @param val the amount they will be approved to spend.
        @return true
     */
    function approve(address spender, uint val) public returns (bool) {
        allowed[msg.sender][spender] = val;
        Approval(msg.sender, spender, val);
        return true;
    }

    /**
        @dev function to transfer tokens inter-user
        @param to address of the recipient of the tokens
        @param val the amount to transfer
        @return true
     */
	function transfer(address to, uint val) transferable ICOTerminated public returns (bool) {
		//only send to a valid address
		require(to != address(0));
		require(val <= balances[msg.sender]);

		//deduct the val from sender
		balances[msg.sender] = balances[msg.sender] - val;

		//give the val to the recipient
		balances[to] = balances[to] + val;

		//emit transfer event 
		Transfer(msg.sender, to, val);
		return true;
	}

    /**
        @dev returns the balance of NTS for an address
        @return balance NTS balance
     */
	function balanceOf(address client) public constant returns (uint) {
		return balances[client];
	}

    /**
        @dev transfer tokens from one address to another, independant of executor.
        @param from the address of the sender of the tokens.
        @param recipient the recipient of the tokens
        @param val the amount of tokens
        @return true
     */
	function transferFrom(address from, address recipient, uint val) transferable ICOTerminated public returns (bool) {
		//to and from must be valid addresses
		require(recipient != address(0));
		require(from != address(0));
		//tokens must exist in from account
		require(val <= balances[from]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(val);
		balances[from] = balances[from] - val;
		balances[recipient] = balances[recipient] + val;

		Transfer(from,recipient,val);
        return true;
	}
	
    /**
        @dev allows Nauticus to toggle disable all inter-user transfers, ICE.
        @param newTransferState whether inter-user transfers are allowed.
        @return true
     */
	function toggleTransfer(bool newTransferState) onlyOwner public returns (bool) {
	    require(newTransferState != transferActive);
	    transferActive = newTransferState;
	    return true;
	}
	
    /**
        @dev mint the appropriate amount of tokens, which is relative to tokens sold, unless hardcap is reached.
        @param tokensToExist the amount of tokens purchased on the Nauticus platform.
        @return true
     */
	function mint(uint tokensToExist) onlyOwner ICOTerminated canMint public returns (bool) {
	    tokensToExist > hardCap ? totalSupply = hardCap : totalSupply = tokensToExist;
	    balances[owner] = balances[owner].add(totalSupply);
        minted = true;
        transferActive = true;
	    return true;
	    
	}
    /**
        @dev allocate an allowance to a user
        @param holder person who holds the allowance
        @param recipient the recipient of a transfer from the holder
        @return remaining tokens left in allowance
     */
	
    function allowance(address holder, address recipient) public constant returns (uint) {
        return allowed[holder][recipient];
    }
    
    /**
        @dev constructor, nothing needs to happen upon contract creation, left blank.
     */
    function NauticusToken () public {}
	
}