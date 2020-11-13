// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


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

// 
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

// 
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

// 
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

// 
contract HoneycombV3 is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount;     // How many staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt.
    uint256 mined;
    uint256 collected;
  }

  struct CollectingInfo {
    uint256 collectableTime;
    uint256 amount;
    bool collected;
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 stakingToken;           // Address of staking token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool.
    uint256 lastRewardBlock;  // Last block number that HONEYs distribution occurs.
    uint256 accHoneyPerShare; // Accumulated HONEYs per share, times 1e12.
    uint256 totalShares;
  }

  struct BatchInfo {
    uint256 startBlock;
    uint256 endBlock;
    uint256 honeyPerBlock;
    uint256 totalAllocPoint;
  }

  // Info of each batch
  BatchInfo[] public batchInfo;
  // Info of each pool at specified batch.
  mapping (uint256 => PoolInfo[]) public poolInfo;
  // Info of each user at specified batch and pool
  mapping (uint256 => mapping (uint256 => mapping (address => UserInfo))) public userInfo;
  mapping (uint256 => mapping (uint256 => mapping (address => CollectingInfo[]))) public collectingInfo;

  IERC20 public honeyToken;
  uint256 public collectingDuration = 86400 * 3;
  uint256 public instantCollectBurnRate = 4000; // 40%
  address public burnDestination;

  event Deposit(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);

  constructor (address _honeyToken, address _burnDestination) public {
    honeyToken = IERC20(_honeyToken);
    burnDestination = _burnDestination;
  }

  function addBatch(uint256 startBlock, uint256 endBlock, uint256 honeyPerBlock) public onlyOwner {
    require(endBlock > startBlock, "endBlock should be larger than startBlock");
    require(endBlock > block.number, "endBlock should be larger than the current block number");
    require(startBlock > block.number, "startBlock should be larger than the current block number");
    
    if (batchInfo.length > 0) {
      uint256 lastEndBlock = batchInfo[batchInfo.length - 1].endBlock;
      require(startBlock >= lastEndBlock, "startBlock should be >= the endBlock of the last batch");
    }

    uint256 senderHoneyBalance = honeyToken.balanceOf(address(msg.sender));
    uint256 requiredHoney = endBlock.sub(startBlock).mul(honeyPerBlock);
    require(senderHoneyBalance >= requiredHoney, "insufficient HONEY for the batch");

    honeyToken.safeTransferFrom(address(msg.sender), address(this), requiredHoney);
    batchInfo.push(BatchInfo({
      startBlock: startBlock,
      endBlock: endBlock,
      honeyPerBlock: honeyPerBlock,
      totalAllocPoint: 0
    }));
  }

  function addPool(uint256 batch, IERC20 stakingToken, uint256 multiplier) public onlyOwner {
    require(batch < batchInfo.length, "batch must exist");
    
    BatchInfo storage targetBatch = batchInfo[batch];
    if (targetBatch.startBlock <= block.number && block.number < targetBatch.endBlock) {
      updateAllPools(batch);
    }

    uint256 lastRewardBlock = block.number > targetBatch.startBlock ? block.number : targetBatch.startBlock;
    batchInfo[batch].totalAllocPoint = targetBatch.totalAllocPoint.add(multiplier);
    poolInfo[batch].push(PoolInfo({
      stakingToken: stakingToken,
      allocPoint: multiplier,
      lastRewardBlock: lastRewardBlock,
      accHoneyPerShare: 0,
      totalShares: 0
    }));
  }

  // Return rewardable block count over the given _from to _to block.
  function getPendingBlocks(uint256 batch, uint256 from, uint256 to) public view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");   
 
    BatchInfo storage targetBatch = batchInfo[batch];

    if (to < targetBatch.startBlock) {
      return 0;
    }
    
    if (to > targetBatch.endBlock) {
      if (from > targetBatch.endBlock) {
        return 0;
      } else {
        return targetBatch.endBlock.sub(from);
      }
    } else {
      return to.sub(from);
    }
  }

  // View function to see pending HONEYs on frontend.
  function minedHoney(uint256 batch, uint256 pid, address account) external view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");   
    require(pid < poolInfo[batch].length, "pool must exist");
    BatchInfo storage targetBatch = batchInfo[batch];

    if (block.number < targetBatch.startBlock) {
      return 0;
    }

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][account];
    uint256 accHoneyPerShare = pool.accHoneyPerShare;
    if (block.number > pool.lastRewardBlock && pool.totalShares != 0) {
      uint256 pendingBlocks = getPendingBlocks(batch, pool.lastRewardBlock, block.number);
      uint256 honeyReward = pendingBlocks.mul(targetBatch.honeyPerBlock).mul(pool.allocPoint).div(targetBatch.totalAllocPoint);
      accHoneyPerShare = accHoneyPerShare.add(honeyReward.mul(1e12).div(pool.totalShares));
    }
    return user.amount.mul(accHoneyPerShare).div(1e12).sub(user.rewardDebt).add(user.mined);
  }

  function updateAllPools(uint256 batch) public {
    require(batch < batchInfo.length, "batch must exist");

    uint256 length = poolInfo[batch].length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(batch, pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 batch, uint256 pid) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    BatchInfo storage targetBatch = batchInfo[batch];
    PoolInfo storage pool = poolInfo[batch][pid];

    if (block.number < targetBatch.startBlock || block.number <= pool.lastRewardBlock || pool.lastRewardBlock > targetBatch.endBlock) {
      return;
    }
    if (pool.totalShares == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 pendingBlocks = getPendingBlocks(batch, pool.lastRewardBlock, block.number);
    uint256 honeyReward = pendingBlocks.mul(targetBatch.honeyPerBlock).mul(pool.allocPoint).div(targetBatch.totalAllocPoint);
    pool.accHoneyPerShare = pool.accHoneyPerShare.add(honeyReward.mul(1e12).div(pool.totalShares));
    pool.lastRewardBlock = block.number;
  }

  // Deposit staking tokens for HONEY allocation.
  function deposit(uint256 batch, uint256 pid, uint256 amount) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    BatchInfo storage targetBatch = batchInfo[batch];

    require(block.number < targetBatch.endBlock, "batch ended");

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][msg.sender];

    // 1. Update pool.accHoneyPerShare
    updatePool(batch, pid);

    // 2. Transfer pending HONEY to user
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accHoneyPerShare).div(1e12).sub(user.rewardDebt);
      if (pending > 0) {
        addToMined(batch, pid, msg.sender, pending);
      }
    }

    // 3. Transfer Staking Token from user to honeycomb
    if (amount > 0) {
      pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), amount);
      user.amount = user.amount.add(amount);
    }

    // 4. Update user.rewardDebt
    pool.totalShares = pool.totalShares.add(amount);
    user.rewardDebt = user.amount.mul(pool.accHoneyPerShare).div(1e12);
    emit Deposit(msg.sender, batch, pid, amount);
  }

  // Withdraw staking tokens.
  function withdraw(uint256 batch, uint256 pid, uint256 amount) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    require(user.amount >= amount, "insufficient balance");

    // 1. Update pool.accHoneyPerShare
    updatePool(batch, pid);

    // 2. Transfer pending HONEY to user
    PoolInfo storage pool = poolInfo[batch][pid];
    uint256 pending = user.amount.mul(pool.accHoneyPerShare).div(1e12).sub(user.rewardDebt);
    if (pending > 0) {
      addToMined(batch, pid, msg.sender, pending);
    }

    // 3. Transfer Staking Token from honeycomb to user
    pool.stakingToken.safeTransfer(address(msg.sender), amount);
    user.amount = user.amount.sub(amount);

    // 4. Update user.rewardDebt
    pool.totalShares = pool.totalShares.sub(amount);
    user.rewardDebt = user.amount.mul(pool.accHoneyPerShare).div(1e12);
    emit Withdraw(msg.sender, batch, pid, amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 batch, uint256 pid) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    pool.stakingToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, batch, pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  function migrate(uint256 toBatch, uint256 toPid, uint256 amount, uint256 fromBatch, uint256 fromPid) public {
    require(toBatch < batchInfo.length, "target batch must exist");
    require(toPid < poolInfo[toBatch].length, "target pool must exist");
    require(fromBatch < batchInfo.length, "source batch must exist");
    require(fromPid < poolInfo[fromBatch].length, "source pool must exist");

    BatchInfo storage targetBatch = batchInfo[toBatch];
    require(block.number < targetBatch.endBlock, "batch ended");

    UserInfo storage userFrom = userInfo[fromBatch][fromPid][msg.sender];
    if (userFrom.amount > 0) {
      PoolInfo storage poolFrom = poolInfo[fromBatch][fromPid];
      PoolInfo storage poolTo = poolInfo[toBatch][toPid];
      require(address(poolFrom.stakingToken) == address(poolTo.stakingToken), "must be the same token");
      withdraw(fromBatch, fromPid, amount);
      deposit(toBatch, toPid, amount);
    }
  }

  // Safe honey transfer function, just in case if rounding error causes pool to not have enough HONEYs.
  function safeHoneyTransfer(uint256 batch, uint256 pid, address to, uint256 amount) internal {
    uint256 honeyBal = honeyToken.balanceOf(address(this));
    require(honeyBal > 0, "insufficient HONEY balance");

    UserInfo storage user = userInfo[batch][pid][to];
    if (amount > honeyBal) {
      honeyToken.transfer(to, honeyBal);
      user.collected = user.collected.add(honeyBal);
    } else {
      honeyToken.transfer(to, amount);
      user.collected = user.collected.add(amount);
    }
  }

  function addToMined(uint256 batch, uint256 pid, address account, uint256 amount) internal {
    UserInfo storage user = userInfo[batch][pid][account];
    user.mined = user.mined.add(amount);
  }

  function startCollecting(uint256 batch, uint256 pid) external {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    withdraw(batch, pid, 0);
    
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    CollectingInfo[] storage collecting = collectingInfo[batch][pid][msg.sender];

    if (user.mined > 0) {
      collecting.push(CollectingInfo({
        collectableTime: block.timestamp + collectingDuration,
        amount: user.mined,
        collected: false
      }));
      user.mined = 0;
    }
  }

  function collectingHoney(uint256 batch, uint256 pid, address account) external view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    CollectingInfo[] storage collecting = collectingInfo[batch][pid][account];
    uint256 total = 0;
    for (uint i = 0; i < collecting.length; ++i) {
      if (!collecting[i].collected && block.timestamp < collecting[i].collectableTime) {
        total = total.add(collecting[i].amount);
      }
    }
    return total;
  }

  function collectableHoney(uint256 batch, uint256 pid, address account) external view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    CollectingInfo[] storage collecting = collectingInfo[batch][pid][account];
    uint256 total = 0;
    for (uint i = 0; i < collecting.length; ++i) {
      if (!collecting[i].collected && block.timestamp >= collecting[i].collectableTime) {
        total = total.add(collecting[i].amount);
      }
    }
    return total;
  }

  function collectHoney(uint256 batch, uint256 pid) external {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    CollectingInfo[] storage collecting = collectingInfo[batch][pid][msg.sender];
    require(collecting.length > 0, "nothing to collect");

    uint256 total = 0;
    for (uint i = 0; i < collecting.length; ++i) {
      if (!collecting[i].collected && block.timestamp >= collecting[i].collectableTime) {
        total = total.add(collecting[i].amount);
        collecting[i].collected = true;
      }
    }

    safeHoneyTransfer(batch, pid, msg.sender, total);
  }

  function instantCollectHoney(uint256 batch, uint256 pid) external {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    withdraw(batch, pid, 0);
    
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    if (user.mined > 0) {
      uint256 portion = 10000 - instantCollectBurnRate;
      safeHoneyTransfer(batch, pid, msg.sender, user.mined.mul(portion).div(10000));
      honeyToken.transfer(burnDestination, user.mined.mul(instantCollectBurnRate).div(10000));
      user.mined = 0;
    }
  }

  function setInstantCollectBurnRate(uint256 value) public onlyOwner {
    require(value <= 10000, "Value range: 0 ~ 10000");
    instantCollectBurnRate = value;
  }

  function setCollectingDuration(uint256 value) public onlyOwner {
    collectingDuration = value;
  }
}