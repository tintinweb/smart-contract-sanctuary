/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function decimals() external view returns (uint8);

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

// File: contracts/utils/SafeERC20.sol

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol


pragma solidity ^0.6.12;


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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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
     * _Available since v3.3._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol

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

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token != IERC20(0)) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            require(
                from == msg.sender && msg.value >= amount,
                "msg.value is zero"
            );
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

// File: contracts/interfaces/IXChanger.sol


pragma solidity ^0.6.0;


interface XChanger {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint256 result);

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) external view returns (uint256 returnAmount);

    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    ) external view returns (uint256 inputAmount);
}

// File: contracts/XChangerUser.sol


pragma solidity ^0.6.12;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    using UniversalERC20 for IERC20;

    XChanger public xchanger;

    /**
     * @dev get a price of one token amount in another
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken
     */

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            (bool success, bytes memory data) =
                address(xchanger).staticcall(
                    abi.encodeWithSelector(
                        xchanger.quote.selector,
                        fromToken,
                        toToken,
                        amount
                    )
                );

            require(
                success && data.length > 0,
                "XChanger quote not successful"
            );

            (returnAmount) = abi.decode(data, (uint256));
        }
    }

    /**
     * @dev get a reverse price of one token amount in another
     * the opposite of above 'quote' method when we need to understand how much we need to spend actually
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param returnAmount - of the toToken
     */
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    ) public view returns (uint256 inputAmount) {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            (bool success, bytes memory data) =
                address(xchanger).staticcall(
                    abi.encodeWithSelector(
                        xchanger.reverseQuote.selector,
                        fromToken,
                        toToken,
                        returnAmount
                    )
                );
            require(
                success && data.length > 0,
                "XChanger reverseQuote not successful"
            );

            (inputAmount) = abi.decode(data, (uint256));
            inputAmount += 1; // Curve requires this
        }
    }

    /**
     * @dev swap one token to another given the amount we want to spend
     
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken we are spending
     * @param slipProtect - flag to ensure the transaction will be performed if the received amount is not less than expected within the given slip %% range (like 1%)
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable returns (uint256 returnAmount) {
        if (
            fromToken.allowance(address(this), address(xchanger)) != uint256(-1)
        ) {
            fromToken.universalApprove(address(xchanger), uint256(-1));
        }

        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
    }
}

// File: contracts/access/Context.sol


pragma solidity ^0.6.0;

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

// File: contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    function initialize() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/ICurve.sol


pragma solidity ^0.6.0;

abstract contract ICurveFiCurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function A() external view virtual returns (uint256);

    function balances(uint256 arg0) external view virtual returns (uint256);

    function fee() external view virtual returns (uint256);
}

// File: contracts/utils/CurveUtils.sol


pragma solidity ^0.6.12;


/**
 * @dev reverse-engineered utils to help Curve amount calculations
 */
