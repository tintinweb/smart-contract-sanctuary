pragma solidity ^0.4.11;
 
contract Token {
    string public symbol = "711";
    string public name = "711 token";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 711000000000000000000;
    address owner = 0;
    bool startDone = false;
    uint public amountRaised;
    uint public deadline;
    uint public overRaisedUnsend = 0;
    uint public backers = 0;
    uint rate = 4;
    uint successcoef = 2;
    uint unreserved = 80;
    uint _durationInMinutes = 0;
    bool fundingGoalReached = false;
    mapping(address => uint256) public balanceOf;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    function Token(address adr) {
		owner = adr;        
    }
	
	function StartICO(uint256 durationInMinutes)
	{
		if (msg.sender == owner && startDone == false)
		{
			balances[owner] = _totalSupply;
			_durationInMinutes = durationInMinutes;
            deadline = now + durationInMinutes * 1 minutes;
			startDone = true;
		}
	}
 
    function totalSupply() constant returns (uint256 totalSupply) {        
		return _totalSupply;
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _amount) returns (bool success) {
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
    ) returns (bool success) {
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
    
    function () payable {
        uint _amount = msg.value;
        uint amount = msg.value;
        _amount = _amount * rate;
        if (amountRaised + _amount <= _totalSupply * unreserved / 100
            && balances[owner] >= _amount
            && _amount > 0
            && balances[msg.sender] + _amount > balances[msg.sender]
            && now <= deadline
            && !fundingGoalReached 
            && startDone) {
        backers += 1;
        balances[msg.sender] += _amount;
        balances[owner] -= _amount;
        amountRaised += _amount;
        Transfer(owner, msg.sender, _amount);
        } else {
            if (!msg.sender.send(amount)) {
                overRaisedUnsend += amount; 
            }
        }
    }
 
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    modifier afterDeadline() { if (now > deadline || amountRaised >= _totalSupply / successcoef) _; }

    function safeWithdrawal() afterDeadline {

    if (amountRaised < _totalSupply / successcoef) {
            uint _amount = balances[msg.sender];
            balances[msg.sender] = 0;
            if (_amount > 0) {
                if (msg.sender.send(_amount / rate)) {
                    balances[owner] += _amount;
                    amountRaised -= _amount;
                    Transfer(msg.sender, owner, _amount);
                } else {
                    balances[msg.sender] = _amount;
                }
            }
        }

    if (owner == msg.sender
    	&& amountRaised >= _totalSupply / successcoef) {
           if (owner.send(this.balance)) {
               fundingGoalReached = true;
            } 
        }
    }
}