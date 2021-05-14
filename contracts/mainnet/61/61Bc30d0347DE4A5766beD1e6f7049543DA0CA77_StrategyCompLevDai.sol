/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IController {
    function ADMIN_ROLE() external view returns (bytes32);

    function HARVESTER_ROLE() external view returns (bytes32);

    function admin() external view returns (address);

    function treasury() external view returns (address);

    function setAdmin(address _admin) external;

    function setTreasury(address _treasury) external;

    function grantRole(bytes32 _role, address _addr) external;

    function revokeRole(bytes32 _role, address _addr) external;

    /*
    @notice Set strategy for vault
    @param _vault Address of vault
    @param _strategy Address of strategy
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external;

    // calls to strategy
    /*
    @notice Invest token in vault into strategy
    @param _vault Address of vault
    */
    function invest(address _vault) external;

    function harvest(address _strategy) external;

    function skim(address _strategy) external;

    /*
    @notice Withdraw from strategy to vault
    @param _strategy Address of strategy
    @param _amount Amount of underlying token to withdraw
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    ) external;

    /*
    @notice Withdraw all from strategy to vault
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdrawAll(address _strategy, uint _min) external;

    /*
    @notice Exit from strategy
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function exit(address _strategy, uint _min) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        uint c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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

        uint size;
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
            functionStaticCall(target, data, "Address: low-level static call failed");
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
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
        uint value
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
        uint value
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
        uint value
    ) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        uint newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
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

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
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

// File: contracts/protocol/IStrategyERC20_V3.sol

/*
version 1.3.0

Changes listed here do not affect interaction with other contracts (Vault and Controller)
- remove functions that are not called by other contracts (vaults and controller)
*/

interface IStrategyERC20_V3 {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function vault() external view returns (address);

    /*
    @notice Returns address of underlying token (ETH or ERC20)
    @dev Return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH strategy
    */
    function underlying() external view returns (address);

    /*
    @notice Returns total amount of underlying token transferred from vault
    */
    function totalDebt() external view returns (uint);

    /*
    @notice Returns amount of underlying token locked in this contract
    @dev Output may vary depending on price of liquidity provider token
         where the underlying token is invested
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Deposit `amount` underlying token
    @param amount Amount of underlying token to deposit
    */
    function deposit(uint _amount) external;

    /*
    @notice Withdraw `_amount` underlying token
    @param amount Amount of underlying token to withdraw
    */
    function withdraw(uint _amount) external;

    /*
    @notice Withdraw all underlying token from strategy
    */
    function withdrawAll() external;

    /*
    @notice Sell any staking rewards for underlying
    */
    function harvest() external;

    /*
    @notice Increase total debt if totalAssets > totalDebt
    */
    function skim() external;

    /*
    @notice Exit from strategy, transfer all underlying tokens back to vault
    */
    function exit() external;

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to underlying token
    */
    function sweep(address _token) external;
}

// File: contracts/StrategyERC20_V3.sol

/*
Changes
- remove functions related to slippage and delta
- add keeper
- remove _increaseDebt
- remove _decreaseDebt
*/

// used inside harvest

abstract contract StrategyERC20_V3 is IStrategyERC20_V3 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public override admin;
    address public nextAdmin;
    address public override controller;
    address public immutable override vault;
    address public immutable override underlying;
    // some functions specific to strategy cannot be called by controller
    // so we introduce a new role
    address public keeper;

    // total amount of underlying transferred from vault
    uint public override totalDebt;

    // performance fee sent to treasury when harvest() generates profit
    uint public performanceFee = 500;
    uint private constant PERFORMANCE_FEE_CAP = 2000; // upper limit to performance fee
    uint internal constant PERFORMANCE_FEE_MAX = 10000;

    // Force exit, in case normal exit fails
    bool public forceExit;

    constructor(
        address _controller,
        address _vault,
        address _underlying,
        address _keeper
    ) public {
        require(_controller != address(0), "controller = zero address");
        require(_vault != address(0), "vault = zero address");
        require(_underlying != address(0), "underlying = zero address");
        require(_keeper != address(0), "keeper = zero address");

        admin = msg.sender;
        controller = _controller;
        vault = _vault;
        underlying = _underlying;
        keeper = _keeper;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == admin ||
                msg.sender == controller ||
                msg.sender == vault ||
                msg.sender == keeper,
            "!authorized"
        );
        _;
    }

    function setNextAdmin(address _nextAdmin) external onlyAdmin {
        require(_nextAdmin != admin, "next admin = current");
        // allow next admin = zero address (cancel next admin)
        nextAdmin = _nextAdmin;
    }

    function acceptAdmin() external {
        require(msg.sender == nextAdmin, "!next admin");
        admin = msg.sender;
        nextAdmin = address(0);
    }

    function setController(address _controller) external onlyAdmin {
        require(_controller != address(0), "controller = zero address");
        controller = _controller;
    }

    function setKeeper(address _keeper) external onlyAdmin {
        require(_keeper != address(0), "keeper = zero address");
        keeper = _keeper;
    }

    function setPerformanceFee(uint _fee) external onlyAdmin {
        require(_fee <= PERFORMANCE_FEE_CAP, "performance fee > cap");
        performanceFee = _fee;
    }

    function setForceExit(bool _forceExit) external onlyAdmin {
        forceExit = _forceExit;
    }

    function totalAssets() external view virtual override returns (uint);

    function deposit(uint) external virtual override;

    function withdraw(uint) external virtual override;

    function withdrawAll() external virtual override;

    function harvest() external virtual override;

    function skim() external virtual override;

    function exit() external virtual override;

    function sweep(address) external virtual override;
}

