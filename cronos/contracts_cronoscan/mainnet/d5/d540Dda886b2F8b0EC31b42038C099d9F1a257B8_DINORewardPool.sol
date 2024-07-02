/**
 *Submitted for verification at cronoscan.com on 2022-06-06
*/

// SPDX-License-Identifier: MIT

    pragma solidity 0.6.12;

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
        function allowance(address owner, address spender)
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
        * @dev Returns the addition of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function tryAdd(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }

        /**
        * @dev Returns the substraction of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function trySub(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            if (b > a) return (false, 0);
            return (true, a - b);
        }

        /**
        * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function tryMul(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }

        /**
        * @dev Returns the division of two unsigned integers, with a division by zero flag.
        *
        * _Available since v3.4._
        */
        function tryDiv(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
        *
        * _Available since v3.4._
        */
        function tryMod(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }

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
            require(b <= a, "SafeMath: subtraction overflow");
            return a - b;
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
            if (a == 0) return 0;
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;
        }

        /**
        * @dev Returns the integer division of two unsigned integers, reverting on
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
            require(b > 0, "SafeMath: division by zero");
            return a / b;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * reverting when dividing by zero.
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
            require(b > 0, "SafeMath: modulo by zero");
            return a % b;
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        * overflow (when the result is negative).
        *
        * CAUTION: This function is deprecated because it requires allocating memory for the error
        * message unnecessarily. For custom revert reasons use {trySub}.
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
            return a - b;
        }

        /**
        * @dev Returns the integer division of two unsigned integers, reverting with custom message on
        * division by zero. The result is rounded towards zero.
        *
        * CAUTION: This function is deprecated because it requires allocating memory for the error
        * message unnecessarily. For custom revert reasons use {tryDiv}.
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
            return a / b;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * reverting with custom message when dividing by zero.
        *
        * CAUTION: This function is deprecated because it requires allocating memory for the error
        * message unnecessarily. For custom revert reasons use {tryMod}.
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
            require(b > 0, errorMessage);
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
        * tydollar of addresses:
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
            // solhint-disable-next-line no-inline-assembly
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
            require(
                address(this).balance >= amount,
                "Address: insufficient balance"
            );

            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{value: amount}("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
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
        function functionCall(address target, bytes memory data)
            internal
            returns (bytes memory)
        {
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
            return
                functionCallWithValue(
                    target,
                    data,
                    value,
                    "Address: low-level call with value failed"
                );
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
            require(
                address(this).balance >= value,
                "Address: insufficient balance for call"
            );
            require(isContract(target), "Address: call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.call{value: value}(
                data
            );
            return _verifyCallResult(success, returndata, errorMessage);
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
        * but performing a static call.
        *
        * _Available since v3.3._
        */
        function functionStaticCall(address target, bytes memory data)
            internal
            view
            returns (bytes memory)
        {
            return
                functionStaticCall(
                    target,
                    data,
                    "Address: low-level static call failed"
                );
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

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.staticcall(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
        * but performing a delegate call.
        *
        * _Available since v3.4._
        */
        function functionDelegateCall(address target, bytes memory data)
            internal
            returns (bytes memory)
        {
            return
                functionDelegateCall(
                    target,
                    data,
                    "Address: low-level delegate call failed"
                );
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

            // solhint-disable-next-line avoid-low-level-calls
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

    /**
    * @title SafeERC20
    * @dev Wrappers around ERC20 operations that throw on failure (when the token
    * contract returns false). Tokens that return no value (and instead revert or
    * throw on failure) are also supported, non-reverting calls are assumed to be
    * successful.
    * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
    * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
    */
    library SafeERC20 {
        using SafeMath for uint256;
        using Address for address;

        function safeTransfer(
            IERC20 token,
            address to,
            uint256 value
        ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        }

        function safeTransferFrom(
            IERC20 token,
            address from,
            address to,
            uint256 value
        ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
            );
        }

        /**
        * @dev Deprecated. This function has issues similar to the ones found in
        * {IERC20-approve}, and its usage is discouraged.
        *
        * Whenever possible, use {safeIncreaseAllowance} and
        * {safeDecreaseAllowance} instead.
        */
        function safeApprove(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            // safeApprove should only be called when setting an initial allowance,
            // or when resetting it to zero. To increase and decrease it, use
            // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
            // solhint-disable-next-line max-line-length
            require(
                (value == 0) || (token.allowance(address(this), spender) == 0),
                "SafeERC20: approve from non-zero to non-zero allowance"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, value)
            );
        }

        function safeIncreaseAllowance(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            uint256 newAllowance = token.allowance(address(this), spender).add(
                value
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }

        function safeDecreaseAllowance(
            IERC20 token,
            address spender,
            uint256 value
        ) internal {
            uint256 newAllowance = token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }

        /**
        * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
        * on the return value: the return value is optional (but if data is returned, it must not be false).
        * @param token The token targeted by the call.
        * @param data The call data (encoded using abi.encode or one of its variants).
        */
        function _callOptionalReturn(IERC20 token, bytes memory data) private {
            // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
            // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
            // the target address contains contract code and also asserts for success in the low-level call.

            bytes memory returndata = address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
            if (returndata.length > 0) {
                // Return data is optional
                // solhint-disable-next-line max-line-length
                require(
                    abi.decode(returndata, (bool)),
                    "SafeERC20: ERC20 operation did not succeed"
                );
            }
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

        constructor() internal {
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

    interface IRewardPool {
        function deposit(uint256 _pid, uint256 _amount) external;

        function withdraw(uint256 _pid, uint256 _amount) external;

        function withdrawAll(uint256 _pid) external;

        function harvestAllRewards() external;

        function pendingReward(uint256 _pid, address _user)
            external
            view
            returns (uint256);

        function pendingAllRewards(address _user) external view returns (uint256);

        function totalAllocPoint() external view returns (uint256);

        function poolLength() external view returns (uint256);

        function getPoolInfo(uint256 _pid)
            external
            view
            returns (address _lp, uint256 _allocPoint);

        function getRewardPerSecond() external view returns (uint256);

        function updateRewardRate(uint256 _newRate) external;
    }

    // Note that this pool has no minter key of DOLLAR (rewards).
    // Instead, the governance will call DOLLAR distributeReward method and send reward to this pool at the beginning.
    contract DINORewardPool is IRewardPool, ReentrancyGuard {
        using SafeMath for uint256;
        using SafeERC20 for IERC20;

        // governance
        address public operator;

        // Info of each user.
        struct UserInfo {
            uint256 amount; // How many LP tokens the user has provided.
            uint256 rewardDebt; // Reward debt. See explanation below.
        }

        // Info of each pool.
        struct PoolInfo {
            IERC20 token; // Address of LP token contract.
            uint256 allocPoint; // How many allocation points assigned to this pool. DOLLARs to distribute in the pool.
            uint256 lastRewardTime; // Last time that DOLLARs distribution occurred.
            uint256 accDOLLARPerShare; // Accumulated DOLLARs per share, times 1e18. See below.
            bool isStarted; // if lastRewardTime has passed
        }

        IERC20 public dollar;

        // Info of each pool.
        PoolInfo[] public poolInfo;

        // Info of each user that stakes LP tokens.
        mapping(uint256 => mapping(address => UserInfo)) public userInfo;

        // Total allocation points. Must be the sum of all allocation points in all pools.
        uint256 public totalAllocPoint_;

        // The time when DOLLAR mining starts.
        uint256 public poolStartTime;

        uint256[] public epochTotalRewards = [
            50000 ether,
            25000 ether,
            20000 ether,
            5000 ether
        ];

        // Time when each epoch ends.
        uint256[4] public epochEndTimes;

        // Reward per second for each of 4 weeks (last item is equal to 0 - for sanity).
        uint256[5] public epocDollarPerSecond;

        event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
        event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
        event EmergencyWithdraw(
            address indexed user,
            uint256 indexed pid,
            uint256 amount
        );
        event RewardPaid(address indexed user, uint256 amount);

        constructor(address _dollar, uint256 _poolStartTime) public {
            require(block.timestamp < _poolStartTime, "late");
            if (_dollar != address(0)) dollar = IERC20(_dollar);

            poolStartTime = _poolStartTime;

            epochEndTimes[0] = poolStartTime + 7 days; // 1st week
            epochEndTimes[1] = epochEndTimes[0] + 7 days; // 2nd week
            epochEndTimes[2] = epochEndTimes[1] + 7 days; // 3rd week
            epochEndTimes[3] = epochEndTimes[2] + 7 days; // 4th week

            epocDollarPerSecond[0] = epochTotalRewards[0].div(7 days);
            epocDollarPerSecond[1] = epochTotalRewards[1].div(7 days);
            epocDollarPerSecond[2] = epochTotalRewards[2].div(7 days);
            epocDollarPerSecond[3] = epochTotalRewards[3].div(7 days);

            epocDollarPerSecond[4] = 0;
            operator = msg.sender;
        }

        modifier onlyOperator() {
            require(
                operator == msg.sender,
                "DOLLARRewardPool: caller is not the operator"
            );
            _;
        }

        function totalAllocPoint() external view override returns (uint256) {
            return totalAllocPoint_;
        }

        function poolLength() external view override returns (uint256) {
            return poolInfo.length;
        }

        function getPoolInfo(uint256 _pid)
            external
            view
            override
            returns (address _lp, uint256 _allocPoint)
        {
            PoolInfo memory pool = poolInfo[_pid];
            _lp = address(pool.token);
            _allocPoint = pool.allocPoint;
        }

        function getRewardPerSecond() external view override returns (uint256) {
            for (uint8 epochId = 0; epochId <= 3; ++epochId) {
                if (block.timestamp <= epochEndTimes[epochId])
                    return epocDollarPerSecond[epochId];
            }
            return 0;
        }

        function checkPoolDuplicate(IERC20 _token) internal view {
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                require(
                    poolInfo[pid].token != _token,
                    "DOLLARRewardPool: existing pool?"
                );
            }
        }

        // Add a new token to the pool. Can only be called by the owner.
        function add(
            uint256 _allocPoint,
            IERC20 _token,
            uint256 _lastRewardTime
        ) public onlyOperator {
            checkPoolDuplicate(_token);
            massUpdatePools();
            if (block.timestamp < poolStartTime) {
                // chef is sleeping
                if (_lastRewardTime == 0) {
                    _lastRewardTime = poolStartTime;
                } else {
                    if (_lastRewardTime < poolStartTime) {
                        _lastRewardTime = poolStartTime;
                    }
                }
            } else {
                // chef is cooking
                if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                    _lastRewardTime = block.timestamp;
                }
            }
            bool _isStarted = (_lastRewardTime <= poolStartTime) ||
                (_lastRewardTime <= block.timestamp);
            poolInfo.push(
                PoolInfo({
                    token: _token,
                    allocPoint: _allocPoint,
                    lastRewardTime: _lastRewardTime,
                    accDOLLARPerShare: 0,
                    isStarted: _isStarted
                })
            );
            if (_isStarted) {
                totalAllocPoint_ = totalAllocPoint_.add(_allocPoint);
            }
        }

        // Update the given pool's DOLLAR allocation point. Can only be called by the owner.
        function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
            massUpdatePools();
            PoolInfo storage pool = poolInfo[_pid];
            if (pool.isStarted) {
                totalAllocPoint_ = totalAllocPoint_.sub(pool.allocPoint).add(
                    _allocPoint
                );
            }
            pool.allocPoint = _allocPoint;
        }

        // Return accumulate rewards over the given _fromTime to _toTime.
        function getGeneratedReward(uint256 _fromTime, uint256 _toTime)
            public
            view
            returns (uint256)
        {
            for (uint8 epochId = 4; epochId >= 1; --epochId) {
                if (_toTime >= epochEndTimes[epochId - 1]) {
                    if (_fromTime >= epochEndTimes[epochId - 1]) {
                        return
                            _toTime.sub(_fromTime).mul(epocDollarPerSecond[epochId]);
                    }
                    uint256 _generatedReward = _toTime
                        .sub(epochEndTimes[epochId - 1])
                        .mul(epocDollarPerSecond[epochId]);
                    if (epochId == 1) {
                        return
                            _generatedReward.add(
                                epochEndTimes[0].sub(_fromTime).mul(
                                    epocDollarPerSecond[0]
                                )
                            );
                    }
                    for (epochId = epochId - 1; epochId >= 1; --epochId) {
                        if (_fromTime >= epochEndTimes[epochId - 1]) {
                            return
                                _generatedReward.add(
                                    epochEndTimes[epochId].sub(_fromTime).mul(
                                        epocDollarPerSecond[epochId]
                                    )
                                );
                        }
                        _generatedReward = _generatedReward.add(
                            epochEndTimes[epochId]
                                .sub(epochEndTimes[epochId - 1])
                                .mul(epocDollarPerSecond[epochId])
                        );
                    }
                    return
                        _generatedReward.add(
                            epochEndTimes[0].sub(_fromTime).mul(
                                epocDollarPerSecond[0]
                            )
                        );
                }
            }
            return _toTime.sub(_fromTime).mul(epocDollarPerSecond[0]);
        }

        // View function to see pending DOLLARs on frontend.
        function pendingReward(uint256 _pid, address _user)
            public
            view
            override
            returns (uint256)
        {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accDOLLARPerShare = pool.accDOLLARPerShare;
            uint256 tokenSupply = pool.token.balanceOf(address(this));
            if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
                uint256 _generatedReward = getGeneratedReward(
                    pool.lastRewardTime,
                    block.timestamp
                );
                uint256 _dollarReward = _generatedReward.mul(pool.allocPoint).div(
                    totalAllocPoint_
                );
                accDOLLARPerShare = accDOLLARPerShare.add(
                    _dollarReward.mul(1e18).div(tokenSupply)
                );
            }
            return user.amount.mul(accDOLLARPerShare).div(1e18).sub(user.rewardDebt);
        }

        function pendingAllRewards(address _user)
            external
            view
            override
            returns (uint256 _total)
        {
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                _total = _total.add(pendingReward(pid, _user));
            }
        }

        // Update reward variables for all pools. Be careful of gas spending!
        function massUpdatePools() public {
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                updatePool(pid);
            }
        }

        // Update reward variables of the given pool to be up-to-date.
        function updatePool(uint256 _pid) public {
            PoolInfo storage pool = poolInfo[_pid];
            if (block.timestamp <= pool.lastRewardTime) {
                return;
            }
            uint256 tokenSupply = pool.token.balanceOf(address(this));
            if (tokenSupply == 0) {
                pool.lastRewardTime = block.timestamp;
                return;
            }
            if (!pool.isStarted) {
                pool.isStarted = true;
                totalAllocPoint_ = totalAllocPoint_.add(pool.allocPoint);
            }
            if (totalAllocPoint_ > 0) {
                uint256 _generatedReward = getGeneratedReward(
                    pool.lastRewardTime,
                    block.timestamp
                );
                uint256 _dollarReward = _generatedReward.mul(pool.allocPoint).div(
                    totalAllocPoint_
                );
                pool.accDOLLARPerShare = pool.accDOLLARPerShare.add(
                    _dollarReward.mul(1e18).div(tokenSupply)
                );
            }
            pool.lastRewardTime = block.timestamp;
        }

        // Deposit LP tokens.
        function deposit(uint256 _pid, uint256 _amount)
            external
            override
            nonReentrant
        {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][msg.sender];
            updatePool(_pid);
            if (user.amount > 0) {
                uint256 _pending = user
                    .amount
                    .mul(pool.accDOLLARPerShare)
                    .div(1e18)
                    .sub(user.rewardDebt);
                if (_pending > 0) {
                    safeDOLLARTransfer(msg.sender, _pending);
                    emit RewardPaid(msg.sender, _pending);
                }
            }
            if (_amount > 0) {
                pool.token.safeTransferFrom(msg.sender, address(this), _amount);
                user.amount = user.amount.add(_amount);
            }
            user.rewardDebt = user.amount.mul(pool.accDOLLARPerShare).div(1e18);
            emit Deposit(msg.sender, _pid, _amount);
        }

        function withdraw(uint256 _pid, uint256 _amount)
            external
            override
            nonReentrant
        {
            _withdraw(msg.sender, _pid, _amount);
        }

        // Withdraw LP tokens.
        function _withdraw(
            address _account,
            uint256 _pid,
            uint256 _amount
        ) internal {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_account];
            require(user.amount >= _amount, "withdraw: not good");
            updatePool(_pid);
            uint256 _pending = user.amount.mul(pool.accDOLLARPerShare).div(1e18).sub(
                user.rewardDebt
            );
            if (_pending > 0) {
                safeDOLLARTransfer(_account, _pending);
                emit RewardPaid(_account, _pending);
            }
            if (_amount > 0) {
                user.amount = user.amount.sub(_amount);
                pool.token.safeTransfer(_account, _amount);
            }
            user.rewardDebt = user.amount.mul(pool.accDOLLARPerShare).div(1e18);
            emit Withdraw(_account, _pid, _amount);
        }

        function withdrawAll(uint256 _pid) external override nonReentrant {
            _withdraw(msg.sender, _pid, userInfo[_pid][msg.sender].amount);
        }

        function harvestAllRewards() external override nonReentrant {
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                if (userInfo[pid][msg.sender].amount > 0) {
                    _withdraw(msg.sender, pid, 0);
                }
            }
        }

        // Withdraw without caring about rewards. EMERGENCY ONLY.
        function emergencyWithdraw(uint256 _pid) external {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][msg.sender];
            uint256 _amount = user.amount;
            user.amount = 0;
            user.rewardDebt = 0;
            pool.token.safeTransfer(msg.sender, _amount);
            emit EmergencyWithdraw(msg.sender, _pid, _amount);
        }

        // Safe dollar transfer function, just in case if rounding error causes pool to not have enough DOLLARs.
        function safeDOLLARTransfer(address _to, uint256 _amount) internal {
            uint256 _dollarBal = dollar.balanceOf(address(this));
            if (_dollarBal > 0) {
                if (_amount > _dollarBal) {
                    dollar.safeTransfer(_to, _dollarBal);
                } else {
                    dollar.safeTransfer(_to, _amount);
                }
            }
        }

        function updateRewardRate(uint256) external override {
            revert("Not support");
        }

        function setOperator(address _operator) external onlyOperator {
            operator = _operator;
        }

        function governanceRecoverUnsupported(
            IERC20 _token,
            uint256 amount,
            address to
        ) external onlyOperator {
            if (block.timestamp < epochEndTimes[1] + 30 days) {
                // do not allow to drain token if less than 30 days after farming
                require(_token != dollar, "!dollar");
                uint256 length = poolInfo.length;   
                for (uint256 pid = 0; pid < length; ++pid) {
                    PoolInfo storage pool = poolInfo[pid];
                    require(_token != pool.token, "!pool.token");
                }
            }
            _token.safeTransfer(to, amount);
        }
    }