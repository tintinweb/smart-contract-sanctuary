/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;


// 
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

// 
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

// 
interface IVotingEscrow {
  enum LockAction { CREATE_LOCK, INCREASE_LOCK_AMOUNT, INCREASE_LOCK_TIME }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  /** Shared Events */
  event Deposit(address indexed provider, uint256 value, uint256 locktime, LockAction indexed action, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event Expired();

  function createLock(uint256 _value, uint256 _unlockTime) external;

  function increaseLockAmount(uint256 _value) external;

  function increaseLockLength(uint256 _unlockTime) external;

  function withdraw() external;

  function expireContract() external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function balanceOfAt(address _owner, uint256 _blockTime) external view returns (uint256);

  function stakingToken() external view returns (IERC20);
}

// 
interface IGovernorAlpha {
    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;

        // Creator of the proposal
        address proposer;

        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        // the ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
        uint256 startTime;

        // The timestamp at which voting ends: votes must be cast prior to this timestamp
        uint endTime;

        // Current number of votes in favor of this proposal
        uint256 forVotes;

        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;

        // The number of votes the voter had, which were cast
        uint votes;
    }

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint startTime, uint endTime, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    function propose(address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, uint256 endTime) external returns (uint);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

    function cancel(uint256 proposalId) external;

    function castVote(uint256 proposalId, bool support) external;

    function getActions(uint256 proposalId) external view returns (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas);

    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

    function state(uint proposalId) external view returns (ProposalState);

    function quorumVotes() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);
}

// 
interface ITimelock {
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  function acceptAdmin() external;

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);

  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function queuedTransactions(bytes32 hash) external view returns (bool);
}

// 
interface IAccessController {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// 
interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}

// 
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// 
interface IPriceFeed {
  event OracleUpdated(address indexed asset, address oracle, address sender);
  event EurOracleUpdated(address oracle, address sender);

  function setAssetOracle(address _asset, address _oracle) external;

  function setEurOracle(address _oracle) external;

  function a() external view returns (IAddressProvider);

  function assetOracles(address _asset) external view returns (AggregatorV3Interface);

  function eurOracle() external view returns (AggregatorV3Interface);

  function getAssetPrice(address _asset) external view returns (uint256);

  function convertFrom(address _asset, uint256 _amount) external view returns (uint256);

  function convertTo(address _asset, uint256 _amount) external view returns (uint256);
}

// 
interface IRatesManager {
  function a() external view returns (IAddressProvider);

  //current annualized borrow rate
  function annualizedBorrowRate(uint256 _currentBorrowRate) external pure returns (uint256);

  //uses current cumulative rate to calculate totalDebt based on baseDebt at time T0
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) external pure returns (uint256);

  //uses current cumulative rate to calculate baseDebt at time T0
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) external pure returns (uint256);

  //calculate a new cumulative rate
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) external view returns (uint256);
}

// 
interface ILiquidationManager {
  function a() external view returns (IAddressProvider);

  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(address _collateralType, uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    external
    view
    returns (uint256 discountedAmount);

  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (bool);
}

// 
interface IVaultsDataProvider {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  // Read
  function a() external view returns (IAddressProvider);

  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// 
interface IFeeDistributor {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProvider);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// 
interface IAddressProvider {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProvider _config) external;

  function setVaultsCore(IVaultsCore _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManager _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProvider);

  function core() external view returns (IVaultsCore);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManager);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// 
interface IConfigProviderV1 {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setLiquidationBonus(uint256 _bonus) external;

  function a() external view returns (IAddressProviderV1);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function liquidationBonus() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);
}

// 
interface ILiquidationManagerV1 {
  function a() external view returns (IAddressProviderV1);

  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(uint256 _amount) external view returns (uint256 discountedAmount);

  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (bool);
}

// 
interface IVaultsCoreV1 {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawAll(uint256 _vaultId) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  //Refresh
  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  //upgrade
  function upgrade(address _newVaultsCore) external;

  //Read only

  function a() external view returns (IAddressProviderV1);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);
}

// 
interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;
}

// 
interface IMIMO is IERC20 {

  function burn(address account, uint256 amount) external;
  
  function mint(address account, uint256 amount) external;

}

// 
interface ISupplyMiner {

  function baseDebtChanged(address user, uint256 newBaseDebt) external;
}

// 
interface IDebtNotifier {

