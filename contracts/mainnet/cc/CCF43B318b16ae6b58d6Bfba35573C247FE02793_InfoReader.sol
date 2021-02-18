// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./Withdrawable.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver, Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPoolAddressesProvider public addressesProvider;

    constructor(address _addressProvider) public {
        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
    }

    receive() payable external {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
        if(_reserve == ethAddress) {
            (bool success, ) = _destination.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Aave fee IFlashLoanReceiver.
* @author Aave
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
    @title ILendingPoolAddressesProvider interface
    @notice provides the interface to fetch the LendingPoolCore address
 */

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/ERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/access/Ownable.sol";

/**
    Ensures that any contract that inherits from this contract is able to
    withdraw funds that are accidentally received or stuck.
 */

contract Withdrawable is Ownable {
    using SafeERC20 for ERC20;
    address constant ETHER = address(0);

    event LogWithdraw(
        address indexed _from,
        address indexed _assetAddress,
        uint amount
    );

    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) public onlyOwner {
        uint assetBalance;
        if (_assetAddress == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = ERC20(_assetAddress).balanceOf(address(this));
            ERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
        emit LogWithdraw(msg.sender, _assetAddress, assetBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";
import "./IERC20.sol";
import "../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILendingPool {
  function addressesProvider () external view returns ( address );
  function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
  function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
  function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
  function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
  function swapBorrowRateMode ( address _reserve ) external;
  function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
  function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
  function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
  function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
  function getReserveConfigurationData ( address _reserve ) external view returns ( uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive );
  function getReserveData ( address _reserve ) external view returns ( uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp );
  function getUserAccountData ( address _user ) external view returns ( uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor );
  function getUserReserveData ( address _reserve, address _user ) external view returns ( uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled );
  function getReserves () external view;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "./IFlashLoanReceiver.sol";

contract LendingPool {
    using SafeMath for uint256;

    receive() payable external {}

    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes memory _params) external {
        uint256 availableLiquidityBefore = address(this).balance;

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        // calculate amount fee
        uint256 amountFee = _amount.mul(30).div(10000); // 0.3% fee

        // get the FlashLoanReceiver instance
        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);
        (bool success,) = _receiver.call{value: _amount}("");
        require(success, "LendingPool: transfer to receiver failed");

        // execute action of the receiver
        receiver.executeOperation(_reserve, _amount, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = address(this).balance;

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract LendingPoolAddressesProvider {

    address lendingPool;

    constructor(address _lendingPool) public {
        lendingPool = _lendingPool;
    }

    function getLendingPool() external view returns (address) {
        return lendingPool;
    }

    function getLendingPoolCore() external view returns (address) {
        return lendingPool;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPool.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IUniswapV2Router.sol";

contract Arb is FlashLoanReceiverBase {
    using SafeMath for uint256;

    address public xvix;
    address public weth;
    address public minter;
    address public floor;
    address public router; // uniswap router
    address public receiver;
    address[] public path;
    address public gov;

    modifier onlyGov() {
        require(msg.sender == gov, "Arb: forbidden");
        _;
    }

    constructor(
        address _xvix,
        address _weth,
        address _minter,
        address _floor,
        address _router,
        address _receiver,
        address _lendingPoolAddressesProvider
    ) FlashLoanReceiverBase(_lendingPoolAddressesProvider) public {
        xvix = _xvix;
        weth = _weth;
        minter = _minter;
        floor = _floor;
        router = _router;
        receiver = _receiver;

        path.push(xvix);
        path.push(weth);

        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setReceiver(address _receiver) external onlyGov {
        receiver = _receiver;
    }

    function rebalanceMinter(uint256 _ethAmount) external onlyGov {
        address asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        bytes memory data = "";
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), asset, _ethAmount, data);
    }

    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _fee,
        bytes calldata /* _params */
    )
        external
        override
    {
        require(_asset == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "Arb: loaned asset is not ETH");
        require(_amount <= getBalanceInternal(address(this), _asset), "Arb: flashLoan failed");

        IMinter(minter).mint{value: _amount}(address(this));

        uint256 amountXVIX = IERC20(xvix).balanceOf(address(this));
        IERC20(xvix).approve(router, amountXVIX);
        IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountXVIX,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_asset, totalDebt);

        uint256 profit = address(this).balance;

        (bool success,) = receiver.call{value: profit}("");
        require(success, "Arb: transfer to receiver failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMinter {
    function enableMint(uint256 ethReserve) external;
    function mint(address receiver) external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Router {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/ILGEToken.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IXVIX.sol";
import "./interfaces/IFloor.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Distributor is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant FLOOR_BASIS_POINTS = 5000;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    bool public isInitialized;

    uint256 public lgeEndTime;
    uint256 public lpUnlockTime;
    bool public lgeIsActive;
    uint256 public ethReceived;

    address public xvix;
    address public weth;
    address public dai;
    address public lgeTokenWETH;
    address public lgeTokenDAI;
    address public floor;
    address public minter;
    address public router; // uniswap router
    address public factory; // uniswap factory
    address[] public path;

    address public gov;

    event Join(address indexed account, uint256 value);
    event RemoveLiquidity(address indexed to, address lgeToken, uint256 amountLGEToken);
    event EndLGE();

    constructor() public {
        lgeIsActive = true;
        gov = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    function initialize(
        address[] memory _addresses,
        uint256 _lgeEndTime,
        uint256 _lpUnlockTime
    ) public nonReentrant {
        require(msg.sender == gov, "Distributor: forbidden");
        require(!isInitialized, "Distributor: already initialized");
        isInitialized = true;

        xvix = _addresses[0];
        weth = _addresses[1];
        dai = _addresses[2];
        lgeTokenWETH = _addresses[3];
        lgeTokenDAI = _addresses[4];
        floor = _addresses[5];
        minter = _addresses[6];
        router = _addresses[7];
        factory = _addresses[8];

        require(ILGEToken(lgeTokenWETH).token() == weth, "Distributor: misconfigured lgeTokenWETH");
        require(ILGEToken(lgeTokenDAI).token() == dai, "Distributor: misconfigured lgeTokenDAI");

        path.push(weth);
        path.push(dai);

        lgeEndTime = _lgeEndTime;
        lpUnlockTime = _lpUnlockTime;
    }

    function join(address _receiver, uint256 _minDAI, uint256 _deadline) public payable nonReentrant {
        require(lgeIsActive, "Distributor: LGE has ended");
        require(msg.value > 0, "Distributor: insufficient value");

        uint256 floorETH = msg.value.mul(FLOOR_BASIS_POINTS).div(BASIS_POINTS_DIVISOR);
        (bool success,) = floor.call{value: floorETH}("");
        require(success, "Distributor: transfer to floor failed");

        uint256 toSwap = msg.value.sub(floorETH).div(2);
        IUniswapV2Router(router).swapExactETHForTokens{value: toSwap}(
            _minDAI,
            path,
            address(this),
            _deadline
        );

        ILGEToken(lgeTokenWETH).mint(_receiver, msg.value);
        ILGEToken(lgeTokenDAI).mint(_receiver, msg.value);
        ethReceived = ethReceived.add(msg.value);

        emit Join(_receiver, msg.value);
    }

    function endLGE(uint256 _deadline) public nonReentrant {
        require(lgeIsActive, "Distributor: LGE already ended");
        if (block.timestamp < lgeEndTime) {
            require(msg.sender == gov, "Distributor: forbidden");
        }

        lgeIsActive = false;

        // update the rebase divisor so that it will not suddenly increase
        // on the first XVIX transfer
        IXVIX(xvix).rebase();

        uint256 totalXVIX = IERC20(xvix).balanceOf(address(this));
        require(totalXVIX > 0, "Distributor: insufficient XVIX");

        uint256 amountXVIX = totalXVIX.div(2);

        _addLiquidityETH(_deadline, amountXVIX);
        _addLiquidityDAI(_deadline, amountXVIX);

        // for simplicity, assume that the minter starts with the exact number of XVIX tokens
        // as the Distributor
        // 1/2 of the XVIX owned by the Distributor and 1/4 of the ETH received by the Distributor
        // is sent to the XVIX / ETH pair
        // this would give a price of (total XVIX) / (1/2 ETH received)
        //
        // initializing the minter with the ethReceived value will let it have a
        // starting price of (total XVIX) / (ETH received)
        // which would be twice the starting price of the XVIX / ETH Uniswap pair
        IMinter(minter).enableMint(ethReceived);

        emit EndLGE();
    }

    function removeLiquidityETH(
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) public nonReentrant {
        uint256 amountWETH = _removeLiquidity(
            lgeTokenWETH,
            _amountLGEToken,
            _amountXVIXMin,
            _amountETHMin,
            _to,
            _deadline
        );

        IWETH(weth).withdraw(amountWETH); // convert WETH to ETH

        (bool success,) = _to.call{value: amountWETH}("");
        require(success, "Distributor: ETH transfer failed");
    }

    function removeLiquidityDAI(
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountTokenMin,
        address _to,
        uint256 _deadline
    ) public nonReentrant {
        uint256 amountDAI = _removeLiquidity(
            lgeTokenDAI,
            _amountLGEToken,
            _amountXVIXMin,
            _amountTokenMin,
            _to,
            _deadline
        );

        IERC20(dai).transfer(_to, amountDAI);
    }

    function _removeLiquidity(
        address _lgeToken,
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountTokenMin,
        address _to,
        uint256 _deadline
    ) private returns (uint256) {
        require(!lgeIsActive, "Distributor: LGE has not ended");
        require(block.timestamp >= lpUnlockTime, "Distributor: unlock time not yet reached");

        uint256 liquidity = _getLiquidityAmount(_lgeToken, _amountLGEToken);

        // burn after calculating liquidity because _getLiquidityAmount uses
        // lgeToken.totalSupply to calculate liquidity
        ILGEToken(_lgeToken).burn(msg.sender, _amountLGEToken);

        if (liquidity == 0) { return 0; }

        address pair = _getPair(_lgeToken);
        IERC20(pair).approve(router, liquidity);

        IUniswapV2Router(router).removeLiquidity(
            xvix,
            ILGEToken(_lgeToken).token(),
            liquidity,
            _amountXVIXMin,
            _amountTokenMin,
            address(this),
            _deadline
        );

        uint256 amountXVIX = IERC20(xvix).balanceOf(address(this));
        uint256 amountToken = IERC20(ILGEToken(_lgeToken).token()).balanceOf(address(this));

        uint256 refundBasisPoints = _getRefundBasisPoints(_lgeToken, _amountLGEToken, amountToken);
        uint256 refundAmount = amountXVIX.mul(refundBasisPoints).div(BASIS_POINTS_DIVISOR);

        // burn XVIX to refund the XLGE participant
        if (refundAmount > 0) {
            IFloor(floor).refund(_to, refundAmount);
        }

        // permanently remove the remaining XVIX by burning
        // and reducing xvix.maxSupply
        uint256 toastAmount = amountXVIX.sub(refundAmount);
        if (toastAmount > 0) {
            IXVIX(xvix).toast(toastAmount);
        }

        emit RemoveLiquidity(_to, _lgeToken, _amountLGEToken);

        return amountToken;
    }

    function _getRefundBasisPoints(
        address _lgeToken,
        uint256 _amountLGEToken,
        uint256 _amountToken
    ) private view returns (uint256) {
        // lgeTokenWETH.refBalance: total ETH holdings at endLGE
        // lgeTokenWETH.refSupply: totalSupply of lgeTokenWETH at endLGE
        // lgeTokenDAI.refBalance: total DAI holdings at endLGE
        // lgeTokenDAI.refSupply: totalSupply of lgeTokenDAI at endLGE
        uint256 refBalance = ILGEToken(_lgeToken).refBalance();
        uint256 refSupply = ILGEToken(_lgeToken).refSupply();
        // refAmount is the proportional amount of WETH or DAI
        // that the user contributed for the given amountLGEToken
        uint256 refAmount = _amountLGEToken.mul(refBalance).div(refSupply);

        // if the user contributed 1 ETH, this ETH is split into:
        // Floor: 0.5 ETH
        // XVIX / ETH LP: 0.25 ETH
        // XVIX / DAI LP: 0.25 ETH worth of DAI
        // the user would then be issued 1 lgeTokenWETH and 1 lgeTokenDAI
        // each lgeToken entitles the user to assets worth ~0.5 ETH
        // e.g. 1 lgeTokenWETH entitles to the user to 0.25 ETH from the XVIX / ETH LP
        // and XVIX worth 0.25 ETH, redeemable from the Floor
        //
        // if the user wants to redeem an _amountLGEToken of 0.8 for lgeTokenWETH
        // refAmount would be 0.2, 0.8 * 0.25 / 1
        // the minExpectedAmount would be 0.4, 0.2 * 2
        uint256 minExpectedAmount = refAmount.mul(2);

        // amountToken is the amount of WETH / DAI already retrieved from
        // removing liquidity
        // if the price of XVIX has doubled, the amount of WETH / DAI retrieved
        // would be doubled as well, so no refund of XVIX is required
        if (_amountToken >= minExpectedAmount) { return 0; }

        // if the price of XVIX has not doubled, some refund would be required
        // e.g. minExpectedAmount is 0.4 and amountToken is 0.3
        // in this case, diff would be 0.1
        // and refundBasisPoints would be 5000, 0.1 * 10,000 / 0.2
        // so 50% of the XVIX retrieved from removing liquidity would be
        // burnt to redeem ETH for the user
        uint256 diff = minExpectedAmount.sub(_amountToken);
        uint256 refundBasisPoints = diff.mul(BASIS_POINTS_DIVISOR).div(refAmount);

        if (refundBasisPoints >= BASIS_POINTS_DIVISOR) {
            return BASIS_POINTS_DIVISOR;
        }

        return refundBasisPoints;
    }

    function _getLiquidityAmount(address _lgeToken, uint256 _amountLGEToken) private view returns (uint256) {
        address pair = _getPair(_lgeToken);
        uint256 pairBalance = IERC20(pair).balanceOf(address(this));
        uint256 totalSupply = IERC20(_lgeToken).totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        // each lgeToken represents a percentage ownership of the
        // liquidity in the XVIX / WETH or XVIX / DAI Uniswap pair
        // e.g. if there are 10 lgeTokens and _amountLGEToken is 1
        // then the liquidity owned by that 1 token is
        // 1 / 10 * (total liquidity owned by this contract)
        return pairBalance.mul(_amountLGEToken).div(totalSupply);
    }

    function _getPair(address _lgeToken) private view returns (address) {
        return IUniswapV2Factory(factory).getPair(xvix, ILGEToken(_lgeToken).token());
    }

    function _addLiquidityETH(uint256 _deadline, uint256 _amountXVIX) private {
        uint256 amountETH = address(this).balance;
        require(amountETH > 0, "Distributor: insufficient ETH");

        IERC20(xvix).approve(router, _amountXVIX);

        IUniswapV2Router(router).addLiquidityETH{value: amountETH}(
            xvix, // token
            _amountXVIX, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            address(this), // to
            _deadline // deadline
        );

        ILGEToken(lgeTokenWETH).setRefBalance(amountETH);
        uint256 totalSupply = IERC20(lgeTokenWETH).totalSupply();
        ILGEToken(lgeTokenWETH).setRefSupply(totalSupply);
    }

    function _addLiquidityDAI(uint256 _deadline, uint256 _amountXVIX) private {
        uint256 amountDAI = IERC20(dai).balanceOf(address(this));
        require(amountDAI > 0, "Distributor: insufficient DAI");

        IERC20(xvix).approve(router, _amountXVIX);
        IERC20(dai).approve(router, amountDAI);

        IUniswapV2Router(router).addLiquidity(
            xvix, // tokenA
            dai, // tokenB
            _amountXVIX, // amountADesired
            amountDAI, // amountBDesired
            0, // amountAMin
            0, // amountBMin
            address(this), // to
            _deadline // deadline
        );

        ILGEToken(lgeTokenDAI).setRefBalance(amountDAI);
        uint256 totalSupply = IERC20(lgeTokenDAI).totalSupply();
        ILGEToken(lgeTokenDAI).setRefSupply(totalSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILGEToken {
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);

    function token() external view returns (address);

    function refBalance() external view returns (uint256);
    function setRefBalance(uint256 balance) external returns (bool);

    function refSupply() external view returns (uint256);
    function setRefSupply(uint256 supply) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXVIX {
    function setGov(address gov) external;
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFloor {
    function refund(address receiver, uint256 burnAmount) external returns (uint256);
    function capital() external view returns (uint256);
    function getMaxMintAmount(uint256 ethAmount) external view returns (uint256);
    function getRefundAmount(uint256 _tokenAmount) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IFarm.sol";
import "./interfaces/IFarmDistributor.sol";

// Adapted from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract Farm is IFarm {
    using SafeMath for uint256;
    uint256 constant PRECISION = 1e30;

    string public name;
    IERC20 public override stakingToken;
    IERC20 public override rewardToken;
    IFarmDistributor public farmDistributor;

    // track stakes
    uint256 public override totalStaked;
    mapping(address => uint256) public staked;

    // track overall cumulative rewards
    uint256 public cumulativeRewardPerToken;
    // track previous cumulate rewards for accounts
    mapping(address => uint256) public previousCumulatedRewardPerToken;
    // track claimable rewards for accounts
    mapping(address => uint256) public claimableReward;

    // track total rewards
    uint256 public totalClaimedRewards;
    uint256 public totalFarmRewards;

    address public gov;

    /**
     * @dev Emitted when an account stakes
     * @param who Account staking
     * @param amountStaked Amount of tokens staked
     */
    event Stake(address indexed who, uint256 amountStaked);

    /**
     * @dev Emitted when an account unstakes
     * @param who Account unstaking
     * @param amountUnstaked Amount of tokens unstaked
     */
    event Unstake(address indexed who, uint256 amountUnstaked);

    /**
     * @dev Emitted when an account claims rewards
     * @param who Account claiming
     * @param amountClaimed Amount of claimed
     */
    event Claim(address indexed who, uint256 amountClaimed);

    event GovChange(address gov);
    event DistributorChange(address distributor);

    modifier onlyGov() {
        require(msg.sender == gov, "Farm: forbidden");
        _;
    }

    constructor(string memory _name, IERC20 _stakingToken, IERC20 _rewardToken) public {
        name = _name;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        gov = msg.sender;
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setFarmDistributor(IFarmDistributor _farmDistributor) public onlyGov {
        farmDistributor = _farmDistributor;
        emit DistributorChange(address(_farmDistributor));
    }

    /**
     * @dev Stake tokens for rewards.
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external override update {
        staked[msg.sender] = staked[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
        emit Stake(msg.sender, amount);
    }

    /**
     * @dev Internal unstake function
     * @param amount Amount of tokens to unstake
     */
    function _unstake(address receiver, uint256 amount) internal {
        require(amount <= staked[msg.sender], "Farm: Cannot withdraw amount bigger than available balance");
        staked[msg.sender] = staked[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        stakingToken.transfer(receiver, amount);
        emit Unstake(receiver, amount);
    }

    /**
     * @dev Internal claim function
     */
    function _claim(address receiver) internal {
        totalClaimedRewards = totalClaimedRewards.add(claimableReward[msg.sender]);
        uint256 rewardToClaim = claimableReward[msg.sender];
        claimableReward[msg.sender] = 0;

        rewardToken.transfer(receiver, rewardToClaim);
        emit Claim(receiver, rewardToClaim);
    }

    /**
     * @dev Remove staked tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(address receiver, uint256 amount) external override update {
        _unstake(receiver, amount);
    }

    /**
     * @dev Claim rewards
     */
    function claim(address receiver) external override update {
        _claim(receiver);
    }

    /**
     * @dev Unstake amount and claim rewards
     * @param amount Amount of tokens to unstake
     */
    function exit(address receiver, uint256 amount) external override update {
        _unstake(receiver, amount);
        _claim(receiver);
    }

    /**
     * @dev Update state and get rewards from distributor
     */
    modifier update() {
        // pull from distributor
        if (address(farmDistributor) != address(0)) {
            farmDistributor.distribute(address(this));
        }
        // calculate total rewards
        uint256 newTotalFarmRewards = rewardToken.balanceOf(address(this)).add(totalClaimedRewards).mul(PRECISION);
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards.sub(totalFarmRewards);
        // update farm rewards
        totalFarmRewards = newTotalFarmRewards;
        // if there are stakers
        if (totalStaked > 0) {
            cumulativeRewardPerToken = cumulativeRewardPerToken.add(totalBlockReward.div(totalStaked));
        }
        // update claimable reward for sender
        claimableReward[msg.sender] = claimableReward[msg.sender].add(
            staked[msg.sender].mul(cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[msg.sender])).div(PRECISION)
        );
        // update previous cumulative for sender
        previousCumulatedRewardPerToken[msg.sender] = cumulativeRewardPerToken;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";

// Adapted from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/interface/ITrueFarm.sol
interface IFarm {
    function rewardToken() external view returns (IERC20);
    function stakingToken() external view returns (IERC20);
    function totalStaked() external view returns (uint256);
    function stake(uint256 amount) external;
    function unstake(address receiver, uint256 amount) external;
    function claim(address receiver) external;
    function exit(address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFarmDistributor {
    function distribute(address farm) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IFarmDistributor.sol";

contract FarmDistributor is IFarmDistributor {
    using SafeMath for uint256;

    IERC20 public rewardToken;

    constructor(IERC20 _rewardToken) public {
        rewardToken = _rewardToken;
    }

    function distribute(address farm) external override {
        uint256 amount = rewardToken.balanceOf(address(this));
        if (amount == 0) { return; }
        rewardToken.transfer(farm, amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IFloor.sol";
import "./interfaces/IXVIX.sol";

// Floor: accumulates ETH and allows XVIX to be burnt for ETH
contract Floor is IFloor, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant REFUND_BASIS_POINTS = 9000; // 90%

    address public immutable xvix;
    // manually track capital to guard against reentrancy attacks
    uint256 public override capital;

    event Refund(address indexed to, uint256 refundAmount, uint256 burnAmount);
    event FloorPrice(uint256 capital, uint256 supply);

    constructor(address _xvix) public {
        xvix = _xvix;
    }

    receive() external payable nonReentrant {
        capital = capital.add(msg.value);
    }

    // when XVIX is burnt 90% is refunded while 10% of ETH is kept within
    // this contract
    // users who burn their tokens later will receive a larger amount of ETH
    function refund(address _receiver, uint256 _burnAmount) public override nonReentrant returns (uint256) {
        uint256 refundAmount = getRefundAmount(_burnAmount);
        require(refundAmount > 0, "Floor: refund amount is zero");
        capital = capital.sub(refundAmount);

        IXVIX(xvix).burn(msg.sender, _burnAmount);

        (bool success,) = _receiver.call{value: refundAmount}("");
        require(success, "Floor: transfer to receiver failed");

        emit Refund(_receiver, refundAmount, _burnAmount);
        emit FloorPrice(capital, IERC20(xvix).totalSupply());

        return refundAmount;
    }

    // if the total supply of XVIX is 1000 and the capital is 200 ETH
    // then this would return 5 for an input of 1
    // for every 1 ETH, the minter should allow a maximum of 5 XVIX to be minted
    // if the minter allows more than 5 XVIX to be minted for 1 ETH, e.g. 10 XVIX,
    // then this would result in the floor price decreasing
    function getMaxMintAmount(uint256 _ethAmount) public override view returns (uint256) {
        if (capital == 0) { return 0; }
        uint256 totalSupply = IERC20(xvix).totalSupply();
        return _ethAmount.mul(totalSupply).div(capital);
    }

    function getRefundAmount(uint256 _tokenAmount) public override view returns (uint256) {
        uint256 totalSupply = IERC20(xvix).totalSupply();
        uint256 amount = capital.mul(_tokenAmount).div(totalSupply);
        return amount.mul(REFUND_BASIS_POINTS).div(BASIS_POINTS_DIVISOR);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

contract Fund {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address[] public receivers;
    uint256[] public feeBasisPoints;

    address public gov;
    address public xvix;

    constructor(address _xvix) public {
        xvix = _xvix;
        gov = msg.sender;
    }

    function setReceivers(address[] memory _receivers, uint256[] memory _feeBasisPoints) public {
        require(msg.sender == gov, "Fund: forbidden");
        _validateInput(_receivers, _feeBasisPoints);
        receivers = _receivers;
        feeBasisPoints = _feeBasisPoints;
    }

    function withdraw(address _token) public {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 feePoints = feeBasisPoints[i];
            uint256 amount = balance.mul(feePoints).div(BASIS_POINTS_DIVISOR);
            IERC20(_token).transfer(receivers[i], amount);
        }
    }

    function withdrawXVIX() public {
        address token = xvix;
        uint256 balance = IERC20(token).balanceOf(address(this));
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 feePoints = feeBasisPoints[i];
            uint256 amount = balance.mul(feePoints).div(BASIS_POINTS_DIVISOR);
            IERC20(token).transfer(receivers[i], amount);
        }
    }

    function _validateInput(address[] memory _receivers, uint256[] memory _feeBasisPoints) private pure {
        require(_receivers.length == _feeBasisPoints.length, "Fund: invalid input");
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _feeBasisPoints.length; i++) {
            totalBasisPoints = totalBasisPoints.add(_feeBasisPoints[i]);
        }
        require(totalBasisPoints == BASIS_POINTS_DIVISOR, "Fund: invalid input");
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";

contract InfoReader {
    function getTokenBalances(IERC20 _token, address[] memory _accounts) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = _token.balanceOf(_accounts[i]);
        }

        return balances;
    }

    function getContractInfo(address[] memory _accounts) public view returns (bool[] memory) {
        bool[] memory info = new bool[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            info[i] = isContract(_accounts[i]);
        }

        return info;
    }

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDistributor {
    function active() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimeVault {
    function withdrawalSlots(uint256 slot) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniFarm {
    function deposit(uint256 amount, address receiver) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./interfaces/ILGEToken.sol";

contract LGEToken is IERC20, ILGEToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public override totalSupply;

    address public distributor;
    address public override token;

    uint256 public override refBalance;
    uint256 public override refSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    event SetRefBalance(uint256 refBalance);
    event SetRefSupply(uint256 refSupply);

    modifier onlyDistributor() {
        require(msg.sender == distributor, "LGEToken: forbidden");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _distributor,
        address _token
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        distributor = _distributor;
        token = _token;
    }

    function mint(address _account, uint256 _amount) public override onlyDistributor returns (bool) {
        _mint(_account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public override onlyDistributor returns (bool) {
        _burn(_account, _amount);
        return true;
    }

    function setRefBalance(uint256 _refBalance) public override onlyDistributor returns (bool) {
        refBalance = _refBalance;
        emit SetRefBalance(_refBalance);
        return true;
    }

    function setRefSupply(uint256 _refSupply) public override onlyDistributor returns (bool) {
        refSupply = _refSupply;
        emit SetRefSupply(_refSupply);
        return true;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "LGEToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "LGEToken: transfer from the zero address");
        require(_recipient != address(0), "LGEToken: transfer to the zero address");

        balances[_sender] = balances[_sender].sub(_amount, "LGEToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address account, uint256 _amount) private {
        require(account != address(0), "LGEToken: mint to the zero address");

        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(address(0), account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "LGEToken: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "LGEToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "LGEToken: approve from the zero address");
        require(_spender != address(0), "LGEToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IMinter.sol";
import "./interfaces/IXVIX.sol";
import "./interfaces/IFloor.sol";

// Minter: allows XVIX to be minted following a bonding curve
contract Minter is IMinter, ReentrancyGuard {
    using SafeMath for uint256;

    address public immutable xvix;
    address public immutable floor;
    address public immutable distributor;

    uint256 public ethReserve;
    bool public active = false;

    event Mint(address indexed to, uint256 value);
    event FloorPrice(uint256 capital, uint256 supply);

    constructor(address _xvix, address _floor, address _distributor) public {
        xvix = _xvix;
        floor = _floor;
        distributor = _distributor;
    }

    // this is called by the Distributor contract so that
    // minting is only allowed after distribution has ended
    function enableMint(uint256 _ethReserve) public override nonReentrant {
        require(msg.sender == distributor, "Minter: forbidden");
        require(_ethReserve != 0, "Minter: insufficient eth reserve");
        require(!active, "Minter: already active");

        active = true;
        ethReserve = _ethReserve;
    }

    function mint(address _receiver) public override payable nonReentrant {
        require(active, "Minter: not active");
        require(ethReserve > 0, "Minter: insufficient eth reserve");
        require(msg.value > 0, "Minter: insufficient value");

        uint256 toMint = getMintAmount(msg.value);
        require(toMint > 0, "Minter: mint amount is zero");

        IXVIX(xvix).mint(_receiver, toMint);
        ethReserve = ethReserve.add(msg.value);

        (bool success,) = floor.call{value: msg.value}("");
        require(success, "Minter: transfer to floor failed");

        emit Mint(_receiver, toMint);
        emit FloorPrice(IFloor(floor).capital(), IERC20(xvix).totalSupply());
    }

    function getMintAmount(uint256 _ethAmount) public view returns (uint256) {
        if (!active) { return 0; }
        if (IFloor(floor).capital() == 0) { return 0; }

        uint256 numerator = _ethAmount.mul(tokenReserve());
        uint256 denominator = ethReserve.add(_ethAmount);
        uint256 mintable = numerator.div(denominator);

        // the maximum tokens that can be minted is capped by the floor price
        // of the Floor contract
        // this ensures that minting tokens will never reduce the floor price
        uint256 max = IFloor(floor).getMaxMintAmount(_ethAmount);

        return mintable < max ? mintable : max;
    }

    function tokenReserve() public view returns (uint256) {
        uint256 maxSupply = IXVIX(xvix).maxSupply();
        uint256 totalSupply = IERC20(xvix).totalSupply();
        return maxSupply.sub(totalSupply);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IUniswapV2Pair.sol';

import "../libraries/math/SafeMath.sol";

// Mock the library because the UniswapV2Pair bytecode hash is different for localhost
library UniswapV2LibraryMock {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'bf679b48085b196f9d52b03e95c7440ff82bf0e67fff5c19e2da17fd628ba9b2' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./uniswap/UniswapV2Library.sol";
import "./libraries/token/IERC20.sol";
import "./interfaces/ILGEToken.sol";
import "./interfaces/IFloor.sol";
import "./interfaces/ITimeVault.sol";

contract Reader {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public immutable factory;
    address public immutable xvix;
    address public immutable dai;
    address public immutable lgeTokenWETH;
    address public immutable distributor;
    address public immutable floor;

    constructor(
        address _factory,
        address _xvix,
        address _dai,
        address _lgeTokenWETH,
        address _distributor,
        address _floor
    ) public {
        factory = _factory;
        xvix = _xvix;
        dai = _dai;
        lgeTokenWETH = _lgeTokenWETH;
        distributor = _distributor;
        floor = _floor;
    }

    function getWithdrawalSlots(ITimeVault vault, uint256[] memory slots) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            amounts[i] = vault.withdrawalSlots(slots[i]);
        }

        return amounts;
    }

    function getBalances(IERC20 _token, address[] memory _accounts) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_accounts.length + 1);

        balances[0] = _token.totalSupply();
        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i + 1] = _token.balanceOf(_accounts[i]);
        }

        return balances;
    }

    function getTokenBalances(IERC20 _token, address[] memory _accounts) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = _token.balanceOf(_accounts[i]);
        }

        return balances;
    }

    function getContractInfo(address[] memory _accounts) public view returns (bool[] memory) {
        bool[] memory info = new bool[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            info[i] = isContract(_accounts[i]);
        }

        return info;
    }

    function getPoolAmounts(
        address _account,
        address _token0,
        address _token1
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        address pair = UniswapV2Library.pairFor(factory, _token0, _token1);
        uint256 supply = IERC20(pair).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0, 0); }
        uint256 accountBalance = IERC20(pair).balanceOf(_account);
        uint256 balance0 = IERC20(_token0).balanceOf(pair);
        uint256 balance1 = IERC20(_token1).balanceOf(pair);
        uint256 pool0 = balance0.mul(accountBalance).div(supply);
        uint256 pool1 = balance1.mul(accountBalance).div(supply);
        return (pool0, pool1, balance0, balance1, supply);
    }

    function getLGEAmounts(address _account) public view returns (uint256, uint256, uint256, uint256) {
        uint256 accountBalance = IERC20(lgeTokenWETH).balanceOf(_account);
        uint256 supply = IERC20(lgeTokenWETH).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0); }

        return (
            accountBalance,
            distributor.balance.mul(accountBalance).div(supply),
            IERC20(dai).balanceOf(distributor).mul(accountBalance).div(supply),
            IERC20(xvix).balanceOf(distributor).mul(accountBalance).div(supply)
        );
    }

    function getLPAmounts(address _account, address _lgeToken) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 supply = IERC20(_lgeToken).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0, 0); }

        uint256 amountLGEToken = IERC20(_lgeToken).balanceOf(_account);
        address pair = UniswapV2Library.pairFor(factory, xvix, ILGEToken(_lgeToken).token());
        uint256 amountToken = getLPAmount(_account, pair, _lgeToken, ILGEToken(_lgeToken).token());
        uint256 amountXVIX = getLPAmount(_account, pair, _lgeToken, xvix);
        uint256 refundBasisPoints = getRefundBasisPoints(_lgeToken, amountLGEToken, amountToken);

        return (
            amountLGEToken,
            amountToken,
            amountXVIX,
            refundBasisPoints,
            IFloor(floor).getRefundAmount(amountXVIX)
        );
    }

    function getLPAmount(address _account, address _pair, address _lgeToken, address _token) public view returns (uint256) {
        if (IERC20(_pair).totalSupply() == 0) { return 0; }
        uint256 amountLGEToken = IERC20(_lgeToken).balanceOf(_account);
        uint256 totalTokenBalance = IERC20(_token).balanceOf(_pair);
        uint256 distributorTokenBalance = totalTokenBalance
            .mul(IERC20(_pair).balanceOf(distributor))
            .div(IERC20(_pair).totalSupply());

        return distributorTokenBalance
            .mul(amountLGEToken)
            .div(IERC20(_lgeToken).totalSupply());
    }

    function getRefundBasisPoints(address _lgeToken, uint256 _amountLGEToken, uint256 _amountToken) public view returns (uint256) {
        uint256 refBalance = ILGEToken(_lgeToken).refBalance();
        uint256 refSupply = ILGEToken(_lgeToken).refSupply();
        uint256 refAmount = _amountLGEToken.mul(refBalance).div(refSupply);
        uint256 minExpectedAmount = refAmount.mul(2);

        if (_amountToken >= minExpectedAmount) { return 0; }

        uint256 diff = minExpectedAmount.sub(_amountToken);
        uint256 refundBasisPoints = diff.mul(BASIS_POINTS_DIVISOR).div(refAmount);

        if (refundBasisPoints >= BASIS_POINTS_DIVISOR) {
            return BASIS_POINTS_DIVISOR;
        }

        return refundBasisPoints;
    }

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IUniswapV2Pair.sol';

import "../libraries/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./interfaces/IXVIX.sol";

contract Timelock {
    using SafeMath for uint256;

    uint256 public constant DELAY = 5 days;

    address public xvix;
    address public owner;
    address public nextGov;
    uint256 public unlockTime;

    event SuggestGov(address gov, uint256 unlockTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Timelock: forbidden");
        _;
    }

    constructor(address _xvix) public {
        owner = msg.sender;
        xvix = _xvix;
    }

    function suggestGov(address _gov) public onlyOwner {
        require(_gov != address(0), "Timelock: gov address is empty");
        unlockTime = block.timestamp.add(DELAY);
        nextGov = _gov;
        emit SuggestGov(_gov, unlockTime);
    }

    function setGov() public onlyOwner {
        require(unlockTime != 0 && unlockTime < block.timestamp, "Timelock: not unlocked");
        IXVIX(xvix).setGov(nextGov);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";
import "./interfaces/IXVIX.sol";
import "./interfaces/ITimeVault.sol";

contract TimeVault is ITimeVault, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant WITHDRAWAL_DELAY = 7 days;
    uint256 public constant WITHDRAWAL_WINDOW = 48 hours;

    address public token;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public withdrawalTimestamps;
    mapping (address => uint256) public withdrawalAmounts;
    mapping (uint256 => uint256) public override withdrawalSlots;

    event Deposit(address account, uint256 amount);
    event BeginWithdrawal(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    constructor(address _token) public {
        token = _token;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "TimeVault: insufficient amount");
        address account = msg.sender;
        IERC20(token).transferFrom(account, address(this), _amount);
        balances[account] = balances[account].add(_amount);
        emit Deposit(account, _amount);
    }

    function beginWithdrawal(uint256 _amount) external nonReentrant {
        address account = msg.sender;
        require(_amount > 0, "TimeVault: insufficient amount");
        require(_amount <= balanceOf(account), "TimeVault: insufficient balance");

        _decreaseWithdrawalSlot(withdrawalTimestamps[account], withdrawalAmounts[account]);

        uint256 time = block.timestamp.add(WITHDRAWAL_DELAY);
        withdrawalTimestamps[account] = time;
        withdrawalAmounts[account] = _amount;

        _increaseWithdrawalSlot(time, _amount);
        emit BeginWithdrawal(account, _amount);
    }

    function withdraw(address _receiver) external nonReentrant {
        address account = msg.sender;
        uint256 currentTime = block.timestamp;
        uint256 minTime = withdrawalTimestamps[account];
        require(minTime != 0, "TimeVault: withdrawal not initiated");
        require(currentTime > minTime, "TimeVault: withdrawal timing not reached");

        uint256 maxTime = minTime.add(WITHDRAWAL_WINDOW);
        require(currentTime < maxTime, "TimeVault: withdrawal window already passed");

        uint256 amount = withdrawalAmounts[account];
        require(amount <= balanceOf(account), "TimeVault: insufficient amount");

        _decreaseWithdrawalSlot(minTime, amount);

        withdrawalTimestamps[account] = 0;
        withdrawalAmounts[account] = 0;

        balances[account] = balances[account].sub(amount);

        IXVIX(token).rebase();
        IERC20(token).transfer(_receiver, amount);

        emit Withdraw(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function getWithdrawalSlot(uint256 _time) public pure returns (uint256) {
        return _time.div(WITHDRAWAL_WINDOW);
    }

    function _increaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        uint256 slot = getWithdrawalSlot(_time);
        withdrawalSlots[slot] = withdrawalSlots[slot].add(_amount);
    }

    function _decreaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        if (_time == 0 || _amount == 0) { return; }
        uint256 slot = getWithdrawalSlot(_time);
        if (_amount > withdrawalSlots[slot]) {
            withdrawalSlots[slot] = 0;
            return;
        }
        withdrawalSlots[slot] = withdrawalSlots[slot].sub(_amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract DAI is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "Dai Stablecoin";
        _symbol = "DAI";
        _decimals = 18;
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract WETH is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "Wrapped ETH";
        _symbol = "WETH";
        _decimals = 18;
    }

    function deposit() public payable {
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IUniswapV2ERC20.sol';
import '../libraries/math/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant override name = 'Uniswap V2';
    string public constant override symbol = 'UNI-V2';
    uint8 public constant override decimals = 18;
    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {}

    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address spender, uint value) external virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual override returns (bool) {
        if (_allowances[from][msg.sender] != uint(-1)) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../libraries/math/Math.sol';
import '../libraries/math/UQ112x112.sol';
import '../libraries/token/IERC20.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Callee.sol';
import './UniswapV2ERC20.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply().mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './TransferHelper.sol';
import '../mocks/UniswapV2LibraryMock.sol';

import '../libraries/math/SafeMath.sol';
import '../libraries/token/IERC20.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/IUniswapV2ERC20.sol';
import '../interfaces/IUniswapV2Router.sol';
import '../interfaces/IUniswapV2Factory.sol';

contract UniswapV2Router is IUniswapV2Router {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2LibraryMock.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2LibraryMock.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2LibraryMock.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2LibraryMock.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2LibraryMock.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2LibraryMock.pairFor(factory, tokenA, tokenB);
        IUniswapV2ERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2LibraryMock.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2LibraryMock.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2LibraryMock.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2LibraryMock.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2LibraryMock.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2LibraryMock.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2LibraryMock.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2LibraryMock.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2LibraryMock.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2LibraryMock.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2LibraryMock.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2LibraryMock.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2LibraryMock.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2LibraryMock.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        override
        virtual
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2LibraryMock.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual returns (uint amountB) {
        return UniswapV2LibraryMock.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        returns (uint amountOut)
    {
        return UniswapV2LibraryMock.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        returns (uint amountIn)
    {
        return UniswapV2LibraryMock.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts)
    {
        return UniswapV2LibraryMock.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts)
    {
        return UniswapV2LibraryMock.getAmountsIn(factory, amountOut, path);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './TransferHelper.sol';
import './UniswapV2Library.sol';

import '../libraries/math/SafeMath.sol';
import '../libraries/token/IERC20.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/IUniswapV2ERC20.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniFarm.sol';
import '../interfaces/IXVIX.sol';

contract XvixRouter {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable WETH;
    address public immutable uniFarm;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, address _uniFarm) public {
        factory = _factory;
        WETH = _WETH;
        uniFarm = _uniFarm;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidityETHAndStake(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(address(this));
        IERC20(pair).approve(uniFarm, liquidity);
        IUniFarm(uniFarm).deposit(liquidity, to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2ERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountToken, uint amountETH) {
        IXVIX(token).rebase();

        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountETH) {
        IXVIX(token).rebase();

        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IXVIX.sol";
import "./interfaces/IFloor.sol";

contract XVIX is IERC20, IXVIX {
    using SafeMath for uint256;

    struct TransferConfig {
        bool active;
        uint256 senderBurnBasisPoints;
        uint256 senderFundBasisPoints;
        uint256 receiverBurnBasisPoints;
        uint256 receiverFundBasisPoints;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant MAX_FUND_BASIS_POINTS = 20; // 0.2%
    uint256 public constant MAX_BURN_BASIS_POINTS = 500; // 5%

    uint256 public constant MIN_REBASE_INTERVAL = 30 minutes;
    uint256 public constant MAX_REBASE_INTERVAL = 1 weeks;
    // cap the max intervals per rebase to avoid uint overflow errors
    uint256 public constant MAX_INTERVALS_PER_REBASE = 10;
    uint256 public constant MAX_REBASE_BASIS_POINTS = 500; // 5%

    // cap the normalDivisor to avoid uint overflow errors
    // the normalDivisor will be reached about 20 years after the first rebase
    uint256 public constant MAX_NORMAL_DIVISOR = 10**23;
    uint256 public constant SAFE_DIVISOR = 10**8;

    string public constant name = "XVIX";
    string public constant symbol = "XVIX";
    uint8 public constant decimals = 18;

    string public website = "https://xvix.finance/";

    address public gov;
    address public minter;
    address public floor;
    address public distributor;
    address public fund;

    uint256 public _normalSupply;
    uint256 public _safeSupply;
    uint256 public override maxSupply;

    uint256 public normalDivisor = 10**8;
    uint256 public rebaseInterval = 1 hours;
    uint256 public rebaseBasisPoints = 2; // 0.02%
    uint256 public nextRebaseTime = 0;

    uint256 public defaultSenderBurnBasisPoints = 0;
    uint256 public defaultSenderFundBasisPoints = 0;
    uint256 public defaultReceiverBurnBasisPoints = 43; // 0.43%
    uint256 public defaultReceiverFundBasisPoints = 7; // 0.07%

    uint256 public govHandoverTime;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    // msg.sender => transfer config
    mapping (address => TransferConfig) public transferConfigs;

    // balances in safe addresses do not get rebased
    mapping (address => bool) public safes;

    event Toast(address indexed account, uint256 value, uint256 maxSupply);
    event FloorPrice(uint256 capital, uint256 supply);
    event Rebase(uint256 normalDivisor, uint256 nextRebaseTime);
    event GovChange(address gov);
    event CreateSafe(address safe, uint256 balance);
    event DestroySafe(address safe, uint256 balance);
    event RebaseConfigChange(uint256 rebaseInterval, uint256 rebaseBasisPoints);
    event DefaultTransferConfigChange(
        uint256 senderBasisPoints,
        uint256 senderFundBasisPoints,
        uint256 receiverBurnBasisPoints,
        uint256 receiverFundBasisPoints
    );
    event SetTransferConfig(
        address indexed msgSender,
        uint256 senderBasisPoints,
        uint256 senderFundBasisPoints,
        uint256 receiverBurnBasisPoints,
        uint256 receiverFundBasisPoints
    );
    event ClearTransferConfig(address indexed msgSender);

    modifier onlyGov() {
        require(msg.sender == gov, "XVIX: forbidden");
        _;
    }

    // the govHandoverTime should be set to a time after XLGE participants can
    // withdraw their funds
    modifier onlyAfterHandover() {
        require(block.timestamp > govHandoverTime, "XVIX: handover time has not passed");
        _;
    }

    modifier enforceMaxSupply() {
        _;
        require(totalSupply() <= maxSupply, "XVIX: max supply exceeded");
    }

    constructor(uint256 _initialSupply, uint256 _maxSupply, uint256 _govHandoverTime) public {
        gov = msg.sender;
        govHandoverTime = _govHandoverTime;
        maxSupply = _maxSupply;
        _mint(msg.sender, _initialSupply);
        _setNextRebaseTime();
    }

    function setGov(address _gov) public override onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setWebsite(string memory _website) public onlyGov {
        website = _website;
    }

    function setMinter(address _minter) public onlyGov {
        require(minter == address(0), "XVIX: minter already set");
        minter = _minter;
    }

    function setFloor(address _floor) public onlyGov {
        require(floor == address(0), "XVIX: floor already set");
        floor = _floor;
    }

    function setDistributor(address _distributor) public onlyGov {
        require(distributor == address(0), "XVIX: distributor already set");
        distributor = _distributor;
    }

    function setFund(address _fund) public onlyGov {
        fund = _fund;
    }

    function createSafe(address _account) public onlyGov enforceMaxSupply {
        require(!safes[_account], "XVIX: account is already a safe");
        safes[_account] = true;

        uint256 balance = balances[_account];
        _normalSupply = _normalSupply.sub(balance);

        uint256 safeBalance = balance.mul(SAFE_DIVISOR).div(normalDivisor);
        balances[_account] = safeBalance;
        _safeSupply = _safeSupply.add(safeBalance);

        emit CreateSafe(_account, balanceOf(_account));
    }

    // onlyAfterHandover guards against a possible gov attack vector
    // since XLGE participants have their funds locked for one month,
    // it is possible for gov to create a safe address and keep
    // XVIX tokens there while destroying all other safes
    // this would raise the value of the tokens kept in the safe address
    //
    // with the onlyAfterHandover modifier this attack can only be attempted
    // after XLGE participants are able to withdraw their funds
    // this would make it difficult for the attack to be profitable
    function destroySafe(address _account) public onlyGov onlyAfterHandover enforceMaxSupply {
        require(safes[_account], "XVIX: account is not a safe");
        safes[_account] = false;

        uint256 balance = balances[_account];
        _safeSupply = _safeSupply.sub(balance);

        uint256 normalBalance = balance.mul(normalDivisor).div(SAFE_DIVISOR);
        balances[_account] = normalBalance;
        _normalSupply = _normalSupply.add(normalBalance);

        emit DestroySafe(_account, balanceOf(_account));
    }

    function setRebaseConfig(
        uint256 _rebaseInterval,
        uint256 _rebaseBasisPoints
    ) public onlyGov onlyAfterHandover {
        require(_rebaseInterval >= MIN_REBASE_INTERVAL, "XVIX: rebaseInterval below limit");
        require(_rebaseInterval <= MAX_REBASE_INTERVAL, "XVIX: rebaseInterval exceeds limit");
        require(_rebaseBasisPoints <= MAX_REBASE_BASIS_POINTS, "XVIX: rebaseBasisPoints exceeds limit");

        rebaseInterval = _rebaseInterval;
        rebaseBasisPoints = _rebaseBasisPoints;

        emit RebaseConfigChange(_rebaseInterval, _rebaseBasisPoints);
    }

    function setDefaultTransferConfig(
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) public onlyGov onlyAfterHandover {
        _validateTransferConfig(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        defaultSenderBurnBasisPoints = _senderBurnBasisPoints;
        defaultSenderFundBasisPoints = _senderFundBasisPoints;
        defaultReceiverBurnBasisPoints = _receiverBurnBasisPoints;
        defaultReceiverFundBasisPoints = _receiverFundBasisPoints;

        emit DefaultTransferConfigChange(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );
    }

    function setTransferConfig(
        address _msgSender,
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) public onlyGov {
        require(_msgSender != address(0), "XVIX: cannot set zero address");
        _validateTransferConfig(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        transferConfigs[_msgSender] = TransferConfig(
            true,
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        emit SetTransferConfig(
            _msgSender,
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );
    }

    function clearTransferConfig(address _msgSender) public onlyGov onlyAfterHandover {
        delete transferConfigs[_msgSender];
        emit ClearTransferConfig(_msgSender);
    }

    function rebase() public override returns (bool) {
        if (block.timestamp < nextRebaseTime) { return false; }
        // calculate the number of intervals that have passed
        uint256 timeDiff = block.timestamp.sub(nextRebaseTime);
        uint256 intervals = timeDiff.div(rebaseInterval).add(1);

        // the multiplier is calculated as (~10000)^intervals
        // the max value of intervals is capped at 10 to avoid uint overflow errors
        // 2^256 has 77 digits
        // 10,000^10 has 40
        // MAX_NORMAL_DIVISOR has 23 digits
        if (intervals > MAX_INTERVALS_PER_REBASE) {
            intervals = MAX_INTERVALS_PER_REBASE;
        }

        _setNextRebaseTime();

        if (rebaseBasisPoints == 0) { return false; }

        uint256 multiplier = BASIS_POINTS_DIVISOR.add(rebaseBasisPoints) ** intervals;
        uint256 divider = BASIS_POINTS_DIVISOR ** intervals;

        uint256 nextDivisor = normalDivisor.mul(multiplier).div(divider);
        if (nextDivisor > MAX_NORMAL_DIVISOR) {
            return false;
        }

        normalDivisor = nextDivisor;
        emit Rebase(normalDivisor, nextRebaseTime);

        return true;
    }

    function mint(address _account, uint256 _amount) public override returns (bool) {
        require(msg.sender == minter, "XVIX: forbidden");
        _mint(_account, _amount);
        return true;
    }

    // permanently remove tokens from circulation by reducing maxSupply
    function toast(uint256 _amount) public override returns (bool) {
        require(msg.sender == distributor, "XVIX: forbidden");
        if (_amount == 0) { return false; }

        _burn(msg.sender, _amount);
        maxSupply = maxSupply.sub(_amount);
        emit Toast(msg.sender, _amount, maxSupply);

        return true;
    }

    function burn(address _account, uint256 _amount) public override returns (bool) {
        require(msg.sender == floor, "XVIX: forbidden");
        _burn(_account, _amount);
        return true;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        if (safes[_account]) {
            return balances[_account].div(SAFE_DIVISOR);
        }

        return balances[_account].div(normalDivisor);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        rebase();
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "XVIX: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        rebase();
        return true;
    }

    function normalSupply() public view returns (uint256) {
        return _normalSupply.div(normalDivisor);
    }

    function safeSupply() public view returns (uint256) {
        return _safeSupply.div(SAFE_DIVISOR);
    }

    function totalSupply() public view override returns (uint256) {
        return normalSupply().add(safeSupply());
    }

    function _validateTransferConfig(
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) private pure {
        require(_senderBurnBasisPoints <= MAX_BURN_BASIS_POINTS, "XVIX: senderBurnBasisPoints exceeds limit");
        require(_senderFundBasisPoints <= MAX_FUND_BASIS_POINTS, "XVIX: senderFundBasisPoints exceeds limit");
        require(_receiverBurnBasisPoints <= MAX_BURN_BASIS_POINTS, "XVIX: receiverBurnBasisPoints exceeds limit");
        require(_receiverFundBasisPoints <= MAX_FUND_BASIS_POINTS, "XVIX: receiverFundBasisPoints exceeds limit");
    }

    function _setNextRebaseTime() private {
        uint256 roundedTime = block.timestamp.div(rebaseInterval).mul(rebaseInterval);
        nextRebaseTime = roundedTime.add(rebaseInterval);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "XVIX: transfer from the zero address");
        require(_recipient != address(0), "XVIX: transfer to the zero address");

        (uint256 senderBurn,
         uint256 senderFund,
         uint256 receiverBurn,
         uint256 receiverFund) = _getTransferConfig();

        // increase senderAmount based on senderBasisPoints
        uint256 senderAmount = _amount;
        uint256 senderBasisPoints = senderBurn.add(senderFund);
        if (senderBasisPoints > 0) {
            uint256 senderTax = _amount.mul(senderBasisPoints).div(BASIS_POINTS_DIVISOR);
            senderAmount = senderAmount.add(senderTax);
        }

        // decrease receiverAmount based on receiverBasisPoints
        uint256 receiverAmount = _amount;
        uint256 receiverBasisPoints = receiverBurn.add(receiverFund);
        if (receiverBasisPoints > 0) {
            uint256 receiverTax = _amount.mul(receiverBasisPoints).div(BASIS_POINTS_DIVISOR);
            receiverAmount = receiverAmount.sub(receiverTax);
        }

        _decreaseBalance(_sender, senderAmount);
        _increaseBalance(_recipient, receiverAmount);

        emit Transfer(_sender, _recipient, receiverAmount);

        // increase fund balance based on fundBasisPoints
        uint256 fundBasisPoints = senderFund.add(receiverFund);
        uint256 fundAmount = _amount.mul(fundBasisPoints).div(BASIS_POINTS_DIVISOR);
        if (fundAmount > 0) {
            _increaseBalance(fund, fundAmount);
            emit Transfer(_sender, fund, fundAmount);
        }

        // emit burn event
        uint256 burnAmount = senderAmount.sub(receiverAmount).sub(fundAmount);
        if (burnAmount > 0) {
            emit Transfer(_sender, address(0), burnAmount);
        }

        _emitFloorPrice();
    }

    function _getTransferConfig() private view returns (uint256, uint256, uint256, uint256) {
        uint256 senderBurn = defaultSenderBurnBasisPoints;
        uint256 senderFund = defaultSenderFundBasisPoints;
        uint256 receiverBurn = defaultReceiverBurnBasisPoints;
        uint256 receiverFund = defaultReceiverFundBasisPoints;

        TransferConfig memory config = transferConfigs[msg.sender];
        if (config.active) {
            senderBurn = config.senderBurnBasisPoints;
            senderFund = config.senderFundBasisPoints;
            receiverBurn = config.receiverBurnBasisPoints;
            receiverFund = config.receiverFundBasisPoints;
        }

        return (senderBurn, senderFund, receiverBurn, receiverFund);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "XVIX: approve from the zero address");
        require(_spender != address(0), "XVIX: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "XVIX: mint to the zero address");
        if (_amount == 0) { return; }

        _increaseBalance(_account, _amount);

        emit Transfer(address(0), _account, _amount);
        _emitFloorPrice();
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "XVIX: burn from the zero address");
        if (_amount == 0) { return; }

        _decreaseBalance(_account, _amount);

        emit Transfer(_account, address(0), _amount);
        _emitFloorPrice();
    }

    function _increaseBalance(address _account, uint256 _amount) private enforceMaxSupply {
        if (_amount == 0) { return; }

        if (safes[_account]) {
            uint256 safeAmount = _amount.mul(SAFE_DIVISOR);
            balances[_account] = balances[_account].add(safeAmount);
            _safeSupply = _safeSupply.add(safeAmount);
            return;
        }

        uint256 normalAmount = _amount.mul(normalDivisor);
        balances[_account] = balances[_account].add(normalAmount);
        _normalSupply = _normalSupply.add(normalAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount) private {
        if (_amount == 0) { return; }

        if (safes[_account]) {
            uint256 safeAmount = _amount.mul(SAFE_DIVISOR);
            balances[_account] = balances[_account].sub(safeAmount, "XVIX: subtraction amount exceeds balance");
            _safeSupply = _safeSupply.sub(safeAmount);
            return;
        }

        uint256 normalAmount = _amount.mul(normalDivisor);
        balances[_account] = balances[_account].sub(normalAmount, "XVIX: subtraction amount exceeds balance");
        _normalSupply = _normalSupply.sub(normalAmount);
    }

    function _emitFloorPrice() private {
        if (_isContract(floor)) {
            emit FloorPrice(IFloor(floor).capital(), totalSupply());
        }
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}