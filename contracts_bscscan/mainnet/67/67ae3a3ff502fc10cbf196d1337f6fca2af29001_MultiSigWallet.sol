/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


interface IRequestApproval {

    event RequestCreated(bytes32 indexed requestId, string details, bytes4 signature, bytes args, address indexed sender);
    event RequestCompleted(bytes32 indexed requestId);
    event RequestApproved(bytes32 indexed requestId, address indexed account, address indexed sender);
    event RequestRejected(bytes32 indexed requestId, address indexed account, address indexed sender);

    struct Request {
        bool created;
        bool completed;
        bytes4 signature;
        uint256 totalApprovers;
        bytes args;
        string details;
        address[] approvers;
    }

    function totalRequests() external view returns (uint256);
    function lastRequestId() external view returns (bytes32);
    function lastRequest() external view returns (Request memory);
    function requiredApprovals() external view returns (uint256);
    function isValidApprover(address account) external view returns (bool);
}


abstract contract RequestApproval is IRequestApproval {
    using SafeMath for uint256;

    uint256 public override totalRequests;
    bytes32 public override lastRequestId;

    mapping(bytes32 => Request) public request;
    mapping(bytes32 => mapping(address => bool)) public approved;

    function lastRequest() external view override returns (Request memory) {
        return request[lastRequestId];
    }

    function requiredApprovals() public view override virtual returns (uint256);

    function isValidApprover(address account) public view override virtual returns (bool);

    function _callback(bytes4 signature, bytes memory args) internal virtual;

    function _createRequest(bytes4 signature, bytes memory args, string memory details) internal returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, details, totalRequests++));

        Request storage req = request[requestId];

        require(!req.created, 'RequestApproval: requestId has already been taken');

        req.created = true;
        req.details = details;
        req.args = args;
        req.signature = signature;

        lastRequestId = requestId;

        emit RequestCreated(requestId, details, signature, args, msg.sender);

        return requestId;
    }

    function _approve(bytes32 requestId, address account) internal {
        require(request[requestId].created, 'RequestApproval: this requestId has not been created');
        require(!request[requestId].completed, 'RequestApproval: this requestId has already been completed');
        require(isValidApprover(account), 'RequestApproval: this account is not a valid account.');

        Request storage req = request[requestId];

        if (!approved[requestId][account]) {
            approved[requestId][account] = true;
            req.totalApprovers = req.totalApprovers.add(1);
            req.approvers.push(account);

            emit RequestApproved(requestId, account, msg.sender);
        }

        uint i = 0;
        while (i < req.approvers.length) {
            if (!isValidApprover(req.approvers[i])) {
                _reject(requestId, req.approvers[i]);
            } else {
                i++;
            }
        }

        if (req.totalApprovers >= requiredApprovals()) {
            _callback(req.signature, req.args);
            req.completed = true;
            emit RequestCompleted(requestId);
        }
    }

    function _reject(bytes32 requestId, address account) internal {
        require(request[requestId].created, 'RequestApproval: this requestId has not been created');
        require(!request[requestId].completed, 'RequestApproval: this requestId has already been completed');
        require(approved[requestId][account], 'RequestApproval: the account has not approved this requestId');

        approved[requestId][account] = false;
        request[requestId].totalApprovers = request[requestId].totalApprovers.sub(1);
        request[requestId].approvers = _removeAccountFromArray(request[requestId].approvers, account);

        emit RequestRejected(requestId, account, msg.sender);
    }

    function _signature(string memory key) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(key)));
    }

    function _removeAccountFromArray(address[] memory accounts, address account) private pure returns (address[] memory) {
        address[] memory newAccounts = new address[](accounts.length - 1);

        uint j = 0;
        for (uint i = 0; i < accounts.length; i++) {
            if (accounts[i] != account) {
                newAccounts[j] = accounts[i];
                j++;
            }
        }

        return newAccounts;
    }
}

interface IAdminControl {

    event AddAdminRequested(bytes32 indexed requestId, address indexed account, address indexed sender);
    event RevokeAdminRequested(bytes32 indexed requestId, address indexed account, address indexed sender);
    event UpdateRequestApprovalsRequested(bytes32 indexed requestId, uint256 amount, address indexed sender);

    event AdminAdded(address indexed account);
    event AdminRevoked(address indexed account);
    event RequiredApprovalsUpdated(uint256 prevAmount, uint256 newAmount);

    function totalAdmins() external view returns (uint256);

    function addAdmin(address account) external returns (bytes32 requestId);

