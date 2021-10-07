/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

    pragma solidity >=0.6.0 <0.8.0;
    pragma experimental ABIEncoderV2;

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

    /**
    * @title Initializable
    *
    * @dev Helper contract to support initializer functions. To use it, replace
    * the constructor with a function that has the `initializer` modifier.
    * WARNING: Unlike constructors, initializer functions must be manually
    * invoked. This applies both to deploying an Initializable contract, as well
    * as extending an Initializable contract via inheritance.
    * WARNING: When used with inheritance, manual care must be taken to not invoke
    * a parent initializer twice, or ensure that all initializers are idempotent,
    * because this is not dealt with automatically as with constructors.
    */
    contract Initializable {

    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
    }

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
    contract ContextUpgradeSafe is Initializable {
        // Empty internal constructor, to prevent people from mistakenly deploying
        // an instance of this contract, which should be used via inheritance.

        function __Context_init() internal initializer {
            __Context_init_unchained();
        }

        function __Context_init_unchained() internal initializer {


        }


        function _msgSender() internal view virtual returns (address payable) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }

        uint256[50] private __gap;
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
    * `onlyOwner`, which can be applied to your functions to restrict their use to
    * the owner.
    */
    contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
        address private _owner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */

        function __Ownable_init() internal initializer {
            __Context_init_unchained();
            __Ownable_init_unchained();
        }

        function __Ownable_init_unchained() internal initializer {


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

        uint256[49] private __gap;
    }

    contract Configurable is OwnableUpgradeSafe {

        mapping (bytes32 => uint) internal config;
        
        function getConfig(bytes32 key) public view returns (uint) {
            return config[key];
        }
        function getConfig(bytes32 key, uint index) public view returns (uint) {
            return config[bytes32(uint(key) ^ index)];
        }
        function getConfig(bytes32 key, address addr) public view returns (uint) {
            return config[bytes32(uint(key) ^ uint(addr))];
        }

        function _setConfig(bytes32 key, uint value) internal {
            if(config[key] != value)
                config[key] = value;
        }
        function _setConfig(bytes32 key, uint index, uint value) internal {
            _setConfig(bytes32(uint(key) ^ index), value);
        }
        function _setConfig(bytes32 key, address addr, uint value) internal {
            _setConfig(bytes32(uint(key) ^ uint(addr)), value);
        }
        
        function setConfig(bytes32 key, uint value) external onlyOwner {
            _setConfig(key, value);
        }
        function setConfig(bytes32 key, uint index, uint value) external onlyOwner {
            _setConfig(bytes32(uint(key) ^ index), value);
        }
        function setConfig(bytes32 key, address addr, uint value) public onlyOwner {
            _setConfig(bytes32(uint(key) ^ uint(addr)), value);
        }
    }


    interface IAnnexStake {
        function depositReward() external payable;
    }

    contract AnnexDutchAuction is Configurable, ReentrancyGuard {
        using SafeMath for uint256;
        using SafeERC20 for IERC20;
        using Address for address;
        bytes32 internal constant TxFeeRatio = bytes32("TxFeeRatio");
        bytes32 internal constant MinValueOfBotHolder =
            bytes32("MinValueOfBotHolder");
        bytes32 internal constant BotToken = bytes32("BotToken");
        bytes32 internal constant StakeContract = bytes32("StakeContract");
        struct CreateReq {
            string name;
            address payable creator;
            address token0;
            address token1;
            uint256 amountTotal0;
            uint256 amountMax1;
            uint256 amountMin1;
            uint256 times;
            uint256 openAt;
            uint256 closeAt;
            bool onlyBot;
            bool enableWhiteList;
        }
        struct Pool {
            string name;
            address payable creator;
            address token0;
            address token1;
            uint256 amountTotal0;
            uint256 amountMax1;
            uint256 amountMin1;
            uint256 times;
            uint256 duration;
            uint256 openAt;
            uint256 closeAt;
            bool enableWhiteList;
        }
        Pool[] public pools;
        mapping(uint256 => uint256) public amountSwap0P;
        mapping(uint256 => uint256) public amountSwap1P;
        mapping(uint256 => bool) public creatorClaimedP;
        mapping(uint256 => bool) public onlyBotHolderP;
        mapping(uint256 => uint256) public lowestBidPrice;
        mapping(address => mapping(uint256 => bool)) public bidderClaimedP;
        mapping(address => mapping(uint256 => uint256)) public myAmountSwap0P;
        mapping(address => mapping(uint256 => uint256)) public myAmountSwap1P;
        mapping(address => uint256) public myCreatedP;
        bool public enableWhiteList;
        mapping(uint256 => mapping(address => bool)) public whitelistP;
        event Created(uint256 indexed index, address indexed sender, Pool pool);
        event Bid(
            uint256 indexed index,
            address indexed sender,
            uint256 amount0,
            uint256 amount1
        );
        event Claimed(
            uint256 indexed index,
            address indexed sender,
            uint256 unFilledAmount0
        );
        function initialize() public initializer {
    
            config[TxFeeRatio] = 0.005 ether; // 0.5%
            config[MinValueOfBotHolder] = 60 ether;
            config[BotToken] = uint256(uint160(0xA9B1Eb5908CfC3cdf91F9B8B3a74108598009096)); // AUCTION
            config[StakeContract] = uint256(
                uint160(0x98945BC69A554F8b129b09aC8AfDc2cc2431c48E)
            );
        }
        function initialize_rinkeby() public {
            initialize();
            config[BotToken] = uint256(uint160(0x5E26FA0FE067d28aae8aFf2fB85Ac2E693BD9EfA)); // AUCTION
            config[StakeContract] = uint256(
                uint160(0xa77A9FcbA2Ae5599e0054369d1655D186020ECE1)
            );
        }
        function initialize_bsc() public {
            initialize();
            config[BotToken] = uint256(uint160(0x1188d953aFC697C031851169EEf640F23ac8529C)); // AUCTION
            config[StakeContract] = uint256(
                uint160(0x1dd665ba1591756aa87157F082F175bDcA9fB91a)
            );
        }
        function create(CreateReq memory poolReq, address[] memory whitelist_)
            external
            nonReentrant
        {
            require(tx.origin == msg.sender, "disallow contract caller");
            require(poolReq.amountTotal0 != 0, "the value of amountTotal0 is zero");
            require(poolReq.amountMin1 != 0, "the value of amountMax1 is zero");
            require(poolReq.amountMax1 != 0, "the value of amountMin1 is zero");
            require(
                poolReq.amountMax1 > poolReq.amountMin1,
                "amountMax1 should larger than amountMin1"
            );
            require(
                poolReq.openAt <= poolReq.closeAt &&
                    poolReq.closeAt.sub(poolReq.openAt) < 7 days,
                "invalid closed"
            );
            require(poolReq.times != 0, "the value of times is zero");
            require(
                bytes(poolReq.name).length <= 15,
                "the length of name is too long"
            );
            uint256 index = pools.length;
            IERC20 _token0 = IERC20(poolReq.token0);
            uint256 token0BalanceBefore = _token0.balanceOf(address(this));
            _token0.safeTransferFrom(
                poolReq.creator,
                address(this),
                poolReq.amountTotal0
            );
            require(
                _token0.balanceOf(address(this)).sub(token0BalanceBefore) ==
                    poolReq.amountTotal0,
                "not support deflationary token"
            );
            if (poolReq.enableWhiteList) {
                require(whitelist_.length > 0, "no whitelist imported");
                _addWhitelist(index, whitelist_);
            }
            Pool memory pool;
            pool.name = poolReq.name;
            pool.creator = poolReq.creator;
            pool.token0 = poolReq.token0;
            pool.token1 = poolReq.token1;
            pool.amountTotal0 = poolReq.amountTotal0;
            pool.amountMax1 = poolReq.amountMax1;
            pool.amountMin1 = poolReq.amountMin1;
            pool.times = poolReq.times;
            pool.duration = poolReq.closeAt.sub(poolReq.openAt);
            pool.openAt = poolReq.openAt;
            pool.closeAt = poolReq.closeAt;
            pool.enableWhiteList = poolReq.enableWhiteList;
            pools.push(pool);
            if (poolReq.onlyBot) {
                onlyBotHolderP[index] = poolReq.onlyBot;
            }
            myCreatedP[poolReq.creator] = pools.length;
            emit Created(index, msg.sender, pool);
        }
        function bid(
            uint256 index,
            uint256 amount0,
            uint256 amount1
        )
            external
            payable
            nonReentrant
            isPoolExist(index)
            checkBotHolder(index)
            isPoolNotClosed(index)
        {
            address payable sender = payable(msg.sender) ;
            require(tx.origin == msg.sender, "disallow contract caller");
            if (enableWhiteList) {
                require(whitelistP[index][sender], "sender not in whitelist");
            }
            Pool memory pool = pools[index];
            require(pool.openAt <= block.timestamp , "pool not open");
            require(amount0 != 0, "the value of amount0 is zero");
            require(amount1 != 0, "the value of amount1 is zero");
            require(pool.amountTotal0 > amountSwap0P[index], "swap amount is zero");
            uint256 curPrice = currentPrice(index);
            uint256 bidPrice = amount1.mul(1 ether).div(amount0);
            require(
                bidPrice >= curPrice,
                "the bid price is lower than the current price"
            );
            if (lowestBidPrice[index] == 0 || lowestBidPrice[index] > bidPrice) {
                lowestBidPrice[index] = bidPrice;
            }
            address token1 = pool.token1;
            if (token1 == address(0)) {
                require(amount1 == msg.value, "invalid ETH amount");
            } else {
                IERC20(token1).safeTransferFrom(sender, address(this), amount1);
            }
            _swap(sender, index, amount0, amount1);
            emit Bid(index, sender, amount0, amount1);
        }
        function creatorClaim(uint256 index)
            external
            nonReentrant
            isPoolExist(index)
            isPoolClosed(index)
        {
            address payable creator = payable(msg.sender);
            require(isCreator(creator, index), "sender is not pool creator");
            require(!creatorClaimedP[index], "creator has claimed this pool");
            creatorClaimedP[index] = true;
            delete myCreatedP[creator];
            Pool memory pool = pools[index];
            uint256 unFilledAmount0 = pool.amountTotal0.sub(amountSwap0P[index]);
            if (unFilledAmount0 > 0) {
                IERC20(pool.token0).safeTransfer(creator, unFilledAmount0);
            }
            uint256 amount1 = lowestBidPrice[index].mul(amountSwap0P[index]).div(
                1 ether
            );
            if (amount1 > 0) {
                if (pool.token1 == address(0)) {
                    uint256 txFee = amount1.mul(getTxFeeRatio()).div(1 ether);
                    uint256 _actualAmount1 = amount1.sub(txFee);
                    if (_actualAmount1 > 0) {
                        pool.creator.transfer(_actualAmount1);
                    }
                    if (txFee > 0) {
                        IAnnexStake(getStakeContract()).depositReward{
                            value: txFee
                        }();
                    }
                } else {
                    IERC20(pool.token1).safeTransfer(pool.creator, amount1);
                }
            }
            emit Claimed(index, creator, unFilledAmount0);
        }
        function bidderClaim(uint256 index)
            external
            nonReentrant
            isPoolExist(index)
            isPoolClosed(index)
        {
            address payable bidder = payable(msg.sender);
            require(!bidderClaimedP[bidder][index], "bidder has claimed this pool");
            bidderClaimedP[bidder][index] = true;
            Pool memory pool = pools[index];
            if (myAmountSwap0P[bidder][index] > 0) {
                IERC20(pool.token0).safeTransfer(
                    bidder,
                    myAmountSwap0P[bidder][index]
                );
            }
            uint256 actualAmount1 = lowestBidPrice[index]
                .mul(myAmountSwap0P[bidder][index])
                .div(1 ether);
            uint256 unfilledAmount1 = myAmountSwap1P[bidder][index].sub(
                actualAmount1
            );
            if (unfilledAmount1 > 0) {
                if (pool.token1 == address(0)) {
                    bidder.transfer(unfilledAmount1);
                } else {
                    IERC20(pool.token1).safeTransfer(bidder, unfilledAmount1);
                }
            }
        }
        function _swap(
            address payable sender,
            uint256 index,
            uint256 amount0,
            uint256 amount1
        ) private {
            Pool memory pool = pools[index];
            uint256 _amount0 = pool.amountTotal0.sub(amountSwap0P[index]);
            uint256 _amount1 = 0;
            uint256 _excessAmount1 = 0;
            if (_amount0 < amount0) {
                _amount1 = _amount0.mul(amount1).div(amount0);
                _excessAmount1 = amount1.sub(_amount1);
            } else {
                _amount0 = amount0;
                _amount1 = amount1;
            }
            myAmountSwap0P[sender][index] = myAmountSwap0P[sender][index].add(
                _amount0
            );
            myAmountSwap1P[sender][index] = myAmountSwap1P[sender][index].add(
                _amount1
            );
            amountSwap0P[index] = amountSwap0P[index].add(_amount0);
            amountSwap1P[index] = amountSwap1P[index].add(_amount1);
            if (_excessAmount1 > 0) {
                if (pool.token1 == address(0)) {
                    sender.transfer(_excessAmount1);
                } else {
                    IERC20(pool.token1).safeTransfer(sender, _excessAmount1);
                }
            }
        }
        function isCreator(address target, uint256 index)
            private
            view
            returns (bool)
        {
            if (pools[index].creator == target) {
                return true;
            }
            return false;
        }
        function currentPrice(uint256 index) public view returns (uint256) {
            Pool memory pool = pools[index];
            uint256 _amount1 = pool.amountMin1;
            uint256 realTimes = pool.times.add(1);
            if (block.timestamp < pool.closeAt) {
                uint256 stepInSeconds = pool.duration.div(realTimes);
                if (stepInSeconds != 0) {
                    uint256 remainingTimes = pool.closeAt.sub(block.timestamp).sub(1).div(
                        stepInSeconds
                    );
                    if (remainingTimes != 0) {
                        _amount1 = pool
                            .amountMax1
                            .sub(pool.amountMin1)
                            .mul(remainingTimes)
                            .div(pool.times)
                            .add(pool.amountMin1);
                    }
                }
            }
            return _amount1.mul(1 ether).div(pool.amountTotal0);
        }
        function nextRoundInSeconds(uint256 index) public view returns (uint256) {
            Pool memory pool = pools[index];
            if (block.timestamp >= pool.closeAt) return 0;
            uint256 realTimes = pool.times.add(1);
            uint256 stepInSeconds = pool.duration.div(realTimes);
            if (stepInSeconds == 0) return 0;
            uint256 remainingTimes = pool.closeAt.sub(block.timestamp).sub(1).div(
                stepInSeconds
            );
            return pool.closeAt.sub(remainingTimes.mul(stepInSeconds)).sub(block.timestamp);
        }
        function _addWhitelist(uint256 index, address[] memory whitelist_) private {
            for (uint256 i = 0; i < whitelist_.length; i++) {
                whitelistP[index][whitelist_[i]] = true;
            }
        }
        function addWhitelist(uint256 index, address[] memory whitelist_) external {
            require(
                owner() == msg.sender || pools[index].creator == msg.sender,
                "no permission"
            );
            _addWhitelist(index, whitelist_);
        }
        function removeWhitelist(uint256 index, address[] memory whitelist_)
            external
        {
            require(
                owner() == msg.sender || pools[index].creator == msg.sender,
                "no permission"
            );
            for (uint256 i = 0; i < whitelist_.length; i++) {
                delete whitelistP[index][whitelist_[i]];
            }
        }
        function getPoolCount() public view returns (uint256) {
            return pools.length;
        }
        function getTxFeeRatio() public view returns (uint256) {
            return config[TxFeeRatio];
        }
        function getMinValueOfBotHolder() public view returns (uint256) {
            return config[MinValueOfBotHolder];
        }
        function getBotToken() public view returns (address) {
            return address(uint160(config[BotToken]));
        }
        function getStakeContract() public view returns (address) {
            return address(uint160(config[StakeContract]));
        }
        modifier checkBotHolder(uint256 index) {
            if (onlyBotHolderP[index]) {
                require(
                    IERC20(getBotToken()).balanceOf(msg.sender) >=
                        getMinValueOfBotHolder(),
                    "BOT is not enough"
                );
            }
            _;
        }
        modifier isPoolClosed(uint256 index) {
            require(pools[index].closeAt <= block.timestamp, "this pool is not closed");
            _;
        }
        modifier isPoolNotClosed(uint256 index) {
            require(pools[index].closeAt > block.timestamp, "this pool is closed");
            _;
        }
        modifier isPoolNotCreate(address target) {
            if (myCreatedP[target] > 0) {
                revert("a pool has created by this address");
            }
            _;
        }
        modifier isPoolExist(uint256 index) {
            require(index < pools.length, "this pool does not exist");
            _;
        }
    }