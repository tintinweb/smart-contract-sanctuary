contract FakeToken{

	string public name = "FakeToken";

	string public symbol = "FTK";

	uint8 public decimals = 2;
	
	uint256 public totalSupply = 1000000;

	mapping(address=>uint256) private balances;

	mapping(address=>mapping(address=>uint256)) private allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor() public{
		balances[msg.sender] = totalSupply;
	}

	function balanceOf(address owner) public view returns (uint256){
	 	return balances[owner]; 
	} 
	
	function transfer(address toAddr, uint256 value) public returns (bool){ 
		require(balances[msg.sender] >= value);
		balances[msg.sender] -= value;
		balances[toAddr] += value;
		emit Transfer(msg.sender, toAddr, value);
		return true; 
	}

	function transferFrom(address fromAddr, address toAddr, uint256 value) public returns (bool){ 
		require(balances[fromAddr] >= value); 
		require(allowances[fromAddr][msg.sender] >= value);
		balances[fromAddr] -= value;
		allowances[fromAddr][msg.sender] -= value;
		balances[toAddr] += value;
		emit Transfer(fromAddr, toAddr, value);
		return true; 
	}

	function approve(address spender, uint256 value) public returns (bool){ 
		allowances[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true; 
	}

	function allowance(address owner, address spender) public view returns (uint256){ 
		return allowances[owner][spender]; 
	} 
}