pragma solidity ^0.4.24;

contract ERC20Basic {

	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transferFrom(address from, address to, uint value)public returns (bool);
	function allowance(address owner, address spender)public view returns (uint);
	function approve(address spender, uint value)public returns (bool ok);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint value);

}

contract BitronCoin is ERC20Basic {

	string	public name			= "Bitron Coin";
	string	public symbol		= "BTO";
	uint 	public decimals		= 9;
	uint 	public _totalSupply = 50000000 * 10 ** decimals;
	uint 	public tokens		= 0;
	uint 	public oneEth		= 10000;
	uint 	public icoEndDate	= 1535673600;
	address public owner		= msg.sender;
	bool	public stopped		= false;
	address public ethFundMain  = 0x1e6d1Fc2d934D2E4e2aE5e4882409C3fECD769dF;

	mapping (address => uint) balance;
	mapping(address => mapping(address => uint)) allowed;

	modifier onlyOwner() {
		if(msg.sender != owner){
			revert();
		}
		_;
	}

	constructor() public {

		balance[owner] = _totalSupply;
		emit Transfer(0x0, owner, _totalSupply);

	}

	function() payable public {

		if( msg.sender != owner && msg.value >= 0.02 ether && now <= icoEndDate && stopped == false ){

			tokens				 = ( msg.value / 10 ** decimals ) * oneEth;
			balance[msg.sender] += tokens;
			balance[owner]		-= tokens;

			emit Transfer(owner, msg.sender, tokens);

		} else {
			revert();
		}

	}

	function totalSupply() public view returns (uint) {
		return _totalSupply;
	}

	function balanceOf(address who) public view returns (uint) {
		return balance[who];
	}

	function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
		require( _to != 0x0);
		tokens = _amount * 10 ** decimals;
		require(balance[_from] >= tokens && allowed[_from][msg.sender] >= tokens && tokens >= 0);
		balance[_from] -= tokens;
		allowed[_from][msg.sender] -= tokens;
		balance[_to] += tokens;
		emit Transfer(_from, _to, tokens);
		return true;
	}

	function transfer(address to, uint256 value) public returns (bool) {

		require(to != owner);

		tokens			= value * 10 ** decimals;
		balance[to]		= balance[to] + tokens;
		balance[owner]	= balance[owner] - tokens;

		emit Transfer(owner, to, tokens);

	}

	function approve(address _spender, uint256 _amount)public returns (bool success) {
		require( _spender != 0x0);
		tokens = _amount * 10 ** decimals;
		allowed[msg.sender][_spender] = tokens;
		emit Approval(msg.sender, _spender, tokens);
		return true;
	}

	function allowance(address _owner, address _spender)public view returns (uint256) {
		require( _owner != 0x0 && _spender !=0x0);
		return allowed[_owner][_spender];
	}

	function drain() external onlyOwner {
		ethFundMain.transfer(address(this).balance);
	}

	function PauseICO() external onlyOwner
	{
		stopped = true;
	}

	function ResumeICO() external onlyOwner
	{
		stopped = false;
	}

}