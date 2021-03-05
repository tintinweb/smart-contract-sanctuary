/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;


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

// 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

// 
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

// 
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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

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
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
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

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

interface IRibbonFactory {
    function isInstrument(address instrument) external returns (bool);

    function getAdapter(string calldata protocolName)
        external
        view
        returns (address);

    function getAdapters()
        external
        view
        returns (address[] memory adaptersArray);

    function burnGasTokens() external;
}

enum OptionType {Invalid, Put, Call}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

contract InstrumentStorageV1 is Initializable, Ownable, ReentrancyGuard {
    IRibbonFactory public factory;
    address public underlying;
    address public strikeAsset;
    address public collateralAsset;
    uint256 public expiry;
    string public name;
    string public symbol;
    mapping(address => OldInstrumentPosition[]) private _instrumentPositions;

    uint256[100] private __instrumentGap;

    struct OldInstrumentPosition {
        bool exercised;
        OptionType[] optionTypes;
        uint32[] optionIDs;
        uint256[] amounts;
        uint256[] strikePrices;
        string[] venues;
    }
}

enum Venues {Unknown, Hegic, OpynGamma}

contract InstrumentStorageV2 {
    struct InstrumentPosition {
        bool exercised;
        uint8 callVenue;
        uint8 putVenue;
        uint32 callOptionID;
        uint32 putOptionID;
        uint256 amount;
        uint256 callStrikePrice;
        uint256 putStrikePrice;
    }

    mapping(address => InstrumentPosition[]) instrumentPositions;

    /**
     * @notice Returns the symbol of the instrument
     * @param _account is the address which has opened InstrumentPositions
     */
    function numOfPositions(address _account) public view returns (uint256) {
        return instrumentPositions[_account].length;
    }

    function getInstrumentPositions(address account)
        external
        view
        returns (InstrumentPosition[] memory positions)
    {
        return instrumentPositions[account];
    }

    function instrumentPosition(address account, uint256 positionID)
        external
        view
        returns (InstrumentPosition memory position)
    {
        return instrumentPositions[account][positionID];
    }
}

enum PurchaseMethod {Invalid, Contract, ZeroEx}

struct OptionTerms {
    address underlying;
    address strikeAsset;
    address collateralAsset;
    uint256 expiry;
    uint256 strikePrice;
    OptionType optionType;
    address paymentToken;
}

struct ZeroExOrder {
    address exchangeAddress;
    address buyTokenAddress;
    address sellTokenAddress;
    address allowanceTarget;
    uint256 protocolFee;
    uint256 makerAssetAmount;
    uint256 takerAssetAmount;
    bytes swapData;
}

interface IProtocolAdapter {
    /**
     * @notice Emitted when a new option contract is purchased
     */
    event Purchased(
        address indexed caller,
        string indexed protocolName,
        address indexed underlying,
        uint256 amount,
        uint256 optionID
    );

    /**
     * @notice Emitted when an option contract is exercised
     */
    event Exercised(
        address indexed caller,
        address indexed options,
        uint256 indexed optionID,
        uint256 amount,
        uint256 exerciseProfit
    );

    /**
     * @notice Name of the adapter. E.g. "HEGIC", "OPYN_V1". Used as index key for adapter addresses
     */
    function protocolName() external pure returns (string memory);

    /**
     * @notice Boolean flag to indicate whether to use option IDs or not.
     * Fungible protocols normally use tokens to represent option contracts.
     */
    function nonFungible() external pure returns (bool);

    /**
     * @notice Returns the purchase method used to purchase options
     */
    function purchaseMethod() external pure returns (PurchaseMethod);

    /**
     * @notice Check if an options contract exist based on the passed parameters.
     * @param optionTerms is the terms of the option contract
     */
    function optionsExist(OptionTerms calldata optionTerms)
        external
        view
        returns (bool);

    /**
     * @notice Get the options contract's address based on the passed parameters
     * @param optionTerms is the terms of the option contract
     */
    function getOptionsAddress(OptionTerms calldata optionTerms)
        external
        view
        returns (address);

