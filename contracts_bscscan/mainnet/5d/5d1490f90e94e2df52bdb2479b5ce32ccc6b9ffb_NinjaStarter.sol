/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

/*
███╗░░██╗██╗███╗░░██╗░░░░░██╗░█████╗░  ░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░
████╗░██║██║████╗░██║░░░░░██║██╔══██╗  ██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗
██╔██╗██║██║██╔██╗██║░░░░░██║███████║  ╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝
██║╚████║██║██║╚████║██╗░░██║██╔══██║  ░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░
██║░╚███║██║██║░╚███║╚█████╔╝██║░░██║  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░
╚═╝░░╚══╝╚═╝╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░

https://ninjaswap.app
*/
// NinjaSwap fee collector : 0x2e7B98107bdA888d0700Da385b1525B26Cc795Cc
//  BUSD address : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity >=0.6.0 <0.8.0;

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.6.4;

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
    function allowance(address _owner, address spender)
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

// File: contracts/libs/SafeBEP20.sol

pragma solidity >=0.6.0 <0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
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

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;

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

    constructor() internal {
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

// File: contracts/NinjaStarter.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);
}
interface IMasterChef {
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function withdraw ( uint256 _pid, uint256 _amount ) external;
  function emergencyWithdraw ( uint256 _pid ) external;
  function userInfo( uint256 pid, address user ) external view returns ( uint256 ,uint256 ,uint256 );
}

