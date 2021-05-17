/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/
// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: @powerpool/poweroracle/contracts/interfaces/IPowerPoke.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPowerPoke {
  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view;

  function authorizePoker(uint256 userId_, address pokerKey_) external view;

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view;

  function slashReporter(uint256 slasherId_, uint256 times_) external;

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external;

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external;

  function addCredit(address client_, uint256 amount_) external;

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external;

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external;

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external;

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external;

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external;

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external;

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external;

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external;

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setClientActiveFlag(address client_, bool active_) external;

  function setCanSlashFlag(address client_, bool canSlash) external;

  function setOracle(address oracle_) external;

  function pause() external;

  function unpause() external;

  /*** GETTERS ***/
  function creditOf(address client_) external view returns (uint256);

  function ownerOf(address client_) external view returns (address);

  function getMinMaxReportIntervals(address client_) external view returns (uint256 min, uint256 max);

  function getSlasherHeartbeat(address client_) external view returns (uint256);

  function getGasPriceLimit(address client_) external view returns (uint256);

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) external view returns (uint256);

  function getGasPriceFor(address client_) external view returns (uint256);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/interfaces/BMathInterface.sol

pragma solidity 0.6.12;

interface BMathInterface {
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);
}

// File: contracts/interfaces/BPoolInterface.sol

pragma solidity 0.6.12;

interface BPoolInterface is IERC20, BMathInterface {
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function getDenormalizedWeight(address) external view returns (uint256);

  function getBalance(address) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCommunityFee()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function calcAmountWithCommunityFee(
    uint256,
    uint256,
    address
  ) external view returns (uint256, uint256);

  function getRestrictions() external view returns (address);

  function isPublicSwap() external view returns (bool);

  function isFinalized() external view returns (bool);

  function isBound(address t) external view returns (bool);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getFinalTokens() external view returns (address[] memory tokens);

  function setSwapFee(uint256) external;

  function setCommunityFeeAndReceiver(
    uint256,
    uint256,
    uint256,
    address
  ) external;

  function setController(address) external;

  function setPublicSwap(bool) external;

  function finalize() external;

  function bind(
    address,
    uint256,
    uint256
  ) external;

  function rebind(
    address,
    uint256,
    uint256
  ) external;

  function unbind(address) external;

  function gulp(address) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getMinWeight() external view returns (uint256);

  function getMaxBoundTokens() external view returns (uint256);
}

// File: contracts/interfaces/PowerIndexPoolInterface.sol

pragma solidity 0.6.12;

interface PowerIndexPoolInterface is BPoolInterface {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external;

  function bind(
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external;

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    );

  function getMinWeight() external view override returns (uint256);

  function getWeightPerSecondBounds() external view returns (uint256, uint256);

  function setWeightPerSecondBounds(uint256, uint256) external;

  function setWrapper(address, bool) external;

  function getWrapperMode() external view returns (bool);
}

// File: contracts/interfaces/TokenInterface.sol

pragma solidity 0.6.12;

interface TokenInterface is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// File: contracts/interfaces/ICurveDepositor2.sol

pragma solidity 0.6.12;

interface ICurveDepositor2 {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[2] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/ICurveDepositor3.sol

pragma solidity 0.6.12;

interface ICurveDepositor3 {
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[3] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/ICurveDepositor4.sol

pragma solidity 0.6.12;

interface ICurveDepositor4 {
  function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[4] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/IVault.sol

pragma solidity ^0.6.0;

interface IVault {
  function token() external view returns (address);

  function totalAssets() external view returns (uint256);

  function balanceOf(address _acc) external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;
}

// File: contracts/interfaces/ICurvePoolRegistry.sol

pragma solidity 0.6.12;

interface ICurvePoolRegistry {
  function get_virtual_price_from_lp_token(address _token) external view returns (uint256);
}

// File: contracts/interfaces/IErc20PiptSwap.sol

pragma solidity 0.6.12;

interface IErc20PiptSwap {
  function swapEthToPipt(uint256 _slippage) external payable returns (uint256 poolAmountOutAfterFee, uint256 oddEth);

