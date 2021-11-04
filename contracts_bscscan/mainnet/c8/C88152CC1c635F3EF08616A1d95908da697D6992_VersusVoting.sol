/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: VersusVoting.sol


pragma solidity 0.8.9;



contract VersusVoting is Ownable {

  enum Pool {
    none,
    one,
    two
  }

  struct Vote {
    Pool pool;
    uint256 stake;
  }

  /**
    * @notice Get sum if want to get final balance at epoch end time.
   */
  struct PoolBalance {
    uint256 startedWith;  //  balance at epoch beginning
    uint256 staked;       //  stakes amount
  }

  struct EpochResult {
    Pool poolWinner;
    uint256 devFee;
  }

  address public versusToken;
  address payable public devFeeReceiver;

  uint256 public devFeePercentage;  //  5%
  uint256 public poolLoserBalanceToNextEpochPercentage; //  30%, balance percentage to be distributed among both pools for next epoch (startedWith). Remainder gets distributed among voters in winner pool (70%).

  uint256 public currentEpoch;
  uint256 public currentEpochStartedAt;
  uint256 public epochDuration;
  uint256 public minStake;
  uint256 public versusBonus;
  uint256 public bnbRewardsWithdrawn;

  mapping(address => uint256) public pendingVersusTokenBonus;                   //  (voter => amount)
  mapping(uint256 => EpochResult) public epochResult;                           //  (epoch => EpochResult)
  mapping(uint256 => mapping(address => Vote)) private voteForVoter;            //  (epoch => (voter => Vote))
  mapping(uint256 => mapping(Pool => PoolBalance)) private balanceForPool;      //  (epoch => (pool => PoolBalance))
  mapping(uint256 => mapping(Pool => address[])) private votersForPool;         //  (epoch => (pool => voters[]))
  mapping(address => uint256[]) private epochListForVoter;                      //  (voter => [epoch]), epochs particapated
  mapping(address => uint256) public indexToStartCalculationsForVoter;          //  (voter => idx), index in epochListForVoter

  event Voted(uint8 pool, address voter, uint256 amount);
  event EpochFinished(uint256 epoch);
  event DevFeeTransferred(address to, uint256 amount);

  modifier onlyValidEpoch(uint256 _epoch) {
    require(_epoch <= currentEpoch, "Wrong epoch");
    _;
  }

  modifier onlyValidPool(Pool _pool) {
    require(_pool == Pool.one || _pool == Pool.two, "Wrong pool");
    _;
  }

  /***
    * @notice: Approve this Smart Contract to transferFrom owner VERSUS tokens.
    * @dev Constructor function.
    * @param _devFeeReceiver Receiver of devFee.
    * @param _versusToken VersusToken address.
   */
  constructor(address _devFeeReceiver, address _versusToken) {
    versusBonus = 0xDE0B6B3A7640000; //  1 VERSUS
    minStake = 0x16345785D8A0000;    //  0.1 BNB
    epochDuration = 10780 seconds;
    poolLoserBalanceToNextEpochPercentage = 30;
    devFeePercentage = 5;

    versusToken = _versusToken;
    devFeeReceiver = payable(_devFeeReceiver);
    currentEpochStartedAt = block.timestamp;
  }

  /***
    * @dev Destroys this Smart Contract.
   */
  function kill() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }

  /***
    * @dev Updates percentage to be distributed among both pools for next epoch (startedWith).
    * @param _percentage Percentage to be used.
   */
  function updatePoolLoserBalanceToNextEpochPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage > 0 && _percentage <= 100, "Wrong _percentage");
    poolLoserBalanceToNextEpochPercentage = _percentage;
  }

  /***
    * @dev Updates dev fee percentage.
    * @param _percentage Percentage to be used.
   */
  function updateDevFeePercentage(uint256 _percentage) external onlyOwner {
    require(_percentage > 0 && _percentage <= 100, "Wrong _percentage");
    devFeePercentage = _percentage;
  }

  /***
    * @dev Updates address as dev fee receiver.
    * @param _address Receiver address.
   */
  function updateDevFeeReceiver(address _address) external onlyOwner {
    require(_address != address(0), "Wrong _address");
    devFeeReceiver = payable(_address);
  }

  /***
   * @dev Updates epoch duration.
   * @param _duration Duration.
   */
  function updateEpochDuration(uint256 _duration) external onlyOwner {
    require(_duration > 0, "Wrong _duration");
    epochDuration = _duration;
  }

  /***
   * @dev Updates Versus token bonus amount.
   * @param _amount Versus amount.
   */
  function updateVersusBonus(uint256 _amount) external onlyOwner {
    versusBonus = _amount;
  }

  /***
   * @dev Updates min stake amount.
   * @param _minStake Min stake amount.
   */
  function updateMinStake(uint256 _minStake) external onlyOwner {
    require(_minStake > 0, "Wrong _minStake");
    minStake = _minStake;
  }

  /***
   * @dev Gets PoolBalance struct for the pool.
   * @param _epoch Epoch id.
   * @param _pool Pool.
   * @return PoolBalance struct.
   */
  function getPoolBalance(uint256 _epoch, Pool _pool) external view onlyValidEpoch(_epoch) onlyValidPool(_pool) returns (PoolBalance memory) {
    return balanceForPool[_epoch][_pool];
  }

  /***
   * @dev Gets balance total amount for the pool.
   * @param _epoch Epoch id.
   * @param _pool Pool.
   * @return Balance total amount.
   */
  function getPoolBalanceTotal(uint256 _epoch, Pool _pool) public view onlyValidEpoch(_epoch) onlyValidPool(_pool) returns (uint256) {
    return balanceForPool[_epoch][_pool].startedWith + balanceForPool[_epoch][_pool].staked;
  }

  /***
   * @dev Gets Vote for the voter.
   * @param _epoch Epoch id.
   * @param _address Voter address.
   * @return Vote struct.
   */
  function getVoteForVoter(uint256 _epoch, address _address) external view onlyValidEpoch(_epoch) returns (Vote memory) {
    return voteForVoter[_epoch][_address];
  }

  /***
   * @dev Gets voters for the pool.
   * @param _epoch Epoch id.
   * @param _pool Pool.
   * @return Voters for pool.
   */
  function getVotersForPool(uint256 _epoch, Pool _pool) public view onlyValidEpoch(_epoch) onlyValidPool(_pool) returns (address[] memory) {
    return votersForPool[_epoch][_pool];
  }

  /***
   * @dev Gets voters count for the pool.
   * @param _epoch Epoch id.
   * @param _pool Pool.
   * @return Voters for pool.
   */
  function getVotersCountForPool(uint256 _epoch, Pool _pool) public view returns (uint256) {
    return getVotersForPool(_epoch, _pool).length;
  }

  /***
   * @dev Gets participated epoch list for voter.
   * @param _address Voter address.
   * @return Epoch list.
   */
  function getEpochListForVoter(address _address) public view returns (uint256[] memory) {
    return epochListForVoter[_address];
  }

  /***
   * @dev Makes vote for the pool.
   * @param _pool Pool.
   */
  function makeVote(Pool _pool) external payable onlyValidPool(_pool) {
    require(msg.value >= minStake, "Wrong amount");
    require(block.timestamp < currentEpochStartedAt + epochDuration, "Voting is closed. Transaction declined.");

    Vote storage vote = voteForVoter[currentEpoch][msg.sender];
    if (vote.pool == Pool.none) {
      vote.pool = _pool;
      votersForPool[currentEpoch][_pool].push(msg.sender);
      epochListForVoter[msg.sender].push(currentEpoch);
    } else {
      require(vote.pool == _pool, "Other pool before");
    }

    //  stake
    vote.stake += msg.value;
    balanceForPool[currentEpoch][_pool].staked += msg.value;

    //  token bonus
    if (versusBonus > 0) {
      pendingVersusTokenBonus[msg.sender] += versusBonus;
    }

    emit Voted(uint8(_pool), msg.sender, msg.value);
  }

  /**
    * @dev Finishes ongoing epoch & performs calculations.
   */
  function finishEpoch() external onlyOwner {

    if (balanceForPool[currentEpoch][Pool.one].staked > balanceForPool[currentEpoch][Pool.two].staked) {
      performCalculationsForPoolWinner(Pool.one);
      performCalculationsForPoolLoser(Pool.two);
    } else if (balanceForPool[currentEpoch][Pool.one].staked < balanceForPool[currentEpoch][Pool.two].staked) {
      performCalculationsForPoolWinner(Pool.two);
      performCalculationsForPoolLoser(Pool.one);
    } else {
      //  draw
      balanceForPool[currentEpoch + 1][Pool.one].startedWith = balanceForPool[currentEpoch][Pool.one].startedWith;
      balanceForPool[currentEpoch + 1][Pool.two].startedWith = balanceForPool[currentEpoch][Pool.two].startedWith;
    }

    emit EpochFinished(currentEpoch);

    currentEpoch += 1;
    currentEpochStartedAt = block.timestamp;
  }

  /***
    * @dev Performs calculations for pool winner.
    * @param _winnerId Pool that won.
   */
  function performCalculationsForPoolWinner(Pool _winnerId) private {
    uint256 balanceWinner = getPoolBalanceTotal(currentEpoch, _winnerId);
    
    //  5% 
    uint256 devFee = (balanceWinner * devFeePercentage) / 100;
    epochResult[currentEpoch] = EpochResult(_winnerId, devFee);

    devFeeReceiver.transfer(devFee);
    emit DevFeeTransferred(devFeeReceiver, devFee);

    //  95% should be PROPORTIONALLY distributed among voters in this pool.
  }

  /***
    * @dev Performs calculations for pool loser.
    * @param _loserId Pool that lost.
   */
  function performCalculationsForPoolLoser(Pool _loserId) private {
    uint256 balanceLoser = getPoolBalanceTotal(currentEpoch, _loserId);
    if (balanceLoser == 0) {
      return;
    }

    //  30%
    uint256 singlePoolAmount = (((balanceLoser * poolLoserBalanceToNextEpochPercentage) / 100)) / 2;
    balanceForPool[currentEpoch + 1][Pool.one].startedWith = singlePoolAmount;
    balanceForPool[currentEpoch + 1][Pool.two].startedWith = singlePoolAmount;

    //  70% should be PROPORTIONALLY distributed among voters in winning pool.
  }

  /***
    * @dev Calculates pending reward for player.
    * @param _loopLimit Limit for epoch looping. Use 0 for all epochs until now.
    * @return amount Reward amount.
    * @return updatedStartIdx Updated epoch idx to start following calculations.
   */
  function calculatePendingReward(uint256 _loopLimit) public view returns (uint256 amount, uint256 updatedStartIdx) {
    uint256[] memory epochList = epochListForVoter[msg.sender];
    if (epochList.length == 0) {
      return(0, 0);
    }

    uint256 startIdx = indexToStartCalculationsForVoter[msg.sender];
    if (startIdx >= epochList.length) {
      return(0, 0);
    }

    uint256 stopIdx = (_loopLimit == 0) ? epochList.length - 1 : (startIdx + _loopLimit) - 1;
    require(stopIdx < epochList.length, "Wrong stopIdx");
    
    if (epochList[stopIdx] == currentEpoch) {
      if (stopIdx == 0) {
        return(0, 0);
      }
      stopIdx --;
    }

    updatedStartIdx = stopIdx + 1;

    for (uint256 idx = startIdx; idx <= stopIdx; idx ++) {
      uint256 epoch = epochList[idx];

      Vote storage vote = voteForVoter[epoch][msg.sender];
      EpochResult storage result = epochResult[epoch];

      if (result.poolWinner == vote.pool) {
        uint256 rewardPoolWinner = _calculateRewardPoolWinnerForEpoch(epoch, result.poolWinner);
        Pool loserPool = (result.poolWinner == Pool.one) ? Pool.two : Pool.one;
        uint256 rewardPoolLoser = _calculateRewardPoolLoserForEpoch(epoch, loserPool);
        uint256 myPortion = stakePortionFor(epoch, result.poolWinner);
        uint256 reward = ((rewardPoolWinner + rewardPoolLoser) * myPortion) / 100 ether;
        amount += reward;
      } else if (result.poolWinner == Pool.none) {
        amount += vote.stake;
      }
    }
  }

  /***
    * @dev Calculates reward for player in winner pool.
    * @param _epoch Epoch.
    * @param _pool Winner pool.
    * @return Reward amount.
   */
  function _calculateRewardPoolWinnerForEpoch(uint256 _epoch, Pool _pool) private view returns(uint256) {
    uint256 balanceTotal = getPoolBalanceTotal(_epoch, _pool);
    uint256 devFee = epochResult[_epoch].devFee;
    return balanceTotal - devFee;
  }

  /***
    * @dev Calculates loser pool chunk to be received by player in winner pool.
    * @param _epoch Epoch.
    * @param _pool Looser pool.
    * @return Chunk amount.
   */
  function _calculateRewardPoolLoserForEpoch(uint256 _epoch, Pool _pool) private view returns(uint256) {
    uint256 balanceLoser = getPoolBalanceTotal(_epoch, _pool);
    if (balanceLoser == 0) {
      return 0;
    }

    return (balanceLoser * (100 - poolLoserBalanceToNextEpochPercentage)) / 100;
  }

  /***
    * @notice Decimals are lost in Solidity, thus use 1 eth for precision.
    * @dev Calculates stake percentage.
    * @param _epoch Epoch.
    * @param _pool Pool.
    * @return Stake percentage.
   */
  function stakePortionFor(uint256 _epoch, Pool _pool) private view returns(uint256) {
    return (voteForVoter[_epoch][msg.sender].stake * 100 ether) / balanceForPool[_epoch][_pool].staked; //  100 ether == 100 * 1 eth (for precision to wei)
  }

  /**
    * @dev Withdraws pending reward.
    * @param _loopLimit Limit for epoch looping.
   */
  function withdrawPendingReward(uint256 _loopLimit) external {
    uint256 versusBonusTmp = pendingVersusTokenBonus[msg.sender];
    if (versusBonusTmp > 0) {
      delete pendingVersusTokenBonus[msg.sender];
      IERC20(versusToken).transferFrom(owner(), msg.sender, versusBonusTmp);
    }

    (uint256 amount, uint256 updatedStartIdx) = calculatePendingReward(_loopLimit);
    if (amount > 0) {
      indexToStartCalculationsForVoter[msg.sender] = updatedStartIdx;
      bnbRewardsWithdrawn += amount;
      (payable(msg.sender)).transfer(amount);
    }

    if (versusBonusTmp == 0 && amount == 0) {
      revert("No reward");
    }
  }
}