contract NinjaStarter is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    IStdReference internal ref;

    //offering token
    IBEP20 public offeringToken;

    // BUSD Token
    IBEP20 public BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    address public xNinjaMaster = address(0x4Dbb8A19FacB2877059078f24ddAad74a203D4C5);


    // total amount of offeringToken that will offer
    uint256 public offeringAmount = 100000000 * 1e18; 

    // IDO starting date
    uint256 public startDate = 1641232800; 

    // limit on each address on buy
    uint256 public buyCap = 0;

    // offering token price in BUSD
    uint256 public buyPrice = 3500000000000000; // 0.0035 BUSD

    // Time when the token sale closes
    bool public isEnded = false;

    // Vesting enabled or not
    bool public isVesting = true;

    //Vesting rounds
    uint256 public vestingRounds = 5;

    //Vesting period 2629743 = 1 month, 604800 = 1 week
    uint256 public vestingPeriod = 2629743;

    // ninja holder reward enable or disable
    bool public isReward = true;

    // number of ninja token required to receive reward
    uint256 public NinjaRequiredForReward = 100;

    // number of bought tokens required to receive reward
    uint256 public minBuyForReward = 1000;

    // reward in percentage
    uint256 rewardInPer = 10;

    // limit on each address on buy
    uint256 public totalSold = 0;

    // Keeps track of BNB deposited
    uint256 public totalCollectedBNB = 0;

    // Keeps track of BUSD deposited
    uint256 public totalCollectedBUSD = 0;

    //offering token owner address
    address payable public tokenOwner;

    //ninjaswap fee collector address
    address payable public feeAddress = 0x2e7B98107bdA888d0700Da385b1525B26Cc795Cc;

    //ninjaswap liqudity address
    address payable public liqudityManager = 0xB1f652a4130792cbD9ef1d42384Fc4124E690B1b;

    //Total sale participants
    uint256 public totalSaleParticipants;

    //ninjaswap will charge this fee 3% and max can be 5%
    uint256 public ninjaFee = 5;

    //locked liquidity %
    uint256 public liquidityInPercentage = 50;

    uint256 private vestingId = 0;

    struct Vesting {
        uint256 vestingId;
        uint256 releaseTime;
        uint256 amount;
        bool released;
    }
    mapping(address => Vesting[]) public vestings;

    //Amount each user deposited BUSD
    mapping(address => uint256) public busdDeposits;

    //Amount each user deposited BNB
    mapping(address => uint256) public bnbDeposits;

    //Amount of offering token bought each user
    mapping(address => uint256) public purchases;

    mapping(address => bool) internal authorizations;

    event purchased(address user, uint256 amount);
    event rewarded(address user, uint256 amount);
    event TokenVestingReleased(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingAdded(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingRemoved(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);

    constructor(IBEP20 _offeringToken, address payable _tokenOwner) public {
        offeringToken = _offeringToken;
        tokenOwner = _tokenOwner;
        ref = IStdReference(0xDA7a001b254CD22e46d3eAB04d937489c93174C3);
        authorizations[msg.sender] = true;
        authorizations[_tokenOwner] = true;
    }

    receive() external payable {
        if (isEnded) {
            revert();
        }
        buyWithBNB(msg.sender);
    }

    function buyWithBNB(address _beneficiary)
        public
        payable
        whenNotPaused
        nonReentrant
        checkBuyCondition(msg.value , _beneficiary)
    {
        uint256 bnbAmount = msg.value;
        uint256 tokensToBePurchased = _getTokenAmount(bnbAmount);
        tokensToBePurchased = _verifyAmount(tokensToBePurchased);
        require(
            tokensToBePurchased > 0,
            "You've reached your limit of purchases"
        );
        uint256 cost = tokensToBePurchased.mul(buyPrice).div(
            getLatestBNBPrice()
        );
        if (bnbAmount > cost) {
            address payable refundAccount = payable(_beneficiary);
            refundAccount.transfer(bnbAmount.sub(cost));
            bnbAmount = cost;
        }
        totalCollectedBNB = totalCollectedBNB.add(bnbAmount);
        if (busdDeposits[_beneficiary] == 0 && bnbDeposits[_beneficiary] == 0) {
            totalSaleParticipants = totalSaleParticipants.add(1);
        }
        bnbDeposits[_beneficiary] = bnbDeposits[_beneficiary].add(bnbAmount);
        _checkout(_beneficiary, tokensToBePurchased);
    }

    function buyWithBusd(uint256 _amountBusd)
        public
        whenNotPaused
        nonReentrant
        checkBuyCondition(_amountBusd,msg.sender) 
    {
        uint256 tokensToBePurchased = _amountBusd.mul(10**18).div(buyPrice);
        tokensToBePurchased = _verifyAmount(tokensToBePurchased);
        require(
            tokensToBePurchased > 0,
            "You've reached your limit of purchases"
        );
        uint256 totalBusd = tokensToBePurchased.mul(buyPrice).div(10**18);
        BUSD.safeTransferFrom(address(msg.sender), address(this), totalBusd);
        totalCollectedBUSD = totalCollectedBUSD.add(totalBusd);
        if (busdDeposits[msg.sender] == 0 && bnbDeposits[msg.sender] == 0) {
            totalSaleParticipants = totalSaleParticipants.add(1);
        }
        busdDeposits[msg.sender] = busdDeposits[msg.sender].add(totalBusd);
        _checkout(msg.sender, tokensToBePurchased);
    }

    function getEstimatedTokensBuyWithBNB(uint256 _bnbAmount)
        public
        view
        returns (uint256)
    {
        return _bnbAmount.mul(getLatestBNBPrice()).div(buyPrice);
    }

    modifier checkBuyCondition(uint256 amount ,address _user) {
        require(_user != address(0));
        require(now >= startDate, "Trade not started");
        require(amount > 0, "Please send more amount");
        require(isEnded == false, "IDO ended");
        _;
    }

  function endOffering() public authorized {
        require(!isEnded, "offering already finalized");
        uint256 unSoldTokens = offeringAmount.sub(totalSold);
        uint256 balance = offeringToken.balanceOf(address(this));
        if (balance > unSoldTokens) {
            offeringToken.safeTransfer(tokenOwner, unSoldTokens);
        }
        isEnded = true;
    }

    function _getTokenAmount(uint256 _bnbAmount)
        internal
        view
        returns (uint256)
    {
        return _bnbAmount.mul(getLatestBNBPrice()).div(buyPrice);
    }

    function _verifyAmount(uint256 _tokensAmount)
        internal
        view
        returns (uint256)
    {
        uint256 canBeBought = _tokensAmount;
        if (buyCap > 0 && canBeBought.add(purchases[msg.sender]) > buyCap) {
            canBeBought = buyCap.sub(purchases[msg.sender]);
        }
        if (canBeBought > offeringAmount.sub(totalSold)) {
            canBeBought = offeringAmount.sub(totalSold);
        }
        return canBeBought;
    }

    function getLatestBNBPrice() public view returns (uint256) {
        IStdReference.ReferenceData memory data = ref.getReferenceData(
            "BNB",
            "USD"
        );
        return data.rate;
    }

    function _checkout(address beneficiary, uint256 _amount) internal {
        uint256 amount = _amount;
        if(isReward && isWhitelisted(beneficiary , _amount)){
            uint256 reward = _amount.mul(rewardInPer).div(100);
            amount = _amount.add(reward);
            emit rewarded(beneficiary, reward);
        }
        uint256 unlockedTokensEveryRound = amount.div(vestingRounds);
        for (uint round = 1; round <= vestingRounds; round++) {
            uint256 releaseTime = block.timestamp + vestingPeriod * round;
            vestingId = vestingId.add(1);
            vestings[beneficiary].push( Vesting({
            vestingId: vestingId,
            releaseTime: releaseTime,
            amount: unlockedTokensEveryRound,
            released: false
        }));
        emit TokenVestingAdded(vestingId, beneficiary, unlockedTokensEveryRound);
        }
        purchases[beneficiary] = purchases[beneficiary].add(amount);
        totalSold = totalSold.add(_amount);
        emit purchased(beneficiary, amount);
    }
    //<================= vestings functions ==============================================>
      function myVestings(address _address) external view returns  (Vesting[] memory) {
        return vestings[_address];
    }
    function myTokens() public view  returns(uint256 total, uint256 claimed, uint256 available, uint256 unclaimed){
        Vesting[] memory _vestings = vestings[msg.sender];
        for(uint256 i=0; i<_vestings.length; i++){
            total = total.add(_vestings[i].amount);
            if(_vestings[i].released)
                claimed = claimed.add(_vestings[i].amount);
            else {
                if(_vestings[i].releaseTime <= block.timestamp)
                    available = available.add(_vestings[i].amount);
                
                unclaimed = unclaimed.add(_vestings[i].amount);
            }
        }
    }
     function myNextRelease()  external view returns(Vesting memory vesting){
        Vesting[] memory _vestings = vestings[msg.sender];
        uint256 nextRelease = 0;
        uint256 index = 0;
        for(uint256 i=0; i<_vestings.length; i++){
           if(!_vestings[i].released && (nextRelease == 0 || _vestings[i].releaseTime < nextRelease) && _vestings[i].releaseTime >= block.timestamp){
               nextRelease = _vestings[i].releaseTime;
               index =  i;
           }
        }
        
        if(nextRelease > 0 ) vesting =  _vestings[index];
    }
    function releaseAll() external {
        Vesting[] storage _vestings  = vestings[msg.sender];
        (,,uint256 available,) = myTokens();
        require(available > 0,  'No token available to claim');
        
        for(uint256  i  = 0; i < _vestings.length; i++){
            if(!_vestings[i].released && _vestings[i].releaseTime <= block.timestamp){
                _vestings[i].released  = true;
            }
        } 
        offeringToken.safeTransfer(address(msg.sender), available);
        emit TokenVestingReleased(0, msg.sender, available);
    }
    // <================================ ADMINS FUNCTIONS ================================>

    //Function modifier to require caller to be authorized
    modifier authorized() {
        require(authorizedYes(msg.sender), "!AUTHORIZED");
        _;
    }

    //Authorize address. Owner only
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    //Return address' authorization status
    function authorizedYes(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    //Remove address' authorization. Owner only
    function authorizeOff(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function pauseIDO() external authorized whenNotPaused {
        _pause();
    }

    function unPauseIDO() external authorized whenPaused {
        _unpause();
    }

    function setIDOSettings(
        uint256 _startDate,
        uint256 _offerAmount,
        uint256 _buyCap,
        uint256 _buyPrice,
        uint256 _ninjaFee,
        uint256 _liquidityInPercentage,
        uint256 _offeringAmount
    ) public onlyOwner {
        require(_ninjaFee <= 5, "invalid fee basis points"); // max 5%
        offeringAmount = _offerAmount;
        startDate = _startDate;
        buyCap = _buyCap;
        buyPrice = _buyPrice;
        ninjaFee = _ninjaFee;
        liquidityInPercentage = _liquidityInPercentage;
        offeringAmount = _offeringAmount;
    }

    function setVestingSettings(
        bool _isVesting,
        uint256 _vestingRounds,
        uint256 _vestingPeriod
    ) public onlyOwner {
        isVesting = _isVesting;
        vestingRounds = _vestingRounds;
        vestingPeriod = _vestingPeriod;
    }

    function setRewardSettings(bool _isReward , uint256 _NinjaRequiredForReward , uint256 _minBuyForReward) public onlyOwner {
        isReward = _isReward;
        NinjaRequiredForReward = _NinjaRequiredForReward;
        minBuyForReward = _minBuyForReward;
    }

    function setTokenOwner(address payable _tokenOwner) external authorized {
        tokenOwner = _tokenOwner;
    }

    function setIDoAddresses(address payable _feeAddress, IBEP20 _busd , address _xNinjaMaster, address payable _liqudityManager)
        external
        onlyOwner
    {
        feeAddress = _feeAddress;
        BUSD = _busd;
        xNinjaMaster = address(_xNinjaMaster);
        liqudityManager = _liqudityManager;
    }

    function WithdrawFunds() public onlyOwner {
        uint256 bnbBalance = address(this).balance;
        uint256 busdBalance = BUSD.balanceOf(address(this));
        if (busdBalance > 0) {
            uint256 busdFee = busdBalance.mul(ninjaFee).div(100);
            uint256 busdLiqudity = busdBalance.mul(liquidityInPercentage).div(100);
            busdBalance = busdBalance.sub(busdFee).sub(busdLiqudity);
            BUSD.safeTransfer(feeAddress, busdFee);
            BUSD.safeTransfer(liqudityManager, busdLiqudity);
            BUSD.safeTransfer(tokenOwner, busdBalance);
        }
        if (bnbBalance > 0) {
            uint256 bnbFee = bnbBalance.mul(ninjaFee).div(100);
            uint256 bnbLiqudity = bnbBalance.mul(liquidityInPercentage).div(100);
            bnbBalance = bnbBalance.sub(bnbFee).sub(bnbLiqudity);
            feeAddress.transfer(bnbFee);
            liqudityManager.transfer(bnbLiqudity);
            tokenOwner.transfer(bnbBalance);
        }
    }
    // check if user whitelisted for reward
    function isWhitelisted(address _address , uint256 _amount) public view returns (bool) {
          uint256 poolId = 0;
        (uint256 _deposited , ,) = IMasterChef(xNinjaMaster).userInfo(poolId, _address);
        return _deposited >= (NinjaRequiredForReward *(10**18)) &&  _amount >= (minBuyForReward *(10**18))? true : false;
    }
  
}