  function swapErc20ToPipt(
    address _swapToken,
    uint256 _swapAmount,
    uint256 _slippage
  ) external payable returns (uint256 poolAmountOut);

  function defaultSlippage() external view returns (uint256);

  function swapPiptToEth(uint256 _poolAmountIn) external payable returns (uint256 ethOutAmount);

  function swapPiptToErc20(address _swapToken, uint256 _poolAmountIn) external payable returns (uint256 erc20Out);
}

// File: contracts/interfaces/IErc20VaultPoolSwap.sol

pragma solidity 0.6.12;

interface IErc20VaultPoolSwap {
  function swapErc20ToVaultPool(
    address _pool,
    address _swapToken,
    uint256 _swapAmount
  ) external returns (uint256 poolAmountOut);

  function swapVaultPoolToErc20(
    address _pool,
    uint256 _poolAmountIn,
    address _swapToken
  ) external returns (uint256 erc20Out);
}

// File: contracts/IndicesSupplyRedeemZap.sol

pragma solidity 0.6.12;

contract IndicesSupplyRedeemZap is OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event InitRound(
    bytes32 indexed key,
    address indexed pool,
    uint256 endTime,
    address indexed inputToken,
    address outputToken
  );
  event FinishRound(
    bytes32 indexed key,
    address indexed pool,
    address indexed inputToken,
    uint256 totalInputAmount,
    uint256 inputCap,
    uint256 initEndTime,
    uint256 finishEndTime
  );

  event SetFee(address indexed token, uint256 fee);
  event TakeFee(address indexed pool, address indexed token, uint256 amount);
  event ClaimFee(address indexed token, uint256 amount);

  event SetRoundPeriod(uint256 roundPeriod);
  event SetPool(address indexed pool, PoolType pType);
  event SetPiptSwap(address indexed pool, address piptSwap);
  event SetTokenCap(address indexed token, uint256 cap);

  event Deposit(
    bytes32 indexed roundKey,
    address indexed pool,
    address indexed user,
    address inputToken,
    uint256 inputAmount
  );
  event Withdraw(
    bytes32 indexed roundKey,
    address indexed pool,
    address indexed user,
    address inputToken,
    uint256 inputAmount
  );

  event SupplyAndRedeemPoke(
    bytes32 indexed roundKey,
    address indexed pool,
    address indexed inputToken,
    address outputToken,
    uint256 totalInputAmount,
    uint256 totalOutputAmount
  );
  event ClaimPoke(
    bytes32 indexed roundKey,
    address indexed pool,
    address indexed claimFor,
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 outputAmount
  );

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;
  address public constant ETH = 0x0000000000000000000000000000000000000001;

  IERC20 public immutable usdc;
  IPowerPoke public immutable powerPoke;

  enum PoolType { NULL, PIPT, VAULT }

  mapping(address => PoolType) public poolType;
  mapping(address => address) public poolSwapContract;
  mapping(address => uint256) public tokenCap;
  // TODO: delete on proxy replace
  mapping(address => address[]) public poolTokens;

  // TODO: delete on proxy replace
  struct VaultConfig {
    uint256 depositorLength;
    uint256 depositorIndex;
    address depositor;
    address lpToken;
    address vaultRegistry;
  }
  mapping(address => VaultConfig) public vaultConfig;

  uint256 public roundPeriod;

  // TODO: delete on proxy replace
  address public feeReceiver;
  mapping(address => uint256) public feeByToken;
  mapping(address => uint256) public pendingFeeByToken;

  mapping(address => uint256) public pendingOddTokens;

  struct Round {
    uint256 startBlock;
    address inputToken;
    address outputToken;
    address pool;
    mapping(address => uint256) inputAmount;
    uint256 totalInputAmount;
    mapping(address => uint256) outputAmount;
    uint256 totalOutputAmount;
    uint256 totalOutputAmountClaimed;
    uint256 endTime;
  }
  mapping(bytes32 => Round) public rounds;

