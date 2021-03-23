/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @kyber.network/utils-sc/contracts/PermissionGroups.sol

pragma solidity 0.6.6;

contract PermissionGroups {
    uint256 internal constant MAX_GROUP_SIZE = 50;

    address public admin;
    address public pendingAdmin;
    mapping(address => bool) internal operators;
    mapping(address => bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    event OperatorAdded(address newOperator, bool isAdd);

    event AlerterAdded(address newAlerter, bool isAdd);

    constructor(address _admin) public {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender], "only alerter");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function getAlerters() external view returns (address[] memory) {
        return alertersGroup;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter], "alerter exists"); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE, "max alerters");

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter(address alerter) public onlyAdmin {
        require(alerters[alerter], "not alerter");
        alerters[alerter] = false;

        for (uint256 i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.pop();
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




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

// File: contracts/libraries/UniERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




/// source: https://github.com/CryptoManiacsZone/1inchProtocol/blob/591a0b4910567abd2f2fcbbf8b85fa3a089d5650/contracts/libraries/UniERC20.sol
library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function isETH(IERC20 token) internal pure returns (bool) {
        return token == ETH_ADDRESS;
    }

    function eq(IERC20 tokenA, IERC20 tokenB) internal pure returns (bool) {
        return (isETH(tokenA) && isETH(tokenB)) || (tokenA == tokenB);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "UniERC20: failed to transfer eth to target");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function uniTransferFromSender(
        IERC20 token,
        address target,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(msg.value >= amount, "UniERC20: not enough value");
            if (target != address(this)) {
                (bool success, ) = target.call{value: amount}("");
                require(success, "UniERC20: failed to transfer eth to target");
            }
            if (msg.value > amount) {
                // Return remainder if exist
                (bool success, ) = msg.sender.call{value: msg.value - amount}("");
                require(success, "UniERC20: failed to transfer back eth");
            }
        } else {
            token.safeTransferFrom(msg.sender, target, amount);
        }
    }

    function uniApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (isETH(token)) {
            return;
        }

        if (amount == 0) {
            token.safeApprove(to, 0);
            return;
        }

        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function uniDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("DECIMALS()"));
        }

        return success ? abi.decode(data, (uint8)) : 18;
    }

    function uniSymbol(IERC20 token) internal view returns (string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("symbol()"));
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSignature("SYMBOL()"));
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint256 i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns (string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns (string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint256 j = 2;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 a = uint8(data[i]) >> 4;
            uint256 b = uint8(data[i]) & 0x0f;
            str[j++] = bytes1(uint8(a + 48 + (a / 10) * 39));
            str[j++] = bytes1(uint8(b + 48 + (b / 10) * 39));
        }

        return string(str);
    }
}

// File: contracts/libraries/Tree.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Tree {
    bytes32 public constant NULL_NODE = 0;

    function merkleBytes32Arr(bytes32[] memory miniBlockHashes) internal pure returns (bytes32) {
        uint256 size = miniBlockHashes.length;
        bytes32[] memory tmpMiniBlockHashes = miniBlockHashes;
        while (size != 1) {
            for (uint256 i = 0; i * 2 < size; i++) {
                if (i * 2 == size - 1) {
                    tmpMiniBlockHashes[i] = sha256(abi.encodePacked(tmpMiniBlockHashes[i * 2], NULL_NODE));
                } else {
                    tmpMiniBlockHashes[i] = sha256(
                        abi.encodePacked(tmpMiniBlockHashes[i * 2], tmpMiniBlockHashes[i * 2 + 1])
                    );
                }
            }
            size = (size + 1) / 2;
        }
        return tmpMiniBlockHashes[0];
    }
}

// File: contracts/libraries/BitStream.sol

pragma solidity ^0.6.0;