  function debtChanged(uint256 _vaultId) external;

  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) external;

  function a() external view returns (IGovernanceAddressProvider);

	function collateralSupplyMinerMapping(address collateral) external view returns (ISupplyMiner);
}

// 
interface IGovernanceAddressProvider {
  function setParallelAddressProvider(IAddressProvider _parallel) external;

  function setMIMO(IMIMO _mimo) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  function setGovernorAlpha(IGovernorAlpha _governorAlpha) external;

  function setTimelock(ITimelock _timelock) external;

  function setVotingEscrow(IVotingEscrow _votingEscrow) external;

  function controller() external view returns (IAccessController);

  function parallel() external view returns (IAddressProvider);

  function mimo() external view returns (IMIMO);

  function debtNotifier() external view returns (IDebtNotifier);

  function governorAlpha() external view returns (IGovernorAlpha);

  function timelock() external view returns (ITimelock);

  function votingEscrow() external view returns (IVotingEscrow);
}

// 
interface IVaultsCore {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function depositETH() external payable;

  function depositByVaultId(uint256 _vaultId, uint256 _amount) external;

  function depositETHByVaultId(uint256 _vaultId) external payable;

  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) external;

  function depositETHAndBorrow(uint256 _borrowAmount) external payable;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawETH(uint256 _vaultId, uint256 _amount) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  function liquidatePartial(uint256 _vaultId, uint256 _amount) external;

  function upgrade(address payable _newVaultsCore) external;

  function acceptUpgrade(address payable _oldVaultsCore) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function WETH() external view returns (IWETH);

  function debtNotifier() external view returns (IDebtNotifier);

  function state() external view returns (IVaultsCoreState);

  function cumulativeRates(address _collateralType) external view returns (uint256);
}

// 
interface IAddressProviderV1 {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProviderV1 _config) external;

  function setVaultsCore(IVaultsCoreV1 _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManagerV1 _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProviderV1);

  function core() external view returns (IVaultsCoreV1);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManagerV1);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// 
interface IVaultsCoreState {
  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  function syncState(IVaultsCoreState _stateAddress) external;

  function syncStateFromV1(IVaultsCoreV1 _core) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);

  function synced() external view returns (bool);
}

// 
interface IConfigProvider {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 liquidationRatio;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
    uint256 liquidationBonus;
    uint256 liquidationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 liquidationRatio,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee,
    uint256 liquidationBonus,
    uint256 liquidationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus) external;

  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) external;

  function setMinVotingPeriod(uint256 _minVotingPeriod) external;

  function setMaxVotingPeriod(uint256 _maxVotingPeriod) external;

  function setVotingQuorum(uint256 _votingQuorum) external;

  function setProposalThreshold(uint256 _proposalThreshold) external;

  function a() external view returns (IAddressProvider);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function minVotingPeriod() external view returns (uint256);

  function maxVotingPeriod() external view returns (uint256);

  function votingQuorum() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralLiquidationRatio(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);

  function collateralLiquidationBonus(address _collateralType) external view returns (uint256);

  function collateralLiquidationFee(address _collateralType) external view returns (uint256);
}

// 
/* solium-disable security/no-block-members */
/**
 * @title  VotingEscrow
 * @notice Lockup GOV, receive vGOV (voting weight that decays over time)
 * @dev    Supports:
 *            1) Tracking MIMO Locked up
 *            2) Decaying voting weight lookup
 *            3) Closure of contract
 */
