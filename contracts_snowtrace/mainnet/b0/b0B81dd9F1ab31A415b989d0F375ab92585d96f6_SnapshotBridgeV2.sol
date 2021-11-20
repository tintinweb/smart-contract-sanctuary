/**
 *Submitted for verification at snowtrace.io on 2021-11-20
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



pragma solidity ^0.8.0;


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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File apps/avai/src/contracts/PodLeader.sol


pragma solidity ^0.8.0;



// Built off Yak's MasterYak, with alterations to allow for transfers of ERC20 instead of AVAX.
// Good luck and have fun
contract PodLeader is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @notice Info of each user.
  struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardTokenDebt; // Reward debt for reward token. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of reward tokens
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
    //   1. The pool's `accRewardsPerShare` (and `lastRewardTimestamp`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  /// @notice Info of each pool.
  struct PoolInfo {
    IERC20 token; // Address of token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. Reward tokens to distribute per second.
    uint256 lastRewardTimestamp; // Last timestamp where reward tokens were distributed.
    uint256 accRewardsPerShare; // Accumulated reward tokens per share, times 1e12. See below.
    uint256 totalStaked; // Total amount of token staked via Rewards Manager
    uint16 depositFeeBP; // Deposit fee in basis points
  }

  IERC20 public orca;

  /// @notice Rewards rewarded per second
  uint256 public rewardsPerSecond;

  /// @notice Info of each pool.
  PoolInfo[] public poolInfo;

  /// @notice Info of each user that stakes tokens
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  // Treasury address
  address public treasury;

  /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  /// @notice The timestamp when rewards start.
  uint256 public startTimestamp;

  /// @notice The timestamp when rewards end.
  uint256 public endTimestamp;

  /// @notice Event emitted when a user deposits funds in the rewards manager
  event Deposit(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    uint256 fee
  );

  /// @notice Event emitted when a user withdraws their original funds + rewards from the rewards manager
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

  /// @notice Event emitted when a user withdraws their original funds from the rewards manager without claiming rewards
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );

  /// @notice Event emitted when new pool is added to the rewards manager
  event PoolAdded(
    uint256 indexed pid,
    address indexed token,
    uint256 allocPoints,
    uint256 totalAllocPoints,
    uint256 rewardStartTimestamp,
    uint16 depositFeeBP
  );

  /// @notice Event emitted when pool allocation points are updated
  event PoolUpdated(
    uint256 indexed pid,
    uint256 oldAllocPoints,
    uint256 newAllocPoints,
    uint256 newTotalAllocPoints
  );

  /// @notice Event emitted when the owner of the rewards manager contract is updated
  event ChangedTreasury(
    address indexed oldTreasury,
    address indexed newTreasury
  );

  /// @notice Event emitted when the amount of reward tokens per seconds is updated
  event ChangedRewardsPerSecond(
    uint256 indexed oldRewardsPerSecond,
    uint256 indexed newRewardsPerSecond
  );

  /// @notice Event emitted when the rewards start timestamp is set
  event SetRewardsStartTimestamp(uint256 indexed startTimestamp);

  /// @notice Event emitted when the rewards end timestamp is updated
  event ChangedRewardsEndTimestamp(
    uint256 indexed oldEndTimestamp,
    uint256 indexed newEndTimestamp
  );

  /// @notice Event emitted when contract address is changed
  event ChangedAddress(
    string indexed addressType,
    address indexed oldAddress,
    address indexed newAddress
  );

  /// @notice Event emitted when deposit fee is updated
  event DepositFeeUpdated(uint256 indexed pid, uint16 oldFee, uint16 newFee);

  /**
   * @notice Create a new Rewards Manager contract
   * @param _startTimestamp timestamp when rewards will start
   * @param _rewardsPerSecond initial amount of reward tokens to be distributed per second
   */
  constructor(
    IERC20 _orca,
    uint256 _startTimestamp,
    uint256 _rewardsPerSecond,
    address _treasury
  ) {
    startTimestamp = _startTimestamp == 0 ? block.timestamp : _startTimestamp;
    emit SetRewardsStartTimestamp(startTimestamp);

    rewardsPerSecond = _rewardsPerSecond;
    emit ChangedRewardsPerSecond(0, _rewardsPerSecond);

    // Set orca token address
    orca = _orca;

    treasury = _treasury;
    emit ChangedTreasury(address(0), _treasury);
  }

  receive() external payable {}

  /**
   * @notice Sets the treasury where fees will go to
   */
  function setTreasury(address _treasury) public onlyOwner {
    address oldTreasury = treasury;
    treasury = _treasury;
    emit ChangedTreasury(oldTreasury, _treasury);
  }

  /**
   * @notice View function to see current poolInfo array length
   * @return pool length
   */
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  /**
   * @notice Add rewards to contract
   * @dev Can only be called by the owner
   */
  function addRewardsBalance(uint256 amount) external onlyOwner {
    orca.safeTransferFrom(msg.sender, address(this), amount);
    _setRewardsEndTimestamp();
  }

  /**
   * @notice Add a new reward token to the pool
   * @dev Can only be called by the owner. DO NOT add the same token more than once. Rewards will be messed up if you do.
   * @param allocPoint Number of allocation points to allot to this token/pool
   * @param token The token that will be staked for rewards
   * @param withUpdate if specified, update all pools before adding new pool
   * @param _depositFeeBp If true, users get voting power for deposits
   */
  function add(
    uint256 allocPoint,
    address token,
    bool withUpdate,
    uint16 _depositFeeBp
  ) external onlyOwner {
    if (withUpdate) {
      massUpdatePools();
    }
    uint256 rewardStartTimestamp = block.timestamp > startTimestamp
      ? block.timestamp
      : startTimestamp;
    if (totalAllocPoint == 0) {
      _setRewardsEndTimestamp();
    }
    totalAllocPoint = totalAllocPoint + allocPoint;
    poolInfo.push(
      PoolInfo({
        token: IERC20(token),
        allocPoint: allocPoint,
        lastRewardTimestamp: rewardStartTimestamp,
        accRewardsPerShare: 0,
        totalStaked: 0,
        depositFeeBP: _depositFeeBp
      })
    );
    emit PoolAdded(
      poolInfo.length - 1,
      token,
      allocPoint,
      totalAllocPoint,
      rewardStartTimestamp,
      _depositFeeBp
    );
  }

  /**
   * @notice Update the given pool's allocation points
   * @dev Can only be called by the owner
   * @param pid The RewardManager pool id
   * @param allocPoint New number of allocation points for pool
   * @param withUpdate if specified, update all pools before setting allocation points
   */
  function set(
    uint256 pid,
    uint256 allocPoint,
    bool withUpdate
  ) external onlyOwner {
    if (withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint - poolInfo[pid].allocPoint + allocPoint;
    emit PoolUpdated(
      pid,
      poolInfo[pid].allocPoint,
      allocPoint,
      totalAllocPoint
    );
    poolInfo[pid].allocPoint = allocPoint;
  }

  /**
   * @notice Update the given pool's deposit fee
   * @dev Can only be called by the owner
   * @param pid The RewardManager pool id
   * @param depositFee New deposit fee for the pool, in basis points
   * @param withUpdate if specified, update all pools before updated deposit fee
   */
  function updateDepositFee(
    uint256 pid,
    uint16 depositFee,
    bool withUpdate
  ) external onlyOwner {
    if (withUpdate) {
      massUpdatePools();
    }

    emit DepositFeeUpdated(pid, poolInfo[pid].depositFeeBP, depositFee);
    poolInfo[pid].depositFeeBP = depositFee;
  }

  /**
   * @notice Returns true if rewards are actively being accumulated
   */
  function rewardsActive() public view returns (bool) {
    return
      block.timestamp >= startTimestamp &&
        block.timestamp <= endTimestamp &&
        totalAllocPoint > 0
        ? true
        : false;
  }

  /**
   * @notice Return reward multiplier over the given from to to timestamp.
   * @param from From timestamp
   * @param to To timestamp
   * @return multiplier
   */
  function getMultiplier(uint256 from, uint256 to)
    public
    view
    returns (uint256)
  {
    uint256 toTimestamp = to > endTimestamp ? endTimestamp : to;
    return toTimestamp > from ? toTimestamp - from : 0;
  }

  /**
   * @notice View function to see pending rewards on frontend.
   * @param pid pool id
   * @param account user account to check
   * @return pending rewards
   */
  function pendingRewards(uint256 pid, address account)
    external
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][account];
    uint256 accRewardsPerShare = pool.accRewardsPerShare;
    uint256 tokenSupply = pool.totalStaked;
    if (block.timestamp > pool.lastRewardTimestamp && tokenSupply != 0) {
      uint256 multiplier = getMultiplier(
        pool.lastRewardTimestamp,
        block.timestamp
      );
      uint256 totalReward = (multiplier * rewardsPerSecond * pool.allocPoint) /
        (totalAllocPoint);
      accRewardsPerShare =
        accRewardsPerShare +
        ((totalReward * 1e12) / tokenSupply);
    }

    uint256 accumulatedRewards = (user.amount * accRewardsPerShare) / 1e12;

    if (accumulatedRewards < user.rewardTokenDebt) {
      return 0;
    }

    return accumulatedRewards - user.rewardTokenDebt;
  }

  /**
   * @notice Update reward variables for all pools
   * @dev Be careful of gas spending!
   */
  function massUpdatePools() public {
    for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
      updatePool(pid);
    }
  }

  /**
   * @notice Update reward variables of the given pool to be up-to-date
   * @param pid pool id
   */
  function updatePool(uint256 pid) public {
    PoolInfo storage pool = poolInfo[pid];
    if (block.timestamp <= pool.lastRewardTimestamp) {
      return;
    }

    uint256 tokenSupply = pool.totalStaked;
    if (tokenSupply == 0) {
      pool.lastRewardTimestamp = block.timestamp;
      return;
    }
    uint256 multiplier = getMultiplier(
      pool.lastRewardTimestamp,
      block.timestamp
    );
    uint256 totalReward = (multiplier * rewardsPerSecond * pool.allocPoint) /
      totalAllocPoint;
    pool.accRewardsPerShare =
      pool.accRewardsPerShare +
      ((totalReward * 1e12) / tokenSupply);

    pool.lastRewardTimestamp = block.timestamp;
  }

  /**
   * @notice Deposit tokens to PodLeader for rewards allocation.
   * @param pid pool id
   * @param amount number of tokens to deposit
   */
  function deposit(uint256 pid, uint256 amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _deposit(pid, amount, pool, user);
  }

  /**
   * @notice Withdraw tokens from PodLeader, claiming rewards.
   * @param pid pool id
   * @param amount number of tokens to withdraw
   */
  function withdraw(uint256 pid, uint256 amount) external nonReentrant {
    require(amount > 0, 'PodLeader::withdraw: amount must be > 0');
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _withdraw(pid, amount, pool, user);
  }

  /**
   * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
   * @param pid pool id
   */
  function emergencyWithdraw(uint256 pid) external nonReentrant {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];

    if (user.amount > 0) {
      pool.totalStaked = pool.totalStaked - user.amount;
      pool.token.safeTransfer(msg.sender, user.amount);

      emit EmergencyWithdraw(msg.sender, pid, user.amount);

      user.amount = 0;
      user.rewardTokenDebt = 0;
    }
  }

  /**
   * @notice Set new rewards per second
   * @dev Can only be called by the owner
   * @param newRewardsPerSecond new amount of rewards to reward each second
   */
  function setRewardsPerSecond(uint256 newRewardsPerSecond) external onlyOwner {
    emit ChangedRewardsPerSecond(rewardsPerSecond, newRewardsPerSecond);
    rewardsPerSecond = newRewardsPerSecond;
    _setRewardsEndTimestamp();
  }

  /**
   * @notice Internal implementation of deposit
   * @param pid pool id
   * @param amount number of tokens to deposit
   * @param pool the pool info
   * @param user the user info
   */
  function _deposit(
    uint256 pid,
    uint256 amount,
    PoolInfo storage pool,
    UserInfo storage user
  ) internal {
    updatePool(pid);

    if (user.amount > 0) {
      uint256 pendingRewardAmount = (user.amount * pool.accRewardsPerShare) /
        1e12 -
        user.rewardTokenDebt;

      if (pendingRewardAmount > 0) {
        _safeRewardsTransfer(msg.sender, pendingRewardAmount);
      }
    }

    pool.token.safeTransferFrom(msg.sender, address(this), amount);

    uint256 depositFee = (amount * pool.depositFeeBP) / 10000;
    if (depositFee > 0) {
      pool.token.safeTransfer(treasury, depositFee);
      pool.totalStaked = pool.totalStaked + amount - depositFee;
      user.amount = user.amount + amount - depositFee;
    } else {
      pool.totalStaked = pool.totalStaked + amount;
      user.amount = user.amount + amount;
    }

    user.rewardTokenDebt = (user.amount * pool.accRewardsPerShare) / 1e12;

    emit Deposit(msg.sender, pid, amount, depositFee);
  }

  /**
   * @notice Internal implementation of withdraw
   * @param pid pool id
   * @param amount number of tokens to withdraw
   * @param pool the pool info
   * @param user the user info
   */
  function _withdraw(
    uint256 pid,
    uint256 amount,
    PoolInfo storage pool,
    UserInfo storage user
  ) internal {
    require(
      user.amount >= amount,
      'PodLeader::_withdraw: amount > user balance'
    );

    updatePool(pid);

    uint256 pendingRewardAmount = (user.amount * pool.accRewardsPerShare) /
      1e12 -
      user.rewardTokenDebt;
    user.amount = user.amount - amount;
    user.rewardTokenDebt = (user.amount * pool.accRewardsPerShare) / 1e12;

    if (pendingRewardAmount > 0) {
      _safeRewardsTransfer(msg.sender, pendingRewardAmount);
    }

    pool.totalStaked = pool.totalStaked - amount;
    pool.token.safeTransfer(msg.sender, amount);

    emit Withdraw(msg.sender, pid, amount);
  }

  /**
   * @notice Safe reward transfer function, just in case if rounding error causes pool to not have enough reward token.
   * @param to account that is receiving rewards
   * @param amount amount of rewards to send
   */
  function _safeRewardsTransfer(address to, uint256 amount) internal {
    uint256 rewardTokenBalance = orca.balanceOf(address(this));
    if (amount > rewardTokenBalance) {
      orca.safeTransfer(to, rewardTokenBalance);
    } else {
      orca.safeTransfer(to, amount);
    }
  }

  /**
   * @notice Internal function that updates rewards end timestamp based on rewards per second and the balance of the contract
   */
  function _setRewardsEndTimestamp() internal {
    if (rewardsPerSecond > 0) {
      uint256 rewardFromTimestamp = block.timestamp >= startTimestamp
        ? block.timestamp
        : startTimestamp;
      uint256 newEndTimestamp = rewardFromTimestamp +
        (orca.balanceOf(address(this)) / rewardsPerSecond);
      if (
        newEndTimestamp > rewardFromTimestamp && newEndTimestamp != endTimestamp
      ) {
        emit ChangedRewardsEndTimestamp(endTimestamp, newEndTimestamp);
        endTimestamp = newEndTimestamp;
      }
    }
  }
}


