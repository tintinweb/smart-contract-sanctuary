// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/ITradeOrderV2.sol";

contract OrderBook is Initializable, Ownable, ReentrancyGuard, IOrderBook {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint16 constant public _maxTradeItem = 500;
  uint16 constant public _viewCount = 50;

  // long: buy security using currency; short: buy currency using security
  // security is the base token, like btc;
  address public _security;

  // currency is the currency, like usdt;
  address public _currency;

  address public _tradeOrderImpl;
  uint48 public _expiry;

  mapping(address => OrderNode) public _orderNodeMap;
  mapping(address => OrderItem) public _orderItemMap;

  // orderHead[1] means long orderNode; orderHead[2] means short orderNode
  mapping(uint8 => address) public _orderHeads;
  mapping(uint8 => address) public _orderLasts;
  mapping(uint8 => uint16) public _nodeCounts;

  mapping(address => uint256) public _feesMap;
  address public _feeReceiver;
  uint256 public _feeRatio = 3e15;

  constructor (address security, address curency, address tradeOrderImpl, uint48 expiry) {
    require(security != address(0) && curency != address(0), "token pair should not be empty");
    require(tradeOrderImpl != address(0), "TradeOrderImpl Empty");
    _tradeOrderImpl = tradeOrderImpl;
    _security = security;
    _currency = curency;
    _expiry = expiry;
    initializeOwner();
    _feeReceiver = owner();
    _feesMap[_security] = 0;
    _feesMap[_currency] = 0;
  }
  
  function makeOrder(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) external override {
    require(position == 1 || position == 2, "makeOrder: position invalid");
    // securityAmt / currencyAmt means wanted amount, not exact amount
    require((securityAmt > 0 && currencyAmt == 0) || (currencyAmt > 0 && securityAmt == 0), "makeOrder: token amount should greater then 0");

    // opponent side position
    uint8 positionOp = __getOpponentSide(position);
    address headNodeOpAddr = _orderHeads[positionOp];

    // none opponent order
    if (headNodeOpAddr == address(0)) {
      // append an order on chain without match trades
      __bookOrder(position, price, securityAmt, currencyAmt);
    } else {
      // try to match orderNode and cover trades
      OrderNode storage currNodeOp = _orderNodeMap[headNodeOpAddr];

      uint8 pos = __compareNodePrice(positionOp, price, currNodeOp.price);
      if (pos == 1) {
        // not match any oppo orders
        __bookOrder(position, price, securityAmt, currencyAmt);
      } else {
        // price is more fit for order
        __fillOrder(position, price, securityAmt, currencyAmt);
      }
    }
    emit OrderBookMade(position, price, securityAmt, currencyAmt, msg.sender);
  }

  function killOrder(address orderItemAddr) external override {
    require(orderItemAddr != address(0), "killOrder: address invalid");
    OrderItem storage orderItem = _orderItemMap[orderItemAddr];
    address orderCreator = orderItem.orderCreator;
    require(msg.sender == orderCreator, "only order creator can kill order");

    ITradeOrderV2 tradeItem = ITradeOrderV2(orderItem.data);

    uint8 orderPosition = tradeItem.orderPosition();
    uint256 orderPrice = tradeItem.orderPrice();
    uint256 orderBalance = tradeItem.balance();

    __makeTradeOrder(tradeItem, orderPosition, 0, 0, 3);

    emit OrderBookKilled(orderPosition, orderPrice, orderBalance, orderItemAddr, msg.sender);
  }

  function findOrderNode(uint8 position, uint256 price) public view returns (bool inNode, address prevAddr, address nextAddr) {

    address _prevAddr = address(0);
    // start at the head of linked list
    address _currAddr = _orderHeads[position];
    uint16 loopCount = _nodeCounts[position];

    for (uint16 i = 0; i <= loopCount; i++) {
      if (_currAddr == address(0)) {
        prevAddr = _prevAddr;
        nextAddr = _currAddr;
        break;
      }
      OrderNode memory _currNode = _orderNodeMap[_currAddr];
      uint8 pos = __compareNodePrice(position, price, _currNode.price);
      if (pos == 1) {
        // price is prev of curr node
        inNode = false;
        prevAddr = _prevAddr;
        nextAddr = _currAddr;
        break;
      } else if (pos == 2) {
        // price match curr node
        inNode = true;
        prevAddr = _currAddr;
        nextAddr = _currNode.next;
        break;
      } else if (pos == 3) {
        // price is next of curr node
        _prevAddr = _currAddr;
        _currAddr = _currNode.next;
      }
    }
  }

  function viewOrderNode(uint8 position) external view override returns (OrderNode[50] memory) {
    OrderNode[50] memory orderNodes;
    address currAddr = _orderHeads[position];

    for (uint16 i = 0; i < _viewCount; i++) {
      if (currAddr == address(0)) {
        break;
      }
      OrderNode memory currNode = _orderNodeMap[currAddr];
      orderNodes[i] = currNode;
      currAddr = currNode.next;
    }
    return orderNodes;
  }

  function viewOrderBalance(address orderNodeAddr) external view override returns (uint256 balance, uint256 capacity) {
    require(orderNodeAddr != address(0), "view address invalid");

    OrderNode memory orderNode = _orderNodeMap[orderNodeAddr];
    address currAddr = orderNode.headItem;

    balance = 0;
    capacity = 0;
    for (uint16 i = 0; i < orderNode.itemCount; i++) {
      if (currAddr == address(0)) {
        break;
      }
      OrderItem memory currItem = _orderItemMap[currAddr];
      (, uint256 tmpB, uint256 tmpC) = __getOrderItemInfo(currAddr);
      balance = balance.add(tmpB);
      capacity = capacity.add(tmpC);
      currAddr = currItem.next;
    }
  }

  function viewOrderItem(address orderNodeAddr) external view override returns (TradeOrderItem[50] memory) {
    require(orderNodeAddr != address(0), "view address invalid");

    TradeOrderItem[50] memory orderItems;

    OrderNode memory orderNode = _orderNodeMap[orderNodeAddr];

    address currAddr = orderNode.headItem;

    for (uint16 i = 0; i < _viewCount; i++) {
      if (currAddr == address(0)) {
        break;
      }
      OrderItem memory currItem = _orderItemMap[currAddr];
      (uint8 status, uint256 balance, uint256 capacity) = __getOrderItemInfo(currAddr);
      orderItems[i] = TradeOrderItem({
        parent: currItem.parent,
        data: currItem.data,
        next: currItem.next,
        balance: balance,
        capacity: capacity,
        // created: 1, partlyFilled: 2, fullFilled: 3, canceled: 4
        status: status,
        orderCreator: currItem.orderCreator
      });
      currAddr = currItem.next;
    }
    return orderItems;
  }

  function viewTokenBalance() external view override returns (uint256 securityBalance, uint256 currencyBalance) {
    securityBalance = IERC20(_security).balanceOf(address(this));
    currencyBalance = IERC20(_currency).balanceOf(address(this));
  }

  function setTradeOrderImpl(address tradeOrderImpl) external override onlyOwner {
    require(tradeOrderImpl != address(0), "OrderBook: tradeOrderImpl cannot be 0");
    emit TradeOrderImplUpdated(_tradeOrderImpl, tradeOrderImpl);
    _tradeOrderImpl = tradeOrderImpl;
  }

  function __bookOrder(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) private {
    (bool inNode, address prevNodeAddr, address nextNodeAddr) = findOrderNode(position, price);

    if (inNode) {
      // try to append order item
      OrderNode storage currNode = _orderNodeMap[prevNodeAddr];
      address prevItemAddr = currNode.lastItem;

      address currItemAddr = __createOrderItem(position, price, securityAmt, currencyAmt);
      OrderItem storage currItem = _orderItemMap[currItemAddr];
      currItem.parent = prevNodeAddr;

      OrderItem storage prevItem = _orderItemMap[prevItemAddr];
      prevItem.next = currItemAddr;

      currNode.lastItem = currItemAddr;
      currNode.itemCount += 1;
      require(currNode.itemCount <= _maxTradeItem, "trade order item count exceed type uint16");
    } else {
      address currNodeAddr = __createOrderNode(position, price, securityAmt, currencyAmt);
      OrderNode storage currNode = _orderNodeMap[currNodeAddr];
      if (prevNodeAddr == address(0)) {
        _orderHeads[position] = currNodeAddr;
        currNode.next = nextNodeAddr;
        if (nextNodeAddr == address(0)) {
          _orderLasts[position] = currNodeAddr;
        }
      } else if (nextNodeAddr == address(0)) {
        OrderNode storage prevNode = _orderNodeMap[prevNodeAddr];
        prevNode.next = currNodeAddr;
        _orderLasts[position] = currNodeAddr;
      } else {
        OrderNode storage prevNode = _orderNodeMap[prevNodeAddr];
        prevNode.next = currNodeAddr;
        currNode.next = nextNodeAddr;
      }
      _nodeCounts[position] += 1;
    }
  }

  function __fillOrder(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) private {

    require((securityAmt > 0 && currencyAmt == 0) || (currencyAmt > 0 && securityAmt == 0), "fill order: choose either security or currency to trade");
    uint256 securityLeft = securityAmt;
    uint256 currencyLeft = currencyAmt;

    uint8 positionOp = __getOpponentSide(position);
    address currNodeAddr = _orderHeads[positionOp];
    uint16 loopCount = _nodeCounts[positionOp];

    for (uint16 i = 0; i < loopCount; i++) {
      if (currNodeAddr == address(0)) {
        break;
      }

      OrderNode memory currNode = _orderNodeMap[currNodeAddr];
      uint8 pos = __compareNodePrice(positionOp, price, currNode.price);
      if (pos == 1) {
        break;
      }

      (securityLeft, currencyLeft) = __fillMatchedOrder(position, securityLeft, currencyLeft, currNodeAddr);
      emit OrderNodeFilled(position, securityLeft, currencyLeft, currNodeAddr);

      if (securityLeft == 0 && currencyLeft == 0) {
        break;
      }

      address nextNodeAddr = currNode.next;
      currNodeAddr = nextNodeAddr;
    }
    if (securityLeft > 0 || currencyLeft > 0) {
      __bookOrder(position, price, securityLeft, currencyLeft);
    }
  }

  function __fillMatchedOrder(uint8 position, uint256 securityAmt, uint256 currencyAmt, address orderNodeOpAddr) private returns (uint256 securityLeft, uint256 currencyLeft) {

    require((securityAmt > 0 && currencyAmt == 0) || (currencyAmt > 0 && securityAmt == 0), "fill order: choose either security or currency to trade");
    securityLeft = securityAmt;
    currencyLeft = currencyAmt;

    OrderNode memory currNodeOp = _orderNodeMap[orderNodeOpAddr];
    address currItemAddr = currNodeOp.headItem;

    for (uint16 i = 0; i < currNodeOp.itemCount; i++) {
      if (currItemAddr == address(0) || (securityLeft == 0 && currencyLeft == 0)) {
        break;
      }

      OrderItem storage currItem = _orderItemMap[currItemAddr];
      (uint8 itemStatus, ,) = __getOrderItemInfo(currItemAddr);
      if (itemStatus == 3 || itemStatus == 4) {
        currItemAddr = __cleanAndMoveOrderItem(currItemAddr);
        continue;
      }

      ITradeOrderV2 tradeItem = ITradeOrderV2(currItem.data);
      uint256 securityInItem = 0;
      uint256 currencyInItem = 0;
      if (position == 1) {
        // tradeItem.position is 2
        securityInItem = tradeItem.balance();
        currencyInItem = tradeItem.capacity();
      } else if (position == 2) {
        // tradeItem.position is 1
        securityInItem = tradeItem.capacity();
        currencyInItem = tradeItem.balance();
      }
      // // partly fill order item
      // uint256 prevBalance = currItem.balance;
      // uint256 prevCapacity = currItem.capacity;

      emit OrderItemDebugger(currItem.data, securityInItem, currencyInItem, securityLeft, currencyLeft);

      if (
        (securityLeft < securityInItem && currencyLeft == 0) || (securityLeft == 0 && currencyLeft < currencyInItem)
      ) {
        // partly fill order item
        __makeTradeOrder(tradeItem, position, securityLeft, currencyLeft, 2);
        securityLeft = 0;
        currencyLeft = 0;
        break;
      } else {
        // fully fill order item
        if (position == 1) {
          __makeTradeOrder(tradeItem, position, 0, currencyInItem, 2);
        } else if (position == 2) {
          __makeTradeOrder(tradeItem, position, securityInItem, 0, 2);
        }
        // either securityLeft or currencyLeft is 0
        if (securityLeft > 0) {
          securityLeft = securityLeft.sub(securityInItem);
        }
        if (currencyLeft > 0) {
          currencyLeft = currencyLeft.sub(currencyInItem);
        }
        currItemAddr = __cleanAndMoveOrderItem(currItemAddr);
      }
    }
    if (currNodeOp.itemCount <= 0) {
      __cleanAndMoveOrderNode(currNodeOp.nodeAddr);
    }
  }

  function __createOrderNode(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) private returns (address) {
    address orderItemAddr = __createOrderItem(position, price, securityAmt, currencyAmt);
    address orderNodeAddr = orderItemAddr;

    OrderItem storage orderItem = _orderItemMap[orderItemAddr];
    orderItem.parent = orderNodeAddr;

    _orderNodeMap[orderNodeAddr] = OrderNode({
      nodeAddr: orderNodeAddr,
      position: position,
      price: price,
      // balance: balance,
      // capacity: capacity,
      next: address(0),
      headItem: orderItemAddr,
      lastItem: orderItemAddr,
      itemCount: 1
    });
    return orderNodeAddr;
  }

  // from head to last
  function __cleanAndMoveOrderNode(address orderNodeAddr) private returns (address) {
    OrderNode storage currNode = _orderNodeMap[orderNodeAddr];
    if (currNode.itemCount > 0) {
      return currNode.nodeAddr;
    }
    // require(_currNode.itemCount <= 0, "order items of current node have not cleaned");
    uint8 position = currNode.position;
    address nextNodeAddr = currNode.next;
  
    _nodeCounts[position] -= 1;
    _orderHeads[position] = nextNodeAddr;
    if (nextNodeAddr == address(0)) {
      _orderLasts[position] = address(0);
    }
    delete _orderNodeMap[orderNodeAddr];
    return nextNodeAddr;
  }

  function __createOrderItem(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) private returns (address) {
    address orderItemAddr = __createOrderBook(position, price, securityAmt, currencyAmt);

    ITradeOrderV2 tradeOrder = ITradeOrderV2(orderItemAddr);

    _orderItemMap[orderItemAddr] = OrderItem({
      parent: address(0),
      data: orderItemAddr,
      next: address(0),
      // balance: tradeOrder.balance(),
      // capacity: tradeOrder.capacity(),
      // status: tradeOrder.status(),
      orderCreator: tradeOrder.orderCreator()
    });
    return orderItemAddr;
  }

  // from head to last
  function __cleanAndMoveOrderItem(address orderItemAddr) private returns (address) {
    OrderItem storage currItem = _orderItemMap[orderItemAddr];

    address currNodeAddr = currItem.parent;
    OrderNode storage currNode = _orderNodeMap[currNodeAddr];

    address nextItemAddr = currItem.next;
    if (nextItemAddr == address(0)) {
      currNode.headItem = address(0);
      currNode.lastItem = address(0);
      currNode.itemCount = 0;
    } else {
      currNode.headItem = nextItemAddr;
      currNode.itemCount -= 1;
    }
    delete _orderItemMap[orderItemAddr];
    return nextItemAddr;
  }

  function __createOrderBook(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) private returns (address) {
    address proxyAddr = Clones.clone(_tradeOrderImpl);
    ITradeOrderV2 tradeOrder = ITradeOrderV2(proxyAddr);
    tradeOrder.initialize(
      _security,
      _currency,
      price,
      _expiry
    );
    __makeTradeOrder(tradeOrder, position, securityAmt, currencyAmt, 1);
    return proxyAddr;
  }

  function __makeTradeOrder(ITradeOrderV2 tradeOrder, uint8 position, uint256 securityAmt, uint256 currencyAmt, uint8 orderType) private {

    IERC20 token0;
    IERC20 token1;
    uint256 amount0 = 0;
    uint256 amount1 = 0;
    address transferTo;

    if (orderType == 1) {
      (token0, amount0) = tradeOrder.book(position, securityAmt, currencyAmt, msg.sender);
      if (amount0 > 0) {
        token0.safeTransferFrom(msg.sender, address(this), amount0);
      }
    } else if (orderType == 2) {
      (token0, amount0, token1, amount1, transferTo) = tradeOrder.fill(position, securityAmt, currencyAmt, msg.sender);
      if (amount0 > 0) {
        token0.safeTransferFrom(msg.sender, transferTo, amount0);
      }
    } else if (orderType == 3) {
      (token1, amount1, transferTo) = tradeOrder.kill(msg.sender);
    }
    if (amount1 > 0) {
      token1.safeTransfer(msg.sender, amount1);
    }

    emit OrderComplete(orderType, address(token0), amount0, msg.sender, address(token1), amount1, transferTo);
  }

  function __getOpponentSide(uint8 position) internal pure returns (uint8) {
    if (position == 1) {
      return 2;
    } else if (position == 2) {
      return 1;
    }
    return 0;
  }

  function __getOrderItemInfo(address orderItemAddr) internal view returns (uint8 status, uint256 balance, uint256 capacity) {
    OrderItem memory currItem = _orderItemMap[orderItemAddr];

    ITradeOrderV2 tradeItem = ITradeOrderV2(currItem.data);

    status = tradeItem.status();
    balance = tradeItem.balance();
    capacity = tradeItem.capacity();
  }

  function __compareNodePrice(uint8 position, uint256 price, uint256 cmpPrice) internal pure returns (uint8) {
    // linked list positoin: 1 prev, 2 curr, 3 next
    if (position == 1) {
      if (price > cmpPrice) {
        return 1;
      } else if (price == cmpPrice) {
        return 2;
      } else {
        return 3;
      }
    } else if (position == 2) {
      if (price < cmpPrice) {
        return 1;
      } else if (price == cmpPrice) {
        return 2;
      } else {
        return 3;
      }
    }
    return 0;
  }

  function __getFeesAmount(uint256 amount) internal view returns (uint256) {
    return amount * _feeRatio / 1e18;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOrderBook {
  event OrderBookMade(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt, address orderMaker);
  event OrderBookKilled(uint8 position, uint256 price, uint256 returnAmt, address orderAddress, address orderMaker);
  event TradeOrderImplUpdated(address oldImpl, address newImpl);
  event OrderComplete(uint8 orderType, address token0, uint256 amount0, address account0, address token1, uint256 amount1, address account1);
  event OrderNodeFilled(uint8 position, uint256 securityLeft, uint256 currencyLeft, address orderNodeAddr);
  event OrderItemDebugger(address itemAddr, uint256 securityInItem, uint256 currencyInItem, uint256 securityLeft, uint256 currencyLeft);

  struct OrderNode {
    address nodeAddr;
    uint8 position;
    uint256 price;
    // // token balance staked
    // uint256 balance;
    // // token capacity for trade
    // uint256 capacity;
    // to next orderNode by using orderNodeMap
    address next;
    // to head orderItem
    address headItem;
    // to last orderItem, fast append node
    address lastItem;
    uint16 itemCount; 
  }

  struct OrderItem {
    address parent;
    address data;
    address next;
    // uint256 balance;
    // uint256 capacity;
    // created: 1, partlyFilled: 2, fullFilled: 3, canceled: 4
    // uint8 status;
    address orderCreator;
  }

  struct TradeOrderItem {
    address parent;
    address data;
    address next;
    uint256 balance;
    uint256 capacity;
    // created: 1, partlyFilled: 2, fullFilled: 3, canceled: 4
    uint8 status;
    address orderCreator;
  }

  function makeOrder(uint8 position, uint256 price, uint256 securityAmt, uint256 currencyAmt) external;
  function killOrder(address orderItemAddr) external;
  function viewOrderNode(uint8 position) external view returns (OrderNode[50] memory);
  function viewOrderBalance(address orderNodeAddr) external view returns (uint256 balance, uint256 capacity);
  function viewOrderItem(address orderNodeAddr) external view returns (TradeOrderItem[50] memory);
  function viewTokenBalance() external view returns (uint256 securityBalance, uint256 currencyBalance);
  function setTradeOrderImpl(address tradeOrderImpl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITradeOrderV2 {

  event OrderBooked(uint8 position, address security, address currency, uint256 securityAmt, uint256 currencyAmt, address orderCreator);
  event OrderFilled(uint8 position, address security, address currency, uint256 fillerTokenAmt, uint256 bookerTokenAmt, address orderFiller, address orderCreator);
  event OrderKilled(uint8 position, address security, address currency, uint256 killedAmt, address orderCreator);

  function initialize(
    address security,
    address currency,
    uint256 price,
    uint48 expiry
  ) external;

  function book(
    uint8 position,
    // long: use currency amount, short: use security amount
    uint256 securityAmt,
    uint256 currencyAmt,
    address account
  ) external returns (IERC20 token, uint256 amount);

  function fill(
    uint8 position,
    // filler used token amount
    uint256 securityAmt,
    uint256 currencyAmt,
    // order filler
    address account
  ) external returns (IERC20 token0, uint256 amount0, IERC20 token1, uint256 amount1, address transferTo);

  function kill(address account) external returns (IERC20 token1, uint256 amount1, address transferTo);

  function balance() external view returns (uint256);

  function capacity() external view returns (uint256);

  function status() external view returns (uint8);

  function orderPosition() external view returns (uint8);

  function orderPrice() external view returns (uint256);

  function orderCreator() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

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
abstract contract Ownable is Context, Initializable {
    address private _owner;
    address private _newOwner;

    // try transfer before newOwner accept
    event OwnershipWaitingTranfer(address indexed previousOwner, address indexed newOwner);
    // newOwner accept and then transfered
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        _newOwner = address(0);
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
        _newOwner = newOwner;
        emit OwnershipWaitingTranfer(_owner, _newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the owner candidate.
     */
    function acceptOwnership() public returns (address newOwner, address oldOwner){
        address msgSender = _msgSender();
        require(_owner != msgSender, "Ownable: caller should not be old owner");
        require(_newOwner == msgSender, "Ownable: caller should be new owner candidate");
        oldOwner = owner();
        (_newOwner, _owner) = (_owner, _newOwner);
        newOwner = owner();
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function initializeReentrancyGuard () internal {
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

