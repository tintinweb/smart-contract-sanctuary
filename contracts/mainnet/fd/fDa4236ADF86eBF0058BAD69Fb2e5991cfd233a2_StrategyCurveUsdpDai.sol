/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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

// File: contracts/protocol/IController.sol

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

// File: contracts/interfaces/curve/LiquidityGaugeV2.sol

interface LiquidityGaugeV2 {
    function deposit(uint) external;

    function balanceOf(address) external view returns (uint);

    function withdraw(uint) external;

    function claim_rewards() external;
}

// File: contracts/interfaces/curve/Minter.sol

// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/Minter.vy
interface Minter {
    function mint(address) external;
}

// File: contracts/interfaces/curve/StableSwapUsdp.sol

interface StableSwapUsdp {
    function get_virtual_price() external view returns (uint);

    /*
    0 USDP
    1 3CRV
    */
    function balances(uint index) external view returns (uint);
}

// File: contracts/interfaces/curve/StableSwap3Pool.sol

interface StableSwap3Pool {
    function get_virtual_price() external view returns (uint);

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint token_amount,
        int128 i,
        uint min_uamount
    ) external;

    function balances(uint index) external view returns (uint);
}

// File: contracts/interfaces/curve/DepositUsdp.sol

interface DepositUsdp {
    /*
    0 USDP
    1 DAI
    2 USDC
    3 USDT
    */
    function add_liquidity(uint[4] memory amounts, uint min) external returns (uint);

    // @dev returns amount of underlying token withdrawn
    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min
    ) external returns (uint);
}

// File: contracts/strategies/StrategyCurveUsdp.sol

