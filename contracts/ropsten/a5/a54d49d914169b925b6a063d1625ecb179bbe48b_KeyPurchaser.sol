/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @unlock-protocol/unlock-abi-7/IPublicLockV7Sol6.sol

pragma solidity ^0.6.0;

/**
* @title The PublicLock Interface
* @author Nick Furfaro (unlock-protocol.com)
 */


interface IPublicLockV7Sol6
{

// See indentationissue description here:
// https://github.com/duaraghav8/Ethlint/issues/268
// solium-disable indentation

  /// Functions

  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

  /**
   * @notice Allow the contract to accept tips in ETH sent directly to the contract.
   * @dev This is okay to use even if the lock is priced in ERC-20 tokens
   */
  receive() external payable;

  /**
   * @dev Never used directly
   */
  function initialize() external;

  /**
  * @notice The version number of the current implementation on this network.
  * @return The current version number.
  */
  function publicLockVersion() external pure returns (uint);

  /**
  * @notice Gets the current balance of the account provided.
  * @param _tokenAddress The token type to retrieve the balance of.
  * @param _account The account to get the balance of.
  * @return The number of tokens of the given type for the given address, possibly 0.
  */
  function getBalance(
    address _tokenAddress,
    address _account
  ) external view
    returns (uint);

  /**
  * @notice Used to disable lock before migrating keys and/or destroying contract.
  * @dev Throws if called by other than a lock manager.
  * @dev Throws if lock contract has already been disabled.
  */
  function disableLock() external;

  /**
   * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
   * @dev Throws if called by other than a lock manager or beneficiary
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
   * use cases.
   */
  function withdraw(
    address _tokenAddress,
    uint _amount
  ) external;

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing( uint _keyPrice, address _tokenAddress ) external;

  /**
   * A function which lets a Lock manager update the beneficiary account,
   * which receives funds on withdrawal.
   * @dev Throws if called by other than a Lock manager or beneficiary
   * @dev Throws if _beneficiary is address(0)
   * @param _beneficiary The new address to set as the beneficiary
   */
  function updateBeneficiary( address _beneficiary ) external;

    /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(
    address _user
  ) external view returns (bool);

  /**
   * @notice Find the tokenId for a given user
   * @return The tokenId of the NFT, else returns 0
   * @param _account The address of the key owner
  */
  function getTokenIdFor(
    address _account
  ) external view returns (uint);

  /**
  * A function which returns a subset of the keys for this Lock as an array
  * @param _page the page of key owners requested when faceted by page size
  * @param _pageSize the number of Key Owners requested per page
  * @dev Throws if there are no key owners yet
  */
  function getOwnersByPage(
    uint _page,
    uint _pageSize
  ) external view returns (address[] memory);

  /**
   * Checks if the given address owns the given tokenId.
   * @param _tokenId The tokenId of the key to check
   * @param _keyOwner The potential key owners address
   */
  function isKeyOwner(
    uint _tokenId,
    address _keyOwner
  ) external view returns (bool);

  /**
  * @dev Returns the key's ExpirationTimestamp field for a given owner.
  * @param _keyOwner address of the user for whom we search the key
  * @dev Returns 0 if the owner has never owned a key for this lock
  */
  function keyExpirationTimestampFor(
    address _keyOwner
  ) external view returns (uint timestamp);

  /**
   * external function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows a Lock manager to assign a descriptive name for this Lock.
   * @param _lockName The new name for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockName(
    string calldata _lockName
  ) external;

  /**
   * Allows a Lock manager to assign a Symbol for this Lock.
   * @param _lockSymbol The new Symbol for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockSymbol(
    string calldata _lockSymbol
  ) external;

  /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
  function symbol()
    external view
    returns(string memory);

    /**
   * Allows a Lock manager to update the baseTokenURI for this Lock.
   * @dev Throws if called by other than a Lock manager
   * @param _baseTokenURI String representing the base of the URI for this lock.
   */
  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external;

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(
    uint256 _tokenId
  ) external view returns(string memory);

