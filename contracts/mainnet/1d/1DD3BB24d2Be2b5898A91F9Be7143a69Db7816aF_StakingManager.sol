pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./templates/Initializable.sol";
import "./interfaces/IStakingManager.sol";


/**
 * @title StakingManager
 * @dev Staking manager contract
 */
contract StakingManager is Initializable, IStakingManager {
    using SafeMath for uint256;

    uint256 constant private XBE_AMOUNT = 12000 ether;
    uint256[7] private DAILY_XBE_REWARD = [
        999900 finney, // first day - 33.33%
        585000 finney, // second day - 19.50%
        414900 finney, // third day - 13.83%
        321600 finney, // 4th day - 10.72%
        263100 finney, // 5th day - 8,77%
        222600 finney, // 6th day - 7,42%
        192900 finney]; // 7th day - 6,43%

    struct Accumulator {
        uint256 lpTotalAmount;
        uint256 xbeTotalReward;
    }

    event StakerAdded(address user, address pool, uint256 day, uint256 amount);
    event StakerHasClaimedReward(address user, uint256[4] lpTokens, uint256 xbeTokens);

    /// all available pools
    address[4] private _pools;

    /// pool address => status
    mapping(address => bool) private _allowListOfPools;

    /// user address => pool address => daily lp balance
    mapping(address => mapping(address => uint256[7])) private _stakes;

    /// pool address => total LP tokens value which was added per day and daily reward
    mapping(address => Accumulator[7]) private _dailyAccumulator;

    IERC20 private _tokenXbe;

    uint256 private _startTime;

    constructor(
        address xbe,
        uint256 startTime
    ) public {
        _tokenXbe = IERC20(xbe);
        _startTime = startTime;
    }

    /**
     * @dev add all pools address for staking
     */
    function configure(address[4] calldata pools) external initializer {
        _tokenXbe.transferFrom(_msgSender(), address(this), XBE_AMOUNT);

        for (uint i = 0; i < 4; ++i) {
            address pool = pools[i];
            _allowListOfPools[pool] = true;
            _pools[i] = pools[i];
            for (uint j = 0; j < 7; ++j) {
                _dailyAccumulator[pool][j].xbeTotalReward = DAILY_XBE_REWARD[j];
            }
        }
    }

    /**
     * @return start time
     */
    function startTime() external view override returns (uint256) {
        return _startTime;
    }

    /**
     * @return end time
     */
    function endTime() public view override returns (uint256) {
        return _startTime + 7 days;
    }

    /**
     * @return day number from startTime
     */
    function currentDay() external view returns (uint256) {
        if (block.timestamp < _startTime) {
            return 0;
        }
        uint256 day = (block.timestamp - _startTime) / 1 days;
        return (day < 7)? (day + 1) : 0;
    }

    function tokenXbe() external view returns (address) {
        return address(_tokenXbe);
    }

    function getPools() external view override returns (address[4] memory) {
        return _pools;
    }

    function totalRewardForPool(address pool) external view returns (uint256, uint256[7] memory) {
        uint256 poolReward = 0;
        uint256[7] memory dailyRewards;
        for (uint256 i = 0; i < 7; ++i) {
            dailyRewards[i] = _dailyAccumulator[pool][i].xbeTotalReward;
            poolReward = poolReward.add(dailyRewards[i]);

        }
        return (poolReward, dailyRewards);
    }

    function totalLPForPool(address pool) external view returns (uint256, uint256[7] memory) {
        uint256 lpAmount = 0;
        uint256[7] memory dailyLP;
        for (uint256 i = 0; i < 7; ++i) {
            dailyLP[i] = _dailyAccumulator[pool][i].lpTotalAmount;
            lpAmount = lpAmount.add(dailyLP[i]);

        }
        return (lpAmount, dailyLP);
    }

    function getStake(address user) external view returns (uint256[4] memory) {
        uint256[4] memory lpTokens;
        for (uint256 i = 0; i < 4; ++i) {
            lpTokens[i] = 0;
            for (uint256 j = 0; j < 7; ++j) {
                lpTokens[i] = lpTokens[i].add(_stakes[user][_pools[i]][j]);
            }
        }
        return lpTokens;
    }

    function getStakeInfoPerDay(address user, address pool) external view returns (uint256[7] memory) {
        uint256[7] memory lpTokens;
        for (uint256 i = 0; i < 7; ++i) {
            lpTokens[i] = _stakes[user][pool][i];
        }
        return lpTokens;
    }

    function calculateReward(address user, uint256 timestamp) external view returns(uint256[4] memory, uint256[4] memory) {
        uint256[4] memory usersLP;
        uint256[4] memory xbeReward;

        uint256 _endTime = endTime();
        if (timestamp == 0) {
            timestamp = _endTime;
        } else if (timestamp > _endTime) {
            timestamp = _endTime;
        }

        for (uint256 i = 0; i < 4; ++i) {
            address pool = _pools[i];
            uint256 accumulateTotalLP = 0;
            uint256 accumulateUserLP = 0;
            for (uint256 j = 0; j < 7 && timestamp >= _startTime + (j + 1) * 86400; ++j) {
                Accumulator memory dailyAccumulator = _dailyAccumulator[pool][j];
                accumulateTotalLP = accumulateTotalLP.add(dailyAccumulator.lpTotalAmount);
                uint256 stake = _stakes[user][pool][j];
                if (stake > 0) {
                    accumulateUserLP = accumulateUserLP.add(stake);
                    usersLP[i] = usersLP[i].add(stake);
                }
                if (accumulateUserLP > 0) {
                    uint256 dailyReward = dailyAccumulator.xbeTotalReward.mul(accumulateUserLP).div(accumulateTotalLP);
                    xbeReward[i] = xbeReward[i].add(dailyReward);
                }
            }
        }

        return (usersLP, xbeReward);
    }

    /**
     * @dev Add stake
     * @param user user address
     * @param pool pool address
     * @param amount number of LP tokens
     */
    function addStake(address user, address pool, uint256 amount) external override {
        require(block.timestamp >= _startTime, "The time has not come yet");
        require(block.timestamp <= _startTime + 7 days, "stakings has finished");
        require(_allowListOfPools[pool], "Pool not found");

        // transfer LP tokens from sender to contract
        IERC20(pool).transferFrom(_msgSender(), address(this), amount);

        uint256 day = (block.timestamp - _startTime) / 1 days;

        // add amount to daily LP total value
        Accumulator storage dailyAccumulator = _dailyAccumulator[pool][day];
        dailyAccumulator.lpTotalAmount = dailyAccumulator.lpTotalAmount.add(amount);

        // add stake info
        _stakes[user][pool][day] = _stakes[user][pool][day].add(amount);

        emit StakerAdded(user, pool, day + 1, amount);
    }

    /**
     * @dev Pick up reward and LP tokens
     */
    function claimReward(address user) external {
        require(block.timestamp > endTime(), "wait end time");
        uint256 xbeReward = 0;
        uint256[4] memory usersLP;

        for (uint256 i = 0; i < 4; ++i) {
            address pool = _pools[i];
            uint256 accumulateTotalLP = 0;
            uint256 accumulateUserLP = 0;
            for (uint256 j = 0; j < 7; ++j) {
                Accumulator storage dailyAccumulator = _dailyAccumulator[pool][j];
                accumulateTotalLP = accumulateTotalLP.add(dailyAccumulator.lpTotalAmount);
                uint256 stake = _stakes[user][pool][j];
                if (stake > 0) {
                    _stakes[user][pool][j] = 0;
                    dailyAccumulator.lpTotalAmount = dailyAccumulator.lpTotalAmount.sub(stake);
                    accumulateUserLP = accumulateUserLP.add(stake);
                    usersLP[i] = usersLP[i].add(stake);
                }
                if (accumulateUserLP > 0) {
                    uint256 dailyReward = dailyAccumulator.xbeTotalReward.mul(accumulateUserLP).div(accumulateTotalLP);
                    dailyAccumulator.xbeTotalReward = dailyAccumulator.xbeTotalReward.sub(dailyReward);
                    xbeReward = xbeReward.add(dailyReward);
                }
            }
            if (usersLP[i] > 0) {
                IERC20(_pools[i]).transfer(user, usersLP[i]);
            }
        }

        require(xbeReward > 0, "Reward is empty");

        _tokenXbe.transfer(user, xbeReward);

        emit StakerHasClaimedReward(user, usersLP, xbeReward);
    }
}

pragma solidity ^0.6.0;

/**
 * @title IStakingManager
 * @dev Staking manager interface
 */
interface IStakingManager {
    function addStake(
        address user,
        address pool,
        uint256 amount
    ) external;

    function startTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function getPools() external view returns (address[4] memory);
}

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @title Initializable allows to create initializable contracts
 * so that only deployer can initialize contract and only once
 */
contract Initializable is Context {
    bool private _isContractInitialized;
    address private _deployer;

    constructor() public {
        _deployer = _msgSender();
    }

    modifier initializer {
        require(_msgSender() == _deployer, "user not allowed to initialize");
        require(!_isContractInitialized, "contract already initialized");
        _;
        _isContractInitialized = true;
    }
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