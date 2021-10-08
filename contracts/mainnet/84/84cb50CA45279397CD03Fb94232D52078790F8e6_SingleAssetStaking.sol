/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * https://github.com/OriginProtocol/origin-dollar
 *
 * Copyright 2020 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


pragma solidity ^0.8.0;



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

// File: contracts/utils/Initializable.sol

pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            initializing || !initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    uint256[50] private ______gap;
}

// File: contracts/governance/Governable.sol

pragma solidity ^0.8.0;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("OUSD.governor");
    bytes32 private constant governorPosition =
        0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;

    // keccak256("OUSD.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;

    // keccak256("OUSD.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x53bf423e48ed90e97d02ab0ebab13b2a235a6bfbe9c321847d5c175333ac4535;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// File: contracts/utils/StableMath.sol

pragma solidity ^0.8.0;


// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    using SafeMath for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param to Decimals to scale to
     * @param from Decimals to scale from
     */
    function scaleBy(
        uint256 x,
        uint256 to,
        uint256 from
    ) internal pure returns (uint256) {
        if (to > from) {
            x = x.mul(10**(to - from));
        } else if (to < from) {
            x = x.div(10**(from - to));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e36 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }
}

// File: contracts/staking/SingleAssetStaking.sol

pragma solidity ^0.8.0;







