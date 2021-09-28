/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT
// File: contracts/libs/IMiner.sol



pragma solidity 0.6.12;

interface IMiner {
    function recordReferrer(address _user, address _referrer) external;
    function addReward(address _user, uint _amount) external;
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Address.sol



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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/math/SafeMath.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/SafeERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.6.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/GSN/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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

// File: https://github.com/smartcontractkit/chainlink/blob/0964ca290565587963cc4ad8f770274f5e0d9e9d/evm-contracts/src/v0.6/VRFRequestIDBase.sol


pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: https://github.com/smartcontractkit/chainlink/blob/0964ca290565587963cc4ad8f770274f5e0d9e9d/evm-contracts/src/v0.6/interfaces/LinkTokenInterface.sol


pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: https://github.com/smartcontractkit/chainlink/blob/0964ca290565587963cc4ad8f770274f5e0d9e9d/evm-contracts/src/v0.6/vendor/SafeMathChainlink.sol


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
library SafeMathChainlink {
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// File: https://github.com/smartcontractkit/chainlink/blob/0964ca290565587963cc4ad8f770274f5e0d9e9d/evm-contracts/src/v0.6/VRFConsumerBase.sol


pragma solidity ^0.6.0;




/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: contracts/Polyroll.sol



pragma solidity 0.6.12;






// Polyroll is the dealer of random number games at Polyroll.org: Coin Flip, Dice Roll, Polyroll, Roulette.
/*
v2 has the same logic as v1, with the following updates:
- Transaction Mining: Contract is linked to TransactionMiner contract to award ROLL tokens to gamblers who lost bets.
- Referral system: Contract is linked to TransactionMiner contract to record a gambler's referrer and distribute referral fees.
- Automated risk management: Dynamically computes maxProfit based on contract balance and balance-to-maxProfit ratio.
- Reward Computation: Calculates txn mining reward based on rewardPct, ROLL/MATIC price, bet amount, and probability of loss.
- House edge and wealth tax are in basis points instead of percentage for fine adjustments.
- betPlaced event log is more detailed to allow users to see their pending bets while waiting for settlement.
- betSettled event log is less detailed to save gas fee paid by Chainlink VRF and speed up confirmation time by Polygon nodes.
*/
contract Polyroll is VRFConsumerBase, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Import contract that governs transaction mining and referral fees
    IMiner public miner;

    // Chainlink VRF related parameters
    address public constant LINK_TOKEN = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant VRF_COORDINATOR = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 public keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint public chainlinkFee = 100000000000000; // 0.0001 LINK

    // Each bet is deducted 100 basis points (1%) in favor of the house
    uint public houseEdgeBP = 100;

    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  36 for double dice roll
    //  37 for roulette
    //  100 for polyroll
    uint constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes. 
    // For example in a dice roll (modolo = 6), 
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of eight below 42.
    uint constant MAX_MASK_MODULO = 40;

     // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // These are constants that make O(1) population count in placeBet possible.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    // In addition to house edge, wealth tax is added for bet amount that exceeds a multiple of wealthTaxThreshold.
    // For example, if wealthTaxThreshold = 200 ether and wealthTaxBP = 100,
    // A bet amount of 200 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 400 ether will have a wealth tax of 2% in addition to house edge.
    uint public wealthTaxThreshold = 200 ether;
    uint public wealthTaxBP = 100;

    // Minimum and maximum bet amounts.
    uint public minBetAmount = 2 ether;
    uint public maxBetAmount = 800 ether;

    // Balance-to-maxProfit ratio. Used to dynamically adjusts maxProfit based on balance.
    uint public balanceMaxProfitRatio = 24;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
    }

    // Array of bets
    Bet[] public bets;

    // Mapping requestId returned by Chainlink VRF to bet Id.
    mapping(bytes32 => uint) public betMap;

    // Percentage of house edge fees to be rewarded to losing gambler.
    uint public rewardPct = 20;

    // Variables for computing price of ROLL in MATIC. Used for computing ROLL reward for transaction mining.
    uint constant SAFETY_FACTOR = 1e7; // Prevent truncation of price in integer datatype by multiplying with SAFETY_FACTOR.
    address constant ROLL_TOKEN = 0xC68e83a305b0FaD69E264A1769a0A070F190D2d6;
    address constant MATIC_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public rollMaticLP = 0x905DCc700fcce9a49b7D907E371230995a45ebCE;
    uint public rollMaticRatio; // Price of ROLL/MATIC
    uint public rollMaticBlockTimestampLast;
    uint maxReward = 20000 ether;

    // Signed integer used for tracking house profit since inception.
    int public houseProfit;

