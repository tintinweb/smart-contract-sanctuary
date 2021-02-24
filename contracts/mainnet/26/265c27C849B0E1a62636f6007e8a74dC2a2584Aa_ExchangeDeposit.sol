// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title ExchangeDeposit
 * @author Jonathan Underwood
 * @notice The main contract logic for centralized exchange deposit backend.
 * @dev This contract is the main contract that will generate the proxies, and
 * all proxies will go through this. There should only be one deployed.
 */
contract ExchangeDeposit {
    using SafeERC20 for IERC20;
    using Address for address payable;
    /**
     * @notice Address to which any funds sent to this contract will be forwarded
     * @dev This is only set in ExchangeDeposit (this) contract's storage.
     * It should be cold.
     */
    address payable public coldAddress;
    /**
     * @notice The minimum wei amount of deposit to allow.
     * @dev This attribute is required for all future versions, as it is
     * accessed directly from ExchangeDeposit
     */
    uint256 public minimumInput = 1e16; // 0.01 ETH
    /**
     * @notice The address with the implementation of further upgradable logic.
     * @dev This is only set in ExchangeDeposit (this) contract's storage.
     * Also, forwarding logic to this address via DELEGATECALL is disabled when
     * this contract is killed (coldAddress == address(0)).
     * Note, it must also have the same storage structure.
     */
    address payable public implementation;
    /**
     * @notice The address that can manage the contract storage (and kill it).
     * @dev This is only set in ExchangeDeposit (this) contract's storage.
     * It has the ability to kill the contract and disable logic forwarding,
     * and change the coldAddress and implementation address storages.
     */
    address payable public immutable adminAddress;
    /**
     * @dev The address of this ExchangeDeposit instance. This is used
     * for discerning whether we are a Proxy or an ExchangeDepsosit.
     */
    address payable private immutable thisAddress;

    /**
     * @notice Create the contract, and sets the destination address.
     * @param coldAddr See storage coldAddress
     * @param adminAddr See storage adminAddress
     */
    constructor(address payable coldAddr, address payable adminAddr) public {
        require(coldAddr != address(0), '0x0 is an invalid address');
        require(adminAddr != address(0), '0x0 is an invalid address');
        coldAddress = coldAddr;
        adminAddress = adminAddr;
        thisAddress = address(this);
    }

    /**
     * @notice Deposit event, used to log deposits sent from the Forwarder contract
     * @dev We don't need to log coldAddress because the event logs and storage
     * are always the same context, so as long as we are checking the correct
     * account's event logs, no one should be able to set off events using
     * DELEGATECALL trickery.
     * @param receiver The proxy address from which funds were forwarded
     * @param amount The amount which was forwarded
     */
    event Deposit(address indexed receiver, uint256 amount);

    /**
     * @dev This internal function checks if the current context is the main
     * ExchangeDeposit contract or one of the proxies.
     * @return bool of whether or not this is ExchangeDeposit
     */
    function isExchangeDepositor() internal view returns (bool) {
        return thisAddress == address(this);
    }

    /**
     * @dev Get an instance of ExchangeDeposit for the main contract
     * @return ExchangeDeposit instance (main contract of the system)
     */
    function getExchangeDepositor() internal view returns (ExchangeDeposit) {
        // If this context is ExchangeDeposit, use `this`, else use exDepositorAddr
        return isExchangeDepositor() ? this : ExchangeDeposit(thisAddress);
    }

    /**
     * @dev Internal function for getting the implementation address.
     * This is needed because we don't know whether the current context is
     * the ExchangeDeposit contract or a proxy contract.
     * @return implementation address of the system
     */
    function getImplAddress() internal view returns (address payable) {
        return
            isExchangeDepositor()
                ? implementation
                : ExchangeDeposit(thisAddress).implementation();
    }

    /**
     * @dev Internal function for getting the sendTo address for gathering ERC20/ETH.
     * If the contract is dead, they will be forwarded to the adminAddress.
     * @return address payable for sending ERC20/ETH
     */
    function getSendAddress() internal view returns (address payable) {
        ExchangeDeposit exDepositor = getExchangeDepositor();
        // Use exDepositor to perform logic for finding send address
        address payable coldAddr = exDepositor.coldAddress();
        // If ExchangeDeposit is killed, use adminAddress, else use coldAddress
        address payable toAddr =
            coldAddr == address(0) ? exDepositor.adminAddress() : coldAddr;
        return toAddr;
    }

    /**
     * @dev Modifier that will execute internal code block only if the sender is the specified account
     */
    modifier onlyAdmin {
        require(msg.sender == adminAddress, 'Unauthorized caller');
        _;
    }

    /**
     * @dev Modifier that will execute internal code block only if not killed
     */
    modifier onlyAlive {
        require(
            getExchangeDepositor().coldAddress() != address(0),
            'I am dead :-('
        );
        _;
    }

    /**
     * @dev Modifier that will execute internal code block only if called directly
     * (Not via proxy delegatecall)
     */
    modifier onlyExchangeDepositor {
        require(isExchangeDepositor(), 'Calling Wrong Contract');
        _;
    }

    /**
     * @notice Execute a token transfer of the full balance from the proxy
     * to the designated recipient.
     * @dev Recipient is coldAddress if not killed, else adminAddress.
     * @param instance The address of the erc20 token contract
     */
    function gatherErc20(IERC20 instance) external {
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance == 0) {
            return;
        }
        instance.safeTransfer(getSendAddress(), forwarderBalance);
    }

    /**
     * @notice Gather any ETH that might have existed on the address prior to creation
     * @dev It is also possible our addresses receive funds from another contract's
     * selfdestruct.
     */
    function gatherEth() external {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        (bool result, ) = getSendAddress().call{ value: balance }('');
        require(result, 'Could not gather ETH');
    }

    /**
     * @notice Change coldAddress to newAddress.
     * @param newAddress the new address for coldAddress
     */
    function changeColdAddress(address payable newAddress)
        external
        onlyExchangeDepositor
        onlyAlive
        onlyAdmin
    {
        require(newAddress != address(0), '0x0 is an invalid address');
        coldAddress = newAddress;
    }

    /**
     * @notice Change implementation to newAddress.
     * @dev newAddress can be address(0) (to disable extra implementations)
     * @param newAddress the new address for implementation
     */
    function changeImplAddress(address payable newAddress)
        external
        onlyExchangeDepositor
        onlyAlive
        onlyAdmin
    {
        require(
            newAddress == address(0) || newAddress.isContract(),
            'implementation must be contract'
        );
        implementation = newAddress;
    }

    /**
     * @notice Change minimumInput to newMinInput.
     * @param newMinInput the new minimumInput
     */
    function changeMinInput(uint256 newMinInput)
        external
        onlyExchangeDepositor
        onlyAlive
        onlyAdmin
    {
        minimumInput = newMinInput;
    }

    /**
     * @notice Sets coldAddress to 0, killing the forwarding and logging.
     */
    function kill() external onlyExchangeDepositor onlyAlive onlyAdmin {
        coldAddress = address(0);
    }

    /**
     * @notice Forward any ETH value to the coldAddress
     * @dev This receive() type fallback means msg.data will be empty.
     * We disable deposits when dead.
     * Security note: Every time you check the event log for deposits,
     * also check the coldAddress storage to make sure it's pointing to your
     * cold account.
     */
    receive() external payable {
        // Using a simplified version of onlyAlive
        // since we know that any call here has no calldata
        // this saves a large amount of gas due to the fact we know
        // that this can only be called from the ExchangeDeposit context
        require(coldAddress != address(0), 'I am dead :-(');
        require(msg.value >= minimumInput, 'Amount too small');
        (bool success, ) = coldAddress.call{ value: msg.value }('');
        require(success, 'Forwarding funds failed');
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Forward commands to supplemental implementation address.
     * @dev This fallback() type fallback will be called when there is some
     * call data, and this contract is alive.
     * It forwards to the implementation contract via DELEGATECALL.
     */
    fallback() external payable onlyAlive {
        address payable toAddr = getImplAddress();
        require(toAddr != address(0), 'Fallback contract not set');
        (bool success, ) = toAddr.delegatecall(msg.data);
        require(success, 'Fallback contract failed');
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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