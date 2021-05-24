/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

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

// File: contracts/interface/IERC20Usdt.sol

pragma solidity ^0.6.0;

interface IERC20Usdt {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/handlers/HandlerBase.sol

pragma solidity ^0.6.0;





abstract contract HandlerBase is Storage, Config {
    using SafeERC20 for IERC20;

    function postProcess() external payable virtual {
        revert("Invalid post process");
        /* Implementation template
        bytes4 sig = stack.getSig();
        if (sig == bytes4(keccak256(bytes("handlerFunction_1()")))) {
            // Do something
        } else if (sig == bytes4(keccak256(bytes("handlerFunction_2()")))) {
            bytes32 temp = stack.get();
            // Do something
        } else revert("Invalid post process");
        */
    }

    function _updateToken(address token) internal {
        stack.setAddress(token);
        // Ignore token type to fit old handlers
        // stack.setHandlerType(uint256(HandlerType.Token));
    }

    function _updatePostProcess(bytes32[] memory params) internal {
        for (uint256 i = params.length; i > 0; i--) {
            stack.set(params[i - 1]);
        }
        stack.set(msg.sig);
        stack.setHandlerType(HandlerType.Custom);
    }

    function getContractName() public pure virtual returns (string memory);

    function _revertMsg(string memory functionName, string memory reason)
        internal
        view
    {
        revert(
            string(
                abi.encodePacked(
                    _uint2String(_getCubeCounter()),
                    "_",
                    getContractName(),
                    "_",
                    functionName,
                    ": ",
                    reason
                )
            )
        );
    }

    function _revertMsg(string memory functionName) internal view {
        _revertMsg(functionName, "Unspecified");
    }

    function _uint2String(uint256 n) internal pure returns (string memory) {
        if (n == 0) {
            return "0";
        } else {
            uint256 len = 0;
            for (uint256 temp = n; temp > 0; temp /= 10) {
                len++;
            }
            bytes memory str = new bytes(len);
            for (uint256 i = len; i > 0; i--) {
                str[i - 1] = bytes1(uint8(48 + (n % 10)));
                n /= 10;
            }
            return string(str);
        }
    }

    function _getBalance(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (amount != uint256(-1)) {
            return amount;
        }

        // ETH case
        if (
            token == address(0) ||
            token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            return address(this).balance;
        }
        // ERC20 token case
        return IERC20(token).balanceOf(address(this));
    }

    function _tokenApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        try IERC20Usdt(token).approve(spender, amount) {} catch {
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, amount);
        }
    }
}

// File: contracts/handlers/maker/IMaker.sol

pragma solidity ^0.6.0;

interface IMakerManager {
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (bytes32);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint);
    function give(uint, address) external;
    function cdpAllow(uint, address, uint) external;
    function urnAllow(address, uint) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
    function exit(address, uint, address, uint) external;
    function quit(uint, address) external;
    function enter(address, uint) external;
    function shift(uint, uint) external;

    function count(address) external view returns (uint256);
    function first(address) external view returns (uint256);
    function last(address) external view returns (uint256);
}

interface IMakerVat {
    function can(address, address) external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) external;
    function hope(address) external;
    function move(address, address, uint) external;
}

interface IMakerGemJoin {
    function dec() external view returns (uint);
    function gem() external view returns (address);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface IMakerChainLog {
    function getAddress(bytes32) external view returns (address);
}

// File: contracts/handlers/maker/IDSProxy.sol

pragma solidity ^0.6.0;

interface IDSProxy {
    function execute(address _target, bytes calldata _data) external payable returns (bytes32 response);
    function owner() external view returns (address);
    function setAuthority(address authority_) external;
}

interface IDSProxyFactory {
    function isProxy(address proxy) external view returns (bool);
    function build() external returns (address);
    function build(address owner) external returns (address);
}

interface IDSProxyRegistry {
    function proxies(address input) external view returns (address);
    function build() external returns (address);
    function build(address owner) external returns (address);
}

// File: contracts/handlers/maker/HMaker.sol

pragma solidity ^0.6.0;





contract HMaker is HandlerBase {
    using SafeERC20 for IERC20;

    // prettier-ignore
    address public constant PROXY_REGISTRY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
    // prettier-ignore
    address public constant DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // prettier-ignore
    address public constant CHAIN_LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    modifier cdpAllowed(uint256 cdp) {
        IMakerManager manager = IMakerManager(getCdpManager());
        address owner = manager.owns(cdp);
        address sender = _getSender();
        if (
            IDSProxyRegistry(PROXY_REGISTRY).proxies(sender) != owner &&
            manager.cdpCan(owner, cdp, sender) != 1
        ) _revertMsg("General", "Unauthorized sender of cdp");
        _;
    }

    function getContractName()
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return "HMaker";
    }

