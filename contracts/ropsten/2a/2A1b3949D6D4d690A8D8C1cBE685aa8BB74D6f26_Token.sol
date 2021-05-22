/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

contract Token{
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
	mapping (address => mapping(address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	//event Transfer(address sender, address reciever, uint256 val);
	//event Approval(address sender, address spender, uint256 val);
	
	// SafeMath functions //
	function safeAdd(uint a, uint b) public pure returns (uint c) 
	{
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) 
	{
		require(b <= a); c = a - b;
	} 
	function safeMul(uint a, uint b) public pure returns (uint c) 
	{ 
		c = a * b; 
		require(a == 0 || c / a == b); 
	} 
	function safeDiv(uint a, uint b) public pure returns (uint c) 
	{ 
		require(b > 0);
        c = a / b;
    }
	////////////////////////
	
    constructor() {
        name = "205208664";
        symbol = "GIL";
        decimals = 18;
        totalSupply = 100000;
        balances[msg.sender] = 100000;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
	{
		// requires that the balance of the _from address is greater than value...
		require(balances[_from] >= _value);
		
		// ... and that the msg.sender is allowed to spend this much  
		// of the _from address's money
        require(allowed[_from][msg.sender] >= _value);
        
		balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success)
	{
		// the msg.sender tells the mapping that _spender can spend _value of 
		// the msg.sender's coins.
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	function allowance(address _owner, address _spender) public view returns (uint256 remaining)
	{
		return allowed[_owner][_spender];
	}

	
}