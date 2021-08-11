/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



pragma experimental ABIEncoderV2;








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


contract LamboStake is Context, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	// Pool
	mapping(string => address) private _rewardTokenAddress;
	mapping(string => address) private _stakedTokenAddress;

	// Tax handling
	mapping(string => string) private _stakeTaxPoolName;
	mapping(string => uint256) private _unstakeRewardTax;
	mapping(string => uint256) private _stakeTokenTax;
	mapping(string => uint256) private _unstakeTokenTax;

	// Total reward for pool
	mapping(string => uint256) private _rewardPools;
	// last time the reward pool was switched
	mapping(string => uint256) private _lastSwitchPools;
	mapping(string => uint256) private _stakePeriod;
	mapping(string => uint256) private _rewardTokensByPeriod;

	mapping(string => uint256) private _currentRewardPools;
	mapping(string => uint256) private _currentTotalRewardPools;
	mapping(string => uint256) private _previousRewardPools;
	mapping(string => uint256) private _previousTotalRewardPools;

	mapping(string => uint256) private _totalStaked;
	mapping(string => uint256) private _totalRewards;
	mapping(string => uint256) private _countStakers;
	mapping(string => uint256) private _accumulatedTokensByPeriod;
	mapping(string => uint256) private _minUserStakesForReward;
	mapping(string => uint256) private _minTotalStakedForFullReward;
	mapping(string => uint256) private _minStakersForFullReward;
	mapping(string => mapping(address => uint256)) private _userStakes;
	mapping(string => mapping(address => uint256)) private _userRewards;
	mapping(string => mapping(address => uint256)) private _nextClaimDate;
    string private empty = "";

	address private retrieveFundWallet;

	event PoolAddedSuccessfully(
		string poolName,
		address stakedToken,
		address rewardToken,
		uint256 unstakeRewardTax,
		uint256 stakePeriod,
		uint256 rewardTokensByPeriod
	);

	event RewardAddedSuccessfully (
		string poolName,
		address rewardToken,
		uint256 amount
	);

	event PoolSwitchedSuccessfully (
		string poolName,
		uint256 amount,
		uint256 switchDate
	);

	event StakeTokenSuccessfully(
		string poolName,
		address from,
		uint256 totalAmount,
		uint256 tax,
		uint256 amount,
		uint256 nextClaimDate
	);

	event ClaimRewardSuccessfully(
		string poolName,
		address from,
		uint256 amount,
		uint256 nextClaimDate
	);

	event RetrieveRewardSuccessfully(
		string poolName,
		address to,
		uint256 rewardBalance
	);

	event UnstakeTokenSuccessfully(
		string poolName,
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

	function getRewardTokenAddress(string calldata poolName) external view returns (address) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _rewardTokenAddress[poolName];
	}

	function getStakeTokenAddress(string calldata poolName) external view returns (address) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _stakedTokenAddress[poolName];
	}

	function getMinStakersForFullReward(string memory poolName) public view returns (uint256) {
		uint256 ret = _minStakersForFullReward[poolName];
		if (ret == 0) {
			return 100;
		}
		return _minStakersForFullReward[poolName];
	}

	function getMinTotalStakedForFullReward(string calldata poolName) external view returns (uint256) {
		return _minTotalStakedForFullReward[poolName];
	}

	function getMinUserStakesForReward(string calldata poolName) external view returns (uint256) {
		return _minUserStakesForReward[poolName];
	}

	function getUserStakes(string calldata poolName,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _userStakes[poolName][account];
	}

	function getUserRewards(string calldata poolName,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _userRewards[poolName][account];
	}

	function getNextClaimDate(string calldata poolName,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _nextClaimDate[poolName][account];
	}

	function getUnstakeRewardTax(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _unstakeRewardTax[poolName];
	}

	function getStakeTokenTax(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		string memory stakeTaxPoolName = _stakeTaxPoolName[poolName];
		return _stakeTokenTax[stakeTaxPoolName];
	}

	function getUnstakeTokenTax(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		string memory stakeTaxPoolName = _stakeTaxPoolName[poolName];
		return _unstakeTokenTax[stakeTaxPoolName];
	}

	function getRewardPool(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _rewardPools[poolName];
	}

	function getLastSwitchDate(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _lastSwitchPools[poolName];
	}

	function getStakePeriod(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _stakePeriod[poolName];
	}

	function getRewardTokensByPeriod(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _rewardTokensByPeriod[poolName];
	}

	function getCurrentRewardPools(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _currentRewardPools[poolName];
	}

	function getCurrentTotalRewardPools(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _currentTotalRewardPools[poolName];
	}

	function getPreviousRewardPools(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _previousRewardPools[poolName];
	}

	function getPreviousTotalRewardPools(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _previousTotalRewardPools[poolName];
	}

	function getTotalStaked(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _totalStaked[poolName];
	}

	function getTotalRewards(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _totalRewards[poolName];
	}

	function getCountStakers(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _countStakers[poolName];
	}

	function getAccumulatedTokensByPeriod(string calldata poolName) external view returns (uint256) {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		return _accumulatedTokensByPeriod[poolName];
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
	function createPool(string memory poolName,address stakedToken,address rewardToken,uint256 unstakeRewardTax,uint256 stakePeriod,uint256 rewardTokensByPeriod) public onlyOwner {
		require(_stakedTokenAddress[poolName] == address(0),"Pool already exists !");
		require(stakePeriod > 0,"Staking period must be greater than 0");
		_stakedTokenAddress[poolName] = stakedToken;
		_rewardTokenAddress[poolName] = rewardToken;
		if (stakedToken == rewardToken) {
			_unstakeRewardTax[poolName] = 0;
		} else {
			_unstakeRewardTax[poolName] = unstakeRewardTax;
		}
		_stakePeriod[poolName] = stakePeriod;
		_rewardTokensByPeriod[poolName] = rewardTokensByPeriod;
		emit PoolAddedSuccessfully(poolName,stakedToken,rewardToken,_unstakeRewardTax[poolName],stakePeriod,rewardTokensByPeriod);
	}

	function setStakeTaxPool(string calldata poolName,string calldata stakeTaxPoolName,uint256 stakeTokenTax,uint256 unstakeTokenTax) external onlyOwner {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		_stakeTaxPoolName[poolName] = stakeTaxPoolName;
        if (keccak256(bytes(stakeTaxPoolName)) == keccak256(bytes(empty))) {
			_stakeTokenTax[stakeTaxPoolName] = 0;
			_unstakeTokenTax[stakeTaxPoolName] = 0;
		} else {
			_stakeTokenTax[stakeTaxPoolName] = stakeTokenTax;
			_unstakeTokenTax[stakeTaxPoolName] = unstakeTokenTax;
		}
	}

	/**
	 * Add tokens to the reward pool, anybody can add rewards
	 */
	function addRewardToPool(string calldata poolName,uint256 amount) external nonReentrant {
		address rewardToken = _rewardTokenAddress[poolName];
		require(rewardToken != address(0),"Pool does not exists !");
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(rewardToken).transferFrom(msg.sender,address(this),amount);
		_rewardPools[poolName] = _rewardPools[poolName] + amount;
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolName] > maxToRetrieve) {
			_rewardPools[poolName] = maxToRetrieve;
		}
		emit RewardAddedSuccessfully(poolName,rewardToken,amount);
	}

	/**
	 * Switch the reward for the period
	 */
	function _switchPool(string memory poolName) private {
		// pool must exist
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		// switch can be done ?
		if (_lastSwitchPools[poolName] + _stakePeriod[poolName] > block.timestamp) {
			// "Stake period not finished, cannot switch pool now !"
			return;
		}
		// NO REWARDS IN POOL, DO NOT SWITCH
		if (_rewardPools[poolName] == 0) return;
		address rewardToken = _rewardTokenAddress[poolName];
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolName] > maxToRetrieve) {
			_rewardPools[poolName] = maxToRetrieve;
		}
		// NO TOKEN REWARD IN CONTRACT, DO NOT SWITCH
		if (maxToRetrieve == 0) return;
		// compute amount
		uint256 amountToReward = _rewardTokensByPeriod[poolName];
		uint256 accumulatedReward = _accumulatedTokensByPeriod[poolName];
		amountToReward = amountToReward + accumulatedReward.div(2);
		if (amountToReward > _rewardPools[poolName]) {
			// if pool is depleted, reward is half of the reward pool
			amountToReward = _rewardPools[poolName].div(2);
		} else
		// at least reward should be 1/20 of reward pool
		if (amountToReward < _rewardPools[poolName].div(20)) {
			amountToReward = _rewardPools[poolName].div(20);
		}
		_accumulatedTokensByPeriod[poolName] = 0;
		uint256 previous = _previousRewardPools[poolName];
		// adding back previous pool to global reward pool and remove amountToReward
		_rewardPools[poolName] = (_rewardPools[poolName] - amountToReward) + previous;
		// previous reward pool is current reward pool
		_previousRewardPools[poolName] = _currentRewardPools[poolName];
		_previousTotalRewardPools[poolName] = _previousRewardPools[poolName];
		// set current as amountToReward
		_currentRewardPools[poolName] = amountToReward;
		_currentTotalRewardPools[poolName] = _currentRewardPools[poolName];
		// set last switch date
		_lastSwitchPools[poolName] = block.timestamp;
		emit PoolSwitchedSuccessfully(poolName,amountToReward,_lastSwitchPools[poolName]);
	}

	/**
	 * Switch the reward for the period
	 */
	function switchPool(string calldata poolName) external onlyOwner {
		checkIfNeedToSwitchPool(poolName);
	}

	function checkIfNeedToSwitchPool(string memory poolName) private {
		if (_lastSwitchPools[poolName] + _stakePeriod[poolName] <= block.timestamp) {
			_switchPool(poolName);
		}
	}

	/**
	 * Stake amount tokens into pool
	 */
	function stakeTokens(string calldata poolName,uint256 amount) external isHuman nonReentrant {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		checkIfNeedToSwitchPool(poolName);
		require(_lastSwitchPools[poolName] > 0,"Pool not opened for staking.");
		address tokenAddress = _stakedTokenAddress[poolName];
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(tokenAddress).transferFrom(msg.sender,address(this),amount);
		// take tax fee
	    uint256 stakeTax = 0;
        if (keccak256(bytes(_stakeTaxPoolName[poolName])) != keccak256(bytes(empty))) {
        	stakeTax = _stakeTokenTax[_stakeTaxPoolName[poolName]];
        }
		uint256 totalAmount = amount;
		uint256 tax = stakeTax == 0 ? 0 : mulScale(amount,stakeTax,1000000);
		if (tax != 0) {
			// remove tax from staked amount
			amount = amount - tax;
			// add tax to accumulated token by period
			_accumulatedTokensByPeriod[_stakeTaxPoolName[poolName]] = _accumulatedTokensByPeriod[_stakeTaxPoolName[poolName]] + tax;
			// add tax to reward pool
			_rewardPools[_stakeTaxPoolName[poolName]] = _rewardPools[_stakeTaxPoolName[poolName]] + tax;
		}
		// add stake to user stakes
		_userStakes[poolName][msg.sender] = _userStakes[poolName][msg.sender] + amount;
		// update total staked
		_totalStaked[poolName] = _totalStaked[poolName] + amount;
		// update next claim date
		if (_lastSwitchPools[poolName] + _stakePeriod[poolName].div(3).mul(2) > block.timestamp) {
			_nextClaimDate[poolName][msg.sender] = block.timestamp + _stakePeriod[poolName];
		} else {
			// staking too late, scheduling to next period
			_nextClaimDate[poolName][msg.sender] = _lastSwitchPools[poolName] + _stakePeriod[poolName].mul(2);
		}
		_countStakers[poolName] = _countStakers[poolName].add(1);
		emit StakeTokenSuccessfully(poolName,msg.sender, totalAmount, tax, amount, _nextClaimDate[poolName][msg.sender]);
	}

	function setMinStakersForFullReward(string calldata poolName,uint256 count) external onlyOwner {
		_minStakersForFullReward[poolName] = count;
	}

	function setMinTotalStakedForFullReward(string calldata poolName,uint256 amount) external onlyOwner {
		_minTotalStakedForFullReward[poolName] = amount;
	}

	function setMinUserStakesForReward(string calldata poolName,uint256 amount) external onlyOwner {
		_minUserStakesForReward[poolName] = amount;
	}

	/**
	 * Estimate how much reward the staker can get when the stake period is over
	 */
	function _estimatedRewards(string memory poolName,address account) private view returns (uint256) {
		if (_stakedTokenAddress[poolName] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		uint256 stakerBalance = _userStakes[poolName][msg.sender];
		uint256 minUserStake = _minUserStakesForReward[poolName];
		if (stakerBalance < minUserStake) {
			return 0;
		}
		uint256 poolAmount = 0;
		uint256 currentPoolAmount = 0;
		if (_nextClaimDate[poolName][account] <= _lastSwitchPools[poolName] + _stakePeriod[poolName]) {
			poolAmount = _currentTotalRewardPools[poolName];
			currentPoolAmount = _currentRewardPools[poolName];
		}
		bool previous = false;
		if (_nextClaimDate[poolName][account] <= _lastSwitchPools[poolName]) {
			// new pools has been added since, so estimate from previous pool
			poolAmount = _previousTotalRewardPools[poolName];
			currentPoolAmount = _previousRewardPools[poolName];
			previous = true;
		}
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolName);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolName];
			if (_totalStaked[poolName] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolName];
			}
			if (_countStakers[poolName] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolName],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			uint256 reward = mulScale(poolAmount,rewardPercentage,1000000);
			// initial percentage changed, take as mush as current pool amount.
			if (reward > currentPoolAmount) {
				if (_totalStaked[poolName] == stakerBalance) {
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
	function estimatedRewards(string memory poolName,address account) public view returns (uint256) {
		if (_stakedTokenAddress[poolName] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		if (_nextClaimDate[poolName][account] != 0 && _nextClaimDate[poolName][account] <= block.timestamp) {
			return _estimatedRewards(poolName,account);
		}
		uint256 stakerBalance = _userStakes[poolName][msg.sender];
		uint256 minUserStakes = _minUserStakesForReward[poolName];
		if (stakerBalance < minUserStakes) {
			return 0;
		}
		uint256 poolAmount = _currentTotalRewardPools[poolName];
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolName);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolName];
			if (_totalStaked[poolName] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolName];
			}
			if (_countStakers[poolName] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolName],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			return mulScale(poolAmount,rewardPercentage,1000000);
		} else {
			return 0;
		}
	}

	function _claimRewards(string memory poolName,address account) private {
		if (_stakedTokenAddress[poolName] == address(0)) {
			// "Pool does not exists !"
			return;
		}
		checkIfNeedToSwitchPool(poolName);
		address rewardTokenAddress = _rewardTokenAddress[poolName];
		address tokenAddress = _stakedTokenAddress[poolName];
		if (_nextClaimDate[poolName][account] <= block.timestamp) {
			uint256 reward = _estimatedRewards(poolName,account);
			bool previous = _nextClaimDate[poolName][account] <= _lastSwitchPools[poolName];
			_nextClaimDate[poolName][account] = _nextClaimDate[poolName][account] + _stakePeriod[poolName];
			if (reward > 0) {
				if (previous) {
					_previousRewardPools[poolName] = _previousRewardPools[poolName] - reward;
				} else {
					_currentRewardPools[poolName] = _currentRewardPools[poolName] - reward;
				}
				_totalRewards[poolName] = _totalRewards[poolName] + reward;
				if (rewardTokenAddress == tokenAddress) {
					// add automatically to user stakes
					_userStakes[poolName][account] = _userStakes[poolName][account] + reward;
					_userRewards[poolName][account] = _userRewards[poolName][account] + reward;
				} else {
					_userRewards[poolName][account] = _userRewards[poolName][account] + reward;
				}
			}
			emit ClaimRewardSuccessfully(poolName, account, reward, _nextClaimDate[poolName][account]);
		}
	}

	function claimRewards(string memory poolName) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		_claimRewards(poolName,msg.sender);
	}

	function retrieveRewards(string memory poolName,address account) public isHuman nonReentrant {
		require(_rewardTokenAddress[poolName] != address(0),"Pool does not exists !");
		address rewardTokenAddress = _rewardTokenAddress[poolName];
		address tokenAddress = _stakedTokenAddress[poolName];
		require(rewardTokenAddress != tokenAddress,"You must unstake to retrieve rewards !");
		_claimRewards(poolName,msg.sender);
		uint256 rewardBalance = _userRewards[poolName][account];
		require(rewardBalance > 0,"No reward to unstake");
		uint256 unstakeTax = _unstakeRewardTax[poolName];
		// take tax fee
		uint256 totalToRemove = rewardBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(totalToRemove,unstakeTax,1000000);
		if (tax != 0) {
			rewardBalance = totalToRemove - tax;
			require(rewardBalance > 0,"Error no tokens to send.");
			// add tax to accumulated tokens for the current period
			_accumulatedTokensByPeriod[poolName] = _accumulatedTokensByPeriod[poolName] + tax;
			// add tax to reward pool
			_rewardPools[poolName] = _rewardPools[poolName] + tax;
		}
		// remove reward from user reward
		_userRewards[poolName][account] = 0;
		// send token
		bool sent = IBEP20(rewardTokenAddress).transfer(account,rewardBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		emit RetrieveRewardSuccessfully(poolName,account, rewardBalance);
	}

	function unstakeTokens(string memory poolName,address account) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		address rewardTokenAddress = _rewardTokenAddress[poolName];
		address tokenAddress = _stakedTokenAddress[poolName];
		_claimRewards(poolName,msg.sender);
		uint256 stakerBalance = _userStakes[poolName][account];
		require(stakerBalance > 0,"No tokens to unstake");
		// take tax fee
		string memory stakeTaxPoolName = _stakeTaxPoolName[poolName];
	    uint256 unstakeTax = 0;
        if (keccak256(bytes(stakeTaxPoolName)) != keccak256(bytes(empty))) {
	        unstakeTax = _unstakeTokenTax[stakeTaxPoolName];
        }
		uint256 totalToRemove = stakerBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(stakerBalance,unstakeTax,1000000);
		// remove tax from staked amount
		if (tax > 0) {
			stakerBalance = stakerBalance - tax;
			require(stakerBalance > 0,"No tokens to unstake.");
			_accumulatedTokensByPeriod[stakeTaxPoolName] = _accumulatedTokensByPeriod[stakeTaxPoolName] + tax;
			_rewardPools[stakeTaxPoolName] = _rewardPools[stakeTaxPoolName] + tax;
		}
		_totalStaked[poolName] = _totalStaked[poolName]-totalToRemove;
		_userStakes[poolName][account] = 0;
		if (tokenAddress == rewardTokenAddress) {
			_totalRewards[poolName] = _totalRewards[poolName] - _userRewards[poolName][account];
			_userRewards[poolName][account] = 0;
		}
		bool sent = IBEP20(tokenAddress).transfer(account,stakerBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		if (_countStakers[poolName] >= 1) {
			_countStakers[poolName] = _countStakers[poolName].sub(1);
		}
		emit UnstakeTokenSuccessfully(poolName,account, stakerBalance);
	}

	// Retrieve BNB sent to this contract
	function retrieveBNB(uint256 amount) external nonReentrant onlyOwner {
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0 && amount <= toRetrieve, 'Error: Cannot withdraw BNB not enough fund.');
		(bool sent,) = address(retrieveFundWallet).call{value : amount}("");
		require(sent, 'Error: Cannot withdraw BNB');
	}

	// Retrieve the tokens in the Reward pool for the given tokenAddress
	function retrieveRewardTokens(string calldata poolName) external nonReentrant onlyOwner {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		address tokenAddress = _rewardTokenAddress[poolName];
		uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		uint256 toRetrieve = _rewardPools[poolName];
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, 'Error: Cannot withdraw TOKEN not enough fund.');
		_rewardPools[poolName] = 0;
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
	function resetPool(string memory poolName) public onlyOwner {
		require(_stakedTokenAddress[poolName] != address(0),"Pool does not exists !");
		require(_totalStaked[poolName] == 0,"User must unstake everything first");
		require(_totalRewards[poolName] == 0,"User must unstake everything first");
		_stakedTokenAddress[poolName] = address(0);
		_rewardTokenAddress[poolName] = address(0);
		_rewardPools[poolName] = 0;
		_currentRewardPools[poolName] = 0;
		_currentTotalRewardPools[poolName] = 0;
		_previousRewardPools[poolName] = 0;
		_previousTotalRewardPools[poolName] = 0;
		_minTotalStakedForFullReward[poolName] = 0;
		_minUserStakesForReward[poolName] = 0;
		_countStakers[poolName] = 0;
		_lastSwitchPools[poolName] = 0;
		_stakeTaxPoolName[poolName] = poolName;
	}
}