/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
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
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
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
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
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

        bytes memory returndata =
            address(token).functionCall(
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

// File: contracts/interface/IProxy.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IProxy {
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    ) external payable;

    function execs(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    ) external payable;
}

// File: contracts/interface/IRegistry.sol

pragma solidity ^0.6.0;

interface IRegistry {
    function handlers(address) external view returns (bytes32);

    function callers(address) external view returns (bytes32);

    function bannedAgents(address) external view returns (uint256);

    function fHalt() external view returns (bool);

    function isValidHandler(address handler) external view returns (bool);

    function isValidCaller(address handler) external view returns (bool);
}

// File: contracts/Config.sol

pragma solidity ^0.6.0;

contract Config {
    // function signature of "postProcess()"
    bytes4 public constant POSTPROCESS_SIG = 0xc2722916;

    // The base amount of percentage function
    uint256 public constant PERCENTAGE_BASE = 1 ether;

    // Handler post-process type. Others should not happen now.
    enum HandlerType {Token, Custom, Others}
}

// File: contracts/lib/LibCache.sol

pragma solidity ^0.6.0;

library LibCache {
    function set(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        bytes32 _value
    ) internal {
        _cache[_key] = _value;
    }

    function setAddress(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        address _value
    ) internal {
        _cache[_key] = bytes32(uint256(uint160(_value)));
    }

    function setUint256(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        uint256 _value
    ) internal {
        _cache[_key] = bytes32(_value);
    }

    function getAddress(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key
    ) internal view returns (address ret) {
        ret = address(uint160(uint256(_cache[_key])));
    }

    function getUint256(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key
    ) internal view returns (uint256 ret) {
        ret = uint256(_cache[_key]);
    }

    function get(mapping(bytes32 => bytes32) storage _cache, bytes32 _key)
        internal
        view
        returns (bytes32 ret)
    {
        ret = _cache[_key];
    }
}

// File: contracts/lib/LibStack.sol

pragma solidity ^0.6.0;

library LibStack {
    function setAddress(bytes32[] storage _stack, address _input) internal {
        _stack.push(bytes32(uint256(uint160(_input))));
    }

    function set(bytes32[] storage _stack, bytes32 _input) internal {
        _stack.push(_input);
    }

    function setHandlerType(bytes32[] storage _stack, Config.HandlerType _input)
        internal
    {
        _stack.push(bytes12(uint96(_input)));
    }

    function getAddress(bytes32[] storage _stack)
        internal
        returns (address ret)
    {
        ret = address(uint160(uint256(peek(_stack))));
        _stack.pop();
    }

    function getSig(bytes32[] storage _stack) internal returns (bytes4 ret) {
        ret = bytes4(peek(_stack));
        _stack.pop();
    }

    function get(bytes32[] storage _stack) internal returns (bytes32 ret) {
        ret = peek(_stack);
        _stack.pop();
    }

    function peek(bytes32[] storage _stack)
        internal
        view
        returns (bytes32 ret)
    {
        require(_stack.length > 0, "stack empty");
        ret = _stack[_stack.length - 1];
    }
}

// File: contracts/Storage.sol

pragma solidity ^0.6.0;

/// @notice A cache structure composed by a bytes32 array
contract Storage {
    using LibCache for mapping(bytes32 => bytes32);
    using LibStack for bytes32[];

    bytes32[] public stack;
    mapping(bytes32 => bytes32) public cache;

    // keccak256 hash of "msg.sender"
    // prettier-ignore
    bytes32 public constant MSG_SENDER_KEY = 0xb2f2618cecbbb6e7468cc0f2aa43858ad8d153e0280b22285e28e853bb9d453a;

    // keccak256 hash of "cube.counter"
    // prettier-ignore
    bytes32 public constant CUBE_COUNTER_KEY = 0xf9543f11459ccccd21306c8881aaab675ff49d988c1162fd1dd9bbcdbe4446be;

    modifier isStackEmpty() {
        require(stack.length == 0, "Stack not empty");
        _;
    }

    modifier isCubeCounterZero() {
        require(_getCubeCounter() == 0, "Cube counter not zero");
        _;
    }

    modifier isInitialized() {
        require(_getSender() != address(0), "Sender is not initialized");
        _;
    }

    modifier isNotInitialized() {
        require(_getSender() == address(0), "Sender is initialized");
        _;
    }

    function _setSender() internal isNotInitialized {
        cache.setAddress(MSG_SENDER_KEY, msg.sender);
    }

    function _resetSender() internal {
        cache.setAddress(MSG_SENDER_KEY, address(0));
    }

    function _getSender() internal view returns (address) {
        return cache.getAddress(MSG_SENDER_KEY);
    }

    function _addCubeCounter() internal {
        cache.setUint256(CUBE_COUNTER_KEY, _getCubeCounter() + 1);
    }

    function _resetCubeCounter() internal {
        cache.setUint256(CUBE_COUNTER_KEY, 0);
    }

    function _getCubeCounter() internal view returns (uint256) {
        return cache.getUint256(CUBE_COUNTER_KEY);
    }
}

