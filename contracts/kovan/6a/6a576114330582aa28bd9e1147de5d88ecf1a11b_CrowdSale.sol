/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

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

// File: contracts/interfaces/IEmiReferral.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface IEmiReferral {
    function l1ReferralShare() external pure returns (uint256);

    function l2ReferralShare() external pure returns (uint256);

    function l3ReferralShare() external pure returns (uint256);

    function getRefStakes()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function addReferral(address _user, address _referral) external;

    function getReferralChain(address _user)
        external
        returns (address[] memory);
}

// File: contracts/interfaces/IESW.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

/**
 * @dev Interface of the DAO token.
 */
interface IESW {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function mintClaimed(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFromVesting(uint256 amount) external;
}

// File: contracts/interfaces/IERC20Detailed.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

/**
 * @dev Interface of the DAO token.
 */
interface IERC20Detailed {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function mint(address account, uint256 amount) external;
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

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

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

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

// File: contracts/CrowdSale.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;











contract CrowdSale is Initializable, Priviledgeable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    event Buy(
        address account,
        uint256 amount,
        uint32 coinId,
        uint256 coinAmount,
        address referral
    );

    struct Coin {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint32 rate;
        uint8 status;
    }

    mapping(uint16 => Coin) internal _coins;
    mapping(address => uint16) public coinIndex;
    uint16 internal _coinCounter;
    uint32 internal _ratePrecision;
    /******************************************************************
     * _token - ESW token
     * _wethToken - WETH token
     * _uniswapFactory - uniswap factory address
     * referralStore - referral contract address
     * foundationWallet - foundation wallet
     * teamWallet - team wallet
     *******************************************************************/
    address internal _token;
    address internal _wethToken;
    address internal _uniswapFactory;
    address internal referralStore;
    address payable public foundationWallet;
    address public teamWallet;
    address internal defRef;

    // !!!In updates to contracts set new variables strictly below this line!!!
    //-----------------------------------------------------------------------------------
 string public codeVersion = "CrowdSale v1.0-137-g7fd1d69";
    uint256 public crowdSalePool = 40_000_000e18;
    bool public isStoped;

    modifier crowdSaleworking {
        require(!isStoped, "CrowdSale: stoped!");
        _;
    }

    event BuyPresale(address account, uint256 amount, uint32 sinceDate);

    //-----------------------------------------------------------------------------------
    // Smart contract Constructor
    //-----------------------------------------------------------------------------------

    function initialize(
        address eswToken,
        address uniswapFactory,
        address referralStoreInput,
        address wethToken,
        address payable _foundationWallet,
        address _teamWallet
    ) public initializer {
        require(
            eswToken != address(0) ||
                uniswapFactory != address(0) ||
                referralStoreInput != address(0) ||
                wethToken != address(0) ||
                _foundationWallet != address(0) ||
                _teamWallet != address(0),
            "Sale:Addresses empty"
        );
        _token = eswToken;
        _uniswapFactory = uniswapFactory;
        referralStore = referralStoreInput;
        _wethToken = wethToken;
        foundationWallet = _foundationWallet;
        teamWallet = _teamWallet;
        _ratePrecision = 10000;
        defRef = address(0xdF3242dE305d033Bb87334169faBBf3b7d3D96c2);
        _addAdmin(msg.sender);
    }

    /*
     * update crowdsale params
     * @param eswToken - ESW token address
     * @param uniswapFactory - uniswap factory address, for getting market rates
     * @param referralStoreInput - referral contract address
     * @param wethToken - wethToken token address
     * @param _foundationWallet - _foundationWallet wallet address
     * @param _teamWallet - _teamWallet wallet address
     * @param _defRef - _defRef wallet address
     */
    function updateParams(
        address eswToken,
        address uniswapFactory,
        address referralStoreInput,
        address wethToken,
        address payable _foundationWallet,
        address _teamWallet,
        address _defRef
    ) public onlyAdmin {
        require(
            eswToken != address(0) ||
                uniswapFactory != address(0) ||
                referralStoreInput != address(0) ||
                wethToken != address(0) ||
                _foundationWallet != address(0) ||
                _teamWallet != address(0) ||
                _defRef != address(0),
            "Sale: Addresses cannot be empty!"
        );
        _token = eswToken;
        _uniswapFactory = uniswapFactory;
        referralStore = referralStoreInput;
        _wethToken = wethToken;
        foundationWallet = _foundationWallet;
        teamWallet = _teamWallet;
        defRef = _defRef;
    }

