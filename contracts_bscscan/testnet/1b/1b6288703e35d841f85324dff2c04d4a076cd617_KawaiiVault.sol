// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './SafeBEP20.sol';
import './IBEP20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './ICalcifireVault.sol';
import './ICalcifireReferral.sol';
import './IPancakeswapFarm.sol';
import './IPancakeRouter01.sol';

contract KawaiiVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        // How many assets the user has provided.
        uint256 stake;
        // How many staked $CALCIFIRE user had at his last action
        uint256 autoCalcifireShares;
        // Calcifire shares not entitled to the user
        uint256 rewardDebt;
        // Timestamp of last user deposit
        uint256 lastDepositedTime;
        // Timestamp that user can claim rewards with no fees
        uint256 noFeesWithdrawTime;
        // When can the user harvest again.
        uint256 nextHarvestUntil;
    }

    // The CALCIFIRE TOKEN
    IBEP20 public constant CALCIFIRE = IBEP20(0x6b65266bD93E5A79B733d377a846d440304a5A08);

    // Addresses
    address public constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    ICalcifireVault immutable public AUTO_CALCIFIRE;
    IBEP20 immutable public STAKED_TOKEN;

    // referral contract address.
    ICalcifireReferral public calcifireReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 500;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    // Runtime data
    mapping(address => UserInfo) public userInfo; // Info of users
    uint256 public accSharesPerStakedToken; // Accumulated AUTO_CALCIFIRE shares per staked token, times 1e18.

    // Farm info
    IPancakeswapFarm immutable public STAKED_TOKEN_FARM;
    IBEP20 immutable public FARM_REWARD_TOKEN;
    uint256 immutable public FARM_PID;
    bool immutable public IS_CAKE_STAKING;

    // Settings
    IPancakeRouter01 immutable public router;
    address[] public pathToCalcifire; // Path from staked token to CALCIFIRE
    address[] public pathToWbnb; // Path from staked token to WBNB

    address public feeAddress;
    address public keeper;
    uint256 public keeperFee = 50; // 0.5%
    uint256 public constant KEEPER_FEE_LIMIT = 100; // 1%

    address public platform;
    uint256 public platformFee;
    uint256 public constant PLATFORM_FEE_LIMIT = 500; // 5%

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnRate;
    uint256 public constant BURN_RATE_LIMIT = 500; // 5%

    uint256 public earlyWithdrawFee = 0; // 0% by default
    uint256 public earlyWithdrawFeePeriod = 5 days;
    uint256 public harvestInterval = 259200;  // Harvest interval in seconds
    uint256 public constant EARLY_WITHDR_FEE_LIMIT = 1000; // 10%
    uint256 public constant EARLY_WITHDR_FEE_PERIOD_LIMIT = 10 days;
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days; // Max harvest interval: 14 days.

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EarlyWithdraw(address indexed user, uint256 amount, uint256 fee);
    event ClaimRewards(address indexed user, uint256 shares, uint256 amount);
    event SwapTokensForTokens(uint256 _inputAmount, uint256 _minOutputAmount, address[] _path, address _to, uint256[] receipt);

    // Setting updates
    event SetPathToCalcifire(address[] oldPath, address[] newPath);
    event SetPathToWbnb(address[] oldPath, address[] newPath);
    event SetBurnRate(uint256 oldBurnRate, uint256 newBurnRate);
    event SetFeeAddress(address oldFeeAddress, address newFeeAddress);
    event SetKeeper(address oldKeeper, address newKeeper);
    event SetKeeperFee(uint256 oldKeeperFee, uint256 newKeeperFee);
    event SetPlatform(address oldPlatform, address newPlatform);
    event SetPlatformFee(uint256 oldPlatformFee, uint256 newPlatformFee);
    event SetEarlyWithdrawFee(uint256 oldEarlyWithdrawFee, uint256 newEarlyWithdrawFee);
    event SetEarlyWithdrawFeePeriod(uint256 oldEarlyWithdrawFeePeriod, uint256 earlyWithdrawFeePeriod);
    event SetHarvestInterval(uint256 oldHarvestInterval, uint256 harvestInterval);
    event SetReferralCommissionRate(uint16 _referralCommissionRate);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        address _autoCalcifire,
        address _stakedToken,
        address _stakedTokenFarm,
        address _farmRewardToken,
        uint256 _farmPid,
        bool _isCakeStaking,
        address _router,
        address[] memory _pathToCalcifire,
        address[] memory _pathToWbnb,
        address _owner,
        address _feeAddress,
        address _keeper,
        address _platform,
        uint256 _burnRate,
        uint256 _platformFee
    ) public {

        require(_autoCalcifire != address(0), "_autoCalcifire cannot be zero address");
        require(_stakedToken != address(0), "_stakedToken cannot be zero address");
        require(_stakedTokenFarm != address(0), "_stakedTokenFarm cannot be zero address");
        require(_farmRewardToken != address(0), "_farmRewardToken cannot be zero address");
        require(_router != address(0), "_router cannot be zero address");
        require(_owner != address(0), "_owner cannot be zero address");
        require(_feeAddress != address(0), "_feeAddress cannot be zero address");
        require(_keeper != address(0), "_keeper cannot be zero address");
        require(_platform != address(0), "_platform cannot be zero address");

        require(
            _pathToCalcifire[0] == address(_farmRewardToken) && _pathToCalcifire[_pathToCalcifire.length - 1] == address(CALCIFIRE),
            "KawaiiVault: Incorrect path to CALCIFIRE"
        );

        require(
            _pathToWbnb[0] == address(_farmRewardToken) && _pathToWbnb[_pathToWbnb.length - 1] == WBNB,
            "KawaiiVault: Incorrect path to WBNB"
        );

        require(_burnRate <= BURN_RATE_LIMIT);
        require(_platformFee <= PLATFORM_FEE_LIMIT);

        AUTO_CALCIFIRE = ICalcifireVault(_autoCalcifire);
        STAKED_TOKEN = IBEP20(_stakedToken);
        STAKED_TOKEN_FARM = IPancakeswapFarm(_stakedTokenFarm);
        FARM_REWARD_TOKEN = IBEP20(_farmRewardToken);
        FARM_PID = _farmPid;
        IS_CAKE_STAKING = _isCakeStaking;

        router = IPancakeRouter01(_router);
        pathToCalcifire = _pathToCalcifire;
        pathToWbnb = _pathToWbnb;

        burnRate = _burnRate;
        platformFee = _platformFee;

        transferOwnership(_owner);
        feeAddress = _feeAddress;
        keeper = _keeper;
        platform = _platform;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(keeper == msg.sender, "KawaiiVault: caller is not the keeper");
        _;
    }

    // 1. Harvest rewards
    // 2. Collect fees
    // 3. Convert rewards to $CALCIFIRE
    // 4. Stake to Calcifire auto-compound vault
    function earn(
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minCalcifireOutput
    ) external onlyKeeper {
        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(0);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0);
        }

        uint256 rewardTokenBalance = _rewardTokenBalance();

        // Collect platform fees
        if (platformFee > 0) {
            _swap(
                rewardTokenBalance.mul(platformFee).div(10000),
                _minPlatformOutput,
                pathToWbnb,
                platform
            );
        }

        // Collect keeper fees
        if (keeperFee > 0) {
            _swap(
                rewardTokenBalance.mul(keeperFee).div(10000),
                _minKeeperOutput,
                pathToWbnb,
                feeAddress
            );
        }

        // Collect Burn fees
        if (burnRate > 0) {
            _swap(
                rewardTokenBalance.mul(burnRate).div(10000),
                _minBurnOutput,
                pathToCalcifire,
                BURN_ADDRESS
            );
        }

        // Convert remaining rewards to CALCIFIRE
        _swap(
            _rewardTokenBalance(),
            _minCalcifireOutput,
            pathToCalcifire,
            address(this)
        );

        uint256 previousShares = totalAutoCalcifireShares();
        uint256 calcifireBalance = _calcifireBalance();

        _approveTokenIfNeeded(
            CALCIFIRE,
            calcifireBalance,
            address(AUTO_CALCIFIRE)
        );

        AUTO_CALCIFIRE.deposit(calcifireBalance);

        uint256 currentShares = totalAutoCalcifireShares();

        accSharesPerStakedToken = accSharesPerStakedToken.add(
            currentShares.sub(previousShares).mul(1e18).div(totalStake())
        );
    }

    function deposit(uint256 _amount, address _referrer) external nonReentrant {
        require(_amount > 0, "KawaiiVault: amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        if (_amount > 0) {

          if (address(calcifireReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
              calcifireReferral.recordReferral(msg.sender, _referrer);
          }
        }

        STAKED_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _approveTokenIfNeeded(
            STAKED_TOKEN,
            _amount,
            address(STAKED_TOKEN_FARM)
        );

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.enterStaking(_amount);
        } else {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount);
        }

        user.autoCalcifireShares = user.autoCalcifireShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.add(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        user.lastDepositedTime = block.timestamp;
        user.noFeesWithdrawTime = user.lastDepositedTime.add(earlyWithdrawFeePeriod);

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "KawaiiVault: amount must be greater than zero");
        require(user.stake >= _amount, "KawaiiVault: withdraw amount exceeds balance");

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(_amount);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount);
        }

        uint256 currentAmount = _amount;

        if (block.timestamp < user.lastDepositedTime.add(earlyWithdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(earlyWithdrawFee).div(10000);

            STAKED_TOKEN.safeTransfer(feeAddress, currentWithdrawFee);

            currentAmount = currentAmount.sub(currentWithdrawFee);

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        user.autoCalcifireShares = user.autoCalcifireShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.sub(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);

        // Withdraw Calcifire rewards if user leaves
        if (user.stake == 0 && user.autoCalcifireShares > 0) {
            _claimRewards(user.autoCalcifireShares, false);
        }

        STAKED_TOKEN.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    function claimRewards(uint256 _shares) external nonReentrant {
        _claimRewards(_shares, true);
    }

    function _claimRewards(uint256 _shares, bool _update) private {
        UserInfo storage user = userInfo[msg.sender];

        if (_update) {
            user.autoCalcifireShares = user.autoCalcifireShares.add(
                user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                    user.rewardDebt
                )
            );

            user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        }

        require(user.autoCalcifireShares >= _shares, "KawaiiVault: claim amount exceeds balance");

        user.autoCalcifireShares = user.autoCalcifireShares.sub(_shares);

        uint256 calcifireBalanceBefore = _calcifireBalance();

        AUTO_CALCIFIRE.withdraw(_shares);

        uint256 withdrawAmount = _calcifireBalance().sub(calcifireBalanceBefore);
        //check Harvest Tax
        uint256 harvestTaxAmount = harvestTax(msg.sender);
        uint256 taxRewards = withdrawAmount.mul(harvestTaxAmount).div(100);
        uint256 netRewards = withdrawAmount.sub(taxRewards);

        _safeCalcifireTransfer(msg.sender, netRewards);
        payReferralCommissionAndBurn(msg.sender, netRewards, taxRewards);

        //reset harvest lockup
        user.nextHarvestUntil = block.timestamp.add(harvestInterval);

        emit ClaimRewards(msg.sender, _shares, netRewards);
    }

    // time till next withdraw with no fees
    function withdrawRewardsTimestamp(address userAddr) public view returns (uint256) {
        UserInfo storage user = userInfo[userAddr];
        uint256 remainingClaimTime = 0;

        if (block.timestamp >= user.noFeesWithdrawTime)
        {
          remainingClaimTime = 0;
        }
        else
        {
          remainingClaimTime = user.noFeesWithdrawTime.sub(block.timestamp);
        }

        return remainingClaimTime;
    }

    function getExpectedOutputs() external view returns (
        uint256 platformOutput,
        uint256 keeperOutput,
        uint256 burnOutput,
        uint256 calcifireOutput
    ) {
        uint256 wbnbOutput = _getExpectedOutput(pathToWbnb);
        uint256 calcifireOutputWithoutFees = _getExpectedOutput(pathToCalcifire);

        platformOutput = wbnbOutput.mul(platformFee).div(10000);
        keeperOutput = wbnbOutput.mul(keeperFee).div(10000);
        burnOutput = calcifireOutputWithoutFees.mul(burnRate).div(10000);

        calcifireOutput = calcifireOutputWithoutFees.sub(
            calcifireOutputWithoutFees.mul(platformFee).div(10000).add(
                calcifireOutputWithoutFees.mul(keeperFee).div(10000)
            ).add(
                calcifireOutputWithoutFees.mul(burnRate).div(10000)
            )
        );
    }

    function _getExpectedOutput(
        address[] memory _path
    ) private view returns (uint256) {
        uint256 rewards = _rewardTokenBalance().add(
            STAKED_TOKEN_FARM.pendingCake(FARM_PID, address(this))
        );

        uint256[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length.sub(1)];
    }

    function balanceOf(
        address _user
    ) external view returns (
        uint256 stake,
        uint256 calcifire,
        uint256 autoCalcifireShares
    ) {
        UserInfo memory user = userInfo[_user];

        uint256 pendingShares = user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
            user.rewardDebt
        );

        stake = user.stake;
        autoCalcifireShares = user.autoCalcifireShares.add(pendingShares);
        calcifire = autoCalcifireShares.mul(AUTO_CALCIFIRE.getPricePerFullShare()).div(1e18);
    }

    function _approveTokenIfNeeded(
        IBEP20 _token,
        uint256 _amount,
        address _spender
    ) private {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.safeIncreaseAllowance(_spender, _amount);
        }
    }

    function _rewardTokenBalance() private view returns (uint256) {
        return FARM_REWARD_TOKEN.balanceOf(address(this));
    }

    function _calcifireBalance() private view returns (uint256) {
        return CALCIFIRE.balanceOf(address(this));
    }

    function totalStake() public view returns (uint256) {
        return STAKED_TOKEN_FARM.userInfo(FARM_PID, address(this));
    }

    function totalAutoCalcifireShares() public view returns (uint256) {
        (uint256 shares, , ,) = AUTO_CALCIFIRE.userInfo(address(this));

        return shares;
    }

    // Safe CALCIFIRE transfer function, just in case if rounding error causes pool to not have enough tokens
    function _safeCalcifireTransfer(address _to, uint256 _amount) private {
        uint256 balance = _calcifireBalance();

        if (_amount > balance) {
            CALCIFIRE.safeTransfer(_to, balance);
        } else {
            CALCIFIRE.safeTransfer(_to, _amount);
        }
    }

    function _swap(
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        address[] memory _path,
        address _to
    ) private {
        _approveTokenIfNeeded(
            FARM_REWARD_TOKEN,
            _inputAmount,
            address(router)
        );

      uint256[] memory receipt = router.swapExactTokensForTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );

        emit SwapTokensForTokens(_inputAmount, _minOutputAmount, _path, _to, receipt);
    }

    function setPathToCalcifire(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == address(CALCIFIRE),
            "KawaiiVault: Incorrect path to CALCIFIRE"
        );

        address[] memory oldPath = pathToCalcifire;

        pathToCalcifire = _path;

        emit SetPathToCalcifire(oldPath, pathToCalcifire);
    }

    function setPathToWbnb(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == WBNB,
            "KawaiiVault: Incorrect path to WBNB"
        );

        address[] memory oldPath = pathToWbnb;

        pathToWbnb = _path;

        emit SetPathToWbnb(oldPath, pathToWbnb);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "_feeAddress cannot be zero address");

        address oldFeeAddress = feeAddress;
        feeAddress = _feeAddress;

        emit SetFeeAddress(oldFeeAddress, feeAddress);
    }

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "_keeper cannot be zero address");

        address oldKeeper = keeper;
        keeper = _keeper;

        emit SetKeeper(oldKeeper, keeper);
    }

    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(_keeperFee <= KEEPER_FEE_LIMIT, "KawaiiVault: Keeper fee too high");

        uint256 oldKeeperFee = keeperFee;

        keeperFee = _keeperFee;

        emit SetKeeperFee(oldKeeperFee, keeperFee);
    }

    function setPlatform(address _platform) external onlyOwner {
        require(_platform != address(0), "_platform cannot be zero address");

        address oldPlatform = platform;
        platform = _platform;

        emit SetPlatform(oldPlatform, platform);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= PLATFORM_FEE_LIMIT, "KawaiiVault: Platform fee too high");

        uint256 oldPlatformFee = platformFee;

        platformFee = _platformFee;

        emit SetPlatformFee(oldPlatformFee, platformFee);
    }

    function setBurnRate(uint256 _burnRate) external onlyOwner {
        require(
            _burnRate <= BURN_RATE_LIMIT,
            "KawaiiVault: Buy back rate too high"
        );

        uint256 oldBurnRate = burnRate;

        burnRate = _burnRate;

        emit SetBurnRate(oldBurnRate, burnRate);
    }

    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(
            _earlyWithdrawFee <= EARLY_WITHDR_FEE_LIMIT,
            "KawaiiVault: Early withdraw fee too high"
        );

        uint256 oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }

    function setEarlyWithdrawFeePeriod(uint256 _earlyWithdrawFeePeriod) external onlyOwner {
        require(
            _earlyWithdrawFeePeriod <= EARLY_WITHDR_FEE_PERIOD_LIMIT,
            "KawaiiVault: Early withdraw fee period too high"
        );

        uint256 oldEarlyWithdrawFeePeriod = earlyWithdrawFeePeriod;

        earlyWithdrawFeePeriod = _earlyWithdrawFeePeriod;

        emit SetEarlyWithdrawFeePeriod(oldEarlyWithdrawFeePeriod, earlyWithdrawFeePeriod);
    }

    // View function to see if user can harvest.
    function canHarvest(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    function setHarvestInterval(uint256 _harvestInterval) public onlyOwner {
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "setHarvestInterval: invalid harvest interval");

        uint256 oldHarvestInterval = harvestInterval;
        harvestInterval = _harvestInterval;

        emit SetHarvestInterval(oldHarvestInterval, harvestInterval);
    }

    // View function to calc current Harvest Tax %
    function harvestTax(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.timestamp >= user.nextHarvestUntil) {
            return 0;
        } else {
            uint256 remainingBlocks = user.nextHarvestUntil.sub(block.timestamp);
            uint256 harvestTaxAmount = remainingBlocks.mul(100).div(harvestInterval);

            if (harvestTaxAmount < 2) {
                return 0;
            } else {
                return harvestTaxAmount;
            }
        }
    }

    // Update the referral contract address by the owner
    function setReferralContract(ICalcifireReferral _calcifireReferral) public onlyOwner {
        calcifireReferral = _calcifireReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;

        emit SetReferralCommissionRate(_referralCommissionRate);
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommissionAndBurn(address _user, uint256 _netRewards, uint256 _taxRewards) internal {
        uint256 commissionAmount = 0;
        uint256 burnTax = _taxRewards;

        if (address(calcifireReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = calcifireReferral.getReferrer(_user);

            if (referrer != address(0) && _taxRewards > 0) {
                commissionAmount = _netRewards.mul(referralCommissionRate).div(10000);

                if (commissionAmount >= _taxRewards) {
                  commissionAmount = _taxRewards;
                  burnTax = 0;
                }
                else {
                  burnTax = burnTax.sub(commissionAmount);
                }
                calcifireReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
        _safeCalcifireTransfer(BURN_ADDRESS, burnTax);
    }
}