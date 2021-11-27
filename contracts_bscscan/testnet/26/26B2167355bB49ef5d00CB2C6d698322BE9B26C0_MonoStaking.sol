// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./Utils.sol";
import "./IBEP20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract MonoStaking is ReentrancyGuard, DataStorage, Events, Ownable, Utils, Pausable {
    using SafeMath for uint256;

    /**
     * @dev Constructor function
     */
    constructor() public {
        //MONO
        pools[1] = Pool(
            1,
            1637977800,
            1637981400,
            0,
            0x44d8DF9034F35eeDC972614d489E4E2ABBE5b993
        );
        durations[1][1] = Duration(7 minutes, 40, 0, 15000 * 10**18);
        durations[1][2] = Duration(14 minutes, 45, 0, 15500 * 10**18);
        durations[1][3] = Duration(30 minutes, 45, 0, 15500 * 10**18);
        // //MONO - BUSD
        // pools[2] = Pool(
        //     2,
        //     1636560000,
        //     1636560000,
        //     0,
        //     0x8d9603447B3F1303D79D42738FA6cb0Db2bAcc42,
        //     10000 * 10**18
        // );
        // //MONO - BNB
        // pools[3] = Pool(
        //     3,
        //     1636560000,
        //     1636560000,
        //     0,
        //     0x2a5Bc58E8A4F73960FD3CE329B71376A174832fc,
        //     4000 * 10**18
        // );
    }

    function invest(uint8 poolId, uint256 _amount, uint256 _duration) external nonReentrant whenNotPaused {
        require(_amount > 0, "Invest amount isn't enough");
        require(poolId != 0, "Invalid plan");
        Pool memory pool = pools[poolId];
        Duration memory duration = durations[poolId][_duration];
        require(duration.maxCap > 0, "not valid duration");
        require(pool.fromTime <= block.timestamp, "Pool not start");
        require(block.timestamp <= pool.toTime, "Pool stopped");
        require(duration.totalAmount.add(_amount) <= duration.maxCap, "Pool cap full fill");
        require(
            IBEP20(pool.tokenAddress).allowance(_msgSender(), address(this)) >=
                _amount,
            "Token allowance too low"
        );
        uint256 currentTime = block.timestamp;
        uint256 period = pool.toTime.sub(currentTime);
        require(period >= duration.duration, "not valid duration");
        _invest(poolId, _amount, _duration);
    }

    function _invest(uint256 _poolId, uint256 _amount, uint256 _duration) internal {
        UserInfo storage user = userInfos[_poolId][_msgSender()];
        Pool storage pool = pools[_poolId];
        Duration storage duration = durations[_poolId][_duration];
        _safeTransferFrom(
            _msgSender(),
            address(this),
            _amount,
            pool.tokenAddress
        );
        if(user.registerTime == 0) {
            user.registerTime = block.timestamp;
            emit Newbie(_msgSender(), block.timestamp);
        }
        user.lastStake = block.timestamp;
        user.totalAmount = user.totalAmount.add(_amount);
        duration.totalAmount = duration.totalAmount.add(_amount);
        pool.totalAmount = pool.totalAmount.add(_amount);
        user.deposits.push(Deposit(_poolId, _duration, block.timestamp, block.timestamp.add(duration.duration), _amount, false));
        if(user.registerTime == 0) {
            user.registerTime = block.timestamp;
            totalUser.push(user);
            emit Newbie(_msgSender(), block.timestamp);
        }
        emit NewDeposit(_msgSender(), _poolId, _amount, _duration);
    }

    function unStake(uint256 start, uint256 _poolId) external nonReentrant whenNotPaused {
        UserInfo storage user = userInfos[_poolId][_msgSender()];
        Pool memory pool = pools[_poolId];
        for (uint256 index = 0; index < user.deposits.length; index++) {
            if(user.deposits[index].start == start && !user.deposits[index].isUnstake) {
                require(block.timestamp >= user.deposits[index].finish, "not valid unstake");
                uint256 currentDividend = getUserDividends(_msgSender(), _poolId, start);
                user.deposits[index].isUnstake = true;
                user.totalPayout = currentDividend;
                IBEP20(pool.tokenAddress).transfer(_msgSender(), currentDividend.add(user.deposits[index].start));
                emit UnStake(_msgSender(), _poolId, currentDividend, start);
            }
        }
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount,
        address _token
    ) private {
        bool sent = IBEP20(_token).transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }

    function setTimeStep(uint256 _time) external onlyOwner {
        TIME_STEP = _time;
    }

    function updatePoolInfo(Pool memory pool) external onlyOwner {
        pools[pool.poolId] = pool;
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./DataStorage.sol";
import "./SafeMath.sol";

contract Utils is DataStorage {
    using SafeMath for uint256;

    function getUserDividends(address userAddress, uint256 poolId, uint256 start)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfos[poolId][userAddress];
        uint256 currentDividend;
        for (uint256 index = 0; index < user.deposits.length; index++) {
            if(user.deposits[index].start == start && !user.deposits[index].isUnstake) {
                uint256 fromTime = user.deposits[index].start;
                uint256 toTime = user.deposits[index].finish > block.timestamp ? block.timestamp : user.deposits[index].finish;
                uint256 totalTime = toTime.sub(fromTime);
                Duration memory duration = durations[poolId][user.deposits[index].duration];
                currentDividend = user.deposits[index].amount.mul(totalTime).mul(duration.rate.div(100).div(duration.duration));
            }
        }
        return currentDividend;          
    }

    function getUserInfo(address userAddress, uint256 poolId)
        public
        view
        returns (UserInfo memory userInfo)
    {
        userInfo = userInfos[poolId][userAddress];
    }

    function getAllUser(uint256 fromRegisterTime, uint256 toRegisterTime)
        public
        view
        returns (UserInfo[] memory)
    {
        UserInfo[] memory allUser = new UserInfo[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (
                totalUser[index].registerTime >= fromRegisterTime &&
                totalUser[index].registerTime <= toRegisterTime
            ) {
                allUser[count] = totalUser[index];
                ++count;
            }
        }
        return allUser;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

pragma solidity 0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Events {
  event Newbie(address indexed user, uint256 registerTime);
  event NewDeposit(address indexed user, uint256 poolId, uint256 amount, uint256 duration);
  event UnStake(address indexed user, uint256 poolId, uint256 amount, uint256 start);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract DataStorage {

	uint256 public TIME_STEP = 1 days;

    struct Pool {
		uint256 poolId;
        uint256 fromTime;
        uint256 toTime;
		uint256 totalAmount;
		address tokenAddress;
    }

	struct UserInfo {
		uint256 totalPayout;
		uint256 registerTime;
		uint256 lastStake;
		uint256 poolId;
		uint256 totalAmount;
		Deposit[] deposits;
	}

	struct Deposit {
		uint256 poolId;
		uint256 duration;
		uint256 start;
		uint256 finish;
		uint256 amount;
		bool isUnstake;
	}

	struct Duration {
		uint256 rate;
		uint256 duration;
		uint256 totalAmount;
		uint256 maxCap;
	}

	mapping (uint256 => Pool) public pools;
	mapping (uint256 => mapping(address => UserInfo)) userInfos;
	mapping (uint256 => mapping(uint256 => Duration)) public durations;

	UserInfo[] internal totalUser;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}