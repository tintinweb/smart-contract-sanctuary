/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

    function _msgSender() internal view virtual returns (address) {
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

interface IMorrox {
    function escrowLockToken(uint256 _tokenId, bool _lock) external;
    function escrowTransferOwnerToken(uint256 _tokenId, address _newOwner) external;
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function totalReserve() external view returns (uint256);
    function reserveBalanceOf(uint256 _tokenId) external view returns (uint256);
    function escrowPrice(uint256 _tokenId) external view returns (uint256);
    
    // IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IValidatorTeam {
    function isValidator(address _address) external view returns(bool);
}

contract Escrow is ContextUpgradeSafe/*, ReentrancyGuardUpgradeable*/, OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    enum ORDER_STATUS { PAYMENT, SHIPMENT, RECEIVED, APPEAL, CANCEL }
    struct OrderInfo{
        uint256 orderId;
        ORDER_STATUS orderStatus;
        address seller;
        address buyer;
        address validator;
        uint256 tokenId;
        uint256 price;
        address receivedBy;
        address appealBy;
        address cancelBy;
    }
    OrderInfo[] public order_list;
    uint256 private currentOrderId;
    bool public escrowPause;
    
    // incentive
    uint256 public constant MAX_FEE = 200; // max 2%
    uint256 public validatorFee;
    uint256 public platformFee;
    
    // stat
    uint256 public totalOrderActive;
    uint256 public totalOrderFinish;
    uint256 public totalOrderCancel;
    uint256 public totalSoldlValue;
    
    // validator
    mapping(address => uint256) validatorOrderActive;
    
    // address
    address public morrox;
    address public ttUSDToken;
    address public validatorTeam;
    address public feeAddress;
    
    // morrox sell stat
    struct MorroxSellInfo{
        uint256 ratingScore; // accumulate of rating score (0-5)
        uint256 ratingCount; // total buyer rating
        uint256 sellCount; // total sold
    }
    mapping(uint256 => MorroxSellInfo) public morroxSellStat;
    
    // seller stat
    struct SellerInfo{
        uint256 sellCount; // total sold
        uint256 disputeCount;
        uint256 disputeWon;
        uint256 disputeLost;
    }
    mapping(address => SellerInfo) public sellerStat;
    
    // events
    event OrderPayment(address indexed buyer, uint256 indexed tokenId, uint256 orderId);
    event OrderShipment(uint256 indexed orderId); 
    event OrderReceive(uint256 indexed orderId); 
    event OrderAppeal(uint256 indexed orderId); 
    event OrderCancel(uint256 indexed orderId); 
    event OrderReceiveByValidator(uint256 indexed orderId); 
    event OrderCancelByValidator(uint256 indexed orderId); 
    event UpdateMorroxSellStat(uint256 indexed tokenId, uint256 ratingScore, uint256 ratingCount, uint256 sellCount);
    event UpdateSellerStat(address indexed seller, uint256 sellCount, uint256 disputeCount, uint256 disputeWon, uint256 disputeLost);
    
    function initialize(address _morrox, address _validatorTeam, address _feeAddress) external initializer {
        OwnableUpgradeSafe.__Ownable_init();
    
        morrox = _morrox;
        validatorTeam = _validatorTeam;
        feeAddress = _feeAddress;
        ttUSDToken = 0x396ffa77cF10Fa8649Fed8Dd6E8138edc51C5555;  
        validatorFee = 50; // 0.5%
        platformFee = 50; // 0.5%
    }
    
    // ------------------------------
    // seller / buyer
    // ------------------------------
    function orderPayment(uint256 _tokenId, address _validator) external /*nonReentrant*/ {
        uint256 _price = IMorrox(morrox).escrowPrice(_tokenId);
        require(_price > 0, "!price");
        require(IValidatorTeam(validatorTeam).isValidator(_validator), "!validator");
        require(!escrowPause, "escrowPause");
        
        address _seller = IMorrox(morrox).ownerOf(_tokenId);
        
        // payment 
        IERC20(ttUSDToken).transferFrom(_msgSender(), address(this), _price);
        
        // add new order
        uint256 orderId = currentOrderId;
        currentOrderId++;
        
        order_list.push(
            OrderInfo({
                orderId: orderId,
                orderStatus: ORDER_STATUS.PAYMENT,
                seller: _seller,
                buyer: _msgSender(),
                validator: _validator,
                tokenId: _tokenId,
                price: _price,
                receivedBy: address(0),
                appealBy: address(0),
                cancelBy: address(0)
            })
        );
        
        // lock
        IMorrox(morrox).escrowLockToken(_tokenId, true);
        
        // validator
        validatorOrderActive[_validator]++;
        
        // stat
        totalOrderActive++;
        
        emit OrderPayment(_msgSender(), _tokenId,orderId);
    }
    
    function orderShipment(uint256 _orderId) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.seller == _msgSender(), "!seller");
        require(_order.orderStatus == ORDER_STATUS.PAYMENT, "order status !PAYMENT");
        
        _order.orderStatus = ORDER_STATUS.SHIPMENT;
        
        emit OrderShipment(_orderId);
    }
    
    function orderReceive(uint256 _orderId, uint256 _rating) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.buyer == _msgSender(), "!buyer");
        require(_order.orderStatus == ORDER_STATUS.SHIPMENT, "order status !SHIPMENT");
        require(_rating <= 5, "rating must between 0-5");
        
        _order.orderStatus = ORDER_STATUS.RECEIVED;
        _order.receivedBy = _msgSender();
        
        // incentive
        uint256 _validatorFee = _order.price.mul(validatorFee).div(10000);
        uint256 _platformFee = _order.price.mul(platformFee).div(10000);
        IERC20(ttUSDToken).safeTransfer(_order.validator, _validatorFee);
        IERC20(ttUSDToken).safeTransfer(feeAddress, _platformFee);
        
        // transfer to seller 
        IERC20(ttUSDToken).safeTransfer(_order.seller, _order.price.sub(_validatorFee).sub(_platformFee));
        
        // unlock
        IMorrox(morrox).escrowLockToken(_order.tokenId, false);
        
        // validator
        validatorOrderActive[_order.validator]--;
        
        // stat
        totalOrderActive--;
        totalOrderFinish++;
        totalSoldlValue = totalSoldlValue.add(_order.price);
        
        // morrox sell stat
        MorroxSellInfo storage _morroxSellStat = morroxSellStat[_order.tokenId];
        _morroxSellStat.ratingScore = _morroxSellStat.ratingScore.add(_rating);
        _morroxSellStat.ratingCount++;
        _morroxSellStat.sellCount++;
        
        // seller stat
        SellerInfo storage _sellerStat = sellerStat[_order.seller];
        _sellerStat.sellCount++;
        
        emit OrderReceive(_orderId);
        emit UpdateMorroxSellStat(_order.tokenId, _morroxSellStat.ratingScore, _morroxSellStat.ratingCount, _morroxSellStat.sellCount);
        emit UpdateSellerStat(_order.seller, _sellerStat.sellCount, _sellerStat.disputeCount, _sellerStat.disputeWon, _sellerStat.disputeLost);
    }
    
    function orderAppeal(uint256 _orderId) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.seller == _msgSender() || _order.buyer == _msgSender(), "!seller or !buyer");
        require(_order.orderStatus == ORDER_STATUS.PAYMENT || _order.orderStatus == ORDER_STATUS.SHIPMENT, "order status !SHIPMENT");
        
        // request to validator decide
        _order.orderStatus = ORDER_STATUS.APPEAL;
        _order.appealBy = _msgSender();
        
        // seller stat
        SellerInfo storage _sellerStat = sellerStat[_order.seller];
        _sellerStat.disputeCount++;
        
        emit OrderAppeal(_orderId);
        emit UpdateSellerStat(_order.seller, _sellerStat.sellCount, _sellerStat.disputeCount, _sellerStat.disputeWon, _sellerStat.disputeLost);
    }
    
    function orderCancel(uint256 _orderId) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.seller == _msgSender(), "!seller");
        require(_order.orderStatus == ORDER_STATUS.PAYMENT, "order status !PAYMENT");
        
        _order.orderStatus = ORDER_STATUS.CANCEL;
        _order.cancelBy = _msgSender();
        
        // transfer back to buyer
        IERC20(ttUSDToken).safeTransfer(_order.buyer, _order.price);
        
        // unlock
        IMorrox(morrox).escrowLockToken(_order.tokenId, false);
        
        // validator
        validatorOrderActive[_order.validator]--;
        
        // stat
        totalOrderActive--;
        totalOrderCancel++;
        
        emit OrderCancel(_orderId);
    }
    
    // ------------------------------
    // onlyValidator
    // ------------------------------
    function orderReceiveByValidator(uint256 _orderId) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.validator == _msgSender(), "!validator");
        require(_order.orderStatus == ORDER_STATUS.APPEAL, "order status !APPEAL");
        
        _order.orderStatus = ORDER_STATUS.RECEIVED;
        _order.receivedBy = _msgSender();
        
        // incentive
        uint256 _validatorFee = _order.price.mul(validatorFee).div(10000);
        uint256 _platformFee = _order.price.mul(platformFee).div(10000);
        IERC20(ttUSDToken).safeTransfer(_order.validator, _validatorFee);
        IERC20(ttUSDToken).safeTransfer(feeAddress, _platformFee);
        
        // transfer to seller 
        IERC20(ttUSDToken).safeTransfer(_order.seller, _order.price.sub(_validatorFee).sub(_platformFee));
        
        // unlock
        IMorrox(morrox).escrowLockToken(_order.tokenId, false);
        
        // validator
        validatorOrderActive[_order.validator]--;
        
        // stat
        totalOrderActive--;
        totalOrderFinish++;
        totalSoldlValue = totalSoldlValue.add(_order.price);
        
        // morrox sell stat
        MorroxSellInfo storage _morroxSellStat = morroxSellStat[_order.tokenId];
        _morroxSellStat.sellCount++;
        
        // seller stat
        SellerInfo storage _sellerStat = sellerStat[_order.seller];
        _sellerStat.sellCount++;
        _sellerStat.disputeWon++;
        
        emit OrderReceiveByValidator(_orderId);
        emit UpdateMorroxSellStat(_order.tokenId, _morroxSellStat.ratingScore, _morroxSellStat.ratingCount, _morroxSellStat.sellCount);
        emit UpdateSellerStat(_order.seller, _sellerStat.sellCount, _sellerStat.disputeCount, _sellerStat.disputeWon, _sellerStat.disputeLost);
    }
    
    function orderCancelByValidator(uint256 _orderId) external /*nonReentrant*/ {
        OrderInfo storage _order = order_list[_orderId];
        
        require(_order.validator == _msgSender(), "!validator");
        require(_order.orderStatus == ORDER_STATUS.APPEAL, "order status !APPEAL");
        
        _order.orderStatus = ORDER_STATUS.CANCEL;
        _order.cancelBy = _msgSender();
        
        // transfer back to buyer
        IERC20(ttUSDToken).safeTransfer(_order.buyer, _order.price);
        
        // unlock
        IMorrox(morrox).escrowLockToken(_order.tokenId, false);
        
        // validator
        validatorOrderActive[_order.validator]--;
        
        // stat
        totalOrderActive--;
        totalOrderCancel++;
        
        // seller stat
        SellerInfo storage _sellerStat = sellerStat[_order.seller];
        _sellerStat.disputeLost++;
        
        emit OrderCancelByValidator(_orderId);
        emit UpdateSellerStat(_order.seller, _sellerStat.sellCount, _sellerStat.disputeCount, _sellerStat.disputeWon, _sellerStat.disputeLost);
    }
    
    // ------------------------------
    // reserve
    // ------------------------------
    function getTokenId(uint256 _orderId) external view returns(uint256) {
        OrderInfo memory _order = order_list[_orderId];
        return _order.tokenId;
    }
    
    // ------------------------------
    // onlyOwner
    // ------------------------------
    function setValidatorTeam(address _address) public onlyOwner {
        require(_address != address(0), "!address");
        validatorTeam = _address;
    }
    
    function setFeeAddress(address _address) public onlyOwner {
        require(_address != address(0), "!address");
        feeAddress = _address;
    }
    
    function setEscrowPause(bool _escrowPause) public onlyOwner {
        escrowPause = _escrowPause;
    }
    
    function setValidatorFee(uint256 _validatorFee) public onlyOwner {
        require(_validatorFee <= MAX_FEE, "MAX_FEE");
        validatorFee = _validatorFee;
    }
    
    function setPlatformFee(uint256 _platformFee) public onlyOwner {
        require(_platformFee <= MAX_FEE, "MAX_FEE");
        platformFee = _platformFee;
    }
    
    // ------------------------------
    // view
    // ------------------------------
    function getTotalOrderActive() external view returns(uint256) {
        return totalOrderActive;
    }
    
    function getValidatorOrderActive(address _validator) external view returns(uint256) {
        return validatorOrderActive[_validator];
    }
}