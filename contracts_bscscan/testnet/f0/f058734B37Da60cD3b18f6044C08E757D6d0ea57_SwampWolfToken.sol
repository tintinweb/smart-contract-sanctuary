/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

/*
________                __        _____
\______ \ _____ _______|  | __   /  _  \    ____   ____
 |    |  \\__  \\_  __ \  |/ /  /  /_\  \  / ___\_/ __ \
 |    `   \/ __ \|  | \/    <  /    |    \/ /_/  >  ___/
/_______  (____  /__|  |__|_ \ \____|__  /\___  / \___  >
        \/     \/           \/         \//_____/      \/
                    ________   _____
                    \_____  \_/ ____\
                     /   |   \   __\
                    /    |    \  |
                    \_______  /__|
                            \/
         __________                        __
         \______   \ ____ _____    _______/  |_
          |    |  _// __ \\__  \  /  ___/\   __\
          |    |   \  ___/ / __ \_\___ \  |  |
          |______  /\___  >____  /____  > |__|
                 \/     \/     \/     \/
________________________________________________________
                         INFO:                          |
________________________________________________________|
This contract is published by RISING CORPORATION for    |
the DarkAgeOfBeast network ( DAOB ) on BSC.             |
Name        : SwampWolfToken                            |
Token symbol: SWAMPWOLF                                 |
Solidity    : 0.8.6                                     |
Contract    : 0x0000000000000000000000000000000000000000|
________________________________________________________|
                  WEBSITE AND SOCIAL:                   |
________________________________________________________|
website :   https://wolfswamp.daob.finance/             |
Twitter :   https://twitter.com/DarkAgeOfBeast          |
Medium  :   https://medium.com/@daob.wolfswamp          |
Reddit  :   https://www.reddit.com/r/DarkAgeOfTheBeast/ |
Pint    :   https://www.pinterest.fr/DarkAgeOfBeast/    |
fb      :   https://www.facebook.com/WolfSwamp          |
TG_off  :   https://t.me/DarkAgeOfBeastOfficial         |
TG_chat :   https://t.me/Darkageofbeast                 |
GitBook :   https://docs.daob.finance/wolfswamp/        |
________________________________________________________|
                 SECURITY AND FEATURES:                 |
________________________________________________________|
The administrator can use certain functions.            |
All sensitive functions are limited.                    |
The swap and liquify function accepts all               |
SWAMPWOLF/{otherToken} pairs.                           |
The update of the burn rate is automated.               |
The update of the liquify rate is automated.            |
The update of the tax transfer fee is automated.        |
Automatic burn liquidity mechanism is implemented.      |
            !  THERE ARE NO HIDDEN FEES  !              |
________________________________________________________|
                     ! WARNING !                        |
________________________________________________________|
Any token manually transferred to this contract will be |
considered a donation and cannot be claimed or recovered|
under any circumstances.                                |
________________________________________________________|
            Creative Commons (CC) license:              |
________________________________________________________|
You can reuse this contract by mentioning at the top :  |
    https://creativecommons.org/licenses/by-sa/4.0/     |
        CC BY MrRise from RisingCorporation.            |
________________________________________________________|

Thanks !
Best Regards !
by MrRise
2021-07-21
*/

pragma solidity 0.8.6;

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
     * - the calling contract must have an BNB balance of at least `value`.
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

pragma solidity 0.8.6;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity 0.8.6;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.8.6;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
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
    function _isOwner() internal view {
        require(owner() == _msgSender(), "Not the owner");
    }
    modifier onlyOwner() {
        _isOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. This can only be called by the current owner.
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
     * This can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/BEP20.sol

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
abstract contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}






// File: contracts\interfaces\IPancakeFactory.sol

pragma solidity >=0.5.0;



interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\interfaces\IPancakePair.sol

pragma solidity >=0.5.0;

interface IPancakePair {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

// File: contracts\interfaces\IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.6;

interface ISwapAndLiquify {

    function swapSwampWolfForBnb(uint256 swampWolfAmount, address swapPair) external ;

    function swapSwampWolfForOtherToken(uint256 swampWolfAmount, address swapPair) external ;

    function addBnbLiquidity(uint256 swampWolfAmount, uint256 bnbAmount) external ;

