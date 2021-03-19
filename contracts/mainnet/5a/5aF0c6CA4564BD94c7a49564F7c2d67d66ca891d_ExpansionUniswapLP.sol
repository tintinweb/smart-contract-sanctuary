// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "../interfaces/ILootCitadel.sol";
import "../interfaces/IUniswapV2PairMinimal.sol";

contract ExpansionUniswapLP is Ownable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /***********************************|
    |   Constants                       |
    |__________________________________*/

    ILootCitadel public citadel;
    uint256 public lootPerBlock;
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;

    /**
     * @notice UserInfo
     * @dev Track account deposits and rewards
     */
    struct UserInfo {
        uint256 amount; // Deposited Tokens
        uint256 rewardDebt; // User Reward Debt
    }

    /**
     * @notice PoolInfo
     * @dev Manage the liquidity pool configuration
     */
    struct PoolInfo {
        IERC20 lpToken; // LP Token Address.
        uint256 allocPoint; // Assigned Allocation Pounts
        uint256 lastRewardBlock; // Last Calculated Reward Block
        uint256 accLootPerShare; // Accumulated LOOT Per Shares
    }

    PoolInfo[] public poolInfo;
    uint256 public totalAllocPoint = 0;

    // User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Liquidity Pools
    mapping(address => bool) public poolExists;

    /****************************************|
    |                  Events                |
    |_______________________________________*/
    /**
     * @notice PoolAdded
     * @dev Event fires when a new pool is added
     */
    event PoolAdded(uint256 pid, address token, uint256 points);

    /**
     * @notice PoolAdded
     * @dev Event fires when a user deposits a Uniswap LP tokens
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice PoolAdded
     * @dev Event fires when a user withdraw Uniswap LP tokens
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice EmergencyWithdraw
     * @dev Event fires when a user executes an emergency withdrawl
     */
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
     * @notice RewardClaimed
     * @dev Event fires when a user claims rewards
     */
    event RewardClaimed(address user, uint256 amount);

    /***********************************|
    |     		 Constructor            |
    |__________________________________*/
    constructor(
        address _citadel,
        uint256 _lootPerBlock,
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock
    ) public {
        citadel = ILootCitadel(_citadel);
        lootPerBlock = _lootPerBlock;
        rewardStartBlock = _rewardStartBlock;
        rewardEndBlock = _rewardEndBlock;
    }

    /***********************************|
    |               Reads               |
    |__________________________________*/

    /**
     * @notice Counts the number of pools
     * @dev Gets the poolInfo length to calculate number of staking pools
     */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /***********************************|
    |               Writes              |
    |__________________________________*/

    /**
     * @notice Add LP Token Pool
     * @dev Add a new staking pool for Uniswap LP token to reward LOOT.
     * @param _allocPoint Points allocated
     * @param _lpToken Liquidity Provider token
     * @return true
     */
    function add(uint256 _allocPoint, address _lpToken)
        external
        onlyOwner
        returns (bool)
    {
        // Check if Pool Exists
        require(poolExists[_lpToken] != true, "Pool Exists");
        poolExists[_lpToken] = true;

        // Awlays Mass Update - Ensures no trickery.
        massUpdatePools();

        uint256 pid = poolInfo.length;

        // Set Last Reward Block
        uint256 lastRewardBlock =
            block.number > rewardStartBlock ? block.number : rewardStartBlock;

        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accLootPerShare: 0
            })
        );

        // Adjust Global Allocation Points
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        // Emit PoolAdded
        emit PoolAdded(pid, _lpToken, _allocPoint);

        return true;
    }

    /**
     * @dev Update the given pool's LOOT allocation point.
     * @param _pid Pool ID
     * @param _allocPoint New allocation points
     * @return true
     */
    function set(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
        returns (bool)
    {
        // Update All Pools
        massUpdatePools();

        // Adjust Total Allocation Points
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );

        // Set Pool Allocation Points
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint256)
    {
        if (to < rewardEndBlock) {
            return to.sub(from);
        } else if (from > rewardEndBlock) {
            return 0;
        } else {
            return rewardEndBlock.sub(from);
        }
    }

    /**
     * @dev View redeemable LOOT amount
     * @param pid Pool ID
     * @param _user User account
     * @return Pending LOOT reward.
     */
    function pendingLoot(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accLootPerShare = pool.accLootPerShare;

        // Current LP Token supply
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // Calculate released since last reward block.
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);

            // Stop calculating after reward block end.
            if (multiplier > 0) {
                // Calculate LOOT Reward
                uint256 lootReward =
                    multiplier.mul(lootPerBlock).mul(pool.allocPoint).div(
                        totalAllocPoint
                    );

                // Accrued LOOT per Share
                accLootPerShare = accLootPerShare.add(
                    lootReward.mul(1e12).div(lpSupply)
                );
            }
        }

        return user.amount.mul(accLootPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Update reward variables for all pools.
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid Pool ID
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        // Update Last Reward Block
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // Calculate Multiplier
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        // Check Rewards Still Available
        if (multiplier > 0) {
            // Update LOOT Reward
            uint256 lootReward =
                multiplier.mul(lootPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );

            // Update Released LOOT
            pool.accLootPerShare = pool.accLootPerShare.add(
                lootReward.mul(1e12).div(lpSupply)
            );
        }

        // Update Last Reward Block
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Deposit tokens and redeem rewards
     * @param pid Pool ID
     * @param amount token deposit amount
     * @return true
     */
    function deposit(uint256 pid, uint256 amount) public returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Update Pool
        updatePool(pid);

        // Reward User with Active Deposits
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLootPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                // Mint Pending Reward
                _alchemy(msg.sender, pending);

                // Emit RewardClaimed
                emit RewardClaimed(msg.sender, pending);
            }
        }

        if (amount > 0) {
            // Transfer Tokens
            pool.lpToken.safeTransferFrom(msg.sender, address(this), amount);

            // Update User Amount Balance
            user.amount = user.amount.add(amount);
        }

        // Update User Reward Debt
        user.rewardDebt = user.amount.mul(pool.accLootPerShare).div(1e12);

        // Emit Deposit
        emit Deposit(msg.sender, pid, amount);

        return true;
    }

    /**
     * @dev Deposit tokens using permit and redeem rewards
     * @param pid Pool ID
     * @param amount token deposit amount
     * @param deadline timestamp deadline
     * @param v signature v data
     * @param r signature r data
     * @param s signature s data
     * @return true
     */
    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        IUniswapV2PairMinimal lpToken =
            IUniswapV2PairMinimal(address(poolInfo[pid].lpToken));
        lpToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(pid, amount);

        return true;
    }

    /**
     * @dev Withdraw tokens and redeem rewards
     * @param pid Pool ID
     * @param amount token withdraw amount
     */
    function withdraw(uint256 pid, uint256 amount) external returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Update Pool
        updatePool(pid);

        // Amount Matches Available User Balance
        require(user.amount >= amount, "Exceeds Deposited Balance");

        uint256 pending =
            user.amount.mul(pool.accLootPerShare).div(1e12).sub(
                user.rewardDebt
            );

        if (pending > 0) {
            // Mint Pending Reward
            _alchemy(msg.sender, pending);

            // Emit RewardClaimed
            emit RewardClaimed(msg.sender, pending);
        }

        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }

        user.rewardDebt = user.amount.mul(pool.accLootPerShare).div(1e12);
        emit Withdraw(msg.sender, pid, amount);

        return true;
    }

    /**
     * @dev Withdraw deposited tokens without rewards
     * @param pid Pool ID
     */
    function emergencyWithdraw(uint256 pid) external returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Transfer LP Tokens
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);

        // Zero Out User Balances
        user.amount = 0;
        user.rewardDebt = 0;

        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(msg.sender, pid, user.amount);

        return true;
    }

    /**
     * @notice User deposited amount per pool
     * @param pid Pool ID
     * @param _user User Address
     */
    function getDepositedAmount(uint256 pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[pid][_user];
        return user.amount;
    }

    /**
     * @notice Call Citadel alchemy
     * @dev Call Citadel alchemy to mint LOOT token
     * @param to receiver of reward
     * @param amount reward amount
     */
    function _alchemy(address to, uint256 amount) internal {
        // Check Remaining Balance
        uint256 balance = citadel.expansionBalance(address(this));

        // rewardBlockEnd Ensure rewards are awalys accurate, but if a miscalculation
        // exists users can still withdraw total remaining rewards.
        if (amount > balance) {
            citadel.alchemy(to, balance);
        } else {
            citadel.alchemy(to, amount);
        }
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

abstract contract ILootCitadel {
    /**
     * @dev Call alchemy for ERC20 token.
     * @param to Receiver of rewards
     * @param amount Amount of rewards
     */
    function alchemy(address to, uint256 amount) external virtual;

    /**
     * @dev Call alchemy for ERC1155 token.
     * @param to Receiver of rewards
     * @param id Item ID
     * @param amount Amount of rewards
     */
    function alchemy(
        address to,
        uint256 id,
        uint256 amount
    ) external virtual;

    /**
     * @dev Call alchemy for ERC721 token.
     * @param to Receiver of rewards
     * @param tokenId Token Identification Number
     */
    function alchemy721(address to, uint256 tokenId) external virtual;

    /**
     * @dev Get current expansion balance
     * @param expansion Receiver of rewards
     */
    function expansionBalance(address expansion)
        external
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

interface IUniswapV2PairMinimal {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// SPDX-License-Identifier: MIT

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