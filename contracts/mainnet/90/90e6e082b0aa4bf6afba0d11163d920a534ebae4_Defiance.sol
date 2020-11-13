pragma solidity ^0.5.13;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
     * @dev called by the owner to pause, triggers stopped state
     **/
    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }
  
  /**
     * @dev Prevent the token from ever being paused again
     **/
    function notPausable() onlyOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }
}




interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract Defiance is Pausable {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private INITIAL_SUPPLY = 1e25; // 1B
	uint256 constant private BURN_RATE = 5; // 5% per tx
	uint256 constant private SUPPLY_FLOOR = 1; // 1% of 1B = 10M
	uint256 constant private MIN_STAKE_AMOUNT = 1e21; // 1,000

	string constant public name = "Defiance";
	string constant public symbol = "DEF";
	uint8 constant public decimals = 18;

	struct User {
		bool whitelisted;
		uint256 balance;
		uint256 staked;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Collect(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);


	constructor() public {
		info.admin = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		whitelist(msg.sender, true);
	}

	function stake(uint256 _tokens) external {
		_stake(_tokens);
	}

	function unstake(uint256 _tokens) external {
		_unstake(_tokens);
	}

	function collect() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.users[msg.sender].balance += _dividends;
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);
		return _dividends;
	}

	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;
		if (info.totalStaked > 0) {
			_burnedAmount /= 2;
			info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalStaked;
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}
		info.totalSupply -= _burnedAmount;
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}

	function distribute(uint256 _tokens) external {
		require(info.totalStaked > 0);
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		info.scaledPayoutPerToken += _tokens * FLOAT_SCALAR / info.totalStaked;
		emit Transfer(msg.sender, address(this), _tokens);
	}

	function transfer(address _to, uint256 _tokens) external whenNotPaused returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external whenNotPaused returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external whenNotPaused returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
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


	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalStaked() public view returns (uint256) {
		return info.totalStaked;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - stakedOf(_user);
	}

	function stakedOf(address _user) public view returns (uint256) {
		return info.users[_user].staked;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].staked) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensStaked, uint256 userBalance, uint256 userStaked, uint256 userDividends) {
		return (totalSupply(), totalStaked(), balanceOf(_user), stakedOf(_user), dividendsOf(_user));
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
			if (info.totalStaked > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalStaked;
				emit Transfer(_from, address(this), _burnedAmount);
			}
			info.totalSupply -= _burnedAmount;
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}
		return _transferred;
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

	function _unstake(uint256 _amount) internal {
		require(stakedOf(msg.sender) >= _amount);
		uint256 _burnedAmount = _amount * BURN_RATE / 100;
		info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalStaked;
		info.totalStaked -= _amount;
		info.users[msg.sender].balance -= _burnedAmount;
		info.users[msg.sender].staked -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
		emit Unstake(msg.sender, _amount);
	}
}