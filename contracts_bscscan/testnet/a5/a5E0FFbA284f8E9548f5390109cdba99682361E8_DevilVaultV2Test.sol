/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT

/*
Devil Vault v2 

Devil Vault is a staking/yield-farming contract that allows holders of the Devil Token to stake their DEVL's in order to access to BUSD rewards from the contract. 
*/

pragma solidity ^0.7.6;


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


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns(bool);

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
            'SafeBEP20: approve from non-zero to non-zero allowance'
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
            'SafeBEP20: decreased allowance below zero'
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

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
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

    constructor() {
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


interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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


contract DevilVaultV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
   

    /*
    ========== STATE, EVENTS, MAPPINGS ==========
    */
    
    // Address For QuoteToken - this is the output token
    IBEP20 public rewardToken;
    // Address For WETH
    IBEP20 public stakingToken;
    
    uint256 totalStaked;
    uint256 allocatedBusd;
    uint256 allocatedDevl;
    uint256 claimedBusd;
    uint256 claimedDevl;
    
    bool depositsEnabled = true;
    
    mapping (address => Account) accounts;
    
    struct Account {
        uint256 userStaked;
        uint256 userBusdClaimed;
        uint256 userDevlClaimed;
    }
    
    constructor(address _rewardToken, address _stakingToken) {
        rewardToken = IBEP20(address(_rewardToken));
        stakingToken = IBEP20(address(_stakingToken));
    }

     /*
    ========== USER FUNCTIONS ==========
    */

    function stake(uint256 _amount) external {
        //Check to make sure they have staking tokens!
        require(stakingToken.balanceOf(msg.sender) <= _amount);
        require(depositsEnabled == true);
        //Force claim to clear up balances
        if(accounts[msg.sender].userStaked > 0) {
        claim();
        }
        //Take the staking tokens from them to contract, add it to the total staked, then personal balance
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        totalStaked += _amount;
        accounts[msg.sender].userStaked += _amount;
    }
    
    function unstake(uint256 _amount) external {
        //Make sure they have DEVL staked
        require(accounts[msg.sender].userStaked >= _amount);
        //Call claim to update balances
        claim();
        //Update balances then transfer tokens
        totalStaked -= _amount;
        accounts[msg.sender].userStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }
    
    function claim() public {
        //Make sure that they're actually staking!
        require(accounts[msg.sender].userStaked > 0);
        //Let's get that lovely pool share. Be mindful of 10**18 operator to prevent FP numbers
        uint256 userPoolShare = calculateUserPoolShare(msg.sender);
        //BUSD first, goes straight to wallet
        uint256 busdToClaim = (userPoolShare.mul(allocatedBusd)).sub(accounts[msg.sender].userBusdClaimed).div(10e18);
        claimedBusd += busdToClaim;
        accounts[msg.sender].userBusdClaimed += busdToClaim;
        rewardToken.transfer(msg.sender, busdToClaim);
        //Now DEVL, does the same except auto stakes
        uint256 devlToClaim = (userPoolShare.mul(allocatedDevl)).sub(accounts[msg.sender].userDevlClaimed).div(10e18);
        claimedDevl += devlToClaim;
        accounts[msg.sender].userDevlClaimed += devlToClaim;
        totalStaked += devlToClaim;
        accounts[msg.sender].userStaked += devlToClaim;
    }
    
    function distributeRewards() external {
        //Check to see how much busd has been accounted for but not yet claimed
        uint256 allocatedBusdInContract = allocatedBusd.sub(claimedBusd);
        //Figure out unallocated busd by checking busd balance minus what is in contract but already accounted for, then add to allocated
        uint256 unallocatedReward = rewardToken.balanceOf(address(this)).sub(allocatedBusdInContract);
        allocatedBusd += unallocatedReward;
        //Do the same for DEVL, but also factoring in staking amount, then add the DEVL so stakers can access
        uint256 allocatedDevlInContract = (allocatedDevl.sub(claimedDevl)).add(totalStaked);
        uint256 unallocatedDevl = stakingToken.balanceOf(address(this)).sub(allocatedDevlInContract);
        allocatedDevl += unallocatedDevl;
    }
    
    function getUserPendingRewardsBusd(address _user) external view returns(uint256){
        uint256 userPoolShare = calculateUserPoolShare(_user);
        uint256 busdToClaim = (userPoolShare.mul(allocatedBusd)).sub(accounts[msg.sender].userBusdClaimed).div(10e18);
        return(busdToClaim);
    }
    
    function getUserPendingRewardsDevl(address _user) external view returns(uint256){
        uint256 userPoolShare = calculateUserPoolShare(_user);
        uint256 devlToClaim = (userPoolShare.mul(allocatedDevl)).sub(accounts[msg.sender].userDevlClaimed).div(10e18);
        return(devlToClaim);
    }
    
    function getUserStakingBalance(address _user) external view returns(uint256){
        uint256 userStakingBalance = accounts[_user].userStaked;
        return(userStakingBalance);
    }
    
    function getUserLifetimeBusdRewards(address _user) external view returns(uint256){
        uint256 userLifetimeBusdRewards = accounts[_user].userBusdClaimed;
        return(userLifetimeBusdRewards);
    }
    
    function getUserLifetimeDevlRewards(address _user) external view returns(uint256){
        uint256 userLifetimeDevlRewards = accounts[_user].userDevlClaimed;
        return(userLifetimeDevlRewards);
    }
    
     /*
    ========== INTERNAL FUNCTIONS ==========
    */
    
    function calculateUserPoolShare(address _user) internal view returns(uint256) {
        uint256 userPoolShare = accounts[_user].userStaked.div(totalStaked.div(10**18));
        return(userPoolShare);
    }
    
     /*
    ========== ADMIN FUNCTIONS ==========
    */
    
    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = IBEP20(address(_stakingToken));
    }
    
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IBEP20(address(_rewardToken));
    }
    
    function emergencyToggleDeposits(bool _status) external onlyOwner {
        depositsEnabled = _status;
    }
    
    function emergencyWithdrawTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IBEP20(_tokenAddress).transfer(msg.sender, _amount);
    }

}

