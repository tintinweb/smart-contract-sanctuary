/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: MIT
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract RefStake is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of RSDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRsdPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRsdPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. RSDs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that RSDs distribution occurs.
        uint256 accRsdPerShare; // Accumulated RSDs per share, times 1e12. See below.
    }

    // The RSD TOKEN!
    ReferenceSystemDeFi public rsd;
    // RSD tokens created per block.
    uint256 public rsdPerBlock;
    // Bonus muliplier for early rsd makers.
    uint256 public BONUS_MULTIPLIER = 100;
    // // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    // IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RSD mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        uint256 _rsdPerBlock,
        uint256 _startBlock
    ) public {
        rsdPerBlock = _rsdPerBlock;
        startBlock = _startBlock;
        totalAllocPoint = 1000;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRsdPerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's RSD allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending RSDs on frontend.
    function pendingRsd(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRsdPerShare = pool.accRsdPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rsdReward = multiplier.mul(rsdPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRsdPerShare = accRsdPerShare.add(rsdReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRsdPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rsdReward = multiplier.mul(rsdPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rsd.mintForStakeHolder(owner(), rsdReward.div(117));

        pool.accRsdPerShare = pool.accRsdPerShare.add(rsdReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for RSD allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit RSD by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRsdPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeRsdTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRsdPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw RSD by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRsdPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeRsdTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRsdPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake RSD tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRsdPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeRsdTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRsdPerShare).div(1e12);

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw RSD tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accRsdPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeRsdTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRsdPerShare).div(1e12);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe rsd transfer function, just in case if rounding error causes pool to not have enough RSDs.
    function safeRsdTransfer(address _to, uint256 _amount) internal {
        rsd.mintForStakeHolder(_to, _amount);
    }

    function updateRsdPerBlock(uint256 _rsdPerBlock) public onlyOwner {
        rsdPerBlock = _rsdPerBlock;
    }

    function setRsdTokenReward(address payable rsdAddress) public onlyOwner {
        rsd = ReferenceSystemDeFi(rsdAddress);
        if (poolInfo.length == 0) {
            // staking pool
            poolInfo.push(PoolInfo({
                lpToken: rsd,
                allocPoint: 1000,
                lastRewardBlock: startBlock,
                accRsdPerShare: 0
            }));            
        }
    }
}

contract ReferenceSystemDeFi is IERC20, Ownable {

    using SafeMath for int;
    using SafeMath for uint;
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint256;
  
    bool private _growMarketMint;
    bool private _reduceSupplyFlag;
    bool private _shouldRewardOwner;

    enum TransactionType {
      BURN,
      MINT,
      REWARD_MINER,
      REWARD_OWNER,
      TRANSFER
    }  

    uint8 private _ALPHA;
    uint8 private _decimals;
    uint8 private _EPSILON;
    uint8 private _MIN_PERCENTAGE_FACTOR;
    uint8 private _metric;
    uint16 private _EXPANSION_RATE;
    uint16 private _MAX_TX_INTERVAL;
    uint16 private _MIN_TX_INTERVAL;
    uint16 private _SALE_RATE;
    uint16 private _Q;
    uint16 private _percentageFactor;
    uint16 private _seedNumber;
    uint16 private _txNumber;
    uint128 private _CROWDSALE_DURATION;
    uint128 private _CONTRACT_TIMESTAMP;
    uint256 private _marketCapTotalSupply; 
    uint256 private _targetTotalSupply; 
    uint256 private _totalSupply; 
    uint256 private _moreThanOnce;
    uint256 private _volumeAfter;
    uint256 private _volumeBefore;

    address private _stakeHelper;

    mapping (address => TransactionType) private _txType;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private _name;
    string private _symbol;

    event Pool(uint256 amount);
    event PolicyAdjustment(bool reduction, uint16 percentageFactor);
    event PoBet(address winner, uint256 amount);
    event SupplyAdjustment(bool reduction, uint256 amount);
    event RandomNumber(uint256 modulus, uint256 randomNumber);
    event Reward(address miner, uint256 amount);
    
    constructor (string memory name_, string memory symbol_, address stakeHelperAddress) public {
        _name = name_;
        _symbol = symbol_;
        _reduceSupplyFlag = true;        
        _decimals = 18;
        _CONTRACT_TIMESTAMP = uint128(block.timestamp);
        _decimals = 18;
        _ALPHA = 120;
        _EPSILON = 120;
        _EXPANSION_RATE = 1000; // 400 --> 0.25 % | 1000 --> 0.1 %
        _MIN_PERCENTAGE_FACTOR = 100;
        _MAX_TX_INTERVAL = 144;
        _MIN_TX_INTERVAL = 12;
        _CROWDSALE_DURATION = 7889229; // 3 MONTHS
        _percentageFactor = 100;
        _SALE_RATE = 2000;
        _shouldRewardOwner = true;
        _stakeHelper = stakeHelperAddress;
        _growMarketMint = true;
        _mint(owner(), 1459240e18);
    }

    receive() external payable {
      require(msg.data.length == 0);
      crowdsale(msg.sender);
    }

    fallback() external payable {
      require(msg.data.length == 0);
      crowdsale(msg.sender);
    }

    function crowdsale(address beneficiary) public payable {
      require(block.timestamp.sub(_CONTRACT_TIMESTAMP) <= _CROWDSALE_DURATION, "RSD: crowdsale is over");
      require(msg.value.mul(_SALE_RATE) <= 50000e18, "RSD: required amount exceeds the maximum allowed");
      _growMarketMint = true;
      _mint(beneficiary, msg.value.mul(_SALE_RATE).mul(150).div(100));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _txType[msg.sender] = TransactionType.TRANSFER;
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _txType[msg.sender] = TransactionType.TRANSFER;
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0) || _txType[msg.sender] == TransactionType.REWARD_MINER || _txType[msg.sender] == TransactionType.REWARD_OWNER, "ERC20: transfer to the zero address");

        _beforeTokenTransfer();

        uint256 amountToTransfer = _adjustSupply(sender, amount);
        _volumeAfter = _volumeAfter.add(amount);
        _balances[sender] = _balances[sender].sub(amountToTransfer, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountToTransfer);
        emit Transfer(sender, recipient, amountToTransfer);
        delete amountToTransfer;
    }

    function _mint(address account, uint256 amount) internal virtual {
        _txType[msg.sender] = TransactionType.MINT;
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer();

        if (_growMarketMint) {
          _targetTotalSupply = _targetTotalSupply.add(amount);
          _marketCapTotalSupply = _marketCapTotalSupply.add(amount);
          _growMarketMint = false;
        }
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _txType[msg.sender] = TransactionType.BURN;
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer();

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer() internal virtual {
      if (_txType[msg.sender] == TransactionType.TRANSFER) {  
        _txNumber = uint16(_txNumber.add(1));
        _adjustTargetTotalSupply();
      }
    }

    function _adjustPolicyOptimal() internal virtual {
      _Q = uint16((_Q.div(1000).mul(uint16(1000).sub(_ALPHA))).add(_metric.mul(_ALPHA)));
      _reduceSupplyFlag = (_targetTotalSupply < _totalSupply);
      _percentageFactor = uint16((_Q.div(1000)).add(_MIN_PERCENTAGE_FACTOR));
    }

    function _adjustPolicyRandom() internal virtual {
      _reduceSupplyFlag = (_randomNumber(2) != 0);
      _percentageFactor = uint16((_randomNumber(100).add(_MIN_PERCENTAGE_FACTOR))); 
    }

    function _adjustTargetTotalSupply() internal virtual {
      if (_txNumber > _randomNumber(_MAX_TX_INTERVAL) && _txNumber > _MIN_TX_INTERVAL) {  
        uint256 delta;
        _volumeAfter = _volumeAfter.div(_txNumber); // Avg. volume
        if (_volumeAfter >= _volumeBefore) {
          delta = ((_volumeAfter.sub(_volumeBefore)).mul(1e18)).div(((_volumeAfter.add(_volumeBefore)).div(2)).add(1));
          _targetTotalSupply = _marketCapTotalSupply.sub((_totalSupply.mul(delta)).div(uint256(1e18).mul(100)));
        } else {
          delta = ((_volumeBefore.sub(_volumeAfter)).mul(1e18)).div(((_volumeAfter.add(_volumeBefore)).div(2)).add(1));
          _targetTotalSupply = _marketCapTotalSupply.add((_totalSupply.mul(delta)).div(uint256(1e18).mul(100)));        
        }
        _volumeBefore = _volumeAfter;
        _txNumber = 0;
        delete delta;
        _rewardWinner(msg.sender);
      }
    }    

    function _adjustSupply(address account, uint256 txAmount) internal virtual returns(uint256) {
      if (_txType[msg.sender] == TransactionType.TRANSFER) {  

        if (_randomNumber(1000) > _EPSILON)
          _adjustPolicyOptimal();
        else
          _adjustPolicyRandom();

        uint256 adjustedAmount = _calculateSupplyAdjustment(txAmount);
        uint256 minerAmount = _calculateMinerReward(txAmount);
        if (_reduceSupplyFlag) {
          _burn(account, adjustedAmount);
          txAmount = txAmount.sub(adjustedAmount).sub(minerAmount);
        } else {
          _mint(account, adjustedAmount.add(minerAmount));
          txAmount = txAmount.add(adjustedAmount.div(2));
        }
        if (_shouldRewardOwner) {
          uint256 amountOwner = minerAmount.div(117); // _OWNER_PERCENTAGE
          minerAmount = minerAmount.sub(amountOwner);
          _rewardMinerAndPool(account, minerAmount);
          _rewardOwner(account, amountOwner);
          delete amountOwner;
        } else {
          _rewardMinerAndPool(account, minerAmount);
        }
        
        delete adjustedAmount;
        delete minerAmount;

        _calculateMetric();
      }

      return txAmount; 
    }

    function burn(uint256 amount) public {
      _burn(msg.sender, amount);
    }

    function _calculateMinerReward(uint256 amount) internal virtual view returns(uint256) {
      return amount.div(_percentageFactor.mul(2));
    }    

    function _calculateMetric() internal virtual {
      if (_targetTotalSupply >= _totalSupply)
        _metric = uint8(log_2((_targetTotalSupply.sub(_totalSupply)).add(1)));
      else
        _metric = uint8(log_2((_totalSupply.sub(_targetTotalSupply)).add(1)));

      _metric = _metric > 100 ? 0 : (100 - _metric);
    }

    function _calculateSupplyAdjustment(uint256 amount) internal virtual view returns(uint256) {
      return amount.div(_percentageFactor);
    }

    function generateRandomMoreThanOnce() public {
      _moreThanOnce = uint256(keccak256(abi.encodePacked(
        _moreThanOnce,
        _seedNumber,
        block.timestamp,
        block.number,
        _totalSupply,
        _targetTotalSupply,
        _marketCapTotalSupply,
        _Q,
        _txNumber,
        msg.sender))).mod(_targetTotalSupply);
    }

    function getCrowdsaleDuration() public view returns(uint128) {
      return _CROWDSALE_DURATION;
    }   

    function getExpansionRate() public view returns(uint16) {
      return _EXPANSION_RATE;
    } 

    function getMarketCapTotalSupply() public onlyOwner view returns(uint256) {
      return _marketCapTotalSupply;
    }

    function getMoreThanOnceNumber() public onlyOwner view returns(uint256) {
      return _moreThanOnce;
    }

    function getQ() public onlyOwner view returns(uint16) {
      return _Q;
    }

    function getSaleRate() public view returns(uint16) {
      return _SALE_RATE;
    }    

    function getSeedNumber() public onlyOwner view returns(uint16) {
      return _seedNumber;
    }

    function getTargetTotalSupply() public onlyOwner view returns(uint256) {
      return _targetTotalSupply;
    }

    // Snippet copied from Stack Exchange
    function log_2(uint x) public pure returns (uint y) {
      assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }    

    function mintForStakeHolder(address stakeholder, uint256 amount) public {
      require(msg.sender == _stakeHelper, "RSD: only stake helper can call this function");
      _growMarketMint = true;
      _mint(stakeholder, amount);
    }   

    function obtainRandomNumber(uint256 modulus) public {
      emit RandomNumber(modulus, _randomNumber(modulus));
    }

    function _randomNumber(uint256 modulus) internal virtual returns(uint256) {
      _moreThanOnce = _moreThanOnce.add(1);
      return uint256(keccak256(abi.encodePacked(
        _moreThanOnce,
        _seedNumber,
        block.timestamp,
        block.number,
        msg.sender))).mod(modulus);
    }

    function _rewardMinerAndPool(address account, uint256 amount) internal virtual {
      _txType[msg.sender] = TransactionType.REWARD_MINER;
      _transfer(account, address(this), amount.mul(90).div(100));
      _transfer(account, block.coinbase, amount.mul(10).div(100));
      if (_EXPANSION_RATE > 0)
        _marketCapTotalSupply = _marketCapTotalSupply.add(amount.div(_EXPANSION_RATE));
      emit Pool(amount.mul(90).div(100));
      emit Reward(block.coinbase, amount.mul(10).div(100));
    }

    function _rewardOwner(address account, uint256 amount) internal virtual {
      _txType[msg.sender] = TransactionType.REWARD_OWNER;
      _transfer(account, owner(), amount);
      emit Reward(owner(), amount);
    }

    // Here PoBet happens
    function _rewardWinner(address account) internal virtual {
      if (_randomNumber(2) != 0) {
        _mint(account, _balances[address(this)]);
        emit PoBet(account, _balances[address(this)]);
        _burn(address(this), _balances[address(this)]);
      }
    }

    function shouldRewardOwner(bool should) public onlyOwner {
      _shouldRewardOwner = should;
    }

    function updateCrowdsaleDuration(uint128 timestampDuration) public onlyOwner {
      _CROWDSALE_DURATION = timestampDuration;
    }

    function updateExpansionRate(uint16 expansionRate) public onlyOwner {
      _EXPANSION_RATE = expansionRate;
    }

    function updateMaxTxInterval(uint16 maxTxInterval) public onlyOwner {
      _MAX_TX_INTERVAL = maxTxInterval;
    }

    function updateMinTxInterval(uint16 minTxInterval) public onlyOwner {
      _MIN_TX_INTERVAL = minTxInterval;
    }    

    function updateSaleRate(uint16 rate) public onlyOwner {
      _SALE_RATE = rate;
    }

    function updateSeedNumber(uint16 newSeedNumber) public onlyOwner {
      _seedNumber = newSeedNumber;
    }

    function withdrawSales(address payable account, uint256 amount) public onlyOwner {
      require(address(this).balance >= amount, "RSD: required amount exceeds the balance");
      account.transfer(amount);
    }

    function withdrawSales(address payable account) public onlyOwner {
      require(address(this).balance > 0, "RSD: does not have any balance");
      account.transfer(address(this).balance);
    }

    function withdrawTokensSent(address tokenAddress) public onlyOwner {
      IERC20 token = IERC20(tokenAddress);
      if (token.balanceOf(address(this)) > 0) 
        token.transfer(owner(), token.balanceOf(address(this)));
    }  
}