// File: contracts/interfaces/uniswap/Uniswap.sol

interface Uniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// File: contracts/interfaces/compound/CErc20.sol

interface CErc20 {
    function mint(uint mintAmount) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function redeem(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );
}

// File: contracts/interfaces/compound/Comptroller.sol

interface Comptroller {
    function markets(address cToken)
        external
        view
        returns (
            bool,
            uint,
            bool
        );

    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, address[] calldata cTokens) external;
}

// File: contracts/strategies/StrategyCompLev.sol

/*
APY estimate

c = collateral ratio
i_s = supply interest rate (APY)
i_b = borrow interest rate (APY)
c_s = supply COMP reward (APY)
c_b = borrow COMP reward (APY)

leverage APY = 1 / (1 - c) * (i_s + c_s - c * (i_b - c_b))

plugging some numbers
31.08 = 4 * (7.01 + 4 - 0.75 * (9.08 - 4.76))
*/

/*
State transitions and valid transactions

### State ###
buff = buffer
s = supplied
b = borrowed

### Transactions ###
dl = deleverage
l = leverage
w = withdraw
d = deposit
s(x) = set butter to x

### State Transitions ###

                             s(max)
(buf = max, s > 0, b > 0) <--------- (buf = min, s > 0, b > 0)
          |                               |        ^
          | dl, w                         | dl, w  | l, d
          |                               |        |
          V                               V        | 
(buf = max, s > 0, b = 0) ---------> (buf = min, s > 0, b = 0)
                             s(min)
*/