    /**
     * @notice Gets the premium to buy `purchaseAmount` of the option contract in ETH terms.
     * @param optionTerms is the terms of the option contract
     * @param purchaseAmount is the number of options purchased
     */
    function premium(OptionTerms calldata optionTerms, uint256 purchaseAmount)
        external
        view
        returns (uint256 cost);

    /**
     * @notice Amount of profit made from exercising an option contract (current price - strike price). 0 if exercising out-the-money.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     */
    function exerciseProfit(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256 profit);

    function canExercise(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (bool);

    /**
     * @notice Purchases the options contract.
     * @param optionTerms is the terms of the option contract
     * @param amount is the purchase amount in Wad units (10**18)
     */
    function purchase(
        OptionTerms calldata optionTerms,
        uint256 amount,
        uint256 maxCost
    ) external payable returns (uint256 optionID);

    /**
     * @notice Exercises the options contract.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     * @param recipient is the account that receives the exercised profits. This is needed since the adapter holds all the positions and the msg.sender is an instrument contract.
     */
    function exercise(
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external payable;

    function createShort(OptionTerms calldata optionTerms, uint256 amount)
        external
        returns (uint256);

    function closeShort() external returns (uint256);
}

library ProtocolAdapter {
    function delegateOptionsExist(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms
    ) external view returns (bool) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "optionsExist((address,address,address,uint256,uint256,uint8,address))",
                    optionTerms
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (bool));
    }

    function delegateGetOptionsAddress(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms
    ) external view returns (address) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "getOptionsAddress((address,address,address,uint256,uint256,uint8,address))",
                    optionTerms
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (address));
    }

    function delegatePremium(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms,
        uint256 purchaseAmount
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "premium((address,address,address,uint256,uint256,uint8,address),uint256)",
                    optionTerms,
                    purchaseAmount
                )
            );
        require(success, "premium staticcall failed");
        return abi.decode(result, (uint256));
    }

    function delegateExerciseProfit(
        IProtocolAdapter adapter,
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "exerciseProfit(address,uint256,uint256)",
                    options,
                    optionID,
                    amount
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (uint256));
    }

    function delegatePurchase(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms,
        uint256 purchaseAmount,
        uint256 maxCost
    ) external returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "purchase((address,address,address,uint256,uint256,uint8,address),uint256,uint256)",
                    optionTerms,
                    purchaseAmount,
                    maxCost
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (uint256));
    }

    function delegatePurchaseWithZeroEx(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms,
        ZeroExOrder calldata zeroExOrder
    ) external {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "purchaseWithZeroEx((address,address,address,uint256,uint256,uint8,address),(address,address,address,address,uint256,uint256,uint256,bytes))",
                    optionTerms,
                    zeroExOrder
                )
            );
        require(success, getRevertMsg(result));
    }

    function delegateExercise(
        IProtocolAdapter adapter,
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external {
        (bool success, bytes memory res) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "exercise(address,uint256,uint256,address)",
                    options,
                    optionID,
                    amount,
                    recipient
                )
            );
        require(success, getRevertMsg(res));
    }

    function delegateClaimRewards(
        IProtocolAdapter adapter,
        address rewardsAddress,
        uint256[] calldata optionIDs
    ) external returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "claimRewards(address,uint256[])",
                    rewardsAddress,
                    optionIDs
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (uint256));
    }

    function delegateRewardsClaimable(
        IProtocolAdapter adapter,
        address rewardsAddress,
        uint256[] calldata optionIDs
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "rewardsClaimable(address,uint256[])",
                    rewardsAddress,
                    optionIDs
                )
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (uint256));
    }

    function delegateCreateShort(
        IProtocolAdapter adapter,
        OptionTerms calldata optionTerms,
        uint256 amount
    ) external returns (uint256) {
        (bool success, bytes memory res) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "createShort((address,address,address,uint256,uint256,uint8,address),uint256)",
                    optionTerms,
                    amount
                )
            );
        require(success, getRevertMsg(res));
        return abi.decode(res, (uint256));
    }

    function delegateCloseShort(IProtocolAdapter adapter)
        external
        returns (uint256)
    {
        (bool success, bytes memory res) =
            address(adapter).delegatecall(
                abi.encodeWithSignature("closeShort()")
            );
        require(success, getRevertMsg(res));
        return abi.decode(res, (uint256));
    }

    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// 
