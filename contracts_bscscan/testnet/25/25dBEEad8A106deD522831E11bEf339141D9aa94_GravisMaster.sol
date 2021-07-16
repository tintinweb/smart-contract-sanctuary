// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Holder.sol';

import './interfaces/IGravisCollectible.sol';

contract GravisMaster is ERC721Holder, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 constant SPEED_INCREASE_PERIOD = 10 minutes;

    enum PoolType {
        Believer,
        Advocate,
        Evangelist
    }

    struct PoolInfo {
        address nft;
        uint256 id;
        uint256 nominalAmount;
        uint256 startBonusAmount;
        uint256 nominalSpeed;
        uint256 speedMultiplier;
        uint256 speedMultiplierCount;
        uint256 bonusAmount;
        uint256 bonusSpeed;
        PoolType poolType;
    }

    struct ClaimPenalty {
        bool nominalPenalty;
        bool bonusPenalty;
        bool canFarmBonusAfterClaim;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 depositTime;
        uint256 claimTime;
        uint256 claimed;
    }

    IERC20 public token;
    address public tokenProvider;
    bool public claimAllowed;
    Counters.Counter public depositIds;
    PoolInfo[] public pools;

    uint256 public bonusDeadlineTime;

    // Info of each user that stakes NFT. pid => deposit id => info
    mapping(uint256 => mapping(uint256 => DepositInfo)) private _deposits;
    // Mapping to track user => array of deposits ids
    mapping(address => uint256[]) private _userDeposits;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 indexed amount);
    event Claim(address indexed user, uint256 indexed poolId, uint256 indexed amount);

    constructor(
        address _token,
        address _provider,
        address[] memory _nfts
    ) public {
        token = IERC20(_token);
        tokenProvider = _provider;

        // Evangelist Pool
        pools.push(
            PoolInfo({
                nft: _nfts[0],
                id: 0,
                nominalAmount: uint256(9600).mul(1e18),
                startBonusAmount: uint256(1600).mul(1e18),
                nominalSpeed: uint256(120).mul(1e18).div(1 minutes),
                speedMultiplier: uint256(20).mul(1e18).div(1 minutes),
                speedMultiplierCount: 3,
                bonusAmount: uint256(3000).mul(1e18),
                bonusSpeed: uint256(100).mul(1e18).div(1 minutes),
                poolType: PoolType.Evangelist
            })
        );

        // Advocate Pool
        pools.push(
            PoolInfo({
                nft: _nfts[0],
                id: 1,
                nominalAmount: uint256(4600).mul(1e18),
                startBonusAmount: uint256(600).mul(1e18),
                nominalSpeed: uint256(50).mul(1e18).div(1 minutes),
                speedMultiplier: uint256(10).mul(1e18).div(1 minutes),
                speedMultiplierCount: 3,
                bonusAmount: uint256(1350).mul(1e18),
                bonusSpeed: uint256(45).mul(1e18).div(1 minutes),
                poolType: PoolType.Advocate
            })
        );

        // Believer Pool
        pools.push(
            PoolInfo({
                nft: _nfts[0],
                id: 2,
                nominalAmount: uint256(2200).mul(1e18),
                startBonusAmount: uint256(200).mul(1e18),
                nominalSpeed: uint256(20).mul(1e18).div(1 minutes),
                speedMultiplier: uint256(5).mul(1e18).div(1 minutes),
                speedMultiplierCount: 3,
                bonusAmount: uint256(600).mul(1e18),
                bonusSpeed: uint256(20).mul(1e18).div(1 minutes),
                poolType: PoolType.Believer
            })
        );
    }

    function getDepositsByUser(uint256 _pid, address _user) public view returns (DepositInfo[] memory) {
        uint256 totalDeposits;

        for (uint256 i = 0; i < _userDeposits[_user].length; i++) {
            if (isDepositExists(_deposits[_pid][_userDeposits[_user][i]])) {
                totalDeposits = totalDeposits.add(1);
            }
        }

        uint256 depositIndex;
        DepositInfo[] memory userDeposits = new DepositInfo[](totalDeposits);

        for (uint256 i = 0; i < _userDeposits[_user].length; i++) {
            if (isDepositExists(_deposits[_pid][_userDeposits[_user][i]])) {
                userDeposits[depositIndex] = _deposits[_pid][_userDeposits[_user][i]];
                depositIndex = depositIndex.add(1);
            }
        }
        return userDeposits;
    }

    /**
     * @dev Public function to deposit nft token to the given pool
     * @param _pid Pool Id
     * @param _amount Tokens amount
     */
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused nonReentrant {
        require(_pid <= 2, 'GravisMaster: Invalid Pool Id');
        require(_amount > 0, 'GravisMaster: Zero amount');

        PoolInfo storage pool = pools[_pid];

        IGravisCollectible(pool.nft).transferFor(_msgSender(), address(this), pool.id, _amount);

        depositIds.increment();

        _deposits[_pid][depositIds.current()] = DepositInfo(_amount, block.timestamp, 0, 0);

        _userDeposits[_msgSender()].push(depositIds.current());

        emit Deposit(_msgSender(), _pid, _amount);
    }

    /**
     * @dev Get user rewards for the given pool
     * @param _pid Pool Id
     * @param _user User address
     * @return rewards
     */
    function getPoolUserRewards(uint256 _pid, address _user) public view returns (uint256 rewards) {
        for (uint256 i = 0; i < _userDeposits[_user].length; i++) {
            rewards = rewards.add(getRewardsForDeposit(_pid, _userDeposits[_user][i]));
        }
    }

    /**
     * @dev Internal function to check if current deposit exists
     * @param info DepositInfo struct
     * @return depositExists
     */
    function isDepositExists(DepositInfo memory info) internal pure returns (bool) {
        return info.amount > 0 && info.depositTime > 0;
    }

    /**
     * @dev Internal function to calculate average farming speed
     * @param fromTime Start period time
     * @param toTime End period time
     * @param pool PoolInfo struct
     * @return averageSpeed
     */
    function getAverageSpeed(
        uint256 fromTime,
        uint256 toTime,
        PoolInfo memory pool
    ) internal pure returns (uint256) {
        uint256 timeDiff = toTime.sub(fromTime);

        uint256 periodsCount = timeDiff.div(SPEED_INCREASE_PERIOD);
        uint256 leftoverTime = timeDiff % SPEED_INCREASE_PERIOD;

        uint256 amount;
        uint256 currentSpeed = pool.nominalSpeed;

        for (uint256 i = 1; i <= periodsCount; i++) {
            amount = amount.add(SPEED_INCREASE_PERIOD.mul(currentSpeed));
            if (i <= pool.speedMultiplierCount) {
                currentSpeed = currentSpeed.add(pool.speedMultiplier);
            }
        }

        if (leftoverTime > 0) {
            amount = amount.add(leftoverTime.mul(currentSpeed));
        }
        // average speed = (SPEED_INCREASE_PERIOD * s1 ... + leftoverTime * sn) / timeDiff

        return periodsCount == 0 ? pool.nominalSpeed : amount.div(timeDiff);
    }

    /**
     * @dev Internal function to calculate time needed to farm nominal amount
     * @param pool PoolInfo struct
     * @return time
     */
    function getTimeToFarmNominal(PoolInfo memory pool) internal pure returns (uint256 time) {
        uint256 currentSpeed = pool.nominalSpeed;
        uint256 amount = pool.startBonusAmount;
        uint256 remainingAmount;

        for (uint256 i = 1; i <= 10; i++) {
            // nominal is reached
            if (amount.add(SPEED_INCREASE_PERIOD.mul(currentSpeed)) >= pool.nominalAmount) {
                // how many tokens we need to farm until nominal
                remainingAmount = amount.add(currentSpeed.mul(SPEED_INCREASE_PERIOD)).sub(pool.nominalAmount);
                // how many seconds to farm this amount at current speed
                return time.add(remainingAmount.div(currentSpeed));
            }

            amount = amount.add(SPEED_INCREASE_PERIOD.mul(currentSpeed));
            time = time.add(SPEED_INCREASE_PERIOD);

            if (i <= pool.speedMultiplierCount) {
                currentSpeed = currentSpeed.add(pool.speedMultiplier);
            }
        }
    }

    /**
     * @dev Internal helper function to calculate farm amount for given deposit without claims
     * @dev see getRewardsForDeposit
     * @param _pid Pool Id
     * @param _depositIndex Deposit index, to get DepositInfo struct from array
     * @return reward
     */
    function getRewardsForDepositWithoutClaim(uint256 _pid, uint256 _depositIndex) internal view returns (uint256 reward) {
        PoolInfo memory pool = pools[_pid];

        DepositInfo memory info = _deposits[_pid][_depositIndex];

        // Excessive check, same check in getRewardsForDeposit
        // if (!isDepositExists(info)) {
        //     return 0;
        // }

        reward = reward.add(pool.startBonusAmount);

        uint256 timeDiff = block.timestamp.sub(info.depositTime);
        uint256 timeToFarmNominal = getTimeToFarmNominal(pool);

        bool canFarmBonus = true;

        // deadline after nominal farmed
        // adjust timeDiff
        if (bonusDeadlineTime > 0 && bonusDeadlineTime > info.depositTime.add(timeToFarmNominal)) {
            timeDiff = bonusDeadlineTime.sub(info.depositTime);
        } else if (bonusDeadlineTime > 0 && bonusDeadlineTime < info.depositTime.add(timeToFarmNominal)) {
            // deadline before nominal farmed
            // switch flag
            canFarmBonus = false;
        }

        // If nominal is farmed, farm bonus
        if (timeDiff > timeToFarmNominal) {
            reward = pool.nominalAmount;
            if (canFarmBonus) {
                timeDiff = timeDiff.sub(timeToFarmNominal);
                if (pool.bonusSpeed.mul(timeDiff) >= pool.bonusAmount) {
                    reward = reward.add(pool.bonusAmount);
                } else {
                    reward = reward.add(pool.bonusSpeed.mul(timeDiff));
                }
            }
        } else {
            uint256 averageSpeed = getAverageSpeed(info.depositTime, block.timestamp, pool);
            reward = reward.add(averageSpeed.mul(timeDiff));
        }

        reward = reward.mul(info.amount).sub(info.claimed);
    }

    /**
     * @dev Internal function to calculate farm amount for given deposit
     * @dev Used to calculate farms for all pools
     * @param _pid Pool Id
     * @param _depositIndex Deposit index, to get DepositInfo struct from array
     * @return reward
     */
    function getRewardsForDeposit(uint256 _pid, uint256 _depositIndex) internal view returns (uint256 reward) {
        PoolInfo memory pool = pools[_pid];

        DepositInfo memory info = _deposits[_pid][_depositIndex];

        if (!isDepositExists(info)) {
            return 0;
        }

        reward = reward.add(pool.startBonusAmount);

        uint256 timeDiff = block.timestamp.sub(info.depositTime);
        uint256 timeToFarmNominal;
        uint256 claimPerToken = info.claimed.div(info.amount);

        if (pool.poolType == PoolType.Believer && info.claimTime > 0) {
            // Believer pool
            // - reset speed to nominal if claimed any time
            // - can not farm bonus if claimed
            if (claimPerToken <= pool.nominalAmount) {
                // Claimed at nominal stage
                timeDiff = block.timestamp.sub(info.claimTime);
                reward = claimPerToken.add(pool.nominalSpeed.mul(timeDiff));
                if (reward > pool.nominalAmount) {
                    reward = pool.nominalAmount;
                }
            } else {
                // Claimed at bonus stage
                reward = claimPerToken;
            }
            reward = reward.mul(info.amount).sub(info.claimed);
        } else if (pool.poolType == PoolType.Advocate && info.claimTime > 0) {
            // Advocate pool
            // - reset speed to nominal if claimed any time
            // - can farm bonus if claimed at nominal stage
            // - cannot farm bonus if claimed at bonus stage
            if (claimPerToken <= pool.nominalAmount) {
                // Claimed at nominal stage
                timeDiff = block.timestamp.sub(info.claimTime);
                reward = claimPerToken.add(pool.nominalSpeed.mul(timeDiff));
                if (reward > pool.nominalAmount) {
                    // Nominal farmed, proceed with farming bonus
                    timeToFarmNominal = pool.nominalAmount.sub(claimPerToken).div(pool.nominalSpeed);
                    reward = pool.nominalAmount;
                    timeDiff = timeDiff.sub(timeToFarmNominal);

                    bool canFarmBonus = true;
                    // deadline after nominal farmed
                    // adjust timeDiff
                    if (bonusDeadlineTime > 0 && bonusDeadlineTime > info.claimTime.add(timeToFarmNominal)) {
                        timeDiff = bonusDeadlineTime.sub(info.claimTime).sub(timeToFarmNominal);
                    } else if (bonusDeadlineTime > 0 && bonusDeadlineTime < info.claimTime.add(timeToFarmNominal)) {
                        // deadline before nominal farmed
                        // switch flag
                        canFarmBonus = false;
                    }
                    if (canFarmBonus) {
                        if (pool.bonusSpeed.mul(timeDiff) >= pool.bonusAmount) {
                            reward = reward.add(pool.bonusAmount);
                        } else {
                            reward = reward.add(pool.bonusSpeed.mul(timeDiff));
                        }
                    }
                }
            } else {
                // Claimed at bonus stage
                reward = claimPerToken;
            }
            reward = reward.mul(info.amount).sub(info.claimed);
        } else if (pool.poolType == PoolType.Evangelist && info.claimTime > 0) {
            // Evangelist pool
            // - no speed reset
            // - can farm bonus if claimed at nominal stage
            // - can farm bonus if claimed at bonus stage
            reward = getRewardsForDepositWithoutClaim(_pid, _depositIndex);
        } else {
            // Not claimed, calculate farm as usual
            reward = getRewardsForDepositWithoutClaim(_pid, _depositIndex);
        }
    }

    /**
     * @dev Internal helper function to claim reward for given deposit
     * @dev Modifies the state
     * @dev see claimRewards
     * @param _pid Pool Id
     * @param _depositIndex Deposit index, to get DepositInfo struct from array
     * @return reward
     */
    function claimRewardsFromDeposit(uint256 _pid, uint256 _depositIndex) internal returns (uint256 reward) {
        reward = getRewardsForDeposit(_pid, _depositIndex);
        if (reward > 0) {
            DepositInfo storage info = _deposits[_pid][_depositIndex];
            info.claimed = info.claimed.add(reward);
            info.claimTime = block.timestamp;
        }
    }

    /**
     * @dev Public function to claim reward for the given pool
     * @dev Iterates through user deposits and claims all rewards for every deposit
     * @dev see claimRewardsFromDeposit
     * @param _pid Pool Id
     */
    function claimRewards(uint256 _pid) public whenNotPaused nonReentrant {
        require(claimAllowed, 'GravisMaster: Claim not allowed');
        require(_userDeposits[_msgSender()].length > 0, 'GravisMaster: No deposits');

        uint256 totalRewards;
        for (uint256 i = 0; i < _userDeposits[_msgSender()].length; i++) {
            totalRewards = totalRewards.add(claimRewardsFromDeposit(_pid, _userDeposits[_msgSender()][i]));
        }

        require(totalRewards > 0, 'GravisMaster: Zero rewards');
        require(token.balanceOf(tokenProvider) >= totalRewards, 'GravisMaster: Not enough tokens');

        token.safeTransferFrom(tokenProvider, _msgSender(), totalRewards);

        emit Claim(_msgSender(), _pid, totalRewards);
    }

    /**
     * @dev Switch the claim allowed flag (owner only)
     */
    function allowClaim() public onlyOwner {
        claimAllowed = true;
    }

    /**
     * @dev Set bonus deadline time to current time (owner only)
     */
    function setBonusDeadlineTime() public onlyOwner {
        require(bonusDeadlineTime == 0, 'GravisMaster: Bonus deadline time already set');
        bonusDeadlineTime = block.timestamp;
    }

    /**
     * @dev Pause all activity of deposit and claim rewards fucntions (owner only)
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpause all activity of deposit and claim rewards fucntions (owner only)
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IGravisCollectible {
    function transferFor(
        address _from,
        address _to,
        uint256 _type,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}