    function getProxyActions() public pure virtual returns (address) {
        return 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
    }

    function getCdpManager() public pure virtual returns (address) {
        return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    }

    function getMcdJug() public view returns (address) {
        return IMakerChainLog(CHAIN_LOG).getAddress("MCD_JUG");
    }

    function openLockETHAndDraw(
        uint256 value,
        address ethJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 wadD
    ) external payable returns (uint256 cdp) {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        // if amount == uint256(-1) return balance of Proxy
        value = _getBalance(address(0), value);

        try
            proxy.execute.value(value)(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "openLockETHAndDraw(address,address,address,address,bytes32,uint256)"
                    0xe685cc04,
                    getCdpManager(),
                    getMcdJug(),
                    ethJoin,
                    daiJoin,
                    ilk,
                    wadD
                )
            )
        returns (bytes32 ret) {
            cdp = uint256(ret);
        } catch Error(string memory reason) {
            _revertMsg("openLockETHAndDraw", reason);
        } catch {
            _revertMsg("openLockETHAndDraw");
        }

        // Update post process
        bytes32[] memory params = new bytes32[](1);
        params[0] = bytes32(cdp);
        _updatePostProcess(params);
    }

    function openLockGemAndDraw(
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 wadC,
        uint256 wadD
    ) external payable returns (uint256 cdp) {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        address token = IMakerGemJoin(gemJoin).gem();

        // if amount == uint256(-1) return balance of Proxy
        wadC = _getBalance(token, wadC);

        IERC20(token).safeApprove(address(proxy), wadC);
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)"
                    0xdb802a32,
                    getCdpManager(),
                    getMcdJug(),
                    gemJoin,
                    daiJoin,
                    ilk,
                    wadC,
                    wadD,
                    true
                )
            )
        returns (bytes32 ret) {
            cdp = uint256(ret);
        } catch Error(string memory reason) {
            _revertMsg("openLockGemAndDraw", reason);
        } catch {
            _revertMsg("openLockGemAndDraw");
        }
        IERC20(token).safeApprove(address(proxy), 0);

        // Update post process
        bytes32[] memory params = new bytes32[](1);
        params[0] = bytes32(cdp);
        _updatePostProcess(params);
    }

    function safeLockETH(
        uint256 value,
        address ethJoin,
        uint256 cdp
    ) external payable {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        address owner = _getProxy(_getSender());
        // if amount == uint256(-1) return balance of Proxy
        value = _getBalance(address(0), value);

        try
            proxy.execute.value(value)(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "safeLockETH(address,address,uint256,address)"
                    0xee284576,
                    getCdpManager(),
                    ethJoin,
                    cdp,
                    owner
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("safeLockETH", reason);
        } catch {
            _revertMsg("safeLockETH");
        }
    }

    function safeLockGem(
        address gemJoin,
        uint256 cdp,
        uint256 wad
    ) external payable {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        address owner = _getProxy(_getSender());
        address token = IMakerGemJoin(gemJoin).gem();
        // if amount == uint256(-1) return balance of Proxy
        wad = _getBalance(token, wad);
        IERC20(token).safeApprove(address(proxy), wad);
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "safeLockGem(address,address,uint256,uint256,bool,address)"
                    0xead64729,
                    getCdpManager(),
                    gemJoin,
                    cdp,
                    wad,
                    true,
                    owner
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("safeLockGem", reason);
        } catch {
            _revertMsg("safeLockGem");
        }
        IERC20(token).safeApprove(address(proxy), 0);
    }

    function freeETH(
        address ethJoin,
        uint256 cdp,
        uint256 wad
    ) external payable cdpAllowed(cdp) {
        // Check msg.sender authority
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "freeETH(address,address,uint256,uint256)"
                    0x7b5a3b43,
                    getCdpManager(),
                    ethJoin,
                    cdp,
                    wad
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("freeETH", reason);
        } catch {
            _revertMsg("freeETH");
        }
    }

    function freeGem(
        address gemJoin,
        uint256 cdp,
        uint256 wad
    ) external payable cdpAllowed(cdp) {
        // Check msg.sender authority
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        address token = IMakerGemJoin(gemJoin).gem();
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "freeGem(address,address,uint256,uint256)"
                    0x6ab6a491,
                    getCdpManager(),
                    gemJoin,
                    cdp,
                    wad
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("freeGem", reason);
        } catch {
            _revertMsg("freeGem");
        }

        // Update post process
        _updateToken(token);
    }

    function draw(
        address daiJoin,
        uint256 cdp,
        uint256 wad
    ) external payable cdpAllowed(cdp) {
        // Check msg.sender authority
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "draw(address,address,address,uint256,uint256)"
                    0x9f6f3d5b,
                    getCdpManager(),
                    getMcdJug(),
                    daiJoin,
                    cdp,
                    wad
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("draw", reason);
        } catch {
            _revertMsg("draw");
        }

        // Update post process
        _updateToken(DAI_TOKEN);
    }

    function wipe(
        address daiJoin,
        uint256 cdp,
        uint256 wad
    ) external payable {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        IERC20(DAI_TOKEN).safeApprove(address(proxy), wad);
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "wipe(address,address,uint256,uint256)"
                    0x4b666199,
                    getCdpManager(),
                    daiJoin,
                    cdp,
                    wad
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("wipe", reason);
        } catch {
            _revertMsg("wipe");
        }
        IERC20(DAI_TOKEN).safeApprove(address(proxy), 0);
    }

    function wipeAll(address daiJoin, uint256 cdp) external payable {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        IERC20(DAI_TOKEN).safeApprove(address(proxy), uint256(-1));
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "wipeAll(address,address,uint256)"
                    0x036a2395,
                    getCdpManager(),
                    daiJoin,
                    cdp
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("wipeAll", reason);
        } catch {
            _revertMsg("wipeAll");
        }
        IERC20(DAI_TOKEN).safeApprove(address(proxy), 0);
    }

    function postProcess() external payable override {
        bytes4 sig = stack.getSig();
        // selector of openLockETHAndDraw(uint256,address,address,bytes32,uint256)
        // and openLockGemAndDraw(address,address,bytes32,uint256,uint256)
        if (sig == 0x5481e4a4 || sig == 0x73af24e7) {
            _transferCdp(uint256(stack.get()));
            uint256 amount = IERC20(DAI_TOKEN).balanceOf(address(this));
            if (amount > 0)
                IERC20(DAI_TOKEN).safeTransfer(_getSender(), amount);
        } else revert("Invalid post process");
    }

    function _getProxy(address user) internal returns (address) {
        return IDSProxyRegistry(PROXY_REGISTRY).proxies(user);
    }

    function _transferCdp(uint256 cdp) internal {
        IDSProxy proxy = IDSProxy(_getProxy(address(this)));
        try
            proxy.execute(
                getProxyActions(),
                abi.encodeWithSelector(
                    // selector of "giveToProxy(address,address,uint256,address)"
                    0x493c2049,
                    PROXY_REGISTRY,
                    getCdpManager(),
                    cdp,
                    _getSender()
                )
            )
        {} catch Error(string memory reason) {
            _revertMsg("_transferCdp", reason);
        } catch {
            _revertMsg("_transferCdp");
        }
    }
}

// File: contracts/handlers/bprotocol/HBProtocol.sol

pragma solidity ^0.6.0;


contract HBProtocol is HMaker {
    using SafeERC20 for IERC20;

    function getContractName() public pure override returns (string memory) {
        return "HBProtocol";
    }

    function getProxyActions() public pure override returns (address) {
        return 0x351626387B5bb5408f97F8fD6B2EC415Efc9E6a1;
    }

    function getCdpManager() public pure override returns (address) {
        return 0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed;
    }
}