    // Events
    event BetPlaced(uint indexed betId, address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollUnder, uint40 mask);
    event BetSettled(uint indexed betId, address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollUnder, uint40 mask, uint outcome, uint winAmount, uint rollReward);
    event BetRefunded(uint indexed betId, address indexed gambler, uint amount);

    // Constructor. Using Chainlink VRFConsumerBase constructor.
    constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) public {}

    // Fallback & receive payable function used to top up the bank roll.
    fallback() external payable {}
    receive() external payable {}

    // Returns game token balance.
    function balance() external view returns (uint) {
        return address(this).balance;
    }

    // Returns number of bets.
    function betsLength() external view returns (uint) {
        return bets.length;
    }

    // Returns maximum profit allowed per bet. Prevents contract from accepting any bets with potential profit exceeding maxProfit.
    function maxProfit() public view returns (uint) {
        return address(this).balance / balanceMaxProfitRatio;
    }

    // Set balance-to-maxProfit ratio. 
    function setBalanceMaxProfitRatio(uint _balanceMaxProfitRatio) external onlyOwner {
        balanceMaxProfitRatio = _balanceMaxProfitRatio;
    }

    // Update Chainlink fee.
    function setChainlinkFee(uint _chainlinkFee) external onlyOwner {
        chainlinkFee = _chainlinkFee;
    }

    // Update Chainlink keyHash. Currently using keyHash with 10 block waiting time config. May configure to 64 block waiting time for more security.
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    // Set minimum bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount;
    }

    // Set maximum bet amount. Setting this to zero effectively disables betting.
    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    // Set house edge.
    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        houseEdgeBP = _houseEdgeBP;
    }

    // Set wealth tax. Setting this to zero effectively disables wealth tax.
    function setWealthTaxBP(uint _wealthTaxBP) external onlyOwner {
        wealthTaxBP = _wealthTaxBP;
    }

    // Set threshold to trigger wealth tax.
    function setWealthTaxThreshold(uint _wealthTaxThreshold) external onlyOwner {
        wealthTaxThreshold = _wealthTaxThreshold;
    }

    // Set transaction mining contract address
    function setMiner(IMiner _miner) external onlyOwner {
        miner = _miner;
    }

    // Set transaction mining reward as a percentage of house edge fees.
    // Setting rewardPct to 100% effectively leads to an expectation value of 0.
    function setRewardPct(uint _rewardPct) external onlyOwner {
        require(_rewardPct <= 100, "rewardPct exceeds 100%");
        rewardPct = _rewardPct;
    }

    // Set rollMaticLP if we change our main trading LP for price reference.
    function setRollMaticLP(address _rollMaticLP) external onlyOwner {
        rollMaticLP = _rollMaticLP;
    }

    // Set maximum ROLL reward that a user can receive per bet.
    function setMaxReward(uint _maxReward) external onlyOwner {
        maxReward = _maxReward;
    }

    // Get ROLL/MATIC price with safeguards against oracle attacks.
    function updateRollMaticRatio() internal {
        // Run function if 30 minutes elapsed.
        if (block.timestamp - rollMaticBlockTimestampLast >= 1800) {

            // Get ratio of ROLL to MATIC multiplied by SAFETY_FACTOR to avoid losing precision.
            uint newRollMaticRatio = IERC20(ROLL_TOKEN).balanceOf(rollMaticLP) * SAFETY_FACTOR / IERC20(MATIC_TOKEN).balanceOf(rollMaticLP);

            if (rollMaticRatio == 0) {
                // Update rollMaticRatio if first time updating.
                rollMaticRatio = newRollMaticRatio;
            } else if (newRollMaticRatio * SAFETY_FACTOR / rollMaticRatio > SAFETY_FACTOR * 110 / 100) {
                // Cap any increase to +10% per update.
                rollMaticRatio = rollMaticRatio * 110 / 100;
            } else if (newRollMaticRatio * SAFETY_FACTOR / rollMaticRatio < SAFETY_FACTOR * 80 / 100) {
                // Cap any decrease to -10% per update.
                rollMaticRatio = rollMaticRatio * 90 / 100;
            } else {
                rollMaticRatio = newRollMaticRatio;
            }
            rollMaticBlockTimestampLast = block.timestamp;
        }
    }

    // Place bet
    function placeBet(uint betMask, uint modulo, address referrer) external payable nonReentrant {

        // Validate input data.
        uint amount = msg.value;
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Insufficient LINK token");
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo not within range");
        require(amount >= minBetAmount && amount <= maxBetAmount, "Bet amount not within range");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask not within range");

        // Update ROLL/MATIC price if data is outdated.
        updateRollMaticRatio();

        // Record referrer in Miner contract
        if (referrer != msg.sender) {
            miner.recordReferrer(msg.sender, referrer);
        }

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. 
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            require(betMask > 0 && betMask <= modulo, "betMask larger than modulo");
            rollUnder = betMask;
        }

        // Winning amount.
        uint possibleWinAmount = getWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit. Bet will not be placed if condition is not met.
        require(possibleWinAmount <= amount + maxProfit(), "maxProfit violation");

        // Check whether contract has enough funds to accept this bet.
        require(lockedInBets + possibleWinAmount <= address(this).balance, "Insufficient funds");

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        bytes32 requestId = requestRandomness(keyHash, chainlinkFee, bets.length);

        // Map requestId to bet ID.
        betMap[requestId] = bets.length;

        // Record bet in event logs. Placed before pushing bet to array in order to get the correct bets.length.
        emit BetPlaced(bets.length, msg.sender, amount, uint8(modulo), uint8(rollUnder), uint40(mask));

        // Store bet in bet list.
        bets.push(Bet(
            {
                amount: amount,
                modulo: uint8(modulo),
                rollUnder: uint8(rollUnder),
                mask: uint40(mask),
                placeBlockNumber: block.number,
                gambler: msg.sender,
                isSettled: false,
                outcome: 0,
                winAmount: 0
            }
        ));
    }

    // Returns the expected win amount.
    function getWinAmount(uint amount, uint modulo, uint rollUnder) private view returns (uint winAmount) {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range");
        uint houseEdgeFee = amount * (houseEdgeBP + getEffectiveWealthTaxBP(amount)) / 10000;
        winAmount = (amount - houseEdgeFee) * modulo / rollUnder;
    }

    // Get effective wealth tax for a given bet size.
    function getEffectiveWealthTaxBP(uint amount) private view returns (uint effectiveWealthTaxBP) {
        effectiveWealthTaxBP = amount / wealthTaxThreshold * wealthTaxBP;
    }

    // Expected ROLL tokens to be rewarded if lose bet.
    function getRollReward(uint amount, uint modulo, uint rollUnder) private view returns (uint) {
        // ROLL reward equals token price multiplied by house edge fees, divided by win probability, multiplied by rewardPct.
        uint rollReward = rollMaticRatio * amount * (houseEdgeBP + getEffectiveWealthTaxBP(amount)) / 10000 * modulo / (modulo - rollUnder) * rewardPct / 100 / SAFETY_FACTOR;
        if (rollReward > maxReward) {
            rollReward = maxReward;
        }
        return rollReward;
    }

    // Callback function called by Chainlink VRF coordinator.
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        settleBet(requestId, randomness);
    }

    // Settle bet. Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(bytes32 requestId, uint randomNumber) internal nonReentrant {
        
        uint betId = betMap[requestId];
        Bet storage bet = bets[betId];
        uint amount = bet.amount;
        
        // Validation checks.
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

        // Do a roll by taking a modulo of random number.
        uint outcome = randomNumber % modulo;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = getWinAmount(amount, modulo, rollUnder);

        // Roll reward if gambler loses this bet
        uint rollReward = getRollReward(amount, modulo, rollUnder);

        // Actual win amount by gambler.
        uint winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
                rollReward = 0;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (outcome < rollUnder) {
                winAmount = possibleWinAmount;
                rollReward = 0;
            }
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.outcome = outcome;

        // Send prize to winner, add ROLL reward to loser, and update house profit.
        if (winAmount > 0) {
            houseProfit -= int(winAmount - amount);
            gambler.transfer(winAmount);
        } else {
            houseProfit += int(amount);
            miner.addReward(gambler, rollReward);
        }
        
        // Record bet settlement in event log.
        emit BetSettled(betId, gambler, amount, uint8(modulo), uint8(rollUnder), bet.mask, outcome, winAmount, rollReward);
    }

    // Owner can withdraw funds not exceeding balance minus potential win amounts by open bets.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal exceeds limit");
        beneficiary.transfer(withdrawAmount);
    }

    // Owner can withdraw non-MATIC tokens.
    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    // Return the bet in the very unlikely scenario it was not settled by Chainlink VRF. 
    // In case you find yourself in a situation like this, just contact Polyroll support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint betId) external nonReentrant {
        
        Bet storage bet = bets[betId];
        uint amount = bet.amount;

        // Validation checks
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(block.number > bet.placeBlockNumber + 21600, "Wait before requesting refund");

        uint possibleWinAmount = getWinAmount(amount, bet.modulo, bet.rollUnder);

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(betId, bet.gambler, amount);
    }
}