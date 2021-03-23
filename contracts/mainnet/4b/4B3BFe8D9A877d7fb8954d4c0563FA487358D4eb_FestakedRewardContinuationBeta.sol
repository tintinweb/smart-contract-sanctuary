pragma solidity >=0.6.0 <0.8.0;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library Constants {
    address constant uniV2FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory constant uniV2Factory = IUniswapV2Factory(uniV2FactoryAddress);

    address constant uniV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(uniV2Router02Address);

    uint32 constant Future2100 = 4102448400;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library SafeAmount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256)  {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).transferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        return postBalance.sub(preBalance);
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IFestaked.sol";
import "../common/SafeAmount.sol";

/**
 * A staking contract distributes rewards.
 * One can create several TraditionalFestaking over one
 * staking and give different rewards for a single
 * staking contract.
 */
contract Festaked is IFestaked {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping (address => uint256) internal _stakes;

    string public name;
    address  public override tokenAddress;
    uint public override stakingStarts;
    uint public override stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint256 public override stakedTotal;
    uint256 public stakingCap;
    uint256 public override stakedBalance;

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    /**
     * Fixed periods. For an open ended contract use end dates from very distant future.
     */
    constructor (
        string memory name_,
        address tokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) public {
        name = name_;
        require(tokenAddress_ != address(0), "Festaking: 0 address");
        tokenAddress = tokenAddress_;

        require(stakingStarts_ > 0, "Festaking: zero staking start time");
        if (stakingStarts_ < now) {
            stakingStarts = now;
        } else {
            stakingStarts = stakingStarts_;
        }

        require(stakingEnds_ >= stakingStarts, "Festaking: staking end must be after staking starts");
        stakingEnds = stakingEnds_;

        require(withdrawStarts_ >= stakingEnds, "Festaking: withdrawStarts must be after staking ends");
        withdrawStarts = withdrawStarts_;

        require(withdrawEnds_ >= withdrawStarts, "Festaking: withdrawEnds must be after withdraw starts");
        withdrawEnds = withdrawEnds_;

        require(stakingCap_ >= 0, "Festaking: stakingCap cannot be negative");
        stakingCap = stakingCap_;
    }

    function stakeOf(address account) external override view returns (uint256) {
        return _stakes[account];
    }

    function stakeFor(address staker, uint256 amount)
    external
    override
    _positive(amount)
    _realAddress(staker)
    _realAddress(msg.sender)
    returns (bool) {
        return _stake(msg.sender, staker, amount);
    }

    /**
    * Requirements:
    * - `amount` Amount to be staked
    */
    function stake(uint256 amount)
    external
    override
    _positive(amount)
    _realAddress(msg.sender)
    returns (bool) {
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    function _stake(address payer, address staker, uint256 amount)
    virtual
    internal
    _after(stakingStarts)
    _before(stakingEnds)
    _positive(amount)
    returns (bool) {
        // check the remaining amount to be staked
        // For pay per transfer tokens we limit the cap on incoming tokens for simplicity. This might
        // mean that cap may not necessary fill completely which is ok.
        uint256 remaining = amount;
        if (stakingCap > 0 && remaining > (stakingCap.sub(stakedBalance))) {
            remaining = stakingCap.sub(stakedBalance);
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        require(remaining > 0, "Festaking: Staking cap is filled");
        require((remaining + stakedTotal) <= stakingCap, "Festaking: this will increase staking amount pass the cap");
        // Update remaining in case actual amount paid was different.
        remaining = _payMe(payer, remaining, tokenAddress);
        emit Staked(tokenAddress, staker, amount, remaining);

        // Transfer is completed
        stakedBalance = stakedBalance.add(remaining);
        stakedTotal = stakedTotal.add(remaining);
        _stakes[staker] = _stakes[staker].add(remaining);
        return true;
    }

    function _payMe(address payer, uint256 amount, address token)
    internal
    returns (uint256) {
        return _payTo(payer, address(this), amount, token);
    }

    function _payTo(address allower, address receiver, uint256 amount, address token)
    internal
    returns (uint256) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        return SafeAmount.safeTransferFrom(token, allower, receiver, amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Festaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "Festaking: negative amount");
        _;
    }

    modifier _after(uint eventTime) {
        require(now >= eventTime, "Festaking: bad timing for the request");
        _;
    }

    modifier _before(uint eventTime) {
        require(now < eventTime, "Festaking: bad timing for the request");
        _;
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./OpenEndedRewardManager.sol";
import "./IFestakeRewardManager.sol";
import "./IFestakeWithdrawer.sol";
import "../common/Constants.sol";

/**
 * Reward continuation can be used to add reward to any staking.
 * We cannot withdraw or stake from here, but we can withdrawRewards.
 * Key is to do a shaddow management of stakes on this contract.
 */
contract FestakedRewardContinuation is OpenEndedRewardManager {
    IFestaked public targetStake;
    bool initialSync = false;
    constructor(
        address targetStake_,
        address tokenAddress_,
        address rewardTokenAddress_) OpenEndedRewardManager(
            "RewardContinuation", tokenAddress_, rewardTokenAddress_, now, Constants.Future2100,
            Constants.Future2100+1, Constants.Future2100+2, 2**128) public {
            targetStake = IFestaked(targetStake_);
    }

    function initialize() public virtual returns (bool) {
        require(!initialSync, "FRC: Already initialized");
        require(now >= targetStake.stakingEnds(), 
            "FRC: Bad timing. Cannot initialize before target stake contribution is closed");
        uint256 stakedBalance_ = targetStake.stakedBalance();
        stakedTotal = stakedBalance_;
        stakedBalance = stakedBalance_;
        initialSync = true;
        return true;
    }

    /**
     * @dev Checks the current stake against the original.
     * runs a dummy withdraw or stake then calculates the rewards accordingly.
     */
    function rewardOf(address staker)
    external override view returns (uint256) {
        require(initialSync, "FRC: Run initialSync");
        if (_stakes[staker] == 0) {
            uint256 remoteStake = _remoteStake(staker);
            return _calcRewardOf(staker, stakedBalance, remoteStake);
        }
        return _calcRewardOf(staker, stakedBalance, _stakes[staker]);
    }

    function _stake(address, address, uint256)
    override
    virtual
    internal
    returns (bool)
    {
        require(false, "RewardContinuation: Stake not supported");
    }

    function withdraw(uint256) external override virtual returns (bool) {
        require(false, "RewardContinuation: Withdraw not supported");
    }

    function _addMarginalReward()
    internal override virtual returns (bool) {
        address me = address(this);
        IERC20 _rewardToken = rewardToken;
        uint256 amount = _rewardToken.balanceOf(me).sub(rewardsTotal);
        // We don't carry stakes here
        // if (address(_rewardToken) == tokenAddress) {
        //     amount = amount.sub(...);
        // }
        if (amount == 0) {
            return true; // No reward to add. Its ok. No need to fail callers.
        }
        rewardsTotal = rewardsTotal.add(amount);
        fakeRewardsTotal = fakeRewardsTotal.add(amount);
    }

    function withdrawRewardsFor(address staker) external returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewardsForRemote(staker);
    }

    function withdrawRewards() external override returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewardsForRemote(msg.sender);
    }

    /**
     * @dev it is important to know there will be no more stake on the remote side
     */
    function _withdrawRewardsForRemote(address staker) internal returns(uint256) {
        require(initialSync, "FRC: Run initialSync");
        uint256 currentStake = Festaked._stakes[staker];
        uint256 remoteStake = _remoteStake(staker);
        uint256 stakedBalance_ = targetStake.stakedBalance();
        // Make sure total staked hasnt gone up on the other side.
        require(stakedBalance_ <= stakedTotal, "FRC: Remote side staked total has increased!");
        require(currentStake == 0 || remoteStake <= currentStake, "FRC: Cannot stake more on the remote side");
        if (currentStake == 0) {
            // First time. Replicate the stake.
            _stakes[staker] = remoteStake;
            _withdrawRewards(staker);
        } else if (remoteStake < currentStake) {
            // This means user has withdrawn remotely! Run the withdraw here to match remote.
            uint256 amount = currentStake.sub(remoteStake);
            _withdraw(staker, amount);
            require(_stakes[staker] == remoteStake, "FRC: Wirhdraw simulation didn't happen correctly!");
        } else {
            _withdrawRewards(staker);
        }
    }

    function _withdraw(address _staker, uint256 amount)
    internal override virtual returns (bool) {
        uint256 actualPay = _withdrawOnlyUpdateState(_staker, amount);
        // We do not have main token to pay. This is just a simulation of withdraw
        // IERC20(tokenAddress).safeTransfer(_staker, amount);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, 0, actualPay);
        return true;
    }

    function _remoteStake(address staker) internal view returns (uint256){
        return targetStake.stakeOf(staker);
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeRewardManager {
    /**
     * @dev legacy add reward. To be used by contract support time limitted rewards.
     */
    function addReward(uint256 rewardAmount) external returns (bool);

    /**
     * @dev withdraw rewards for the user.
     * The only option is to withdraw all rewards is one go.
     */
    function withdrawRewards() external returns (uint256);

    /**
     * @dev marginal rewards is to be used by contracts supporting ongoing rewards.
     * Send the reward to the contract address first.
     */
    function addMarginalReward() external returns (bool);

    function rewardToken() external view returns (IERC20);

    function rewardsTotal() external view returns (uint256);

    /**
     * @dev returns current rewards for an address
     */
    function rewardOf(address addr) external view returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeWithdrawer {

    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    /**
     * @dev withdraws a certain amount and distributes rewards.
     */
    function withdraw(uint256 amount) external returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Ferrum Staking interface
 */
interface IFestaked {
    
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);
    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    function stake (uint256 amount) external returns (bool);

    function stakeFor (address staker, uint256 amount) external returns (bool);

    function stakeOf(address account) external view returns (uint256);

    function tokenAddress() external view returns (address);

    function stakedTotal() external view returns (uint256);

    function stakedBalance() external view returns (uint256);

    function stakingStarts() external view returns (uint256);

    function stakingEnds() external view returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IFestakeRewardManager.sol";
import "./IFestakeWithdrawer.sol";
import "./Festaked.sol";

/**
 * Allows stake, unstake, and add reward at any time.
 * stake and reward token can be different.
 */
contract OpenEndedRewardManager is 
        Festaked,
        IFestakeRewardManager, IFestakeWithdrawer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public override rewardToken;
    uint256 public override rewardsTotal;
    uint256 public fakeRewardsTotal;
    mapping (address=>uint256) fakeRewards;

    constructor(
        string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) Festaked(name_, tokenAddress_, stakingStarts_, stakingEnds_,
            withdrawStarts_, withdrawEnds_, stakingCap_) public {
            rewardToken = IERC20(rewardTokenAddress_);
    }

    /**
     * First send the rewards to this contract, then call this method.
     * Designed to be called by smart contracts.
     */
    function addMarginalReward()
    external override returns (bool) {
        return _addMarginalReward();
    }

    function _addMarginalReward()
    internal virtual returns (bool) {
        address me = address(this);
        IERC20 _rewardToken = rewardToken;
        uint256 amount = _rewardToken.balanceOf(me).sub(rewardsTotal);
        if (address(_rewardToken) == tokenAddress) {
            amount = amount.sub(stakedBalance);
        }
        if (amount == 0) {
            return true; // No reward to add. Its ok. No need to fail callers.
        }
        rewardsTotal = rewardsTotal.add(amount);
        fakeRewardsTotal = fakeRewardsTotal.add(amount);
        return true;
    }

    function addReward(uint256 rewardAmount)
    external override returns (bool) {
        require(rewardAmount != 0, "OERM: rewardAmount is zero");
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);
        _addMarginalReward();
    }

    function fakeRewardOf(address staker) external view returns (uint256) {
        return fakeRewards[staker];
    }

    function rewardOf(address staker)
    external override virtual view returns (uint256) {
        uint256 stake = Festaked._stakes[staker];
        return _calcRewardOf(staker, stakedBalance, stake);
    }

    function _calcRewardOf(address staker, uint256 totalStaked_, uint256 stake)
    internal view returns (uint256) {
        if (stake == 0) {
            return 0;
        }
        uint256 fr = fakeRewards[staker];
        uint256 rew = _calcReward(totalStaked_, fakeRewardsTotal, stake);
        return rew > fr ? rew.sub(fr) : 0; // Ignoring the overflow problem
    }

    function withdrawRewards() external override virtual returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewards(msg.sender);
    }

    /**
     * First withdraw all rewards, than withdarw it all, then stake back the remaining.
     */
    function withdraw(uint256 amount) external override virtual returns (bool) {
        address _staker = msg.sender;
        return _withdraw(_staker, amount);
    }

    function _withdraw(address _staker, uint256 amount)
    internal virtual returns (bool) {
        if (amount == 0) {
            return true;
        }
        uint256 actualPay = _withdrawOnlyUpdateState(_staker, amount);
        IERC20(tokenAddress).safeTransfer(_staker, amount);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, amount, actualPay);
        return true;
    }

    function _withdrawOnlyUpdateState(address _staker, uint256 amount)
    internal virtual returns (uint256) {
        uint256 userStake = _stakes[_staker];
        require(amount <= userStake, "OERM: Not enough balance");
        uint256 userFake = fakeRewards[_staker];
        uint256 fakeTotal = fakeRewardsTotal;
        uint256 _stakedBalance = stakedBalance;
        uint256 actualPay = _calcWithdrawRewards(userStake, userFake, _stakedBalance, fakeTotal);

        uint256 fakeRewAmount = _calculateFakeRewardAmount(amount, fakeTotal, _stakedBalance);

        fakeRewardsTotal = fakeRewardsTotal.sub(fakeRewAmount);
        fakeRewards[_staker] = userFake.add(actualPay).sub(fakeRewAmount);
        rewardsTotal = rewardsTotal.sub(actualPay);
        stakedBalance = _stakedBalance.sub(amount);
        _stakes[_staker] = userStake.sub(amount);
        return actualPay;
    }

    function _stake(address payer, address staker, uint256 amount)
    virtual
    override
    internal
    // _after(stakingStarts)
    // _before(withdrawEnds)
    // _positive(amount)
    // _realAddress(payer)
    // _realAddress(staker)
    returns (bool) {
        return _stakeNoPreAction(payer, staker, amount);
    }

    function _stakeNoPreAction(address payer, address staker, uint256 amount)
    internal
    returns (bool) {
        uint256 remaining = amount;
        uint256 _stakingCap = stakingCap;
        uint256 _stakedBalance = stakedBalance;
        // check the remaining amount to be staked
        // For pay per transfer tokens we limit the cap on incoming tokens for simplicity. This might
        // mean that cap may not necessary fill completely which is ok.
        if (_stakingCap != 0 && remaining > (_stakingCap.sub(_stakedBalance))) {
            remaining = _stakingCap.sub(_stakedBalance);
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        require(remaining != 0, "OERM: Staking cap is filled");
        require(stakingCap == 0 || remaining.add(stakedBalance) <= stakingCap, "OERM: this will increase staking amount pass the cap");
        // Update remaining in case actual amount paid was different.
        remaining = _payMe(payer, remaining, tokenAddress);
        require(_stakeUpdateStateOnly(staker, remaining), "OERM: Error staking");
        // To ensure total is only updated here. Not when simulating the stake.
        stakedTotal = stakedTotal.add(remaining);
        emit Staked(tokenAddress, staker, amount, remaining);
    }

    function _stakeUpdateStateOnly(address staker, uint256 amount)
    internal returns (bool) {
        uint256 _stakedBalance = stakedBalance;
        uint256 _fakeTotal = fakeRewardsTotal;
        bool isNotNew = _stakedBalance != 0;
        uint256 curRew = isNotNew ?
            _calculateFakeRewardAmount(amount, _fakeTotal, _stakedBalance) :
            _fakeTotal;

        _stakedBalance = _stakedBalance.add(amount);
        _stakes[staker] = _stakes[staker].add(amount);
        fakeRewards[staker] = fakeRewards[staker].add(curRew);

        stakedBalance = _stakedBalance;
        if (isNotNew) {
            fakeRewardsTotal = _fakeTotal.add(curRew);
        }
        return true;
    }

    function _calculateFakeRewardAmount(
        uint256 amount, uint256 baseFakeTotal, uint256 baseStakeTotal
    ) internal pure returns (uint256) {
        return amount.mul(baseFakeTotal).div(baseStakeTotal);
    }

    function _withdrawRewards(address _staker) internal returns (uint256) {
        uint256 userStake = _stakes[_staker];
        uint256 _stakedBalance = stakedBalance;
        uint256 totalFake = fakeRewardsTotal;
        uint256 userFake = fakeRewards[_staker];
        uint256 actualPay = _calcWithdrawRewards(userStake, userFake, _stakedBalance, totalFake);
        rewardsTotal = rewardsTotal.sub(actualPay);
        fakeRewards[_staker] = fakeRewards[_staker].add(actualPay);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, 0, actualPay);
        return actualPay;
    }

    function _calcWithdrawRewards(
        uint256 _stakedAmount,
        uint256 _userFakeRewards,
        uint256 _totalStaked,
        uint256 _totalFakeRewards)
    internal pure returns (uint256) {
        uint256 toPay = _calcReward(_totalStaked, _totalFakeRewards, _stakedAmount);
        return toPay > _userFakeRewards ? toPay.sub(_userFakeRewards) : 0; // Ignore rounding issue
    }

    function _calcReward(uint256 total, uint256 fakeTotal, uint256 staked)
    internal pure returns (uint256) {
        return fakeTotal.mul(staked).div(total);
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../FestakedRewardContinuation.sol";

/**
 * A beta version of FestakedRewardContinuation with ability of sweeping the rewards
 * in case something went wrong.
 * NOTE: Once you sweep rewards to owner, do NOT use the contract any more.
 */
contract FestakedRewardContinuationBeta is FestakedRewardContinuation, Ownable {
    constructor(
        address targetStake_,
        address tokenAddress_,
        address rewardTokenAddress_) FestakedRewardContinuation(
            targetStake_, tokenAddress_, rewardTokenAddress_) public {}
    bool nuked = false;

    function initialize() public override returns (bool) {
        require(!nuked, "FRCB: Already nuked");
        return FestakedRewardContinuation.initialize();
    }

    function sweepToOwner() onlyOwner() external {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(owner(), balance);
        initialSync = false; // Make sure contract cannot be used any more.
        nuked = true;
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}