    /**
     * stop crowdsale buy functions, need admin rights
     */
    function stopCrowdSale(bool isStopedNewValue) public onlyAdmin {
        isStoped = isStopedNewValue;
    }

    /**
     * set new crowdsale pool size
     */
    function setPoolsize(uint256 _newcrowdSalePool) public onlyAdmin {
        crowdSalePool = _newcrowdSalePool;
    }

    /*
     * register tokens in crowdsale
     * @param coinAddress - token address
     * @param rate - token rate
     * @param status - token status
     */
    function fetchCoin(
        address coinAddress,
        uint32 rate,
        uint8 status
    ) public onlyAdmin {
        require(coinIndex[coinAddress] == 0, "Already loaded");
        string memory _name = IERC20Detailed(coinAddress).name();
        string memory _symbol = IERC20Detailed(coinAddress).symbol();
        uint8 _decimals = IERC20Detailed(coinAddress).decimals();

        _coins[_coinCounter] = Coin(
            coinAddress,
            _name,
            _symbol,
            _decimals,
            1 * rate,
            status
        );
        coinIndex[coinAddress] = _coinCounter;
        _coinCounter += 1;
    }

    /*
     * set status for registered token in crowdsale
     * @param index - token index id
     * @param status - token status
     */
    function setStatusByID(uint16 coinId, uint8 status) public onlyAdmin {
        _coins[coinId].status = status;
    }

    /*
     * set rate for registered token in crowdsale
     * @param index - token index id
     * @param rate - token rate
     */
    function setRateByID(uint16 coinId, uint32 rate) public onlyAdmin {
        _coins[coinId].rate = rate;
    }

    /*
     * get ESW token address
     */
    function getToken() external view returns (address) {
        return _token;
    }

    /*
     * get tokens count
     */
    function coinCounter() public view returns (uint16) {
        return _coinCounter;
    }

    /*
     * get registered in crowdsale token's data
     * @param index - token index id
     * @return name - token name
     * @return symbol - token symbol
     * @return decimals - token decimals
     * @return status - token decimals
     */
    function coin(uint16 index)
        public
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint8 status
        )
    {
        return (
            _coins[index].name,
            _coins[index].symbol,
            _coins[index].decimals,
            _coins[index].status
        );
    }

    /*
     * get token's rate
     * @param index - token index id
     * @return rate - token rate
     */
    function coinRate(uint16 index) public view returns (uint32 rate) {
        return (_coins[index].rate);
    }

    /*
     * get token's address and status
     * @param index - token index id
     * @return coinAddress - token wallet address
     * @return status - token status (0 - inactive, 1 - active and fixed rate, 3 - active and market rate)
     */
    function coinData(uint16 index)
        public
        view
        returns (address coinAddress, uint8 status)
    {
        return (_coins[index].token, _coins[index].status);
    }

    /*
     * normalise amount to 10**18
     * @param amount - amount to normalise
     * @param coinDecimals - token decimals
     * @param isReverse - if false calc from token value, true - calc from ESW value
     * @return normalised value to result coin decimals
     */
    function _normalizeCoinAmount(
        uint256 amount,
        uint8 coinDecimals,
        bool isReverse
    ) internal pure returns (uint256) {
        if (!isReverse) {
            if (coinDecimals > 18) {
                return amount.div(uint256(10)**(coinDecimals - 18));
            }
            return amount.mul(uint256(10)**(18 - coinDecimals));
        } else {
            if (coinDecimals > 18) {
                return amount.mul(uint256(10)**(coinDecimals - 18));
            }
            return amount.div(uint256(10)**(18 - coinDecimals));
        }
    }

