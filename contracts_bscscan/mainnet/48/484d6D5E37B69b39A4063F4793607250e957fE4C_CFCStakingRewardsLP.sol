/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
// Crypto Fight Club
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract CFCStakingRewardsLP is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;
    uint256 public totalShares;
    uint256 public totalStakes;
    address public nft;
    uint256 public constant MIN_STAKE_DURATION = 1 days;
    uint256 public constant FULL_STAKE_LENGTH = 1820 days;
    uint256 public constant GRACE_PERIOD = 2 weeks;
    uint256 public constant LATE_PENALTY = 143; // 0.143%, means need to divide by 100000

    struct StakeStore {
        uint256 stakeID;
        uint256 principle;
        uint256 shares;
        uint256 userRewardPerSharePaid;
        uint256 createdAt;
        uint256 duration;
    }

    mapping(uint256 => StakeStore[]) public stakeLists;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        nft = msg.sender;
    }

    /* ========== VIEWS ========== */
    modifier isNFTContract() {
        require(msg.sender == nft, "Only NFT Contract has access");
        _;
    }

    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(blockTime(), periodFinish);
    }

    function rewardPerShare() public view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerShareStored;
        }
        return
            rewardPerShareStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalShares)
            );
    }

    function earned(uint256 tokenID, uint256 stakeIndex) public view returns (uint256) {
        return stakeLists[tokenID][stakeIndex].shares.mul(
                    rewardPerShare().sub(stakeLists[tokenID][stakeIndex].userRewardPerSharePaid)
                ).div(1e18);
    }

    function bonusCalculator(uint256 amount, uint256 duration) public pure returns (uint256) {
        uint256 benchmarkTime = 1 days;
        uint256 bonus = 0;
        if (duration > benchmarkTime) {
            uint256 cappedExtraTime = duration <= FULL_STAKE_LENGTH ? duration.sub(benchmarkTime) : FULL_STAKE_LENGTH;
            // if stake amount or extra duration is too tiny, this bonus could be 0
            bonus = amount.mul(cappedExtraTime).div(FULL_STAKE_LENGTH);
        }
        return bonus;
    }

    function shareCalculator(uint256 amount, uint256 duration) public pure returns (uint256) {
        return bonusCalculator(amount, duration).add(amount);
    }

    function numOfStakes(uint256 tokenID) public view returns (uint256) {
        return stakeLists[tokenID].length;
    }

    function stakeEndTime(uint256 tokenID, uint256 stakeIndex) public view returns (uint256) {
        return stakeLists[tokenID][stakeIndex].createdAt.add(stakeLists[tokenID][stakeIndex].duration);
    }

    function latePenaltyCalculator(uint256 reward, uint256 endTime) public view returns (uint256) {
        uint256 lateTime = blockTime().sub(endTime);
        if (lateTime > GRACE_PERIOD) {
            uint256 penaltyDays = lateTime.sub(GRACE_PERIOD).div(1 days);
            // if reward is smaller than 1000 (0.000000000000001 FIGHT), penalty will always be 0
            uint256 penalty = reward.mul(penaltyDays).mul(LATE_PENALTY).div(100000);
            return Math.min(reward, penalty);
        } else {
            return 0;
        }
    }

    // for convieniences
    function latePenalty(uint256 tokenID, uint256 stakeIndex) external view returns (uint256) {
        return latePenaltyCalculator(earned(tokenID, stakeIndex), stakeEndTime(tokenID, stakeIndex));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 tokenID, uint256 amount, uint256 duration) external isNFTContract nonReentrant updateReward {
        require(amount > 0, "Cannot stake 0");
        require(duration >= MIN_STAKE_DURATION, "Stake duration less than mininum");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        totalStakes = totalStakes.add(amount);
        uint shares = shareCalculator(amount, duration);
        totalShares = totalShares.add(shares);
        stakeLists[tokenID].push(
            StakeStore({
                stakeID: numOfStakes(tokenID),
                principle: amount,
                shares: shares,
                userRewardPerSharePaid: rewardPerShareStored,
                createdAt: blockTime(),
                duration: duration
            })
        );
        emit Staked(tokenID, amount);
    }

    function unstake(uint256 tokenID, uint256 stakeIndex, address target) external isNFTContract validStakeIndex(tokenID, stakeIndex) nonReentrant updateReward {
        require(stakeEndTime(tokenID, stakeIndex) <= blockTime(), "Still in lock");
        uint256 reward = earned(tokenID, stakeIndex);
        uint256 penalty = 0;
        if (reward > 0) {
            // apply late penalty if any
            penalty = latePenaltyCalculator(reward, stakeEndTime(tokenID, stakeIndex));
            uint256 finalReward = reward.sub(penalty);
            rewardsToken.safeTransfer(target, finalReward);
            emit RewardPaid(target, tokenID, finalReward);
        }
        _unstakePrinciple(tokenID, stakeIndex, target);
        _handlePenalty(penalty);
    }

    // this will give up all rewards and should only use for special purpose
    function unstakeWithoutReward(uint256 tokenID, uint256 stakeIndex, address target) external isNFTContract validStakeIndex(tokenID, stakeIndex) nonReentrant updateReward {
        require(stakeEndTime(tokenID, stakeIndex) <= blockTime(), "Still in lock");
        _unstakePrinciple(tokenID, stakeIndex, target);
    }

    function emergencyUnstake(uint256 tokenID, uint256 stakeIndex, address target) external isNFTContract validStakeIndex(tokenID, stakeIndex) nonReentrant updateReward {
        require(stakeEndTime(tokenID, stakeIndex) > blockTime(), "You can unstake noramlly");
        uint256 reward = earned(tokenID, stakeIndex);
        uint256 penalty = 0;
        if (reward > 0) {
            // if reward is less than 2 (0.000000000000000002 FIGHT), there is no penalty
            uint256 afterPenalty = reward.div(2);
            penalty = reward.sub(afterPenalty);
            rewardsToken.safeTransfer(target, afterPenalty);
            emit RewardPaid(target, tokenID, afterPenalty);
      }
        _unstakePrinciple(tokenID, stakeIndex, target);
        _handlePenalty(penalty);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function _unstakePrinciple(uint256 tokenID, uint256 stakeIndex, address target) internal {
      uint256 amount = stakeLists[tokenID][stakeIndex].principle;
      uint256 shares = stakeLists[tokenID][stakeIndex].shares;
      totalStakes = totalStakes.sub(amount);
      totalShares = totalShares.sub(shares);
      uint256 lastIndex = stakeLists[tokenID].length - 1;

      if (stakeIndex != lastIndex) {
          /* Copy last element to the requested element's "hole" */
          stakeLists[tokenID][stakeIndex] = stakeLists[tokenID][lastIndex];
      }

      stakeLists[tokenID].pop();
      stakingToken.safeTransfer(target, amount);
      emit Withdrawn(target, tokenID, amount);
    }

    function _handlePenalty(uint256 penalty) internal {
      if (penalty > 0) {
        if(totalShares != 0) {
          _redistributeReward(penalty);
        } else { // last staker penalty burn
          rewardsToken.burn(penalty);
        }
      }
    }

    function _redistributeReward(uint256 amount) internal {
      rewardPerShareStored = rewardPerShareStored.add(
              amount.mul(1e18).div(totalShares)
          );
    }
    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward, uint256 rewardsDuration) external onlyOwner updateReward() {
        require(blockTime().add(rewardsDuration) >= periodFinish, "Cannot reduce existing period");

        if (blockTime() >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(blockTime());
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = blockTime();
        periodFinish = blockTime().add(rewardsDuration);
        emit RewardAdded(reward, periodFinish);
    }

    // onlyOwner modifier is not necessary but still there to ensure it only run once
    function setNFTContract(address _nft) external onlyOwner {
        require(nft == msg.sender, 'Only run this once');
        nft = _nft;
    }

    function bigPayDay(uint256 amount) external onlyOwner updateReward {
      require(totalShares > 0, "no users");
      rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
      _redistributeReward(amount);
    }

    /* ========== MODIFIERS ========== */
    modifier validStakeIndex(uint256 tokenID, uint256 stakeIndex) {
        require(numOfStakes(tokenID) > stakeIndex, "StakeID does not exist");
        _;
    }

    modifier updateReward() {
        rewardPerShareStored = rewardPerShare();
        lastUpdateTime = lastTimeRewardApplicable();
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 periodFinish);
    event Staked(uint256 tokenID, uint256 amount);
    event Withdrawn(address indexed target, uint256 tokenID, uint256 amount);
    event RewardPaid(address indexed target, uint256 tokenID, uint256 reward);
}