contract StrategyCompLev is StrategyERC20_V3 {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event Harvest(uint profit);
    event Skim(uint profit);

    // Uniswap //
    address private constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Compound //
    address private constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address private constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address private immutable cToken;

    // buffer to stay below market collateral ratio, scaled up by 1e18
    uint public buffer = 0.04 * 1e18;

    constructor(
        address _controller,
        address _vault,
        address _underlying,
        address _cToken,
        address _keeper
    ) public StrategyERC20_V3(_controller, _vault, _underlying, _keeper) {
        require(_cToken != address(0), "cToken = zero address");
        cToken = _cToken;

        IERC20(_underlying).safeApprove(_cToken, type(uint).max);

        // These tokens are never held by this contract
        // so the risk of them getting stolen is minimal
        IERC20(COMP).safeApprove(UNISWAP, type(uint).max);
    }

    function _increaseDebt(uint _amount) private returns (uint) {
        uint balBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransferFrom(vault, address(this), _amount);
        uint balAfter = IERC20(underlying).balanceOf(address(this));

        uint diff = balAfter.sub(balBefore);
        totalDebt = totalDebt.add(diff);

        return diff;
    }

    function _decreaseDebt(uint _amount) private returns (uint) {
        uint balBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, _amount);
        uint balAfter = IERC20(underlying).balanceOf(address(this));

        uint diff = balBefore.sub(balAfter);
        if (diff >= totalDebt) {
            totalDebt = 0;
        } else {
            totalDebt -= diff;
        }

        return diff;
    }

    function _totalAssets() private view returns (uint) {
        // WARNING: This returns balance last time someone transacted with cToken
        (uint error, uint cTokenBal, uint borrowed, uint exchangeRate) =
            CErc20(cToken).getAccountSnapshot(address(this));

        if (error > 0) {
            // something is wrong, return 0
            return 0;
        }

        uint supplied = cTokenBal.mul(exchangeRate) / 1e18;
        if (supplied < borrowed) {
            // something is wrong, return 0
            return 0;
        }

        uint bal = IERC20(underlying).balanceOf(address(this));
        // supplied >= borrowed
        return bal.add(supplied - borrowed);
    }

    /*
    @notice Returns amount of underlying tokens locked in this contract
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    /*
    @dev buffer = 0 means safe collateral ratio = market collateral ratio
         buffer = 1e18 means safe collateral ratio = 0
    */
    function setBuffer(uint _buffer) external onlyAuthorized {
        require(_buffer > 0 && _buffer <= 1e18, "buffer");
        buffer = _buffer;
    }

    function _getMarketCollateralRatio() private view returns (uint) {
        /*
        This can be changed by Compound Governance, with a minimum waiting
        period of five days
        */
        (, uint col, ) = Comptroller(COMPTROLLER).markets(cToken);
        return col;
    }

    function _getSafeCollateralRatio(uint _marketCol) private view returns (uint) {
        if (_marketCol > buffer) {
            return _marketCol - buffer;
        }
        return 0;
    }

    // Not view function
    function _getSupplied() private returns (uint) {
        return CErc20(cToken).balanceOfUnderlying(address(this));
    }

    // Not view function
    function _getBorrowed() private returns (uint) {
        return CErc20(cToken).borrowBalanceCurrent(address(this));
    }

    // Not view function. Call using static call from web3
    function getLivePosition()
        external
        returns (
            uint supplied,
            uint borrowed,
            uint marketCol,
            uint safeCol
        )
    {
        supplied = _getSupplied();
        borrowed = _getBorrowed();
        marketCol = _getMarketCollateralRatio();
        safeCol = _getSafeCollateralRatio(marketCol);
    }

    // @dev This returns balance last time someone transacted with cToken
    function getCachedPosition()
        external
        view
        returns (
            uint supplied,
            uint borrowed,
            uint marketCol,
            uint safeCol
        )
    {
        // ignore first output, which is error code
        (, uint cTokenBal, uint _borrowed, uint exchangeRate) =
            CErc20(cToken).getAccountSnapshot(address(this));

        supplied = cTokenBal.mul(exchangeRate) / 1e18;
        borrowed = _borrowed;
        marketCol = _getMarketCollateralRatio();
        safeCol = _getSafeCollateralRatio(marketCol);
    }

    // @dev This modifier checks collateral ratio after leverage or deleverage
    modifier checkCollateralRatio() {
        _;
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);

        // borrowed / supplied <= safe col
        // supplied can = 0 so we check borrowed <= supplied * safe col
        // max borrow
        uint max = supplied.mul(safeCol) / 1e18;
        require(borrowed <= max, "borrowed > max");
    }

    // @dev In case infinite approval is reduced so that strategy cannot function
    function approve(uint _amount) external onlyAdmin {
        IERC20(underlying).safeApprove(cToken, _amount);
    }

    function _supply(uint _amount) private {
        require(CErc20(cToken).mint(_amount) == 0, "mint");
    }

    // @dev Execute manual recovery by admin
    // @dev `_amount` must be >= balance of underlying
    function supply(uint _amount) external onlyAdmin {
        _supply(_amount);
    }

    function _borrow(uint _amount) private {
        require(CErc20(cToken).borrow(_amount) == 0, "borrow");
    }

    // @dev Execute manual recovery by admin
    function borrow(uint _amount) external onlyAdmin {
        _borrow(_amount);
    }

    function _repay(uint _amount) private {
        require(CErc20(cToken).repayBorrow(_amount) == 0, "repay");
    }

    // @dev Execute manual recovery by admin
    // @dev `_amount` must be >= balance of underlying
    function repay(uint _amount) external onlyAdmin {
        _repay(_amount);
    }

    function _redeem(uint _amount) private {
        require(CErc20(cToken).redeemUnderlying(_amount) == 0, "redeem");
    }

    // @dev Execute manual recovery by admin
    function redeem(uint _amount) external onlyAdmin {
        _redeem(_amount);
    }

    function _getMaxLeverageRatio(uint _col) private pure returns (uint) {
        /*
        c = collateral ratio

        geometric series converges to
            1 / (1 - c)
        */
        // multiplied by 1e18
        return uint(1e36).div(uint(1e18).sub(_col));
    }

    function _getBorrowAmount(
        uint _supplied,
        uint _borrowed,
        uint _col
    ) private pure returns (uint) {
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        x = amount to borrow

        (b + x) / s <= c
        becomes
        x <= sc - b
        */
        // max borrow
        uint max = _supplied.mul(_col) / 1e18;
        if (_borrowed >= max) {
            return 0;
        }
        return max - _borrowed;
    }

    /*
    Find total supply S_n after n iterations starting with
    S_0 supplied and B_0 borrowed

    c = collateral ratio
    S_i = supplied after i iterations
    B_i = borrowed after i iterations

    S_0 = current supplied
    B_0 = current borrowed

    borrowed and supplied after n iterations
        B_n = cS_(n-1)
        S_n = S_(n-1) + (cS_(n-1) - B_(n-1))

    you can prove using algebra and induction that
        B_n / S_n <= c

        S_n - S_(n-1) = c^(n-1) * (cS_0 - B_0)

        S_n = S_0 + sum (c^i * (cS_0 - B_0)), 0 <= i <= n - 1
            = S_0 + (1 - c^n) / (1 - c)

        S_n <= S_0 + (cS_0 - B_0) / (1 - c)
    */
    function _leverage(uint _targetSupply) private checkCollateralRatio {
        // buffer = 1e18 means safe collateral ratio = 0
        if (buffer >= 1e18) {
            return;
        }

        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint unleveraged = supplied.sub(borrowed); // supply with 0 leverage
        require(_targetSupply >= unleveraged, "leverage");

        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);
        uint lev = _getMaxLeverageRatio(safeCol);
        // 99% to be safe, and save gas
        uint max = (unleveraged.mul(lev) / 1e18).mul(9900) / 10000;
        if (_targetSupply >= max) {
            _targetSupply = max;
        }

        uint i;
        while (supplied < _targetSupply) {
            // target is usually reached in 9 iterations
            require(i < 25, "max iteration");

            // use market collateral to calculate borrow amount
            // this is done so that supplied can reach _targetSupply
            // 99.99% is borrowed to be safe
            uint borrowAmount =
                _getBorrowAmount(supplied, borrowed, marketCol).mul(9999) / 10000;
            require(borrowAmount > 0, "borrow = 0");

            if (supplied.add(borrowAmount) > _targetSupply) {
                // borrow > 0 since supplied < _targetSupply
                borrowAmount = _targetSupply.sub(supplied);
            }
            _borrow(borrowAmount);
            // end loop with _supply, this ensures no borrowed amount is unutilized
            _supply(borrowAmount);

            // supplied > _getSupplied(), by about 3 * 1e12 %, but we use local variable to save gas
            supplied = supplied.add(borrowAmount);
            // _getBorrowed == borrowed
            borrowed = borrowed.add(borrowAmount);
            i++;
        }
    }

    function leverage(uint _targetSupply) external onlyAuthorized {
        _leverage(_targetSupply);
    }

    function _deposit() private {
        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            _supply(bal);
            // leverage to max
            _leverage(type(uint).max);
        }
    }

    /*
    @notice Deposit underlying token into this strategy
    @param _amount Amount of underlying token to deposit
    */
    function deposit(uint _amount) external override onlyAuthorized {
        require(_amount > 0, "deposit = 0");

        uint diff = _increaseDebt(_amount);
        _deposit();

        emit Deposit(diff);
    }

    function _getRedeemAmount(
        uint _supplied,
        uint _borrowed,
        uint _col
    ) private pure returns (uint) {
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        r = redeem

        b / (s - r) <= c
        becomes
        r <= s - b / c
        */
        // min supply
        // b / c = min supply needed to borrow b
        uint min = _borrowed.mul(1e18).div(_col);

        if (_supplied <= min) {
            return 0;
        }
        return _supplied - min;
    }

    /*
    Find S_0, amount of supply with 0 leverage, after n iterations starting with
    S_n supplied and B_n borrowed

    c = collateral ratio
    S_n = current supplied
    B_n = current borrowed

    S_(n-i) = supplied after i iterations
    B_(n-i) = borrowed after i iterations
    R_(n-i) = Redeemable after i iterations
        = S_(n-i) - B_(n-i) / c
        where B_(n-i) / c = min supply needed to borrow B_(n-i)

    For 0 <= k <= n - 1
        S_k = S_(k+1) - R_(k+1)
        B_k = B_(k+1) - R_(k+1)
    and
        S_k - B_k = S_(k+1) - B_(k+1)
    so
        S_0 - B_0 = S_1 - S_2 = ... = S_n - B_n

    S_0 has 0 leverage so B_0 = 0 and we get
        S_0 = S_0 - B_0 = S_n - B_n
    ------------------------------------------

    Find S_(n-k), amount of supply, after k iterations starting with
    S_n supplied and B_n borrowed

    with algebra and induction you can derive that

    R_(n-k) = R_n / c^k
    S_(n-k) = S_n - sum R_(n-i), 0 <= i <= k - 1
            = S_n - R_n * ((1 - 1/c^k) / (1 - 1/c))

    Equation above is valid for S_(n - k) k < n
    */
    function _deleverage(uint _targetSupply) private checkCollateralRatio {
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint unleveraged = supplied.sub(borrowed);
        require(_targetSupply <= supplied, "deleverage");

        uint marketCol = _getMarketCollateralRatio();

        // min supply
        if (_targetSupply <= unleveraged) {
            _targetSupply = unleveraged;
        }

        uint i;
        while (supplied > _targetSupply) {
            // target is usually reached in 8 iterations
            require(i < 25, "max iteration");

            // 99.99% to be safe
            uint redeemAmount =
                (_getRedeemAmount(supplied, borrowed, marketCol)).mul(9999) / 10000;
            require(redeemAmount > 0, "redeem = 0");

            if (supplied.sub(redeemAmount) < _targetSupply) {
                // redeem > 0 since supplied > _targetSupply
                redeemAmount = supplied.sub(_targetSupply);
            }
            _redeem(redeemAmount);
            _repay(redeemAmount);

            // supplied < _geSupplied(), by about 7 * 1e12 %
            supplied = supplied.sub(redeemAmount);
            // borrowed == _getBorrowed()
            borrowed = borrowed.sub(redeemAmount);
            i++;
        }
    }

    function deleverage(uint _targetSupply) external onlyAuthorized {
        _deleverage(_targetSupply);
    }

    // @dev Returns amount available for transfer
    function _withdraw(uint _amount) private returns (uint) {
        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal >= _amount) {
            return _amount;
        }

        uint redeemAmount = _amount - bal;
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        r = amount to redeem
        x = amount to repay

        where
            r <= s - b (can't redeem more than unleveraged supply)
        and
            x <= b (can't repay more than borrowed)
        and
            (b - x) / (s - x - r) <= c (stay below c after redeem and repay)

        so pick x such that
            (b - cs + cr) / (1 - c) <= x <= b

        when b <= cs left side of equation above <= cr / (1 - c) so pick x such that
            cr / (1 - c) <= x <= b
        */
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);
        uint unleveraged = supplied.sub(borrowed);

        // r <= s - b
        if (redeemAmount > unleveraged) {
            redeemAmount = unleveraged;
        }
        // cr / (1 - c) <= x <= b
        uint repayAmount = redeemAmount.mul(safeCol).div(uint(1e18).sub(safeCol));
        if (repayAmount > borrowed) {
            repayAmount = borrowed;
        }

        _deleverage(supplied.sub(repayAmount));
        _redeem(redeemAmount);

        uint balAfter = IERC20(underlying).balanceOf(address(this));
        if (balAfter < _amount) {
            return balAfter;
        }
        return _amount;
    }

    /*
    @notice Withdraw undelying token to vault
    @param _amount Amount of underlying token to withdraw
    @dev Caller should implement guard against slippage
    */
    function withdraw(uint _amount) external override onlyAuthorized {
        require(_amount > 0, "withdraw = 0");
        // available <= _amount
        uint available = _withdraw(_amount);
        uint diff;
        if (available > 0) {
            diff = _decreaseDebt(available);
        }

        emit Withdraw(diff);
    }

    // @dev withdraw all creates dust in supplied
    function _withdrawAll() private {
        _withdraw(type(uint).max);

        // In case there is dust, re-calculate balance
        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            IERC20(underlying).safeTransfer(vault, bal);
            totalDebt = 0;
        }

        emit Withdraw(bal);
    }

    /*
    @notice Withdraw all underlying to vault
    @dev Caller should implement guard agains slippage
    */
    function withdrawAll() external override onlyAuthorized {
        _withdrawAll();
    }

    /*
    @dev Uniswap fails with zero address so no check is necessary here
    */
    function _swap(
        address _from,
        address _to,
        uint _amount
    ) private {
        // create dynamic array with 3 elements
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = WETH;
        path[2] = _to;

        Uniswap(UNISWAP).swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }

    function _claimRewards() private {
        // claim COMP
        address[] memory cTokens = new address[](1);
        cTokens[0] = cToken;
        Comptroller(COMPTROLLER).claimComp(address(this), cTokens);

        uint compBal = IERC20(COMP).balanceOf(address(this));
        if (compBal > 0) {
            _swap(COMP, underlying, compBal);
            // Now this contract has underlying token
        }
    }

    /*
    @notice Claim and sell any rewards
    */
    function harvest() external override onlyAuthorized {
        _claimRewards();

        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                IERC20(underlying).safeTransfer(treasury, fee);
            }
            // _supply() to decrease collateral ratio and earn interest
            // use _supply() instead of _deposit() to save gas
            uint profit = bal.sub(fee);
            _supply(profit);

            emit Harvest(profit);
        }
    }

    /*
    @notice Increase total debt if profit > 0
    */
    function skim() external override onlyAuthorized {
        uint bal = IERC20(underlying).balanceOf(address(this));
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint unleveraged = supplied.sub(borrowed);
        uint total = bal.add(unleveraged);
        require(total > totalDebt, "total <= debt");

        uint profit = total - totalDebt;

        // Incrementing totalDebt has the same effect as transferring profit
        // back to vault and then depositing into this strategy
        // Here we simply increment totalDebt to save gas
        totalDebt = total;

        emit Skim(profit);
    }

    /*
    @notice Exit from strategy, transfer all underlying tokens back to vault
            unless forceExit = true
    */
    function exit() external override onlyAuthorized {
        if (forceExit) {
            return;
        }
        _claimRewards();
        _withdrawAll();
    }

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    */
    function sweep(address _token) external override onlyAdmin {
        require(_token != underlying, "protected token");
        require(_token != cToken, "protected token");
        require(_token != COMP, "protected token");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

// File: contracts/strategies/StrategyCompLevDai.sol

contract StrategyCompLevDai is StrategyCompLev {
    constructor(
        address _controller,
        address _vault,
        address _cToken,
        address _keeper
    )
        public
        StrategyCompLev(
            _controller,
            _vault,
            // DAI
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            // CDAI
            _cToken,
            _keeper
        )
    {}
}