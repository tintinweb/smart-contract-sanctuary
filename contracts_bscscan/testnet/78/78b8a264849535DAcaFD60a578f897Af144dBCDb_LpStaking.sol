// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./interfaces/IBEP20.sol";
import "./libraries/SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Lp Staking
 */
contract LpStaking is Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount; //staked amount
        uint256 createdAt; // Timestamp of when stake was created
        uint256 rewardAmount; // Calculated reward amount, will be transfered to stake holder after plan expiry
        uint8 state; // state of the stake, 0 - FREE, 1 - ACTIVE, 2 - 'REMOVING'
        string plan;
    }

    struct Plan {
        string name; //The name of the plan, should be a single word in lowercase
        uint256 durationInDays; // The duration in days of the plan
        uint256 rewardPercentage; //The total reward percentage of the plan
        uint256 minimumStake; //The minimum amount a stakeholder can stake
        uint256 createdAt; // Timestamp of when plan was created
        uint256 usageCount; // How many stakes are in active on this plan
        uint256 stakedAmount;
        uint8 state; // State of the plan, 0 - Not Created, 1 - Active, 2 - Disabled
    }

    uint256 public constant MAX_NUM_OF_STAKES_PER_USER = 5;

    address public lpTokenAddress; /* LEOS Token Contract Address */
    address public rewardAccount; //Lp account from which reward amount will be sent to Stake holders
    uint256 public totalStakedAmount; // Total staked amount, from all share holders
    uint256 public totalPendingRewardAmount; // Reward Amount pending to be rewarded to all stakeholders
    uint256 public totalRewardAmountClaimed; // Reward amount transfered to all stake holders
    bool public stakingPaused;

    //The stakes for each stakeholder.
    mapping(address => Stake[MAX_NUM_OF_STAKES_PER_USER]) internal stakes;

    //The plans
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
        uint256 stakeamount,
        uint256 rewardAmount
    );

    constructor(address lpToken, address rewardsFrom) public {
        lpTokenAddress = lpToken;
        rewardAccount = rewardsFrom;
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stakeAmount The size of the stake to be created.
     * @param _plan The type of stake to be created.
     */
    function enterStaking(uint256 _stakeAmount, string memory _plan)
       external  
        returns (uint256 stakeIndex)
    {
        uint256 i;
        uint256 rewardAmount;

        Plan storage plan = plans[_plan];

        require(!stakingPaused, "LpStaking: Staking Paused");
        /* plan must be valid and should not be disabled for further stakes */
        require(
            plan.state == 1,
            "LpStaking: Invalid or disabled staking plan"
        );
        require(
            _stakeAmount >= plan.minimumStake,
            "LpStaking: Stake is below minimum allowed stake"
        );

        // Transfer tokens from stake holders Lp account to this contract account
        IBEP20(lpTokenAddress).transferFrom(
            _msgSender(),
            address(this),
            _stakeAmount
        );

        /* Reward amount is the rewardAmount */
        rewardAmount = (
            _stakeAmount.mul(plan.rewardPercentage).div(10000)
        );

        IBEP20(lpTokenAddress).transferFrom(
            rewardAccount,
            address(this),
	    rewardAmount
        );

        /* A stack holder can stake upto MAX_NUM_OF_STAKES_PER_USER of stakes at any point of time */
        for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++)
            if (stakes[_msgSender()][i].state == 0) break;

        require(
            i < MAX_NUM_OF_STAKES_PER_USER,
            "LpStacking: Reached maximum stakes per user"
        );

        Stake storage stake = stakes[_msgSender()][i];

        stake.amount = _stakeAmount;
        stake.plan = _plan;
        stake.rewardAmount = rewardAmount;
        stake.createdAt = block.timestamp;
        stake.state = 1; // Set to active statemul
        stakeIndex = i;

        totalStakedAmount = totalStakedAmount.add(_stakeAmount);
        totalPendingRewardAmount = totalPendingRewardAmount.add(
            stake.rewardAmount
        );

        plan.stakedAmount = plan.stakedAmount.add(_stakeAmount);

        /* Increase the usage count of this plan */
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
        external
        view
        returns (uint256[] memory stakesIndexes, uint256 numStakes)
    {
        uint256 i;
        uint256 j;

        for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++)
            if (stakes[stakeHolder][i].state == 1) numStakes++;

        if (numStakes > 0) {
            stakesIndexes = new uint256[](numStakes);

            for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++) {
                if (stakes[stakeHolder][i].state == 1) {
                    stakesIndexes[j] = i;
                    j++;
                }
            }
        }
    }

    function getAllStakes(address stakeHolder)
        external
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

        for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++) {
            if (stakes[stakeHolder][i].state == 1) numStakes++;
        }

        if (numStakes > 0) {
            stakesIndexes = new uint256[](numStakes);
            stakedAmounts = new uint256[](numStakes);
            createdAt = new uint256[](numStakes);

            for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++) {
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
        external
        view
        returns (
            uint256 stakeAmount,
            uint256 createdAt,
            uint256 rewardAmount,
            string memory plan
        )
    {
        if (
            _stakeIndex < MAX_NUM_OF_STAKES_PER_USER &&
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
        external
        view
        onlyOwner
        returns (uint256)
    {
        if (plans[_plan].state > 0)
            return plans[_plan].stakedAmount;

        return 0;
    }

    /* Withdraw/Remove a stake */
    function withdrawStaking(uint256 _stakeIndex) external {
        uint256 amount;

        require(
            _stakeIndex < MAX_NUM_OF_STAKES_PER_USER,
            "LpStaking: Invalid stake index"
        );

        Stake storage stake = stakes[_msgSender()][_stakeIndex];
        require(stake.state == 1, "LpStaking: Stake is not active");
        require(
            _isExpired(stake.createdAt, plans[stake.plan].durationInDays),
            "LpStaking: Stake Plan not expired yet"
        );

        // set the state to 'removing'
        stake.state = 2;

        /* transfer stake amount + rewared amount to the stake holder */
        amount = amount.add(stake.amount);
        amount = amount.add(stake.rewardAmount);

        IBEP20(lpTokenAddress).transfer(_msgSender(), amount);

        /* Update globals */
        totalStakedAmount = totalStakedAmount.sub(stake.amount);
        totalPendingRewardAmount = totalPendingRewardAmount.sub(
            stake.rewardAmount
        );
        totalRewardAmountClaimed = totalRewardAmountClaimed.add(
            stake.rewardAmount
        );

        plans[stake.plan].stakedAmount = plans[stake.plan].stakedAmount.sub(
            stake.amount
        );

        /* reduce plan active count */
        plans[stake.plan].usageCount--;

        emit StakeRemoved(
            _msgSender(),
            _stakeIndex,
            stake.amount,
            stake.amount.mul(plans[stake.plan].rewardPercentage).div(10000)
        );
        delete stakes[_msgSender()][_stakeIndex]; //Sets state to 0
    }

    /*
     */
    function transferExcessReward(address _to) external onlyOwner {
        uint256 excessAmount = IBEP20(lpTokenAddress).balanceOf(
            address(this)
        );

        if (excessAmount > 0) {
            excessAmount = excessAmount.sub(
                totalStakedAmount.add(totalPendingRewardAmount)
            );
            IBEP20(lpTokenAddress).transfer(_to, excessAmount);
        }
        emit ExcessRewardTransferred(_to, excessAmount);
    }

    /*
     * @notice A method to pause staking. New stakes are not allowed once paused
     *
     */
    function pauseStaking() external onlyOwner returns (bool) {
        stakingPaused = true;
        return true;
    }

    /*
     * @notice A method to resume paused staking. New stakes are allowed once resumed
     *
     */
    function resumeStaking() external onlyOwner returns (bool) {
        stakingPaused = false;
        return true;
    }

    /*
     * @notice A method to update 'rewaredAccount'
     *
     */
    function updateRewardAccount(address _rewardAccount)
        external 
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
     * @param _duration The duration in weeks of the plan to be created.
     * @param _reward_percentage The total reward percentage of the plan.
     *        Percentage should be in the degree of '100' (i.e multiply the required percent by 100)
     *        To set 10 percent, _reward_percentage should be 1000, to set 0.1 percent, it shoud be 10.
     */
    function createPlan(
        string memory _name,
        uint256 _minimum_stake,
        uint256 _duration,
        uint256 _reward_percentage
    ) external onlyOwner {
        require(_duration > 0, "LpStaking: Duration in weeks can't be zero");
        require(_minimum_stake > 0, "LpStaking: Minimum stake can't be zero");
        require(
            _reward_percentage > 0,
            "LpStaking: Total reward percentage can't be zero"
        );
        require(plans[_name].state == 0, "LpStaking: Plan already exists");

        Plan storage plan = plans[_name];

        plan.name = _name;
        plan.minimumStake = _minimum_stake;
        plan.durationInDays = _duration;
        plan.rewardPercentage = _reward_percentage;
        plan.createdAt = block.timestamp;
        plan.state = 1;

        emit PlanCreated(plan.name, plan.durationInDays, plan.rewardPercentage);
    }

    function deletePlan(string memory _name) external onlyOwner {
        require(plans[_name].state > 0, "LpStaking: Plan not found");
        require(plans[_name].usageCount == 0, "LpStaking: Plan is in use");

        delete plans[_name];

        emit PlanDeleted(_name);
    }

    /*
     * @notice A method to disable a plan. No more new stakes will be added with this plan.
     * @param _name The plan name to disable
     */
    function disablePlan(string memory _name) external onlyOwner {
        require(plans[_name].state > 0, "LpStaking: Plan doesn't exist");
        plans[_name].state = 2; //Disable
    }

    /**
     * @notice A method to retrieve the plan with the name.
     * @param _name The plan to retrieve
     */
    function getPlanInfo(string memory _name)
       external 
        view
        returns (
            uint256 minimumStake,
            uint256 duration,
            uint256 rewardPercentage,
            uint256 usageCount,
            uint8 state
        )
    {
        Plan storage plan = plans[_name];

        if (plan.state > 0) {
            minimumStake = plan.minimumStake;
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
        if (block.timestamp >= (_time + _duration * 1 days))
            return true;
        else
            return false;
    }

    function getUserStakedAmount(address stakeHolder)
        external
        view
        returns (uint256 stakedAmount)
    {
        uint256 i;

        for (i = 0; i < MAX_NUM_OF_STAKES_PER_USER; i++)
            if (stakes[stakeHolder][i].state == 1) {
		stakedAmount = stakedAmount.add(stakes[stakeHolder][i].amount); 
	    }
    }
}

// SPDX-License-Identifier: MIT
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