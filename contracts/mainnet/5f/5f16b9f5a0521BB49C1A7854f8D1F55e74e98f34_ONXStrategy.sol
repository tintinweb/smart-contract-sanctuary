// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./modules/BaseShareField.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IONXStrategy {
    function invest(address user, uint256 amount) external; 
    function withdraw(address user, uint256 amount) external;
    function liquidation(address user) external;
    function claim(address user, uint256 amount, uint256 total) external;
    function query() external view returns (uint256);
    function mint() external;
    function interestToken() external view returns (address);
    function farmToken() external view returns (address);
}

interface IONXFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingOnX(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo(uint _index) external view returns(address, uint256, uint256, uint256);
}

contract ONXStrategy is IONXStrategy, BaseShareField, Initializable {
	event Mint(address indexed user, uint256 amount);
	using SafeMath for uint256;
	address public override interestToken;
	address public override farmToken;
	address public poolAddress;
	address public onxFarm;
	uint256 public lpPoolpid;
	address public owner;

	function initialize(
		address _interestToken,
		address _farmToken,
		address _poolAddress,
		address _onxFarm,
		uint256 _lpPoolpid
	) public initializer {
		owner = msg.sender;
		interestToken = _interestToken;
		farmToken = _farmToken;
		poolAddress = _poolAddress;
		onxFarm = _onxFarm;
		lpPoolpid = _lpPoolpid;
		_setShareToken(_interestToken);
	}

	function invest(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		TransferHelper.safeTransferFrom(farmToken, msg.sender, address(this), amount);
		IERC20(farmToken).approve(onxFarm, amount);
		IONXFarm(onxFarm).deposit(lpPoolpid, amount);
		_increaseProductivity(user, amount);
	}

	function withdraw(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IONXFarm(onxFarm).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(farmToken, msg.sender, amount);
		_decreaseProductivity(user, amount);
	}

	function liquidation(address user) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		uint256 amount = users[user].amount;
		_decreaseProductivity(user, amount);
		uint256 reward = users[user].rewardEarn;
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.add(reward);
		users[user].rewardEarn = 0;
		_increaseProductivity(msg.sender, amount);
	}

	function claim(
		address user,
		uint256 amount,
		uint256 total
	) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IONXFarm(onxFarm).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(farmToken, msg.sender, amount);
		_decreaseProductivity(msg.sender, amount);
		uint256 claimAmount = users[msg.sender].rewardEarn.mul(amount).div(total);
		users[user].rewardEarn = users[user].rewardEarn.add(claimAmount);
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.sub(claimAmount);
	}

	function _currentReward() internal view override returns (uint256) {
		return
			mintedShare
				.add(IERC20(shareToken).balanceOf(address(this)))
				.add(IONXFarm(onxFarm).pendingOnX(lpPoolpid, address(this)))
				.sub(totalShare);
	}

	function query() external view override returns (uint256) {
		return _takeWithAddress(msg.sender);
	}

	function mint() external override {
		IONXFarm(onxFarm).deposit(lpPoolpid, 0);
		uint256 amount = _mint(msg.sender);
		emit Mint(msg.sender, amount);
	}
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library TransferHelper {
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
	}

	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
	}

	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
	}

	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "TransferHelper: ETH_TRANSFER_FAILED");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import "../libraries/SafeMath.sol";
import "../libraries/TransferHelper.sol";

interface IERC20 {
	function approve(address spender, uint256 value) external returns (bool);

	function balanceOf(address owner) external view returns (uint256);
}

contract BaseShareField {
	using SafeMath for uint256;

	uint256 public totalProductivity;
	uint256 public accAmountPerShare;

	uint256 public totalShare;
	uint256 public mintedShare;
	uint256 public mintCumulation;

	uint256 private unlocked = 1;
	address public shareToken;

	modifier lock() {
		require(unlocked == 1, "Locked");
		unlocked = 0;
		_;
		unlocked = 1;
	}

	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 rewardDebt; // Reward debt.
		uint256 rewardEarn; // Reward earn and not minted
		bool initialize; // already setup.
	}

	mapping(address => UserInfo) public users;

	function _setShareToken(address _shareToken) internal {
		shareToken = _shareToken;
	}

	// Update reward variables of the given pool to be up-to-date.
	function _update() internal virtual {
		if (totalProductivity == 0) {
			totalShare = totalShare.add(_currentReward());
			return;
		}

		uint256 reward = _currentReward();
		accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
		totalShare += reward;
	}

	function _currentReward() internal view virtual returns (uint256) {
		return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
	}

	// Audit user's reward to be up-to-date
	function _audit(address user) internal virtual {
		UserInfo storage userInfo = users[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		}
	}

	// External function call
	// This function increase user's productivity and updates the global productivity.
	// the users' actual share percentage will calculated by:
	// Formula:     user_productivity / global_productivity
	function _increaseProductivity(address user, uint256 value) internal virtual returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = users[user];
		_update();
		_audit(user);
		totalProductivity = totalProductivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		return true;
	}

	// External function call
	// This function will decreases user's productivity by value, and updates the global productivity
	// it will record which block this is happenning and accumulates the area of (productivity * time)
	function _decreaseProductivity(address user, uint256 value) internal virtual returns (bool) {
		UserInfo storage userInfo = users[user];
		require(value > 0 && userInfo.amount >= value, "INSUFFICIENT_PRODUCTIVITY");

		_update();
		_audit(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		totalProductivity = totalProductivity.sub(value);

		return true;
	}

	function _transferTo(
		address user,
		address to,
		uint256 value
	) internal virtual returns (bool) {
		UserInfo storage userInfo = users[user];
		require(value > 0 && userInfo.amount >= value, "INSUFFICIENT_PRODUCTIVITY");

		_update();
		_audit(user);
		uint256 transferAmount = value.mul(userInfo.rewardEarn).div(userInfo.amount);
		userInfo.rewardEarn = userInfo.rewardEarn.sub(transferAmount);
		users[to].rewardEarn = users[to].rewardEarn.add(transferAmount);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		totalProductivity = totalProductivity.sub(value);

		return true;
	}

	function _takeWithAddress(address user) internal view returns (uint256) {
		UserInfo storage userInfo = users[user];
		uint256 _accAmountPerShare = accAmountPerShare;
		if (totalProductivity != 0) {
			uint256 reward = _currentReward();
			_accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
		}
		return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
	}

	// External function call
	// When user calls this function, it will calculate how many token will mint to user from his productivity * time
	// Also it calculates global token supply from last time the user mint to this time.
	function _mint(address user) internal virtual lock returns (uint256) {
		_update();
		_audit(user);
		require(users[user].rewardEarn > 0, "NOTHING TO MINT SHARE");
		uint256 amount = users[user].rewardEarn;
		TransferHelper.safeTransfer(shareToken, user, amount);
		users[user].rewardEarn = 0;
		mintedShare += amount;
		return amount;
	}

	function _mintTo(address user, address to) internal virtual lock returns (uint256) {
		_update();
		_audit(user);
		uint256 amount = users[user].rewardEarn;
		if (amount > 0) {
			TransferHelper.safeTransfer(shareToken, to, amount);
		}

		users[user].rewardEarn = 0;
		mintedShare += amount;
		return amount;
	}

	// Returns how many productivity a user has and global has.
	function getProductivity(address user) public view virtual returns (uint256, uint256) {
		return (users[user].amount, totalProductivity);
	}

	// Returns the current gorss product rate.
	function interestsPerBlock() public view virtual returns (uint256) {
		return accAmountPerShare;
	}
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}