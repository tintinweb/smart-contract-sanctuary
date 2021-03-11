/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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

// File: contracts/protocol/IStrategy.sol

/*
version 1.2.0

Changes

Changes listed here do not affect interaction with other contracts (Vault and Controller)
- removed function assets(address _token) external view returns (bool);
- remove function deposit(uint), declared in IStrategyERC20
- add function setSlippage(uint _slippage);
- add function setDelta(uint _delta);
*/

interface IStrategy {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function vault() external view returns (address);

    /*
    @notice Returns address of underlying asset (ETH or ERC20)
    @dev Must return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH strategy
    */
    function underlying() external view returns (address);

    /*
    @notice Returns total amount of underlying transferred from vault
    */
    function totalDebt() external view returns (uint);

    function performanceFee() external view returns (uint);

    function slippage() external view returns (uint);

    /* 
    @notice Multiplier used to check total underlying <= total debt * delta / DELTA_MIN
    */
    function delta() external view returns (uint);

    /*
    @dev Flag to force exit in case normal exit fails
    */
    function forceExit() external view returns (bool);

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setPerformanceFee(uint _fee) external;

    function setSlippage(uint _slippage) external;

    function setDelta(uint _delta) external;

    function setForceExit(bool _forceExit) external;

    /*
    @notice Returns amount of underlying asset locked in this contract
    @dev Output may vary depending on price of liquidity provider token
         where the underlying asset is invested
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Withdraw `_amount` underlying asset
    @param amount Amount of underlying asset to withdraw
    */
    function withdraw(uint _amount) external;

    /*
    @notice Withdraw all underlying asset from strategy
    */
    function withdrawAll() external;

    /*
    @notice Sell any staking rewards for underlying and then deposit undelying
    */
    function harvest() external;

    /*
    @notice Increase total debt if profit > 0 and total assets <= max,
            otherwise transfers profit to vault.
    @dev Guard against manipulation of external price feed by checking that
         total assets is below factor of total debt
    */
    function skim() external;

    /*
    @notice Exit from strategy
    @dev Must transfer all underlying tokens back to vault
    */
    function exit() external;

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to underlying token
    */
    function sweep(address _token) external;
}

// File: contracts/protocol/IStrategyETH.sol

interface IStrategyETH is IStrategy {
    /*
    @notice Deposit ETH
    */
    function deposit() external payable;
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

// File: contracts/StrategyETH.sol

/*
version 1.2.0
*/

// used inside harvest

abstract contract StrategyETH is IStrategyETH {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public override admin;
    address public override controller;
    address public immutable override vault;
    // Placeholder address to indicate that this is ETH strategy
    address public constant override underlying =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // total amount of ETH transferred from vault
    uint public override totalDebt;

    // performance fee sent to treasury when harvest() generates profit
    uint public override performanceFee = 500;
    uint private constant PERFORMANCE_FEE_CAP = 2000; // upper limit to performance fee
    uint internal constant PERFORMANCE_FEE_MAX = 10000;

    // prevent slippage from deposit / withdraw
    uint public override slippage = 100;
    uint internal constant SLIPPAGE_MAX = 10000;

    /* 
    Multiplier used to check totalAssets() is <= total debt * delta / DELTA_MIN
    */
    uint public override delta = 10050;
    uint private constant DELTA_MIN = 10000;

    // Force exit, in case normal exit fails
    bool public override forceExit;

    constructor(address _controller, address _vault) public {
        require(_controller != address(0), "controller = zero address");
        require(_vault != address(0), "vault = zero address");

        admin = msg.sender;
        controller = _controller;
        vault = _vault;
    }

    /*
    @dev implement receive() external payable in child contract
    @dev receive() should restrict msg.sender to prevent accidental ETH transfer
    @dev vault and controller will never call receive()
    */

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == admin || msg.sender == controller || msg.sender == vault,
            "!authorized"
        );
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function setController(address _controller) external override onlyAdmin {
        require(_controller != address(0), "controller = zero address");
        controller = _controller;
    }

    function setPerformanceFee(uint _fee) external override onlyAdmin {
        require(_fee <= PERFORMANCE_FEE_CAP, "performance fee > cap");
        performanceFee = _fee;
    }

