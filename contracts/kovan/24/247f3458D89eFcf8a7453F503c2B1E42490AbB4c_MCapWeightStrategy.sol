/**
 *Submitted for verification at Etherscan.io on 2021-03-27
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

// SPDX-License-Identifier: GPL-3.0

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

// File: contracts/interfaces/IPowerOracle.sol

pragma solidity 0.6.12;

interface IPowerOracle {
  function assetPrices(address _token) external view returns (uint256);
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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: contracts/interfaces/IPoolRestrictions.sol

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// File: contracts/PowerIndexAbstractController.sol

pragma solidity 0.6.12;





contract PowerIndexAbstractController is Ownable {
  using SafeMath for uint256;

  bytes4 public constant CALL_VOTING_SIG = bytes4(keccak256(bytes("callVoting(address,bytes4,bytes,uint256)")));

  event CallPool(bool indexed success, bytes4 indexed inputSig, bytes inputData, bytes outputData);

  PowerIndexPoolInterface public immutable pool;

  constructor(address _pool) public {
    pool = PowerIndexPoolInterface(_pool);
  }

  /**
   * @notice Call any function from pool, except prohibited signatures.
   * @param signature Method signature
   * @param args Encoded method inputs
   */
  function callPool(bytes4 signature, bytes calldata args) external onlyOwner {
    _checkSignature(signature);
    (bool success, bytes memory data) = address(pool).call(abi.encodePacked(signature, args));
    require(success, "NOT_SUCCESS");
    emit CallPool(success, signature, args, data);
  }

  /**
   * @notice Call voting by pool
   * @param voting Voting address
   * @param signature Method signature
   * @param args Encoded method inputs
   * @param value Send value to pool
   */
  function callVotingByPool(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external {
    require(_restrictions().isVotingSenderAllowed(voting, msg.sender), "SENDER_NOT_ALLOWED");
    pool.callVoting(voting, signature, args, value);
  }

  /**
   * @notice Migrate several contracts with setController method to new controller address
   * @param newController New controller to migrate
   * @param addressesToMigrate Address to call setController method
   */
  function migrateController(address newController, address[] calldata addressesToMigrate) external onlyOwner {
    uint256 len = addressesToMigrate.length;
    for (uint256 i = 0; i < len; i++) {
      PowerIndexPoolInterface(addressesToMigrate[i]).setController(newController);
    }
  }

  function _restrictions() internal view returns (IPoolRestrictions) {
    return IPoolRestrictions(pool.getRestrictions());
  }

  function _checkSignature(bytes4 signature) internal pure virtual {
    require(signature != CALL_VOTING_SIG, "SIGNATURE_NOT_ALLOWED");
  }
}

// File: contracts/interfaces/PowerIndexWrapperInterface.sol

pragma solidity 0.6.12;

interface PowerIndexWrapperInterface {
  function getFinalTokens() external view returns (address[] memory tokens);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getBalance(address _token) external view returns (uint256);

  function setPiTokenForUnderlyingsMultiple(address[] calldata _underlyingTokens, address[] calldata _piTokens)
    external;

  function setPiTokenForUnderlying(address _underlyingTokens, address _piToken) external;

  function updatePiTokenEthFees(address[] calldata _underlyingTokens) external;

  function withdrawOddEthFee(address payable _recipient) external;

  function calcEthFeeForTokens(address[] memory tokens) external view returns (uint256 feeSum);

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external payable;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external payable;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external payable returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external payable returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);
}

// File: contracts/interfaces/WrappedPiErc20Interface.sol

pragma solidity 0.6.12;

interface WrappedPiErc20Interface is IERC20 {
  function deposit(uint256 _amount) external payable returns (uint256);

  function withdraw(uint256 _amount) external payable returns (uint256);

  function changeRouter(address _newRouter) external;

  function setEthFee(uint256 _newEthFee) external;

  function approveUnderlying(address _to, uint256 _amount) external;

  function callExternal(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  struct ExternalCallData {
    address destination;
    bytes4 signature;
    bytes args;
    uint256 value;
  }

  function callExternalMultiple(ExternalCallData[] calldata calls) external;

  function getUnderlyingBalance() external view returns (uint256);
}

// File: contracts/interfaces/WrappedPiErc20FactoryInterface.sol

pragma solidity 0.6.12;


interface WrappedPiErc20FactoryInterface {
  event NewWrappedPiErc20(address indexed token, address indexed wrappedToken, address indexed creator);