  mapping(bytes32 => bytes32) public lastRoundByPartialKey;

  modifier onlyReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyNonReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "ONLY_EOA");
    _;
  }

  constructor(address _usdc, address _powerPoke) public {
    usdc = IERC20(_usdc);
    powerPoke = IPowerPoke(_powerPoke);
  }

  function initialize(uint256 _roundPeriod) external initializer {
    __Ownable_init();
    roundPeriod = _roundPeriod;
  }

  receive() external payable {
    pendingOddTokens[ETH] = pendingOddTokens[ETH].add(msg.value);
  }

  /* ==========  Client Functions  ========== */

  function depositEth(address _pool) external payable onlyEOA {
    require(poolType[_pool] == PoolType.PIPT, "NS_POOL");

    _deposit(_pool, ETH, _pool, msg.value);
  }

  function depositErc20(
    address _pool,
    address _inputToken,
    uint256 _amount
  ) external onlyEOA {
    require(poolType[_pool] != PoolType.NULL, "UP");

    require(_inputToken == address(usdc), "NS_TOKEN");

    _deposit(_pool, _inputToken, _pool, _amount);
  }

  function depositPoolToken(
    address _pool,
    address _outputToken,
    uint256 _poolAmount
  ) external onlyEOA {
    PoolType pType = poolType[_pool];
    require(pType != PoolType.NULL, "UP");

    if (pType == PoolType.PIPT) {
      require(_outputToken == address(usdc) || _outputToken == ETH, "NS_TOKEN");
    } else {
      require(_outputToken == address(usdc), "NS_TOKEN");
    }

    _deposit(_pool, _pool, _outputToken, _poolAmount);
  }

  function withdrawEth(address _pool, uint256 _amount) external onlyEOA {
    require(poolType[_pool] == PoolType.PIPT, "NS_POOL");

    _withdraw(_pool, ETH, _pool, _amount);
  }

  function withdrawErc20(
    address _pool,
    address _outputToken,
    uint256 _amount
  ) external onlyEOA {
    require(poolType[_pool] != PoolType.NULL, "UP");
    require(_outputToken != ETH, "ETH_CANT_BE_OT");

    _withdraw(_pool, _outputToken, _pool, _amount);
  }

  function withdrawPoolToken(
    address _pool,
    address _outputToken,
    uint256 _amount
  ) external onlyEOA {
    PoolType pType = poolType[_pool];
    require(pType != PoolType.NULL, "UP");

    if (pType == PoolType.PIPT) {
      require(_outputToken == address(usdc) || _outputToken == ETH, "NS_TOKEN");
    } else {
      require(_outputToken == address(usdc), "NS_TOKEN");
    }

    _withdraw(_pool, _pool, _outputToken, _amount);
  }

  /* ==========  Poker Functions  ========== */

  function supplyAndRedeemPokeFromReporter(
    uint256 _reporterId,
    bytes32[] memory _roundKeys,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) onlyEOA {
    _supplyAndRedeemPoke(_roundKeys, false);
  }

  function supplyAndRedeemPokeFromSlasher(
    uint256 _reporterId,
    bytes32[] memory _roundKeys,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) onlyEOA {
    _supplyAndRedeemPoke(_roundKeys, true);
  }

  function claimPokeFromReporter(
    uint256 _reporterId,
    bytes32 _roundKey,
    address[] memory _claimForList,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) onlyEOA {
    _claimPoke(_roundKey, _claimForList, false);
  }

  function claimPokeFromSlasher(
    uint256 _reporterId,
    bytes32 _roundKey,
    address[] memory _claimForList,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) onlyEOA {
    _claimPoke(_roundKey, _claimForList, true);
  }

  /* ==========  Owner Functions  ========== */