    function setSlippage(uint _slippage) external override onlyAdmin {
        require(_slippage <= SLIPPAGE_MAX, "slippage > max");
        slippage = _slippage;
    }

    function setDelta(uint _delta) external override onlyAdmin {
        require(_delta >= DELTA_MIN, "delta < min");
        delta = _delta;
    }

    function setForceExit(bool _forceExit) external override onlyAdmin {
        forceExit = _forceExit;
    }

    function _sendEthToVault(uint _amount) internal {
        require(address(this).balance >= _amount, "ETH balance < amount");

        (bool sent, ) = vault.call{value: _amount}("");
        require(sent, "Send ETH failed");
    }

    function _increaseDebt(uint _ethAmount) private {
        totalDebt = totalDebt.add(_ethAmount);
    }

    function _decreaseDebt(uint _ethAmount) private {
        _sendEthToVault(_ethAmount);

        if (_ethAmount >= totalDebt) {
            totalDebt = 0;
        } else {
            totalDebt -= _ethAmount;
        }
    }

    function _totalAssets() internal view virtual returns (uint);

    /*
    @notice Returns amount of ETH locked in this contract
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    function _deposit() internal virtual;

    /*
    @notice Deposit ETH into this strategy
    */
    function deposit() external payable override onlyAuthorized {
        require(msg.value > 0, "deposit = 0");

        _increaseDebt(msg.value);
        _deposit();
    }

    /*
    @notice Returns total shares owned by this contract for depositing ETH
            into external Defi
    */
    function _getTotalShares() internal view virtual returns (uint);

    function _getShares(uint _ethAmount, uint _totalEth) internal view returns (uint) {
        /*
        calculate shares to withdraw

        w = amount of ETH to withdraw
        E = total redeemable ETH
        s = shares to withdraw
        P = total shares deposited into external liquidity pool

        w / E = s / P
        s = w / E * P
        */
        if (_totalEth > 0) {
            uint totalShares = _getTotalShares();
            return _ethAmount.mul(totalShares) / _totalEth;
        }
        return 0;
    }

    function _withdraw(uint _shares) internal virtual;

    /*
    @notice Withdraw ETH to vault
    @param _ethAmount Amount of ETH to withdraw
    @dev Caller should implement guard against slippage
    */
    function withdraw(uint _ethAmount) external override onlyAuthorized {
        require(_ethAmount > 0, "withdraw = 0");
        uint totalEth = _totalAssets();
        require(_ethAmount <= totalEth, "withdraw > total");

        uint shares = _getShares(_ethAmount, totalEth);
        if (shares > 0) {
            _withdraw(shares);
        }

        // transfer ETH to vault
        /*
        WARNING: Here we are transferring all funds in this contract.
                 This operation is safe under 2 conditions:
        1. This contract does not hold any funds at rest.
        2. Vault does not allow user to withdraw excess > _underlyingAmount
        */
        uint ethBal = address(this).balance;
        if (ethBal > 0) {
            _decreaseDebt(ethBal);
        }
    }

    function _withdrawAll() internal {
        uint totalShares = _getTotalShares();
        if (totalShares > 0) {
            _withdraw(totalShares);
        }

        // transfer ETH to vault
        uint ethBal = address(this).balance;
        if (ethBal > 0) {
            _sendEthToVault(ethBal);
            totalDebt = 0;
        }
    }

    /*
    @notice Withdraw all ETH to vault
    @dev Caller should implement guard agains slippage
    */
    function withdrawAll() external override onlyAuthorized {
        _withdrawAll();
    }

    /*
    @notice Sell any staking rewards for ETH and then deposit ETH
    */
    function harvest() external virtual override;

