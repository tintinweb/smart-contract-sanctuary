/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity ^0.5.17;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

//OFFICIAL LIVIA SMART CONTRACT

contract Livia {

	uint256 constant private BURNING_RATE = 5;
	uint256 constant private INITIAL_SUPPLY = 480000000;
	uint256 constant private MINIMUM_SUPPLY_PBEPENTAGE = 5;
	uint256 constant private MIN_STAKE_AMOUNT = 100;
	string constant public name = "Livia";
	uint8 constant public decimals = 18;
	string constant public symbol = "LVA";
	uint256 constant private DEFAULT_SCALAR_VALUE = 2**64;

	struct User {
		uint256 balance;
		uint256 staked;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
		bool burningDisabled;
	}


	struct Info {
		address adminAddress;
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
	}

	Info private info;

	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event DisableBurning(address indexed user, bool status);
	event Collect(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);
	event Transfer(address indexed from, address indexed to, uint256 tokens);

	constructor() public {
		info.adminAddress = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		disableBurning(msg.sender, true);
	}

	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;
		if (info.totalStaked > 0) {
			_burnedAmount /= 2;
			info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}

		info.totalSupply -= _burnedAmount;
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}

	function stake(uint256 _tokens) external {
		_stake(_tokens);
	}

	function unstake(uint256 _tokens) external {
		_unstake(_tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		uint256 _transferred = _transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _transferred, _data));
		}
		return true;
	}

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * BURNING_RATE / 100;

		if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * MINIMUM_SUPPLY_PBEPENTAGE / 100 || isBurningDisabled(_from)) {
			_burnedAmount = 0;
		}

		uint256 _transferred = _tokens - _burnedAmount;
		info.users[_to].balance += _transferred;

		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {
			if (info.totalStaked > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;
				emit Transfer(_from, address(this), _burnedAmount);
			}

			info.totalSupply -= _burnedAmount;
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}

		return _transferred;
	}

	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function distribute(uint256 _tokens) external {
		require(info.totalStaked > 0);
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		info.scaledPayoutPerToken += _tokens * DEFAULT_SCALAR_VALUE / info.totalStaked;
		emit Transfer(msg.sender, address(this), _tokens);
	}

	function disableBurning(address _user, bool _status) public {
		require(msg.sender == info.adminAddress);
		info.users[_user].burningDisabled = _status;
		emit DisableBurning(_user, _status);
	}

	function totalStaked() public view returns (uint256) {
		return info.totalStaked;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].staked) - info.users[_user].scaledPayout) / DEFAULT_SCALAR_VALUE;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - stakedOf(_user);
	}

	function stakedOf(address _user) public view returns (uint256) {
		return info.users[_user].staked;
	}

	function isBurningDisabled(address _user) public view returns (bool) {
		return info.users[_user].burningDisabled;
	}

	function infoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensStaked, uint256 userBalance, uint256 userStaked, uint256 userDividends) {
		return (totalSupply(), totalStaked(), balanceOf(_user), stakedOf(_user), dividendsOf(_user));
	}

	function _stake(uint256 _amount) internal {
		require(balanceOf(msg.sender) >= _amount);
		require(stakedOf(msg.sender) + _amount >= MIN_STAKE_AMOUNT);
		info.totalStaked += _amount;
		info.users[msg.sender].staked += _amount;
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}

	function collect() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * DEFAULT_SCALAR_VALUE);
		info.users[msg.sender].balance += _dividends;
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);
		return _dividends;
	}

	function _unstake(uint256 _amount) internal {
		require(stakedOf(msg.sender) >= _amount);
		uint256 _burnedAmount = _amount * BURNING_RATE / 100;
		info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;
		info.totalStaked -= _amount;
		info.users[msg.sender].balance -= _burnedAmount;
		info.users[msg.sender].staked -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
		emit Unstake(msg.sender, _amount);
	}

}