// File: contracts/lib/LibParam.sol

pragma solidity ^0.6.0;

library LibParam {
    bytes32 private constant STATIC_MASK =
        0x0100000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PARAMS_MASK =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 private constant REFS_MASK =
        0x00000000000000000000000000000000000000000000000000000000000000FF;
    bytes32 private constant RETURN_NUM_MASK =
        0x00FF000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant REFS_LIMIT = 22;
    uint256 private constant PARAMS_SIZE_LIMIT = 64;
    uint256 private constant RETURN_NUM_OFFSET = 240;

    function isStatic(bytes32 conf) internal pure returns (bool) {
        if (conf & STATIC_MASK == 0) return true;
        else return false;
    }

    function isReferenced(bytes32 conf) internal pure returns (bool) {
        if (getReturnNum(conf) == 0) return false;
        else return true;
    }

    function getReturnNum(bytes32 conf) internal pure returns (uint256 num) {
        bytes32 temp = (conf & RETURN_NUM_MASK) >> RETURN_NUM_OFFSET;
        num = uint256(temp);
    }

    function getParams(bytes32 conf)
        internal
        pure
        returns (uint256[] memory refs, uint256[] memory params)
    {
        require(!isStatic(conf), "Static params");
        uint256 n = REFS_LIMIT;
        while (conf & REFS_MASK == REFS_MASK && n > 0) {
            n--;
            conf = conf >> 8;
        }
        require(n > 0, "No dynamic param");
        refs = new uint256[](n);
        params = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            refs[i] = uint256(conf & REFS_MASK);
            conf = conf >> 8;
        }
        uint256 i = 0;
        for (uint256 k = 0; k < PARAMS_SIZE_LIMIT; k++) {
            if (conf & PARAMS_MASK != 0) {
                require(i < n, "Location count exceeds ref count");
                params[i] = k * 32 + 4;
                i++;
            }
            conf = conf >> 1;
        }
        require(i == n, "Location count less than ref count");
    }
}

// File: contracts/Proxy.sol

pragma solidity ^0.6.0;

/**
 * @title The entrance of Furucombo
 * @author Ben Huang
 */