  function setRoundPeriod(uint256 _roundPeriod) external onlyOwner {
    roundPeriod = _roundPeriod;
    emit SetRoundPeriod(roundPeriod);
  }

  function setPools(address[] memory _pools, PoolType[] memory _types) external onlyOwner {
    uint256 len = _pools.length;
    require(len == _types.length, "L");
    for (uint256 i = 0; i < len; i++) {
      poolType[_pools[i]] = _types[i];
      _updatePool(_pools[i]);
      emit SetPool(_pools[i], _types[i]);
    }
  }

  function setPoolsSwapContracts(address[] memory _pools, address[] memory _swapContracts) external onlyOwner {
    uint256 len = _pools.length;
    require(len == _swapContracts.length, "L");
    for (uint256 i = 0; i < len; i++) {
      poolSwapContract[_pools[i]] = _swapContracts[i];
      usdc.approve(_swapContracts[i], uint256(-1));
      IERC20(_pools[i]).approve(_swapContracts[i], uint256(-1));
      emit SetPiptSwap(_pools[i], _swapContracts[i]);
    }
  }

  function setTokensCap(address[] memory _tokens, uint256[] memory _caps) external onlyOwner {
    uint256 len = _tokens.length;
    require(len == _caps.length, "L");
    for (uint256 i = 0; i < len; i++) {
      tokenCap[_tokens[i]] = _caps[i];
      emit SetTokenCap(_tokens[i], _caps[i]);
    }
  }

  function updatePools(address[] memory _pools) external onlyOwner {
    uint256 len = _pools.length;
    for (uint256 i = 0; i < len; i++) {
      _updatePool(_pools[i]);
    }
  }

  /* ==========  View Functions  ========== */

  function getCurrentBlockRoundKey(
    address pool,
    address inputToken,
    address outputToken
  ) public view returns (bytes32) {
    return getRoundKey(block.number, pool, inputToken, outputToken);
  }

