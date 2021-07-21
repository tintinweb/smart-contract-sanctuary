pragma solidity ^0.5.17;

contract YTCoin {
    // consts
    uint8 constant public decimals = 18;
    string constant public symbol = "YTCoin";
	string constant public name = "YTCoin";
	uint256 constant public FLOAT_SCALAR = 2**64;
	uint256 constant public BURN_RATE = 10;
	uint256 constant public SUPPLY_FLOOR = 1;
	uint256 constant public INITIAL_SUPPLY = 5e25;
	uint256 constant public MIN_FREEZE_AMOUNT = 1e19;
	bool public isInitializationPeriod = true;

	// events
	event Stake(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Harvest(address indexed owner, uint256 tokens);

	// structs
	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	struct User {
		bool whitelisted;
		uint256 balance;
		uint256 frozen;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	Info private info;

	constructor() public {
		info.totalSupply = INITIAL_SUPPLY;
		info.admin = msg.sender;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		whitelist(msg.sender, true);
	}

	function harvest() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.users[msg.sender].balance += _dividends;
		emit Transfer(address(this), msg.sender, _dividends);
		emit Harvest(msg.sender, _dividends);
		return _dividends;
	}

	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;
		if (info.totalFrozen > 0) {
			_burnedAmount /= 2;
			info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}
		info.totalSupply -= _burnedAmount;
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}

	function distribute(uint256 _tokens) external {
		require(info.totalFrozen > 0);
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		info.scaledPayoutPerToken += _tokens * FLOAT_SCALAR / info.totalFrozen;
		emit Transfer(msg.sender, address(this), _tokens);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - frozenOf(_user);
	}

	function frozenOf(address _user) public view returns (uint256) {
		return info.users[_user].frozen;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalFrozen() public view returns (uint256) {
		return info.totalFrozen;
	}

	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	function whitelist(address _user, bool _status) public {
		require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
		emit Whitelist(_user, _status);
	}

	function setInitializationPeriod(bool _status) public {
		require(msg.sender == info.admin);
		isInitializationPeriod = _status;
	}

	function migrateChefBreeder(address _admin) public {
		require(msg.sender == info.admin);
		info.admin = _admin;
	}

	uint public breederFactor;

	function setBreederFactor(uint256 _fac) public {
		require(msg.sender == info.admin);
		breederFactor = _fac;
	}

	uint public breederFactorCreation;

	function setBreederFactorCreation(uint256 _fac) public {
		require(msg.sender == info.admin);
		breederFactorCreation = _fac;
	}

	address public breederTipLover;

	function setBreederTipLover(address _tl) public {
		require(msg.sender == info.admin);
		breederTipLover = _tl;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * BURN_RATE / 100;
		if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * SUPPLY_FLOOR / 100 || isWhitelisted(_from)) {
			_burnedAmount = 0;
		}
		uint256 _transferred = _tokens - _burnedAmount;
		info.users[_to].balance += _transferred;
		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {
			if (info.totalFrozen > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
				emit Transfer(_from, address(this), _burnedAmount);
			}
			info.totalSupply -= _burnedAmount;
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}
		return _transferred;
	}


	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensFrozen, uint256 userBalance, uint256 userFrozen, uint256 userDividends) {
		return (totalSupply(), totalFrozen(), balanceOf(_user), frozenOf(_user), dividendsOf(_user));
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function isWhitelisted(address _user) public view returns (bool) {
		// return info.users[_user].whitelisted || isInitializationPeriod;
		return true;
	}


	function _unstake(uint256 _amount) internal {
		require(frozenOf(msg.sender) >= _amount);
		uint256 _burnedAmount = _amount * BURN_RATE / 100;
		info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
		info.totalFrozen -= _amount;
		info.users[msg.sender].balance -= _burnedAmount;
		info.users[msg.sender].frozen -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
		emit Unstake(msg.sender, _amount);
	}

	function _stake(uint256 _amount) internal {
		require(balanceOf(msg.sender) >= _amount);
		require(frozenOf(msg.sender) + _amount >= MIN_FREEZE_AMOUNT);
		info.totalFrozen += _amount;
		info.users[msg.sender].frozen += _amount;
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}


	function unstake(uint256 amount) external {
		_unstake(amount);
	}

	function stake(uint256 amount) external {
		_stake(amount);
	}

}

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}