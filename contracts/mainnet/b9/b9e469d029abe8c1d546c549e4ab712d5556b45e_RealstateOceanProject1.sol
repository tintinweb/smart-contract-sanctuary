pragma solidity ^0.4.18;
	
	contract ERC20 {
	  uint public totalSupply;
	  function balanceOf(address who) constant returns (uint);
	  function allowance(address owner, address spender) constant returns (uint);
	

	  function transfer(address _to, uint _value) returns (bool success);
	  function transferFrom(address _from, address _to, uint _value) returns (bool success);
	  function approve(address spender, uint value) returns (bool ok);
	  event Transfer(address indexed from, address indexed to, uint value);
	  event Approval(address indexed owner, address indexed spender, uint value);
	}
	

	/**
	 * Math operations with safety checks
	 */
	contract SafeMath {
	  function safeMul(uint a, uint b) internal returns (uint) {
	    uint c = a * b;
	    assert(a == 0 || c / a == b);
	    return c;
	  }
	

	  function safeDiv(uint a, uint b) internal returns (uint) {
	    assert(b > 0);
	    uint c = a / b;
	    assert(a == b * c + a % b);
	    return c;
	  }
	

	  function safeSub(uint a, uint b) internal returns (uint) {
	    assert(b <= a);
	    return a - b;
	  }
	

	  function safeAdd(uint a, uint b) internal returns (uint) {
	    uint c = a + b;
	    assert(c>=a && c>=b);
	    return c;
	  }
	

	  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
	    return a >= b ? a : b;
	  }
	

	  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
	    return a < b ? a : b;
	  }
	

	  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
	    return a >= b ? a : b;
	  }
	

	  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
	    return a < b ? a : b;
	  }
	}
	

	contract StandardToken is ERC20, SafeMath {
	

	  /* Token supply got increased and a new owner received these tokens */
	  event Minted(address receiver, uint amount);
	

	  /* Actual balances of token holders */
	  mapping(address => uint) balances;
	

	  /* approve() allowances */
	  mapping (address => mapping (address => uint)) allowed;
	

	  /* Interface declaration */
	  function isToken() public constant returns (bool weAre) {
	    return true;
	  }
	

	  function transfer(address _to, uint _value) returns (bool success) {
	    balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	  }
	

	  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
	    uint _allowance = allowed[_from][msg.sender];
	

	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
	  }
	

	  function balanceOf(address _owner) constant returns (uint balance) {
	    return balances[_owner];
	  }
	

	  function approve(address _spender, uint _value) returns (bool success) {

	
	    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
	

	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	  }
	

	  function allowance(address _owner, address _spender) constant returns (uint remaining) {
	    return allowed[_owner][_spender];
	  }
	}

	contract RealstateOceanProject1 is StandardToken {
	

	    string public name = "Realstate Ocean Project 1";
	    string public symbol = "RSO-P1";
	    uint public decimals = 18;
	    uint EthPrice = 385;
	 
        function set(uint x) public onlyOwner {
        EthPrice = x;
        }


	    /**
	     * Boolean contract states
	     */
	    bool halted = false; //the founder address can set this to true to halt the whole ICO event due to emergency
	    bool ICO = true; //ICO state
	    bool public freeze = true; //Freeze state
	

	    /**
	     * Initial founder address (set in constructor)
	     * All deposited ETH will be forwarded to this address.
	     */
	    address founder = 0x0;
	    address owner = 0x0;
	

	    /**
	     * Token count
	     */
	    uint totalTokens = 100000000 * 10**18;
	    uint team = 0; // No Team
	    uint bounty = 0; // No Bounty
	

	    /**
	     * ICO cap
	     */
	    uint ICOCap = 10000000120 * 10**18; // Max amount raised during ICO is 10.000.000 // 1000 unidades representan 1 ETH 


	    /**
	     * Statistic values
	     */
	    uint presaleTokenSupply = 0; // This will keep track of the token supply created during the event
	    uint presaleEtherRaised = 0; // This will keep track of the Ether raised during the event
	    uint ICOTokenSupply = 0; // This will keep track of the token supply created during the ICO
	

	    event Buy(address indexed sender, uint eth, uint fbt);
	

	    /* This generates a public event on the blockchain that will notify clients */
	    event TokensSent(address indexed to, uint256 value);
	    event ContributionReceived(address indexed to, uint256 value);
	    event Burn(address indexed from, uint256 value);
	

	    function RealstateOceanProject1(address _founder) payable {
	        owner = msg.sender;
	        founder = _founder;
	

	        // Move team token pool to founder balance
	        balances[founder] = team;
	        // Sub from total tokens team pool
	        totalTokens = safeSub(totalTokens, team);
	        // Sub from total tokens bounty pool
	        totalTokens = safeSub(totalTokens, bounty);
	        // Total supply is 100000000
	        totalSupply = totalTokens;
	        balances[owner] = totalSupply;
	    }
	

	    /**
	     * 1 RSO-P1 = 1 FINNEY
	     * Price is 1000 Realstate Ocean Projetc 1 for 1 ETH
	     */
	    function price() constant returns (uint){
	        return 1 finney;
	    }
	

	    /**
	      * The basic entry point to participate the event process.
	      *
	      * Pay for funding, get invested tokens back in the sender address.
	      */
	    function buy() public payable returns(bool) {
	        // Buy allowed if contract is not on halt
	        require(!halted);
	        // Amount of wei should be more that 0
	        require(msg.value>0);
	

	        // Count expected tokens price
	        uint tokens = msg.value * 10**18 / price();
	

	        // Total tokens should be more than user want&#39;s to buy
	        require(balances[owner]>tokens);
	

	        // ICO Token Price
	        if (ICO) {
	            tokens = (tokens / 1000) * EthPrice;
	        }
	

	        // Check how much tokens already sold
	        if (ICO) {
	            // Check that required tokens count are less than tokens already sold on ICO
	            require(safeAdd(presaleTokenSupply, tokens) < ICOCap);
	        } 

	        // Send wei to founder address
	        founder.transfer(msg.value);
	

	        // Add tokens to user balance and remove from totalSupply
	        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
	        // Remove sold tokens from total supply count
	        balances[owner] = safeSub(balances[owner], tokens);
	

	        // Update stats
	        if (ICO) {
	            ICOTokenSupply  = safeAdd(ICOTokenSupply, tokens);
	        }
	        presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
	        presaleEtherRaised = safeAdd(presaleEtherRaised, msg.value);
	

	        // Send buy RSO-P1 token action
	        Buy(msg.sender, msg.value, tokens);
	

	        // /* Emit log events */
	        TokensSent(msg.sender, tokens);
	        ContributionReceived(msg.sender, msg.value);
	        Transfer(owner, msg.sender, tokens);
	

	        return true;
	    }
	

	    /**
	     * ICO state.
	     */
	    function InitialPriceEnable() onlyOwner() {
	        ICO = true;
	    }
	

	    function InitialPriceDisable() onlyOwner() {
	        ICO = false;
	    }
		
	  
	    /**
	     * Emergency stop whole ICO event.
	     */
	    function EventEmergencyStop() onlyOwner() {
	        halted = true;
	    }
	

	    function EventEmergencyContinue() onlyOwner() {
	        halted = false;
	    }
	

	    /**
	     * ERC 20 Standard Token interface transfer function
	     *
	     * Prevent transfers until halt period is over.
	     */
	    function transfer(address _to, uint256 _value) isAvailable() returns (bool success) {
	        return super.transfer(_to, _value);
	    }
	    /**
	     * ERC 20 Standard Token interface transfer function
	     *
	     * Prevent transfers until halt period is over.
	     */
	    function transferFrom(address _from, address _to, uint256 _value) isAvailable() returns (bool success) {
	        return super.transferFrom(_from, _to, _value);
	    }
	

	    /**
	     * Burn all tokens from a balance.
	     */
	    function burnRemainingTokens() isAvailable() onlyOwner() {
	        Burn(owner, balances[owner]);
	        balances[owner] = 0;
	    }
	

	    modifier onlyOwner() {
	        require(msg.sender == owner);
	        _;
	    }
	

	    modifier isAvailable() {
	        require(!halted && !freeze);
	        _;
	    }
	

	    /**
	     * Buy tokens
	     */
	    function() payable {
	        buy();
	    }
	

	    /**
	     * Freeze and unfreeze ICO.
	     */
	    function freeze() onlyOwner() {
	         freeze = true;
	    }
	

	     function unFreeze() onlyOwner() {
	         freeze = false;
	     }
}