    /*
    @notice Increase total debt if profit > 0 and total assets <= max,
            otherwise transfers profit to vault.
    @dev Guard against manipulation of external price feed by checking that
         total assets is below factor of total debt
    */
    function skim() external override onlyAuthorized {
        uint totalEth = _totalAssets();
        require(totalEth > totalDebt, "total ETH < debt");

        uint profit = totalEth - totalDebt;

        // protect against price manipulation
        uint max = totalDebt.mul(delta) / DELTA_MIN;
        if (totalEth <= max) {
            /*
            total ETH is within reasonable bounds, probaly no price
            manipulation occured.
            */

            /*
            If we were to withdraw profit followed by deposit, this would
            increase the total debt roughly by the profit.

            Withdrawing consumes high gas, so here we omit it and
            directly increase debt, as if withdraw and deposit were called.
            */
            totalDebt = totalDebt.add(profit);
        } else {
            /*
            Possible reasons for total ETH > max
            1. total debt = 0
            2. total ETH really did increase over max
            3. price was manipulated
            */
            uint shares = _getShares(profit, totalEth);
            if (shares > 0) {
                uint balBefore = address(this).balance;
                _withdraw(shares);
                uint balAfter = address(this).balance;

                uint diff = balAfter.sub(balBefore);
                if (diff > 0) {
                    _sendEthToVault(diff);
                }
            }
        }
    }

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

// File: contracts/interfaces/curve/StableSwapSTETH.sol

interface StableSwapSTETH {
    function get_virtual_price() external view returns (uint);

    /*
    0 ETH
    1 STETH
    */
    function balances(uint _index) external view returns (uint);

    function add_liquidity(uint[2] memory amounts, uint min) external payable;