  function getRoundKey(
    uint256 blockNumber,
    address pool,
    address inputToken,
    address outputToken
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(blockNumber, pool, inputToken, outputToken));
  }

  function getRoundPartialKey(
    address pool,
    address inputToken,
    address outputToken
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(pool, inputToken, outputToken));
  }

  function getLastRoundKey(
    address pool,
    address inputToken,
    address outputToken
  ) external view returns (bytes32) {
    return lastRoundByPartialKey[getRoundPartialKey(pool, inputToken, outputToken)];
  }

  function isRoundReadyToExecute(bytes32 roundKey) public view returns (bool) {
    Round storage round = rounds[roundKey];
    if (tokenCap[round.inputToken] == 0) {
      return round.endTime <= block.timestamp;
    }
    if (round.totalInputAmount == 0) {
      return false;
    }
    return round.totalInputAmount >= tokenCap[round.inputToken] || round.endTime <= block.timestamp;
  }

  function getRoundUserInput(bytes32 roundKey, address user) external view returns (uint256) {
    return rounds[roundKey].inputAmount[user];
  }

  function getRoundUserOutput(bytes32 roundKey, address user) external view returns (uint256) {
    return rounds[roundKey].outputAmount[user];
  }

  /* ==========  Internal Functions  ========== */

  function _deposit(
    address _pool,
    address _inputToken,
    address _outputToken,
    uint256 _amount
  ) internal {
    require(_amount > 0, "NA");
    bytes32 roundKey = _updateRound(_pool, _inputToken, _outputToken);

    if (_inputToken != ETH) {
      IERC20(_inputToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    Round storage round = rounds[roundKey];
    round.inputAmount[msg.sender] = round.inputAmount[msg.sender].add(_amount);
    round.totalInputAmount = round.totalInputAmount.add(_amount);

    require(round.inputAmount[msg.sender] == 0 || round.inputAmount[msg.sender] > 1e5, "MIN_INPUT");

    emit Deposit(roundKey, _pool, msg.sender, _inputToken, _amount);
  }

  function _withdraw(
    address _pool,
    address _inputToken,
    address _outputToken,
    uint256 _amount
  ) internal {
    require(_amount > 0, "NA");
    bytes32 roundKey = _updateRound(_pool, _inputToken, _outputToken);
    Round storage round = rounds[roundKey];

    round.inputAmount[msg.sender] = round.inputAmount[msg.sender].sub(_amount);
    round.totalInputAmount = round.totalInputAmount.sub(_amount);

    require(round.inputAmount[msg.sender] == 0 || round.inputAmount[msg.sender] > 1e5, "MIN_INPUT");

    if (_inputToken == ETH) {
      msg.sender.transfer(_amount);
    } else {
      IERC20(_inputToken).safeTransfer(msg.sender, _amount);
    }

    emit Withdraw(roundKey, _pool, msg.sender, _inputToken, _amount);
  }

  function _supplyAndRedeemPoke(bytes32[] memory _roundKeys, bool _bySlasher) internal {
    (uint256 minInterval, uint256 maxInterval) = _getMinMaxReportInterval();

    uint256 len = _roundKeys.length;
    require(len > 0, "L");

    for (uint256 i = 0; i < len; i++) {
      Round storage round = rounds[_roundKeys[i]];

      _updateRound(round.pool, round.inputToken, round.outputToken);
      _checkRoundBeforeExecute(_roundKeys[i], round);

      require(round.endTime + minInterval <= block.timestamp, "MIN_I");
      if (_bySlasher) {
        require(round.endTime + maxInterval <= block.timestamp, "MAX_I");
      }

      require(round.inputToken == round.pool || round.outputToken == round.pool, "UA");

      if (round.inputToken == round.pool) {
        _redeemPool(round, round.totalInputAmount);
      } else {
        _supplyPool(round, round.totalInputAmount);
      }

      require(round.totalOutputAmount != 0, "NULL_TO");

      emit SupplyAndRedeemPoke(
        _roundKeys[i],
        round.pool,
        round.inputToken,
        round.outputToken,
        round.totalInputAmount,
        round.totalOutputAmount
      );
    }
  }

  function _supplyPool(Round storage round, uint256 totalInputAmount) internal {
    PoolType pType = poolType[round.pool];
    if (pType == PoolType.PIPT) {
      IErc20PiptSwap piptSwap = IErc20PiptSwap(payable(poolSwapContract[round.pool]));
      if (round.inputToken == ETH) {
        (round.totalOutputAmount, ) = piptSwap.swapEthToPipt{ value: totalInputAmount }(piptSwap.defaultSlippage());
      } else {
        round.totalOutputAmount = piptSwap.swapErc20ToPipt(
          round.inputToken,
          totalInputAmount,
          piptSwap.defaultSlippage()
        );
      }
    } else if (pType == PoolType.VAULT) {
      IErc20VaultPoolSwap vaultPoolSwap = IErc20VaultPoolSwap(poolSwapContract[round.pool]);
      round.totalOutputAmount = vaultPoolSwap.swapErc20ToVaultPool(round.pool, address(usdc), totalInputAmount);
    }
  }

  function _redeemPool(Round storage round, uint256 totalInputAmount) internal {
    PoolType pType = poolType[round.pool];
    if (pType == PoolType.PIPT) {
      IErc20PiptSwap piptSwap = IErc20PiptSwap(payable(poolSwapContract[round.pool]));
      if (round.inputToken == ETH) {
        round.totalOutputAmount = piptSwap.swapPiptToEth(totalInputAmount);
      } else {
        round.totalOutputAmount = piptSwap.swapPiptToErc20(round.outputToken, totalInputAmount);
      }
    } else if (pType == PoolType.VAULT) {
      IErc20VaultPoolSwap vaultPoolSwap = IErc20VaultPoolSwap(poolSwapContract[round.pool]);
      round.totalOutputAmount = vaultPoolSwap.swapVaultPoolToErc20(round.pool, totalInputAmount, address(usdc));
    }
  }

  function _claimPoke(
    bytes32 _roundKey,
    address[] memory _claimForList,
    bool _bySlasher
  ) internal {
    (uint256 minInterval, uint256 maxInterval) = _getMinMaxReportInterval();

    uint256 len = _claimForList.length;
    require(len > 0, "L");

    Round storage round = rounds[_roundKey];
    require(round.endTime + minInterval <= block.timestamp, "MIN_I");
    if (_bySlasher) {
      require(round.endTime + maxInterval <= block.timestamp, "MAX_I");
    }
    require(round.totalOutputAmount != 0, "NULL_TO");

    for (uint256 i = 0; i < len; i++) {
      address _claimFor = _claimForList[i];
      require(round.inputAmount[_claimFor] != 0, "INPUT_NULL");
      require(round.outputAmount[_claimFor] == 0, "OUTPUT_NOT_NULL");

      uint256 inputShare = round.inputAmount[_claimFor].mul(1 ether).div(round.totalInputAmount);
      uint256 outputAmount = round.totalOutputAmount.mul(inputShare).div(1 ether);
      round.outputAmount[_claimFor] = outputAmount;
      round.totalOutputAmountClaimed = round.totalOutputAmountClaimed.add(outputAmount).add(10);
      IERC20(round.outputToken).safeTransfer(_claimFor, outputAmount - 1);

      emit ClaimPoke(
        _roundKey,
        round.pool,
        _claimFor,
        round.inputToken,
        round.outputToken,
        round.inputAmount[_claimFor],
        outputAmount
      );
    }
  }

  function _checkRoundBeforeExecute(bytes32 _roundKey, Round storage round) internal {
    bytes32 partialKey = getRoundPartialKey(round.pool, round.inputToken, round.outputToken);

    require(lastRoundByPartialKey[partialKey] != _roundKey, "CUR_ROUND");
    require(round.totalInputAmount != 0, "TI_NULL");
    require(round.totalOutputAmount == 0, "TO_NOT_NULL");
  }

  function _updateRound(
    address _pool,
    address _inputToken,
    address _outputToken
  ) internal returns (bytes32 roundKey) {
    bytes32 partialKey = getRoundPartialKey(_pool, _inputToken, _outputToken);
    roundKey = lastRoundByPartialKey[partialKey];

    if (roundKey == bytes32(0) || isRoundReadyToExecute(roundKey)) {
      if (roundKey != bytes32(0)) {
        emit FinishRound(
          roundKey,
          _pool,
          _inputToken,
          rounds[roundKey].totalInputAmount,
          tokenCap[_inputToken],
          rounds[roundKey].endTime,
          block.timestamp
        );
        rounds[roundKey].endTime = block.timestamp;
      }
      roundKey = getCurrentBlockRoundKey(_pool, _inputToken, _outputToken);
      rounds[roundKey].startBlock = block.number;
      rounds[roundKey].pool = _pool;
      rounds[roundKey].inputToken = _inputToken;
      rounds[roundKey].outputToken = _outputToken;
      rounds[roundKey].endTime = block.timestamp.add(roundPeriod);
      lastRoundByPartialKey[partialKey] = roundKey;
      emit InitRound(roundKey, _pool, rounds[roundKey].endTime, _inputToken, _outputToken);
    }

    return roundKey;
  }

  function _updatePool(address _pool) internal {
    poolTokens[_pool] = PowerIndexPoolInterface(_pool).getCurrentTokens();
    if (poolType[_pool] == PoolType.VAULT) {
      uint256 len = poolTokens[_pool].length;
      for (uint256 i = 0; i < len; i++) {
        IERC20(poolTokens[_pool][i]).approve(_pool, uint256(-1));
      }
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, _gasStart.sub(gasleft()), _compensationPlan, _rewardOpts);
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    (min, max) = powerPoke.getMinMaxReportIntervals(address(this));
    min = min == 1 ? 0 : min;
  }
}