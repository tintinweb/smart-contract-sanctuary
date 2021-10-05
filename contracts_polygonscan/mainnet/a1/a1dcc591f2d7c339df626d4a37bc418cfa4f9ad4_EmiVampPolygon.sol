/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libraries/Priviledgeable.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;


abstract contract Priviledgeable {
    using SafeMath for uint256;
    using SafeMath for uint256;

    event PriviledgeGranted(address indexed admin);
    event PriviledgeRevoked(address indexed admin);

    modifier onlyAdmin() {
        require(
            _priviledgeTable[msg.sender],
            "Priviledgeable: caller is not the owner"
        );
        _;
    }

    mapping(address => bool) private _priviledgeTable;

    constructor() internal {
        _priviledgeTable[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyAdmin returns (bool) {
        require(_admin != address(0), "Admin address cannot be 0");
        return _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin returns (bool) {
        require(_admin != address(0), "Admin address cannot be 0");
        _priviledgeTable[_admin] = false;
        emit PriviledgeRevoked(_admin);

        return true;
    }

    function isAdmin(address _who) external view returns (bool) {
        return _priviledgeTable[_who];
    }

    //-----------
    // internals
    //-----------
    function _addAdmin(address _admin) internal returns (bool) {
        _priviledgeTable[_admin] = true;
        emit PriviledgeGranted(_admin);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: @openzeppelin/contracts/proxy/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// File: contracts/interfaces/IEmiswap.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;


interface IEmiswapRegistry {
    function pools(IERC20 token1, IERC20 token2)
        external
        view
        returns (IEmiswap);

    function isPool(address addr) external view returns (bool);

    function deploy(IERC20 tokenA, IERC20 tokenB) external returns (IEmiswap);

    function getAllPools() external view returns (IEmiswap[] memory);
}

interface IEmiswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        address referral
    ) external payable returns (uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token)
        external
        view
        returns (uint256);

    function getBalanceForRemoval(IERC20 token) external view returns (uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns (uint256, uint256);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address to,
        address referral
    ) external payable returns (uint256 returnAmount);

    function initialize(IERC20[] calldata assets) external;
}

// File: contracts/interfaces/IEmiVoting.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;

interface IEmiVoting {
    function getVotingResult(uint256 _hash) external view returns (address);
}

// File: contracts/interfaces/IMooniswap.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;


interface IMooniswap {
    function getTokens() external view returns (IERC20[] memory);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;
}

// File: contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/libraries/EmiswapLib.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;




library EmiswapLib {
    using SafeMath for uint256;
    uint256 public constant FEE_DENOMINATOR = 1e18;

    function previewSwapExactTokenForToken(
        address factory,
        address tokenFrom,
        address tokenTo,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(tokenFrom), IERC20(tokenTo));

        if (pairContract != IEmiswap(0)) {
            (, ammountTo) = pairContract.getReturn(
                IERC20(tokenFrom),
                IERC20(tokenTo),
                ammountFrom
            );
        }
    }

    /**************************************************************************************
     * get preview result of virtual swap by route of tokens
     **************************************************************************************/
    function previewSwapbyRoute(
        address factory,
        address[] memory path,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        for (uint256 i = 0; i < path.length - 1; i++) {
            if (path.length >= 2) {
                ammountTo = previewSwapExactTokenForToken(
                    factory,
                    path[i],
                    path[i + 1],
                    ammountFrom
                );

                if (i == (path.length - 2)) {
                    return (ammountTo);
                } else {
                    ammountFrom = ammountTo;
                }
            }
        }
    }

    function fee(address factory) internal view returns (uint256) {
        return IEmiswap(factory).fee();
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        address factory,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "EmiswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "EmiswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator =
            reserveOut.sub(amountOut).mul(
                uint256(1000000000000000000).sub(fee(factory)).div(1e15)
            ); // 997
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        address factory,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) {
            return (0);
        }

        uint256 amountInWithFee =
            amountIn.mul(
                uint256(1000000000000000000).sub(fee(factory)).div(1e15)
            ); //997
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = (denominator == 0 ? 0 : amountOut =
            numerator /
            denominator);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IEmiswap pairContract =
                IEmiswapRegistry(factory).pools(
                    IERC20(IERC20(path[i])),
                    IERC20(path[i - 1])
                );

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(
                    IERC20(path[i - 1])
                );
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(
                    IERC20(path[i])
                );
            }

            amounts[i - 1] = getAmountIn(
                factory,
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            IEmiswap pairContract =
                IEmiswapRegistry(factory).pools(
                    IERC20(IERC20(path[i])),
                    IERC20(path[i + 1])
                );

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(
                    IERC20(path[i])
                );
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(
                    IERC20(path[i + 1])
                );
            }

            amounts[i + 1] = getAmountOut(
                factory,
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "EmiswapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "EmiswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

// File: contracts/EmiVamp-polygon.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;












/**
 * @dev Contract to convert liquidity from other market makers (Uniswap/Mooniswap) to our pairs.
 */
contract EmiVampPolygon is Priviledgeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct LPTokenInfo {
        address lpToken;
        uint16 tokenType; // Token type: 0 - uniswap (default), 1 - mooniswap
    }

    // Info of each third-party lp-token.
    LPTokenInfo[] public lpTokensInfo;

    string public codeVersion = "EmiVampPolygon v1.0.0";
    address public ourFactory;
    event Deposit(address indexed user, address indexed token, uint256 amount);

    address public defRef;

    // !!!In updates to contracts set new variables strictly below this line!!!
    //-----------------------------------------------------------------------------------

    /**
     * @dev Implementation of {UpgradeableProxy} type of constructors
     */
    constructor(
        address[] memory _lptokens,
        uint8[] memory _types,
        address _ourfactory
    ) public {
        require(_lptokens.length > 0, "EmiVamp: length>0!");
        require(_lptokens.length == _types.length, "EmiVamp: lengths!");
        require(_ourfactory != address(0), "EmiVamp: factory!");

        for (uint256 i = 0; i < _lptokens.length; i++) {
            lpTokensInfo.push(
                LPTokenInfo({lpToken: _lptokens[i], tokenType: _types[i]})
            );
        }
        ourFactory = _ourfactory;
        defRef = address(0xdF3242dE305d033Bb87334169faBBf3b7d3D96c2);
        _addAdmin(msg.sender);
    }

    /**
     * @dev Returns length of LP-tokens private array
     */
    function lpTokensInfoLength() external view returns (uint256) {
        return lpTokensInfo.length;
    }

    /**
     *  @dev Returns pair base tokens
     */
    function lpTokenDetailedInfo(uint256 _pid)
        external
        view
        returns (address, address)
    {
        require(_pid < lpTokensInfo.length, "EmiVamp: Wrong lpToken idx");

        if (lpTokensInfo[_pid].tokenType == 0) {
            // this is uniswap
            IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokensInfo[_pid].lpToken);
            return (lpToken.token0(), lpToken.token1());
        } else {
            // this is mooniswap
            IMooniswap lpToken = IMooniswap(lpTokensInfo[_pid].lpToken);
            IERC20[] memory t = lpToken.getTokens();
            return (address(t[0]), address(t[1]));
        }
    }

    /**

     * @dev Adds new entry to the list of convertible LP-tokens
     */
    function addLPToken(address _token, uint16 _tokenType)
        external
        onlyAdmin
        returns (uint256)
    {
        require(_token != address(0), "EmiVamp: Token address cannot be 0");
        require(_tokenType < 2, "EmiVamp: Wrong type");

        for (uint256 i = 0; i < lpTokensInfo.length; i++) {
            if (lpTokensInfo[i].lpToken == _token) {
                return i;
            }
        }
        lpTokensInfo.push(
            LPTokenInfo({lpToken: _token, tokenType: _tokenType})
        );
        return lpTokensInfo.length;
    }

    /**
     * @dev Remove entry from the list of convertible LP-tokens
     */
    function removeLPToken(uint256 _idx) external onlyAdmin {
        require(_idx < lpTokensInfo.length, "EmiVamp: wrong idx");

        delete lpTokensInfo[_idx];
    }

    /**
     * @dev Change entry from the list of convertible LP-tokens
     */
    function changeLPToken(
        uint256 _idx,
        address _token,
        uint16 _tokenType
    ) external onlyAdmin {
        require(_idx < lpTokensInfo.length, "EmiVamp: wrong idx");
        require(_token != address(0), "EmiVamp: token=0!");
        require(_tokenType < 2, "EmiVamp: wrong tokenType");

        lpTokensInfo[_idx].lpToken = _token;
        lpTokensInfo[_idx].tokenType = _tokenType;
    }

    /**
     * @dev Change emifactory address
     */
    function changeFactory(address _newFactory) external onlyAdmin {
        require(
            _newFactory != address(0),
            "EmiVamp: New factory address is wrong"
        );
        ourFactory = _newFactory;
    }

    /**
     * @dev Change default referrer address
     */
    function changeReferral(address _ref) external onlyAdmin {
        defRef = _ref;
    }

    // Deposit LP tokens to us
    /**
     * @dev Main function that converts third-party liquidity (represented by LP-tokens) to our own LP-tokens
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid < lpTokensInfo.length, "EmiVamp: pool idx is wrong");

        if (lpTokensInfo[_pid].tokenType == 0) {
            _depositUniswap(_pid, _amount);
        } else if (lpTokensInfo[_pid].tokenType == 1) {
            _depositMooniswap(_pid, _amount);
        } else {
            return;
        }
        emit Deposit(msg.sender, lpTokensInfo[_pid].lpToken, _amount);
    }

    /**
     * @dev Actual function that converts third-party Uniswap liquidity (represented by LP-tokens) to our own LP-tokens
     */
    function _depositUniswap(uint256 _pid, uint256 _amount) internal {
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokensInfo[_pid].lpToken);

        // check pair existance
        IERC20 token0 = IERC20(lpToken.token0());
        IERC20 token1 = IERC20(lpToken.token1());

        // transfer to us
        TransferHelper.safeTransferFrom(
            address(lpToken),
            address(msg.sender),
            address(lpToken),
            _amount
        );

        // get liquidity
        (uint256 amountIn0, uint256 amountIn1) = lpToken.burn(address(this));

        _addOurLiquidity(
            address(token0),
            address(token1),
            amountIn0,
            amountIn1,
            msg.sender
        );
    }

    function _addOurLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        address _to
    ) internal {
        (uint256 amountA, uint256 amountB) =
            _addLiquidity(_token0, _token1, _amount0, _amount1);

        IEmiswap pairContract =
            IEmiswapRegistry(ourFactory).pools(
                IERC20(_token0),
                IERC20(_token1)
            );

        TransferHelper.safeApprove(_token0, address(pairContract), amountA);
        TransferHelper.safeApprove(_token1, address(pairContract), amountB);

        uint256[] memory amounts;
        amounts = new uint256[](2);
        uint256[] memory minAmounts;
        minAmounts = new uint256[](2);

        if (_token0 < _token1) {
            amounts[0] = amountA;
            amounts[1] = amountB;
        } else {
            amounts[0] = amountB;
            amounts[1] = amountA;
        }

        uint256 liquidity =
            IEmiswap(pairContract).deposit(amounts, minAmounts, defRef);
        TransferHelper.safeTransfer(address(pairContract), _to, liquidity);

        // return the change
        if (amountA < _amount0) {
            // consumed less tokens 0 than given
            TransferHelper.safeTransfer(
                _token0,
                address(msg.sender),
                _amount0.sub(amountA)
            );
        }

        if (amountB < _amount1) {
            // consumed less tokens 1 than given
            TransferHelper.safeTransfer(
                _token1,
                address(msg.sender),
                _amount1.sub(amountB)
            );
        }
    }

    /**
     * @dev Actual function that converts third-party Mooniswap liquidity (represented by LP-tokens) to our own LP-tokens
     */
    function _depositMooniswap(uint256 _pid, uint256 _amount) internal {
        IMooniswap lpToken = IMooniswap(lpTokensInfo[_pid].lpToken);
        IERC20[] memory t = lpToken.getTokens();

        // check pair existance
        IERC20 token0 = IERC20(t[0]);
        IERC20 token1 = IERC20(t[1]);

        // transfer to us
        TransferHelper.safeTransferFrom(
            address(lpToken),
            address(msg.sender),
            address(this),
            _amount
        );

        uint256 amountBefore0 = token0.balanceOf(address(this));
        uint256 amountBefore1 = token1.balanceOf(address(this));

        uint256[] memory minVals = new uint256[](2);

        lpToken.withdraw(_amount, minVals);

        // get liquidity
        uint256 amount0 = token0.balanceOf(address(this)).sub(amountBefore0);
        uint256 amount1 = token1.balanceOf(address(this)).sub(amountBefore1);

        _addOurLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            msg.sender
        );
    }

    /**
    @dev Function check for LP token pair availability. Return _pid or 0 if none exists
  */
    function isPairAvailable(address _token0, address _token1)
        public
        view
        returns (uint16)
    {
        require(_token0 != address(0), "EmiVamp: wrong token0 address");
        require(_token1 != address(0), "EmiVamp: wrong token1 address");

        for (uint16 i = 0; i < lpTokensInfo.length; i++) {
            address t0 = address(0);
            address t1 = address(0);

            if (lpTokensInfo[i].tokenType == 0) {
                IUniswapV2Pair lpt = IUniswapV2Pair(lpTokensInfo[i].lpToken);
                t0 = lpt.token0();
                t1 = lpt.token1();
            } else if (lpTokensInfo[i].tokenType == 1) {
                IMooniswap lpToken = IMooniswap(lpTokensInfo[i].lpToken);

                IERC20[] memory t = lpToken.getTokens();

                t0 = address(t[0]);
                t1 = address(t[1]);
            } else {
                return 0;
            }

            if (
                (t0 == _token0 && t1 == _token1) ||
                (t1 == _token0 && t0 == _token1)
            ) {
                return 1;
            }
        }
        return 0;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 amountA, uint256 amountB) {
        IERC20 ERC20tokenA = IERC20(tokenA);
        IERC20 ERC20tokenB = IERC20(tokenB);

        IEmiswap pairContract =
            IEmiswapRegistry(ourFactory).pools(ERC20tokenA, ERC20tokenB);
        // create the pair if it doesn't exist yet
        if (pairContract == IEmiswap(0)) {
            pairContract = IEmiswapRegistry(ourFactory).deploy(
                ERC20tokenA,
                ERC20tokenB
            );
        }

        uint256 reserveA = pairContract.getBalanceForAddition(ERC20tokenA);
        uint256 reserveB = pairContract.getBalanceForRemoval(ERC20tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal =
                EmiswapLib.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= 0,
                    "EmiswapRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal =
                    EmiswapLib.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= 0,
                    "EmiswapRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     */
    function transferAnyERC20Token(
        address tokenAddress,
        address beneficiary,
        uint256 tokens
    ) external onlyAdmin nonReentrant() returns (bool success) {
        require(
            tokenAddress != address(0),
            "EmiVamp: Token address cannot be 0"
        );
        return IERC20(tokenAddress).transfer(beneficiary, tokens);
    }
}