  /**
   * @notice Allows a Lock manager to add or remove an event hook
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external;

  /**
  * @dev Purchase function
  * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
  * (_value is ignored when using ETH)
  * @param _recipient address of the recipient of the purchased key
  * @param _referrer address of the user making the referral
  * @param _data arbitrary data populated by the front-end which initiated the sale
  * @dev Throws if lock is disabled. Throws if lock is sold-out. Throws if _recipient == address(0).
  * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if a Lock manager increases the
  * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
  * than keyPrice is approved for spending).
  */
  function purchase(
    uint256 _value,
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external payable;

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view
    returns (uint);

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  ) external;

  /**
   * Determines how much of a fee a key owner would need to pay in order to
   * transfer the key to another account.  This is pro-rated so the fee goes down
   * overtime.
   * @dev Throws if _keyOwner does not have a valid key
   * @param _keyOwner The owner of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    address _keyOwner,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key and perform a refund and cancellation of the key
   * @param _keyOwner The key owner to whom we wish to send a refund to
   * @param amount The amount to refund the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(
    address _keyOwner,
    uint amount
  ) external;

   /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * @dev Cancels a key managed by a different user and sends the funds to the keyOwner.
   * @param _keyManager the key managed by this user will be canceled
   * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyManager
   * @param _tokenId The key to cancel
   */
  function cancelAndRefundFor(
    address _keyManager,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint _tokenId
  ) external;

  /**
   * @notice Sets the minimum nonce for a valid off-chain approval message from the
   * senders account.
   * @dev This can be used to invalidate a previously signed message.
   */
  function invalidateOffchainApproval(
    uint _nextAvailableNonce
  ) external;

  /**
   * Allow a Lock manager to change the refund penalty.
   * @dev Throws if called by other than a Lock manager
   * @param _freeTrialLength The new duration of free trials for this lock
   * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _keyOwner The key owner to get the refund value for.
   * a cancelAndRefund block.timestamp.
   * Note that due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   */
  function getCancelAndRefundValueFor(
    address _keyOwner
  ) external view returns (uint refund);

  function keyManagerToNonce(address ) external view returns (uint256 );

  /**
   * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
   * @dev this can be computed in JS instead of read from the contract.
   * @param _keyManager The key manager's address (also the message signer)
   * @param _txSender The address cancelling cancel on behalf of the keyOwner
   * @return approvalHash The hash to sign
   */
  function getCancelAndRefundApprovalHash(
    address _keyManager,
    address _txSender
  ) external view returns (bytes32 approvalHash);

  function addKeyGranter(address account) external;

  function addLockManager(address account) external;

  function isKeyGranter(address account) external view returns (bool);

  function isLockManager(address account) external view returns (bool);

  function onKeyPurchaseHook() external view returns(address);

  function onKeyCancelHook() external view returns(address);

  function revokeKeyGranter(address _granter) external;

  function renounceLockManager() external;

  ///===================================================================
  /// Auto-generated getter functions from public state variables

  function beneficiary() external view returns (address );

  function expirationDuration() external view returns (uint256 );

  function freeTrialLength() external view returns (uint256 );

  function isAlive() external view returns (bool );

  function keyPrice() external view returns (uint256 );

  function maxNumberOfKeys() external view returns (uint256 );

  function owners(uint256 ) external view returns (address );

  function refundPenaltyBasisPoints() external view returns (uint256 );

  function tokenAddress() external view returns (address );

  function transferFeeBasisPoints() external view returns (uint256 );

  function unlockProtocol() external view returns (address );

  function keyManagerOf(uint) external view returns (address );

  ///===================================================================

  /**
  * @notice Allows the key owner to safely share their key (parent key) by
  * transferring a portion of the remaining time to a new key (child key).
  * @dev Throws if key is not valid.
  * @dev Throws if `_to` is the zero address
  * @param _to The recipient of the shared key
  * @param _tokenId the key to share
  * @param _timeShared The amount of time shared
  * checks if `_to` is a smart contract (code size > 0). If so, it calls
  * `onERC721Received` on `_to` and throws if the return value is not
  * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
  * @dev Emit Transfer event
  */
  function shareKey(
    address _to,
    uint _tokenId,
    uint _timeShared
  ) external;

