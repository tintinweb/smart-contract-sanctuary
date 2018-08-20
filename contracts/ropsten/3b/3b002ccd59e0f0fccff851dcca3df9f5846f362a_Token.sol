pragma solidity ^0.4.18;
 
contract Token {
    string public symbol = "";
    string public name = "";
    uint8 public constant decimals = 18;
	string public constant ICOFactoryVersion = "1.0";
    uint256 _totalSupply = 0;
	uint256 _oneEtherEqualsInWei = 0;	
	uint256 _maxICOpublicSupply = 0;
	uint256 _ownerICOsupply = 0;
	uint256 _currentICOpublicSupply = 0;
	uint256 _blockICOdatetime = 0;
	address _ICOfundsReceiverAddress = 0;
	address _remainingTokensReceiverAddress = 0;
    address owner = 0;	
    bool setupDone = false;
	bool isICOrunning = false;
	bool ICOstarted = false;
	uint256 ICOoverTimestamp = 0;
   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed _owner, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    function Token(address adr) public {
        owner = adr;        
    }
	
	function() public payable
	{
		if ((isICOrunning && _blockICOdatetime == 0) || (isICOrunning && _blockICOdatetime > 0 && now <= _blockICOdatetime))
		{
			uint256 _amount = ((msg.value * _oneEtherEqualsInWei) / 1000000000000000000);
			
			if (((_currentICOpublicSupply + _amount) > _maxICOpublicSupply) && _maxICOpublicSupply > 0) revert();
			
			if(!_ICOfundsReceiverAddress.send(msg.value)) revert();					
			
			_currentICOpublicSupply += _amount;
			
			balances[msg.sender] += _amount;
			
			_totalSupply += _amount;			
			
			Transfer(this, msg.sender, _amount);
		}
		else
		{
			revert();
		}
	}
   
    function SetupToken(string tokenName, string tokenSymbol, uint256 oneEtherEqualsInWei, uint256 maxICOpublicSupply, uint256 ownerICOsupply, address remainingTokensReceiverAddress, address ICOfundsReceiverAddress, uint256 blockICOdatetime) public
    {
        if (msg.sender == owner && !setupDone)
        {
            symbol = tokenSymbol;
            name = tokenName;
			_oneEtherEqualsInWei = oneEtherEqualsInWei;
			_maxICOpublicSupply = maxICOpublicSupply * 1000000000000000000;									
			if (ownerICOsupply > 0)
			{
				_ownerICOsupply = ownerICOsupply * 1000000000000000000;
				_totalSupply = _ownerICOsupply;
				balances[owner] = _totalSupply;
				Transfer(this, owner, _totalSupply);
			}			
			_ICOfundsReceiverAddress = ICOfundsReceiverAddress;
			if (_ICOfundsReceiverAddress == 0) _ICOfundsReceiverAddress = owner;
			_remainingTokensReceiverAddress = remainingTokensReceiverAddress;
			_blockICOdatetime = blockICOdatetime;			
            setupDone = true;
        }
    }
	
	function StartICO() public returns (bool success)
    {
        if (msg.sender == owner && !ICOstarted && setupDone)
        {
            ICOstarted = true;			
			isICOrunning = true;			
        }
		else
		{
			revert();
		}
		return true;
    }
	
	function StopICO() public returns (bool success)
    {
        if (msg.sender == owner && isICOrunning)
        {            
			if (_remainingTokensReceiverAddress != 0 && _maxICOpublicSupply > 0)
			{
				uint256 _remainingAmount = _maxICOpublicSupply - _currentICOpublicSupply;
				if (_remainingAmount > 0)
				{
					balances[_remainingTokensReceiverAddress] += _remainingAmount;
					_totalSupply += _remainingAmount;
					Transfer(this, _remainingTokensReceiverAddress, _remainingAmount);	
				}
			}				
			isICOrunning = false;	
			ICOoverTimestamp = now;
        }
		else
		{
			revert();
		}
		return true;
    }
	
	function BurnTokens(uint256 amountInWei) public returns (bool success)
    {
		if (balances[msg.sender] >= amountInWei)
		{
			balances[msg.sender] -= amountInWei;
			_totalSupply -= amountInWei;
			Burn(msg.sender, amountInWei);
			Transfer(msg.sender, 0, amountInWei);
		}
		else
		{
			revert();
		}
		return true;
    }
 
    function totalSupply() public constant returns (uint256 totalSupplyValue) {        
        return _totalSupply;
    }
	
	function OneEtherEqualsInWei() public constant returns (uint256 oneEtherEqualsInWei) {        
        return _oneEtherEqualsInWei;
    }
	
	function MaxICOpublicSupply() public constant returns (uint256 maxICOpublicSupply) {        
        return _maxICOpublicSupply;
    }
	
	function OwnerICOsupply() public constant returns (uint256 ownerICOsupply) {        
        return _ownerICOsupply;
    }
	
	function CurrentICOpublicSupply() public constant returns (uint256 currentICOpublicSupply) {        
        return _currentICOpublicSupply;
    }
	
	function RemainingTokensReceiverAddress() public constant returns (address remainingTokensReceiverAddress) {        
        return _remainingTokensReceiverAddress;
    }
	
	function ICOfundsReceiverAddress() public constant returns (address ICOfundsReceiver) {        
        return _ICOfundsReceiverAddress;
    }
	
	function Owner() public constant returns (address ownerAddress) {        
        return owner;
    }
	
	function SetupDone() public constant returns (bool setupDoneFlag) {        
        return setupDone;
    }
    
	function IsICOrunning() public constant returns (bool isICOrunningFalg) {        
        return isICOrunning;
    }
	
	function IsICOstarted() public constant returns (bool isICOstartedFlag) {        
        return ICOstarted;
    }
	
	function ICOoverTimeStamp() public constant returns (uint256 ICOoverTimestampCheck) {        
        return ICOoverTimestamp;
    }
	
	function BlockICOdatetime() public constant returns (uint256 blockStopICOdate) {        
        return _blockICOdatetime;
    }
	
	function TimeNow() public constant returns (uint256 timenow) {        
        return now;
    }
	 
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}