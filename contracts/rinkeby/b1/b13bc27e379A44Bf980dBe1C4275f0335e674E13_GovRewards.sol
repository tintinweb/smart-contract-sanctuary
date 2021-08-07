// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IReign.sol";
import "../libraries/LibRewardsDistribution.sol";

contract GovRewards {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;

    // state variables

    address private _rewardsVault;
    // contracts
    IERC20 private _reignToken;
    IReign private _reign;

    mapping(uint128 => uint256) private _sizeAtEpoch;
    mapping(uint128 => uint256) private _epochInitTime;
    mapping(address => uint128) private lastEpochIdHarvested;

    uint256 public epochDuration; // init from reignDiamond contract
    uint256 public epochStart; // init from reignDiamond contract
    uint128 public lastInitializedEpoch;

    // events
    event MassHarvest(
        address indexed user,
        uint256 epochsHarvested,
        uint256 totalValue
    );
    event Harvest(
        address indexed user,
        uint128 indexed epochId,
        uint256 amount
    );
    event InitEpoch(address indexed caller, uint128 indexed epochId);

    // constructor
    constructor(
        address reignTokenAddress,
        address reign,
        address rewardsVault
    ) {
        _reignToken = IERC20(reignTokenAddress);
        _reign = IReign(reign);
        _rewardsVault = rewardsVault;
    }

    //before this the epoch start date is 0
    function initialize() public {
        require(epochStart == 0, "Can only be initialized once");
        epochDuration = _reign.getEpochDuration();
        epochStart = _reign.getEpoch1Start();
    }

    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0

        for (
            uint128 i = lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            uint256 userRewards = _harvest(i);
            totalDistributedValue = totalDistributedValue.add(userRewards);
        }

        emit MassHarvest(
            msg.sender,
            epochId - lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        _reignToken.transferFrom(
            _rewardsVault,
            msg.sender,
            totalDistributedValue
        );

        return totalDistributedValue;
    }

    //gets the rewards for a single epoch
    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(
            lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Harvest in order"
        );
        // get amount to transfer and transfer it
        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            _reignToken.transferFrom(_rewardsVault, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    /*
     * internal methods
     */

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[msg.sender] = epochId;

        // exit if there is no stake on the epoch
        if (_sizeAtEpoch[epochId] == 0) {
            return 0;
        }

        // compute and return user total reward.
        // For optimization reasons the transfer have been moved to an upper layer
        // (i.e. massHarvest needs to do a single transfer)
        uint256 epochRewards = getRewardsForEpoch();
        uint256 boostMultiplier = getBoost(msg.sender, epochId);
        uint256 userEpochRewards = epochRewards
            .mul(_getUserBalancePerEpoch(msg.sender, epochId))
            .mul(boostMultiplier)
            .div(_sizeAtEpoch[epochId])
            .div(1 * 10**18); // apply boost multiplier

        return userEpochRewards;
    }

    function _initEpoch(uint128 epochId) internal {
        require(
            lastInitializedEpoch.add(1) == epochId,
            "Epoch can be init only in order"
        );
        lastInitializedEpoch = epochId;
        _epochInitTime[epochId] = block.timestamp;
        // call the staking smart contract to init the epoch
        _sizeAtEpoch[epochId] = _getPoolSize(block.timestamp);

        emit InitEpoch(msg.sender, epochId);
    }

    /*
     *   VIEWS
     */

    //returns the current epoch
    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // gets the total amount of rewards accrued to a pool during an epoch
    function getRewardsForEpoch() public view returns (uint256) {
        return LibRewardsDistribution.rewardsPerEpochStaking(epochStart);
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256)
    {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256) {
        return lastEpochIdHarvested[msg.sender];
    }

    // calls to the staking smart contract to retrieve the epoch total poolLP size
    function getPoolSizeAtTs(uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return _getPoolSize(timestamp);
    }

    // calls to the staking smart contract to retrieve the epoch total poolLP size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _sizeAtEpoch[epochId];
    }

    // checks if the user has voted that epoch and returns accordingly
    function getBoost(address user, uint128 epoch)
        public
        view
        returns (uint256)
    {
        return _reign.stakingBoostAtEpoch(user, epoch);
    }

    function _getPoolSize(uint256 timestamp) internal view returns (uint256) {
        // retrieve unilp token balance
        return _reign.reignStakedAtTs(timestamp);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        // retrieve unilp token balance per user per epoch
        return _reign.getEpochUserBalance(userAddress, epochId);
    }

    // compute epoch id from blocktimestamp and
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(
            block.timestamp.sub(epochStart).div(epochDuration).add(1)
        );
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibReignStorage.sol";

