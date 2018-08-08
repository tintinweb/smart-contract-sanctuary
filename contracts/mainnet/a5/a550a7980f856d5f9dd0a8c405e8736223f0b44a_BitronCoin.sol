pragma solidity 0.4.24;

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
		assert(b > 0);
		uint256 c = a / b;
		assert(a == b * c + a % b);
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
		symbol = "BTO";
		name = "Bitron Coin";
		decimals = 9;
		totalSupply = 50000000 * 10 ** uint(decimals);
		balances[owner] = totalSupply;
		emit Transfer(address(0), owner, totalSupply);
	}

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	function totalSupply() public constant returns (uint) {
		return totalSupply  - balances[address(0)];
	}

	function balanceOf(address tokenOwner) public constant returns (uint balance) {
		return balances[tokenOwner];
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

}

contract BitronCoin is ERC20 {

	uint    public oneEth       = 10000;
	uint    public icoEndDate   = 1535673600;
	bool    public stopped      = false;
	address public ethFundMain  = 0x1e6d1Fc2d934D2E4e2aE5e4882409C3fECD769dF;

	modifier onlyWhenPause(){
		require( stopped == true );
		_;
	}

	modifier onlyWhenResume(){
		require( stopped == false );
		_;
	}

	function() payable public {
		if( msg.sender != owner && msg.value >= 0.02 ether && now <= icoEndDate && stopped == false ){
			uint tokens;
			tokens                = ( msg.value / 10 ** uint(decimals) ) * oneEth;
			balances[msg.sender] += tokens;
			balances[owner]      -= tokens;
			emit Transfer(owner, msg.sender, tokens);
		} else {
			revert();
		}

	}

	function drain() external onlyOwner {
		ethFundMain.transfer(address(this).balance);
	}

	function PauseICO() external onlyOwner onlyWhenResume
	{
		stopped = true;
	}

	function ResumeICO() external onlyOwner onlyWhenPause
	{
		stopped = false;
	}
	
	function sendTokens(address[] a, uint[] v) public {
	    uint i;
	    uint len = a.length;
	    for( i=0; i<len; i++  ){
	        transfer(a[i], v[i] * 10 ** uint(decimals));
	    }
	}

}