    function addOtherLiquidity(uint256 swampWolfAmount, address otherTokenAddress, uint256 otherTokenAmount) external ;

}

// File: contracts/SwampWolfToken.sol

pragma solidity 0.8.6;

// SwampWolfToken.
contract SwampWolfToken is BEP20  {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Transfer tax rate in basis points ( START: 0.01% + 0.01% by transfer , MAX: 12% ).
    uint16 public transferTaxRate = 1;
    // Burn rate % of transfer tax in basis points ( START: 100% of transferTaxRate - 0.01% by transfer , MIN: 25% ).
    uint16 public burnRate = 10000;
    // Burn liquidity rate in basis points ( 0.01% ).
    uint16 public burnLiquidityRate = 1;
    // The block number for the last burn in liquidity.
    uint256 public lastLiquidityBurn;
    // Max transfer tax rate: 12%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1200;
    // Burn amount for front-end display ( replace burn address )
    uint256 public totalBurn = 0;
    // Max transfer amount rate in basis points ( default: will be set at 0.5% of total supply after presale ).
    // Can only be less than 50 basis points > See updateMaxTransferAmountRate() function.
    uint16 public maxTransferAmountRate = 0;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Automatic burn liquidity enabled
    bool public burnLiquidityEnabled = false;
    // Min amount to liquify. (default 243 SWAMPWOLF)
    uint256 public minAmountToLiquify = 243 ether;
    // The swap router, modifiable. Will be changed to DAOB's router when our own AMM release ( DAOB - Dark Age Of Beast ).
    IPancakeRouter02 public swampWolfSwapRouter;
    // The SwapAndLquify contract.
    ISwapAndLiquify public swapAndLiquifyContract;
    // The SwapAndLiquify contract address
    address private _swapAndLiquifyAddress;
    // The trading pair
    address public swampWolfSwapPair;
    // Indexing trading pair list
    mapping(address => bool) private _isSwapPair;
    // The Trading pair list
    address[] private _swapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;
    // The presale contract address
    address private _presaleContract;
    // The admin can use this functions :
    // updateMaxTransferAmountRate ( MAX 0.5% of totalSupply )
    // updateMinAmountToLiquify ( no MAX )
    // updateSwapAndLiquifyEnabled
    // setExcludedFromAntiWhale ( initially, the MaxTransferAmount is set to 0 to allow developers to create pairs after the presale. )
    // updateSwampWolfSwapRouter
    // updatePresaleContract
    // updateSwapAndLiquifyContract
    // updateLpAddress
    // transferAdmin
    // burn (self burn)
    address private _admin;

    // Events
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TransferTaxRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed admin, bool enabled);
    event BurnLiquidityEnabledUpdated(address indexed admin, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed admin, uint256 previousAmount, uint256 newAmount);
    event SwampWolfSwapRouterUpdated(address indexed admin, address indexed router, address indexed pair);
    event SwapAndLiquify(address indexed tokenPair, uint256 bnbReceived, uint256 tokensSwapped);
    event NewTradingPairAdded( address indexed SwampWolf, address indexed otherToken);