    function revokeAdmin(address account) external returns (bytes32 requestId);

    function updateRequiredApprovals(uint256 newRequiredApprovals) external returns (bytes32 requestId);
}

abstract contract AdminControl is IAdminControl, RequestApproval {
    using SafeMath for uint256;

    uint256 public override totalAdmins;
    uint256 private _requiredApprovals;
    
    bytes4 private immutable ADD_ADMIN = _signature('_addAdmin(address)');
    bytes4 private immutable REVOKE_ADMIN = _signature('_revokeAdmin(address)');
    bytes4 private immutable SET_APPROVALS = _signature('_setApprovals(uint256)');

    mapping(address => bool) public admin;

    constructor(address[] memory initialAdminAccounts, uint256 _minApprovals) {
        for (uint i = 0; i < initialAdminAccounts.length; i++) {
            _addAdmin(initialAdminAccounts[i]);
        }

        _requiredApprovals = _minApprovals;
    }

    modifier onlyAdmin {
        require(admin[msg.sender], 'AdminControl: this account is not an admin');
        _;
    }

    function addAdmin(address account) external onlyAdmin override returns (bytes32 requestId) {
        require(!admin[account], "This account is already an admin");

        requestId = _createRequest(
            ADD_ADMIN,
            abi.encode(account),
            string(abi.encodePacked(
                "Request to add admin account ",
                Strings.toHexString(uint160(account), 20)
            ))
        );

        emit AddAdminRequested(requestId, account, msg.sender);
    }

    function revokeAdmin(address account) external onlyAdmin override returns (bytes32 requestId) {
        require(admin[account], "This account is not an admin");

        requestId = _createRequest(
            REVOKE_ADMIN,
            abi.encode(account),
            string(abi.encodePacked(
                "Request to revoke admin account ",
                Strings.toHexString(uint160(account), 20)
            ))
        );

        emit RevokeAdminRequested(requestId, account, msg.sender);
    }

    function updateRequiredApprovals(uint256 newRequiredAmount) external onlyAdmin override returns (bytes32 requestId) {
        require(newRequiredAmount <= totalAdmins, "New approval amount must be less than the total admins");

        requestId = _createRequest(
            SET_APPROVALS,
            abi.encode(newRequiredAmount),
            string(abi.encodePacked(
                "Request to change the requiredApprovals from ",
                Strings.toString(requiredApprovals()),
                " to ",
                Strings.toString(newRequiredAmount)
            ))
        );

        emit UpdateRequestApprovalsRequested(requestId, newRequiredAmount, msg.sender);
    }

    function requiredApprovals() public view override returns (uint256) {
        return _requiredApprovals < totalAdmins ? _requiredApprovals : totalAdmins;
    }

    function isValidApprover(address account) public view override returns (bool) {
        return admin[account];
    }

    function _addAdmin(address account) private {
        require(!admin[account], "This account is already an admin");

        admin[account] = true;
        totalAdmins = totalAdmins.add(1);

        emit AdminAdded(account);
    }

    function _revokeAdmin(address account) private {
        require(admin[account], "This account is not an admin");

        admin[account] = false;
        totalAdmins = totalAdmins.sub(1);

        emit AdminRevoked(account);
    }

    function _setApprovals(uint256 amount) private {
        uint256 prevAmount = requiredApprovals();
        _requiredApprovals = amount;
        emit RequiredApprovalsUpdated(prevAmount, amount);
    }
    
    function _callback(bytes4 signature, bytes memory args) internal virtual override {
        address account;
        
        if (signature == ADD_ADMIN) {
            (account) = abi.decode(args, (address));
            _addAdmin(account);
        }
        else if (signature == REVOKE_ADMIN) {
            (account) = abi.decode(args, (address));
            _revokeAdmin(account);
        }
        else if (signature == SET_APPROVALS) {
            uint256 newApprovals;
            (newApprovals) = abi.decode(args, (uint256));
            _setApprovals(newApprovals);
        }
    }
}

interface IMultiSigWallet {

    event TokenTransferRequested(bytes32 indexed requestId, address to, uint256 amount, address tokenAddress, string reason, address indexed sender);
    event TransferRequested(bytes32 indexed requestId, address to, uint256 amount, string reason, address indexed sender);
    event FunctionCallRequested(bytes32 indexed requestId, address target, bytes data, string reason, address indexed sender);
    event Transfer(address to, uint256 amount, address tokenAddress, string reason);
    event FunctionCall(address target, bytes data, string reason);
    event FundsReceived(uint256 amount, address sender);

