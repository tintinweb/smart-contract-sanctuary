pragma solidity ^0.4.24;
contract Bill {
    mapping (address => uint256) balances;
	mapping (address => uint256) fundValue;
	address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public minFundedValue;
	uint256 public maxFundedValue;
    bool public isFundedMax;
    bool public isFundedMini;
    uint256 public closeTime;
    uint256 public startTime;
    
     /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function Bill(
	    address _owner,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
		uint256 _totalSupply,
        uint256 _closeTime,
        uint256 _startTime,
		uint256 _minValue,
		uint256 _maxValue
        ) { 
        owner = _owner;                                      // Set owner of contract 
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        closeTime = _closeTime;                              // Set fund closing time
		startTime = _startTime;                              // Set fund start time
		totalSupply = _totalSupply;                          // Total supply
		minFundedValue = _minValue;                          // Set minimum funding goal
		maxFundedValue = _maxValue;                          // Set max funding goal
		isFundedMax = false;                                 // Initialize fund minimum flag 
		isFundedMini = false;                                // Initialize fund max flag
		balances[owner] = _totalSupply;                      // Set owner balance equal totalsupply 
    }
    
	/*default-function called when values are sent */
	function () payable {
       buyBILL();
    }
	
    /*send ethereum and get BILL*/
    function buyBILL() payable returns (bool success){
		if(msg.sender == owner) throw;
        if(now > closeTime) throw; 
        if(now < startTime) throw;
        if(isFundedMax) throw;
        uint256 token = 0;
        if(closeTime - 2 weeks > now) {
             token = msg.value;
        }else {
            uint day = (now - (closeTime - 2 weeks))/(2 days) + 1;
            token = msg.value;
            while( day > 0) {
                token  =   token * 95 / 100 ;    
                day -= 1;
            }
        }
        
        balances[msg.sender] += token;
        if(balances[owner] < token) 
            return false;
        balances[owner] -= token;
        if(this.balance >= minFundedValue) {
            isFundedMini = true;
        }
        if(this.balance >= maxFundedValue) {
            isFundedMax = true;   
        }
		fundValue[msg.sender] += msg.value;
        Transfer(owner, msg.sender, token);    
        return true;
    }    
    
     /*query BILL balance*/
    function balanceOf( address _owner) constant returns (uint256 value)
    {
        return balances[_owner];
    }
	
	/*query fund ethereum balance */
	function balanceOfFund(address _owner) constant returns (uint256 value)
	{
		return fundValue[_owner];
	}

    /*refund &#39;msg.sender&#39; in the case the Token Sale didn&#39;t reach ite minimum 
    funding goal*/
    function reFund() payable returns (bool success) {
        if(now <= closeTime) throw;     
		if(isFundedMini) throw;             
		uint256 value = fundValue[msg.sender];
		fundValue[msg.sender] = 0;
		if(value <= 0) throw;
        if(!msg.sender.send(value)) 
            throw;
        balances[owner] +=  balances[msg.sender];
        balances[msg.sender] = 0;
        Transfer(msg.sender, this, balances[msg.sender]); 
        return true;
    }

	
	/*refund _fundaddr in the case the Token Sale didn&#39;t reach its minimum 
    funding goal*/
	function reFundByOther(address _fundaddr) payable returns (bool success) {
	    if(now <= closeTime) throw;    
		if(isFundedMini) throw;           
		uint256 value = fundValue[_fundaddr];
		fundValue[_fundaddr] = 0;
		if(value <= 0) throw;
        if(!_fundaddr.send(value)) throw;
        balances[owner] += balances[_fundaddr];
        balances[_fundaddr] = 0;
        Transfer(msg.sender, this, balances[_fundaddr]); 
        return true;
	}

    
    /* Send coins */
    function transfer(address _to, uint256 _value) payable returns (bool success) {
        if(_value <= 0 ) throw;                                      // Check send token value > 0;
		if (balances[msg.sender] < _value) throw;                    // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) throw;           // Check for overflows
		if(now < closeTime ) {										 // unclosed allowed retrieval, Closed fund allow transfer   
			if(_to == address(this)) {
				fundValue[msg.sender] -= _value;
				balances[msg.sender] -= _value;
				balances[owner] += _value;
				if(!msg.sender.send(_value))
					return false;
				Transfer(msg.sender, _to, _value); 							// Notify anyone listening that this transfer took place
				return true;      
			}
		} 										
		
		balances[msg.sender] -= _value;                          // Subtract from the sender
		balances[_to] += _value;                                 // Add the same to the recipient                       
		 
		Transfer(msg.sender, _to, _value); 							// Notify anyone listening that this transfer took place
		return true;      
    }
    
    /*send reward*/
    function sendRewardBILL(address rewarder, uint256 value) payable returns (bool success) {
        if(msg.sender != owner) throw;
		if(now <= closeTime) throw;        
		if(!isFundedMini) throw;               
        if( balances[owner] < value) throw;
        balances[rewarder] += value;
        uint256 halfValue  = value / 2;
        balances[owner] -= halfValue;
        totalSupply +=  halfValue;
        Transfer(owner, rewarder, value);    
        return true;
       
    }
    
    function modifyStartTime(uint256 _startTime) {
		if(msg.sender != owner) throw;
        startTime = _startTime;
    }
    
    function modifyCloseTime(uint256 _closeTime) {
		if(msg.sender != owner) throw;
       closeTime = _closeTime;
    }
    
    /*withDraw ethereum when closed fund*/
    function withDrawEth(uint256 value) payable returns (bool success) {
        if(now <= closeTime ) throw;
        if(!isFundedMini) throw;
        if(this.balance < value) throw;
        if(msg.sender != owner) throw;
        if(!msg.sender.send(value))
            return false;
        return true;
    }
}