contract CurveUtils {
    address internal constant CURVE_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // 3-pool DAI/USDC/USDT
    address internal constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    ICurveFiCurve internal curve = ICurveFiCurve(CURVE_ADDRESS);

    uint256 private constant N_COINS = 3;
    uint256[N_COINS] private RATES; //
    uint256[N_COINS] private PRECISION_MUL;
    uint256 private constant LENDING_PRECISION = 10**18;
    uint256 private constant FEE_DENOMINATOR = 10**10;

    mapping(address => int128) internal curveIndex;
    mapping(int128 => address) internal reverseCurveIndex;

    /**
     * @dev get index of a token in Curve pool contract
     */
    function getCurveIndex(address token) internal view returns (int128) {
        // to avoid 'stack too deep' compiler issue
        return curveIndex[token] - 1;
    }

    /**
     * @dev init internal variables at creation
     */
    function init() public virtual {
        RATES = [
            1000000000000000000,
            1000000000000000000000000000000,
            1000000000000000000000000000000
        ];
        PRECISION_MUL = [1, 1000000000000, 1000000000000];

        curveIndex[DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[USDC_ADDRESS] = 2;
        curveIndex[USDT_ADDRESS] = 3;
        reverseCurveIndex[0] = DAI_ADDRESS;
        reverseCurveIndex[1] = USDC_ADDRESS;
        reverseCurveIndex[2] = USDT_ADDRESS;
    }

    /**
     * @dev curve-specific maths
     */
    function get_D(uint256[N_COINS] memory xp, uint256 amp)
        internal
        pure
        returns (uint256)
    {
        uint256 S = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            S += xp[i];
        }
        if (S == 0) {
            return 0;
        }

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;

        for (uint256 i = 0; i < 255; i++) {
            uint256 D_P = D;

            for (uint256 j = 0; j < N_COINS; j++) {
                D_P = (D_P * D) / (xp[j] * N_COINS + 1); // +1 is to prevent /0
            }

            Dprev = D;
            D =
                ((Ann * S + D_P * N_COINS) * D) /
                ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if ((D - Dprev) <= 1) {
                    break;
                }
            } else {
                if ((Dprev - D) <= 1) {
                    break;
                }
            }
        }
        return D;
    }

    /**
     * @dev curve-specific maths
     */
    function get_y(
        uint256 i,
        uint256 j,
        uint256 x,
        uint256[N_COINS] memory xp_
    ) internal view returns (uint256) {
        //x in the input is converted to the same price/precision
        uint256 amp = curve.A();
        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * N_COINS;

        uint256 _x = 0;

        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i == i) {
                _x = x;
            } else if (_i != j) {
                _x = xp_[_i];
            } else {
                continue;
            }

            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }

        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann; //  # - D
        uint256 y_prev = 0;
        uint256 y = D;

        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            //# Equality with the precision of 1
            if (y > y_prev) {
                if ((y - y_prev) <= 1) {
                    break;
                } else if ((y_prev - y) <= 1) {
                    break;
                }
            }
        }

        return y;
    }

    /**
     * @dev curve-specific maths - this method does not exists in the curve pool but we recreated it
     */
    function get_dx_underlying(
        uint256 i,
        uint256 j,
        uint256 dy
    ) internal view returns (uint256) {
        //dx and dy in underlying units
        //uint256[N_COINS] rates = self._stored_rates();

        uint256[N_COINS] memory xp = _xp();

        uint256[N_COINS] memory precisions = PRECISION_MUL;

        uint256 y =
            xp[j] -
                ((dy * FEE_DENOMINATOR) / (FEE_DENOMINATOR - curve.fee())) *
                precisions[j];
        uint256 x = get_y(j, i, y, xp);
        uint256 dx = (x - xp[i]) / precisions[i];
        return dx;
    }

    /**
     * @dev curve-specific maths
     */
    function _xp() internal view returns (uint256[N_COINS] memory) {
        uint256[N_COINS] memory result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * curve.balances(i)) / LENDING_PRECISION;
        }

        return result;
    }
}

// File: contracts/aCRVMinerStaker.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;





