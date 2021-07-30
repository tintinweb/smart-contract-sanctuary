/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: Address

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// Part: Context

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

// Part: ISwapRouter

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

/*
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
*/
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
/*
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
*/
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// Part: ReentrancyGuard

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
}

// Part: IERC20Metadata

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// Part: Ownable

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
abstract contract Ownable is Context {
    address private _owner;

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// Part: AutoStakingPool

contract AutoStakingPool is Context, Ownable, ReentrancyGuard {
	// constants
	address public autoAddress;

	// current balance, and when accounts are allowed to unstake
	struct Release {
		uint256 date;
		uint256 amount;
	}
	mapping(address => uint256) private _balance;
	mapping(address => uint256) private _availableBalance;
	mapping(address => Release[]) private _releases;
	uint256 public startDate;

	// rewards for staking
	mapping(address => uint256) private _nextUnpaidDay;
	mapping(address => uint256) private _rewards;

	// day = timespan from day*86400 to (day+1)*86400
	// everything is paid out at end of day
	uint256 private _rewardSupply;
	uint256 private _rewardsYetToBeClaimed; // this variable may ultimately be unnecessary?
	uint256 public rewardEnd;
	uint256 public dailyPayout;

	mapping(uint256 => uint256) private dailyRewardRate; // values in Autowei for better precision
	uint256 private _nextDayToUpdate;
	uint256 private _totalStaked; // total staked across all users in a day

	constructor(address _autoAddress, uint256 _startDate) {
		autoAddress = _autoAddress;
		startDate = _startDate;
	}

	function stake(uint256 amount) public nonReentrant {
		_stake(_msgSender(), amount);
	}

	function stake(address account, uint256 amount) public nonReentrant {
		require(
			_msgSender() == account || _msgSender() == autoAddress,
			"Cannot stake on behalf of another account."
		);
		_stake(account, amount);
	}

	function _stake(address account, uint256 amount) private {
		_updateRewards(account); // also calls _updateDailyRates()
		IERC20(autoAddress).transferFrom(account, address(this), amount);
		_balance[account] += amount;
		_totalStaked += amount;
		uint256 date = (startDate < block.timestamp)
			? block.timestamp - startDate
			: 0;
		uint256 fifth = amount / 5;
		_releases[account].push(Release(date + 604800, fifth));
		_releases[account].push(Release(date + 1209600, fifth));
		_releases[account].push(Release(date + 1814400, fifth));
		_releases[account].push(Release(date + 2419200, fifth));
		_releases[account].push(Release(date + 3024000, amount - 4 * fifth));
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balance[account];
	}

	function availableBalance(address account) public view returns (uint256) {
		uint newlyAvailable = 0;
		Release[] memory arr = _releases[account];
		for (uint i = 0; i < arr.length; i++)
			if (block.timestamp > startDate + arr[i].date)
				newlyAvailable += arr[i].amount;
		return _availableBalance[account] + newlyAvailable;
	}

	function lockedBalance(address account) public view returns (uint256) {
		return balanceOf(account) - availableBalance(account);
	}

	function withdraw(uint256 amount) public nonReentrant {
		_updateRewards(_msgSender()); // also calls _updateDailyRates()
		_processReleases(_msgSender());
		require(_availableBalance[_msgSender()] >= amount, "Not enough AUTO avaialable to withdraw.");
		IERC20(autoAddress).transfer(_msgSender(), amount);
		_availableBalance[_msgSender()] -= amount;
		_balance[_msgSender()] -= amount;
		_totalStaked -= amount;
	}

	function rewards(address account) public view returns (uint256) {
		if (_nextUnpaidDay[account] == 0) // waiting for user's first stake
			return 0;
		uint256 today = block.timestamp / 86400;
		uint256 start = _nextUnpaidDay[account];
		uint256 staked = _balance[account];
		uint256 totalRewards = _rewards[account];
		for (uint256 day = start; day < today; day++)
			totalRewards += staked * _rewardRate(day) / 1e18;
		return totalRewards;
	}

	function withdrawRewards() public nonReentrant {
		_updateRewards(_msgSender());
		uint256 amount = _rewards[_msgSender()];
		require(amount > 0, "Nothing to withdraw.");
		// This should never fail unless I've done something wrong
		require(amount <= _rewardsYetToBeClaimed, "Insufficient funds in contract.");
		_rewardsYetToBeClaimed -= amount;
		_rewards[_msgSender()] = 0;
		IERC20(autoAddress).transfer(_msgSender(), amount);
	}

	function addRewards(uint256 duration, uint256 amount) public nonReentrant {
		require(duration > 0, "Duration cannot be 0.");
		require(duration < 1000, "Duration should be in days.");
		_updateDailyRates(); // also updates the rewards available vs. waiting to be claimed
		uint256 today = (block.timestamp / 86400);
		uint256 end = today + duration;
		if (end > rewardEnd)
			rewardEnd = end;
		IERC20(autoAddress).transferFrom(_msgSender(), address(this), amount);
		_rewardSupply += amount;
		dailyPayout = _rewardSupply / (rewardEnd - today);
		if (_nextDayToUpdate == 0)
			_nextDayToUpdate = today;
	}

	function showReleases(address account) public view returns (Release[] memory) {
		return _releases[account];
	}

	function delayStartDate(uint256 newDate) public onlyOwner {
		require(startDate < block.timestamp + 604800, "Start date is too far passed to update.");
		require(newDate > startDate, "Start date must increase.");
		startDate = newDate;
	}

	// make this public to somewhat reduce user gas costs?
	function _updateDailyRates() private {
		if (rewardEnd <= _nextDayToUpdate)
			return;
		uint256 today = block.timestamp / 86400;
		// add this to somewhat reduce gas costs on already-updated withdrawls?
		// if (today < nextDayToUpdate)
		// 	return;
		uint256 day = _nextDayToUpdate;
		for (; day < today; day++)
			dailyRewardRate[day] = _rewardRate(day);
		uint256 end = day;
		if (end > rewardEnd)
			end = rewardEnd;
		uint256 totalRewarded = dailyPayout * (end - _nextDayToUpdate);
		_nextDayToUpdate = day;
		_rewardSupply -= totalRewarded;
		_rewardsYetToBeClaimed += totalRewarded;
	}

	// TODO make sure this is called before every balance change
	function _updateRewards(address account) private {
		_updateDailyRates();
		_rewards[account] = rewards(account);
		_nextUnpaidDay[account] = block.timestamp / 86400;
	}

	function _processReleases(address account) private {
		uint removed = 0;
		Release[] storage arr = _releases[account];
		for (uint i = 0; i < arr.length; i++) {
			if (removed > 0)
				arr[i - removed] = arr[i];
			if (block.timestamp > startDate + arr[i].date) {
				_availableBalance[account] += arr[i].amount;
				removed += 1;
			}
		}
		for (uint i = 0; i < removed; i++)
			arr.pop();
		_releases[account] = arr;
	}

	function _rewardRate(uint256 day) private view returns (uint256) {
		if (day < _nextDayToUpdate)
			return dailyRewardRate[day];
		if (day >= rewardEnd || _totalStaked == 0)
			return 0;
		else
			return (dailyPayout * 1e18) / _totalStaked;
	}
}

// File: AutoETH.sol

// modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract Auto is Context, IERC20, IERC20Metadata, Ownable, ReentrancyGuard {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public stakingAddress;
    mapping(address => bool) private noStakeOnTransferFrom;
    mapping(address => bool) private noStakeOnTransferTo;
    ISwapRouter public swapRouter;

    mapping(address => bool) private feeWhitelist;
    uint8 public feePercent = 6;
    address payable public feeWallet;

    constructor(address payable _feeWallet, address _swapRouter) {
        _balances[_msgSender()] = 1200000e18;
        feeWallet = _feeWallet;
        swapRouter = ISwapRouter(_swapRouter);
        // no fees and no staking when sending to swap contract
        feeWhitelist[_swapRouter] = true;
        noStakeOnTransferTo[_swapRouter] = true;
    }

    function setStakingPool(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
        feeWhitelist[_stakingAddress] = true;
        noStakeOnTransferFrom[_stakingAddress] = true;
        noStakeOnTransferTo[_stakingAddress] = true;
    }

    function name() public pure override returns (string memory) {
        return "Auto";
    }

    function symbol() public pure override returns (string memory) {
        return "AUTO";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 1200000e18;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool success)
    {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        // staking contract is exempt from approval system
        if (_msgSender() != stakingAddress) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        return true;
    }

    function setFeePercent(uint8 _feePercent) public onlyOwner {
        require(_feePercent < 100, "Percent must be less than 100.");
        feePercent = _feePercent;
    }

    function allowTransfersWithoutFees(address account, bool status)
        public
        onlyOwner
    {
        feeWhitelist[account] = status;
    }

    function allowTransferFromWithoutStake(address account, bool status)
        public
        onlyOwner
    {
        noStakeOnTransferFrom[account] = status;
    }

    function allowTransferToWithoutStake(address account, bool status)
        public
        onlyOwner
    {
        noStakeOnTransferTo[account] = status;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (!feeWhitelist[sender] && !feeWhitelist[recipient]) {
            uint256 totalFee = (amount * feePercent) / 100;

            // 1/3 of the fee goes to liquidity: 1/6 in tokens, 1/6 in Ether.
            uint256 liquidityTokenFee = totalFee / 6;
            uint256 remainingTokens = totalFee - liquidityTokenFee;

            _transferForFree(sender, address(this), totalFee);
            _swapTokensForETH(address(this), remainingTokens);
            _addLiquidity(feeWallet, liquidityTokenFee);
            Address.sendValue(feeWallet, address(this).balance);
            amount -= totalFee;
        }
        _transferForFree(sender, recipient, amount);

        if (noStakeOnTransferFrom[sender] || noStakeOnTransferTo[recipient])
            return;

        AutoStakingPool stakingContract = AutoStakingPool(stakingAddress);
        stakingContract.stake(recipient, amount);
    }

    function _transferForFree(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _swapTokensForETH(address to, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), amount);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, // amount in
            0, // amount out min
            path,
            to,
            block.timestamp // deadline
        );
    }

    function _addLiquidity(address to, uint256 amount) private {
        _approve(address(this), address(swapRouter), amount);

        swapRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            amount,
            0,
            0,
            to,
            block.timestamp
        );
    }

    receive() external payable {}
}