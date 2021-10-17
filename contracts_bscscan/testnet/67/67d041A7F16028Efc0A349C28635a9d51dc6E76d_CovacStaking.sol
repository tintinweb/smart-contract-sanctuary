pragma solidity >=0.6.0;

import "./Context.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Context {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = _msgSender();
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_msgSender() == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

pragma solidity >=0.6.0;

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

pragma solidity >=0.6.0;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./interfaces/IBEP20.sol";
import "./libraries/SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Covac Staking
 */
contract CovacStaking is Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount; // Staked amount
        uint256 createdAt; // Timestamp when stake is created
        uint256 rewardAmount; // Calculated reward amount, will be transfered to stake holder after plan expiry
        uint8 state; // State of the stake, 0 - FREE, 1 - ACTIVE, 2 - 'REMOVING'
        string plan;
    }

    struct Plan {
        string name; // The name of the plan, should be a single word in lowercase
        uint256 durationInDays; // The duration in days of the plan
        uint256 rewardPercentage; // The total reward percentage of the plan with 2 decimal ex. 20% = 2000
        uint256 minimumStake; // The minimum amount a stakeholder can stake
        uint256 maximumStake; // The maximum amount a stakeholder can stake for the first 48 hours
        uint256 planMaximumStake; // The maximum stakable amount of a plan
        uint256 createdAt; // Timestamp when plan is created
        uint256 usageCount; // How many stakes are in active on this plan
        uint256 stakedAmount; // Total stake amount of a plan
        uint8 state; // State of the plan, 0 - Not Created, 1 - Active, 2 - Disabled
    }

    address public tokenAddress; // Token Contract Address
    address public rewardAccount; // Account from which reward will be sent to Stake holders
    uint256 public totalStakedAmount; // Total staked amount, from all share holders
    uint256 public totalPendingRewardAmount; // Reward Amount pending to be rewarded to all stakeholders
    uint256 public totalRewardAmountClaimed; // Reward amount transfered to all stake holders
    bool public stakingPaused;

    // The stakes for each stakeholder.
    mapping(address => Stake[]) internal stakes;

    // The plans (name -> plan)
    mapping(string => Plan) internal plans;

    event PlanCreated(string name, uint256 duration, uint256 rewardPercentage);
    event PlanDeleted(string name);
    event ExcessRewardTransferred(address, uint256);
    event Staked(
        address sender,
        string plan,
        uint256 stakeAmount,
        uint256 duration,
        uint256 rewardAmount
    );
    event StakeRemoved(
        address sender,
        uint256 stakeIndex,
        uint256 stakeAmount,
        uint256 rewardAmount
    );

    constructor(address token, address rewardsFrom) public {
        tokenAddress = token;
        rewardAccount = rewardsFrom;
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stakeAmount The size of the stake to be created.
     * @param _plan The type of stake to be created.
     */
    function enterStaking(uint256 _stakeAmount, string memory _plan)
        public
        returns (uint256 stakeIndex)
    {
        uint256 i;
        uint256 rewardAmount;

        Plan storage plan = plans[_plan];

        require(!stakingPaused, "CovacStaking: Staking is Paused");
        /* plan must be valid and should not be disabled for further stakes */
        require(
            plan.state == 1,
            "CovacStaking: Invalid or disabled staking plan"
        );
        require(
            _stakeAmount >= plan.minimumStake,
            "CovacStaking: Stake amount is below minimum allowed stake"
        );
        require(
            _stakeAmount <= plan.maximumStake || _isExpired(plan.createdAt, 2),
            "CovacStaking: Stake amount is exceed maximum allowed stake in the first 48 hours"
        );
        require(
            !_isExceedMaxStaked(_plan, _stakeAmount),
            "CovacStaking: Stake amount is exceed the maximum stakable amount of a plan"
        );
        // Transfer tokens from stake holders account to this contract account
        IBEP20(tokenAddress).transferFrom(
            _msgSender(),
            address(this),
            _stakeAmount
        );
        
        rewardAmount = (
            _stakeAmount.mul(plan.rewardPercentage).div(10000)
        );

        IBEP20(tokenAddress).transferFrom(
            rewardAccount,
            address(this),
            rewardAmount
        );

        for (i = 0; i < stakes[_msgSender()].length; i++)
            if (stakes[_msgSender()][i].state == 0) break;

        stakeIndex = i;
        stakes[_msgSender()].push(
            Stake(_stakeAmount, block.timestamp, rewardAmount, 1, _plan)
        );

        totalStakedAmount = totalStakedAmount.add(_stakeAmount);
        totalPendingRewardAmount = totalPendingRewardAmount.add(rewardAmount);

        plan.stakedAmount = plan.stakedAmount.add(_stakeAmount);

        // Increase the usage count of this plan
        plan.usageCount++;

        emit Staked(
            _msgSender(),
            _plan,
            _stakeAmount,
            plan.durationInDays,
            _stakeAmount.mul(plan.rewardPercentage).div(10000)
        );
    }

    function getStakesIndexes(address stakeHolder)
        public
        view
        returns (uint256[] memory stakesIndexes, uint256 numStakes)
    {
        uint256 i;
        uint256 j;
        uint256 totalStakes = stakes[stakeHolder].length;
        for (i = 0; i < totalStakes; i++)
            if (stakes[stakeHolder][i].state == 1) numStakes++;

        if (numStakes > 0) {
            stakesIndexes = new uint256[](numStakes);

            for (i = 0; i < totalStakes; i++) {
                if (stakes[stakeHolder][i].state == 1) {
                    stakesIndexes[j] = i;
                    j++;
                }
            }
        }
    }

    function getAllStakes(address stakeHolder)
        public
        view
        returns (
            uint256[] memory stakesIndexes,
            uint256[] memory stakedAmounts,
            uint256[] memory createdAt,
            uint256 numStakes
        )
    {
        uint256 i;
        uint256 j;
        uint256 totalStakes = stakes[stakeHolder].length;
        for (i = 0; i < totalStakes; i++) {
            if (stakes[stakeHolder][i].state == 1) numStakes++;
        }

        if (numStakes > 0) {
            stakesIndexes = new uint256[](numStakes);
            stakedAmounts = new uint256[](numStakes);
            createdAt = new uint256[](numStakes);

            for (i = 0; i < totalStakes; i++) {
                if (stakes[stakeHolder][i].state == 1) {
                    stakesIndexes[j] = i;
                    stakedAmounts[j] = stakes[stakeHolder][i].amount;
                    createdAt[j] = stakes[stakeHolder][i].createdAt;
                    j++;
                }
            }
        }
    }

    function getStakeInfo(address stakeHolder, uint256 _stakeIndex)
        public
        view
        returns (
            uint256 stakeAmount,
            uint256 createdAt,
            uint256 rewardAmount,
            string memory plan
        )
    {
        if (
            _stakeIndex < stakes[stakeHolder].length &&
            stakes[stakeHolder][_stakeIndex].state == 1
        ) {
            stakeAmount = stakes[stakeHolder][_stakeIndex].amount;
            createdAt = stakes[stakeHolder][_stakeIndex].createdAt;
            plan = stakes[stakeHolder][_stakeIndex].plan;
            rewardAmount = stakeAmount.mul(plans[plan].rewardPercentage).div(
                10000
            );
        }
    }

    function getStakedAmountByPlan(string memory _plan)
        public
        view
        onlyOwner
        returns (uint256)
    {
        if (plans[_plan].state > 0)
            return plans[_plan].stakedAmount;
        return 0;
    }

    // Withdraw/Remove a stake
    function withdrawStaking(uint256 _stakeIndex) public {
        uint256 amount;

        require(
            _stakeIndex < stakes[_msgSender()].length,
            "CovacStaking: Invalid stake index"
        );

        Stake storage stake = stakes[_msgSender()][_stakeIndex];
        require(stake.state == 1, "CovacStaking: Stake is not active");

        // Set the state to 'removing'
        stake.state = 2;

        /* Transfer stake amount + rewared amount to the stake holder if withdraw after stake expired
         * else transfer 
         */
        amount = amount.add(stake.amount);
        if (_isExpired(stake.createdAt, plans[stake.plan].durationInDays)) {
            /* Transfer stake + reward to stake holder, if withdraw after stake expired
               then update global variable */
            amount = amount.add(stake.rewardAmount);
            IBEP20(tokenAddress).transfer(_msgSender(), amount);
            totalStakedAmount = totalStakedAmount.sub(stake.amount);
            totalPendingRewardAmount = totalPendingRewardAmount.sub(
                stake.rewardAmount
            );
            totalRewardAmountClaimed = totalRewardAmountClaimed.add(
                stake.rewardAmount
            );
        } else {
            /* Transfer stake to stake holder, and transfer reward to rewardAddress, if withdraw before stake expired
               then update global variable */
            IBEP20(tokenAddress).transfer(_msgSender(), amount);
            IBEP20(tokenAddress).transfer(rewardAccount,stake.rewardAmount);
            totalStakedAmount = totalStakedAmount.sub(stake.amount);
            totalPendingRewardAmount = totalPendingRewardAmount.sub(
                stake.rewardAmount
            );
        }

        plans[stake.plan].stakedAmount = plans[stake.plan].stakedAmount.sub(
            stake.amount
        );

        // Reduce plan active count
        plans[stake.plan].usageCount--;

        emit StakeRemoved(
            _msgSender(),
            _stakeIndex,
            stake.amount,
            stake.rewardAmount
        );
        delete stakes[_msgSender()][_stakeIndex]; // Sets state to 0
    }

    /**
     * @notice transfer excessing reward to destination address
     * @param _to The destination address.
     */
    function transferExcessReward(address _to) public onlyOwner {
        uint256 excessAmount = IBEP20(tokenAddress).balanceOf(
            address(this)
        );

        if (excessAmount > 0) {
            excessAmount = excessAmount.sub(
                totalStakedAmount.add(totalPendingRewardAmount)
            );
            IBEP20(tokenAddress).transfer(_to, excessAmount);
        }
        emit ExcessRewardTransferred(_to, excessAmount);
    }

    /**
     * @notice A method to pause staking. New stakes are not allowed once paused
     *
     */
    function pauseStaking() public onlyOwner returns (bool) {
        stakingPaused = true;
        return true;
    }

    /**
     * @notice A method to resume paused staking. New stakes are allowed once resumed
     *
     */
    function resumeStaking() public onlyOwner returns (bool) {
        stakingPaused = false;
        return true;
    }

    /**
     * @notice A method to update 'rewaredAccount'
     * @param _rewardAccount Account from which reward will be sent to Stake holders
     */
    function updateRewardAccount(address _rewardAccount)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _rewardAccount != address(0),
            "Invalid address for rewardAccount"
        );

        rewardAccount = _rewardAccount;
        return true;
    }

    /**
     * @notice A method for a contract owner to create a staking plan.
     * @param _name The name of the plan to be created.
     * @param _minimum_stake The minimum a stakeholder can stake.
     * @param _maximum_stake The maximum amount a stakeholder can stake for the first 48 hours
     * @param _plan_maximum_stake The maximum stakable amount of a plan
     * @param _duration The duration in days of the plan to be created.
     * @param _reward_percentage The total reward percentage of the plan.
     *        Percentage should be in the degree of '100' (i.e multiply the required percent by 100)
     *        To set 10 percent, _reward_percentage should be 1000, to set 0.1 percent, it shoud be 10.
     */
    function createPlan(
        string memory _name,
        uint256 _minimum_stake,
        uint256 _maximum_stake,
        uint256 _plan_maximum_stake,
        uint256 _duration,
        uint256 _reward_percentage
    ) public onlyOwner {
        require(_duration > 0, "CovacStaking: Duration in days must grater than zero");
        require(
            _minimum_stake > 0,
            "CovacStaking: Minimum stake must grater than zero"
        );
        require(
            _maximum_stake >= _minimum_stake,
            "CovacStaking: Maximum stake must not less than Minimum stake"
        );
        require(
            _plan_maximum_stake >= _maximum_stake,
            "CovacStaking: Total Maximum stake must not less than Maximum stake"
        );
        require(
            _reward_percentage > 0,
            "CovacStaking: Total reward percentage must grater than zero"
        );
        require(plans[_name].state == 0, "CovacStaking: Plan already exists");

        Plan storage plan = plans[_name];

        plan.name = _name;
        plan.minimumStake = _minimum_stake;
        plan.maximumStake = _maximum_stake;
        plan.planMaximumStake = _plan_maximum_stake;
        plan.durationInDays = _duration;
        plan.rewardPercentage = _reward_percentage;
        plan.createdAt = block.timestamp;
        plan.state = 1;

        emit PlanCreated(plan.name, plan.durationInDays, plan.rewardPercentage);
    }

    function deletePlan(string memory _name) public onlyOwner {
        require(plans[_name].state > 0, "CovacStaking: Plan not found");
        require(plans[_name].usageCount == 0, "CovacStaking: Plan is in use");

        delete plans[_name];

        emit PlanDeleted(_name);
    }

    /**
     * @notice A method to disable a plan. No more stakes will be added to this plan.
     * @param _name The plan name to disable
     */
    function disablePlan(string memory _name) public onlyOwner {
        require(plans[_name].state > 0, "CovacStaking: Plan doesn't exist");
        plans[_name].state = 2; // Disable
    }

    /**
     * @notice A method to update a plan minimum staking amount.
     * @param _name The plan name to update
     * @param _minimum_stake The minimum a stakeholder can stake.
     */
    function updateMinimumStake(string memory _name, uint256 _minimum_stake)
        public
        onlyOwner
    {
        require(plans[_name].state > 0, "CovacStaking: Plan doesn't exist");
        require(
            _minimum_stake > 0,
            "CovacStaking: Minimum stake must grater than zero"
        );
        require(
            _minimum_stake <= plans[_name].maximumStake,
            "CovacStaking: Minimum stake must not grater than maximum stake"
        );
        plans[_name].minimumStake = _minimum_stake;
    }

    /**
     * @notice A method to update a plan total maximum staking amount.
     * @param _name The plan name to update
     * @param _plan_maximum_stake The maximum stakable amount of a plan
     */
    function updatePlanMaximumStake(
        string memory _name,
        uint256 _plan_maximum_stake
    ) public onlyOwner {
        require(plans[_name].state > 0, "CovacStaking: Plan doesn't exist");
        require(
            _plan_maximum_stake >= plans[_name].maximumStake,
            "CovacStaking: Total Maximum stake must not less than Maximum stake"
        );
        plans[_name].planMaximumStake = _plan_maximum_stake;
    }

    /**
     * @notice A method to retrieve the plan with the name.
     * @param _name The plan to retrieve
     */
    function getPlanInfo(string memory _name)
        public
        view
        returns (
            uint256 minimumStake,
            uint256 maximumStake,
            uint256 planMaximumStake,
            uint256 duration,
            uint256 rewardPercentage,
            uint256 usageCount,
            uint8 state
        )
    {
        Plan storage plan = plans[_name];

        if (plan.state > 0) {
            minimumStake = plan.minimumStake;
            maximumStake = plan.maximumStake;
            planMaximumStake = plan.planMaximumStake;
            duration = plan.durationInDays;
            rewardPercentage = plan.rewardPercentage;
            usageCount = plan.usageCount;
            state = plan.state;
        }
    }

    function _isExpired(uint256 _time, uint256 _duration)
        internal
        view
        returns (bool)
    {
        // TODO: change 'minutes to 'days' in production
        if (block.timestamp >= (_time + _duration * 1 minutes)) return true;
        else return false;
    }

    function _isExceedMaxStaked(string memory _plan, uint256 _stakeAmount)
        internal
        view
        returns (bool)
    {
        return
            plans[_plan].stakedAmount + _stakeAmount >
            plans[_plan].planMaximumStake;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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