  function build(
    address _token,
    address _router,
    string calldata _name,
    string calldata _symbol
  ) external returns (WrappedPiErc20Interface);
}

// File: contracts/interfaces/IPiRouterFactory.sol

pragma solidity 0.6.12;

interface IPiRouterFactory {
  function buildRouter(address _piToken, bytes calldata _args) external returns (address);
}

// File: contracts/powerindex-router/PowerIndexWrappedController.sol

pragma solidity 0.6.12;







contract PowerIndexWrappedController is PowerIndexAbstractController {
  /* ==========  EVENTS  ========== */

  /** @dev Emitted on replacing underlying token with exists piToken. */
  event ReplacePoolTokenWithPiToken(
    address indexed underlyingToken,
    address indexed piToken,
    uint256 balance,
    uint256 denormalizedWeight
  );

  /** @dev Emitted on replacing underlying token with new version of token. */
  event ReplacePoolTokenWithNewVersion(
    address indexed oldToken,
    address indexed newToken,
    address indexed migrator,
    uint256 balance,
    uint256 denormalizedWeight
  );

  /** @dev Emitted on finishing pool replacing. */
  event ReplacePoolTokenFinish();

  /** @dev Emitted on poolWrapper update. */
  event SetPoolWrapper(address indexed poolWrapper);

  /** @dev Emitted on piTokenFactory update. */
  event SetPiTokenFactory(address indexed piTokenFactory);

  /** @dev Emitted on creating piToken. */
  event CreatePiToken(address indexed underlyingToken, address indexed piToken, address indexed router);

  /* ==========  Storage  ========== */

  /** @dev Address of poolWrapper contract. */
  PowerIndexWrapperInterface public poolWrapper;

  /** @dev Address of piToken factory contract. */
  WrappedPiErc20FactoryInterface public piTokenFactory;

  constructor(
    address _pool,
    address _poolWrapper,
    address _piTokenFactory
  ) public PowerIndexAbstractController(_pool) {
    poolWrapper = PowerIndexWrapperInterface(_poolWrapper);
    piTokenFactory = WrappedPiErc20FactoryInterface(_piTokenFactory);
  }

  /**
   * @dev Set poolWrapper contract address.
   * @param _poolWrapper Address of pool wrapper.
   */
  function setPoolWrapper(address _poolWrapper) external onlyOwner {
    poolWrapper = PowerIndexWrapperInterface(_poolWrapper);
    emit SetPoolWrapper(_poolWrapper);
  }

  /**
   * @dev Set piTokenFactory contract address.
   * @param _piTokenFactory Address of PiToken factory.
   */
  function setPiTokenFactory(address _piTokenFactory) external onlyOwner {
    piTokenFactory = WrappedPiErc20FactoryInterface(_piTokenFactory);
    emit SetPiTokenFactory(_piTokenFactory);
  }

  /**
   * @dev Creating piToken using underling token and router factory.
   * @param _underlyingToken Token, which will be wrapped by piToken.
   * @param _routerFactory Router factory, to creating router by buildRouter function.
   * @param _routerArgs Router args, depends on router implementation.
   * @param _name Name of piToken.
   * @param _name Symbol of piToken.
   */
  function createPiToken(
    address _underlyingToken,
    address _routerFactory,
    bytes memory _routerArgs,
    string calldata _name,
    string calldata _symbol
  ) external onlyOwner {
    _createPiToken(_underlyingToken, _routerFactory, _routerArgs, _name, _symbol);
  }

  /**
   * @dev Creating piToken and replacing pool token with it.
   * @param _underlyingToken Token, which will be wrapped by piToken.
   * @param _routerFactory Router factory, to creating router by buildRouter function.
   * @param _routerArgs Router args, depends on router implementation.
   * @param _name Name of piToken.
   * @param _name Symbol of piToken.
   */
  function replacePoolTokenWithNewPiToken(
    address _underlyingToken,
    address _routerFactory,
    bytes calldata _routerArgs,
    string calldata _name,
    string calldata _symbol
  ) external payable onlyOwner {
    WrappedPiErc20Interface piToken = _createPiToken(_underlyingToken, _routerFactory, _routerArgs, _name, _symbol);
    _replacePoolTokenWithPiToken(_underlyingToken, piToken);
  }

  /**
   * @dev Replacing pool token with existing piToken.
   * @param _underlyingToken Token, which will be wrapped by piToken.
   * @param _piToken Address of piToken.
   */
  function replacePoolTokenWithExistingPiToken(address _underlyingToken, WrappedPiErc20Interface _piToken)
    external
    payable
    onlyOwner
  {
    _replacePoolTokenWithPiToken(_underlyingToken, _piToken);
  }

  /**
   * @dev Replacing pool token with new token version and calling migrator.
   * Warning! All balance of poll token will be approved to _migrator for exchange to new token.
   *
   * @param _oldToken Pool token ti replace with new version.
   * @param _newToken New version of token to bind to pool instead of the old.
   * @param _migrator Address of contract to migrate from old token to new. Do not use untrusted contract!
   * @param _migratorData Data for executing migrator.
   */
  function replacePoolTokenWithNewVersion(
    address _oldToken,
    address _newToken,
    address _migrator,
    bytes calldata _migratorData
  ) external onlyOwner {
    uint256 denormalizedWeight = pool.getDenormalizedWeight(_oldToken);
    uint256 balance = pool.getBalance(_oldToken);

    pool.unbind(_oldToken);

    IERC20(_oldToken).approve(_migrator, balance);
    (bool success, ) = _migrator.call(_migratorData);
    require(success, "NOT_SUCCESS");

    require(
      IERC20(_newToken).balanceOf(address(this)) >= balance,
      "PiBPoolController:newVersion: insufficient newToken balance"
    );

    IERC20(_newToken).approve(address(pool), balance);
    _bindNewToken(_newToken, balance, denormalizedWeight);

    emit ReplacePoolTokenWithNewVersion(_oldToken, _newToken, _migrator, balance, denormalizedWeight);
  }

  /*** Internal Functions ***/

  function _replacePoolTokenWithPiToken(address _underlyingToken, WrappedPiErc20Interface _piToken) internal {
    uint256 denormalizedWeight = pool.getDenormalizedWeight(_underlyingToken);
    uint256 balance = pool.getBalance(_underlyingToken);

    pool.unbind(_underlyingToken);

    IERC20(_underlyingToken).approve(address(_piToken), balance);
    _piToken.deposit{ value: msg.value }(balance);

    _piToken.approve(address(pool), balance);
    _bindNewToken(address(_piToken), balance, denormalizedWeight);

    if (address(poolWrapper) != address(0)) {
      poolWrapper.setPiTokenForUnderlying(_underlyingToken, address(_piToken));
    }

    emit ReplacePoolTokenWithPiToken(_underlyingToken, address(_piToken), balance, denormalizedWeight);
  }

  function _bindNewToken(
    address _piToken,
    uint256 _balance,
    uint256 _denormalizedWeight
  ) internal virtual {
    pool.bind(_piToken, _balance, _denormalizedWeight);
  }

  function _createPiToken(
    address _underlyingToken,
    address _routerFactory,
    bytes memory _routerArgs,
    string calldata _name,
    string calldata _symbol
  ) internal returns (WrappedPiErc20Interface) {
    WrappedPiErc20Interface piToken = piTokenFactory.build(_underlyingToken, address(this), _name, _symbol);
    address router = IPiRouterFactory(_routerFactory).buildRouter(address(piToken), _routerArgs);
    Ownable(router).transferOwnership(msg.sender);
    piToken.changeRouter(router);

    emit CreatePiToken(_underlyingToken, address(piToken), router);
    return piToken;
  }
}

// File: contracts/PowerIndexPoolController.sol

pragma solidity 0.6.12;

contract PowerIndexPoolController is PowerIndexWrappedController {
  using SafeERC20 for IERC20;

  /* ==========  Storage  ========== */

  /** @dev Signature to execute bind in pool. */
  bytes4 public constant BIND_SIG = bytes4(keccak256(bytes("bind(address,uint256,uint256,uint256,uint256)")));

  /** @dev Signature to execute unbind in pool. */
  bytes4 public constant UNBIND_SIG = bytes4(keccak256(bytes("unbind(address)")));

  struct DynamicWeightInput {
    address token;
    uint256 targetDenorm;
    uint256 fromTimestamp;
    uint256 targetTimestamp;
  }

  /** @dev Emitted on setting new weights strategy. */
  event SetWeightsStrategy(address indexed weightsStrategy);

  /** @dev Weights strategy contract address. */
  address public weightsStrategy;

  modifier onlyWeightsStrategy() {
    require(msg.sender == weightsStrategy, "ONLY_WEIGHTS_STRATEGY");
    _;
  }

  constructor(
    address _pool,
    address _poolWrapper,
    address _wrapperFactory,
    address _weightsStrategy
  ) public PowerIndexWrappedController(_pool, _poolWrapper, _wrapperFactory) {
    weightsStrategy = _weightsStrategy;
  }

  /* ==========  Configuration Actions  ========== */

  /**
   * @notice Call bind in pool.
   * @param token Token to bind.
   * @param balance Initial token balance.
   * @param targetDenorm Target weight.
   * @param fromTimestamp Start timestamp to change weight.
   * @param targetTimestamp Target timestamp to change weight.
   */
  function bind(
    address token,
    uint256 balance,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external onlyOwner {
    _validateNewTokenBind();

    IERC20(token).safeTransferFrom(msg.sender, address(this), balance);
    IERC20(token).approve(address(pool), balance);
    pool.bind(token, balance, targetDenorm, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Set the old token's target weight to MIN_WEIGHT and add a new token
   * with a previous weight of the old token.
   * @param oldToken Token to replace.
   * @param newToken New token.
   * @param balance Initial new token balance.
   * @param fromTimestamp Start timestamp to change weight.
   * @param targetTimestamp Target timestamp to change weight.
   */
  function replaceTokenWithNew(
    address oldToken,
    address newToken,
    uint256 balance,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external onlyOwner {
    _replaceTokenWithNew(oldToken, newToken, balance, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice The same as replaceTokenWithNew, but sets fromTimestamp with block.timestamp
   * and uses durationFromNow to set targetTimestamp.
   * @param oldToken Token to replace
   * @param newToken New token
   * @param balance Initial new token balance
   * @param durationFromNow Duration to set targetTimestamp.
   */
  function replaceTokenWithNewFromNow(
    address oldToken,
    address newToken,
    uint256 balance,
    uint256 durationFromNow
  ) external onlyOwner {
    uint256 now = block.timestamp.add(1);
    _replaceTokenWithNew(oldToken, newToken, balance, now, now.add(durationFromNow));
  }

  /**
   * @notice Call setDynamicWeight for several tokens.
   * @param _dynamicWeights Tokens dynamic weights configs.
   */
  function setDynamicWeightList(DynamicWeightInput[] memory _dynamicWeights) external onlyOwner {
    uint256 len = _dynamicWeights.length;
    for (uint256 i = 0; i < len; i++) {
      pool.setDynamicWeight(
        _dynamicWeights[i].token,
        _dynamicWeights[i].targetDenorm,
        _dynamicWeights[i].fromTimestamp,
        _dynamicWeights[i].targetTimestamp
      );
    }
  }

  /**
   * @notice Set _weightsStrategy address.
   * @param _weightsStrategy Contract for weights management.
   */
  function setWeightsStrategy(address _weightsStrategy) external onlyOwner {
    weightsStrategy = _weightsStrategy;
    emit SetWeightsStrategy(_weightsStrategy);
  }

  /**
   * @notice Call setDynamicWeight for several tokens, can be called only by weightsStrategy address.
   * @param _dynamicWeights Tokens dynamic weights configs.
   */
  function setDynamicWeightListByStrategy(DynamicWeightInput[] memory _dynamicWeights) external onlyWeightsStrategy {
    uint256 len = _dynamicWeights.length;
    for (uint256 i = 0; i < len; i++) {
      pool.setDynamicWeight(
        _dynamicWeights[i].token,
        _dynamicWeights[i].targetDenorm,
        _dynamicWeights[i].fromTimestamp,
        _dynamicWeights[i].targetTimestamp
      );
    }
  }

  /**
   * @notice Permissionless function to unbind tokens with MIN_WEIGHT.
   * @param _token Token to unbind.
   */
  function unbindNotActualToken(address _token) external {
    require(pool.getDenormalizedWeight(_token) == pool.getMinWeight(), "DENORM_MIN");
    (, uint256 targetTimestamp, , ) = pool.getDynamicWeightSettings(_token);
    require(block.timestamp > targetTimestamp, "TIMESTAMP_MORE_THEN_TARGET");

    uint256 tokenBalance = pool.getBalance(_token);

    pool.unbind(_token);
    (, , , address communityWallet) = pool.getCommunityFee();
    IERC20(_token).safeTransfer(communityWallet, tokenBalance);
  }

  function _checkSignature(bytes4 signature) internal pure override {
    require(signature != BIND_SIG && signature != UNBIND_SIG && signature != CALL_VOTING_SIG, "SIGNATURE_NOT_ALLOWED");
  }

  /*** Internal Functions ***/

  /**
   * @notice Set the old token's target weight to MIN_WEIGHT and
   * add a new token with a previous weight of the old token.
   * @param oldToken Token to replace
   * @param newToken New token
   * @param balance Initial new token balance
   * @param fromTimestamp Start timestamp to change weight.
   * @param targetTimestamp Target timestamp to change weight.
   */
  function _replaceTokenWithNew(
    address oldToken,
    address newToken,
    uint256 balance,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) internal {
    uint256 minWeight = pool.getMinWeight();
    (, , , uint256 targetDenorm) = pool.getDynamicWeightSettings(oldToken);

    pool.setDynamicWeight(oldToken, minWeight, fromTimestamp, targetTimestamp);

    IERC20(newToken).safeTransferFrom(msg.sender, address(this), balance);
    IERC20(newToken).approve(address(pool), balance);
    pool.bind(newToken, balance, targetDenorm.sub(minWeight), fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Check that pool doesn't have the maximum number of bound tokens.
   * If there is a max number of bound tokens, one should have a minimum weight.
   */
  function _validateNewTokenBind() internal {
    address[] memory tokens = pool.getCurrentTokens();
    uint256 tokensLen = tokens.length;
    uint256 minWeight = pool.getMinWeight();

    if (tokensLen == pool.getMaxBoundTokens() - 1) {
      for (uint256 i = 0; i < tokensLen; i++) {
        (, , , uint256 targetDenorm) = pool.getDynamicWeightSettings(tokens[i]);
        if (targetDenorm == minWeight) {
          return;
        }
      }
      revert("NEW_TOKEN_NOT_ALLOWED"); // If there is no tokens with target MIN_WEIGHT
    }
  }
}

// File: contracts/balancer-core/BConst.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

contract BConst {
    uint public constant BONE              = 10**18;
    // Minimum number of tokens in the pool
    uint public constant MIN_BOUND_TOKENS  = 2;
    // Maximum number of tokens in the pool
    uint public constant MAX_BOUND_TOKENS  = 9;
    // Minimum swap fee
    uint public constant MIN_FEE           = BONE / 10**6;
    // Maximum swap fee
    uint public constant MAX_FEE           = BONE / 10;
    // Minimum weight for token
    uint public constant MIN_WEIGHT        = 1000000000;
    // Maximum weight for token
    uint public constant MAX_WEIGHT        = BONE * 50;
    // Maximum total weight
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    // Minimum balance for a token
    uint public constant MIN_BALANCE       = BONE / 10**12;
    // Initial pool tokens supply
    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;
    // Maximum input tokens balance ratio for swaps.
    uint public constant MAX_IN_RATIO      = BONE / 2;
    // Maximum output tokens balance ratio for swaps.
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// File: contracts/balancer-core/BNum.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;


contract BNum is BConst {

    function btoi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b > 0, "ERR_DIV_ZERO");
      return a / b;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

}

// File: contracts/weight-strategies/MCapWeightAbstract.sol

pragma solidity 0.6.12;

contract MCapWeightAbstract is BNum, OwnableUpgradeSafe {
  event SetExcludeTokenBalances(address indexed token, address[] excludeTokenBalances);
  event FetchTokenMCap(address indexed pool, address indexed token, uint256 mCap);
  event UpdatePoolWeights(
    address indexed pool,
    uint256 indexed timestamp,
    address[] tokens,
    uint256[3][] weightsChange,
    uint256[] newMCaps
  );

  struct TokenConfigItem {
    address token;
    address[] excludeTokenBalances;
  }

  IPowerOracle public oracle;
  mapping(address => address[]) public excludeTokenBalances;

  constructor(address _oracle) public OwnableUpgradeSafe() {
    if (_oracle != address(0)) {
      __Ownable_init();
      oracle = IPowerOracle(_oracle);
    }
  }

  function setExcludeTokenBalances(address _token, address[] calldata _excludeTokenBalances) external onlyOwner {
    excludeTokenBalances[_token] = _excludeTokenBalances;

    emit SetExcludeTokenBalances(_token, _excludeTokenBalances);
  }

  function setExcludeTokenBalancesList(TokenConfigItem[] calldata _tokenConfigItems) external onlyOwner {
    uint256 len = _tokenConfigItems.length;
    for (uint256 i = 0; i < len; i++) {
      excludeTokenBalances[_tokenConfigItems[i].token] = _tokenConfigItems[i].excludeTokenBalances;

      emit SetExcludeTokenBalances(_tokenConfigItems[i].token, _tokenConfigItems[i].excludeTokenBalances);
    }
  }

  function getTokenMarketCap(address _token) public view returns (uint256) {
    uint256 totalSupply = IERC20(_token).totalSupply();
    uint256 len = excludeTokenBalances[_token].length;
    for (uint256 i = 0; i < len; i++) {
      totalSupply = bsub(totalSupply, IERC20(_token).balanceOf(excludeTokenBalances[_token][i]));
    }
    return bdiv(bmul(totalSupply, oracle.assetPrices(_token)), 1 ether);
  }

  function getExcludeTokenBalancesLength(address _token) external view returns (uint256) {
    return excludeTokenBalances[_token].length;
  }

  function getExcludeTokenBalancesList(address _token) external view returns (address[] memory) {
    return excludeTokenBalances[_token];
  }

  function _computeWeightsChangeWithEvent(
    PowerIndexPoolInterface _pool,
    address[] memory _tokens,
    address[] memory _piTokens,
    uint256 _minWPS,
    uint256 _maxWPS,
    uint256 fromTimestamp,
    uint256 toTimestamp
  ) internal returns (uint256[3][] memory weightsChange, uint256 lenToPush) {
    uint256[] memory newMCaps;
    (weightsChange, lenToPush, newMCaps) = computeWeightsChange(
      _pool,
      _tokens,
      _piTokens,
      _minWPS,
      _maxWPS,
      fromTimestamp,
      toTimestamp
    );
    emit UpdatePoolWeights(address(_pool), block.timestamp, _tokens, weightsChange, newMCaps);
  }

  function computeWeightsChange(
    PowerIndexPoolInterface _pool,
    address[] memory _tokens,
    address[] memory _piTokens,
    uint256 _minWPS,
    uint256 _maxWPS,
    uint256 fromTimestamp,
    uint256 toTimestamp
  )
    public
    view
    returns (
      uint256[3][] memory weightsChange,
      uint256 lenToPush,
      uint256[] memory newMCaps
    )
  {
    uint256 len = _tokens.length;
    newMCaps = new uint256[](len);

    uint256 newMarketCapSum;
    for (uint256 i = 0; i < len; i++) {
      newMCaps[i] = getTokenMarketCap(_tokens[i]);
      newMarketCapSum = badd(newMarketCapSum, newMCaps[i]);
    }

    weightsChange = new uint256[3][](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 oldWeight;
      if (_piTokens.length == _tokens.length) {
        oldWeight = _pool.getDenormalizedWeight(_piTokens[i]);
      } else {
        oldWeight = _pool.getDenormalizedWeight(_tokens[i]);
      }
      uint256 newWeight = bmul(bdiv(newMCaps[i], newMarketCapSum), 25 * BONE);
      weightsChange[i] = [i, oldWeight, newWeight];
    }

    for (uint256 i = 0; i < len; i++) {
      uint256 wps = getWeightPerSecond(weightsChange[i][1], weightsChange[i][2], fromTimestamp, toTimestamp);
      if (wps >= _minWPS) {
        lenToPush++;
      }
    }

    if (lenToPush > 1) {
      _sort(weightsChange);
    }
  }

  function getWeightPerSecond(
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) public pure returns (uint256) {
    uint256 delta = targetDenorm > fromDenorm ? bsub(targetDenorm, fromDenorm) : bsub(fromDenorm, targetDenorm);
    return div(delta, bsub(targetTimestamp, fromTimestamp));
  }

  function _quickSort(
    uint256[3][] memory wightsChange,
    int256 left,
    int256 right
  ) internal pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256[3] memory pivot = wightsChange[uint256(left + (right - left) / 2)];
    int256 pDiff = int256(pivot[2]) - int256(pivot[1]);
    while (i <= j) {
      while (int256(wightsChange[uint256(i)][2]) - int256(wightsChange[uint256(i)][1]) < pDiff) i++;
      while (pDiff < int256(wightsChange[uint256(j)][2]) - int256(wightsChange[uint256(j)][1])) j--;
      if (i <= j) {
        (wightsChange[uint256(i)], wightsChange[uint256(j)]) = (wightsChange[uint256(j)], wightsChange[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) _quickSort(wightsChange, left, j);
    if (i < right) _quickSort(wightsChange, i, right);
  }

  function _sort(uint256[3][] memory weightsChange) internal pure {
    _quickSort(weightsChange, int256(0), int256(weightsChange.length - 1));
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
}

// File: contracts/weight-strategies/MCapWeightStrategy.sol

pragma solidity 0.6.12;

contract MCapWeightStrategy is MCapWeightAbstract {
  event AddPool(address indexed pool, address indexed poolController);
  event SetPool(address indexed pool, address indexed poolController, bool indexed active);
  event SetWeightsChangeDuration(uint256 weightsChangeDuration);

  struct PokeVars {
    PowerIndexPoolInterface pool;
    uint256 minWPS;
    uint256 maxWPS;
    address[] tokens;
    address[] piTokens;
    uint256 tokensLen;
    uint256 fromTimestamp;
    uint256 iToPush;
  }

  struct Pool {
    PowerIndexPoolController controller;
    PowerIndexWrapperInterface wrapper;
    uint256 lastWeightsUpdate;
    bool active;
  }

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;

  address[] public pools;
  mapping(address => Pool) public poolsData;

  uint256 weightsChangeDuration;

  IPowerPoke public powerPoke;

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

  modifier denyContract() {
    require(msg.sender == tx.origin, "CONTRACT_CALL");
    _;
  }

  constructor() public MCapWeightAbstract(address(0)) {}

  function initialize(
    address _oracle,
    address _powerPoke,
    uint256 _weightsChangeDuration
  ) external initializer {
    __Ownable_init();
    oracle = IPowerOracle(_oracle);
    powerPoke = IPowerPoke(_powerPoke);
    weightsChangeDuration = _weightsChangeDuration;
  }

  function setWeightsChangeDuration(uint256 _weightsChangeDuration) external onlyOwner {
    weightsChangeDuration = _weightsChangeDuration;

    emit SetWeightsChangeDuration(_weightsChangeDuration);
  }

  function addPool(
    address _poolAddress,
    address _controller,
    address _wrapper
  ) external onlyOwner {
    require(address(poolsData[_poolAddress].controller) == address(0), "ALREADY_EXIST");
    require(_controller != address(0), "CONTROLLER_CANT_BE_NULL");
    pools.push(_poolAddress);
    poolsData[_poolAddress].controller = PowerIndexPoolController(_controller);
    poolsData[_poolAddress].wrapper = PowerIndexWrapperInterface(_wrapper);
    poolsData[_poolAddress].active = true;
    emit AddPool(_poolAddress, _controller);
  }

  function setPool(
    address _poolAddress,
    address _controller,
    address _wrapper,
    bool _active
  ) external onlyOwner {
    require(_controller != address(0), "CONTROLLER_CANT_BE_NULL");
    poolsData[_poolAddress].controller = PowerIndexPoolController(_controller);
    poolsData[_poolAddress].wrapper = PowerIndexWrapperInterface(_wrapper);
    poolsData[_poolAddress].active = _active;
    emit SetPool(_poolAddress, _controller, _active);
  }

  function pausePool(address _poolAddress) external onlyOwner {
    poolsData[_poolAddress].active = false;
    PowerIndexPoolInterface pool = PowerIndexPoolInterface(_poolAddress);
    address[] memory tokens = pool.getCurrentTokens();

    uint256 len = tokens.length;
    PowerIndexPoolController.DynamicWeightInput[] memory dws;
    dws = new PowerIndexPoolController.DynamicWeightInput[](len);

    for (uint256 i = 0; i < len; i++) {
      dws[i].token = tokens[i];
      dws[i].fromTimestamp = block.timestamp + 1;
      dws[i].targetTimestamp = block.timestamp + 2;
      dws[i].targetDenorm = pool.getDenormalizedWeight(tokens[i]);
    }

    poolsData[_poolAddress].controller.setDynamicWeightListByStrategy(dws);
  }

  function pokeFromReporter(
    uint256 _reporterId,
    address[] memory _pools,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) denyContract {
    _poke(_pools, false);
  }

  function pokeFromSlasher(
    uint256 _reporterId,
    address[] memory _pools,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) denyContract {
    _poke(_pools, true);
  }

  function getPoolsList() external view returns (address[] memory) {
    return pools;
  }

  function getPoolsLength() external view returns (uint256) {
    return pools.length;
  }

  function getActivePoolsList() external view returns (address[] memory output) {
    uint256 len = pools.length;
    uint256 activeLen = 0;

    for (uint256 i; i < len; i++) {
      if (poolsData[pools[i]].active) {
        activeLen++;
      }
    }

    output = new address[](activeLen);
    uint256 ai;
    for (uint256 i; i < len; i++) {
      if (poolsData[pools[i]].active) {
        output[ai++] = pools[i];
      }
    }
  }

  function _poke(address[] memory _pools, bool _bySlasher) internal {
    require(_pools.length != 0, "NULL_LENGTH");

    (uint256 minInterval, uint256 maxInterval) = _getMinMaxReportInterval();
    for (uint256 pi = 0; pi < _pools.length; pi++) {
      PokeVars memory pv;
      pv.pool = PowerIndexPoolInterface(_pools[pi]);

      Pool storage pd = poolsData[address(pv.pool)];
      require(pd.active, "NOT_ACTIVE");
      require(pd.lastWeightsUpdate + minInterval < block.timestamp, "MIN_INTERVAL_NOT_REACHED");
      if (_bySlasher) {
        require(pd.lastWeightsUpdate + maxInterval < block.timestamp, "MAX_INTERVAL_NOT_REACHED");
      }
      (pv.minWPS, pv.maxWPS) = pv.pool.getWeightPerSecondBounds();

      if (address(pd.wrapper) == address(0)) {
        pv.tokens = pv.pool.getCurrentTokens();
      } else {
        pv.tokens = pd.wrapper.getCurrentTokens();
        pv.piTokens = pv.pool.getCurrentTokens();
      }
      pv.tokensLen = pv.tokens.length;

      pv.fromTimestamp = block.timestamp + 1;

      (uint256[3][] memory weightsChange, uint256 lenToPush) =
        _computeWeightsChangeWithEvent(
          pv.pool,
          pv.tokens,
          pv.piTokens,
          pv.minWPS,
          pv.maxWPS,
          pv.fromTimestamp,
          pv.fromTimestamp + weightsChangeDuration
        );

      PowerIndexPoolController.DynamicWeightInput[] memory dws;
      dws = new PowerIndexPoolController.DynamicWeightInput[](lenToPush);

      for (uint256 i = 0; i < pv.tokensLen; i++) {
        uint256 wps =
          getWeightPerSecond(
            weightsChange[i][1],
            weightsChange[i][2],
            pv.fromTimestamp,
            pv.fromTimestamp + weightsChangeDuration
          );

        if (wps > pv.maxWPS) {
          if (weightsChange[i][1] > weightsChange[i][2]) {
            weightsChange[i][2] = bsub(weightsChange[i][1], mul(weightsChangeDuration, pv.maxWPS));
          } else {
            weightsChange[i][2] = badd(weightsChange[i][1], mul(weightsChangeDuration, pv.maxWPS));
          }
        }

        if (wps >= pv.minWPS) {
          if (address(pd.wrapper) == address(0)) {
            dws[pv.iToPush].token = pv.tokens[weightsChange[i][0]];
          } else {
            dws[pv.iToPush].token = pv.piTokens[weightsChange[i][0]];
          }
          dws[pv.iToPush].fromTimestamp = pv.fromTimestamp;
          dws[pv.iToPush].targetTimestamp = pv.fromTimestamp + weightsChangeDuration;
          dws[pv.iToPush].targetDenorm = weightsChange[i][2];
          pv.iToPush++;
        }
      }

      if (dws.length > 0) {
        pd.controller.setDynamicWeightListByStrategy(dws);
      }

      pd.lastWeightsUpdate = block.timestamp;
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, bsub(_gasStart, gasleft()), _compensationPlan, _rewardOpts);
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }
}