    function approve(bytes32 requestId) external;
    function reject(bytes32 requestId) external;

    function transferToken(address to, uint256 amount, address tokenAddress, string memory reason) external returns (bytes32 requestId);
    function transfer(address to, uint256 amount, string memory reason) external returns (bytes32 requestId);
    function functionCall(address target, bytes memory data, string memory reason) external returns (bytes32 requestId);
    function balance() external view returns (uint256);
    function tokenBalance(address tokenAddress) external view returns (uint256);
}

contract MultiSigWallet is IMultiSigWallet, AdminControl {
    using SafeERC20 for IERC20;
    using Address for address;
    
    bytes4 private immutable TRANSFER = _signature('_transfer(address,uint256,address)');
    bytes4 private immutable FUNCTION_CALL = _signature('_functionCall(address,bytes)');

    constructor(address[] memory initialAdminAccounts, uint256 minApprovers) AdminControl(initialAdminAccounts, minApprovers) {
    }
    
    receive() external payable {
        emit FundsReceived(msg.value, msg.sender);
    }
    
    function balance() external view override returns (uint256) {
        return address(this).balance;
    }
    
    function tokenBalance(address tokenAddress) external view override returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function approve(bytes32 requestId) external override onlyAdmin {
        _approve(requestId, msg.sender);
    }

    function reject(bytes32 requestId) external override onlyAdmin {
        _reject(requestId, msg.sender);
    }

    function transferToken(address to, uint256 amount, address tokenAddress, string memory reason) external onlyAdmin override returns (bytes32 requestId) {
        require(amount > 0, 'MultiSigWallet: please transfer more than 0 amount');
        require(tokenAddress != address(0), 'MultiSigWallet: tokenAddress is zero');
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "MultiSigWallet: this wallet does not have enough funds.");

        requestId = _createRequest(
            TRANSFER,
            abi.encode(to, amount, tokenAddress, reason),
            string(abi.encodePacked(
                "Transfer ",
                Strings.toString(amount),
                " Tokens (",
                Strings.toHexString(uint160(tokenAddress), 20),
                ") to ",
                Strings.toHexString(uint160(to), 20),
                " for ",
                reason
            ))
        );

        emit TokenTransferRequested(requestId, to, amount, tokenAddress, reason, msg.sender);
    }

    function transfer(address to, uint256 amount, string memory reason) external onlyAdmin override returns (bytes32 requestId) {
        require(amount > 0, 'MultiSigWallet: please transfer more than 0 amount');
        require(address(this).balance >= amount, "MultiSigWallet: this wallet does not have enough funds.");

        requestId = _createRequest(
            TRANSFER,
            abi.encode(to, amount, address(0), reason),
            string(abi.encodePacked(
                "Transfer ",
                Strings.toString(amount),
                " ETH to ",
                Strings.toHexString(uint160(to), 20),
                " for: ",
                reason
            ))
        );

        emit TransferRequested(requestId, to, amount, reason, msg.sender);
    }

    function functionCall(address target, bytes memory data, string memory reason) external override onlyAdmin returns (bytes32 requestId) {
        require(target != address(0), 'MultiSigWallet: cannot call 0 address');
        require(target != address(this), 'MultiSigWallet: cannot call self');

        requestId = _createRequest(
            FUNCTION_CALL,
            abi.encode(target, data, reason),
            string(abi.encodePacked(
                "External call to external function ",
                Strings.toHexString(uint160(target), 20),
                " for ",
                reason
            ))
        );

        emit FunctionCallRequested(requestId, target, data, reason, msg.sender);
    }

    function _transfer(address to, uint256 amount, address tokenAddress, string memory reason) private {
        if (tokenAddress == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(to, amount);
        }

        emit Transfer(to, amount, tokenAddress, reason);
    }

    function _functionCall(address target, bytes memory data, string memory reason) private {
        target.functionCall(data);

        emit FunctionCall(target, data, reason);
    }
    
    function _callback(bytes4 signature, bytes memory args) internal override {
        string memory reason;

        if (signature == TRANSFER) {
            address to;
            uint256 amount;
            address tokenAddress;
            (to, amount, tokenAddress, reason) = abi.decode(args, (address, uint256, address, string));
            _transfer(to, amount, tokenAddress, reason);
        } else if (signature == FUNCTION_CALL) {
            address target;
            bytes memory targetArgs;
            (target, targetArgs, reason) = abi.decode(args, (address, bytes, string));
            _functionCall(target, targetArgs, reason);
        } else {
            super._callback(signature, args);
        }
    }
}