contract StrategyCurveUsdp is StrategyERC20_V3 {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event Harvest(uint profit);
    event Skim(uint profit);

    // Uniswap //
    address private constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant USDP = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // USDP = 0 | DAI = 1 | USDC = 2 | USDT = 3
    uint private immutable UNDERLYING_INDEX;
    // precision to convert 10 ** 18  to underlying decimals
    uint[4] private PRECISION_DIV = [1, 1, 1e12, 1e12];
    // precision div of underlying token (used to save gas)
    uint private immutable PRECISION_DIV_UNDERLYING;

    // Curve //
    // StableSwap3Pool
    address private constant BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // StableSwap
    address private constant SWAP = 0x42d7025938bEc20B69cBae5A77421082407f053A;
    // liquidity provider token (USDP / 3CRV)
    address private constant LP = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    // Deposit
    address private constant DEPOSIT = 0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940;
    // LiquidityGaugeV2
    address private constant GAUGE = 0x055be5DDB7A925BfEF3417FC157f53CA77cA7222;
    // Minter
    address private constant MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    // CRV
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // prevent slippage from deposit / withdraw
    uint public slippage = 100;
    uint private constant SLIPPAGE_MAX = 10000;

    /*
    Numerator used to update totalDebt if
    totalAssets() is <= totalDebt * delta / DELTA_MIN
    */
    uint public delta = 10050;
    uint private constant DELTA_MIN = 10000;

    // enable to claim LiquidityGaugeV2 rewards
    bool public shouldClaimRewards;

    constructor(
        address _controller,
        address _vault,
        address _underlying,
        uint _underlyingIndex,
        address _keeper
    ) public StrategyERC20_V3(_controller, _vault, _underlying, _keeper) {
        UNDERLYING_INDEX = _underlyingIndex;
        PRECISION_DIV_UNDERLYING = PRECISION_DIV[_underlyingIndex];

        // Infinite approvals should be safe as long as only small amount
        // of underlying is stored in this contract.

        // Approve DepositUsdp.add_liquidity
        IERC20(USDP).safeApprove(DEPOSIT, type(uint).max);
        IERC20(DAI).safeApprove(DEPOSIT, type(uint).max);
        IERC20(USDC).safeApprove(DEPOSIT, type(uint).max);
        IERC20(USDT).safeApprove(DEPOSIT, type(uint).max);
        // Approve LiquidityGaugeV2.deposit
        IERC20(LP).safeApprove(GAUGE, type(uint).max);
        // approve DepositUsdp.remove_liquidity
        IERC20(LP).safeApprove(DEPOSIT, type(uint).max);

        // These tokens are never held by this contract
        // so the risk of them getting stolen is minimal
        IERC20(CRV).safeApprove(UNISWAP, type(uint).max);
    }

    /*
    @notice Set max slippage for deposit and withdraw from Curve pool
    @param _slippage Max amount of slippage allowed
    */
    function setSlippage(uint _slippage) external onlyAdmin {
        require(_slippage <= SLIPPAGE_MAX, "slippage > max");
        slippage = _slippage;
    }

    /*
    @notice Set delta, used to calculate difference between totalAsset and totalDebt
    @param _delta Numerator of delta / DELTA_MIN
    */
    function setDelta(uint _delta) external onlyAdmin {
        require(_delta >= DELTA_MIN, "delta < min");
        delta = _delta;
    }

    /*
    @notice Activate or decactivate LiquidityGaugeV2.claim_rewards()
    */
    function setShouldClaimRewards(bool _shouldClaimRewards) external onlyAdmin {
        shouldClaimRewards = _shouldClaimRewards;
    }

    function _totalAssets() private view returns (uint) {
        uint lpBal = LiquidityGaugeV2(GAUGE).balanceOf(address(this));
        uint pricePerShare = StableSwapUsdp(SWAP).get_virtual_price();

        return lpBal.mul(pricePerShare) / (PRECISION_DIV_UNDERLYING * 1e18);
    }

    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    function _increaseDebt(uint _amount) private returns (uint) {
        // USDT has transfer fee so we need to check balance after transfer
        uint balBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransferFrom(vault, address(this), _amount);
        uint balAfter = IERC20(underlying).balanceOf(address(this));

        uint diff = balAfter.sub(balBefore);
        totalDebt = totalDebt.add(diff);

        return diff;
    }

    function _decreaseDebt(uint _amount) private returns (uint) {
        // USDT has transfer fee so we need to check balance after transfer
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

    /*
    @notice Deposit underlying token into Curve
    @param _token Address of underlying token
    @param _index Index of underlying token
    */
    function _deposit(address _token, uint _index) private {
        // deposit underlying token, get LP
        uint bal = IERC20(_token).balanceOf(address(this));
        if (bal > 0) {
            // mint LP
            uint[4] memory amounts;
            amounts[_index] = bal;

            /*
            shares = underlying amount * precision div * 1e18 / price per share
            */
            uint pricePerShare = StableSwapUsdp(SWAP).get_virtual_price();
            uint shares = bal.mul(PRECISION_DIV[_index]).mul(1e18).div(pricePerShare);
            uint min = shares.mul(SLIPPAGE_MAX - slippage) / SLIPPAGE_MAX;

            uint lpAmount = DepositUsdp(DEPOSIT).add_liquidity(amounts, min);

            // stake into LiquidityGaugeV2
            if (lpAmount > 0) {
                LiquidityGaugeV2(GAUGE).deposit(lpAmount);
            }
        }
    }

    function deposit(uint _amount) external override onlyAuthorized {
        require(_amount > 0, "deposit = 0");

        uint diff = _increaseDebt(_amount);
        _deposit(underlying, UNDERLYING_INDEX);

        emit Deposit(diff);
    }

    function _getTotalShares() private view returns (uint) {
        return LiquidityGaugeV2(GAUGE).balanceOf(address(this));
    }

    function _getShares(
        uint _amount,
        uint _total,
        uint _totalShares
    ) private pure returns (uint) {
        /*
        calculate shares to withdraw

        w = amount of underlying to withdraw
        U = total redeemable underlying
        s = shares to withdraw
        P = total shares deposited into external liquidity pool

        w / U = s / P
        s = w / U * P
        */
        if (_total > 0) {
            // avoid rounding errors and cap shares to be <= total shares
            if (_amount >= _total) {
                return _totalShares;
            }
            return _amount.mul(_totalShares) / _total;
        }
        return 0;
    }

    /*
    @notice Withdraw underlying token from Curve
    @param _amount Amount of underlying token to withdraw
    @return Actual amount of underlying token that was withdrawn
    */
    function _withdraw(uint _amount) private returns (uint) {
        require(_amount > 0, "withdraw = 0");

        uint total = _totalAssets();

        if (_amount >= total) {
            _amount = total;
        }

        uint totalShares = _getTotalShares();
        uint shares = _getShares(_amount, total, totalShares);

        if (shares > 0) {
            // withdraw LP from LiquidityGaugeV2
            LiquidityGaugeV2(GAUGE).withdraw(shares);

            uint min = _amount.mul(SLIPPAGE_MAX - slippage) / SLIPPAGE_MAX;
            // withdraw creates LP dust
            return
                DepositUsdp(DEPOSIT).remove_liquidity_one_coin(
                    shares,
                    int128(UNDERLYING_INDEX),
                    min
                );
            // Now we have underlying
        }
        return 0;
    }

    function withdraw(uint _amount) external override onlyAuthorized {
        uint withdrawn = _withdraw(_amount);

        if (withdrawn < _amount) {
            _amount = withdrawn;
        }
        // if withdrawn > _amount, excess will be deposited when deposit() is called

        uint diff;
        if (_amount > 0) {
            diff = _decreaseDebt(_amount);
        }

        emit Withdraw(diff);
    }

    function _withdrawAll() private {
        _withdraw(type(uint).max);

        // There may be dust so re-calculate balance
        uint bal = IERC20(underlying).balanceOf(address(this));
        if (bal > 0) {
            IERC20(underlying).safeTransfer(vault, bal);
            totalDebt = 0;
        }

        emit Withdraw(bal);
    }

    function withdrawAll() external override onlyAuthorized {
        _withdrawAll();
    }

    /*
    @notice Returns address and index of token with lowest balance in Curve pool
    */
    function _getMostPremiumToken() private view returns (address, uint) {
        // WARNING: USDP disabled - Low ETH / USDP liquidity

        // meta pool balances
        // uint[2] memory balances;
        // balances[0] = StableSwapUsdp(SWAP).balances(0); // USDP
        // balances[1] = StableSwapUsdp(SWAP).balances(1); // 3CRV

        // if (balances[0] <= balances[1]) {
        //     return (USDP, 0);
        // } else {
        // base pool balances
        uint[3] memory baseBalances;
        baseBalances[0] = StableSwap3Pool(BASE_POOL).balances(0); // DAI
        baseBalances[1] = StableSwap3Pool(BASE_POOL).balances(1).mul(1e12); // USDC
        baseBalances[2] = StableSwap3Pool(BASE_POOL).balances(2).mul(1e12); // USDT

        /*
        DAI  1
        USDC 2
        USDT 3
        */

        // DAI
        if (baseBalances[0] <= baseBalances[1] && baseBalances[0] <= baseBalances[2]) {
            return (DAI, 1);
        }

        // USDC
        if (baseBalances[1] <= baseBalances[0] && baseBalances[1] <= baseBalances[2]) {
            return (USDC, 2);
        }

        return (USDT, 3);
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

    function _claimRewards(address _token) private {
        if (shouldClaimRewards) {
            LiquidityGaugeV2(GAUGE).claim_rewards();
            // Rewarded tokens will be managed by admin via calling sweep()
        }

        // claim CRV
        Minter(MINTER).mint(GAUGE);

        uint crvBal = IERC20(CRV).balanceOf(address(this));
        // Swap only if CRV >= 1, otherwise swap may fail
        if (crvBal >= 1e18) {
            _swap(CRV, _token, crvBal);
            // Now this contract has token
        }
    }

    /*
    @notice Claim CRV and deposit most premium token into Curve
    */
    function harvest() external override onlyAuthorized {
        (address token, uint index) = _getMostPremiumToken();

        _claimRewards(token);

        uint bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = 0 address");

                IERC20(token).safeTransfer(treasury, fee);
            }

            _deposit(token, index);

            emit Harvest(bal.sub(fee));
        }
    }

    function skim() external override onlyAuthorized {
        uint total = _totalAssets();
        require(total > totalDebt, "total underlying < debt");

        uint profit = total - totalDebt;

        // protect against price manipulation
        uint max = totalDebt.mul(delta) / DELTA_MIN;
        if (total <= max) {
            /*
            total underlying is within reasonable bounds, probaly no price
            manipulation occured.
            */

            /*
            If we were to withdraw profit followed by deposit, this would
            increase the total debt roughly by the profit.

            Withdrawing consumes high gas, so here we omit it and
            directly increase debt, as if withdraw and deposit were called.
            */
            // total debt = total debt + profit = total
            totalDebt = total;
        } else {
            /*
            Possible reasons for total underlying > max
            1. total debt = 0
            2. total underlying really did increase over max
            3. price was manipulated
            */
            uint withdrawn = _withdraw(profit);
            if (withdrawn > 0) {
                IERC20(underlying).safeTransfer(vault, withdrawn);
            }
        }

        emit Skim(profit);
    }

    function exit() external override onlyAuthorized {
        if (forceExit) {
            return;
        }
        _claimRewards(underlying);
        _withdrawAll();
    }

    function sweep(address _token) external override onlyAdmin {
        require(_token != underlying, "protected token");
        require(_token != GAUGE, "protected token");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

// File: contracts/strategies/StrategyCurveUsdpDai.sol

contract StrategyCurveUsdpDai is StrategyCurveUsdp {
    constructor(
        address _controller,
        address _vault,
        address _keeper
    ) public StrategyCurveUsdp(_controller, _vault, DAI, 1, _keeper) {}
}