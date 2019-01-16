pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient
{
	function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract Token 
{
	/**
	* @dev Standard ERC223 function that will handle incoming token transfers.
	*
	* @param _from  Token sender address.
	* @param _value Amount of tokens.
	* @param _data  Transaction metadata.
	*/
	function tokenFallback(address _from, uint _value, bytes memory _data) public;

	function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool);
}

contract UnBasicIncome 
{
	// Public variables of the token
	string	public	name;
	string	public	symbol;
	uint8	public	decimals;
	uint256	public	totalS;
	
	// Private variables of the token
	uint    internal _minTimeForPercent=20*60;    //time in seconds
	uint    internal _timePercentDivider=60*60;     //one hour
	uint    internal _startTime;                //for calc all other
	uint    internal _timeLen1=3600*36;         //36 hours
	uint    internal _timeLen2=3600*108;        //include _timeLen1 so 72 hours

	uint256 internal _minValForPercent=1638400;
	address	payable internal _mainOwner=0x394b570584F2D37D441E669e74563CD164142930;


	struct account
	{
		uint256 balance;
		uint	timeLastAccess;
	}


	// This creates an array with all balances and it time Last Access
	mapping (address => account) internal _accounts;
	mapping (address => mapping (address => uint256)) internal _allowed;

	// This generates a public event on the blockchain that will notify clients
//	event Transfer(address indexed from, address indexed to, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value,bytes _data);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);


	constructor() public 
	{
		name="Unconditional Basic Income";	// Set the name for display purposes
		symbol="UBI05";				// Set the symbol for display purposes
		decimals=2;                 //total = 128*1024*1024*1024
		totalS=13743895347200;		// Update total supply with the decimal amount
		_accounts[_mainOwner].balance=totalS;	// Give the creator all initial tokens
		_startTime=now;
		_accounts[_mainOwner].timeLastAccess=_startTime;
        	_timeLen1+=_startTime;         //calc one time !
        	_timeLen2+=_startTime;

	}


	//test contract is or not
	function isContract(address _addr) private view returns (bool)
	{
        	uint length;
        	assembly
        	{
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	// entry to buy tokens
	function () external payable 
	{        
		buy();
	}

	/// @notice entry to buy tokens
	function buy() public payable returns(bool)
	{
		// reject contract buyer to avoid breaking interval limit
		require(!isContract(msg.sender));

        	uint timeNow=now;
        	uint tokensForEth=3355443200;

		uint256 amount=(tokensForEth*msg.value)/100 ether;
		amount=amount*100;
        
		_transfer(_mainOwner,msg.sender,amount);    //send tokens to buyer
        	_mainOwner.transfer(msg.value);         //send ether to _mainOwner
	}

	function tokenFallback(address _from, uint _value, bytes memory _data) public payable 
	{
		Token receiver = Token(msg.sender);
		receiver.transfer(_mainOwner, _value, _data);

	}

	/**
	* Internal transfer, only can be called by this contract
	*/
	function _transfer(address _from, address _to, uint _value) internal 
	{
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != address(0x0));
		
		
		// Check if the sender has enough
		require(_accounts[_from].balance >= _value);
		// Check for overflows
		require(_accounts[_to].balance + _value > _accounts[_to].balance);
		// Save this for an assertion in the future
		uint256 previousBalances = _accounts[_from].balance + _accounts[_to].balance;
		// Subtract from the sender
		_accounts[_from].balance -= _value;
		// Add the same to the recipient
		_accounts[_to].balance += _value;
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
		assert(_accounts[_from].balance + _accounts[_to].balance == previousBalances);
		
		//get commission fee
		uint256 cfee=_value>>15;    //cfee=100/(128*256)
		if(cfee>0)                  //round fee to 1 token
		{
			cfee=cfee*100;
			require(_accounts[_from].balance >= cfee);
			_accounts[_from].balance -= cfee;
            		uint newBal=totalS-cfee;
        		require(newBal < totalS);       // Check for overflows                
        		totalS=newBal;
		}
		

		bytes memory empty;
		emit Transfer(_from, _to, _value,empty);
	}


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
	{
		uint256 allowance = _allowed[_from][msg.sender];
        
		require(allowance >= _value);        
        
		_allowed[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		emit Approval(_from, msg.sender, _allowed[_from][msg.sender]);
		return true;
	}




	function transfer(address _to, uint256 _value) public returns(bool) 
	{
		bytes memory empty;
		_transfer(msg.sender, _to, _value);
		if(isContract(_to))
		{
			Token receiver = Token(_to);
			receiver.tokenFallback(msg.sender, _value, empty);
		}
		return true;
	}
	
	
	function transfer(address _to, uint _value, bytes memory _data) public returns(bool) 
	{
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
		if(isContract(_to))
        	{
			Token receiver = Token(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
        
		return true;        
	}
	

	function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool)
	{
        	tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value))
		{
			spender.receiveApproval(msg.sender, _value, address(this), _extraData);
			return true;
		}
	}


	function approve(address _spender, uint256 _value) public returns(bool)
	{
		require(_spender != address(0));
		_allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address owner, address spender) public view returns (uint256)
	{
		return _allowed[owner][spender];
	}

	function balanceOf(address _owner) public view returns(uint256)
	{
		return _accounts[_owner].balance;
	}

    	// Function to access total supply of tokens .
	function totalSupply() public view returns(uint256) 
	{
		return totalS;
	}
}