  /**
  * @notice Update transfer and cancel rights for a given key
  * @param _tokenId The id of the key to assign rights for
  * @param _keyManager The address to assign the rights to for the given key
  */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) external;

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);
  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(bytes4 interfaceId) external view returns (bool );
  ///===================================================================

  /// From ERC-721
  /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address _owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;

    /**
    * @notice Get the approved address for a single NFT
    * @dev Throws if `_tokenId` is not a valid NFT.
    * @param _tokenId The NFT to find the approved address for
    * @return operator The approved address for this NFT, or the zero address if there is none
    */
    function getApproved(uint256 _tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address _owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/mixins/LockRoles.sol

pragma solidity 0.6.6;



/**
 * @notice Provides modifiers for interfacing with roles from a lock.
 */
contract LockRoles
{
  /**
   * @notice Lock managers are admins for the lock contract.
   */
  modifier onlyLockManager(
    IPublicLockV7Sol6 _lock
  )
  {
    require(_lock.isLockManager(msg.sender), 'ONLY_LOCK_MANAGER');
    _;
  }

  /**
   * @notice Key granters and lock managers have permission to distribute keys without any expense.
   */
  modifier onlyKeyGranterOrManager(
    IPublicLockV7Sol6 _lock
  )
  {
    require(_lock.isKeyGranter(msg.sender) || _lock.isLockManager(msg.sender), 'ONLY_KEY_GRANTER');
    _;
  }
}

// File: contracts/KeyPurchaser.sol

pragma solidity 0.6.6;








/**
 * @notice Purchase a key priced in any ERC-20 token - either once or as a regular subscription.
 * This allows the user to purchase or subscribe to a key with 1 tx (`approve`)
 * or if the token supports it, with 1 signed message (`permit`).
 *
 * The user can remove the ERC-20 approval to cancel anytime.
 *
 * Risk: if the user transfers or cancels the key, they would naturally expect that also cancels
 * the subscription but it does not. This should be handled by the frontend.
 */
contract KeyPurchaser is Initializable, LockRoles
{
  using Address for address payable;
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  /**
   * @notice Emitted when the stop is triggered by a stopper (`account`).
   */
  event Stopped(address account);

  // set on initialize and cannot change

  /**
   * @notice This is the lock for the content users are subscribing to.
   */
  IPublicLockV7Sol6 public lock;

  /**
   * @notice The most you will spend on a single key purchase.
   * @dev This allows the lock owner to increase the key price overtime, up to a point, without
   * breaking subscriptions.
   */
  uint public maxPurchasePrice;

  /**
   * @notice How close to the end of a subscription someone may renew the purchase.
   * @dev To ensure that the subscription never expires, we allow this amount of time (maybe 1 day)
   * before it expires for the renewal to happen.
   */
  uint public renewWindow;

  /**
   * @notice The earliest a renewal may be purchased after the previous purchase was done.
   * @dev This typically would not apply, but helps to avoid potential abuse or confusion
   * around cancel and transfer scenarios.
   */
  uint public renewMinFrequency;

  /**
   * @notice The amount of tokens rewarded from the end user to the msg.sender for enabling this feature.
   * This is paid with each renewal of the key.
   */
  uint public msgSenderReward;

  // admin can change these anytime

  /**
   * @notice Metadata for these subscription terms which may be displayed on the frontend.
   */
  string public name;

  /**
   * @notice Metadata for these subscription terms which can be used to supress the offering
   * from the frontend.
   */
  bool internal hidden;

  /**
   * @notice Indicates if the contract has been disabled by a lock manager. Once stopped it
   * may never start again.
   */
  bool public stopped;

  // store minimal history

  /**
   * @notice Tracks when the key was last purchased for a user's subscription.
   * @dev This is used to enforce renewWindow and renewMinFrequency.
   */
  mapping(address => uint) public timestampOfLastPurchase;

  /**
   * @notice Called once to set terms that cannot change later on.
   * @dev We are using initialize instead of a constructor so that this
   * contract may be deployed with a minimal proxy.
   */
  function initialize(
    IPublicLockV7Sol6 _lock,
    uint _maxPurchasePrice,
    uint _renewWindow,
    uint _renewMinFrequency,
    uint _msgSenderReward
  ) public
    initializer()
  {
    lock = _lock;
    maxPurchasePrice = _maxPurchasePrice;
    renewWindow = _renewWindow;
    renewMinFrequency = _renewMinFrequency;
    msgSenderReward = _msgSenderReward;
    approveSpending();
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not stopped.
   */
  modifier whenNotStopped()
  {
    require(!stopped, 'Stoppable: stopped');
    _;
  }

  /**
    * @notice Called by a stopper to stop, triggers stopped state.
    */
  function stop() public onlyLockManager(lock) whenNotStopped
  {
    stopped = true;
    emit Stopped(msg.sender);
  }

  /**
   * @notice Approves the lock to spend funds held by this contract.
   * @dev Automatically called on initialize, needs to be called again if the tokenAddress changes.
   * No permissions required, it's okay to call this again. Typically that would not be required.
   */
  function approveSpending() public
  {
    IERC20 token = IERC20(lock.tokenAddress());
    if(address(token) != address(0))
    {
      token.approve(address(lock), uint(-1));
    }
  }

  /**
   * @notice Used by admins to update metadata which may be leveraged by the frontend.
   * @param _name An optional name to display on the frontend.
   * @param _hidden A flag to indicate if the subscription should be displayed on the frontend.
   */
  function config(
    string memory _name,
    bool _hidden
  ) public
    onlyLockManager(lock)
  {
    name = _name;
    hidden = _hidden;
  }

  /**
   * @notice Indicates if this purchaser should be exposed as an option to users on the frontend.
   * False does not necessarily mean previous subs will no longer work (see `stopped` for that).
   */
  function shouldBeDisplayed() public view returns(bool)
  {
    return !stopped && !hidden;
  }

  /**
   * @notice Checks if terms allow someone to purchase another key on behalf of a given _recipient.
   * @return purchasePrice as an internal gas optimization so we don't need to look it up again.
   * @param _referrer An address passed to the lock during purchase, potentially offering them a reward.
   * @param _data Arbitrary data included with the lock purchase. This may be used for things such as
   * a discount code, which can be safely done by having the maxPurchasePrice lower then the actual keyPrice.
   */
  function _readyToPurchaseFor(
    address payable _recipient,
    address _referrer,
    bytes memory _data
  ) private view
    // Prevent any purchase after these subscription terms have been stopped
    whenNotStopped
    returns(uint purchasePrice)
  {
    uint lastPurchase = timestampOfLastPurchase[_recipient];
    // `now` must be strictly larger than the timestamp of the last block
    // so now - lastPurchase is always >= 1
    require(now - lastPurchase >= renewMinFrequency, 'BEFORE_MIN_FREQUENCY');

    uint expiration = lock.keyExpirationTimestampFor(_recipient);
    require(expiration <= now || expiration - now <= renewWindow, 'OUTSIDE_RENEW_WINDOW');

    purchasePrice = lock.purchasePriceFor(_recipient, _referrer, _data);
    require(purchasePrice <= maxPurchasePrice, 'PRICE_TOO_HIGH');
  }

  /**
   * @notice Checks if terms allow someone to purchase another key on behalf of a given _recipient.
   * @dev This will throw an error if it's not time to renew a purchase for the _recipient.
   * This is slightly different than the internal _readyToPurchaseFor as a gas optimization.
   * When actually processing the purchase we don't need to check the balance because the transfer
   * itself would fail.
   * @param _referrer An address passed to the lock during purchase, potentially offering them a reward.
   * @param _data Arbitrary data included with the lock purchase. This may be used for things such as
   * a discount code, which can be safely done by having the maxPurchasePrice lower then the actual keyPrice.
   */
  function readyToPurchaseFor(
    address payable _recipient,
    address _referrer,
    bytes memory _data
  ) public view
  {
    uint purchasePrice = _readyToPurchaseFor(_recipient, _referrer, _data);
    purchasePrice = purchasePrice.add(msgSenderReward);

    // It's okay if the lock changes tokenAddress as the ERC-20 approval is specifically
    // for the token the endUser wanted to spend
    IERC20 token = IERC20(lock.tokenAddress());
    require(token.balanceOf(_recipient) >= purchasePrice, 'INSUFFICIENT_BALANCE');
    require(token.allowance(_recipient, address(this)) >= purchasePrice, 'INSUFFICIENT_ALLOWANCE');
  }

  /**
   * @notice Called by anyone to purchase or renew a key on behalf of a user.
   * @dev The user must have ERC-20 spending approved and the purchase must meet the terms
   * defined during initialization.
   * @param _referrer An address passed to the lock during purchase, potentially offering them a reward.
   * @param _data Arbitrary data included with the lock purchase. This may be used for things such as
   * a discount code, which can be safely done by having the maxPurchasePrice lower then the actual keyPrice.
   */
  function purchaseFor(
    address payable _recipient,
    address _referrer,
    bytes memory _data
  ) public
  {
    // It's okay if the lock changes tokenAddress as the ERC-20 approval is specifically
    // the token the endUser wanted to spend
    IERC20 token = IERC20(lock.tokenAddress());

    uint keyPrice = _readyToPurchaseFor(_recipient, _referrer, _data);
    uint totalCost = keyPrice.add(msgSenderReward);
    if(totalCost > 0)
    {
      // We don't need safeTransfer as if these do not work the purchase will fail
      token.transferFrom(_recipient, address(this), totalCost);
      if(msgSenderReward > 0)
      {
        token.transfer(msg.sender, msgSenderReward);
      }

      // approve from this contract to the lock is already complete
    }

    lock.purchase(keyPrice, _recipient, _referrer, _data);
    timestampOfLastPurchase[_recipient] = now;

    // RE events: it's not clear emitting an event adds value over the ones from purchase and the token transfer
  }
}

// File: hardlydifficult-eth/contracts/proxies/Clone2Factory.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


// From https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
// Updated to support Solidity 5, switch to `create2` and revert on fail
library Clone2Factory
{
  /**
   * @notice Uses create2 to deploy a clone to a pre-determined address.
   * @param target the address of the template contract, containing the logic for this contract.
   * @param salt a salt used to determine the contract address before the transaction is mined,
   * may be random or sequential.
   * The salt to use with the create2 call can be `msg.sender+salt` in order to
   * prevent an attacker from front-running another user's deployment.
   * @return proxyAddress the address of the newly deployed contract.
   * @dev Using `bytes12` for the salt saves 6 gas over using `uint96` (requires another shift).
   * Will revert on fail.
   */
  function createClone2(
    address target,
    bytes32 salt
  ) internal
    returns (address proxyAddress)
  {
    // solium-disable-next-line
    assembly
    {
      let pointer := mload(0x40)

      // Create the bytecode for deployment based on the Minimal Proxy Standard (EIP-1167)
      // bytecode: 0x0
      mstore(pointer, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(pointer, 0x14), shl(96, target))
      mstore(add(pointer, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      // `create2` consumes all available gas if called with a salt that's already been consumed
      // we check if the address is available first so that doesn't happen
      // Costs ~958 gas

      // Calculate the hash
      let contractCodeHash := keccak256(pointer, 0x37)

      // salt: 0x100
      mstore(add(pointer, 0x100), salt)

      // addressSeed: 0x40
      // 0xff
      mstore(add(pointer, 0x40), 0xff00000000000000000000000000000000000000000000000000000000000000)
      // this
      mstore(add(pointer, 0x41), shl(96, address()))
      // salt
      mstore(add(pointer, 0x55), mload(add(pointer, 0x100)))
      // hash
      mstore(add(pointer, 0x75), contractCodeHash)

      proxyAddress := keccak256(add(pointer, 0x40), 0x55)

      switch extcodesize(proxyAddress)
      case 0 {
        // Deploy the contract, returning the address or 0 on fail
        proxyAddress := create2(0, pointer, 0x37, mload(add(pointer, 0x100)))
      }
      default {
        proxyAddress := 0
      }
    }

    // Revert if the deployment fails (possible if salt was already used)
    require(proxyAddress != address(0), 'PROXY_DEPLOY_FAILED');
  }
}

// File: hardlydifficult-eth/contracts/proxies/Clone2Probe.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


// https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
library Clone2Probe
{
  function getClone2Address(
    address target,
    bytes32 salt
  ) internal view
    returns (address cloneAddress)
  {
    // solium-disable-next-line
    assembly
    {
      let pointer := mload(0x40)

      // Create the bytecode for deployment based on the Minimal Proxy Standard (EIP-1167)
      mstore(pointer, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(pointer, 0x14), shl(96, target))
      mstore(add(pointer, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      // Calculate the hash
      let contractCodeHash := keccak256(pointer, 0x37)

      // 0xff
      mstore(pointer, 0xff00000000000000000000000000000000000000000000000000000000000000)
      // this (byte 1 - 21)
      mstore(add(pointer, 0x1), shl(96, address()))

      // salt
      mstore(add(pointer, 0x15), salt)

      // hash
      mstore(add(pointer, 0x35), contractCodeHash)

      cloneAddress := keccak256(pointer, 0x55)
    }
  }
}

// File: contracts/KeyPurchaserFactory.sol

pragma solidity 0.6.6;





/**
 * @notice A factory for creating keyPurchasers.
 * @dev This contract acts as a registry to discover purchasers for a lock
 * and by creating each purchaser itself, it's a single tx to deploy and initialize and this guarantees
 * a consistent implementation and that it was created by the lock owner.
 */
contract KeyPurchaserFactory
{
  using Clone2Factory for address;
  using Clone2Probe for address;

  event KeyPurchaserCreated(address indexed forLock, address indexed keyPurchaser);

  /**
   * @notice The implementation for minimal proxies to use.
   */
  address public keyPurchaserTemplate;

  /**
   * @notice The registry of available keyPurchases for a given lock.
   */
  mapping(address => address[]) public lockToKeyPurchasers;

  constructor() public
  {
    keyPurchaserTemplate = address(new KeyPurchaser());
  }

  function _getClone2Salt(
    IPublicLockV7Sol6 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency,
    uint _msgSenderReward,
    uint _nonce
  ) private pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(address(_lock), _maxKeyPrice, _renewWindow, _renewMinFrequency, _msgSenderReward, _nonce));
  }

  /**
   * @notice Returns the address for a keyPurchaser given the terms.
   * @dev This works whether or not the keyPurchaser has actually been deployed yet.
   */
  function getExpectedAddress(
    IPublicLockV7Sol6 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency,
    uint _msgSenderReward,
    uint _nonce
  ) external view
    returns (address)
  {
    bytes32 salt = _getClone2Salt(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency, _msgSenderReward, _nonce);
    return keyPurchaserTemplate.getClone2Address(salt);
  }

  /**
   * @notice Deploys a new KeyPurchaser for a lock and stores the address for reference.
   * @param _nonce Allows a KeyPurchaser to be redeployed with a different address in case the original
   * was incorrectly stopped. Typically this should be set to 0.
   * @dev See KeyPurchaser for a description of the other params.
   */
  function deployKeyPurchaser(
    IPublicLockV7Sol6 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency,
    uint _msgSenderReward,
    uint _nonce
  ) public
  {
    bytes32 salt = _getClone2Salt(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency, _msgSenderReward, _nonce);
    address purchaser = keyPurchaserTemplate.createClone2(salt);

    KeyPurchaser(purchaser).initialize(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency, _msgSenderReward);
    lockToKeyPurchasers[address(_lock)].push(purchaser);
    emit KeyPurchaserCreated(address(_lock), purchaser);
  }

  /**
   * @notice Returns all the KeyPurchasers for a given lock.
   * @dev Some KeyPurchasers in this list may have been disabled or stopped.
   */
  function getKeyPurchasers(
    address _lock
  ) public view
    returns (address[] memory)
  {
    return lockToKeyPurchasers[_lock];
  }

  /**
   * @notice Returns the number of available keyPurchasers for a given lock.
   */
  function getKeyPurchaserCount(
    address _lock
  ) public view
    returns (uint)
  {
    return lockToKeyPurchasers[_lock].length;
  }
}