/**
 *Submitted for verification at cronoscan.com on 2022-05-29
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

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            "ContractGuard: one block, one function"
        );
        require(
            !checkSameSenderReentranted(),
            "ContractGuard: one block, one function"
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public share;

    address public reserveFund;
    uint256 public withdrawFee;
    uint256 public stakeFee;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _setStakeFee(uint256 _stakeFee) internal {
        require(_stakeFee <= 5, "Max stake fee is 5%");
        stakeFee = _stakeFee;
    }

    function _setWithdrawFee(uint256 _withdrawFee) internal {
        require(_withdrawFee <= 20, "Max withdraw fee is 20%");
        withdrawFee = _withdrawFee;
    }

    function _setReserveFund(address _reserveFund) internal {
        require(
            _reserveFund != address(0),
            "reserveFund address cannot be 0 address"
        );
        reserveFund = _reserveFund;
    }

    function stake(uint256 amount) public virtual {
        share.safeTransferFrom(msg.sender, address(this), amount);
        if (stakeFee > 0) {
            uint256 feeAmount = amount.mul(stakeFee).div(100);
            share.safeTransfer(reserveFund, feeAmount);
            amount = amount.sub(feeAmount);
        }
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) public virtual {
        uint256 memberShare = _balances[msg.sender];
        require(
            memberShare >= amount,
            "Boardroom: withdraw request greater than staked amount"
        );
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = memberShare.sub(amount);
        if (withdrawFee > 0) {
            uint256 feeAmount = amount.mul(withdrawFee).div(100);
            share.safeTransfer(reserveFund, feeAmount);
            amount = amount.sub(feeAmount);
        }
        share.safeTransfer(msg.sender, amount);
    }
}

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function transferOwnership(address newOwner_) external;

    function distributeReward(address _launcherAddress) external;

    function totalBurned() external view returns (uint256);
}

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);

    function getPegPrice() external view returns (int256);

    function getPegPriceUpdated() external view returns (int256);
}

interface ITreasury is IEpoch {
    function getMainTokenPrice() external view returns (uint256);

    function getMainTokenUpdatedPrice() external view returns (uint256);

    function getPegTokenPrice(address _token) external view returns (uint256);

    function getPegTokenUpdatedPrice(address _token)
    external
    view
    returns (uint256);

    function getMainTokenLockedBalance() external view returns (uint256);

    function getMainTokenCirculatingSupply() external view returns (uint256);

    function getNextExpansionRate() external view returns (uint256);

    function getNextExpansionAmount() external view returns (uint256);

    function getPegTokenExpansionRate(address) external view returns (uint256);

    function getPegTokenExpansionAmount(address)
    external
    view
    returns (uint256);

    function previousEpochMainTokenPrice() external view returns (uint256);

    function boardroom() external view returns (address);

    function boardroomSharedPercent() external view returns (uint256);

    function daoFund() external view returns (address);

    function daoFundSharedPercent() external view returns (uint256);

    function marketingFund() external view returns (address);

    function marketingFundSharedPercent() external view returns (uint256);

    function insuranceFund() external view returns (address);

    function insuranceFundSharedPercent() external view returns (uint256);

    function getBondDiscountRate() external view returns (uint256);

    function getBondPremiumRate() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

interface IPegBoardroom {
    function earned(address _token, address _member)
    external
    view
    returns (uint256);

    function updateReward(address _token, address _member) external;

    function claimReward(address _token, address _member) external;

    function sacrificeReward(address _token, address _member) external;

    function allocateSeignioragePegToken(address _token, uint256 _amount)
    external;
}

// support multi-pegs
contract OneBoardroom is ShareWrapper, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct Memberseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
    }

    struct BoardroomSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    IERC20 public maintoken;
    IERC20 public pegtoken;
    IERC20 public paytoken; // second collateral
    ITreasury public treasury;
    address public insuranceFund;
    address public mainTokenracle;

    //    mapping(address => Memberseat) public members;
    //    BoardroomSnapshot[] public boardroomHistory;

    mapping(address => mapping(address => Memberseat)) public members; // pegToken => _member => Memberseat
    mapping(address => uint256) public timers; // start deposit time for each members
    mapping(address => BoardroomSnapshot[]) public boardroomHistory; // pegToken => BoardroomSnapshot history


    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;

    uint256 public minCollateralPercent;
    uint256 public maxCollateralPercent;
    uint256 public paytokenCollateralDiscountPercent;
    uint256 public maintokenTokenSupplyTarget;
    address[] public pegTokens;
    bool isSacrificeReward;
    mapping(address => address) public pegOriginalTokenOracle;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed token,
        address indexed user,
        uint256 reward
    );
    event RewardAdded(
        address indexed token,
        address indexed user,
        uint256 reward
    );
    event RewardSacrificed(
        address indexed token,
        address indexed user,
        uint256 reward
    );

    /* ========== Modifiers =============== */

    modifier onlyOperator() {
        require(
            operator == msg.sender,
            "Boardroom: caller is not the operator"
        );
        _;
    }

    modifier onlyTreasury() {
        require(
            address(treasury) == msg.sender || operator == msg.sender,
            "Boardroom: caller is not the treasury"
        );
        _;
    }

    modifier memberExists() {
        require(
            balanceOf(msg.sender) > 0,
            "Boardroom: The member does not exist"
        );
        _;
    }

    modifier updateReward(address _member) {
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            address _token = pegTokens[_pti];
            Memberseat memory seat = members[_token][_member];
            seat.rewardEarned = earned(_token, _member);
            seat.lastSnapshotIndex = latestSnapshotIndex(_token);
            members[_token][_member] = seat;
        }
        _;
    }

    modifier notInitialized() {
        require(!initialized, "Boardroom: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20 _maintoken,
        IERC20 _share,
        IERC20 _pegtoken,
        IERC20 _paytoken,
        ITreasury _treasury,
        address _insuranceFund
    ) public notInitialized {
        maintoken = _maintoken;
        share = _share;

        pegtoken = _pegtoken;
        paytoken = _paytoken;
        treasury = _treasury;
        insuranceFund = _insuranceFund;

        withdrawLockupEpochs = 6; // Lock for 9 epochs (72h) before release withdraw
        rewardLockupEpochs = 3;

        minCollateralPercent = 0; // 0%
        maxCollateralPercent = 0; // 0%

        withdrawFee = 1;
        withdrawFee = 1;

        paytokenCollateralDiscountPercent = 0; // 20% discount if pay by PAYTOKEN
        maintokenTokenSupplyTarget = 405175  ether;
        isSacrificeReward = false;
        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setPAYTOKEN(IERC20 _paytoken) external onlyOperator {
        paytoken = _paytoken;
    }

    function setTreasury(ITreasury _treasury) external onlyOperator {
        require(address(_treasury) != address(0), "zero");
        treasury = _treasury;
    }

    function setInsuranceFund(address _insuranceFund) external onlyOperator {
        require(_insuranceFund != address(0), "zero");
        insuranceFund = _insuranceFund;
    }

    function setLockUp(uint256 _withdrawLockupEpochs , uint256 _rewardLockupEpochs) external onlyOperator {
        require(
            _withdrawLockupEpochs <= 42,
            "_withdrawLockupEpochs: out of range"
        ); // <= 2 week
        require(
            rewardLockupEpochs <= 21,
            "rewardLockupEpochs: out of range"
        ); // <= 1 week
        require(
            rewardLockupEpochs <  _withdrawLockupEpochs,
            "rewardLockupEpochs: out of range"
        ); // <= 1 week
        rewardLockupEpochs = _rewardLockupEpochs;
        withdrawLockupEpochs = _withdrawLockupEpochs;
    }

    function addPegToken(address _token) external onlyOperator {
        require(IERC20(_token).totalSupply() > 0, "Boardroom: invalid token");
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            require(pegTokens[_pti] != _token, "Boardroom: existing token");
        }
        require(
            boardroomHistory[_token].length == 0,
            "Boardroom: boardroomHistory exists"
        );
        BoardroomSnapshot memory genesisSnapshot = BoardroomSnapshot({
        time: block.number,
        rewardReceived: 0,
        rewardPerShare: 0
        });
        boardroomHistory[_token].push(genesisSnapshot);
        pegTokens.push(_token);
    }

    function setPegTokenConfig(address _token, address _oracle)
    external
    onlyOperator
    {
        pegOriginalTokenOracle[_token] = _oracle;
    }

    function setReserveFund(address _reserveFund) external onlyOperator {
        _setReserveFund(_reserveFund);
    }

    function setStakeFee(uint256 _stakeFee) external onlyOperator {
        _setStakeFee(_stakeFee);
    }

    function setMainTokenracle(address _mainTokenracle) external onlyOperator {
        mainTokenracle = _mainTokenracle;
    }

    function setMinCollateralPercent(uint256 _minCollateralPercent)
    external
    onlyOperator
    {
        require(_minCollateralPercent <= 3500, "too high"); // <= 35%
        minCollateralPercent = _minCollateralPercent;
    }

    function setMaxCollateralPercent(uint256 _maxCollateralPercent)
    external
    onlyOperator
    {
        require(_maxCollateralPercent >= 6500, "too low"); // >= 65%
        maxCollateralPercent = _maxCollateralPercent;
    }

    function setPAYTOKENCollateralDiscountPercent(
        uint256 _paytokenCollateralDiscountPercent
    ) external onlyOperator {
        require(_paytokenCollateralDiscountPercent <= 5000, "too high"); // <= 50%
        paytokenCollateralDiscountPercent = _paytokenCollateralDiscountPercent;
    }

    function setMainTokenTokenSupplyTarget(uint256 _maintokenTokenSupplyTarget)
    external
    onlyOperator
    {
        require(_maintokenTokenSupplyTarget >= 100000000 ether, "too low"); // >= 100 million MAINTOKEN
        maintokenTokenSupplyTarget = _maintokenTokenSupplyTarget;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOperator {
        _setWithdrawFee(_withdrawFee);
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex(address _token) public view returns (uint256) {
        return boardroomHistory[_token].length.sub(1);
    }

    function getLatestSnapshot(address _token)
    internal
    view
    returns (BoardroomSnapshot memory)
    {
        return boardroomHistory[_token][latestSnapshotIndex(_token)];
    }

    function getLastSnapshotIndexOf(address token, address member)
    public
    view
    returns (uint256)
    {
        return members[token][member].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address token, address member)
    internal
    view
    returns (BoardroomSnapshot memory)
    {
        return boardroomHistory[token][getLastSnapshotIndexOf(token, member)];
    }

    function canClaimReward(address member) external view  returns (bool) {
        return timers[member].add(rewardLockupEpochs) <= treasury.epoch();
        // return true;
        // ITreasury _treasury = ITreasury(treasury);
        // return _treasury.previousEpochMainTokenPrice() >= 1e18 && _treasury.getNextExpansionRate() > 0; // current epoch and next epoch are both expansion
    }

    function getCollateralPercent()
    public
    view
    returns (uint256 _collateralPercent)
    {
        uint256 _maintokenSupply = maintoken.totalSupply();
        uint256 _maintokenTokenSupplyTarget = maintokenTokenSupplyTarget;
        if (_maintokenSupply >= _maintokenTokenSupplyTarget) {
            _collateralPercent = maxCollateralPercent;
        } else {
            _collateralPercent = _maintokenSupply.mul(10000).div(
                _maintokenTokenSupplyTarget
            );
            if (_collateralPercent > maxCollateralPercent) {
                _collateralPercent = maxCollateralPercent;
            } else if (_collateralPercent < minCollateralPercent) {
                _collateralPercent = minCollateralPercent;
            }
        }
    }

    function canWithdraw(address member) external view returns (bool) {
        return timers[member].add(withdrawLockupEpochs) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getPegTokenPrice(address _token) external view returns (uint256) {
        return treasury.getPegTokenPrice(_token);
    }

    function getPegTokenUpdatedPrice(address _token)
    external
    view
    returns (uint256)
    {
        return treasury.getPegTokenUpdatedPrice(_token);
    }

    function getMainTokenverPegTokenPrice() public view returns (uint256) {
        return
        (mainTokenracle == address(0))
        ? 1e18
        : uint256(IEpoch(mainTokenracle).getPegPriceUpdated());
    }

    function getPegOriginalTokenOverPegTokenPrice(address _token)
    public
    view
    returns (uint256)
    {
        address _oracle = pegOriginalTokenOracle[_token];
        return
        (_oracle == address(0))
        ? 1e18
        : uint256(IEpoch(_oracle).getPegPriceUpdated());
    }

    // =========== Member getters

    function rewardPerShare(address _token) public view returns (uint256) {
        return getLatestSnapshot(_token).rewardPerShare;
    }

    function earned(address _token, address _member)
    public
    view
    returns (uint256)
    {
        uint256 latestRPS = getLatestSnapshot(_token).rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(_token, _member).rewardPerShare;

        return
        balanceOf(_member).mul(latestRPS.sub(storedRPS)).div(1e18).add(
            members[_token][_member].rewardEarned
        );
    }

    function numOfPegTokens() public view returns (uint256) {
        return pegTokens.length;
    }

    function earnedAllPegTokens(address _member)
    external
    view
    returns (
        uint256 _numOfPegTokens,
        address[] memory _pegTokenAddresses,
        uint256[] memory _earnedPegTokens
    )
    {
        _numOfPegTokens = numOfPegTokens();
        _pegTokenAddresses = new address[](_numOfPegTokens);
        _earnedPegTokens = new uint256[](_numOfPegTokens);
        for (uint256 i = 0; i < _numOfPegTokens; i++) {
            _pegTokenAddresses[i] = pegTokens[i];
            _earnedPegTokens[i] = earned(_pegTokenAddresses[i], _member);
        }
    }

    function getCollateralForClaimAllPegTokens(address _token, address _member)
    public
    view
    returns (uint256)
    {
        uint256 _earned = earned(_token, _member);
        uint256 _price = getPegOriginalTokenOverPegTokenPrice(_token);
        uint256 _collateralPercent = getCollateralPercent();
        return _earned.mul(_price).mul(_collateralPercent).div(1e22); // 1e18 * 10000
    }

    function getCollateralForClaimAllPegTokens(address _member)
    public
    view
    returns (
        uint256 _numOfPegTokens,
        address[] memory _pegTokenAddresses,
        uint256[] memory _earnedPegTokens,
        uint256[] memory _collateralForPegTokens,
        uint256 _totalCollateral,
        uint256 _totalPAYTOKENCollateral
    )
    {
        _numOfPegTokens = numOfPegTokens();
        _pegTokenAddresses = new address[](_numOfPegTokens);
        _earnedPegTokens = new uint256[](_numOfPegTokens);
        _collateralForPegTokens = new uint256[](_numOfPegTokens);
        uint256 _collateralPercent = getCollateralPercent();
        for (uint256 i = 0; i < _numOfPegTokens; i++) {
            address _token = pegTokens[i];
            uint256 _earned = earned(_token, _member);
            _pegTokenAddresses[i] = _token;
            _earnedPegTokens[i] = _earned;
            uint256 _price = getPegOriginalTokenOverPegTokenPrice(_token);
            uint256 _collateral = _earned
            .mul(_price)
            .mul(_collateralPercent)
            .div(1e22);
            _collateralForPegTokens[i] = _collateral;
            _totalCollateral = _totalCollateral.add(_collateral);
        }
        _totalPAYTOKENCollateral = _totalCollateral.mul(1e18).div(
            getMainTokenverPegTokenPrice()
        );
        _totalPAYTOKENCollateral = _totalPAYTOKENCollateral.sub(
            _totalPAYTOKENCollateral.mul(paytokenCollateralDiscountPercent).div(10000)
        ); // sub discount
    }

    function getTotalCollateralForClaimAllPegTokens(address _member)
    public
    view
    returns (uint256 _totalCollateral)
    {
        uint256 _numOfPegTokens = pegTokens.length;
        for (uint256 i = 0; i < _numOfPegTokens; i++) {
            address _token = pegTokens[i];
            uint256 _earned = earned(_token, _member);
            uint256 _price = getPegOriginalTokenOverPegTokenPrice(_token);
            uint256 _collateral = _earned.mul(_price).div(1e18);
            _totalCollateral = _totalCollateral.add(_collateral);
        }
        uint256 _collateralPercent = getCollateralPercent();
        _totalCollateral = _totalCollateral.mul(_collateralPercent).div(10000);
    }

    function getTotalPAYTOKENCollateralForClaimAllPegTokens(address _member)
    public
    view
    returns (uint256 _totalPAYTOKENCollateral)
    {
        uint256 _totalCollateral = getTotalCollateralForClaimAllPegTokens(
            _member
        );
        _totalPAYTOKENCollateral = _totalCollateral.mul(1e18).div(
            getMainTokenverPegTokenPrice()
        );
        _totalPAYTOKENCollateral = _totalPAYTOKENCollateral.sub(
            _totalPAYTOKENCollateral.mul(paytokenCollateralDiscountPercent).div(10000)
        ); // sub discount
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
    public
    override
    onlyOneBlock
    updateReward(msg.sender)
    {
        require(amount > 0, "Boardroom: Cannot stake 0");
        super.stake(amount);
        timers[msg.sender] = treasury.epoch();
        // reset timer
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
    public
    override
    onlyOneBlock
    memberExists
    updateReward(msg.sender)
    {
        require(amount > 0, "Boardroom: Cannot withdraw 0");
        require(
            timers[msg.sender].add(withdrawLockupEpochs) <= treasury.epoch(),
            "Boardroom: still in withdraw lockup"
        );
        if (isSacrificeReward == true ) _sacrificeReward();
        else _claimReward(true);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function _sacrificeReward() internal updateReward(msg.sender) {
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            address _token = pegTokens[_pti];
            uint256 reward = members[_token][msg.sender].rewardEarned;
            IBasisAsset(_token).burn(reward);
            members[_token][msg.sender].rewardEarned = 0;
            emit RewardSacrificed(_token, msg.sender, reward);
        }
    }

    function claimReward(bool _usePAYTOKENCollateral) external onlyOneBlock {
        require( timers[msg.sender].add(rewardLockupEpochs) <= treasury.epoch(), "!claim");
        _claimReward(_usePAYTOKENCollateral);
    }

    function _claimReward(bool _usePAYTOKENCollateral)
    internal
    updateReward(msg.sender)
    {
        uint256 _reward = members[address(maintoken)][msg.sender].rewardEarned;
        if (_reward > 0) {
            if (_usePAYTOKENCollateral) {
                paytoken.safeTransferFrom(
                    msg.sender,
                    insuranceFund,
                    getTotalPAYTOKENCollateralForClaimAllPegTokens(msg.sender)
                );
            } else {
                pegtoken.safeTransferFrom(
                    msg.sender,
                    insuranceFund,
                    getTotalCollateralForClaimAllPegTokens(msg.sender)
                );
            }
        }
        timers[msg.sender] = treasury.epoch(); // reset timer
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            address _token = pegTokens[_pti];
            _reward = members[_token][msg.sender].rewardEarned;
            IERC20(_token).safeTransfer(msg.sender, _reward);
            members[_token][msg.sender].rewardEarned = 0;
            emit RewardPaid(_token, msg.sender, _reward);
        }
    }

    function allocateSeigniorage(address _token, uint256 _amount)
    external
    onlyTreasury
    {
        require(_amount > 0, "Boardroom: Cannot allocate 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _totalSupply = totalSupply();
        require(
            _totalSupply > 0,
            "Boardroom: Cannot allocate when totalSupply is 0"
        );
        require(
            boardroomHistory[_token].length > 0,
            "Boardroom: Cannot allocate when boardroomHistory is empty"
        );

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot(_token).rewardPerShare;
        uint256 nextRPS = prevRPS.add(_amount.mul(1e18).div(_totalSupply));

        BoardroomSnapshot memory newSnapshot = BoardroomSnapshot({
        time: block.number,
        rewardReceived: _amount,
        rewardPerShare: nextRPS
        });
        boardroomHistory[_token].push(newSnapshot);

        emit RewardAdded(_token, msg.sender, _amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(maintoken), "maintoken");
        require(address(_token) != address(share), "share");
        _token.safeTransfer(_to, _amount);
    }
}