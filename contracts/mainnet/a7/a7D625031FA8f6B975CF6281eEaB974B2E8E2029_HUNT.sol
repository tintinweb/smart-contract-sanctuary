pragma solidity ^0.4.11;

	//	HUNT Crowdsale Token Contract 
	//	Aqua Commerce LTD Company #194644 (Republic of Seychelles)
	//	The MIT Licence .


contract SafeMath {
	
    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }
	
	function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }
	
	function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x <= y ? x : y;
    }
}


contract Owned {
    
	address public owner;
    address public newOwner;
	
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert (msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


//	ERC20 interface
//	see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
	
	function totalSupply() constant returns (uint totalSupply);
	function balanceOf(address who) constant returns (uint);
	function allowance(address owner, address spender) constant returns (uint);
	
	function transfer(address to, uint value) returns (bool ok);
	function transferFrom(address from, address to, uint value) returns (bool ok);
	function approve(address spender, uint value) returns (bool ok);
  
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


contract StandardToken is ERC20, SafeMath {
	
	uint256                                            _totalSupply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    modifier onlyPayloadSize(uint numwords) {
		assert(msg.data.length == numwords * 32 + 4);
        _;
   }
   
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _who) constant returns (uint256) {
        return _balances[_who];
    }
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return _approvals[_owner][_spender];
    }
    
    function transfer(address _to, uint _value) onlyPayloadSize(2) returns (bool success) {
        assert(_balances[msg.sender] >= _value);
        
        _balances[msg.sender] = sub(_balances[msg.sender], _value);
        _balances[_to] = add(_balances[_to], _value);
        
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3) returns (bool success) {
        assert(_balances[_from] >= _value);
        assert(_approvals[_from][msg.sender] >= _value);
        
        _approvals[_from][msg.sender] = sub(_approvals[_from][msg.sender], _value);
        _balances[_from] = sub(_balances[_from], _value);
        _balances[_to] = add(_balances[_to], _value);
        
        Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success) {
        _approvals[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        
        return true;
    }

}

contract HUNT is StandardToken, Owned {

    // Token information
	string public constant name = "HUNT";
    string public constant symbol = "HT";
    uint8 public constant decimals = 18;
	
    // Initial contract data
	uint256 public capTokens;
    uint256 public startDate;
    uint256 public endDate;
    uint public curs;
	
	address addrcnt;
	uint256 public totalTokens;
	uint256 public totalEthers;
	mapping (address => uint256) _userBonus;
	
    event BoughtTokens(address indexed buyer, uint256 ethers,uint256 newEtherBalance, uint256 tokens, uint _buyPrice);
	event Collect(address indexed addrcnt,uint256 amount);
	
    function HUNT(uint256 _start, uint256 _end, uint256 _capTokens, uint _curs, address _addrcnt) {
        startDate	= _start;
		endDate		= _end;
        capTokens   = _capTokens;
        addrcnt  	= _addrcnt;
		curs		= _curs;
    }

	function time() internal constant returns (uint) {
        return block.timestamp;
    }
	
    // Cost of one token
    // Day  1-2  : 1 USD = 1 HUNT
    // Days 3–5  : 1.2 USD = 1 HUNT
    // Days 6–10 : 1.3 USD = 1 HUNT
    // Days 11–15: 1.4 USD = 1 HUNT
    // Days 16–22: 1.5 USD = 1 HUNT
    
    
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(time());
    }

	function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 2 days)) {
            return div(curs,100);
        } else if (at < (startDate + 5 days)) {
            return div(curs,120);
        } else if (at < (startDate + 10 days)) {
            return div(curs,130);
        } else if (at < (startDate + 15 days)) {
            return div(curs,140);
        } else if (at <= endDate) {
            return div(curs,150);
        } else {
            return 0;
        }
    }

    // Buy tokens from the contract
    function () payable {
        buyTokens(msg.sender);
    }

    // Exchanges can buy on behalf of participant
    function buyTokens(address participant) payable {
        
		// No contributions before the start of the crowdsale
        require(time() >= startDate);
        
		// No contributions after the end of the crowdsale
        require(time() <= endDate);
        
		// No 0 contributions
        require(msg.value > 0);

        // Add ETH raised to total
        totalEthers = add(totalEthers, msg.value);
        
		// What is the HUNT to ETH rate
        uint256 _buyPrice = buyPrice();
		
        // Calculate #HUNT - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        uint tokens = msg.value * _buyPrice;

        // Check tokens > 0
        require(tokens > 0);

		if ((time() >= (startDate + 15 days)) && (time() <= endDate)){
			uint leftTokens=sub(capTokens,add(totalTokens, tokens));
			leftTokens = (leftTokens>0)? leftTokens:0;
			uint bonusTokens = min(_userBonus[participant],min(tokens,leftTokens));
			
			// Check bonusTokens >= 0
			require(bonusTokens >= 0);
			
			tokens = add(tokens,bonusTokens);
        }
		
		// Cannot exceed capTokens
		totalTokens = add(totalTokens, tokens);
        require(totalTokens <= capTokens);

		// Compute tokens for foundation 38%
        // Number of tokens restricted so maths is safe
        uint ownerTokens = div(tokens,50)*19;

		// Add to total supply
        _totalSupply = add(_totalSupply, tokens);
		_totalSupply = add(_totalSupply, ownerTokens);
		
        // Add to balances
        _balances[participant] = add(_balances[participant], tokens);
		_balances[owner] = add(_balances[owner], ownerTokens);

		// Add to user bonus
		if (time() < (startDate + 2 days)){
			uint bonus = div(tokens,2);
			_userBonus[participant] = add(_userBonus[participant], bonus);
        }
		
		// Log events
        BoughtTokens(participant, msg.value, totalEthers, tokens, _buyPrice);
        Transfer(0x0, participant, tokens);
		Transfer(0x0, owner, ownerTokens);

    }

    // Transfer the balance from owner&#39;s account to another account, with a
    // check that the crowdsale is finalised 
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends + 7 days
        require((time() > endDate + 7 days ));
        // Standard transfer
        return super.transfer(_to, _amount);
    }

    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with a check that the crowdsale is
    // finalised 
    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends + 7 days
        require((time() > endDate + 7 days ));
        // Standard transferFrom
        return super.transferFrom(_from, _to, _amount);
    }

    function mint(uint256 _amount) onlyOwner {
        require((time() > endDate + 7 days ));
        require(_amount > 0);
        _balances[owner] = add(_balances[owner], _amount);
        _totalSupply = add(_totalSupply, _amount);
        Transfer(0x0, owner, _amount);
    }

    function burn(uint256 _amount) onlyOwner {
		require((time() > endDate + 7 days ));
        require(_amount > 0);
        _balances[owner] = sub(_balances[owner],_amount);
        _totalSupply = sub(_totalSupply,_amount);
		Transfer(owner, 0x0 , _amount);
    }
    
	function setCurs(uint _curs) onlyOwner {
        require(_curs > 0);
        curs = _curs;
    }

  	// Crowdsale owners can collect ETH any number of times
    function collect() onlyOwner {
		require(addrcnt.call.value(this.balance)(0));
		Collect(addrcnt,this.balance);
	}
}