/// @dev based on https://github.com/ethereum/solidity-examples/blob/master/src/bytes/Bytes.sol
library BitStream {
    uint256 internal constant WORD_SIZE = 256;

    /// @dev unsafe wrapper to get dataPtr
    function getPtr(bytes memory data) internal pure returns (uint256 dataPtr) {
        assembly {
            dataPtr := add(data, 32)
        }
    }

    /// @param self pointer to memory source to read
    /// @param offset number of bits is skipped
    /// @param len number of bit to read
    /// @dev this function suppose to use in memory <= 1 word
    function readBits(
        uint256 self,
        uint256 offset,
        uint256 len
    ) internal pure returns (uint256 out) {
        self += offset / 8;
        offset = offset % 8;
        require(len + offset <= WORD_SIZE, "too much bytes");
        uint256 endOffset = WORD_SIZE - offset - len;
        uint256 mask = ((1 << len) - 1) << (endOffset);
        assembly {
            out := and(mload(self), mask)
            out := shr(endOffset, out)
        }
    }

    /// @param self pointer to memory source to write
    /// @param data data to write
    /// @param offset number of bits is skipped
    /// @param len number of bit to write
    /// @dev this function suppose to use in memory <= 1 word
    function writeBits(
        uint256 self,
        uint256 data,
        uint256 offset,
        uint256 len
    ) internal pure {
        self += offset / 8;
        offset = offset % 8;
        require(len + offset <= WORD_SIZE, "too much bytes");
        uint256 endOffset = WORD_SIZE - offset - len;
        data = data << endOffset;
        uint256 mask = ((1 << len) - 1) << (endOffset);
        assembly {
            let destpart := and(mload(self), not(mask))
            mstore(self, or(destpart, data))
        }
    }

    function copyBits(
        uint256 self,
        uint256 src,
        uint256 srcOffset,
        uint256 dstOffset,
        uint256 len
    ) internal pure {
        uint256 data = readBits(src, srcOffset, len);
        writeBits(self, data, dstOffset, len);
    }
}

// File: contracts/Deserializer.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Deserializer {
    enum OpType {
        NotSubmittedTx,
        Swap1,
        Swap2,
        AddLiquidity,
        RemoveLiquidity,
        HiddenTx,
        DepositToNew,
        Deposit,
        Withdraw,
        Exit
    }

    uint256 internal constant NOT_SUBMITTED_BYTES_SIZE = 1;
    uint256 internal constant SWAP_BYTES_SIZE = 11;
    uint256 internal constant ADD_LIQUIDITY_BYTES_SIZE = 16;
    uint256 internal constant REMOVE_LIQUIDITY_BYTES_SIZE = 11;
    uint256 internal constant TX_COMMITMENT_SIZE = 32;

    uint256 internal constant DEPOSIT_BYTES_SIZE = 6;
    uint256 internal constant WITHDRAW_BYTES_SIZE = 13;
    uint256 internal constant OPERATION_COMMITMENT_SIZE = 32;
}

// File: contracts/interface/ILayer2.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ILayer2 {
    function getBatchRoot(uint256 batchNumber) external view returns (bytes32 batchRoot);

    function lastestBatch() external view returns (bytes32 batchRoot, uint256 batchNumber);
}

// File: contracts/interface/IZkVerifier.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IZkVerifier {
    function verifyBlockProof(
        uint256[] calldata _proof,
        bytes32 _commitment,
        uint32 _chunks
    ) external view returns (bool);
}

// File: contracts/L2.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;











// import "hardhat/console.sol";
// import "./libraries/BytesDebugger.sol";