interface TokenInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract DevilVaultV2Test is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /*
    ========== STATE, CONSTRUCTOR, MAPPINGS ==========
    */
    
    // Address for reward token (BUSD)/staking token (DEVL)/WBNB
    IBEP20 public rewardToken;
    IBEP20 public stakingToken;
    IBEP20 public WBNB;
    address dexAddress;
    
    uint256 totalStaked;
    uint256 allocatedBusd;
    uint256 allocatedDevl;
    uint256 claimedBusd;
    uint256 claimedDevl;
    uint256 numberOfStakers;
    
    //Adjustabled number of minimum amount of tokens in this contract that determins when swap can happen
    uint256 public minNumBnbToSwap;
    
    bool depositsEnabled = true;
    bool swapEnabled = true;
    
    mapping (address => Account) accounts;
    
    struct Account {
        uint256 userStaked;
        uint256 userBusdClaimed;
        uint256 userDevlClaimed;
    }
    
    //Uniswap address is hardcoded 
    // Rinkeby Uni Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D Rinkeby WETH: 0xc778417E063141139Fce010982780140Aa0cD5Ab 
    //Pancake Testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Pancaketest WBNB: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd 
    //Pancake Main: 0x10ED43C718714eb63d5aA57B78B54704E256024E Pancake WBNB: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));

    //ATTENTION: WBNB IS HARDCODED. CHECK BEFORE DEPLOY.
    constructor(address _rewardToken, address _stakingToken) {
        rewardToken = IBEP20(address(_rewardToken));
        stakingToken = IBEP20(address(_stakingToken));
        WBNB = IBEP20(address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd));
    }

     /*
    ========== USER FUNCTIONS ==========
    */

    function stake(uint256 _amount) external nonReentrant {
        //Check to make sure they have staking tokens!
        require(stakingToken.balanceOf(msg.sender) >= _amount);
        require(depositsEnabled == true);
        //Force claim to clear up balances then do another if to increment staker #
        if(accounts[msg.sender].userStaked > 0) {
        claim();
        }
        if(accounts[msg.sender].userStaked == 0) {
            numberOfStakers ++;
        }
        //Take the staking tokens from user to contract, add it to the total staked, then personal balance
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        totalStaked += _amount;
        accounts[msg.sender].userStaked += _amount;
        emit Staked(_amount, msg.sender);
    }
    
    function unstake(uint256 _amount) external nonReentrant {
        //Make sure they have DEVL staked
        require(accounts[msg.sender].userStaked >= _amount);
        //Call claim to update balances
        claim();
        //Update balances then transfer tokens
        totalStaked -= _amount;
        accounts[msg.sender].userStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        if(accounts[msg.sender].userStaked == 0) {
            numberOfStakers --;
        }
        emit Unstaked(_amount, msg.sender);
    }

    //Allows users to withdraw without claiming rewards
    function emergencyWithdraw(uint256 _amount) external nonReentrant {
        //Make sure they have DEVL staked
        require(accounts[msg.sender].userStaked >= _amount);
        //Update balances then transfer tokens
        totalStaked -= _amount;
        accounts[msg.sender].userStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        if(accounts[msg.sender].userStaked == 0) {
            numberOfStakers --;
        }
        emit Unstaked(_amount, msg.sender);
    }
    
    function claim() public {
        //Make sure that they're actually staking!
        require(accounts[msg.sender].userStaked > 0);
        //BUSD first - goes straight to wallet
        if(allocatedBusd > 0){
            uint256 busdToClaim = getUserPendingRewardsBusd(msg.sender);
            claimedBusd += busdToClaim;
            accounts[msg.sender].userBusdClaimed += busdToClaim;
            rewardToken.transfer(msg.sender, busdToClaim);
        emit BusdClaimed(busdToClaim, msg.sender);
        }
        //Now DEVL, does the same, comment is for not currently used autostake.
        if(allocatedDevl > 0){
            uint256 devlToClaim = getUserPendingRewardsDevl(msg.sender);
            claimedDevl += devlToClaim;
            accounts[msg.sender].userDevlClaimed += devlToClaim;
            stakingToken.transfer(msg.sender, devlToClaim);
            totalStaked += devlToClaim;
            accounts[msg.sender].userStaked += devlToClaim;
            emit DevlClaimed(devlToClaim, msg.sender);
        }
    }
    
    function getUserPendingRewardsBusd(address _user) public view returns(uint256){
        uint256 userPoolShare = calculateUserPoolShare(_user);
        uint256 pendingBusdToClaim = (allocatedBusd.mul(userPoolShare)).div(10**18);
        uint256 busdToClaim = pendingBusdToClaim.sub(accounts[_user].userBusdClaimed);
        return(busdToClaim);
    }
    
    function getUserPendingRewardsDevl(address _user) public view returns(uint256){
        uint256 userPoolShare = calculateUserPoolShare(_user);
        uint256 pendingDevlToClaim = (allocatedDevl.mul(userPoolShare)).div(10**18);
        uint256 devlToClaim = pendingDevlToClaim.sub(accounts[_user].userDevlClaimed);
        return(devlToClaim);
    }
    
    function getUserStakingBalance(address _user) external view returns(uint256){
        uint256 userStakingBalance = accounts[_user].userStaked;
        return(userStakingBalance);
    }
    
    function getUserLifetimeBusdRewards(address _user) external view returns(uint256){
        uint256 userLifetimeBusdRewards = accounts[_user].userBusdClaimed;
        return(userLifetimeBusdRewards);
    }
    
    function getUserLifetimeDevlRewards(address _user) external view returns(uint256){
        uint256 userLifetimeDevlRewards = accounts[_user].userDevlClaimed;
        return(userLifetimeDevlRewards);
    }
    
    function getAllocatedRewardBusd() external view returns(uint256){
        return(allocatedBusd);
    }
    
    function getAllocatedRewardDevl() external view returns(uint256){
        return(allocatedDevl);
    }
    
    function getTokenBalances() external view returns (uint256, uint256) {
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        uint256 stakingBalance = stakingToken.balanceOf(address(this));
        return(rewardBalance, stakingBalance);
    }
    
    function getGlobalStaked() external view returns (uint256) {
        return(totalStaked);
    }
    
    function getNumOfStakers() external view returns (uint256) {
        return(numberOfStakers);
    }
    
     /*
    ========== INTERNAL FUNCTIONS ==========
    */
    
    function calculateUserPoolShare(address _user) public view returns(uint256) {
        uint256 userPoolShare = accounts[_user].userStaked.div(totalStaked.div(10**18));
        // uint256 pendingUserPoolShare = userPoolShare.mul(10000);
        return(userPoolShare);
    }
    
    function distributeRewards() internal {
        //Find the unallocated busd by checking busd balance minus what is in contract but already accounted for, then add to allocated
        uint256 allocatedBusdInContract = allocatedBusd.sub(claimedBusd);
        uint256 unallocatedReward = (rewardToken.balanceOf(address(this))).sub(allocatedBusdInContract);
        allocatedBusd = allocatedBusd.add(unallocatedReward);
        //Do the same for DEVL, but also factoring in staking amount, then add the DEVL so stakers can access
        if(stakingToken.balanceOf(address(this)) != totalStaked){
            uint256 allocatedDevlInContract = allocatedDevl.sub(claimedDevl);
            uint256 unallocatedDevl = (stakingToken.balanceOf(address(this))).sub(allocatedDevlInContract).sub(totalStaked);
            allocatedDevl = allocatedDevl.add(unallocatedDevl);
        }
        //emit RewardsDistributed(unallocatedReward, unallocatedDevl);
    }
    
     /*
    ========== ADMIN FUNCTIONS ==========
    */
    
    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = IBEP20(address(_stakingToken));
    }
    
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IBEP20(address(_rewardToken));
    }
    
    function emergencyToggleDeposits(bool _status) external onlyOwner {
        depositsEnabled = _status;
    }

    function emergencyToggleSwap(bool _status) external onlyOwner {
        swapEnabled = _status;
    }
    
    function callDistributeRewards() external onlyOwner {
        distributeRewards();
    }
    
    /*
    ========== SWAP FUNCTIONS ==========
    */
    
    //Allows contract to receive BNB and call the swap function on receipt
    receive() external payable {
        vaultSwap();
    }
     
    function vaultSwap() public payable {
        if(swapEnabled == true){
        require(address(rewardToken) != address(0), "Quote Token should not be zero address");
        address [] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(rewardToken);
    
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
        distributeRewards();
        emit Swapped(msg.value);
        }
    }

    function manualVaultSwap() external onlyOwner {
        require(address(rewardToken) != address(0), "Quote Token should not be zero address");
        address [] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(rewardToken);
    
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
        distributeRewards();
        emit Swapped(address(this).balance);
    }
        
    /*
    ========== EVENTS ==========
    */

    event Staked(uint256 _amount, address _user);
    event Unstaked(uint256 _amount, address _user);
    event DevlClaimed(uint256 _amountDevl, address _user);
    event BusdClaimed(uint256 _amountBusd, address _user);
    event RewardsDistributed(uint256 _amountBUSD, uint256 _amountDevl);
    event Swapped(uint256 _amountBnbSwapped);

}