contract SingleAssetStaking is Initializable, Governable {
    using SafeMath for uint256;
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken; // this is both the staking and rewards

    struct Stake {
        uint256 amount; // amount to stake
        uint256 end; // when does the staking period end
        uint256 duration; // the duration of the stake
        uint240 rate; // rate to charge use 248 to reserve 8 bits for the bool
        bool paid;
        uint8 stakeType;
    }

    struct DropRoot {
        bytes32 hash;
        uint256 depth;
    }

    uint256[] public durations; // allowed durations
    uint256[] public rates; // rates that correspond with the allowed durations

    uint256 public totalOutstanding;
    bool public paused;

    mapping(address => Stake[]) public userStakes;

    mapping(uint8 => DropRoot) public dropRoots;

    // type 0 is reserved for stakes done by the user, all other types will be drop/preApproved stakes
    uint8 constant USER_STAKE_TYPE = 0;
    uint256 constant MAX_STAKES = 256;

    address public transferAgent;

    /* ========== Initialize ========== */

    /**
     * @dev Initialize the contracts, sets up durations, rates, and preApprover
     *      for preApproved contracts can only be called once
     * @param _stakingToken Address of the token that we are staking
     * @param _durations Array of allowed durations in seconds
     * @param _rates Array of rates(0.3 is 30%) that correspond to the allowed
     *               durations in 1e18 precision
     */
    function initialize(
        address _stakingToken,
        uint256[] calldata _durations,
        uint256[] calldata _rates
    ) external onlyGovernor initializer {
        stakingToken = IERC20(_stakingToken);
        _setDurationRates(_durations, _rates);
    }

    /* ========= Internal helper functions ======== */

    /**
     * @dev Validate and set the duration and corresponding rates, will emit
     *      events NewRate and NewDurations
     */
    function _setDurationRates(
        uint256[] memory _durations,
        uint256[] memory _rates
    ) internal {
        require(
            _rates.length == _durations.length,
            "Mismatch durations and rates"
        );

        for (uint256 i = 0; i < _rates.length; i++) {
            require(_rates[i] < type(uint240).max, "Max rate exceeded");
        }

        rates = _rates;
        durations = _durations;

        emit NewRates(msg.sender, rates);
        emit NewDurations(msg.sender, durations);
    }

    function _totalExpectedRewards(Stake[] storage stakes)
        internal
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (!stake.paid) {
                total = total.add(stake.amount.mulTruncate(stake.rate));
            }
        }
    }

    function _totalExpected(Stake storage _stake)
        internal
        view
        returns (uint256)
    {
        return _stake.amount.add(_stake.amount.mulTruncate(_stake.rate));
    }

    function _airDroppedStakeClaimed(address account, uint8 stakeType)
        internal
        view
        returns (bool)
    {
        Stake[] storage stakes = userStakes[account];
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeType == stakeType) {
                return true;
            }
        }
        return false;
    }

    function _findDurationRate(uint256 duration)
        internal
        view
        returns (uint240)
    {
        for (uint256 i = 0; i < durations.length; i++) {
            if (duration == durations[i]) {
                return uint240(rates[i]);
            }
        }
        return 0;
    }

    /**
     * @dev Internal staking function
     *      will insert the stake into the stakes array and verify we have
     *      enough to pay off stake + reward
     * @param staker Address of the staker
     * @param stakeType Number that represent the type of the stake, 0 is user
     *                  initiated all else is currently preApproved
     * @param duration Number of seconds this stake will be held for
     * @param rate Rate(0.3 is 30%) of reward for this stake in 1e18, uint240 =
     *             to fit the bool and type in struct Stake
     * @param amount Number of tokens to stake in 1e18
     */
    function _stake(
        address staker,
        uint8 stakeType,
        uint256 duration,
        uint240 rate,
        uint256 amount
    ) internal {
        require(!paused, "Staking paused");

        Stake[] storage stakes = userStakes[staker];

        uint256 end = block.timestamp.add(duration);

        uint256 i = stakes.length; // start at the end of the current array

        require(i < MAX_STAKES, "Max stakes");

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        while (i != 0 && stakes[i - 1].end > end) {
            // shift it back one
            stakes[i] = stakes[i - 1];
            i -= 1;
        }

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.rate = rate;
        newStake.stakeType = stakeType;
        newStake.end = end;
        newStake.duration = duration;
        newStake.amount = amount;

        totalOutstanding = totalOutstanding.add(_totalExpected(newStake));

        emit Staked(staker, amount, duration, rate);
    }

    function _stakeWithChecks(
        address staker,
        uint256 amount,
        uint256 duration
    ) internal {
        require(amount > 0, "Cannot stake 0");

        uint240 rewardRate = _findDurationRate(duration);
        require(rewardRate > 0, "Invalid duration"); // we couldn't find the rate that correspond to the passed duration

        _stake(staker, USER_STAKE_TYPE, duration, rewardRate, amount);
        // transfer in the token so that we can stake the correct amount
        stakingToken.safeTransferFrom(staker, address(this), amount);
    }

    modifier requireLiquidity() {
        // we need to have enough balance to cover the rewards after the operation is complete
        _;
        require(
            stakingToken.balanceOf(address(this)) >= totalOutstanding,
            "Insufficient rewards"
        );
    }

    /* ========== VIEWS ========== */

    function getAllDurations() external view returns (uint256[] memory) {
        return durations;
    }

    function getAllRates() external view returns (uint256[] memory) {
        return rates;
    }

    /**
     * @dev Return all the stakes paid and unpaid for a given user
     * @param account Address of the account that we want to look up
     */
    function getAllStakes(address account)
        external
        view
        returns (Stake[] memory)
    {
        return userStakes[account];
    }

    /**
     * @dev Find the rate that corresponds to a given duration
     * @param _duration Number of seconds
     */
    function durationRewardRate(uint256 _duration)
        external
        view
        returns (uint256)
    {
        return _findDurationRate(_duration);
    }

    /**
     * @dev Has the airdropped stake already been claimed
     */
    function airDroppedStakeClaimed(address account, uint8 stakeType)
        external
        view
        returns (bool)
    {
        return _airDroppedStakeClaimed(account, stakeType);
    }

    /**
     * @dev Calculate all the staked value a user has put into the contract,
     *      rewards not included
     * @param account Address of the account that we want to look up
     */
    function totalStaked(address account)
        external
        view
        returns (uint256 total)
    {
        Stake[] storage stakes = userStakes[account];

        for (uint256 i = 0; i < stakes.length; i++) {
            if (!stakes[i].paid) {
                total = total.add(stakes[i].amount);
            }
        }
    }

    /**
     * @dev Calculate all the rewards a user can expect to receive.
     * @param account Address of the account that we want to look up
     */
    function totalExpectedRewards(address account)
        external
        view
        returns (uint256)
    {
        return _totalExpectedRewards(userStakes[account]);
    }

    /**
     * @dev Calculate all current holdings of a user: staked value + prorated rewards
     * @param account Address of the account that we want to look up
     */
    function totalCurrentHoldings(address account)
        external
        view
        returns (uint256 total)
    {
        Stake[] storage stakes = userStakes[account];

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (stake.paid) {
                continue;
            } else if (stake.end < block.timestamp) {
                total = total.add(_totalExpected(stake));
            } else {
                //calcualte the precentage accrued in term of rewards
                total = total.add(
                    stake.amount.add(
                        stake.amount.mulTruncate(stake.rate).mulTruncate(
                            stake
                                .duration
                                .sub(stake.end.sub(block.timestamp))
                                .divPrecisely(stake.duration)
                        )
                    )
                );
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Make a preapproved stake for the user, this is a presigned voucher that the user can redeem either from
     *      an airdrop or a compensation program.
     *      Only 1 of each type is allowed per user. The proof must match the root hash
     * @param index Number that is zero base index of the stake in the payout entry
     * @param stakeType Number that represent the type of the stake, must not be 0 which is user stake
     * @param duration Number of seconds this stake will be held for
     * @param rate Rate(0.3 is 30%) of reward for this stake in 1e18, uint240 to fit the bool and type in struct Stake
     * @param amount Number of tokens to stake in 1e18
     * @param merkleProof Array of proofs for that amount
     */
    function airDroppedStake(
        uint256 index,
        uint8 stakeType,
        uint256 duration,
        uint256 rate,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external requireLiquidity {
        require(stakeType != USER_STAKE_TYPE, "Cannot be normal staking");
        require(rate < type(uint240).max, "Max rate exceeded");
        require(index < 2**merkleProof.length, "Invalid index");
        DropRoot storage dropRoot = dropRoots[stakeType];
        require(merkleProof.length == dropRoot.depth, "Invalid proof");

        // Compute the merkle root
        bytes32 node = keccak256(
            abi.encodePacked(
                index,
                stakeType,
                address(this),
                msg.sender,
                duration,
                rate,
                amount
            )
        );
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(merkleProof[i], node));
            } else {
                node = keccak256(abi.encodePacked(node, merkleProof[i]));
            }
            path /= 2;
        }

        // Check the merkle proof
        require(node == dropRoot.hash, "Stake not approved");

        // verify that we haven't already staked
        require(
            !_airDroppedStakeClaimed(msg.sender, stakeType),
            "Already staked"
        );

        _stake(msg.sender, stakeType, duration, uint240(rate), amount);
    }

    /**
     * @dev Stake an approved amount of staking token into the contract.
     *      User must have already approved the contract for specified amount.
     * @param amount Number of tokens to stake in 1e18
     * @param duration Number of seconds this stake will be held for
     */
    function stake(uint256 amount, uint256 duration) external requireLiquidity {
        // no checks are performed in this function since those are already present in _stakeWithChecks
        _stakeWithChecks(msg.sender, amount, duration);
    }

    /**
     * @dev Stake an approved amount of staking token into the contract. This function
     *      can only be called by OGN token contract.
     * @param staker Address of the account that is creating the stake
     * @param amount Number of tokens to stake in 1e18
     * @param duration Number of seconds this stake will be held for
     */
    function stakeWithSender(
        address staker,
        uint256 amount,
        uint256 duration
    ) external returns (bool) {
        require(
            msg.sender == address(stakingToken),
            "Only token contract can make this call"
        );

        _stakeWithChecks(staker, amount, duration);
        return true;
    }

    /**
     * @dev Exit out of all possible stakes
     */
    function exit() external requireLiquidity {
        Stake[] storage stakes = userStakes[msg.sender];
        require(stakes.length > 0, "Nothing staked");

        uint256 totalWithdraw = 0;
        uint256 stakedAmount = 0;
        uint256 l = stakes.length;
        do {
            Stake storage exitStake = stakes[l - 1];
            // stop on the first ended stake that's already been paid
            if (exitStake.end < block.timestamp && exitStake.paid) {
                break;
            }
            //might not be ended
            if (exitStake.end < block.timestamp) {
                //we are paying out the stake
                exitStake.paid = true;
                totalWithdraw = totalWithdraw.add(_totalExpected(exitStake));
                stakedAmount = stakedAmount.add(exitStake.amount);
            }
            l--;
        } while (l > 0);
        require(totalWithdraw > 0, "All stakes in lock-up");

        totalOutstanding = totalOutstanding.sub(totalWithdraw);
        emit Withdrawn(msg.sender, totalWithdraw, stakedAmount);
        stakingToken.safeTransfer(msg.sender, totalWithdraw);
    }

    /**
     * @dev Use to transfer all the stakes of an account in the case that the account is compromised
     *      Requires access to both the account itself and the transfer agent
     * @param _frmAccount the address to transfer from
     * @param _dstAccount the address to transfer to(must be a clean address with no stakes)
     * @param r r portion of the signature by the transfer agent
     * @param s s portion of the signature
     * @param v v portion of the signature
     */
    function transferStakes(
        address _frmAccount,
        address _dstAccount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(transferAgent == msg.sender, "must be transfer agent");
        Stake[] storage dstStakes = userStakes[_dstAccount];
        require(dstStakes.length == 0, "Dest stakes must be empty");
        require(_frmAccount != address(0), "from account not set");
        Stake[] storage stakes = userStakes[_frmAccount];
        require(stakes.length > 0, "Nothing to transfer");

        // matches ethers.signMsg(ethers.utils.solidityPack([string(4), address, adddress, address]))
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n64",
                abi.encodePacked(
                    "tran",
                    address(this),
                    _frmAccount,
                    _dstAccount
                )
            )
        );
        require(ecrecover(hash, v, r, s) == _frmAccount, "Transfer not authed");

        // copy the stakes into the dstAccount array and delete the old one
        userStakes[_dstAccount] = stakes;
        delete userStakes[_frmAccount];
        emit StakesTransfered(_frmAccount, _dstAccount, stakes.length);
    }

    /* ========== MODIFIERS ========== */

    function setPaused(bool _paused) external onlyGovernor {
        paused = _paused;
        emit Paused(msg.sender, paused);
    }

    /**
     * @dev Set new durations and rates will not effect existing stakes
     * @param _durations Array of durations in seconds
     * @param _rates Array of rates that corresponds to the durations (0.01 is 1%) in 1e18
     */
    function setDurationRates(
        uint256[] calldata _durations,
        uint256[] calldata _rates
    ) external onlyGovernor {
        _setDurationRates(_durations, _rates);
    }

    /**
     * @dev Set the agent that will authorize transfers
     * @param _agent Address of agent
     */
    function setTransferAgent(address _agent) external onlyGovernor {
        transferAgent = _agent;
    }

    /**
     * @dev Set air drop root for a specific stake type
     * @param _stakeType Type of staking must be greater than 0
     * @param _rootHash Root hash of the Merkle Tree
     * @param _proofDepth Depth of the Merklke Tree
     */
    function setAirDropRoot(
        uint8 _stakeType,
        bytes32 _rootHash,
        uint256 _proofDepth
    ) external onlyGovernor {
        require(_stakeType != USER_STAKE_TYPE, "Cannot be normal staking");
        dropRoots[_stakeType].hash = _rootHash;
        dropRoots[_stakeType].depth = _proofDepth;
        emit NewAirDropRootHash(_stakeType, _rootHash, _proofDepth);
    }

    /* ========== EVENTS ========== */

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 rate
    );
    event Withdrawn(address indexed user, uint256 amount, uint256 stakedAmount);
    event Paused(address indexed user, bool yes);
    event NewDurations(address indexed user, uint256[] durations);
    event NewRates(address indexed user, uint256[] rates);
    event NewAirDropRootHash(
        uint8 stakeType,
        bytes32 rootHash,
        uint256 proofDepth
    );
    event StakesTransfered(
        address indexed fromUser,
        address toUser,
        uint256 numStakes
    );
}