contract RibbonVolatility is DSMath, InstrumentStorageV1, InstrumentStorageV2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ProtocolAdapter for IProtocolAdapter;

    bytes32 private constant hegicHash = keccak256(bytes("HEGIC"));
    bytes32 private constant opynHash = keccak256(bytes("OPYN_GAMMA"));

    event PositionCreated(
        address indexed account,
        uint256 indexed positionID,
        string[] venues,
        OptionType[] optionTypes,
        uint256 amount
    );
    event Exercised(
        address indexed account,
        uint256 indexed positionID,
        uint256 totalProfit,
        bool[] optionsExercised
    );

    event ClaimedRewards(uint256 numRewards);

    receive() external payable {}

    function initialize(
        address _owner,
        address _factory,
        string memory _name,
        string memory _symbol,
        address _underlying,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _expiry
    ) public initializer {
        require(block.timestamp < _expiry, "Expiry has already passed");

        Ownable.initialize(_owner);
        factory = IRibbonFactory(_factory);
        name = _name;
        symbol = _symbol;
        expiry = _expiry;
        underlying = _underlying;
        strikeAsset = _strikeAsset;
        collateralAsset = _collateralAsset;
    }

    function exerciseProfit(address account, uint256 positionID)
        external
        view
        returns (uint256)
    {
        InstrumentPosition storage position =
            instrumentPositions[account][positionID];

        if (position.exercised) return 0;

        uint256 profit = 0;

        uint8[] memory venues = new uint8[](2);
        venues[0] = position.putVenue;
        venues[1] = position.callVenue;

        for (uint256 i = 0; i < venues.length; i++) {
            string memory venue = getAdapterName(venues[i]);
            uint256 amount = position.amount;

            OptionType optionType;
            uint256 strikePrice;
            uint32 optionID;
            if (i == 0) {
                strikePrice = position.putStrikePrice;
                optionID = position.putOptionID;
                optionType = OptionType.Put;
            } else {
                strikePrice = position.callStrikePrice;
                optionID = position.callOptionID;
                optionType = OptionType.Call;
            }

            address adapterAddress = factory.getAdapter(venue);
            require(adapterAddress != address(0), "Adapter does not exist");
            IProtocolAdapter adapter = IProtocolAdapter(adapterAddress);
            address options =
                adapter.getOptionsAddress(
                    OptionTerms(
                        underlying,
                        strikeAsset,
                        collateralAsset,
                        expiry,
                        strikePrice,
                        optionType,
                        address(0) // paymentToken is not used at all nor stored in storage
                    )
                );

            bool exercisable = adapter.canExercise(options, optionID, amount);
            if (!exercisable) {
                continue;
            }

            profit += adapter.delegateExerciseProfit(options, optionID, amount);
        }
        return profit;
    }

    function canExercise(address account, uint256 positionID)
        external
        view
        returns (bool)
    {
        InstrumentPosition storage position =
            instrumentPositions[account][positionID];

        if (position.exercised) return false;

        bool eitherOneCanExercise = false;

        uint8[] memory venues = new uint8[](2);
        venues[0] = position.putVenue;
        venues[1] = position.callVenue;

        for (uint256 i = 0; i < venues.length; i++) {
            string memory venue = getAdapterName(venues[i]);
            uint256 strikePrice;
            uint32 optionID;
            OptionType optionType;
            if (i == 0) {
                strikePrice = position.putStrikePrice;
                optionID = position.putOptionID;
                optionType = OptionType.Put;
            } else {
                strikePrice = position.callStrikePrice;
                optionID = position.callOptionID;
                optionType = OptionType.Call;
            }

            address adapterAddress = factory.getAdapter(venue);
            require(adapterAddress != address(0), "Adapter does not exist");
            IProtocolAdapter adapter = IProtocolAdapter(adapterAddress);

            address options =
                adapter.getOptionsAddress(
                    OptionTerms(
                        underlying,
                        strikeAsset,
                        address(0), // collateralAsset not needed
                        expiry,
                        strikePrice,
                        optionType,
                        address(0) // paymentToken is not used nor stored in storage
                    )
                );

            bool canExerciseOptions =
                adapter.canExercise(options, optionID, position.amount);

            if (canExerciseOptions) {
                eitherOneCanExercise = true;
            }
        }
        return eitherOneCanExercise;
    }

    struct BuyInstrumentParams {
        uint8 callVenue;
        uint8 putVenue;
        address paymentToken;
        uint256 callStrikePrice;
        uint256 putStrikePrice;
        uint256 amount;
        uint256 callMaxCost;
        uint256 putMaxCost;
        bytes callBuyData;
        bytes putBuyData;
    }

    function buyInstrument(BuyInstrumentParams calldata params)
        external
        payable
        nonReentrant
        returns (uint256 positionID)
    {
        require(block.timestamp < expiry, "Cannot purchase after expiry");

        factory.burnGasTokens();

        string memory callVenueName = getAdapterName(params.callVenue);
        string memory putVenueName = getAdapterName(params.putVenue);

        uint32 putOptionID =
            purchaseOptionAtVenue(
                putVenueName,
                OptionType.Put,
                params.amount,
                params.putStrikePrice,
                params.putBuyData,
                params.paymentToken,
                params.putMaxCost
            );
        uint32 callOptionID =
            purchaseOptionAtVenue(
                callVenueName,
                OptionType.Call,
                params.amount,
                params.callStrikePrice,
                params.callBuyData,
                params.paymentToken,
                params.callMaxCost
            );

        InstrumentPosition memory position =
            InstrumentPosition(
                false,
                params.callVenue,
                params.putVenue,
                callOptionID,
                putOptionID,
                params.amount,
                params.callStrikePrice,
                params.putStrikePrice
            );

        positionID = instrumentPositions[msg.sender].length;
        instrumentPositions[msg.sender].push(position);

        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);
    }

    function purchaseOptionAtVenue(
        string memory venue,
        OptionType optionType,
        uint256 amount,
        uint256 strikePrice,
        bytes memory buyData,
        address paymentToken,
        uint256 maxCost
    ) private returns (uint32 optionID) {
        address adapterAddress = factory.getAdapter(venue);
        require(adapterAddress != address(0), "Adapter does not exist");
        IProtocolAdapter adapter = IProtocolAdapter(adapterAddress);

        require(optionType != OptionType.Invalid, "Invalid option type");

        uint256 _expiry = expiry;

        Venues venueID = getVenueID(venue);

        if (venueID == Venues.OpynGamma) {
            purchaseWithZeroEx(
                adapter,
                optionType,
                strikePrice,
                buyData,
                _expiry
            );
        } else if (venueID == Venues.Hegic) {
            optionID = purchaseWithContract(
                adapter,
                optionType,
                amount,
                strikePrice,
                paymentToken,
                maxCost,
                _expiry
            );
        } else {
            revert("Venue not supported");
        }
    }

    function purchaseWithContract(
        IProtocolAdapter adapter,
        OptionType optionType,
        uint256 amount,
        uint256 strikePrice,
        address paymentToken,
        uint256 maxCost,
        uint256 _expiry
    ) private returns (uint32 optionID) {
        OptionTerms memory optionTerms =
            OptionTerms(
                underlying,
                strikeAsset,
                collateralAsset,
                _expiry,
                strikePrice,
                optionType,
                paymentToken
            );

        uint256 optionID256 =
            adapter.delegatePurchase(optionTerms, amount, maxCost);
        optionID = uint32(optionID256);
    }

    function purchaseWithZeroEx(
        IProtocolAdapter adapter,
        OptionType optionType,
        uint256 strikePrice,
        bytes memory buyData,
        uint256 _expiry
    ) private {
        OptionTerms memory optionTerms =
            OptionTerms(
                underlying,
                strikeAsset,
                collateralAsset,
                _expiry,
                strikePrice,
                optionType,
                address(0)
            );

        ZeroExOrder memory zeroExOrder = abi.decode(buyData, (ZeroExOrder));

        adapter.delegatePurchaseWithZeroEx(optionTerms, zeroExOrder);
    }

    function exercisePosition(uint256 positionID)
        external
        nonReentrant
        returns (uint256 totalProfit)
    {
        InstrumentPosition storage position =
            instrumentPositions[msg.sender][positionID];
        require(!position.exercised, "Already exercised");

        bool[] memory optionsExercised = new bool[](2);
        uint8[] memory venues = new uint8[](2);
        venues[0] = position.putVenue;
        venues[1] = position.callVenue;

        for (uint256 i = 0; i < venues.length; i++) {
            string memory adapterName = getAdapterName(venues[i]);
            IProtocolAdapter adapter =
                IProtocolAdapter(factory.getAdapter(adapterName));

            OptionType optionType;
            uint256 strikePrice;
            uint32 optionID;
            if (i == 0) {
                strikePrice = position.putStrikePrice;
                optionID = position.putOptionID;
                optionType = OptionType.Put;
            } else {
                strikePrice = position.callStrikePrice;
                optionID = position.callOptionID;
                optionType = OptionType.Call;
            }

            address paymentToken = address(0); // it is irrelevant at this stage

            address optionsAddress =
                adapter.getOptionsAddress(
                    OptionTerms(
                        underlying,
                        strikeAsset,
                        collateralAsset,
                        expiry,
                        strikePrice,
                        optionType,
                        paymentToken
                    )
                );

            require(optionsAddress != address(0), "Options address must exist");

            uint256 amount = position.amount;

            uint256 profit =
                adapter.delegateExerciseProfit(
                    optionsAddress,
                    optionID,
                    amount
                );
            if (profit > 0) {
                adapter.delegateExercise(
                    optionsAddress,
                    optionID,
                    amount,
                    msg.sender
                );
                optionsExercised[i] = true;
            } else {
                optionsExercised[i] = false;
            }
            totalProfit += profit;
        }
        position.exercised = true;

        emit Exercised(msg.sender, positionID, totalProfit, optionsExercised);
    }

    function claimRewards(address rewardsAddress) external {
        IProtocolAdapter adapter =
            IProtocolAdapter(factory.getAdapter("HEGIC"));
        uint256[] memory optionIDs = getOptionIDs(msg.sender);
        uint256 claimedRewards =
            adapter.delegateClaimRewards(rewardsAddress, optionIDs);
        emit ClaimedRewards(claimedRewards);
    }

    function rewardsClaimable(address rewardsAddress)
        external
        view
        returns (uint256 rewardsToClaim)
    {
        IProtocolAdapter adapter =
            IProtocolAdapter(factory.getAdapter("HEGIC"));
        uint256[] memory optionIDs = getOptionIDs(msg.sender);
        rewardsToClaim = adapter.delegateRewardsClaimable(
            rewardsAddress,
            optionIDs
        );
    }

    function getOptionIDs(address user)
        private
        view
        returns (uint256[] memory optionIDs)
    {
        uint256 i = 0;
        uint256 j = 0;

        InstrumentPosition[] memory positions = instrumentPositions[user];

        optionIDs = new uint256[](positions.length.mul(2));

        while (i < positions.length) {
            if (
                keccak256(bytes(getAdapterName(positions[i].callVenue))) ==
                hegicHash
            ) {
                optionIDs[j] = positions[i].callOptionID;
                j += 1;
            }
            if (
                keccak256(bytes(getAdapterName(positions[i].putVenue))) ==
                hegicHash
            ) {
                optionIDs[j] = positions[i].putOptionID;
                j += 1;
            }
            i += 1;
        }
    }

    function getAdapterName(uint8 venueID)
        private
        pure
        returns (string memory)
    {
        if (venueID == uint8(Venues.Hegic)) {
            return "HEGIC";
        } else if (venueID == uint8(Venues.OpynGamma)) {
            return "OPYN_GAMMA";
        }
        return "";
    }

    function getVenueID(string memory venueName) private pure returns (Venues) {
        if (keccak256(bytes(venueName)) == hegicHash) {
            return Venues.Hegic;
        } else if (keccak256(bytes(venueName)) == opynHash) {
            return Venues.OpynGamma;
        }
        return Venues.Unknown;
    }
}