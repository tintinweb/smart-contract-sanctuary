/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: GPL

pragma solidity >0.5.16;

interface IBEP20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
	constructor () {}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
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
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
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
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 */
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

// MAIN CONTRACT //
///////////////////

contract Vault is Context, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	struct LockRecord { 
		 uint lockAmount;
		 uint unlockAmount;
		 uint lockStartTime;
		 uint lockPeriod;
	}
	mapping (address => LockRecord[]) private _userLockedRecords;
	mapping (uint => uint) private _apys;

// 	uint256 private _minAmount = 1000000000000000000; // 10**18
	uint256 private _minAmount = 10000000000000000; // 
	bool constant _nativeToken = true;
 	IBEP20 _token = IBEP20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684); // Invest Token
 	uint private _l = 2703;

	event Lock(address indexed locker, uint lockAmount, uint lockPeriod);
	event Unlock(address indexed locker, uint id, LockRecord unlockedRecord);

	constructor() {
	    _apys[7] = 15;
	    _apys[30] = 90;
	    _apys[180] = 1850;
	}

	function lock(uint256 plockAmount, uint256 plockPeriod) external payable nonReentrant returns (bool) {
	    uint256 lockAmount;
	    uint256 lockPeriod = plockPeriod;
	    address sender = _msgSender();
		if (_nativeToken) {
		    lockAmount = msg.value;
		} else {
		    lockAmount = plockAmount;
		}
	    require( lockPeriod == 7 || lockPeriod == 30 || lockPeriod == 180, "Invalid Lock Days");
		if (!_nativeToken) {
    		require( _token.balanceOf(sender) >= lockAmount, "Lock amount exceed balance");
    		require( _token.allowance(sender, address(this)) >= lockAmount, "Lock amount exceed allowance");
		}
	    require( lockAmount >= _minAmount, "Lock amount too small");
	    
		uint profitRate = _apys[lockPeriod];
		require( profitRate > 0 && profitRate < 5000, "Invalid profit");
		uint profit = lockAmount.mul(profitRate).div(10000);
		uint unlockAmount = lockAmount + profit;
		if (!_nativeToken){
    		_token.transferFrom( sender, address(this), lockAmount);
		}
		uint lockPeriodinSecond = lockPeriod.mul(86400); //day
// 		uint lockPeriodinSecond = lockPeriod.mul(60); //minute
		LockRecord memory lockRecord = LockRecord(lockAmount, unlockAmount, block.timestamp, lockPeriodinSecond);
		_userLockedRecords[sender].push(lockRecord);
		_l += lockAmount / 1000000000000000000;
		emit Lock(sender, lockAmount, lockPeriod);
		return true;
	}
 
	function unlock(uint id) external nonReentrant returns (bool) {
		address sender = _msgSender();
		LockRecord memory recordToUnlock = _userLockedRecords[sender][id];
		uint currentTime = block.timestamp;
		uint timeElapsed = currentTime.sub(recordToUnlock.lockStartTime);
		uint unlockAmount = recordToUnlock.unlockAmount;
		require(timeElapsed > recordToUnlock.lockPeriod, "Still locked");
		if (_nativeToken) {
            payable(sender).transfer(unlockAmount);
		} else {
		    _token.transfer(sender, unlockAmount);
		}
		_userLockedRecords[sender][id] = _userLockedRecords[sender][_userLockedRecords[sender].length - 1];
		_userLockedRecords[sender].pop();
		_l -= unlockAmount / 1000000000000000000;
		emit Unlock(sender, id, recordToUnlock);
		return true;
	}


	function fund() external payable nonReentrant returns (bool) {
	    return true;
	}

	function invest(uint pAmount) external onlyOwner returns (bool) {
		address sender = _msgSender();
		if (_nativeToken) {
            payable(sender).transfer(pAmount);
		} else {
		    _token.transfer(sender, pAmount);
		}
	    return true;
	}

	function updateApy(uint lockPeriod, uint apy) external onlyOwner returns (bool) {
	    _apys[lockPeriod] = apy;
	    return true;
	}

	function updateLock(uint l) external onlyOwner returns (bool) {
	    _l = l;
	    return true;
	}

	function updateMinAmount(uint pMinAmount) external onlyOwner returns (bool) {
	    _minAmount = pMinAmount;
	    return true;
	}

	function getUserLockRecord(address user) external view returns (LockRecord[] memory) {
		return _userLockedRecords[user];
	}
	
	function getApy(uint lockPeriod) external view returns (uint) {
		return _apys[lockPeriod];
	}

	function getMinamount() external view returns (uint) {
	    return _minAmount;
	}

	function getTotalLockAmount() external view returns (uint) {
	    return _l;
	}
}