// File apps/avai/src/contracts/interfaces/IPair.sol


pragma solidity ^0.8.0;

interface IPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}


// File apps/avai/src/contracts/snapshot/UpdateSnapshotBridge.sol


pragma solidity ^0.8.0;


contract SnapshotBridgeV2 {
  PodLeader staking;
  PodLeader podLeader;

  IERC20 xOrca;
  IERC20 orca;

  constructor(
    address payable _staking,
    address payable _podleader,
    address _orca,
    address _xorca
  ) {
    staking = PodLeader(_staking);
    podLeader = PodLeader(_podleader);
    orca = IERC20(_orca);
    xOrca = IERC20(_xorca);
  }

  function xOrcaVote(address user) public view returns (uint256) {
    uint256 xOrcaSupply = xOrca.totalSupply();
    uint256 xOrcaOrcaSupply = orca.balanceOf(address(xOrca));
    uint256 ratio = (xOrcaOrcaSupply * 10000) / xOrcaSupply;

    uint256 userBalance = (ratio * xOrca.balanceOf(user)) / 10000;
    return userBalance;
  }

  function xOrcaStakedVote(address user, uint256 pid)
    public
    view
    returns (uint256)
  {
    uint256 xOrcaSupply = xOrca.totalSupply();
    uint256 xOrcaOrcaSupply = orca.balanceOf(address(xOrca));
    uint256 ratio = (xOrcaOrcaSupply * 10000) / xOrcaSupply;

    (uint256 amount, ) = podLeader.userInfo(pid, user);
    uint256 userBalance = (ratio * amount) / 10000;
    return userBalance;
  }

  function stakingPoolVote(uint256 pid, address user)
    public
    view
    returns (uint256)
  {
    (uint256 amount, ) = staking.userInfo(pid, user);
    return amount;
  }

  function podLeaderVote(uint256 pid, address user)
    public
    view
    returns (uint256)
  {
    (IERC20 token, , , , , ) = podLeader.poolInfo(pid);
    (uint256 amount, ) = podLeader.userInfo(pid, user);

    IPair pool = IPair(address(token));
    address token0 = pool.token0();
    uint256 totalSupply = pool.totalSupply();
    uint256 decimals = pool.decimals();

    (uint256 reserves0, uint256 reserves1, ) = pool.getReserves();
    require(totalSupply > 0, 'Cannot divide by zero');
    if (address(orca) == token0) {
      uint256 tokensPerLP = (reserves0 * 10**decimals) / totalSupply;
      uint256 tokenCount = (amount * tokensPerLP) / (10**decimals);
      return tokenCount;
    } else {
      uint256 tokensPerLP = (reserves1 * 10**decimals) / totalSupply;
      uint256 tokenCount = (amount * tokensPerLP) / (10**decimals);
      return tokenCount;
    }
  }
}