contract VotingEscrow is IVotingEscrow, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant MAXTIME = 1460 days; // 365 * 4 years
  bool public expired = false;
  IERC20 public override stakingToken;

  mapping(address => LockedBalance) public locked;

  string public override name;
  string public override symbol;
  // solhint-disable-next-line
  uint256 public constant override decimals = 18;

  // AddressProvider
  IGovernanceAddressProvider public a;

  constructor(
    IERC20 _stakingToken,
    IGovernanceAddressProvider _a,
    string memory _name,
    string memory _symbol
  ) public {
    require(address(_stakingToken) != address(0));
    require(address(_a) != address(0));

    stakingToken = _stakingToken;
    a = _a;

    name = _name;
    symbol = _symbol;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /** @dev Modifier to ensure contract has not yet expired */
  modifier contractNotExpired() {
    require(!expired, "Contract is expired");
    _;
  }

  /**
   * @dev Creates a new lock
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   */
  function createLock(uint256 _value, uint256 _unlockTime) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount == 0, "Withdraw old tokens first");
    require(_unlockTime > block.timestamp, "Can only lock until time in the future");

    _depositFor(msg.sender, _value, _unlockTime, locked_, LockAction.CREATE_LOCK);
  }

  /**
   * @dev Increases amount of stake thats locked up & resets decay
   * @param _value Additional units of StakingToken to add to exiting stake
   */
  function increaseLockAmount(uint256 _value) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount > 0, "No existing lock found");
    require(locked_.end > block.timestamp, "Cannot add to expired lock. Withdraw");

    _depositFor(msg.sender, _value, 0, locked_, LockAction.INCREASE_LOCK_AMOUNT);
  }

  /**
   * @dev Increases length of lockup & resets decay
   * @param _unlockTime New unlocktime for lockup
   */
  function increaseLockLength(uint256 _unlockTime) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(locked_.amount > 0, "Nothing is locked");
    require(locked_.end > block.timestamp, "Lock expired");
    require(_unlockTime > locked_.end, "Can only increase lock time");

    _depositFor(msg.sender, 0, _unlockTime, locked_, LockAction.INCREASE_LOCK_TIME);
  }

  /**
   * @dev Withdraws all the senders stake, providing lockup is over
   */
  function withdraw() external override {
    _withdraw(msg.sender);
  }

  /**
   * @dev Ends the contract, unlocking all stakes.
   * No more staking can happen. Only withdraw.
   */
  function expireContract() external override onlyManager contractNotExpired {
    expired = true;
    emit Expired();
  }

  /***************************************
                    GETTERS
    ****************************************/

  /**
   * @dev Gets the user's votingWeight at the current time.
   * @param _owner User for which to return the votingWeight
   * @return uint256 Balance of user
   */
  function balanceOf(address _owner) public view override returns (uint256) {
    return balanceOfAt(_owner, block.timestamp);
  }

  /**
   * @dev Gets a users votingWeight at a given block timestamp
   * @param _owner User for which to return the balance
   * @param _blockTime Timestamp for which to calculate balance. Can not be in the past
   * @return uint256 Balance of user
   */
  function balanceOfAt(address _owner, uint256 _blockTime) public view override returns (uint256) {
    require(_blockTime >= block.timestamp, "Must pass block timestamp in the future");

    LockedBalance memory currentLock = locked[_owner];

    if (currentLock.end <= _blockTime) return 0;
    uint256 remainingLocktime = currentLock.end.sub(_blockTime);
    if (remainingLocktime > MAXTIME) {
      remainingLocktime = MAXTIME;
    }

    return currentLock.amount.mul(remainingLocktime).div(MAXTIME);
  }

  /**
   * @dev Deposits or creates a stake for a given address
   * @param _addr User address to assign the stake
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   * @param _oldLocked Previous amount staked by this user
   * @param _action See LockAction enum
   */
  function _depositFor(
    address _addr,
    uint256 _value,
    uint256 _unlockTime,
    LockedBalance memory _oldLocked,
    LockAction _action
  ) internal {
    LockedBalance memory newLocked = LockedBalance({ amount: _oldLocked.amount, end: _oldLocked.end });

    // Adding to existing lock, or if a lock is expired - creating a new one
    newLocked.amount = newLocked.amount.add(_value);
    if (_unlockTime != 0) {
      newLocked.end = _unlockTime;
    }
    locked[_addr] = newLocked;

    if (_value != 0) {
      stakingToken.safeTransferFrom(_addr, address(this), _value);
    }

    emit Deposit(_addr, _value, newLocked.end, _action, block.timestamp);
  }

  /**
   * @dev Withdraws a given users stake, providing the lockup has finished
   * @param _addr User for which to withdraw
   */
  function _withdraw(address _addr) internal nonReentrant {
    LockedBalance memory oldLock = LockedBalance({ end: locked[_addr].end, amount: locked[_addr].amount });
    require(block.timestamp >= oldLock.end || expired, "The lock didn't expire");
    require(oldLock.amount > 0, "Must have something to withdraw");

    uint256 value = uint256(oldLock.amount);

    LockedBalance memory currentLock = LockedBalance({ end: 0, amount: 0 });
    locked[_addr] = currentLock;

    stakingToken.safeTransfer(_addr, value);

    emit Withdraw(_addr, value, block.timestamp);
  }
}