interface IReign {
    function BASE_MULTIPLIER() external view returns (uint256);

    // deposit allows a user to add more bond to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current BOND balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of BOND that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        external
        view
        returns (LibReignStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // bondStaked returns the total raw amount of BOND staked at the current block
    function reignStaked() external view returns (uint256);

    // reignStakedAtTs returns the total raw amount of BOND users have deposited into the contract
    // it does not include any bonus
    function reignStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakingBoost calculates the multiplier on the user's stake at the current timestamp
    function stakingBoost(address user) external view returns (uint256);

    // stackingBoostAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    function stackingBoostAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // returns the last timestamp in which the user intercated with the staking contarct
    function userLastAction(address user) external view returns (uint256);

    // reignCirculatingSupply returns the current circulating supply of BOND
    function reignCirculatingSupply() external view returns (uint256);

    function getEpochDuration() external view returns (uint256);

    function getEpoch1Start() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);

    function stakingBoostAtEpoch(address, uint128)
        external
        view
        returns (uint256);

    function getEpochUserBalance(address, uint128)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";

library LibRewardsDistribution {
    using SafeMath for uint256;

    uint256 public constant TOTAL_REIGN_SUPPLY = 1000000000 * 10**18;

    uint256 public constant WRAPPING_TOKENS = 500000000 * 10**18;
    uint256 public constant TEAM = 140000000 * 10**18;
    uint256 public constant TREASURY_SALE = 120000000 * 10**18;
    uint256 public constant STAKING_TOKENS = 100000000 * 10**18;
    uint256 public constant TREASURY = 50000000 * 10**18;
    uint256 public constant DEV_FUND = 50000000 * 10**18;
    uint256 public constant LP_REWARDS_TOKENS = 40000000 * 10**18;

    uint256 public constant HALVING_PERIOD = 62899200; // 104 Weeks in Seconds
    uint256 public constant EPOCHS_IN_PERIOD = 104; // Weeks in 2 years
    uint256 public constant BLOCKS_IN_PERIOD = 2300000 * 2;
    uint256 public constant BLOCKS_IN_EPOCH = 44230;

    uint256 public constant TOTAL_ALLOCATION = 1000000000;

    /*
     *   WRAPPING
     */

    function wrappingRewardsPerEpochTotal(uint256 epoch1start)
        internal
        view
        returns (uint256)
    {
        return wrappingRewardsPerPeriodTotal(epoch1start) / EPOCHS_IN_PERIOD;
    }

    function wrappingRewardsPerPeriodTotal(uint256 epoch1start)
        internal
        view
        returns (uint256)
    {
        uint256 _timeElapsed = (block.timestamp.sub(epoch1start));
        uint256 _periodNr = (_timeElapsed / HALVING_PERIOD).add(1); // this creates the 2 year step function
        return WRAPPING_TOKENS.div(2 * _periodNr);
    }

    /*
     *   GOV STAKING
     */

    function rewardsPerEpochStaking(uint256 epoch1start)
        internal
        view
        returns (uint256)
    {
        return stakingRewardsPerPeriodTotal(epoch1start) / EPOCHS_IN_PERIOD;
    }

    function stakingRewardsPerPeriodTotal(uint256 epoch1start)
        internal
        view
        returns (uint256)
    {
        if (epoch1start > block.timestamp) {
            return 0;
        }
        uint256 _timeElapsed = (block.timestamp.sub(epoch1start));
        uint256 _periodNr = (_timeElapsed / HALVING_PERIOD).add(1); // this creates the 2 year step function
        return STAKING_TOKENS.div(2 * _periodNr);
    }

    /*
     *   LP REWARDS
     */

    function rewardsPerEpochLPRewards(uint256 totalAmount, uint256 nrOfEpochs)
        internal
        view
        returns (uint256)
    {
        return totalAmount / nrOfEpochs;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibReignStorage {

    bytes32 constant STORAGE_POSITION = keccak256("org.sovreign.reign.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct EpochBalance {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
        uint256 stakingBoost;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        mapping(address => EpochBalance[]) userBalanceHistory;
        mapping(address => uint128) lastWithdrawEpochId;
        // array of reign staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] reignStakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 reign; // the reign Token
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function reignStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}