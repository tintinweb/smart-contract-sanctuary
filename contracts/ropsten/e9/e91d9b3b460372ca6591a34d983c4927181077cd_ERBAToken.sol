pragma solidity 0.4.24;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

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

contract ERC20 is ERC20Interface, Owned {
    
    using SafeMath for uint;

    string  public symbol;
    string  public name;
    uint8   public decimals;
    uint    public totalSupply;
    
    constructor() public {
        symbol = &quot;ERBA&quot;;
        name = &quot;ERBA Token&quot;;
        decimals = 18;
        totalSupply = 200000000 * 10 ** uint(decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

	function transfer(address to, uint tokens) public returns (bool success) {
		require((tokens <= balances[msg.sender]));
        require((tokens > 0));
        require(to != address(0));
		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}

	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
	    require((tokens <= allowed[from][msg.sender] ));
        require((tokens > 0));
        require(to != address(0));
		require(balances[from] >= tokens);
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns (bool success) {
	    require(spender != address(0));
	    require(tokens <= balances[msg.sender]);
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
}


contract ERBAToken is ERC20
{
    
	address public wallet;
	uint constant TOKEN_DECIMALS = 10 ** 18;
	uint constant ETH_DECIMALS = 10 ** 18;
	uint public  EtherUSDPriceFactor;
	uint public oneEth;

	bool private paused = false;
	
	struct Stage {
	    uint start_date;
	    uint end_date;
	    uint stage_no;
	    uint tokens;
	    uint bonus;
	    uint contribution;
	}
	
	constructor(uint _oneEth, address _wallet) public {
	    oneEth = _oneEth;
	    wallet = _wallet;
	}
	
	Stage stage;
	
	modifier onlyWhenPause(){
	    require( paused == true );
	    _;
	}
	
	modifier onlyWhenResume(){
	    require( paused == false );
	    _;
	}

	function() public payable
	{
		require(!paused && msg.sender != owner);
		require(now >= stage.start_date && now <= stage.end_date);
		require(stage.stage_no > 0);
		uint tokens = (msg.value).mul(oneEth);
		uint bonus = ((tokens).mul(stage.bonus)).div(100);
		uint total = tokens + bonus;
		require(stage.contribution + total <= stage.tokens );
		stage.contribution = stage.contribution + total;
		transferTokens(msg.sender, total);
	}
	
	function transferTokens(address to_address, uint256 tokens) private returns(bool success)
	{
		require(to_address != 0x0);
		require(balances[address(this)] >= tokens);
		balances[address(this)] = (balances[address(this)]).sub(tokens);
		balances[to_address] = (balances[to_address]).add(tokens);
		emit Transfer(address(this), to_address, tokens);
		return true;
	}

	function setStage( uint _stage, uint _tokens, uint _startDate, uint _endDate, uint _bonus ) public onlyOwner
	{
	    require( _tokens > 0 );
	    require( now < _startDate );
	    require( _startDate < _endDate );
	    require( stage.end_date < _startDate );
	    require( stage.stage_no < _stage && _stage > 0 );
	    uint tokens = _tokens *  TOKEN_DECIMALS;
	    stage.start_date = _startDate;
	    stage.end_date = _endDate;
	    stage.tokens = tokens;
	    stage.stage_no = _stage;
	    stage.contribution = 0;
	    stage.bonus = _bonus;
	    transfer(address(this), tokens);
	}
	
	function pauseICO() external onlyOwner onlyWhenResume
	{
		paused = true;
	}
	
	function resumeICO() external onlyOwner onlyWhenPause
	{
		paused = false;
	}
	
	function getStage() public view returns (uint) {
	    return stage.stage_no;
	}
	
	function getStageStartDate() public view returns (uint) {
	    return stage.start_date;
	}
	
	function getStageEndDate() public view returns (uint) {
	    return stage.end_date;
	}

	function forwardFunds() external onlyOwner
	{
		wallet.transfer(address(this).balance);
	}

}