abstract contract ICurvePool {
    function add_liquidity(
        uint256[3] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external virtual returns (uint256 out);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external virtual returns (uint256 out);

    function balances(uint256 i) external view virtual returns (uint256);
}

abstract contract ICurveGauge is IERC20 {
    function deposit(uint256 _value) external virtual;

    function withdraw(uint256 _value) external virtual;

    function claim_rewards() external virtual;
}

abstract contract IMinter {
    function mint(address gauge_addr) external virtual;
}

/**
 * @title aCRV external pool contract
 * @dev is an example of external pool which implements maximizing CRV yield mining capabilities.
 */

contract aCRVMiner is Ownable, XChangerUser, CurveUtils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool private initialized;

    address public ValueHolder;
    ICurvePool private constant curveAAVE =
        ICurvePool(0xDeBF20617708857ebe4F679508E7b7863a8A8EeE);
    IERC20 private constant A3Token =
        IERC20(0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900);
    ICurveGauge private constant curveGauge =
        ICurveGauge(0xd662908ADA2Ea1916B3318327A97eB18aD588b5d);

    IMinter private constant minter =
        IMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    IERC20 crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public enterToken; //= DAI_ADDRESS;
    IERC20 private enterTokenIERC20; //= IERC20(enterToken);

    event LogValueHolderUpdated(address Manager);

    /**
     * @dev main init function
     */

    function init(address _enterToken, address _xChanger) external {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        _init(_enterToken, _xChanger);
    }

    /**
     * @dev internal variable initialization
     */
    function _init(address _enterToken, address _xChanger) internal {
        CurveUtils.init();
        enterToken = _enterToken;
        enterTokenIERC20 = IERC20(enterToken);
        ValueHolder = msg.sender;
        xchanger = XChanger(_xChanger);
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(address _enterToken, address _xChanger) external onlyOwner {
        _init(_enterToken, _xChanger);
    }

    /**
     * @dev this modifier is only for methods that should be called by ValueHolder contract
     */
    modifier onlyValueHolder() {
        require(msg.sender == ValueHolder, "Not Value Holder");
        _;
    }

    /**
     * @dev Sets new ValueHolder address
     */
    function setValueHolder(address _ValueHolder) external onlyOwner {
        ValueHolder = _ValueHolder;
        emit LogValueHolderUpdated(_ValueHolder);
    }

    /**
     * @dev set new XChanger (XTrinity) contract implementation address to use
     */
    function setXChangerImpl(address _Xchanger) external onlyOwner {
        xchanger = XChanger(_Xchanger);
    }

    /**
     * @dev method for retrieving tokens back to ValueHolder or whereever
     */

    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) external onlyValueHolder returns (uint256) {
        IERC20 Token = IERC20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }

        Token.universalTransfer(recipient, amount);
        return amount;
    }

    /**
     * @dev Main function to enter Compound supply/borrow position using the available [DAI] token balance
     */
    function addPosition() external onlyValueHolder returns (uint256 amount) {
        amount = enterTokenIERC20.balanceOf(address(this));
        require(amount > 0, "No available enterToken");

        uint256[3] memory _amounts;

        int128 tokenindex = getCurveIndex(enterToken);

        if (tokenindex == 0) {
            _amounts = [amount, 0, 0];
        } else if (tokenindex == 1) {
            _amounts = [0, amount, 0];
        } else if (tokenindex == 2) {
            _amounts = [0, 0, amount];
        } else {
            revert("wrong token index");
        }

        allow(enterTokenIERC20, address(curveAAVE));

        curveAAVE.add_liquidity(_amounts, 0, true);

        uint256 balance_a3 = A3Token.balanceOf(address(this));

        allow(A3Token, address(curveGauge));

        curveGauge.deposit(balance_a3);
    }

    /**
     * @dev function to fix allowance if needed
     */
    function allow(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) != uint256(-1)) {
            token.universalApprove(spender, uint256(-1));
        }
    }

    /**
     * @dev Main function to exit position - partially or completely
     */
    function exitPosition(uint256 amount) public onlyValueHolder {
        uint256 balance_a3 = A3Token.balanceOf(address(this));
        balance_a3 += curveGauge.balanceOf(address(this));
        uint256 a3_token_to_withdraw;

        if (amount == uint256(-1)) {
            //115792089237316195423570985008687907853269984665640564039457584007913129639935
            //10000000000000000000000

            //TODO: completely close position
            a3_token_to_withdraw = balance_a3;
        } else {
            // TODO partial close - find out how much
            uint256 totalStaked = getTokenStaked();

            require(amount <= totalStaked, "too much");

            a3_token_to_withdraw = amount.mul(balance_a3).div(totalStaked);
        }

        curveGauge.withdraw(a3_token_to_withdraw);

        int128 tokenindex = getCurveIndex(enterToken);

        require(tokenindex < 3, "wrong token index");

        curveAAVE.remove_liquidity_one_coin(
            a3_token_to_withdraw,
            tokenindex,
            0,
            true
        );
    }

    /**
     * @dev Get the total amount of enterToken value of the pool
     */
    function getTokenStaked() public view returns (uint256 totalTokenStaked) {
        uint256 a3CRVbalance = IERC20(curveGauge).balanceOf(address(this));
        a3CRVbalance += A3Token.balanceOf(address(this));

        uint256 a3CRVTotal = A3Token.totalSupply();
        uint256 balance;

        for (int128 i = 0; i < 3; i++) {
            balance = curveAAVE.balances(uint256(i)).mul(a3CRVbalance).div(
                a3CRVTotal
            );
            if (reverseCurveIndex[i] != enterToken) {
                balance = xchanger.quote(
                    IERC20(reverseCurveIndex[i]),
                    enterTokenIERC20,
                    balance
                );
            }

            totalTokenStaked += balance;
        }
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function getPoolValue(address denominateTo)
        public
        view
        returns (uint256 totalValue)
    {
        uint256 freeDAI = enterTokenIERC20.balanceOf(address(this));
        uint256 totalDAI = freeDAI.add(getTokenStaked());
        totalValue = quote(enterTokenIERC20, IERC20(denominateTo), totalDAI);

        //TODO: add CRV ???
        /*
        uint256 balanceComp = comp.balanceOf(address(this));
        if (balanceComp > 0) {
            uint256 compQuote = quote(comp, IERC20(denominateTo), balanceComp);
            totalValue = totalValue.add(compQuote);
        }
        */
    }

    /**
     * @dev Claim all available CRV from compound and convert to DAI as needed
     */
    function claimValue() external {
        minter.mint(address(curveGauge));
        convertCRV();
    }

    /**
     * @dev Convert CRV to [DAI] using XChanger (XTrinity swap)
     */
    function convertCRV() public {
        uint256 returnAmount;
        uint256 balanceCRV = crv.balanceOf(address(this));
        if (balanceCRV > 0) {
            returnAmount = swap(crv, enterTokenIERC20, balanceCRV, false);
        }
    }
}