// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import {StakingRewards} from "./StakingRewards.sol";
import {TokenRecovery} from "./TokenRecovery.sol";

contract ServiceProvider is ReentrancyGuard, Context, TokenRecovery {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct WithdrawalRequest {
        uint256 withdrawalPermittedFrom;
        uint256 amount;
    }

    mapping(address => WithdrawalRequest) public withdrawalRequest;

    address public controller; // StakingRewards

    address public serviceProvider;
    address public serviceProviderManager;

    IERC20 public cudosToken;

    /// @notice Allows the rewards fee to be specified to 2 DP
    uint256 public constant PERCENTAGE_MODULO = 100_00;

    /// @notice True when contract is initialised and the service provider has staked the required bond
    bool public isServiceProviderFullySetup;

    bool public exited;

    /// @notice Defined by the service provider when depositing their bond
    uint256 public rewardsFeePercentage;

    event StakedServiceProviderBond(address indexed serviceProvider, address indexed serviceProviderManager, uint256 indexed pid, uint256 rewardsFeePercentage);
    event IncreasedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid, uint256 amount, uint256 totalAmount);
    event DecreasedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid, uint256 amount, uint256 totalAmount);
    event ExitedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid);
    event WithdrewServiceProviderStake(address indexed serviceProvider, uint256 indexed amount, uint256 totalAmount);
    event AddDelegatedStake(address indexed user, uint256 indexed amount, uint256 totalAmount);
    event WithdrawDelegatedStakeRequested(address indexed user, uint256 indexed amount, uint256 totalAmount);
    event WithdrewDelegatedStake(address indexed user, uint256 indexed amount, uint256 totalAmount);
    event ExitDelegatedStake(address indexed user, uint256 indexed amount);
    event CallibratedServiceProviderFee(address indexed user, uint256 newFee);

    mapping(address => uint256) public delegatedStake;
    mapping(address => uint256) public rewardDebt;

    uint256 public totalDelegatedStake;

    uint256 public rewardsProgrammeId;

    uint256 public accTokensPerShare; // Accumulated reward tokens per share, times 1e18. See below.

    // this is called by StakingRewards to whitelist a service provider and is equivalent of the constructor
    function init(address _serviceProvider, IERC20 _cudosToken) external {
        require(serviceProvider == address(0), "ServiceProvider.init: Fn can only be called once");
        require(_serviceProvider != address(0), "ServiceProvider.init: Service provider cannot be zero address");
        require(address(_cudosToken) != address(0), "ServiceProvider.init: Cudos token cannot be zero address");
        serviceProvider = _serviceProvider;
        cudosToken = _cudosToken;

        controller = _msgSender();
        // StakingRewards contract currently
    }

    // Called by the Service Provider to stake initial minimum cudo required to become a validator
    function stakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) nonReentrant external {
        require(_msgSender() == serviceProvider, "ServiceProvider.stakeServiceProviderBond: Only Service Provider");

        serviceProviderManager = serviceProvider;
        _stakeServiceProviderBond(_rewardsProgrammeId, _rewardsFeePercentage);
    }

    function adminStakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) nonReentrant external {
        require(
            StakingRewards(controller).hasAdminRole(_msgSender()),
            "ServiceProvider.adminStakeServiceProviderBond: Only admin"
        );

        serviceProviderManager = _msgSender();
        _stakeServiceProviderBond(_rewardsProgrammeId, _rewardsFeePercentage);
    }

    function increaseServiceProviderStake(uint256 _amount) nonReentrant external {
        require(isServiceProviderFullySetup, "ServiceProvider.increaseServiceProviderStake: Service provider not setup");
        require(_msgSender() == serviceProviderManager, "ServiceProvider.increaseServiceProviderStake: Only service provider");
        require(_amount > 0, "ServiceProvider.increaseServiceProviderStake: Cannot stake 0");

        StakingRewards rewards = StakingRewards(controller);
        uint256 maxStakingAmountForServiceProviders = rewards.maxStakingAmountForServiceProviders();
        uint256 amountStakedSoFar = rewards.amountStakedByUserInRewardProgramme(rewardsProgrammeId, address(this));

        require(amountStakedSoFar.add(_amount) <= maxStakingAmountForServiceProviders, "ServiceProvider.increaseServiceProviderStake: Exceeds max staking");

        // Get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // increase the service provider stake
        StakingRewards(controller).stake(rewardsProgrammeId, serviceProviderManager, _amount);

        // Update delegated stake
        delegatedStake[serviceProvider] = delegatedStake[serviceProvider].add(_amount);
        totalDelegatedStake = totalDelegatedStake.add(_amount);

        emit IncreasedServiceProviderBond(serviceProvider, rewardsProgrammeId, _amount, delegatedStake[serviceProvider]);
    }

    function requestExcessServiceProviderStakeWithdrawal(uint256 _amount) nonReentrant external {
        require(isServiceProviderFullySetup, "ServiceProvider.requestExcessServiceProviderStakeWithdrawal: Service provider not setup");
        require(_msgSender() == serviceProviderManager, "ServiceProvider.requestExcessServiceProviderStakeWithdrawal: Only service provider");
        require(_amount > 0, "ServiceProvider.requestExcessServiceProviderStakeWithdrawal: Cannot withdraw 0");

        StakingRewards rewards = StakingRewards(controller);
        uint256 amountLeftAfterWithdrawal = delegatedStake[serviceProvider].sub(_amount);
        require(
            amountLeftAfterWithdrawal >= rewards.minRequiredStakingAmountForServiceProviders(),
            "ServiceProvider.requestExcessServiceProviderStakeWithdrawal: Remaining stake for a service provider cannot fall below minimum"
        );

        // Get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // Apply the unbonding period
        uint256 unbondingPeriod = rewards.unbondingPeriod();

        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(_amount);

        delegatedStake[serviceProvider] = amountLeftAfterWithdrawal;
        totalDelegatedStake = totalDelegatedStake.sub(_amount);

        rewards.withdraw(rewardsProgrammeId, address(this), _amount);

        emit DecreasedServiceProviderBond(serviceProvider, rewardsProgrammeId, _amount, delegatedStake[serviceProvider]);
    }

    // only called by service provider
    // all CUDOs staked by service provider and any delegated stake plus rewards will be returned to this contract
    // delegators will have to call their own exit methods to get their original stake and rewards
    function exitAsServiceProvider() nonReentrant external {
        require(_msgSender() == serviceProviderManager, "ServiceProvider.exitAsServiceProvider: Only service provider");

        // Distribute rewards to the service provider and update delegator reward entitlement
        _getAndDistributeRewardsWithMassUpdate();

        StakingRewards rewards = StakingRewards(controller);

        // Assign the unbonding period
        uint256 unbondingPeriod = rewards.unbondingPeriod();

        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(delegatedStake[serviceProvider]);

        // Exit the rewards program bringing in all staked CUDO and earned rewards
        StakingRewards(controller).exit(rewardsProgrammeId);

        // Update service provider state
        uint256 serviceProviderDelegatedStake = delegatedStake[serviceProvider];
        delegatedStake[serviceProvider] = 0;
        totalDelegatedStake = totalDelegatedStake.sub(serviceProviderDelegatedStake);

        // this will mean a service provider could start the program again with stakeServiceProviderBond()
        isServiceProviderFullySetup = false;

        // prevents a SP from re-entering and causing loads of problems!!!
        exited = true;

         // Don't transfer tokens at this point. The service provider needs to wait for the unbonding period first, then needs to call withdrawServiceProviderStake()

        emit ExitedServiceProviderBond(serviceProvider, rewardsProgrammeId);
    }

    // To be called only by a service provider
    function withdrawServiceProviderStake() nonReentrant external {
        require(_msgSender() == serviceProviderManager, "ServiceProvider.withdrawServiceProviderStake: Only service provider");

        WithdrawalRequest storage withdrawalRequest = withdrawalRequest[_msgSender()];

        require(withdrawalRequest.amount > 0, "ServiceProvider.withdrawServiceProviderStake: no withdrawal request in flight");
        require(
            StakingRewards(controller)._getBlock() >= withdrawalRequest.withdrawalPermittedFrom,
            "ServiceProvider.withdrawServiceProviderStake: Not passed unbonding period"
            );

        uint256 withdrawalRequestAmount = withdrawalRequest.amount;
        withdrawalRequest.amount = 0;

        cudosToken.transfer(_msgSender(), withdrawalRequestAmount);

        emit WithdrewServiceProviderStake(_msgSender(), withdrawalRequestAmount, delegatedStake[serviceProvider]);
    }

    // Called by a CUDO holder that wants to delegate their stake to a service provider
    function delegateStake(uint256 _amount) nonReentrant external {
        require(isServiceProviderFullySetup, "ServiceProvider.delegateStake: Service Provider has not posted the required bond");
        require(_msgSender() != serviceProviderManager, "ServiceProvider.delegateStake: Cannot delegate as service provider");
        require(_amount > 0, "ServiceProvider.delegateStake: Cannot stake 0");

        // get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // now stake - no rewards will be sent back
        StakingRewards(controller).stake(rewardsProgrammeId, _msgSender(), _amount);

        // Update user and total delegated stake after _distributeRewards so that calc issues don't arise in _distributeRewards
        uint256 previousDelegatedStake = delegatedStake[_msgSender()];
        delegatedStake[_msgSender()] = previousDelegatedStake.add(_amount);
        totalDelegatedStake = totalDelegatedStake.add(_amount);

        // we need to update the reward debt so that the user doesn't suddenly have rewards due
        rewardDebt[_msgSender()] = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18);

        emit AddDelegatedStake(_msgSender(), _amount, delegatedStake[_msgSender()]);
    }

    // Called by a CUDO holder that has previously delegated stake to the service provider
    function requestDelegatedStakeWithdrawal(uint256 _amount) nonReentrant external {
        require(isServiceProviderFullySetup, "ServiceProvider.requestDelegatedStakeWithdrawal: Service Provider has not posted the required bond");
        require(_amount > 0, "ServiceProvider.requestDelegatedStakeWithdrawal: Invalid withdrawal amount");
        require(_msgSender() != serviceProviderManager, "ServiceProvider.requestDelegatedStakeWithdrawal: Not a service provider method");
        require(delegatedStake[_msgSender()] >= _amount, "ServiceProvider.requestDelegatedStakeWithdrawal: Amount exceeds delegated stake");

        _getAndDistributeRewardsWithMassUpdate();

        StakingRewards rewards = StakingRewards(controller);
        uint256 unbondingPeriod = rewards.unbondingPeriod();

        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(_amount);

        delegatedStake[_msgSender()] = delegatedStake[_msgSender()].sub(_amount);
        totalDelegatedStake = totalDelegatedStake.sub(_amount);

        rewards.withdraw(rewardsProgrammeId, address(this), _amount);

        emit WithdrawDelegatedStakeRequested(_msgSender(), _amount, delegatedStake[_msgSender()]);
    }

    function withdrawDelegatedStake() nonReentrant external {
        require(_msgSender() != serviceProviderManager, "ServiceProvider.withdrawDelegatedStake: Not a service provider method");
        WithdrawalRequest storage withdrawalRequest = withdrawalRequest[_msgSender()];
        require(withdrawalRequest.amount > 0, "ServiceProvider.withdrawDelegatedStake: no withdrawal request in flight");

        if (!exited) {
            require(isServiceProviderFullySetup, "ServiceProvider.withdrawDelegatedStake: Service provider not set up");
            require(
                StakingRewards(controller)._getBlock() >= withdrawalRequest.withdrawalPermittedFrom,
                "ServiceProvider.withdrawDelegatedStake: Not passed unbonding period"
            );
        }
        // No waiting on withdrawals if exited already

        uint256 withdrawalRequestAmount = withdrawalRequest.amount;
        withdrawalRequest.amount = 0;

        cudosToken.transfer(_msgSender(), withdrawalRequestAmount);

        emit WithdrewDelegatedStake(_msgSender(), withdrawalRequestAmount, delegatedStake[_msgSender()]);
    }

    // Can be called by a delegator when a service provider exits
    // Service provider must have exited when the delegator calls this method. Otherwise, they call withdrawDelegatedStake
    function exitAsDelegator() nonReentrant external {
        require(exited, "ServiceProvider.exitAsDelegator: Service provider has not exited");

        uint256 userDelegatedStake = delegatedStake[_msgSender()];
        require(userDelegatedStake > 0, "ServiceProvider.exitAsDelegator: No stake delegated");

        // accTokensPerShare would have already been updated when the service provider exited
        _sendDelegatorAnyPendingRewards();

        delegatedStake[_msgSender()] = 0;
        totalDelegatedStake = totalDelegatedStake.sub(userDelegatedStake);

        // Send them back their stake
        cudosToken.transfer(_msgSender(), userDelegatedStake);

        emit ExitDelegatedStake(_msgSender(), userDelegatedStake);
    }

    // Should be possible for anyone to call this to get the reward from the StakingRewards contract
    // The total rewards due to all delegators will have the rewardsFeePercentage deducted and sent to the Service Provider
    function getReward() external {
        require(!exited, "ServiceProvider.exitAsDelegator: Service provider has exited. Please withdraw your tokens, and you will automatically receive your rewards.");
        require(isServiceProviderFullySetup, "ServiceProvider.getReward: Service Provider has not posted the required bond");
        _getAndDistributeRewards();
    }

    function callibrateServiceProviderFee() external {
        StakingRewards rewards = StakingRewards(controller);
        uint256 minServiceProviderFee = rewards.minServiceProviderFee();

        // current fee is too low - increase to minServiceProviderFee
        if (rewardsFeePercentage < minServiceProviderFee) {
            rewardsFeePercentage = minServiceProviderFee;
            emit CallibratedServiceProviderFee(_msgSender(), rewardsFeePercentage);
        }
    }

    /////////////////
    // View methods
    /////////////////

    function pendingRewards(address _user) public view returns (uint256) {
        uint256 pendingRewardsServiceProviderAndDelegators = StakingRewards(controller).pendingCudoRewards(
            rewardsProgrammeId,
            address(this)
        );

        (
            uint256 stakeDelegatedToServiceProvider,
            uint256 rewardDueToServiceProvider,
            uint256 netRewardsDueToDelegators
        ) = _workOutHowMuchDueToServiceProviderAndDelegators(pendingRewardsServiceProviderAndDelegators);

        if (_user == serviceProvider) {
            return rewardDueToServiceProvider;
        }

        uint256 _accTokensPerShare = accTokensPerShare;
        if (stakeDelegatedToServiceProvider > 0) {
            // Update accTokensPerShare which governs rewards token due to each delegator
            _accTokensPerShare = _accTokensPerShare.add(
                netRewardsDueToDelegators.mul(1e18).div(stakeDelegatedToServiceProvider)
            );
        }

        return delegatedStake[_user].mul(_accTokensPerShare).div(1e18).sub(rewardDebt[_user]);
    }

    ///////////////////
    // Private methods
    ///////////////////

    function _getAndDistributeRewards() private {
        uint256 cudosBalanceBeforeGetReward = cudosToken.balanceOf(address(this));

        StakingRewards(controller).getReward(rewardsProgrammeId);

        uint256 cudosBalanceAfterGetReward = cudosToken.balanceOf(address(this));

        // This is the amount of CUDO that we received from the the above getReward() call
        uint256 rewardDelta = cudosBalanceAfterGetReward.sub(cudosBalanceBeforeGetReward);

        if (rewardDelta > 0) {
            _distributeRewards(rewardDelta);
        }
    }

    function _getAndDistributeRewardsWithMassUpdate() private {
        uint256 cudosBalanceBeforeGetReward = cudosToken.balanceOf(address(this));

        StakingRewards(controller).getRewardWithMassUpdate(rewardsProgrammeId);

        uint256 cudosBalanceAfterGetReward = cudosToken.balanceOf(address(this));

        // This is the amount of CUDO that we received from the the above getReward() call
        uint256 rewardDelta = cudosBalanceAfterGetReward.sub(cudosBalanceBeforeGetReward);

        if (rewardDelta > 0) {
            _distributeRewards(rewardDelta);
        }
    }

    function _distributeRewards(uint256 _amount) private {
        (
            uint256 stakeDelegatedToServiceProvider,
            uint256 rewardDueToServiceProvider,
            uint256 netRewardsDueToDelegators
        ) = _workOutHowMuchDueToServiceProviderAndDelegators(_amount);

        if (stakeDelegatedToServiceProvider > 0) {
            // Update accTokensPerShare which governs rewards token due to each delegator
            accTokensPerShare = accTokensPerShare.add(
                netRewardsDueToDelegators.mul(1e18).div(stakeDelegatedToServiceProvider)
            );
        }

        // If sender is not serviceProvider, send them their share
        if (_msgSender() != serviceProviderManager) {
            // check sender has a delegatedStake
            if (delegatedStake[_msgSender()] > 0) {
                _sendDelegatorAnyPendingRewards();
            }
        }

        cudosToken.transfer(serviceProviderManager, rewardDueToServiceProvider);
    }

    function _workOutHowMuchDueToServiceProviderAndDelegators(uint256 _amount) private view returns (uint256, uint256, uint256) {
        // work out what percentage is the user delegatedStake of total supply
        // user delegatedStake does not include the amount staked by the serviceProvider
        uint256 stakeDelegatedToServiceProvider = totalDelegatedStake.sub(delegatedStake[serviceProvider]);
        uint256 percentageOfStakeThatIsDelegatedToServiceProvider = stakeDelegatedToServiceProvider.mul(PERCENTAGE_MODULO).div(totalDelegatedStake);

        // Of the stake delegated to the service provider, deduct a percentage of the reward for the service fee
        uint256 grossRewardsDueToDelegators = _amount.mul(
            percentageOfStakeThatIsDelegatedToServiceProvider
        ).div(PERCENTAGE_MODULO);

        uint256 rewardsFee = grossRewardsDueToDelegators.mul(rewardsFeePercentage).div(PERCENTAGE_MODULO);

        uint256 netRewardsDueToDelegators = grossRewardsDueToDelegators.sub(rewardsFee);

        // Send reward fee plus rewards for delegatedStake[serviceProvider] to serviceProvider
        uint256 rewardDueToServiceProvider = _amount.sub(netRewardsDueToDelegators);

        return (stakeDelegatedToServiceProvider, rewardDueToServiceProvider, netRewardsDueToDelegators);
    }

    // Ensure this is not called when sender is service provider
    function _sendDelegatorAnyPendingRewards() private {
        uint256 pending = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18).sub(rewardDebt[_msgSender()]);

        if (pending > 0) {
            rewardDebt[_msgSender()] = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18);
            cudosToken.transfer(_msgSender(), pending);
        }
    }

    function _stakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) private {
        require(!isServiceProviderFullySetup, "ServiceProvider.stakeServiceProviderBond: Service provider already set up");
        require(!exited, "ServiceProvider.stakeServiceProviderBond: Exited service provider cannot reenter");
        require(_rewardsFeePercentage > 0 && _rewardsFeePercentage < PERCENTAGE_MODULO, "ServiceProvider.stakeServiceProviderBond: Fee percentage must be greater than zero");

        StakingRewards rewards = StakingRewards(controller);
        uint256 minRequiredStakingAmountForServiceProviders = rewards.minRequiredStakingAmountForServiceProviders();
        uint256 minServiceProviderFee = rewards.minServiceProviderFee();

        require(_rewardsFeePercentage >= minServiceProviderFee, "ServiceProvider.stakeServiceProviderBond: Fee percentage must be greater or equal to minServiceProviderFee");

        rewardsFeePercentage = _rewardsFeePercentage;
        rewardsProgrammeId = _rewardsProgrammeId;
        isServiceProviderFullySetup = true;

        delegatedStake[serviceProvider] = minRequiredStakingAmountForServiceProviders;
        totalDelegatedStake = totalDelegatedStake.add(minRequiredStakingAmountForServiceProviders);

        // A mass update is required at this point
        _getAndDistributeRewardsWithMassUpdate();

        rewards.stake(
            _rewardsProgrammeId,
            _msgSender(),
            minRequiredStakingAmountForServiceProviders
        );

        emit StakedServiceProviderBond(serviceProvider, serviceProviderManager, _rewardsProgrammeId, rewardsFeePercentage);
    }

    // *** CUDO Admin Emergency only **

    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external override {
        require(StakingRewards(controller).hasAdminRole(_msgSender()), "ServiceProvider.recoverEth: Only admin");
        IERC20(_erc20).transfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import { ServiceProvider } from "./ServiceProvider.sol";
import { CloneFactory } from "./CloneFactory.sol";
import { CudosAccessControls } from "../CudosAccessControls.sol";
import { StakingRewardsGuild } from "./StakingRewardsGuild.sol";
import { TokenRecovery } from "./TokenRecovery.sol";

// based on MasterChef from sushi swap
contract StakingRewards is CloneFactory, ReentrancyGuard, Context, TokenRecovery {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user that is staked into a specific reward program i.e. 3 month, 6 month, 12 month
    struct UserInfo {
        uint256 lastStakedBlockNumber;
        uint256 amount;     // How many cudos tokens the user has staked.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of cudos
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * rewardProgramme.accTokensPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a rewardProgramme. Here's what happens:
        //   1. The rewardProgramme's `accTokensPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info about a reward program where each differs in minimum required length of time for locking up CUDOs.
    struct RewardProgramme {
        uint256 minStakingLengthInBlocks; // once staked, amount of blocks the staker has to wait before being able to withdraw
        uint256 allocPoint;       // Percentage of total CUDOs rewards (across all programmes) that this programme will get
        uint256 lastRewardBlock;  // Last block number that CUDOs was claimed for reward programme users.
        uint256 accTokensPerShare; // Accumulated tokens per share, times 1e18. See below.
        uint256 totalStaked; // total staked in this reward programme
    }

    bool userActionsPaused;

    // staking and reward token - CUDOs
    IERC20 public token;

    CudosAccessControls public accessControls;
    StakingRewardsGuild public rewardsGuildBank;

    // tokens rewarded per block.
    uint256 public tokenRewardPerBlock;

    // Info of each reward programme.
    RewardProgramme[] public rewardProgrammes;

    /// @notice minStakingLengthInBlocks -> is active / valid reward programme
    mapping(uint256 => bool) public isActiveRewardProgramme;

    // Info of each user that has staked in each programme.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // total staked across all programmes
    uint256 public totalCudosStaked;

    // weighted total staked across all programmes
    uint256 public weightedTotalCudosStaked;

    // The block number when rewards start.
    uint256 public startBlock;

    // service provider -> proxy and reverse mapping
    mapping(address => address) public serviceProviderToWhitelistedProxyContracts;
    mapping(address => address) public serviceProviderContractToServiceProvider;

    /// @notice Used as a base contract to clone for all new whitelisted service providers
    address public cloneableServiceProviderContract;

    /// @notice By default, 2M CUDO must be supplied to be a validator
    uint256 public minRequiredStakingAmountForServiceProviders = 2_000_000 * 10 ** 18;
    uint256 public maxStakingAmountForServiceProviders = 1_000_000_000 * 10 ** 18;

    uint256 public minServiceProviderFee = 2_00; // initially 2%

    uint256 public constant numOfBlocksInADay = 6500;
    uint256 public unbondingPeriod = numOfBlocksInADay.mul(21); // Equivalent to solidity 21 days

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event MinRequiredStakingAmountForServiceProvidersUpdated(uint256 oldValue, uint256 newValue);
    event MaxStakingAmountForServiceProvidersUpdated(uint256 oldValue, uint256 newValue);
    event MinServiceProviderFeeUpdated(uint256 oldValue, uint256 newValue);
    event ServiceProviderWhitelisted(address indexed serviceProvider);
    event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);
    event RewardProgrammeAdded(uint256 allocPoint, uint256 minStakingLengthInBlocks);
    event RewardProgrammeAllocPointUpdated(uint256 oldValue, uint256 newValue);
    event UserActionsPausedToggled(bool isPaused);

    constructor(
        IERC20 _token,
        CudosAccessControls _accessControls,
        StakingRewardsGuild _rewardsGuildBank,
        uint256 _tokenRewardPerBlock,
        uint256 _startBlock,
        address _cloneableServiceProviderContract
    ) public {
        require(address(_accessControls) != address(0), "StakingRewards.constructor: Invalid access controls");
        require(address(_token) != address(0), "StakingRewards.constructor: Invalid token address");
        require(_cloneableServiceProviderContract != address(0), "StakingRewards.constructor: Invalid cloneable service provider");

        token = _token;
        accessControls = _accessControls;
        rewardsGuildBank = _rewardsGuildBank;
        tokenRewardPerBlock = _tokenRewardPerBlock;
        startBlock = _startBlock;
        cloneableServiceProviderContract = _cloneableServiceProviderContract;
    }

    // Update reward variables of the given programme to be up-to-date.
    function updateRewardProgramme(uint256 _programmeId) public {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];

        if (_getBlock() <= rewardProgramme.lastRewardBlock) {
            return;
        }

        uint256 totalStaked = rewardProgramme.totalStaked;

        if (totalStaked == 0) {
            rewardProgramme.lastRewardBlock = _getBlock();
            return;
        }

        uint256 blocksSinceLastReward = _getBlock().sub(rewardProgramme.lastRewardBlock);
        // we want to divide proportionally by all the tokens staked in the RPs, not to distribute first to RP
        // so what we want here is rewardProgramme.allocPoint.mul(rewardProgramme.totalStaked).div(the sum of the products of allocPoint times totalStake for each RP)
        uint256 rewardPerShare = blocksSinceLastReward.mul(tokenRewardPerBlock).mul(rewardProgramme.allocPoint).mul(1e18).div(weightedTotalCudosStaked);
        rewardProgramme.accTokensPerShare = rewardProgramme.accTokensPerShare.add(rewardPerShare);
        rewardProgramme.lastRewardBlock = _getBlock();
    }

    function getReward(uint256 _programmeId) external nonReentrant {
        updateRewardProgramme(_programmeId);
        _getReward(_programmeId);
    }

    function massUpdateRewardProgrammes() public {
        uint256 programmeLength = rewardProgrammes.length;
        for(uint256 i = 0; i < programmeLength; i++) {
            updateRewardProgramme(i);
        }
    }

    function getRewardWithMassUpdate(uint256 _programmeId) external nonReentrant {
        massUpdateRewardProgrammes();
        _getReward(_programmeId);
    }

    // stake CUDO in a specific reward programme that dictates a minimum lockup period
    function stake(uint256 _programmeId, address _from, uint256 _amount) external nonReentrant {
        require(userActionsPaused == false, "StakingRewards.stake: Staking is currently paused");
        require(_amount > 0, "StakingRewards.stake: Cannot stake 0");
        require(serviceProviderContractToServiceProvider[_msgSender()] != address(0), "StakingRewards.stake: Unknown service provider");
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];

        user.lastStakedBlockNumber = _getBlock();

        user.amount = user.amount.add(_amount);
        rewardProgramme.totalStaked = rewardProgramme.totalStaked.add(_amount);
        totalCudosStaked = totalCudosStaked.add(_amount);
        // weigted sum gets updated when new tokens are staked
        weightedTotalCudosStaked = weightedTotalCudosStaked.add(_amount.mul(rewardProgramme.allocPoint));

        user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);

        token.safeTransferFrom(address(_from), address(rewardsGuildBank), _amount);
        emit Deposit(_from, _programmeId, _amount);
    }

    // Withdraw stake and rewards
    function withdraw(uint256 _programmeId, address _to, uint256 _amount) public nonReentrant {
        require(userActionsPaused == false, "StakingRewards.withdraw: Withdrawals are currently paused");
        require(_amount > 0, "StakingRewards.withdraw: Cannot withdraw 0");
        require(serviceProviderContractToServiceProvider[_msgSender()] != address(0), "StakingRewards.withdraw: Unknown service provider");
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];

        require(user.amount >= _amount, "StakingRewards.withdraw: Amount exceeds balance");
        require(
            _getBlock() >= user.lastStakedBlockNumber.add(rewardProgramme.minStakingLengthInBlocks),
            "StakingRewards.withdraw: Min staking period has not yet passed"
        );

        user.amount = user.amount.sub(_amount);
        rewardProgramme.totalStaked = rewardProgramme.totalStaked.sub(_amount);
        totalCudosStaked = totalCudosStaked.sub(_amount);
        // weigted sum gets updated when new tokens are withdrawn
        weightedTotalCudosStaked = weightedTotalCudosStaked.sub(_amount.mul(rewardProgramme.allocPoint));

        user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);

        rewardsGuildBank.withdrawTo(_to, _amount);
        emit Withdraw(_msgSender(), _programmeId, _amount);
    }

    function exit(uint256 _programmeId) external {
        require(serviceProviderContractToServiceProvider[_msgSender()] != address(0), "Unknown service provider");
        withdraw(_programmeId, _msgSender(), userInfo[_programmeId][_msgSender()].amount);
    }

    // *****
    // View
    // *****

    function numberOfRewardProgrammes() external view returns (uint256) {
        return rewardProgrammes.length;
    }

    function getRewardProgrammeInfo(uint256 _programmeId) external view returns (
        uint256 minStakingLengthInBlocks,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accTokensPerShare,
        uint256 totalStaked
    ) {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        return (
        rewardProgramme.minStakingLengthInBlocks,
        rewardProgramme.allocPoint,
        rewardProgramme.lastRewardBlock,
        rewardProgramme.accTokensPerShare,
        rewardProgramme.totalStaked
        );
    }

    function amountStakedByUserInRewardProgramme(uint256 _programmeId, address _user) external view returns (uint256) {
        return userInfo[_programmeId][_user].amount;
    }

    function totalStakedInRewardProgramme(uint256 _programmeId) external view returns (uint256) {
        return rewardProgrammes[_programmeId].totalStaked;
    }

    function totalStakedAcrossAllRewardProgrammes() external view returns (uint256) {
        return totalCudosStaked;
    }

    // View function to see pending CUDOs on frontend.
    function pendingCudoRewards(uint256 _programmeId, address _user) external view returns (uint256) {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_user];
        uint256 accTokensPerShare = rewardProgramme.accTokensPerShare;
        uint256 totalStaked = rewardProgramme.totalStaked;

        if (_getBlock() > rewardProgramme.lastRewardBlock && totalStaked != 0) {
            uint256 blocksSinceLastReward = _getBlock().sub(rewardProgramme.lastRewardBlock);
            // reward distribution is changed in line with the change within the updateRewardProgramme function
            uint256 rewardPerShare = blocksSinceLastReward.mul(tokenRewardPerBlock).mul(rewardProgramme.allocPoint).mul(1e18).div(weightedTotalCudosStaked);
            accTokensPerShare = accTokensPerShare.add(rewardPerShare);
        }

        return user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);
    }

    // proxy for service provider
    function hasAdminRole(address _caller) external view returns (bool) {
        return accessControls.hasAdminRole(_caller);
    }

    // *********
    // Whitelist
    // *********
    // methods that check for whitelist role in access controls are for any param changes that could be done via governance

    function updateMinRequiredStakingAmountForServiceProviders(uint256 _newValue) external {
        require(accessControls.hasWhitelistRole(_msgSender()), "StakingRewards.updateMinRequiredStakingAmountForServiceProviders: Only whitelisted");
        require(_newValue < maxStakingAmountForServiceProviders, "StakingRewards.updateMinRequiredStakingAmountForServiceProviders: Min staking must be less than max staking amount");

        emit MinRequiredStakingAmountForServiceProvidersUpdated(minRequiredStakingAmountForServiceProviders, _newValue);

        minRequiredStakingAmountForServiceProviders = _newValue;
    }

    function updateMaxStakingAmountForServiceProviders(uint256 _newValue) external {
        require(accessControls.hasWhitelistRole(_msgSender()), "StakingRewards.updateMaxStakingAmountForServiceProviders: Only whitelisted");
        require(_newValue > minRequiredStakingAmountForServiceProviders, "StakingRewards.updateMaxStakingAmountForServiceProviders: Max staking must be greater than min staking amount");

        emit MaxStakingAmountForServiceProvidersUpdated(maxStakingAmountForServiceProviders, _newValue);

        maxStakingAmountForServiceProviders = _newValue;
    }

    function updateMinServiceProviderFee(uint256 _newValue) external {
        require(accessControls.hasWhitelistRole(_msgSender()), "StakingRewards.updateMinServiceProviderFee: Only whitelisted");

        emit MinServiceProviderFeeUpdated(minServiceProviderFee, _newValue);

        minServiceProviderFee = _newValue;
    }

    // *****
    // Admin
    // *****

    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external override {
        require(accessControls.hasAdminRole(_msgSender()), "StakingRewards.recoverEth: Only admin");
        IERC20(_erc20).safeTransfer(_recipient, _amount);
    }

    function whitelistServiceProvider(address _serviceProvider) external {
        require(accessControls.hasAdminRole(_msgSender()), "StakingRewards.whitelistServiceProvider: Only admin");
        require(serviceProviderToWhitelistedProxyContracts[_serviceProvider] == address(0), "StakingRewards.whitelistServiceProvider:  Already whitelisted service provider");
        address serviceProviderContract = createClone(cloneableServiceProviderContract);
        serviceProviderToWhitelistedProxyContracts[_serviceProvider] = serviceProviderContract;
        serviceProviderContractToServiceProvider[serviceProviderContract] = _serviceProvider;
        ServiceProvider(serviceProviderContract).init(_serviceProvider, token);

        emit ServiceProviderWhitelisted(_serviceProvider);
    }

    function updateTokenRewardPerBlock(uint256 _tokenRewardPerBlock) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "StakingRewards.updateTokenRewardPerBlock: Only admin"
        );

        // If this is not done, any pending rewards could be potentially lost
        massUpdateRewardProgrammes();

        // Log old and new value
        emit RewardPerBlockUpdated(tokenRewardPerBlock, _tokenRewardPerBlock);

        // this is safe to be set to zero - it would effectively turn off all staking rewards
        tokenRewardPerBlock = _tokenRewardPerBlock;
    }

    // Admin - Add a rewards programme
    function addRewardsProgramme(uint256 _allocPoint, uint256 _minStakingLengthInBlocks, bool _withUpdate) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "StakingRewards.addRewardsProgramme: Only admin"
        );

        require(
            isActiveRewardProgramme[_minStakingLengthInBlocks] == false,
            "StakingRewards.addRewardsProgramme: Programme is already active"
        );

        require(_allocPoint > 0, "StakingRewards.addRewardsProgramme: Invalid alloc point");

        if (_withUpdate) {
            massUpdateRewardProgrammes();
        }

        uint256 lastRewardBlock = _getBlock() > startBlock ? _getBlock() : startBlock;
        rewardProgrammes.push(
            RewardProgramme({
        minStakingLengthInBlocks: _minStakingLengthInBlocks,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accTokensPerShare: 0,
        totalStaked: 0
        })
        );

        isActiveRewardProgramme[_minStakingLengthInBlocks] = true;

        emit RewardProgrammeAdded(_allocPoint, _minStakingLengthInBlocks);
    }

    // Update the given reward programme's CUDO allocation point. Can only be called by admin.
    function updateAllocPointForRewardProgramme(uint256 _programmeId, uint256 _allocPoint, bool _withUpdate) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "StakingRewards.updateAllocPointForRewardProgramme: Only admin"
        );

        if (_withUpdate) {
            massUpdateRewardProgrammes();
        }

        weightedTotalCudosStaked = weightedTotalCudosStaked.sub(rewardProgrammes[_programmeId].totalStaked.mul(rewardProgrammes[_programmeId].allocPoint));

        emit RewardProgrammeAllocPointUpdated(rewardProgrammes[_programmeId].allocPoint, _allocPoint);

        rewardProgrammes[_programmeId].allocPoint = _allocPoint;

        weightedTotalCudosStaked = weightedTotalCudosStaked.add(rewardProgrammes[_programmeId].totalStaked.mul(rewardProgrammes[_programmeId].allocPoint));
    }

    function updateUserActionsPaused(bool _isPaused) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "StakingRewards.addRewardsProgramme: Only admin"
        );

        userActionsPaused = _isPaused;

        emit UserActionsPausedToggled(_isPaused);
    }

    // ********
    // Internal
    // ********

    function _getReward(uint256 _programmeId) internal {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);
                rewardsGuildBank.withdrawTo(_msgSender(), pending);
            }
        }
    }

    function _getBlock() public virtual view returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CudosAccessControls is AccessControl {
    // Role definitions
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");

    // Events
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event WhitelistRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event WhitelistRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CudosAccessControls: sender must be an admin");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /////////////
    // Lookups //
    /////////////

    function hasAdminRole(address _address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function hasWhitelistRole(address _address) external view returns (bool) {
        return hasRole(WHITELISTED_ROLE, _address);
    }

    function hasSmartContractRole(address _address) external view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    function addAdminRole(address _address) external onlyAdminRole {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    function removeAdminRole(address _address) external onlyAdminRole {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }

    function addWhitelistRole(address _address) external onlyAdminRole {
        _setupRole(WHITELISTED_ROLE, _address);
        emit WhitelistRoleGranted(_address, _msgSender());
    }

    function removeWhitelistRole(address _address) external onlyAdminRole {
        revokeRole(WHITELISTED_ROLE, _address);
        emit WhitelistRoleRemoved(_address, _msgSender());
    }

    function addSmartContractRole(address _address) external onlyAdminRole {
        _setupRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }

    function removeSmartContractRole(address _address) external onlyAdminRole {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { CudosAccessControls } from "../CudosAccessControls.sol";

contract StakingRewardsGuild {
    using SafeERC20 for IERC20;

    IERC20 public token;
    CudosAccessControls public accessControls;

    constructor(IERC20 _token, CudosAccessControls _accessControls) public {
        token = _token;
        accessControls = _accessControls;
    }

    function withdrawTo(address _recipient, uint256 _amount) external {
        require(
            accessControls.hasSmartContractRole(msg.sender),
            "StakingRewardsGuild.withdrawTo: Only authorised smart contract"
        );
        require(_recipient != address(0), "StakingRewardsGuild.withdrawTo: _recipient is zero address");

        token.transfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract TokenRecovery {
    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external virtual;
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

import "../utils/Context.sol";

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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
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
  }
}