    function remove_liquidity_one_coin(
        uint _token_amount,
        int128 i,
        uint min_amount
    ) external;
}

// File: contracts/interfaces/lido/StETH.sol

interface StETH {
    function submit(address) external payable returns (uint);
}

// File: contracts/strategies/StrategyStEth.sol

contract StrategyStEth is StrategyETH {
    // Uniswap //
    address private constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Curve //
    // liquidity provider token (Curve ETH/STETH)
    address private constant LP = 0x06325440D014e39736583c165C2963BA99fAf14E;
    // StableSwapSTETH
    address private constant POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    // LiquidityGaugeV2
    address private constant GAUGE = 0x182B723a58739a9c974cFDB385ceaDb237453c28;
    // Minter
    address private constant MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    // CRV
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // LIDO //
    address private constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    constructor(address _controller, address _vault)
        public
        StrategyETH(_controller, _vault)
    {
        // These tokens are never held by this contract
        // so the risk of them getting stolen is minimal
        IERC20(CRV).safeApprove(UNISWAP, uint(-1));
        // Minted on Gauge deposit, withdraw and claim_rewards
        // only this contract can spend on UNISWAP
        IERC20(LDO).safeApprove(UNISWAP, uint(-1));
    }

    receive() external payable {
        // Don't allow vault to accidentally send ETH
        require(msg.sender != vault, "msg.sender = vault");
    }

    function _totalAssets() internal view override returns (uint) {
        uint shares = LiquidityGaugeV2(GAUGE).balanceOf(address(this));
        uint pricePerShare = StableSwapSTETH(POOL).get_virtual_price();

        return shares.mul(pricePerShare) / 1e18;
    }

    function _getStEthDepositAmount(uint _ethBal) private view returns (uint) {
        /*
        Goal is to find a0 and a1 such that b0 + a0 is close to b1 + a1 

        E = amount of ETH
        b0 = balance of ETH in Curve
        b1 = balance of stETH in Curve
        a0 = amount of ETH to deposit into Curve
        a1 = amount of stETH to deposit into Curve

        d = |b0 - b1|

        if d >= E
            if b0 >= b1
                a0 = 0
                a1 = E
            else
                a0 = E
                a1 = 0
        else
            if b0 >= b1
                # add d to balance Curve pool, plus half of remaining
                a1 = d + (E - d) / 2 = (E + d) / 2
                a0 = E - a1
            else
                a0 = (E + d) / 2
                a1 = E - a0
        */
        uint[2] memory balances;
        balances[0] = StableSwapSTETH(POOL).balances(0);
        balances[1] = StableSwapSTETH(POOL).balances(1);

        uint diff;
        if (balances[0] >= balances[1]) {
            diff = balances[0] - balances[1];
        } else {
            diff = balances[1] - balances[0];
        }

        // a0 = ETH amount is ignored, recomputed after stEth is bought
        // a1 = stETH amount
        uint a1;
        if (diff >= _ethBal) {
            if (balances[0] >= balances[1]) {
                a1 = _ethBal;
            }
        } else {
            if (balances[0] >= balances[1]) {
                a1 = (_ethBal.add(diff)) / 2;
            } else {
                a1 = _ethBal.sub((_ethBal.add(diff)) / 2);
            }
        }

        // a0 is ignored, recomputed after stEth is bought
        return a1;
    }

    /*
    @notice Deposits ETH to LiquidityGaugeV2
    */
    function _deposit() internal override {
        uint bal = address(this).balance;
        if (bal > 0) {
            uint stEthAmount = _getStEthDepositAmount(bal);
            if (stEthAmount > 0) {
                StETH(ST_ETH).submit{value: stEthAmount}(address(this));
            }

            uint ethBal = address(this).balance;
            uint stEthBal = IERC20(ST_ETH).balanceOf(address(this));

            if (stEthBal > 0) {
                // ST_ETH is proxy so don't allow infinite approval
                IERC20(ST_ETH).safeApprove(POOL, stEthBal);
            }

            /*
            shares = eth amount * 1e18 / price per share
            */
            uint pricePerShare = StableSwapSTETH(POOL).get_virtual_price();
            uint shares = bal.mul(1e18).div(pricePerShare);
            uint min = shares.mul(SLIPPAGE_MAX - slippage) / SLIPPAGE_MAX;

            StableSwapSTETH(POOL).add_liquidity{value: ethBal}([ethBal, stEthBal], min);
        }

        // stake into LiquidityGaugeV2
        uint lpBal = IERC20(LP).balanceOf(address(this));
        if (lpBal > 0) {
            IERC20(LP).safeApprove(GAUGE, lpBal);
            LiquidityGaugeV2(GAUGE).deposit(lpBal);
        }
    }

    function _getTotalShares() internal view override returns (uint) {
        return LiquidityGaugeV2(GAUGE).balanceOf(address(this));
    }

    function _withdraw(uint _lpAmount) internal override {
        // withdraw LP from  LiquidityGaugeV2
        LiquidityGaugeV2(GAUGE).withdraw(_lpAmount);

        uint lpBal = IERC20(LP).balanceOf(address(this));
        /*
        eth amount = (shares * price per shares) / 1e18
        */
        uint pricePerShare = StableSwapSTETH(POOL).get_virtual_price();
        uint ethAmount = lpBal.mul(pricePerShare) / 1e18;
        uint min = ethAmount.mul(SLIPPAGE_MAX - slippage) / SLIPPAGE_MAX;

        StableSwapSTETH(POOL).remove_liquidity_one_coin(lpBal, 0, min);
        // Now we have ETH
    }

    /*
    @dev Uniswap fails with zero address so no check is necessary here
    */
    function _swapToEth(address _from, uint _amount) private {
        // create dynamic array with 2 elements
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = WETH;

        Uniswap(UNISWAP).swapExactTokensForETH(
            _amount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }

    function _claimRewards() private {
        // claim LDO
        LiquidityGaugeV2(GAUGE).claim_rewards();
        // claim CRV
        Minter(MINTER).mint(GAUGE);

        // Infinity approval for Uniswap set inside constructor
        uint ldoBal = IERC20(LDO).balanceOf(address(this));
        if (ldoBal > 0) {
            _swapToEth(LDO, ldoBal);
        }

        uint crvBal = IERC20(CRV).balanceOf(address(this));
        if (crvBal > 0) {
            _swapToEth(CRV, crvBal);
        }
    }

    /*
    @notice Claim CRV and deposit most premium token into Curve
    */
    function harvest() external override onlyAuthorized {
        _claimRewards();

        uint bal = address(this).balance;
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");
                // treasury must be able to receive ETH
                (bool sent, ) = treasury.call{value: fee}("");
                require(sent, "Send ETH failed");
            }
            _deposit();
        }
    }

    /*
    @notice Exit strategy by harvesting CRV to underlying token and then
            withdrawing all underlying to vault
    @dev Must return all underlying token to vault
    @dev Caller should implement guard agains slippage
    */
    function exit() external override onlyAuthorized {
        if (forceExit) {
            return;
        }
        _claimRewards();
        _withdrawAll();
    }

    function sweep(address _token) external override onlyAdmin {
        require(_token != GAUGE, "protected token");
        require(_token != LDO, "protected token");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}