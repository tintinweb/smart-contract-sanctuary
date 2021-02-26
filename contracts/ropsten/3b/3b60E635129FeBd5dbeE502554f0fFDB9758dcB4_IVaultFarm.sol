/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: UNLICENSED
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function capfarm() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function mint(address sender, uint256 amount) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/IVaultFarm.sol

pragma solidity ^0.6.0;

contract IVaultFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
        uint256 lockAmount; // Lock amount reward token
        uint256 lastUnlockBlock;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IERC20 rewardToken; // Address of reward token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. reward to distribute per block.
        uint256 lastRewardBlock; // Last block number that Reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward per share, times 1e12. See below.
        uint256 rewardPerBlock; // Reward per block.
        uint256 percentLockReward; // Percent lock reward.
        uint256 percentForDev; // Percent for dev team.
        uint256 finishBonusAtBlock;
        uint256 startBlock; // Start at block.
        uint256 totalLock; // Total lock reward token on pool.
        uint256 lockFromBlock; // Lock from block.
        uint256 lockToBlock; // Lock to block.
    }

    // Dev address.
    address public _owner;
    // Dev address.
    address public devaddr;
    bool public status; // Status handle farmer can harvest.
    IERC20 public referralToken; // UBU token for check referral program

    uint256 public stakeAmountLv1; // Minimum stake UBU token condition level1 for referral program.
    uint256 public stakeAmountLv2; // Minimum stake UBU token condition level2 for referral program.

    uint256 public percentForReferLv1; // Percent reward level1 referral program.
    uint256 public percentForReferLv2; // Percent reward level2 referral program.

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => address) public referrers;
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(uint256 => uint256[]) public rewardMultipliers;
    mapping(uint256 => uint256[]) public halvingAtBlocks;

    // Total allocation points. Must be the sum of all allocation points in all pools same reward token.
    mapping(IERC20 => uint256) public totalAllocPoints;
    // Total locks. Must be the sum of all token locks in all pools same reward token.
    mapping(IERC20 => uint256) public totalLocks;
    mapping(address => mapping(address => uint256)) public referralAmountLv1;
    mapping(address => mapping(address => uint256)) public referralAmountLv2;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SendReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 lockAmount
    );
    event Lock(address indexed to, uint256 value);
    event Status(address indexed user, bool status);
    event SetReferralToken(address indexed user, IERC20 referralToken);
    event SendReferralReward(
        address indexed user,
        address indexed referrer,
        uint256 indexed pid,
        uint256 amount,
        uint256 lockAmount
    );
    event AmountStakeLevelRefer(
        address indexed user,
        uint256 indexed stakeAmountLv1,
        uint256 indexed stakeAmountLv2
    );

    bool public initialized = false;

    function initialize(IERC20 _referralToken) public {
        require(!initialized, "has initialized");
        devaddr = msg.sender;
        _owner = msg.sender;
        stakeAmountLv1 = 100 * 10**18;
        stakeAmountLv2 = 1000 * 10**18;
        percentForReferLv1 = 7;
        percentForReferLv2 = 3;
        referralToken = _referralToken;
        status = true;
        initialized = true;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        IERC20 _lpToken,
        IERC20 _rewardToken,
        uint256 _startBlock,
        uint256 _allocPoint,
        uint256 _rewardPerBlock,
        uint256 _percentLockReward,
        uint256 _percentForDev,
        uint256 _halvingAfterBlock,
        uint256[] memory _rewardMultiplier,
        uint256 _lockFromBlock,
        uint256 _lockToBlock
    ) public onlyOwner {
        _setAllocPoints(_rewardToken, _allocPoint);
        uint256 finishBonusAtBlock =
            _setHalvingAtBlocks(
                poolInfo.length,
                _rewardMultiplier,
                _halvingAfterBlock,
                _startBlock
            );

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardToken: _rewardToken,
                lastRewardBlock: block.number > _startBlock
                    ? block.number
                    : _startBlock,
                allocPoint: _allocPoint,
                accRewardPerShare: 0,
                startBlock: _startBlock,
                rewardPerBlock: _rewardPerBlock,
                percentLockReward: _percentLockReward,
                percentForDev: _percentForDev,
                finishBonusAtBlock: finishBonusAtBlock,
                totalLock: 0,
                lockFromBlock: _lockFromBlock,
                lockToBlock: _lockToBlock
            })
        );
    }

    function _setAllocPoints(IERC20 _rewardToken, uint256 _allocPoint)
        internal
        onlyOwner
    {
        totalAllocPoints[_rewardToken] = totalAllocPoints[_rewardToken].add(
            _allocPoint
        );
    }

    function _setHalvingAtBlocks(
        uint256 _pid,
        uint256[] memory _rewardMultiplier,
        uint256 _halvingAfterBlock,
        uint256 _startBlock
    ) internal onlyOwner returns (uint256) {
        rewardMultipliers[_pid] = _rewardMultiplier;
        for (uint256 i = 0; i < _rewardMultiplier.length - 1; i++) {
            uint256 halvingAtBlock =
                _halvingAfterBlock.mul(i + 1).add(_startBlock);
            halvingAtBlocks[_pid].push(halvingAtBlock);
        }
        uint256 finishBonusAtBlock =
            _halvingAfterBlock.mul(_rewardMultiplier.length - 1).add(
                _startBlock
            );
        halvingAtBlocks[_pid].push(uint256(-1));
        return finishBonusAtBlock;
    }

    function setStatus(bool _status) public onlyOwner {
        status = _status;
        emit Status(msg.sender, status);
    }

    function setreferralToken(IERC20 _referralToken) public onlyOwner {
        referralToken = _referralToken;
        emit SetReferralToken(msg.sender, referralToken);
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfo[_pid];

        totalAllocPoints[pool.rewardToken] = totalAllocPoints[pool.rewardToken]
            .sub(pool.allocPoint)
            .add(_allocPoint);
        pool.allocPoint = _allocPoint;
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

        uint256 forDev;
        uint256 forFarmer;
        (forDev, forFarmer) = getPoolReward(_pid);

        if (forDev > 0) {
            uint256 lockAmount = forDev.mul(pool.percentLockReward).div(100);
            if (devaddr != address(0)) {
                pool.rewardToken.mint(devaddr, forDev.sub(lockAmount));
                farmLock(devaddr, lockAmount, _pid);
            }
        }
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            forFarmer.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256[] memory _halvingAtBlock,
        uint256[] memory _rewardMultiplier,
        uint256 _startBlock
    ) public pure returns (uint256) {
        uint256 result = 0;
        if (_from < _startBlock) return 0;

        for (uint256 i = 0; i < _halvingAtBlock.length; i++) {
            uint256 endBlock = _halvingAtBlock[i];

            if (_to <= endBlock) {
                uint256 m = _to.sub(_from).mul(_rewardMultiplier[i]);
                return result.add(m);
            }

            if (_from < endBlock) {
                uint256 m = endBlock.sub(_from).mul(_rewardMultiplier[i]);
                _from = endBlock;
                result = result.add(m);
            }
        }

        return result;
    }

    function getPoolReward(uint256 _pid)
        public
        view
        returns (uint256 forDev, uint256 forFarmer)
    {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 multiplier =
            getMultiplier(
                pool.lastRewardBlock,
                block.number,
                halvingAtBlocks[_pid],
                rewardMultipliers[_pid],
                pool.startBlock
            );
        uint256 amount =
            multiplier.mul(pool.rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoints[pool.rewardToken]
            );
        uint256 rewardCanAlloc =
            pool.rewardToken.capfarm().sub(totalLocks[pool.rewardToken]);

        if (rewardCanAlloc < amount) {
            forDev = 0;
            forFarmer = rewardCanAlloc;
        } else {
            forDev = amount.mul(pool.percentForDev).div(100);
            forFarmer = amount.sub(forDev);
        }
    }

    // View function to see pending reward on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            uint256 forFarmer;
            (, forFarmer) = getPoolReward(_pid);
            accRewardPerShare = accRewardPerShare.add(
                forFarmer.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function claimReward(uint256 _pid) public {
        require(status == true, "UFarmer::withdraw: can not claim reward");
        updatePool(_pid);
        _harvest(_pid);
    }

    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 masterBal =
                pool.rewardToken.capfarm().sub(totalLocks[pool.rewardToken]);

            if (pending > masterBal) {
                pending = masterBal;
            }

            if (pending > 0) {
                uint256 referAmountLv1 =
                    pending.mul(percentForReferLv1).div(100);
                uint256 referAmountLv2 =
                    pending.mul(percentForReferLv2).div(100);
                _transferReferral(_pid, referAmountLv1, referAmountLv2);

                uint256 amount =
                    pending.sub(referAmountLv1).sub(referAmountLv2);
                uint256 lockAmount =
                    amount.mul(pool.percentLockReward).div(100);
                pool.rewardToken.mint(msg.sender, amount.sub(lockAmount));
                farmLock(msg.sender, lockAmount, _pid);
                user.rewardDebtAtBlock = block.number;

                emit SendReward(msg.sender, _pid, amount, lockAmount);
            }

            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }
    }

    function _transferReferral(
        uint256 _pid,
        uint256 _referAmountLv1,
        uint256 _referAmountLv2
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address referrerLv1 = referrers[address(msg.sender)];
        uint256 referAmountForDev = 0;

        if (referrerLv1 != address(0)) {
            uint256 lpStaked = referralToken.balanceOf(referrerLv1);
            if (lpStaked >= stakeAmountLv1) {
                uint256 lockAmount =
                    _referAmountLv1.mul(pool.percentLockReward).div(100);
                pool.rewardToken.mint(
                    referrerLv1,
                    _referAmountLv1.sub(lockAmount)
                );
                farmLock(referrerLv1, lockAmount, _pid);

                referralAmountLv1[address(pool.rewardToken)][
                    address(referrerLv1)
                ] = referralAmountLv1[address(pool.rewardToken)][
                    address(referrerLv1)
                ]
                    .add(_referAmountLv1);
                emit SendReferralReward(
                    referrerLv1,
                    msg.sender,
                    _pid,
                    _referAmountLv1,
                    lockAmount
                );
            } else {
                // dev team will receive reward of referrer level 1
                referAmountForDev = referAmountForDev.add(_referAmountLv1);
            }

            address referrerLv2 = referrers[referrerLv1];
            uint256 lpStaked2 = referralToken.balanceOf(referrerLv2);
            if (referrerLv2 != address(0) && lpStaked2 >= stakeAmountLv2) {
                uint256 lockAmount =
                    _referAmountLv2.mul(pool.percentLockReward).div(100);
                pool.rewardToken.mint(
                    referrerLv2,
                    _referAmountLv2.sub(lockAmount)
                );
                farmLock(referrerLv2, lockAmount, _pid);

                referralAmountLv2[address(pool.rewardToken)][
                    address(referrerLv2)
                ] = referralAmountLv2[address(pool.rewardToken)][
                    address(referrerLv2)
                ]
                    .add(_referAmountLv2);
                emit SendReferralReward(
                    referrerLv2,
                    msg.sender,
                    _pid,
                    _referAmountLv2,
                    lockAmount
                );
            } else {
                // dev team will receive reward of referrer level 2
                referAmountForDev = referAmountForDev.add(_referAmountLv2);
            }
        } else {
            referAmountForDev = _referAmountLv1.add(_referAmountLv2);
        }

        if (referAmountForDev > 0) {
            uint256 lockAmount =
                referAmountForDev.mul(pool.percentLockReward).div(100);
            pool.rewardToken.mint(devaddr, referAmountForDev.sub(lockAmount));
            farmLock(devaddr, lockAmount, _pid);
        }
    }

    function setAmountLPStakeLevelRefer(
        uint256 _stakeAmountLv1,
        uint256 _stakeAmountLv2
    ) public onlyOwner {
        stakeAmountLv1 = _stakeAmountLv1;
        stakeAmountLv2 = _stakeAmountLv2;
        emit AmountStakeLevelRefer(msg.sender, stakeAmountLv1, stakeAmountLv2);
    }

    // Deposit LP tokens to UFarmer.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public {
        require(_amount > 0, "UFarmer::deposit: amount must be greater than 0");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _harvest(_pid);
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);

        if (
            referrers[address(msg.sender)] == address(0) &&
            _referrer != address(0) &&
            _referrer != address(msg.sender)
        ) {
            referrers[address(msg.sender)] = address(_referrer);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from UFarmer.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(status == true, "UFarmer::withdraw: can not withdraw");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "UFarmer::withdraw: not good");

        updatePool(_pid);
        _harvest(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from UFarmer.
    function withdrawAll(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid);
        emergencyWithdraw(_pid);
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

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function getNewRewardPerBlock(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 multiplier =
            getMultiplier(
                block.number - 1,
                block.number,
                halvingAtBlocks[_pid],
                rewardMultipliers[_pid],
                pool.startBlock
            );

        return
            multiplier.mul(pool.rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoints[pool.rewardToken]
            );
    }

    function totalLockInPool(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].totalLock;
    }

    function totalLock(IERC20 _rewardToken) public view returns (uint256) {
        return totalLocks[_rewardToken];
    }

    function lockOf(address _holder, uint256 _pid)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_holder].lockAmount;
    }

    function lastUnlockBlock(address _holder, uint256 _pid)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_holder].lastUnlockBlock;
    }

    function farmLock(
        address _holder,
        uint256 _amount,
        uint256 _pid
    ) internal {
        require(_holder != address(0), "ERC20: lock to the zero address");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_holder];

        require(
            _amount <=
                pool.rewardToken.capfarm().sub(totalLocks[pool.rewardToken]),
            "ERC20: lock amount over allowed"
        );
        user.lockAmount = user.lockAmount.add(_amount);
        pool.totalLock = pool.totalLock.add(_amount);
        totalLocks[pool.rewardToken] = totalLocks[pool.rewardToken].add(
            _amount
        );

        if (user.lastUnlockBlock < pool.lockFromBlock) {
            user.lastUnlockBlock = pool.lockFromBlock;
        }
        emit Lock(_holder, _amount);
    }

    function canUnlockAmount(address _holder, uint256 _pid)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_holder];

        if (block.number < pool.lockFromBlock) {
            return 0;
        } else if (block.number >= pool.lockToBlock) {
            return user.lockAmount;
        } else {
            uint256 releaseBlock = block.number.sub(user.lastUnlockBlock);
            uint256 numberLockBlock =
                pool.lockToBlock.sub(user.lastUnlockBlock);
            return user.lockAmount.mul(releaseBlock).div(numberLockBlock);
        }
    }

    function unlock(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockAmount > 0, "ERC20: cannot unlock");

        uint256 amount = canUnlockAmount(msg.sender, _pid);
        uint256 masterBL = pool.rewardToken.capfarm();

        if (amount > masterBL) {
            amount = masterBL;
        }

        pool.rewardToken.mint(msg.sender, amount);
        user.lockAmount = user.lockAmount.sub(amount);
        user.lastUnlockBlock = block.number;
        pool.totalLock = pool.totalLock.sub(amount);
        totalLocks[pool.rewardToken] = totalLocks[pool.rewardToken].sub(amount);
    }
}