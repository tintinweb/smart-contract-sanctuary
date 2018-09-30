pragma solidity ^0.4.18;

/**
 * @title SafeMath
 */
library SafeMath {

    /**
    * Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AltcoinToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NIGHT is ERC20, Owned {
    
    using SafeMath for uint256;
    address owner = msg.sender;
	
	// address owner = 0xB097Bf1930b339f5C40d45954a9cD90FBbd02510;
	
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "NIGHT";
    string public constant symbol = "NIGHT";
    uint public constant decimals = 2;
    
    uint256 public totalSupply =  100000000;
    uint256 public totalDistributed = 0; 
    uint256 public totalIcoDistributed = 0;
    uint256 public constant minContribution = 1 ether / 100; // 0.01 Eth
	
	uint256 public tokensPerEth = 0;
	
	// ------------------------------
    // Token Distribution and Address
    // ------------------------------
    
    // saleable 75%
    uint256 public constant totalIco = 75000000;
    uint256 public totalIcoDist = 0;
    address storageIco = owner;
    
    // airdrop 5%
    uint256 public constant totalAirdrop = 5000000;
    address storageAirdrop = 0xd06EA246FDb6Eb08C61bc0fe5Ba3865792c02202;
    
    // developer 20%
    uint256 public constant totalDeveloper = 25000000;
    address storageDev = 0x341a7EF6CccE6302Da31b186597ae4144575f102;
    
    
    // ---------------------
    // sale start and price
    // ---------------------
    
    // presale
	uint public presaleStartTime = 1536768000; // 23.00
    uint256 public presalePerEth = 200000;
    
    // ico
    uint public icoStartTime = 1536768900;
    uint256 public icoPerEth = 100000;
    
    // ico1
    uint public ico1StartTime = 1536769800;
    uint256 public ico1PerEth = 50000;
    
    // ico2
    uint public ico2StartTime = 1536770700;
    uint256 public ico2PerEth = 10000;
    
    //ico start and end
    uint public icoOpenTime = presaleStartTime;
    uint public icoEndTime = 1536771600;
    
	// -----------------------
	// events
	// -----------------------
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);
    
    event Burn(address indexed burner, uint256 value);
	
	event Sent(address from, address to, uint amount);
	
	
	// -------------------
	// STATE
	// ---------------------
    bool public icoOpen = false; // allow to buy
    bool public icoFinished = false; // stop buy
    bool public distributionFinished = false;
    
    
    // -----
    // temp
    // -----
    uint256 public tTokenPerEth = 0;
    bool public tIcoOpen = false;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
        
        //creator is owner
        transferOwnership(owner);
        
        //initial distribution
        distr(storageAirdrop,totalAirdrop);
        distr(storageDev,totalDeveloper);
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    
    
    // ORI
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
 //   modifier onlyOwner() {
  //      require(msg.sender == owner);
  //      _;
 //   }
    
    
  
  /*  
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
*/
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        balances[owner] = balances[owner].sub(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
	
	function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    
    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
				
		//owner withdraw 
		if (msg.sender == owner && msg.value == 0){
			withdraw();
		}
		
		if(msg.sender != owner){
			if ( now < icoOpenTime ){
				revert(&#39;ICO does not open yet&#39;);
			}
			
			//is Open
			if ( ( now >= icoOpenTime ) && ( now <= icoEndTime ) ){
				icoOpen = true;
			}
			
			if ( now > icoEndTime ){
				icoOpen = false;
				icoFinished = true;
				distributionFinished = true;
			}
			
			if ( icoFinished == true ){
				revert(&#39;ICO has finished&#39;);
			}
			
			if ( distributionFinished == true ){
				revert(&#39;Token distribution has finished&#39;);
			}
			
			// ico is open
			if ( icoOpen == true ){
				// set price
				if ( now >= presaleStartTime && now < icoStartTime){ tTokenPerEth = presalePerEth; }
				if ( now >= icoStartTime && now < ico1StartTime){ tTokenPerEth = icoPerEth; }
				if ( now >= ico1StartTime && now < ico2StartTime){ tTokenPerEth = ico1PerEth; }
				if ( now >= ico2StartTime && now < icoEndTime){ tTokenPerEth = ico2PerEth; }
				
				tokensPerEth = tTokenPerEth;
				
				getTokens();
				
			}
		}
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;

        require( msg.value >= minContribution );

        require( msg.value > 0 );
        
        tokens = tokensPerEth.mul(msg.value) / 1 ether;
        address investor = msg.sender;
        
        
        if ( icoFinished == true ){
			revert(&#39;ICO Has Finished&#39;);
		}
        
        //remaining ballance
        if( balances[owner] < tokens ){
			revert(&#39;Insufficient Token Balance or Sold Out.&#39;);
		}
        
        if (tokens < 0){
			revert();
		}
        
        totalIcoDistributed += tokens;
        
        if (tokens > 0) {
           distr(investor, tokens);           
        }

        if (totalIcoDistributed >= totalIco) {
            distributionFinished = true;
        }
    }
	
	
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        AltcoinToken t = AltcoinToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawAltcoinTokens(address _tokenContract) onlyOwner public returns (bool) {
        AltcoinToken token = AltcoinToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    
}