contract L2 is ILayer2, Deserializer, PermissionGroups, ReentrancyGuard {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    uint48 private constant MAX_DEPOSIT_ID = 2**44 - 1;
    uint256 private constant MAX_TOKEN_ID = 2**10 - 1;
    uint256 private constant MAX_ACCOUNT_ID = 2**32 - 1;
    // TODO: review below constants
    uint32 private constant NUM_CHUNKS = 32;
    uint256 private constant NUM_TX_IN_BLOCKS = 8;
    uint256 private constant NUM_BLOCKS_IN_BATCH = 4;

    enum BatchStatus {NOT_SUBMITTED, SUBMITTED, CONFIRMED, FINALIZED, REVERT}

    struct BatchCallData {
        bytes[] operationData;
        bytes[] txData;
        bytes[] hiddenTxData;
        bytes32[] stateHashes;
    }

    struct BatchData {
        bytes32 batchRoot;
        BatchStatus status;
        uint64 submitBlockTime;
    }

    struct TokenData {
        bool isListed;
        bool isEnabled;
        uint16 tokenID;
        uint256 minDepositAmount;
    }

    /// @dev size = 224 < 1 word
    struct WithdrawRequest {
        uint16 tokenID;
        uint32 accountID;
        uint32 amountMantisa;
        uint8 amountExp;
        uint32 batchNumber;
        bool isCompleted;
    }

    struct ExitRequest {
        uint256 timeStamp;
        bool isConfirmed;
        address withdrawTo;
        bytes32 balanceRoot;
    }

    // TODO: emit finalize event
    struct AccountData {
        bool isAdded;
        uint32 accountID;
    }

    event TokenListed(IERC20 indexed token, uint16 tokenID, uint256 minDepositAmount);

    event TokenEnabled(IERC20 indexed token, bool isEnabled);

    event MinDepositSet(IERC20 indexed token, uint256 minDepositAmount);

    event SubmitDeposit(uint32 indexed accountID, uint48 depositID, uint16 tokenID, uint256 amount);

    event SubmitDepositToNew(
        address indexed withdrawTo,
        uint48 depositID,
        bytes32 pubKey,
        uint256 accountID,
        uint16 tokenID,
        uint256 amount
    );

    event SubmitBatch(uint32 indexed batchNumber, bytes32 blockDataHash, bytes32 batchRoot);

    event SubmitZkProof(
        uint32 indexed startBlock,
        uint32 indexed endBlock,
        uint256 zkProofDataID,
        bytes32 zkProofHash
    );

    event SubmitExit(uint32 indexed accountID);

    event CompleteExit(uint32 indexed accountID, uint16 tokenID, uint256 amount);

    event CompleteWithdraw(
        uint256 indexed withdrawID,
        uint32 indexed accountID,
        address indexed destAddress,
        uint16 tokenID,
        uint256 amount
    );

    // Chain of batch, each contains batchRoot
    mapping(uint256 => BatchData) public batches;
    uint256 public batchesLength;
    uint256 public lastFinalizedBatchID = 0;

    // List of token, and map from address to ID
    IERC20[] internal tokens;
    mapping(IERC20 => TokenData) public tokenInfos;

    //deposit data
    uint48 public numDeposits;
    uint48 public numIncludedDeposits;
    mapping(uint48 => bytes32) public depositHashes;

    //withdraw data
    uint256 public numWithdraws;
    mapping(uint256 => WithdrawRequest) public withdrawRequests;

    // exit data
    mapping(uint32 => ExitRequest) public exitRequests;
    mapping(uint32 => mapping(uint16 => bool)) public isCompleteExits;

    // account data
    uint32 public numOccupiedAccounts;
    mapping(bytes32 => AccountData) public pubKeyToAccountData;
    mapping(uint32 => address) public withdrawAddresses;

    // sha256 of all validators
    bytes32 public immutable validatorsPubkeyRoot;
    IZkVerifier public immutable verifier;

    /// @dev constructor also create the 1st account where fee will transfer to
    constructor(
        address _admin,
        bytes32 _adminPubKey,
        address _adminWithdrawTo,
        bytes32 _validatorsPubkeyRoot,
        bytes32 genesisRoot,
        IZkVerifier _verifier
    ) public PermissionGroups(_admin) {
        batches[0].batchRoot = genesisRoot;
        batches[0].status = BatchStatus.FINALIZED;
        batches[0].submitBlockTime = uint64(block.timestamp);
        batchesLength = 1;
        validatorsPubkeyRoot = _validatorsPubkeyRoot;
        verifier = _verifier;
        // create the 1st account
        numOccupiedAccounts = 1;
        pubKeyToAccountData[_adminPubKey] = AccountData({isAdded: true, accountID: 0});
        withdrawAddresses[0] = _adminWithdrawTo;
    }

    receive() external payable {}

    function listToken(IERC20 _token, uint256 _minDepositAmount) external onlyAdmin {
        listTokenInternal(_token, _minDepositAmount);

        emit MinDepositSet(_token, _minDepositAmount);
    }

    function setMinDepositAmount(IERC20 _token, uint256 _minDepositAmount) external onlyAdmin {
        tokenInfos[_token].minDepositAmount = _minDepositAmount;

        emit MinDepositSet(_token, _minDepositAmount);
    }

    /// @dev this function to block deposit
    function enableToken(IERC20 _token, bool _isEnabled) external onlyAdmin {
        tokenInfos[_token].isEnabled = _isEnabled;

        emit TokenEnabled(_token, _isEnabled);
    }

    function depositNewUser(
        bytes32 publicKey,
        address withdrawTo,
        IERC20 token,
        uint256 amount
    ) external payable {
        require(numDeposits < MAX_DEPOSIT_ID, "overflow depositID");
        bool isEnabled = tokenInfos[token].isEnabled;
        uint16 tokenID = tokenInfos[token].tokenID;
        require(isEnabled, "token is not enabled");
        uint256 minDepositAmount = tokenInfos[token].minDepositAmount;
        require(amount >= minDepositAmount, "insufficient deposit amount");
        require(!pubKeyToAccountData[publicKey].isAdded, "pubKey is already added");

        token.uniTransferFromSender(payable(address(this)), amount);
        uint48 depositID = numDeposits;
        depositHashes[depositID] = sha256(abi.encodePacked(depositID, publicKey, withdrawTo, tokenID, amount));
        numDeposits += 1;

        require(numOccupiedAccounts <= MAX_ACCOUNT_ID, "overflow accountID");
        uint32 accountID = numOccupiedAccounts;
        pubKeyToAccountData[publicKey] = AccountData({isAdded: true, accountID: accountID});
        withdrawAddresses[accountID] = withdrawTo;
        numOccupiedAccounts += 1;

        emit SubmitDepositToNew(withdrawTo, depositID, publicKey, accountID, tokenID, amount);
    }

    function deposit(
        uint32 accountID,
        IERC20 token,
        uint256 amount
    ) external payable {
        require(numDeposits < MAX_DEPOSIT_ID, "overflow depositID");
        bool isEnabled = tokenInfos[token].isEnabled;
        uint16 tokenID = tokenInfos[token].tokenID;
        require(isEnabled, "token is not enabled");
        uint256 minDepositAmount = tokenInfos[token].minDepositAmount;
        require(amount >= minDepositAmount, "insufficient deposit amount");
        require(accountID < numOccupiedAccounts, "deposit into uncreated account");

        token.uniTransferFromSender(payable(address(this)), amount);
        uint48 depositID = numDeposits;
        depositHashes[depositID] = sha256(abi.encodePacked(depositID, accountID, tokenID, amount));
        numDeposits = depositID + 1;

        emit SubmitDeposit(accountID, depositID, tokenID, amount);
    }

    function submitBatch(
        uint32 batchNumber,
        BatchCallData calldata batch,
        bytes32 preBlockRoot,
        uint32 timeStamp
    ) external onlyOperator {
        uint256 batchLength = batch.operationData.length;
        require(
            batch.txData.length == batchLength &&
                batch.hiddenTxData.length == batchLength &&
                batch.stateHashes.length == batchLength,
            "unmatch length"
        );
        require(batchLength <= 32, "batchLength > 32");
        require(batchesLength == uint256(batchNumber), "unmatch batchNumber");
        bytes32[] memory blockHashes = new bytes32[](batchLength);
        // avoid stack too deep, local sope for currentDepositID, currentWithdrawID
        {
            uint48 currentDepositID = numIncludedDeposits;
            uint256 currentWithdrawID = numWithdraws;
            for (uint256 i = 0; i < batchLength; i++) {
                bytes32 operationRoot;
                (operationRoot, currentDepositID, currentWithdrawID) = handleOperation(
                    batch.operationData[i],
                    NUM_TX_IN_BLOCKS * OPERATION_COMMITMENT_SIZE,
                    currentDepositID,
                    currentWithdrawID,
                    batchNumber
                );
                bytes32 txRoot = handleTx(batch.txData[i], NUM_TX_IN_BLOCKS * TX_COMMITMENT_SIZE);
                bytes32 hiddenTxRoot = handleHiddenTx(batch.hiddenTxData[i], NUM_TX_IN_BLOCKS * 32);
                uint256 blockNumber = i + batchNumber * NUM_BLOCKS_IN_BATCH;
                bytes32 stateHash = batch.stateHashes[i];
                blockHashes[i] = sha256(
                    abi.encodePacked(
                        operationRoot,
                        txRoot,
                        hiddenTxRoot,
                        i == 0 ? preBlockRoot : blockHashes[i - 1],
                        blockNumber,
                        stateHash
                    )
                );
            }
            // at here currentDepositID == numIncludedDeposits
            require(currentDepositID <= numDeposits, "IncludedDeposits > Deposits");
            numIncludedDeposits = currentDepositID;
            numWithdraws = currentWithdrawID;
        }
        bytes32 blockDataHash = Tree.merkleBytes32Arr(blockHashes);
        bytes32 prevBatchRoot = batches[batchNumber - 1].batchRoot;
        bytes32 batchRoot = sha256(
            abi.encodePacked(
                prevBatchRoot,
                blockDataHash,
                timeStamp,
                uint32(batchNumber * NUM_BLOCKS_IN_BATCH),
                uint8(batchLength),
                batch.stateHashes[batchLength - 1]
            )
        );
        // save batch root to storage
        batches[batchNumber].batchRoot = batchRoot;
        batches[batchNumber].status = BatchStatus.SUBMITTED;
        batches[batchNumber].submitBlockTime = timeStamp;
        batchesLength++;

        emit SubmitBatch(batchNumber, blockDataHash, batchRoot);
    }

    function submitZkProof(uint256 batchNumber, uint256[] calldata zkProof) external onlyOperator {
        BatchData memory batchData = batches[batchNumber];
        require(batchData.status == BatchStatus.SUBMITTED, "invalid batchData status");
        bytes32 batchCommitment = sha256(abi.encodePacked(validatorsPubkeyRoot, batchData.batchRoot));
        require(verifier.verifyBlockProof(zkProof, batchCommitment, NUM_CHUNKS), "invalid proof");
        // if the previous batch is not finalized, then early return
        if (lastFinalizedBatchID != batchNumber - 1) {
            batchData.status = BatchStatus.CONFIRMED;
            return;
        }
        uint256 i = batchNumber;
        for (; i < batchesLength; i++) {
            if (i == batchNumber || batches[i].status == BatchStatus.CONFIRMED) {
                batches[i].status = BatchStatus.FINALIZED;
            } else {
                break;
            }
        }
        lastFinalizedBatchID = i;
        // TODO: emit finalize event
    }

    function completeWithdraw(uint256[] calldata withdrawIDs) external virtual nonReentrant {
        for (uint256 i = 0; i < withdrawIDs.length; i++) {
            uint256 withdrawID = withdrawIDs[i];
            WithdrawRequest memory withdrawRequest = withdrawRequests[withdrawID];
            if (withdrawRequest.isCompleted) {
                continue;
            }

            if (batches[withdrawRequest.batchNumber].status == BatchStatus.FINALIZED) {
                continue;
            }
            IERC20 token = IERC20(tokens[withdrawRequest.tokenID]);
            uint256 amount = uint256(withdrawRequest.amountMantisa) * (10**uint256(withdrawRequest.amountExp));
            address payable destAddress = address(uint256(withdrawAddresses[withdrawRequest.accountID]));

            withdrawRequests[withdrawID].isCompleted = true;
            //TODO: how to implement a fail safe here
            token.uniTransfer(destAddress, amount);
            emit CompleteWithdraw(
                withdrawIDs[i],
                withdrawRequest.accountID,
                destAddress,
                withdrawRequest.tokenID,
                amount
            );
        }
    }

    function isAllowedWithdraw(uint256[] calldata withdrawIDs)
        external
        view
        returns (bool[] memory isAllowedWithdrawFlags)
    {
        isAllowedWithdrawFlags = new bool[](withdrawIDs.length);
        for (uint256 i = 0; i < withdrawIDs.length; i++) {
            uint256 withdrawID = withdrawIDs[i];
            WithdrawRequest memory withdrawRequest = withdrawRequests[withdrawID];
            if (withdrawRequest.isCompleted) {
                isAllowedWithdrawFlags[i] = false;
                continue;
            }

            if (batches[withdrawRequest.batchNumber].status == BatchStatus.FINALIZED) {
                isAllowedWithdrawFlags[i] = false;
                continue;
            }
            isAllowedWithdrawFlags[i] = true;
        }
    }

    function getBatchRoot(uint256 batchNumber) external override view returns (bytes32 batchRoot) {
        return batches[batchNumber].batchRoot;
    }

    function lastestBatch() external override view returns (bytes32 batchRoot, uint256 batchNumber) {
        uint256 _batchesLength = batchesLength;
        batchRoot = batches[_batchesLength - 1].batchRoot;
        batchNumber = _batchesLength - 1;
    }

    function getTokens() external view returns (IERC20[] memory) {
        return tokens;
    }

    function listTokenInternal(IERC20 token, uint256 minDepositAmount) internal {
        require(tokens.length <= MAX_TOKEN_ID, "overflow tokenID");
        require(minDepositAmount > 0, "zero minDepositAmount");
        require(!tokenInfos[token].isListed, "listed Token");
        uint16 tokenID = uint16(tokens.length);
        tokens.push(token);
        tokenInfos[token] = TokenData({
            isListed: true,
            isEnabled: true,
            tokenID: tokenID,
            minDepositAmount: minDepositAmount
        });

        emit TokenListed(token, tokenID, minDepositAmount);
    }

    /// @dev marks incoming Depoist and Exit as done, calculates operation Root
    function handleOperation(
        bytes memory operationData,
        uint256 operationCommitmentLength,
        uint48 _currentDepositID,
        uint256 _currentWithdrawID,
        uint32 batchNumber
    )
        internal
        returns (
            bytes32 operationRoot,
            uint48 currentDepositID,
            uint256 currentWithdrawID
        )
    {
        currentDepositID = _currentDepositID;
        currentWithdrawID = _currentWithdrawID;

        bytes memory operationCommitment = new bytes(operationCommitmentLength);
        uint256 operationPtr = BitStream.getPtr(operationData);
        uint256 commitmentPtr = BitStream.getPtr(operationCommitment);
        uint256 operationPtrEnd = operationPtr + operationData.length;
        uint256 commitmentPtrEnd = commitmentPtr + operationCommitmentLength;
        while (operationPtr < operationPtrEnd) {
            // 1st 4 bit for OpcodeType
            OpType opType = OpType(BitStream.readBits(operationPtr, 0, 4));
            if (opType == OpType.Deposit || opType == OpType.DepositToNew) {
                require(operationPtr + DEPOSIT_BYTES_SIZE <= operationPtrEnd, "deposit bad data 1");
                require(commitmentPtr + OPERATION_COMMITMENT_SIZE <= commitmentPtrEnd, "deposit bad data 2");
                uint48 depositID = uint48(BitStream.readBits(operationPtr, 4, 44));
                require(depositID == currentDepositID, "roll-up unexpected depositID");
                bytes32 depositHash = depositHashes[depositID];
                currentDepositID++;
                // write commitment data and increase offset
                BitStream.writeBits(commitmentPtr, uint256(depositHash), 0, 256);
                operationPtr += DEPOSIT_BYTES_SIZE;
                commitmentPtr += OPERATION_COMMITMENT_SIZE;
            } else if (opType == OpType.Withdraw) {
                require(operationPtr + WITHDRAW_BYTES_SIZE <= operationPtrEnd, "withdraw bad data 1");
                require(commitmentPtr + OPERATION_COMMITMENT_SIZE <= commitmentPtrEnd, "deposit bad data 2");
                WithdrawRequest memory withdrawRequest;
                withdrawRequest.tokenID = uint16(BitStream.readBits(operationPtr, 4, 10));
                withdrawRequest.amountMantisa = uint32(BitStream.readBits(operationPtr + 2, 0, 32));
                withdrawRequest.amountExp = uint8(BitStream.readBits(operationPtr + 6, 0, 8));
                withdrawRequest.accountID = uint32(BitStream.readBits(operationPtr + 7, 0, 32));
                withdrawRequest.isCompleted = false;
                withdrawRequest.batchNumber = batchNumber;
                // // create withdraw request to onchain data;
                withdrawRequests[currentWithdrawID] = withdrawRequest;
                currentWithdrawID += 1;
                BitStream.copyBits(commitmentPtr, operationPtr, 0, 0, WITHDRAW_BYTES_SIZE * 8);
                operationPtr += WITHDRAW_BYTES_SIZE;
                commitmentPtr += OPERATION_COMMITMENT_SIZE;
            } else {
                // TODO: opType == OpType.Exit
                revert("invalid opcode");
            }
        }
        operationRoot = sha256(operationCommitment);
    }

    function handleTx(bytes memory txData, uint256 txCommitmentLength) internal pure returns (bytes32 txRoot) {
        bytes memory operationCommitment = new bytes(txCommitmentLength);
        uint256 txPtr = BitStream.getPtr(txData);
        uint256 commitmentPtr = BitStream.getPtr(operationCommitment);
        uint256 txPtrEnd = txPtr + txData.length;
        uint256 commitmentPtrEnd = commitmentPtr + txCommitmentLength;
        while (txPtr < txPtrEnd) {
            // 1st 4 bit for OpcodeType
            OpType opType = OpType(BitStream.readBits(txPtr, 0, 4));
            if (opType == OpType.Swap1 || opType == OpType.Swap2) {
                require(txPtr + SWAP_BYTES_SIZE <= txPtrEnd, "swap bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "swap bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, SWAP_BYTES_SIZE * 8);
                txPtr += SWAP_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.AddLiquidity) {
                require(txPtr + ADD_LIQUIDITY_BYTES_SIZE <= txPtrEnd, "addLiquidity bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "addLiquidity bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, ADD_LIQUIDITY_BYTES_SIZE * 8);
                txPtr += ADD_LIQUIDITY_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.RemoveLiquidity) {
                require(txPtr + REMOVE_LIQUIDITY_BYTES_SIZE <= txPtrEnd, "removeLiquidity bad data 1");
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "removeLiquidity bad data 2");
                BitStream.copyBits(commitmentPtr, txPtr, 0, 0, REMOVE_LIQUIDITY_BYTES_SIZE * 8);
                txPtr += REMOVE_LIQUIDITY_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else if (opType == OpType.NotSubmittedTx) {
                require(commitmentPtr + TX_COMMITMENT_SIZE <= commitmentPtrEnd, "not submited bad data");
                txPtr += NOT_SUBMITTED_BYTES_SIZE;
                commitmentPtr += TX_COMMITMENT_SIZE;
            } else {
                revert("invalid opcode");
            }
        }
        txRoot = sha256(operationCommitment);
    }

    function handleHiddenTx(bytes memory hiddenTxData, uint256 commitmentLength)
        internal
        pure
        returns (bytes32 hiddenTxRoot)
    {
        require(hiddenTxData.length % 32 == 0 && hiddenTxData.length < commitmentLength, "invalid hidden tx data 1");
        bytes memory commitment = new bytes(commitmentLength);
        uint256 dataPtr = BitStream.getPtr(hiddenTxData);
        uint256 commitmentPtr = BitStream.getPtr(commitment);
        uint256 dataPtrEnd = dataPtr + hiddenTxData.length;
        while (dataPtr < dataPtrEnd) {
            assembly {
                mstore(commitmentPtr, mload(dataPtr))
            }
            dataPtr += 32;
            commitmentPtr += 32;
        }
        hiddenTxRoot = sha256(commitment);
    }
}