    /*
     * get normalised amount of result tokens
     * @param coinId - crowdsale registered token id
     * @param amount - input token amount
     * @param isReverse - if false calc from token value to ESW value, true - calc from ESW value to token value
     * @return normalised value of result tokens
     */
    function getBuyCoinAmountByID(
        uint16 coinId,
        uint256 amount,
        bool isReverse
    ) public view returns (uint256) {
        if (!isReverse) {
            return
                _normalizeCoinAmount(
                    amount.mul(_ratePrecision).div(_coins[coinId].rate),
                    _coins[coinId].decimals,
                    isReverse
                );
        } else {
            return
                _normalizeCoinAmount(
                    amount.mul(_coins[coinId].rate).div(_ratePrecision),
                    _coins[coinId].decimals,
                    isReverse
                );
        }
    }

    /**
     * Presale function, get lists of weallets, tokens and dates, and virtual freeze it.
     * Presale limits by time and working till 1612137599 (2021-01-31T23:59:59+00:00 in ISO 8601)
     * @param beneficiaries - list of beneficiaries wallets
     * @param tokens - list of ESW tokens amount bought
     * @param sinceDate - list of purchasing dates
     */
    function presaleBulkLoad(
        address[] memory beneficiaries,
        uint256[] memory tokens,
        uint32[] memory sinceDate
    ) public onlyAdmin {
        require(beneficiaries.length > 0, "Sale:Array empty");
        require(beneficiaries.length == sinceDate.length, "Sale:Arrays length");
        require(sinceDate.length == tokens.length, "Sale:Arrays length");
        require(now <= 	1613340000, "Sale: presale is over"); // 15 feb 2021 00:00 GMT

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            crowdSalePool = crowdSalePool.sub(tokens[i]);
            emit BuyPresale(beneficiaries[i], tokens[i], sinceDate[i]);
        }
    }

    /**
     * Buy ESW for tokens view,
     * @param coinAddress - payment token address
     * @param amount - payment token amount (isReverse = false), ESW token amount (isReverse = true),
     * @param isReverse - 'false' for view from payment token to ESW amount, 'true' for view from ESW amount to payment token amount
     * @return currentTokenAmount - ESW amount
     * @return coinId - crowdsale registered token id
     * @return coinAmount - rate in case of market token rate
     */
    function buyView(
        address coinAddress,
        uint256 amount,
        bool isReverse
    )
        public
        view
        returns (
            uint256 currentTokenAmount,
            uint16 coinId,
            uint256 coinAmount
        )
    {
        coinId = coinIndex[coinAddress];

        if (
            (coinAddress != _coins[coinId].token) ||
            (_coins[coinId].status == 0) ||
            (amount == 0)
        ) {
            return (currentTokenAmount, coinId, coinAmount);
        }

        // if amount is ESW
        if (isReverse && (amount.mul(105).div(100) > crowdSalePool)) {
            return (currentTokenAmount, coinId, coinAmount);
        }

        coinAmount = amount;

        currentTokenAmount = 0;

        if (_coins[coinId].status == 1) {
            currentTokenAmount = getBuyCoinAmountByID(
                coinId,
                coinAmount,
                isReverse
            );
        } else {
            // get pair pool
            address pairContract =
                IUniswapV2Factory(_uniswapFactory).getPair(
                    _coins[coinId].token,
                    _coins[0].token
                );

            if (pairContract == address(0)) {
                return (0, 0, 0);
            }

            // get pool reserves
            uint112 reserve0;
            uint112 reserve1;
            if (!isReverse) {
                (reserve0, reserve1, ) = IUniswapV2Pair(pairContract)
                    .getReserves();
            } else {
                (reserve1, reserve0, ) = IUniswapV2Pair(pairContract)
                    .getReserves();
            }

            // token0 1 : token1 10 => 1:10, coinamount=amount*10/1
            if (IUniswapV2Pair(pairContract).token1() == _coins[0].token) {
                coinAmount = _getAmountOut(amount, reserve0, reserve1);
            } else {
                coinAmount = _getAmountOut(amount, reserve1, reserve0);
            }
            currentTokenAmount = (
                isReverse
                    ? coinAmount.mul(_coins[0].rate).div(_ratePrecision)
                    : coinAmount.mul(_ratePrecision).div(_coins[0].rate)
            );
        }

        if (
            !isReverse && (currentTokenAmount.mul(105).div(100) > crowdSalePool)
        ) {
            return (0, 0, 0);
        }

        if ((currentTokenAmount == 0)) {
            return (0, 0, 0);
        }

        return (currentTokenAmount, coinId, coinAmount);
    }

    /**
     * Buy ESW for tokens,
     * @param coinAddress - payment token address
     * @param amount - payment token amount (isReverse = false), ESW token amount (isReverse = true),
     * @param referralInput - referrral address
     * @param isReverse - 'false' for view from payment token to ESW amount, 'true' for view from ESW amount to payment token amount
     */
    function buy(
        address coinAddress,
        uint256 amount,
        address referralInput,
        bool isReverse
    ) public crowdSaleworking {
        require(referralInput != msg.sender, "Sale:ref!");
        require(amount > 0, "Sale:amount needed");
        require(
            coinAddress == _coins[coinIndex[coinAddress]].token,
            "Sale:Coin not allowed"
        );
        require(
            _coins[coinIndex[coinAddress]].status != 0,
            "Sale:Coin not active"
        );

        (uint256 currentTokenAmount, uint16 coinId, ) =
            buyView(coinAddress, amount, isReverse);

        require(currentTokenAmount > 0, "Sale:0 ESW");

        uint256 eswCurrentTokenAmount;
        uint256 paymentTokenAmount;
        if (!isReverse) {
            eswCurrentTokenAmount = currentTokenAmount;
            paymentTokenAmount = amount;
        } else {
            eswCurrentTokenAmount = amount;
            paymentTokenAmount = currentTokenAmount;
        }

        require(
            eswCurrentTokenAmount.mul(105).div(100) <= crowdSalePool,
            "Sale:limit exceeded"
        );
        crowdSalePool = crowdSalePool.sub(eswCurrentTokenAmount);
        IERC20(coinAddress).safeTransferFrom(
            msg.sender,
            foundationWallet,
            paymentTokenAmount
        );

        emit Buy(
            msg.sender,
            eswCurrentTokenAmount,
            coinId,
            paymentTokenAmount,
            _saveReferrals(referralInput)
        );
    }

    /**
     * Rate input amount in base token (DAI) value with market rate
     * @param amountIn - input token amount
     * @param reserveIn - reserve of payment token
     * @param reserveOut - reserve of base USD token (DAI)
     * @return amountOut - input amount rated in base token (DAI)
     */
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Sale:_INPUT");
        require(reserveIn > 0 && reserveOut > 0, "Sale:_LIQUIDITY");
        amountOut = amountIn.mul(reserveOut).div(reserveIn);
    }

    /**
     * Buy ESW for ETH view
     * @param amount - ETH amount (isReverse=false), ESW amount (isReverse=true)
     * @param isReverse - 'false' view to calc ESW from input ETH, 'true' view to calc ETH from input ESW
     * @return currentTokenAmount - 'false' view ESW amount, 'true' view ETH amount
     * @return coinAmount - input amount rated in base token (DAI)
     */
    function buyWithETHView(uint256 amount, bool isReverse)
        public
        view
        returns (uint256 currentTokenAmount, uint256 coinAmount)
    {
        coinAmount = 0;
        currentTokenAmount = 0;

        if (amount == 0) {
            return (0, 0);
        }

        // Check ESW limits
        if (isReverse && amount.mul(105).div(100) > crowdSalePool) {
            return (0, 0);
        }

        address pairContract =
            IUniswapV2Factory(_uniswapFactory).getPair(
                _wethToken,
                _coins[0].token
            );

        if (pairContract == address(0)) {
            return (0, 0);
        }

        uint112 reserve0;
        uint112 reserve1;

        if (!isReverse) {
            (reserve0, reserve1, ) = IUniswapV2Pair(pairContract).getReserves();
        } else {
            (reserve1, reserve0, ) = IUniswapV2Pair(pairContract).getReserves();
        }

        coinAmount = (
            IUniswapV2Pair(pairContract).token1() == _coins[0].token
                ? _getAmountOut(amount, reserve0, reserve1)
                : _getAmountOut(amount, reserve1, reserve0)
        );

        currentTokenAmount = (
            isReverse
                ? coinAmount.mul(_coins[0].rate).div(_ratePrecision)
                : coinAmount.mul(_ratePrecision).div(_coins[0].rate)
        );

        if (currentTokenAmount <= 0) {
            return (0, 0);
        }

        if (
            !isReverse && currentTokenAmount.mul(105).div(100) > crowdSalePool
        ) {
            return (0, 0);
        }

        return (currentTokenAmount, coinAmount);
    }

    /**
     * @param referralInput address of referral
     * @param amount in case isReverse=false amount is ETH value, in case isReverse=true amount is ESW value
     * @param isReverse switch calc mode false - calc from ETH value, true - calc from ESW value
     * slippage - price change value from desired parameter, actual in range 0% - 5%, 5% = 500
     */
    function buyWithETH(
        address referralInput,
        uint256 amount,
        bool isReverse
    ) public payable crowdSaleworking {
        uint256 slippage = 500;

        require(referralInput != msg.sender, "Sale:ref!");

        require(
            msg.value > 0 && (!isReverse ? msg.value == amount : true),
            "Sale:ETH needed"
        );
        if (!isReverse) {
            require(msg.value == amount, "Sale:ETH needed");
        } else {
            require(amount > 0, "Sale:incorrect amount");
        }

        uint256 eswTokenAmount;
        uint256 ethTokenAmount;

        (uint256 currentTokenAmount, ) =
            buyWithETHView((!isReverse ? msg.value : amount), isReverse);

        if (!isReverse) {
            eswTokenAmount = currentTokenAmount;
            ethTokenAmount = msg.value;
        } else {
            eswTokenAmount = amount;
            ethTokenAmount = currentTokenAmount;
        }

        require(
            eswTokenAmount > 0 &&
                ethTokenAmount > 0 &&
                ethTokenAmount.mul(10000 - slippage).div(10000) <= msg.value,
            "Sale:0 ETH"
        );
        require(
            eswTokenAmount.mul(105).div(100) <= crowdSalePool,
            "Sale:limit exceeded"
        );

        crowdSalePool = crowdSalePool.sub(eswTokenAmount);
        foundationWallet.transfer(msg.value);

        emit Buy(
            msg.sender,
            eswTokenAmount,
            999,
            msg.value,
            _saveReferrals(referralInput)
        );
    }

    /**
     * save referral
     * @param referralInput address to save
     */
    function _saveReferrals(address referralInput) internal returns (address) {
        // Get referrals
        address[] memory referrals =
            IEmiReferral(referralStore).getReferralChain(msg.sender);

        if (referrals.length == 0) {
            if (address(referralInput) != address(0x0)) {
                // if have no referral and passed refferal -> set and return it
                IEmiReferral(referralStore).addReferral(
                    msg.sender,
                    referralInput
                );
                return (referralInput);
            } else {
                // if have no referral and not passed refferal -> return zero
                return (address(0));
            }
        } else {
            // already have referral -> return it
            return (referrals[0]);
        }
    }

    /**
     * default payment receive, not supported paramters, so call buyWithETH with 0x0 address with eth value
     */
    receive() external payable {
        buyWithETH(
            address(0),
            msg.value,
            false /* , 10 */ /** default slippage 0.1% */
        );
    }
}