contract Proxy is IProxy, Storage, Config {
    using Address for address;
    using SafeERC20 for IERC20;
    using LibParam for bytes32;

    modifier isNotBanned(address agent) {
        require(registry.bannedAgents(agent) == 0, "Banned");
        _;
    }

    modifier isNotHalted() {
        require(registry.fHalt() == false, "Halted");
        _;
    }

    IRegistry public immutable registry;

    constructor(address _registry) public {
        registry = IRegistry(_registry);
    }

    /**
     * @notice Direct transfer from EOA should be reverted.
     * @dev Callback function will be handled here.
     */
    fallback()
        external
        payable
        isNotHalted
        isNotBanned(msg.sender)
        isInitialized
    {
        // If triggered by a function call, caller should be registered in
        // registry.
        // The function call will then be forwarded to the location registered
        // in registry.
        require(_isValidCaller(msg.sender), "Invalid caller");

        address target = address(bytes20(registry.callers(msg.sender)));
        bytes memory result = _exec(target, msg.data);

        // return result for aave v2 flashloan()
        uint256 size = result.length;
        assembly {
            let loc := add(result, 0x20)
            return(loc, size)
        }
    }

    /**
     * @notice Direct transfer from EOA should be reverted.
     */
    receive() external payable {
        require(Address.isContract(msg.sender), "Not allowed from EOA");
    }

    /**
     * @notice Combo execution function. Including three phases: pre-process,
     * exection and post-process.
     * @param tos The handlers of combo.
     * @param configs The configurations of executing cubes.
     * @param datas The combo datas.
     */
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    ) external payable override isNotHalted isNotBanned(msg.sender) {
        _preProcess();
        _execs(tos, configs, datas);
        _postProcess();
    }

    /**
     * @notice The execution interface for callback function to be executed.
     * @dev This function can only be called through the handler, which makes
     * the caller become proxy itself.
     */
    function execs(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    )
        external
        payable
        override
        isNotHalted
        isNotBanned(msg.sender)
        isInitialized
    {
        require(msg.sender == address(this), "Does not allow external calls");
        _execs(tos, configs, datas);
    }

    /**
     * @notice The execution phase.
     * @param tos The handlers of combo.
     * @param configs The configurations of executing cubes.
     * @param datas The combo datas.
     */
    function _execs(
        address[] memory tos,
        bytes32[] memory configs,
        bytes[] memory datas
    ) internal {
        bytes32[256] memory localStack;
        uint256 index = 0;

        require(
            tos.length == datas.length,
            "Tos and datas length inconsistent"
        );
        require(
            tos.length == configs.length,
            "Tos and configs length inconsistent"
        );
        for (uint256 i = 0; i < tos.length; i++) {
            bytes32 config = configs[i];
            // Check if the data contains dynamic parameter
            if (!config.isStatic()) {
                // If so, trim the exectution data base on the configuration and stack content
                _trim(datas[i], config, localStack, index);
            }
            // Check if the output will be referenced afterwards
            bytes memory result = _exec(tos[i], datas[i]);
            if (config.isReferenced()) {
                // If so, parse the output and place it into local stack
                uint256 num = config.getReturnNum();
                uint256 newIndex = _parse(localStack, result, index);
                require(
                    newIndex == index + num,
                    "Return num and parsed return num not matched"
                );
                index = newIndex;
            }

            // Setup the process to be triggered in the post-process phase
            _setPostProcess(tos[i]);
        }
    }

    /**
     * @notice Trimming the execution data.
     * @param data The execution data.
     * @param config The configuration.
     * @param localStack The stack the be referenced.
     * @param index Current element count of localStack.
     */
    function _trim(
        bytes memory data,
        bytes32 config,
        bytes32[256] memory localStack,
        uint256 index
    ) internal pure {
        // Fetch the parameter configuration from config
        (uint256[] memory refs, uint256[] memory params) = config.getParams();
        // Trim the data with the reference and parameters
        for (uint256 i = 0; i < refs.length; i++) {
            require(refs[i] < index, "Reference to out of localStack");
            bytes32 ref = localStack[refs[i]];
            uint256 offset = params[i];
            uint256 base = PERCENTAGE_BASE;
            assembly {
                let loc := add(add(data, 0x20), offset)
                let m := mload(loc)
                // Adjust the value by multiplier if a dynamic parameter is not zero
                if iszero(iszero(m)) {
                    // Assert no overflow first
                    let p := mul(m, ref)
                    if iszero(eq(div(p, m), ref)) {
                        revert(0, 0)
                    } // require(p / m == ref)
                    ref := div(p, base)
                }
                mstore(loc, ref)
            }
        }
    }

    /**
     * @notice Parse the return data to the local stack.
     * @param localStack The local stack to place the return values.
     * @param ret The return data.
     * @param index The current tail.
     */
    function _parse(
        bytes32[256] memory localStack,
        bytes memory ret,
        uint256 index
    ) internal pure returns (uint256 newIndex) {
        uint256 len = ret.length;
        // The return value should be multiple of 32-bytes to be parsed.
        require(len % 32 == 0, "illegal length for _parse");
        // Estimate the tail after the process.
        newIndex = index + len / 32;
        require(newIndex <= 256, "stack overflow");
        assembly {
            let offset := shl(5, index)
            // Store the data into localStack
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(localStack, add(i, offset)),
                    mload(add(add(ret, i), 0x20))
                )
            }
        }
    }

    /**
     * @notice The execution of a single cube.
     * @param _to The handler of cube.
     * @param _data The cube execution data.
     */
    function _exec(address _to, bytes memory _data)
        internal
        returns (bytes memory result)
    {
        require(_isValidHandler(_to), "Invalid handler");
        _addCubeCounter();
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _to,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            result := mload(0x40)
            mstore(
                0x40,
                add(result, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(result, size)
            returndatacopy(add(result, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    revert(add(result, 0x20), size)
                }
        }
    }

    /**
     * @notice Setup the post-process.
     * @param _to The handler of post-process.
     */
    function _setPostProcess(address _to) internal {
        // If the stack length equals 0, just skip
        // If the top is a custom post-process, replace it with the handler
        // address.
        if (stack.length == 0) {
            return;
        } else if (
            stack.peek() == bytes32(bytes12(uint96(HandlerType.Custom)))
        ) {
            stack.pop();
            // Check if the handler is already set.
            if (bytes4(stack.peek()) != 0x00000000) stack.setAddress(_to);
            stack.setHandlerType(HandlerType.Custom);
        }
    }

    /// @notice The pre-process phase.
    function _preProcess() internal virtual isStackEmpty isCubeCounterZero {
        // Set the sender.
        _setSender();
    }

    /// @notice The post-process phase.
    function _postProcess() internal {
        // If the top of stack is HandlerType.Custom (which makes it being zero
        // address when `stack.getAddress()`), get the handler address and execute
        // the handler with it and the post-process function selector.
        // If not, use it as token address and send the token back to user.
        while (stack.length > 0) {
            address addr = stack.getAddress();
            if (addr == address(0)) {
                addr = stack.getAddress();
                _exec(addr, abi.encodeWithSelector(POSTPROCESS_SIG));
            } else {
                uint256 amount = IERC20(addr).balanceOf(address(this));
                if (amount > 0) IERC20(addr).safeTransfer(msg.sender, amount);
            }
        }

        // Balance should also be returned to user
        uint256 amount = address(this).balance;
        if (amount > 0) msg.sender.transfer(amount);

        // Reset the msg.sender and cube counter
        _resetSender();
        _resetCubeCounter();
    }

    /// @notice Check if the handler is valid in registry.
    function _isValidHandler(address handler) internal view returns (bool) {
        return registry.isValidHandler(handler);
    }

    /// @notice Check if the caller is valid in registry.
    function _isValidCaller(address caller) internal view returns (bool) {
        return registry.isValidCaller(caller);
    }
}