    function _isAdmin() internal view {
        require(_admin == msg.sender, "Not Admin");
    }
    modifier onlyAdmin() {
        _isAdmin();
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (
            _excludedFromAntiWhale[sender] == false
            && _excludedFromAntiWhale[recipient] == false
        ) {
            require(amount <= maxTransferAmount(), "Exceeds the maxTransferAmount");
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Constructs the SwampWolfToken contract.
     */
    constructor() BEP20("SwampWolf Token", "SWAMPWOLF") {
        _admin = _msgSender();
        emit AdminTransferred(address(0), _admin);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
    }

    function isSwapPair(address token) external view returns (bool){
        return _isSwapPair[token];
    }

    /**
     * @dev Self destroy `_amount` tokens decreasing the total supply.
     *
     * Requirements
     *
     * This can only be called by the owner ( MasterChef ).
     */
    function masterBurn(uint256 _amount) external onlyOwner  {
        _burn(owner(), _amount);
        totalBurn += _amount;
    }

    /**
     * @dev Self destroy `_amount` tokens decreasing the total supply.
     *
     */
    function burn(uint256 _amount) public   {
        _burn(msg.sender, _amount);
        totalBurn += _amount;
    }

    /**
     * @dev Destroy `_amount` tokens to `_to` decreasing the total supply.
     *
     * Internal purpose
     */
    function burn(address _to, uint256 _amount) internal  {
        _burn(_to, _amount);
        totalBurn += _amount;
    }

    /**
     * @dev Destroy `_amount` tokens to `msg.sender` decreasing the total supply.
     *
     * Requirements
     *
     * This can only be called by the presale contract .
     */
    function burnUnsoldPresale(uint256 _amount) external  {
        if(_presaleContract == msg.sender){
            burn(msg.sender, _amount);
        }
    }

    /**
     * @dev Destroys 0.01% tokens in liquidity to decreasing the total supply several times a day.
     *
     * Internal purpose
     */
    function burnLiquidity() internal  {
        uint256 arrayLength = _swapPair.length;
        for(uint16 i = 0; i < arrayLength; i++ ){
            uint256 liquidityBalance = balanceOf(_swapPair[i]);
            uint256 amountToBurn = liquidityBalance.mul(burnLiquidityRate).div(10000);
            burn(_swapPair[i], amountToBurn);
        }
        lastLiquidityBurn = block.number;
    }

    /**
     * @dev Creates `_amount` token to `_to`.
     *
     * Requirements
     *
     * This can only be called by the owner (MasterChef).
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);

    }

    /**
     *@dev Overrides transfer function to meet Tokenomics of SWAMPWOLF.
     *
     * Requirements
     *
     * Transfer amount must be less than maxTransferAmount.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount)  {
        // Swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(swampWolfSwapRouter) != address(0)
            && swampWolfSwapPair != address(0)
            && _isSwapPair[recipient]
            && sender != _swapAndLiquifyAddress
            && recipient != _swapAndLiquifyAddress
            && sender != owner()
            && sender != _admin
        ) {
            swapAndLiquify(recipient);
        }
        if(
            lastLiquidityBurn.add(2430) < block.number
            && burnLiquidityEnabled
        ){
            burnLiquidity();
        }
        // Use normal transfer in some cases.
        if (
            transferTaxRate == 0
            || sender == owner()
            || recipient == owner()
            || sender == swampWolfSwapPair
            || _isSwapPair[sender]
            || recipient == _presaleContract
            || sender == _presaleContract
            || sender == _admin
            || recipient == _swapAndLiquifyAddress
            || sender == _swapAndLiquifyAddress
        ) {
            super._transfer(sender, recipient, amount);
        }
        else {
            // starting tax is 0.01% + 0.01% after every transfer ( MAX : 12% of transfer ).
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            // burn amount : starting is 100% of taxAmount - 0.01% after every transfer ( MIN : 25% of taxAmount ).
            uint256 burnAmount = taxAmount.mul(burnRate).div(10000);
            // add to liquidity amount : taxAmount - burnAmount, starting is 0.01% + 0.01% after every transfer ( MAX : 75% of taxAmount ).
            uint256 liquidityAmount = taxAmount.sub(burnAmount);
            require(taxAmount == burnAmount + liquidityAmount, "Burn value invalid");
            // transfer sent to recipient - taxAmount
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "Tax value invalid");
            burn(sender, burnAmount);
            super._transfer(sender, _swapAndLiquifyAddress, liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            // if tax is less than 10% add 0.01% in basis points.
            if(transferTaxRate < MAXIMUM_TRANSFER_TAX_RATE){
                transferTaxRate += 1;
            }
            // if burn rate is more than 25% remove 0.01% in basis points.
            if(burnRate > 2500){
                burnRate -= 1;
            }
        }
    }

    /**
     *@dev Swap and puts the tokens that have just been swapped into SWAMPWOLF/{otherToken} liquidity
     *
     */
    function swapAndLiquify(address swapPair ) public {
        // Capture the current SWAMPWOLF balance of the SwampAndLiquify contract
        uint256 swampWolfBalance = balanceOf(_swapAndLiquifyAddress);
        // Get the maximum transfer amount
        uint256 maxTokenTransferAmount = maxTransferAmount();
        // If the SWAMPWOLF balance of the SwampAndLiquify contract is bigger than the maximum transfer amount swampWolfBalance = maxTokenTransferAmount
        swampWolfBalance = swampWolfBalance > maxTokenTransferAmount ? maxTokenTransferAmount : swampWolfBalance;
        if (swampWolfBalance >= minAmountToLiquify){
            // Only the minimum amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;
            address swapPairAddress = swapPair;
            if(swapPair != swampWolfSwapPair){
                // Swap SWAMPWOLF for {otherToken}
                swapAndLiquifyContract.swapSwampWolfForOtherToken(liquifyAmount, swapPairAddress);
                emit SwapAndLiquify(swapPairAddress, liquifyAmount.div(2), liquifyAmount.div(2));
            }
            else{
                // Swap SWAMPWOLF for BNB
                swapAndLiquifyContract.swapSwampWolfForBnb(liquifyAmount, swapPairAddress);
                emit SwapAndLiquify(swapPairAddress, liquifyAmount.div(2), liquifyAmount.div(2));

            }
        }
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Update the max transfer amount rate.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     * Must be less than 0.5% in basis points.
     * Must be bigger than 0.01% in basis points.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyAdmin {
        require(_maxTransferAmountRate <= 50 && _maxTransferAmountRate >= 1, "Exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyAdmin {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyAdmin {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyAdmin {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the burnLiquidityEnabled.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updateBurnLiquidityEnabled(bool _enabled) public onlyAdmin {
        emit BurnLiquidityEnabledUpdated(msg.sender, _enabled);
        burnLiquidityEnabled = _enabled;
    }

    /**
     * @dev Update the presale address.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updatePresaleContract(address _presaleAddress) public onlyAdmin {
        _presaleContract = _presaleAddress;
        setExcludedFromAntiWhale(_presaleAddress, true);
    }

    /**
     * @dev Update the swapAndLiquify contract address.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updateSwapAndLiquifyContract(address _swapAndLiquifyContract) public onlyAdmin {
        swapAndLiquifyContract = ISwapAndLiquify(_swapAndLiquifyContract);
        _swapAndLiquifyAddress = _swapAndLiquifyContract;
    }

    /**
     * @dev Update the swap router.
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function updateSwampWolfSwapRouter(address _router) public onlyAdmin {
        swampWolfSwapRouter = IPancakeRouter02(_router);
        swampWolfSwapPair = IPancakeFactory(swampWolfSwapRouter.factory()).getPair(address(this), swampWolfSwapRouter.WETH());
        require(swampWolfSwapPair != address(0), "Invalid SwampWolfSwapRouter.");
        emit SwampWolfSwapRouterUpdated(msg.sender, address(swampWolfSwapRouter), swampWolfSwapPair);
    }

    /**
    * @dev Include or exclude trading pair for swapAndLiquify and burnLiquidity function.
    *
    * Requirements
    *
    * This can only be called by MasterChef through the functions addPool() or setPool().
    */
    function setNewTradingPair(address _address, bool _enabled) external onlyOwner {
        _isSwapPair[_address] = _enabled;
        if(_enabled){
            if(!_isSwapPair[_address]){
                _swapPair.push(_address);
            }
        }
        else{
            if(_isSwapPair[_address]){
                uint256 arrayLength = _swapPair.length;
                for(uint16 i = 0; i < arrayLength; i++ ){
                    if(_swapPair[i] == _address){
                        _swapPair[i] = _swapPair[arrayLength.sub(1)];
                        _swapPair.pop();
                    }
                }
            }
        }
        emit NewTradingPairAdded(msg.sender, address(_address));
    }

    /**
     * @dev Returns the address of the current admin.
     *
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev Returns the address of the current presale contract.
     *
     */
    function presaleContract() public view returns (address) {
        return _presaleContract;
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     *
     * Requirements
     *
     * This can only be called by the current admin.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "zero address");
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }

    /**
     * @dev To receive BNB donations
     *
     */
    receive() external payable {}

    /**
     * @dev Drain BNB that are sent here for donation
     *
     * Requirements
     *
     * This can only be called by the owner.
     */
    function drainBNB() public onlyAdmin {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    /**
     * @dev Drain tokens that are sent here for donation
     *
     * Requirements
     *
     * This can only be called by the owner.
     */
    function drainBEP20Token(address _token) public onlyAdmin {
        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).safeTransfer(msg.sender, amount);
    }


}