pragma solidity 0.5.13;

contract TimeFarmer {

	uint256 constant public TOKEN_PRECISION = 1e6;
	
	uint256 constant private initial_supply = 24 * 10 * 365 * TOKEN_PRECISION;
	
	string constant public name = "TimeFarmer";
	string constant public symbol = "FARM";
	uint8 constant public decimals = 6;

	struct User {
	    bool whitelisted;
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		address admin;
	}
	
	Info private info;
	
	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	
	constructor() public {
		info.admin = msg.sender;
		info.totalSupply = initial_supply;
		
		info.users[msg.sender].balance = initial_supply;
		info.users[msg.sender].whitelisted = true;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 userBalance) {
		return (totalSupply(), balanceOf(_user));
	}
	
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	
	function whitelist(address _user, bool _status) public {
		require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
		emit Whitelist(_user, _status);
	}
	
	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {

	 	require(balanceOf(_from) >= _tokens);
	 	
	 	uint256 _transferred = 0;
	 	
        info.users[_from].balance -= _tokens;
		_transferred = _tokens;
		info.users[_to].balance += _transferred;
	
		emit Transfer(_from, _to, _transferred);
	
		return _transferred;
	}
	
}