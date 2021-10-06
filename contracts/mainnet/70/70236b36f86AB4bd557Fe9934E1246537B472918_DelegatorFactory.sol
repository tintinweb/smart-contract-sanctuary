// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and making it call a
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

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IGovernanceToken.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Delegator Contract
 * @author Cryptex.Finance
 * @notice Contract in charge of handling delegations.
 */

contract Delegator is Ownable {
   /* ========== STATE VARIABLES ========== */

   /// @notice Address of the staking governance token
   address public immutable token;

   /// @notice Tracks the amount of staked tokens per user
   mapping(address => uint256) public stakerBalance;

   /* ========== CONSTRUCTOR ========== */

   /**
    * @notice Constructor
    * @param delegatee_ address
    * @param token_ address
    * @dev when created delegates all it's power to delegatee_ and can't be changed later
    * @dev sets delegator factory as owner
    */
   constructor(address delegatee_, address token_) {
      require(
         delegatee_ != address(0) && token_ != address(0),
         "Address can't be 0"
      );
      require(IGovernanceToken(token_).decimals() == 18, "Decimals must be 18");
      token = token_;
      IGovernanceToken(token_).delegate(delegatee_);
   }

   /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @notice Increases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be staked and delegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred from the user to this contract
    */
   function stake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] += amount_;
   }

   /**
    * @notice Decreases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be withdrawn and undelegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred back to the user from this contract
    */
   function removeStake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] -= amount_;
      require(
         IGovernanceToken(token).transfer(staker_, amount_),
         "Transfer failed"
      );
   }

   /* ========== VIEWS ========== */

   /// @notice returns the delegatee of this contract
   function delegatee() external returns (address) {
      return IGovernanceToken(token).delegates(address(this));
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IGovernanceToken.sol";
import "./Delegator.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title Delegator Contract Factory
 * @author Cryptex.Finance
 * @notice Contract in charge of generating Delegator contracts, handling delegations and CTX balance map, rewards.
 */

contract DelegatorFactory is Ownable, ReentrancyGuard {
   /* ========== STATE VARIABLES ========== */

   /// @notice Address of the staking governance token
   address public immutable stakingToken;

   /// @notice Address of the reward token
   address public immutable rewardsToken;

   /// @notice Minimum wait time before removing stake
   uint256 public waitTime;

   /// @notice Tracks the period where users stop earning rewards
   uint256 public periodFinish = 0;
   uint256 public rewardRate = 0;

   /// @notice How long the rewards lasts, it updates when more rewards are added
   uint256 public rewardsDuration = 186 days;

   /// @notice Last time rewards were updated
   uint256 public lastUpdateTime;

   /// @notice Amount of reward calculated per token stored
   uint256 public rewardPerTokenStored;

   /// @notice Track the rewards paid to users
   mapping(address => uint256) public userRewardPerTokenPaid;

   /// @notice Tracks the user rewards
   mapping(address => uint256) public rewards;

   /// @notice Tracks the address of a delegatee with a delegator contract address
   mapping(address => address) public delegatorToDelegatee;

   /// @notice Tracks the delegator contract address from delegatee address
   mapping(address => address) public delegateeToDelegator;

   /// @notice Tracks if address is an official delegator
   mapping(address => bool) public delegators;

   /// @notice Tracks minimum wait time the account has to wait before removing stake
   mapping(address => mapping(address => uint256)) public stakerWaitTime;

   /// @dev Tracks the total supply of staked tokens
   uint256 private _totalSupply;

   /// @dev Tracks the amount of staked tokens per user
   mapping(address => uint256) private _balances;

   /* ========== EVENTS ========== */

   /// @notice An event emitted when a Delegator is created
   event DelegatorCreated(address indexed delegator, address indexed delegatee);

   /// @notice An event emitted when an user has staked and delegated
   event Staked(
      address indexed delegator,
      address indexed delegatee,
      uint256 amount
   );

   /// @notice An event emitted when an user removes stake and undelegated
   event Withdrawn(
      address indexed delegator,
      address indexed delegatee,
      uint256 amount
   );

   /// @notice An event emitted when the minimum wait time is updated
   event WaitTimeUpdated(uint256 waitTime);

   /// @notice An event emitted when a reward is added
   event RewardAdded(uint256 reward);

   /// @notice An event emitted when reward is paid to a user
   event RewardPaid(address indexed user, uint256 reward);

   /// @notice An event emitted when the rewards duration is updated
   event RewardsDurationUpdated(uint256 newDuration);

   /* ========== CONSTRUCTOR ========== */

   /**
    * @notice Constructor
    * @param stakingToken_ address
    * @param rewardsToken_ address
    * @param waitTime_ uint256
    * @param timelock_ address
    * @dev transfers ownership to timelock
    */
   constructor(
      address stakingToken_,
      address rewardsToken_,
      uint256 waitTime_,
      address timelock_
   ) {
      require(
         stakingToken_ != address(0) &&
            rewardsToken_ != address(0) &&
            timelock_ != address(0),
         "Address can't be 0"
      );
      require(
         IGovernanceToken(stakingToken_).decimals() == 18 &&
            IGovernanceToken(rewardsToken_).decimals() == 18,
         "Decimals must be 18"
      );
      stakingToken = stakingToken_;
      rewardsToken = rewardsToken_;
      waitTime = waitTime_;
      transferOwnership(timelock_);
   }

   /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @notice Updates the reward and time on call.
    * @param account_ address
    */
   function updateReward(address account_) private {
      rewardPerTokenStored = rewardPerToken();
      lastUpdateTime = lastTimeRewardApplicable();

      if (account_ != address(0)) {
         rewards[account_] = currentEarned(account_);
         userRewardPerTokenPaid[account_] = rewardPerTokenStored;
      }
   }

   /**
    * @notice Notifies the contract that reward has been added to be given.
    * @param reward_ uint
    * @dev Only owner  can call it
    * @dev Increases duration of rewards
    */
   function notifyRewardAmount(uint256 reward_) external onlyOwner {
      updateReward(address(0));
      if (block.timestamp >= periodFinish) {
         rewardRate = reward_ / rewardsDuration;
      } else {
         uint256 remaining = periodFinish - block.timestamp;
         uint256 leftover = remaining * rewardRate;
         rewardRate = (reward_ + leftover) / rewardsDuration;
      }

      lastUpdateTime = block.timestamp;
      periodFinish = block.timestamp + rewardsDuration;

      // Ensure the provided reward amount is not more than the balance in the contract.
      // This keeps the reward rate in the right range, preventing overflows due to
      // very high values of rewardRate in the earned and rewardsPerToken functions;
      // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
      uint256 balance = IGovernanceToken(rewardsToken).balanceOf(address(this));
      require(
         rewardRate <= balance / rewardsDuration,
         "Provided reward too high"
      );
      emit RewardAdded(reward_);
   }

   /**
    * @notice  Updates the reward duration
    * @param rewardsDuration_ uint
    * @dev Only owner can call it
    * @dev Previous rewards must be complete
    */
   function setRewardsDuration(uint256 rewardsDuration_) external onlyOwner {
      require(
         block.timestamp > periodFinish,
         "Previous rewards period must be complete before changing the duration for the new period"
      );
      rewardsDuration = rewardsDuration_;
      emit RewardsDurationUpdated(rewardsDuration);
   }

   /**
    * @notice Transfers to the caller the current amount of rewards tokens earned.
    * @dev updates rewards on call
    */
   function getReward() external nonReentrant {
      updateReward(msg.sender);
      uint256 reward = rewards[msg.sender];
      if (reward > 0) {
         rewards[msg.sender] = 0;
         require(
            IGovernanceToken(rewardsToken).transfer(msg.sender, reward),
            "Transfer Failed"
         );
         emit RewardPaid(msg.sender, reward);
      }
   }

   /**
    * @notice Creates a new delegator contract that delegates all votes to delegatee_
    * @param delegatee_ address that will be receiving all votes
    * @dev only one delegator contract pointing to the same delegatee can exist
    */
   function createDelegator(address delegatee_) external {
      require(delegatee_ != address(0), "Delegatee can't be 0");
      require(
         delegateeToDelegator[delegatee_] == address(0),
         "Delegator already created"
      );
      Delegator delegator = new Delegator(delegatee_, stakingToken);
      delegateeToDelegator[delegatee_] = address(delegator);
      delegatorToDelegatee[address(delegator)] = delegatee_;
      delegators[address(delegator)] = true;
      emit DelegatorCreated(address(delegator), delegatee_);
   }

   /**
    * @notice Stakes to delegator_ the amount_ specified
    * @param delegator_ contract address where to send the amount_
    * @param amount_ uint to be staked and delegated
    * @dev Delegator must be valid and amount has to be greater than 0
    * @dev amount_ is transferred to the delegator contract and staker starts earning rewards if active
    * @dev updates rewards on call
    */
   function stake(address delegator_, uint256 amount_) external nonReentrant {
      require(delegators[delegator_], "Not a valid delegator");
      require(amount_ > 0, "Amount must be greater than 0");
      updateReward(msg.sender);
      _totalSupply = _totalSupply + amount_;
      _balances[msg.sender] = _balances[msg.sender] + amount_;
      Delegator d = Delegator(delegator_);
      d.stake(msg.sender, amount_);
      stakerWaitTime[msg.sender][delegator_] = block.timestamp + waitTime;
      require(
         IGovernanceToken(stakingToken).transferFrom(
            msg.sender,
            delegator_,
            amount_
         ),
         "Transfer Failed"
      );
      emit Staked(delegator_, msg.sender, amount_);
   }

   /**
    * @notice Removes amount_ from delegator_
    * @param delegator_ contract address where to remove the stake from
    * @param amount_ uint to be removed from stake and undelegated
    * @dev Delegator must be valid and amount has to be greater than 0
    * @dev amount_ must be <= that current user stake
    * @dev amount_ is transferred from the  delegator contract to the staker
    * @dev updates rewards on call
    * @dev requires that at least waitTime has passed since delegation to unDelegate
    */
   function withdraw(address delegator_, uint256 amount_)
      external
      nonReentrant
   {
      require(delegators[delegator_], "Not a valid delegator");
      require(amount_ > 0, "Amount must be greater than 0");
      require(
         block.timestamp >= stakerWaitTime[msg.sender][delegator_],
         "Need to wait the minimum staking period"
      );
      updateReward(msg.sender);
      _totalSupply = _totalSupply - amount_;
      _balances[msg.sender] = _balances[msg.sender] - amount_;
      Delegator d = Delegator(delegator_);
      d.removeStake(msg.sender, amount_);
      emit Withdrawn(delegator_, msg.sender, amount_);
   }

   /**
    * @notice updates the min wait time between delegation and unDelegation
    * @param waitTime_ uint new wait time
    * @dev only the owner can call it
    */
   function updateWaitTime(uint256 waitTime_) external onlyOwner {
      waitTime = waitTime_;
      emit WaitTimeUpdated(waitTime_);
   }

   /* ========== VIEWS ========== */

   /**
    * @notice Returns the amount of reward tokens a user has earned.
    * @param account_ address
    */
   function currentEarned(address account_) private view returns (uint256) {
      return
         (_balances[account_] *
            (rewardPerTokenStored - userRewardPerTokenPaid[account_])) /
         1e18 +
         rewards[account_];
   }

   /// @notice Returns the total amount of staked tokens.
   function totalSupply() external view returns (uint256) {
      return _totalSupply;
   }

   /**
    * @notice Returns the amount of staked tokens from specific user
    * @param account_ address
    */
   function balanceOf(address account_) external view returns (uint256) {
      return _balances[account_];
   }

   /// @notice Returns reward rate for a duration
   function getRewardForDuration() external view returns (uint256) {
      return rewardRate * rewardsDuration;
   }

   /// @notice Returns the minimum between current block timestamp or the finish period of rewards.
   function lastTimeRewardApplicable() public view returns (uint256) {
      return min(block.timestamp, periodFinish);
   }

   /// @notice Returns the calculated reward per token deposited.
   function rewardPerToken() public view returns (uint256) {
      if (_totalSupply == 0) {
         return rewardPerTokenStored;
      }

      return
         rewardPerTokenStored +
         ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) /
         _totalSupply;
   }

   /**
    * @notice Returns the amount of reward tokens a user has earned.
    * @param account_ address
    */
   function earned(address account_) public view returns (uint256) {
      return
         (_balances[account_] *
            (rewardPerToken() - userRewardPerTokenPaid[account_])) /
         1e18 +
         rewards[account_];
   }

   /**
    * @notice Returns the minimum between two variables
    * @param a_ uint
    * @param b_ uint
    */
   function min(uint256 a_, uint256 b_) public pure returns (uint256) {
      return a_ < b_ ? a_ : b_;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IGovernanceToken {
   function delegate(address delegatee) external;

   function delegates(address delegator) external returns (address);

   function transfer(address dst, uint256 rawAmount) external returns (bool);

   function transferFrom(
      address src,
      address dst,
      uint256 rawAmount
   ) external returns (bool);

   function balanceOf(address src) external returns (uint256);

   function decimals() external returns (uint8);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}