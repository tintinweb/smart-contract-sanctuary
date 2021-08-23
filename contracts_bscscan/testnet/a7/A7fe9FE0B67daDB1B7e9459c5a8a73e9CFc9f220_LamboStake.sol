/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
	bool private _useMultipleCallers;
	address private _owner;
	mapping(address => bool) private _authorizedCallers;
	uint256 private _countAuthorizedCallers;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AuthorizedCaller(address account,bool value);

	constructor () internal {
		_owner = _msgSender();
		_useMultipleCallers = true;
		_setAuthorizedCallers(_owner,true);
		emit OwnershipTransferred(address(0), _owner);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function isAuthorizedCaller(address account) public view returns (bool) {
		return (_owner ==  account) || (_useMultipleCallers && _authorizedCallers[account]);
	}

	modifier onlyOwner() {
		require(_owner == _msgSender() || (_useMultipleCallers && _authorizedCallers[_msgSender()] == true), "Ownable: caller is not authorized");
		_;
	}

	function _setAuthorizedCallers(address account,bool value) private {
		if (account == address(0)) return;
		if (value && !_useMultipleCallers) return;
		if (value && _authorizedCallers[account]) return;
		if (!value && !_authorizedCallers[account]) return;
		if (value) _countAuthorizedCallers++; else _countAuthorizedCallers--;
		_authorizedCallers[account] = value;
		emit AuthorizedCaller(account,value);
	}

	function setAuthorizedCallers(address account,bool value) public onlyOwner {
	    _setAuthorizedCallers(account,value);
	}
	
	function countAuthorizedCallers() public view returns (uint256) {
	    return _countAuthorizedCallers;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_countAuthorizedCallers = 0;
		_useMultipleCallers = false;
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_setAuthorizedCallers(_owner,false);
		_setAuthorizedCallers(newOwner,true);
		_owner = newOwner;
	}
}

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

    constructor () public {
        _status = _NOT_ENTERED;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

contract LamboStake is Context, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	// Pool
	mapping(uint256 => address) private _rewardTokenAddress;
	mapping(uint256 => address) private _stakedTokenAddress;

	// Tax handling
	mapping(uint256 => uint256) private _stakeTaxpoolIndex;
	mapping(uint256 => uint256) private _unstakeRewardTax;
	mapping(uint256 => uint256) private _stakeTokenTax;
	mapping(uint256 => uint256) private _unstakeTokenTax;

	// Total reward for pool
	mapping(uint256 => uint256) private _rewardPools;
	// last time the reward pool was switched
	mapping(uint256 => uint256) private _lastSwitchPools;
	mapping(uint256 => uint256) private _stakePeriod;
	mapping(uint256 => uint256) private _rewardTokensByPeriod;

	mapping(uint256 => uint256) private _unclaimRewardPools;
	mapping(uint256 => uint256) private _unclaimTotalRewardPools;
	mapping(uint256 => uint256) private _currentRewardPools;
	mapping(uint256 => uint256) private _currentTotalRewardPools;
	mapping(uint256 => uint256) private _previousRewardPools;
	mapping(uint256 => uint256) private _previousTotalRewardPools;

	mapping(uint256 => uint256) private _totalStaked;
	mapping(uint256 => uint256) private _totalRewards;
	mapping(uint256 => uint256) private _countStakers;
	mapping(uint256 => uint256) private _accumulatedTokensByPeriod;
	mapping(uint256 => uint256) private _minUserStakesForReward;
	mapping(uint256 => uint256) private _minTotalStakedForFullReward;
	mapping(uint256 => uint256) private _minStakersForFullReward;
	mapping(uint256 => mapping(address => uint256)) private _userStakes;
	mapping(uint256 => mapping(address => uint256)) private _userRewards;
	mapping(uint256 => mapping(address => uint256)) private _nextClaimDate;

	struct Pool {
		string poolName;
		uint256 poolIndex;
		address stakedToken;
		address rewardToken;
		uint256 unstakeRewardTax;
		uint256 stakePeriod;
		uint256 rewardTokensByPeriod;
	}

    Pool[] private availablePools;

	address private retrieveFundWallet;

	event PoolAddedSuccessfully(
		string poolName,
		uint256 poolIndex,
		address stakedToken,
		address rewardToken,
		uint256 unstakeRewardTax,
		uint256 stakePeriod,
		uint256 rewardTokensByPeriod
	);

	event RewardAddedSuccessfully (
		uint256 poolIndex,
		address rewardToken,
		uint256 amount
	);

	event PoolSwitchedSuccessfully (
		uint256 poolIndex,
		uint256 amount,
		uint256 switchDate
	);

	event StakeTokenSuccessfully(
		uint256 poolIndex,
		address from,
		uint256 totalAmount,
		uint256 tax,
		uint256 amount,
		uint256 nextClaimDate
	);

	event ClaimRewardSuccessfully(
		uint256 poolIndex,
		address from,
		uint256 amount,
		uint256 nextClaimDate
	);

	event RetrieveRewardSuccessfully(
		uint256 poolIndex,
		address to,
		uint256 rewardBalance
	);

	event UnstakeTokenSuccessfully(
		uint256 poolIndex,
		address to,
		uint256 amount
	);

	constructor () public {
		retrieveFundWallet = owner();
	}

	function mulScale(uint x, uint y, uint128 scale) internal pure returns (uint) {
		uint256 a = x.div(scale);
		uint256 b = x.mod(scale);
		uint256 c = y.div(scale);
		uint256 d = y.mod(scale);
		return (a.mul(c).mul(scale)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(scale));
	}
	
	function getRewardTokenAddress(uint256 poolIndex) external view returns (address) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardTokenAddress[poolIndex];
	}

	function getStakeTokenAddress(uint256 poolIndex) external view returns (address) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _stakedTokenAddress[poolIndex];
	}
	
	function getMinStakersForFullReward(uint256 poolIndex) public view returns (uint256) {
		uint256 ret = _minStakersForFullReward[poolIndex];
		if (ret == 0) {
			return 100;
		}
		return _minStakersForFullReward[poolIndex];
	}

	function getMinTotalStakedForFullReward(uint256 poolIndex) external view returns (uint256) {
		return _minTotalStakedForFullReward[poolIndex];
	}

	function getMinUserStakesForReward(uint256 poolIndex) external view returns (uint256) {
		return _minUserStakesForReward[poolIndex];
	}

	function getUserStakes(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _userStakes[poolIndex][account];
	}

	function getUserRewards(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _userRewards[poolIndex][account];
	}

	function getNextClaimDate(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _nextClaimDate[poolIndex][account];
	}

	function getUnstakeRewardTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _unstakeRewardTax[poolIndex];
	}

	function getStakeTokenTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
		return _stakeTokenTax[stakeTaxpoolIndex];
	}

	function getUnstakeTokenTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
		return _unstakeTokenTax[stakeTaxpoolIndex];
	}

	function getRewardPool(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardPools[poolIndex];
	}

	function getLastSwitchDate(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _lastSwitchPools[poolIndex];
	}

	function getStakePeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _stakePeriod[poolIndex];
	}

	function getRewardTokensByPeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardTokensByPeriod[poolIndex];
	}

	function getCurrentRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _currentRewardPools[poolIndex];
	}

	function getCurrentTotalRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _currentTotalRewardPools[poolIndex];
	}

	function getPreviousRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _previousRewardPools[poolIndex];
	}

	function getPreviousTotalRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _previousTotalRewardPools[poolIndex];
	}

	function getUnclaimRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _unclaimRewardPools[poolIndex];
	}

	function getUnclaimTotalRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _unclaimTotalRewardPools[poolIndex];
	}

	function getTotalStaked(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _totalStaked[poolIndex];
	}

	function getTotalRewards(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _totalRewards[poolIndex];
	}

	function getCountStakers(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _countStakers[poolIndex];
	}

	function getAccumulatedTokensByPeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _accumulatedTokensByPeriod[poolIndex];
	}

	function toHours(uint256 amount) external pure returns (uint256) {
		return amount * (1 hours);
	}

	function toMinutes(uint256 amount) external pure returns (uint256) {
		return amount * (1 minutes);
	}

	function toDays(uint256 amount) external pure returns (uint256) {
		return amount * (1 days);
	}

	/**
	 * Create a new staking pool
	 */
	function createPool(string memory poolName,uint256 poolIndex,address stakedToken,address rewardToken,uint256 unstakeRewardTax,uint256 stakePeriod,uint256 rewardTokensByPeriod) public onlyOwner returns (Pool memory) {
		require(poolIndex != 0,"Pool index 0 is reserved !");
		require(_stakedTokenAddress[poolIndex] == address(0),"Pool already exists !");
		require(stakePeriod > 0,"Staking period must be greater than 0");
		_stakedTokenAddress[poolIndex] = stakedToken;
		_rewardTokenAddress[poolIndex] = rewardToken;
		if (stakedToken == rewardToken) {
			_unstakeRewardTax[poolIndex] = 0;
		} else {
			_unstakeRewardTax[poolIndex] = unstakeRewardTax;
		}
		_stakePeriod[poolIndex] = stakePeriod;
		_rewardTokensByPeriod[poolIndex] = rewardTokensByPeriod;
		emit PoolAddedSuccessfully(poolName,poolIndex,stakedToken,rewardToken,_unstakeRewardTax[poolIndex],stakePeriod,rewardTokensByPeriod);
		Pool memory pool;
		pool.poolName = poolName;
		pool.poolIndex = poolIndex;
		pool.stakedToken = stakedToken;
		pool.rewardToken = rewardToken;
		pool.unstakeRewardTax = _unstakeRewardTax[poolIndex];
		pool.stakePeriod = stakePeriod;
		pool.rewardTokensByPeriod = rewardTokensByPeriod;
		availablePools.push(pool);
		return pool;
	}
	
	function listPools() external view returns (Pool [] memory) {
		return availablePools;
	}

	function setStakeTaxPool(uint256 poolIndex,uint256 stakeTaxpoolIndex,uint256 stakeTokenTax,uint256 unstakeTokenTax) external onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_stakeTaxpoolIndex[poolIndex] = stakeTaxpoolIndex;
        if (stakeTaxpoolIndex == 0) {
			_stakeTokenTax[stakeTaxpoolIndex] = 0;
			_unstakeTokenTax[stakeTaxpoolIndex] = 0;
		} else {
			_stakeTokenTax[stakeTaxpoolIndex] = stakeTokenTax;
			_unstakeTokenTax[stakeTaxpoolIndex] = unstakeTokenTax;
		}
	}
	
	function setUnstakeRewardTax(uint256 poolIndex,uint256 tax) external onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_unstakeRewardTax[poolIndex] = tax;
	}
	

	/**
	 * Add tokens to the reward pool, anybody can add rewards
	 */
	function addRewardToPool(uint256 poolIndex,uint256 amount) external nonReentrant {
		address rewardToken = _rewardTokenAddress[poolIndex];
		require(rewardToken != address(0),"Pool does not exists !");
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(rewardToken).transferFrom(msg.sender,address(this),amount);
		_rewardPools[poolIndex] = _rewardPools[poolIndex] + amount;
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolIndex] > maxToRetrieve) {
			_rewardPools[poolIndex] = maxToRetrieve;
		}
		emit RewardAddedSuccessfully(poolIndex,rewardToken,amount);
	}

	/**
	 * Switch the reward for the period
	 */
	function _switchPool(uint256 poolIndex) private {
		// pool must exist
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		// switch can be done ?
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex] > block.timestamp) {
			// "Stake period not finished, cannot switch pool now !"
			return;
		}
		// NO REWARDS IN POOL, DO NOT SWITCH
		if (_rewardPools[poolIndex] == 0) return;
		address rewardToken = _rewardTokenAddress[poolIndex];
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolIndex] > maxToRetrieve) {
			_rewardPools[poolIndex] = maxToRetrieve;
		}
		// NO TOKEN REWARD IN CONTRACT, DO NOT SWITCH
		if (maxToRetrieve == 0) return;
		// compute amount
		uint256 amountToReward = _rewardTokensByPeriod[poolIndex];
		uint256 accumulatedReward = _accumulatedTokensByPeriod[poolIndex];
		amountToReward = amountToReward + accumulatedReward.div(2);
		if (amountToReward > _rewardPools[poolIndex]) {
			// if pool is depleted, reward is half of the reward pool
			amountToReward = _rewardPools[poolIndex].div(2);
		} else
		// at least reward should be 1/20 of reward pool
		if (amountToReward < _rewardPools[poolIndex].div(20)) {
			amountToReward = _rewardPools[poolIndex].div(20);
		}
		_accumulatedTokensByPeriod[poolIndex] = 0;
		uint256 previous = _previousRewardPools[poolIndex];
		// adding back previous pool to unclaim reward pool
		_unclaimRewardPools[poolIndex] = _unclaimRewardPools[poolIndex].add(previous);
		_unclaimTotalRewardPools[poolIndex] = _unclaimRewardPools[poolIndex];
		// remove amountToReward from global pool
		_rewardPools[poolIndex] = (_rewardPools[poolIndex].sub(amountToReward));
		// previous reward pool is current reward pool
		_previousRewardPools[poolIndex] = _currentRewardPools[poolIndex];
		_previousTotalRewardPools[poolIndex] = _previousRewardPools[poolIndex];
		// set current as amountToReward
		_currentRewardPools[poolIndex] = amountToReward;
		_currentTotalRewardPools[poolIndex] = _currentRewardPools[poolIndex];
		// set last switch date
		_lastSwitchPools[poolIndex] = block.timestamp;
		emit PoolSwitchedSuccessfully(poolIndex,amountToReward,_lastSwitchPools[poolIndex]);
	}

	/**
	 * Switch the reward for the period
	 */
	function switchPool(uint256 poolIndex) external onlyOwner {
		checkIfNeedToSwitchPool(poolIndex);
	}
	
	function addUnclaimedRewardsToRewardPool(uint256 poolIndex) external onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_rewardPools[poolIndex] = _rewardPools[poolIndex].add(_unclaimRewardPools[poolIndex]);
		_unclaimTotalRewardPools[poolIndex] = 0;
		_unclaimRewardPools[poolIndex] = 0;
	}
	
	function checkIfNeedToSwitchPool(uint256 poolIndex) private {
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex] <= block.timestamp) {
			_switchPool(poolIndex);
		}
	}
	
	/**
	 * Stake amount tokens into pool
	 */
	function stakeTokens(uint256 poolIndex,uint256 amount) external isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		checkIfNeedToSwitchPool(poolIndex);
		require(_lastSwitchPools[poolIndex] > 0,"Pool not opened for staking.");
		_claimRewards(poolIndex,msg.sender);
		address tokenAddress = _stakedTokenAddress[poolIndex];
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(tokenAddress).transferFrom(msg.sender,address(this),amount);
		// take tax fee
	    uint256 stakeTax = 0;
        if (_stakeTaxpoolIndex[poolIndex] != 0) {
        	stakeTax = _stakeTokenTax[_stakeTaxpoolIndex[poolIndex]];
        }
		uint256 totalAmount = amount;
		uint256 tax = stakeTax == 0 ? 0 : mulScale(amount,stakeTax,1000000);
		if (tax != 0) {
			// remove tax from staked amount
			amount = amount - tax;
			// add tax to accumulated token by period
			_accumulatedTokensByPeriod[_stakeTaxpoolIndex[poolIndex]] = _accumulatedTokensByPeriod[_stakeTaxpoolIndex[poolIndex]] + tax;
			// add tax to reward pool
			_rewardPools[_stakeTaxpoolIndex[poolIndex]] = _rewardPools[_stakeTaxpoolIndex[poolIndex]] + tax;
		}
		// add stake to user stakes
		bool isNew = _userStakes[poolIndex][msg.sender] == 0;
		_userStakes[poolIndex][msg.sender] = _userStakes[poolIndex][msg.sender] + amount;
		// update total staked
		_totalStaked[poolIndex] = _totalStaked[poolIndex] + amount;
		// update next claim date
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex].mul(2).div(3) > block.timestamp) {
			_nextClaimDate[poolIndex][msg.sender] = block.timestamp + _stakePeriod[poolIndex];
		} else {
			// staking too late, scheduling to next period
			_nextClaimDate[poolIndex][msg.sender] = _lastSwitchPools[poolIndex] + _stakePeriod[poolIndex].mul(2);
		}
		if (isNew) {
			_countStakers[poolIndex] = _countStakers[poolIndex].add(1);
		}
		emit StakeTokenSuccessfully(poolIndex,msg.sender, totalAmount, tax, amount, _nextClaimDate[poolIndex][msg.sender]);
	}

	function setRewardTokensByPeriod(uint256 poolIndex,uint256 amount) external onlyOwner {
		_rewardTokensByPeriod[poolIndex] = amount;
	}

	function setMinStakersForFullReward(uint256 poolIndex,uint256 count) external onlyOwner {
		_minStakersForFullReward[poolIndex] = count;
	}

	function setMinTotalStakedForFullReward(uint256 poolIndex,uint256 amount) external onlyOwner {
		_minTotalStakedForFullReward[poolIndex] = amount;
	}

	function setMinUserStakesForReward(uint256 poolIndex,uint256 amount) external onlyOwner {
		_minUserStakesForReward[poolIndex] = amount;
	}

	/**
	 * Estimate how much reward the staker can get when the stake period is over
	 */
	function _estimatedRewards(uint256 poolIndex,address account,bool forcePrevious) private view returns (uint256) {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		uint256 stakerBalance = _userStakes[poolIndex][msg.sender];
		uint256 minUserStake = _minUserStakesForReward[poolIndex];
		if (stakerBalance < minUserStake) {
			return 0;
		}
		uint256 poolAmount = 0;
		uint256 currentPoolAmount = 0;
		if (_nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex] - _stakePeriod[poolIndex] && !forcePrevious) {
			// in unclaim
			poolAmount = _unclaimTotalRewardPools[poolIndex];
			currentPoolAmount = _unclaimRewardPools[poolIndex];
		} else
		if (_nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex]) {
			// new pools has been added since, so estimate from previous pool
			poolAmount = _previousTotalRewardPools[poolIndex];
			currentPoolAmount = _previousRewardPools[poolIndex];
		} else
		if (_nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex] + _stakePeriod[poolIndex]) {
			poolAmount = _currentTotalRewardPools[poolIndex];
			currentPoolAmount = _currentRewardPools[poolIndex];
		}
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolIndex);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolIndex];
			if (_totalStaked[poolIndex] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolIndex];
			}
			if (_countStakers[poolIndex] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolIndex],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			uint256 reward = mulScale(poolAmount,rewardPercentage,1000000);
			// initial percentage changed, take as mush as current pool amount.
			if (reward > currentPoolAmount) {
				if (_totalStaked[poolIndex] == stakerBalance) {
					reward = currentPoolAmount;	
				} else {
					reward = mulScale(currentPoolAmount,rewardPercentage,1000000);
				}
			}
			return reward;
		} else {
			return 0;
		}
	}

	/**
	 * Estimate how much reward the staker could get at claim date
	 */
	function estimatedRewards(uint256 poolIndex,address account) public view returns (uint256) {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		if (_nextClaimDate[poolIndex][account] != 0 && _nextClaimDate[poolIndex][account] <= block.timestamp) {
			if (_nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex] - _stakePeriod[poolIndex])	{
				uint256 rewardUnclaim = _estimatedRewards(poolIndex,account,false);
				uint256 reward = _estimatedRewards(poolIndex,account,true);
				return reward.add(rewardUnclaim);
			} else {
				return _estimatedRewards(poolIndex,account,true);
			}
		}
		uint256 stakerBalance = _userStakes[poolIndex][msg.sender];
		uint256 minUserStakes = _minUserStakesForReward[poolIndex];
		if (stakerBalance < minUserStakes) {
			return 0;
		}
		uint256 poolAmount = _currentTotalRewardPools[poolIndex];
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolIndex);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolIndex];
			if (_totalStaked[poolIndex] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolIndex];
			}
			if (_countStakers[poolIndex] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolIndex],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			return mulScale(poolAmount,rewardPercentage,1000000);
		} else {
			return 0;
		}
	}

	function _claimRewards(uint256 poolIndex,address account) private {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return;
		}
		checkIfNeedToSwitchPool(poolIndex);
		address rewardTokenAddress = _rewardTokenAddress[poolIndex];
		address tokenAddress = _stakedTokenAddress[poolIndex];
		if (_nextClaimDate[poolIndex][account] <= block.timestamp) {
			bool unclaim = _nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex] - _stakePeriod[poolIndex];
			uint256 reward = _estimatedRewards(poolIndex,account,true);
			uint256 rewardUnclaim = 0;
			if (unclaim) {
				rewardUnclaim = _estimatedRewards(poolIndex,account,false);
			}
			bool previous = _nextClaimDate[poolIndex][account] < _lastSwitchPools[poolIndex];
			// next claim, next period.
			_nextClaimDate[poolIndex][account] = _lastSwitchPools[poolIndex] + _stakePeriod[poolIndex];
			if (reward > 0) {
				if (unclaim) {
					_unclaimRewardPools[poolIndex] = _unclaimRewardPools[poolIndex].sub(rewardUnclaim);
				}
				if (previous) {
					_previousRewardPools[poolIndex] = _previousRewardPools[poolIndex].sub(reward);
				} else {
					_currentRewardPools[poolIndex] = _currentRewardPools[poolIndex].sub(reward);
				}
				_totalRewards[poolIndex] = _totalRewards[poolIndex].add(reward).add(rewardUnclaim);
				if (rewardTokenAddress == tokenAddress) {
					// add automatically to user stakes
					_userStakes[poolIndex][account] = _userStakes[poolIndex][account].add(reward).add(rewardUnclaim);
					_userRewards[poolIndex][account] = _userRewards[poolIndex][account].add(reward).add(rewardUnclaim);
				} else {
					_userRewards[poolIndex][account] = _userRewards[poolIndex][account].add(reward).add(rewardUnclaim);
				}
			}
			emit ClaimRewardSuccessfully(poolIndex, account, reward, _nextClaimDate[poolIndex][account]);
		}
	}

	function claimRewards(uint256 poolIndex) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_claimRewards(poolIndex,msg.sender);
	}

	function _retrieveRewards(uint256 poolIndex,address account) private {
		require(_rewardTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address rewardTokenAddress = _rewardTokenAddress[poolIndex];
		address tokenAddress = _stakedTokenAddress[poolIndex];
		_claimRewards(poolIndex,msg.sender);
		uint256 rewardBalance = _userRewards[poolIndex][account];
		require(rewardBalance > 0,"No reward to unstake");
		uint256 unstakeTax = _unstakeRewardTax[poolIndex];
		// take tax fee
		uint256 totalToRemove = rewardBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(totalToRemove,unstakeTax,1000000);
		if (tax != 0) {
			rewardBalance = totalToRemove - tax;
			require(rewardBalance > 0,"Error no tokens to send.");
			// add tax to accumulated tokens for the current period
			_accumulatedTokensByPeriod[poolIndex] = _accumulatedTokensByPeriod[poolIndex] + tax;
			// add tax to reward pool
			_rewardPools[poolIndex] = _rewardPools[poolIndex] + tax;
		}
		if (rewardTokenAddress == tokenAddress) {
			_userStakes[poolIndex][account] = _userStakes[poolIndex][account].sub(_userRewards[poolIndex][account]);
		}
		_totalRewards[poolIndex] = _totalRewards[poolIndex].sub(_userRewards[poolIndex][account]);
		// remove reward from user reward
		_userRewards[poolIndex][account] = 0;
		// send token
		bool sent = IBEP20(rewardTokenAddress).transfer(account,rewardBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		emit RetrieveRewardSuccessfully(poolIndex,account, rewardBalance);
	}

	function retrieveRewards(uint256 poolIndex,address account) public isHuman nonReentrant {
		_retrieveRewards(poolIndex,account);
	}

	function unstakeTokens(uint256 poolIndex,address account) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address tokenAddress = _stakedTokenAddress[poolIndex];
		_claimRewards(poolIndex,msg.sender);
		_retrieveRewards(poolIndex,msg.sender);
		uint256 stakerBalance = _userStakes[poolIndex][account];
		require(stakerBalance > 0,"No tokens to unstake");
		// take tax fee
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
	    uint256 unstakeTax = 0;
        if (stakeTaxpoolIndex != 0) {
	        unstakeTax = _unstakeTokenTax[stakeTaxpoolIndex];
        }
		uint256 totalToRemove = stakerBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(stakerBalance,unstakeTax,1000000);
		// remove tax from staked amount
		if (tax > 0) {
			stakerBalance = stakerBalance - tax;
			require(stakerBalance > 0,"No tokens to unstake.");
			_accumulatedTokensByPeriod[stakeTaxpoolIndex] = _accumulatedTokensByPeriod[stakeTaxpoolIndex] + tax;
			_rewardPools[stakeTaxpoolIndex] = _rewardPools[stakeTaxpoolIndex] + tax;
		}
		_totalStaked[poolIndex] = _totalStaked[poolIndex]-totalToRemove;
		_userStakes[poolIndex][account] = 0;
		bool sent = IBEP20(tokenAddress).transfer(account,stakerBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		if (_countStakers[poolIndex] >= 1) {
			_countStakers[poolIndex] = _countStakers[poolIndex].sub(1);
		}
		emit UnstakeTokenSuccessfully(poolIndex,account, stakerBalance);
	}

	// Retrieve BNB sent to this contract
	function retrieveBNB(uint256 amount) external nonReentrant onlyOwner {
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0 && amount <= toRetrieve, 'Error: Cannot withdraw BNB not enough fund.');
		(bool sent,) = address(retrieveFundWallet).call{value : amount}("");
		require(sent, 'Error: Cannot withdraw BNB');
	}

	// Retrieve the tokens in the Reward pool for the given tokenAddress
	function retrieveRewardTokens(uint256 poolIndex) external nonReentrant onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address tokenAddress = _rewardTokenAddress[poolIndex];
		uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		uint256 toRetrieve = _rewardPools[poolIndex];
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, 'Error: Cannot withdraw TOKEN not enough fund.');
		_rewardPools[poolIndex] = 0;
		bool sent = IBEP20(tokenAddress).transfer(retrieveFundWallet,toRetrieve);
		require(sent, 'Error: Cannot withdraw TOKEN');
	}

	/** 
	 * Retrieve the tokens in the contract balance for the given tokenAddress
	 * CALL RESET POOL BEFORE RETRIEVING ANYTHING
	 * WARNING THIS FUNCTION CAN BREAK THE POOL
	 * ONLY FOR EMERGENCY
	 */
	function retrieveTokens(address tokenAddress,uint256 amount) external nonReentrant onlyOwner {
		uint256 toRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		if (amount > toRetrieve) {
			amount = toRetrieve;
		}
		require(amount > 0, 'Error: Cannot withdraw TOKEN not enough fund.');
		bool sent = IBEP20(tokenAddress).transfer(retrieveFundWallet,amount);
		require(sent, 'Error: Cannot withdraw TOKEN');
	}

	/** 
	 * WARNING THIS FUNCTION WILL BREAK THE POOL
	 * ONLY FOR EMERGENCY
	 * DO NOT CREATE A POOL WITH SAME NAME AGAIN
	 */
	function resetPool(uint256 poolIndex) public onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		require(_totalStaked[poolIndex] == 0,"User must unstake everything first");
		require(_totalRewards[poolIndex] == 0,"User must unstake everything first");
		_stakedTokenAddress[poolIndex] = address(0);
		_rewardTokenAddress[poolIndex] = address(0);
		_rewardPools[poolIndex] = 0;
		_currentRewardPools[poolIndex] = 0;
		_currentTotalRewardPools[poolIndex] = 0;
		_unclaimRewardPools[poolIndex] = 0;
		_unclaimTotalRewardPools[poolIndex] = 0;
		_previousRewardPools[poolIndex] = 0;
		_previousTotalRewardPools[poolIndex] = 0;
		_minTotalStakedForFullReward[poolIndex] = 0;
		_minUserStakesForReward[poolIndex] = 0;
		_countStakers[poolIndex] = 0;
		_lastSwitchPools[poolIndex] = 0;
		_stakeTaxpoolIndex[poolIndex] = poolIndex;
		if (availablePools.length == 1) {
		    availablePools.pop();
		} else {
    		for (uint256 i=0;i<availablePools.length;i++) {
                if (availablePools[i].poolIndex == poolIndex) {
                    availablePools[i] = availablePools[availablePools.length-1];
                    availablePools.pop();
                }
    		}
		}
	}
}