// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IThrottledPool.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IIdPool.sol";
import "./interfaces/IReferrersData.sol";
import "./interfaces/IWhitelist.sol";
import "./libraries/BP.sol";
import "./libraries/StakingPowerLibrary.sol";

/// @title Staking contract
contract Staking is IStaking, UUPSUpgradeable, ReentrancyGuardUpgradeable {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant IDO_ROLE = keccak256("IDO_ROLE");

    using SafeCast for uint;
    using SafeERC20 for IERC20;
    using StakingPowerLibrary for StakingPowerLibrary.StakingPowerData;

    uint16 public constant SCALING_FACTOR = 10_000;

    uint16 private constant REFERRAL_LINK_REWARD_IN_BP = 100; // 1% * BP
    uint16 private constant REFERRER_REWARD_IN_BP = 500; // 5% * BP
    uint16 private constant MAX_REFERRER_BOOSTER_IN_BP = 2000; // 20% * BP
    uint16 private constant EXIT_FEE_IN_BP = 500; // 5% * BP (A 5% staking fee is applied to the user's stake (but not to the rewards) when the user exists before the due time)

    address public override registry;
    address public override token;
    address public override tokenPool;
    address public override whitelist;
    address public override referrersData;

    uint16 public override minTierReferrerBooster;
    uint public override stakesCount;
    uint public override minReferrerStakeAmount;

    StakingPowerLibrary.StakingPowerData public override stakingPowerData;
    mapping(address => mapping(uint => StakeDetails)) public override stakes;
    uint public override lastTierSnapshot;
    
    mapping(address => AccountDetails) private accountOf_;
    mapping(uint => Tier[]) private tierSnapshots_;
    mapping(uint => uint8) private tierSnapshotsColumnCount_;
    mapping(uint => uint8) private tierSnapshotsFirstEarlyUnstakeIndex_;

    /// @notice Initialize contract
    /// @param _registry Registry for account
    /// @param _token Token to stake
    /// @param _tokenPool Pool for shares
    /// @param _referrersData Users with referrers
    /// @param _tiers Booster tiers
    /// @param _tierLength Tiers length
    /// @param _firstEarlyUnstakeIndex First non-zero index
    /// @param _minReferrerStakeAmount Min stake for referrer
    function initialize(
        address _registry,
        address _token,
        address _tokenPool,
        address _referrersData,
        Tier[] calldata _tiers,
        uint8 _tierLength,
        uint8 _firstEarlyUnstakeIndex,
        uint _minReferrerStakeAmount
    ) initializer external {
        __ReentrancyGuard_init();

        require(
            _registry != address(0) &&
            _token != address(0) && 
            _tokenPool != address(0) && 
            _referrersData != address(0), 
            "Staking: ZERO"
        );

        registry = _registry;
        token = _token;
        tokenPool = _tokenPool;
        referrersData = _referrersData;
        minTierReferrerBooster = 0;
        minReferrerStakeAmount = _minReferrerStakeAmount;

        setTiers(_tiers, _tierLength, _firstEarlyUnstakeIndex);
        stakingPowerData.setInfo(5 minutes, 2 minutes);
    }

    /// @notice Get info for account
    /// @param _account User
    /// @return details User details
    function info(address _account) external override view returns (InfoAccountDetails memory details) {
        (uint32 stakingPowerInitialBreak, ) = stakingPowerData.info();
        details = InfoAccountDetails({
            tierLength: tierSnapshotsColumnCount_[lastTierSnapshot],
            tiers: tierSnapshots_[lastTierSnapshot],
            accountDetails: accountOf_[_account],
            minReferrerStakeAmount: minReferrerStakeAmount,
            stakingPowerInitialBreak: stakingPowerInitialBreak,
            whitelistLink: ''
        });
    }

    /// @notice Tiers info
    /// @param _snapshotIndex Snapshot index
    /// @return snapshot Tiers
    /// @return columnCount Number of columns
    /// @return firstEarlyUnstakeIndex First non-zero index
    function tierSnapshotInfo(uint _snapshotIndex) external override view returns (
        Tier[] memory snapshot,
        uint8 columnCount,
        uint8 firstEarlyUnstakeIndex
    ) {
        snapshot = tierSnapshots_[_snapshotIndex];
        columnCount = tierSnapshotsColumnCount_[_snapshotIndex];
        firstEarlyUnstakeIndex = tierSnapshotsFirstEarlyUnstakeIndex_[_snapshotIndex];
    }

    /// @notice Check if user can participate in the IDO
    /// @param _account User
    /// @return if user can partipate
    function canParticipate(address _account) external override view returns (bool) {
        return stakingPowerData.canParticipate(accountOf_[_account].lastIDOParticipation) && 
               stakingPowerData.canParticipate(accountOf_[_account].lastIDORegistration);
    }

    /// @notice Get expected staking power
    /// @param _account User
    /// @param _ids Ids of stakes
    /// @return stakingPower Expected staking power for ids
    function expectedStakingPower(address _account, uint[] calldata _ids) external override view returns (uint[] memory stakingPower) {
        stakingPower = new uint[](_ids.length);
        for (uint i; i < _ids.length; ++i) {
            StakeDetails storage stake_ = stakes[_account][_ids[i]];
            stakingPower[i] = stakingPowerData.expectedStakingPower(stake_.stakingPower, stake_.amountInToken, stake_.startDateInSeconds, stake_.tierBoosterInBP);
        }
    }

    /// @param _whitelist New whitelist address
    function setWhitelist(address _whitelist) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelist = _whitelist;
        emit SetWhitelist(_whitelist);
    }

    /// @notice Set staking power data
    /// @param _stakingPowerInitialBreak Period of time after which user will be able to claim staking power
    /// @param _participationBreak Period of time after which user will be able to participate in the IDO again
    function setStakingPowerData(uint32 _stakingPowerInitialBreak, uint32 _participationBreak) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingPowerData.setInfo(_stakingPowerInitialBreak, _participationBreak);
        emit SetStakingPowerData(_stakingPowerInitialBreak, _participationBreak);
    }

    /// @param _minTierReferrerBooster New referrer booster
    function setMinTierReferrerBooster(uint16 _minTierReferrerBooster) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minTierReferrerBooster < tierSnapshots_[lastTierSnapshot].length, "Staking: INVALID_TIER");
        minTierReferrerBooster = _minTierReferrerBooster;
        emit SetMinTierReferrerBooster(_minTierReferrerBooster);
    }

    /// @param _minReferrerStakeAmount New minimal referrer stake amount
    function setMinReferrerStakeAmount(uint _minReferrerStakeAmount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        minReferrerStakeAmount = _minReferrerStakeAmount;
        emit SetMinReferrerStakeAmount(_minReferrerStakeAmount);
    }

    /// @notice Create stake
    /// @param _amount Amount to stake
    /// @param _row Selected row
    /// @param _column Selected column
    function stake(
        uint _amount,
        uint8 _row,
        uint8 _column
    )  
        external 
        override
        nonReentrant 
    {
        _stake(StakeInfo({referrer: IReferrersData(referrersData).parentOf(msg.sender), row: _row, column: _column, amount: _amount}));
    }

    /// @notice Create stake with referrer
    /// @param _stakeParams stake params
    function stakeWithReferrer(StakeWithReferrerParams calldata _stakeParams)  
        external 
        override
        nonReentrant 
    {
        _processReferring(
            _stakeParams.signaturesUser, 
            _stakeParams.referrer, 
            _stakeParams.signaturesReferrer, 
            _stakeParams.signers
        );
        _stake(StakeInfo({referrer: _stakeParams.referrer, row: _stakeParams.row, column: _stakeParams.column, amount: _stakeParams.amount}));
    }

    /// @notice Create stake with permit
    /// @param _details permit details
    function stakeWithPermit(PermitStakeDetails calldata _details) 
        external 
        override  
        nonReentrant 
    {
        IERC20Permit(token).permit(
            msg.sender, 
            address(this), 
            _details.amount, 
            _details.deadline, 
            _details.v,
            _details.r, 
            _details.s
        );
        _stake(StakeInfo({
            referrer: IReferrersData(referrersData).parentOf(msg.sender),
            row: _details.row,
            column: _details.column,
            amount: _details.amount
        }));
    }

    /// @notice Create stake with permit and referrer
    /// @param _details permit details
    function stakeWithPermitWithReferrer(PermitStakeDetailsWithReferrer calldata _details) 
        external 
        override  
        nonReentrant 
    {
        IERC20Permit(token).permit(
            msg.sender, 
            address(this), 
            _details.amount, 
            _details.deadline, 
            _details.v,
            _details.r,
            _details.s
        );
        _processReferring(
            _details.signaturesUser, 
            _details.referrer, 
            _details.signaturesReferrer, 
            _details.signers
        );
        _stake(StakeInfo({
            referrer: _details.referrer,
            row: _details.row,
            column: _details.column,
            amount: _details.amount
        }));
    }

    /// @notice Unstake
    /// @param _id stake's id
    function unstake(uint _id) 
        external 
        override
        nonReentrant 
    {
        _unstake(msg.sender, _id, false);
    }

    function unstakeWithoutFee(address _address, uint _id) 
        external
        override  
        nonReentrant 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _unstake(_address, _id, true);
    }

    function _unstake(address _address, uint _id, bool _withoutFee) 
        private 
        accumulateRewards(_address, accountOf_[_address].referrer, _id) 
    {
        StakeDetails storage stakeDetails = stakes[_address][_id];
        require(stakeDetails.stakeId != 0, "Staking: INVALID_ID");
        StakeRewardDetails memory stakeRewardDetails = _sendStakeReward(_address, stakeDetails, _withoutFee);
        {
            uint amountInToken = stakeDetails.amountInToken;
            accountOf_[_address].totalStake -= amountInToken;
            accountOf_[_address].totalBoostedStake -= (amountInToken * (BP.DECIMAL_FACTOR + stakeDetails.tierBoosterInBP)) / BP.DECIMAL_FACTOR;
        }
      
        if (stakeRewardDetails.earlyExitFee > 0) {
            IERC20(token).safeTransfer(IThrottledPool(tokenPool).emissionController(), stakeRewardDetails.earlyExitFee);
        }
        if (stakes[_address][_id].stakingPower > 0) {
            accountOf_[_address].totalStakingPower -= stakes[_address][_id].stakingPower;
        }
        delete stakes[_address][_id];
        emit Unstake(_address, _id, stakeRewardDetails.amountInToken + stakeRewardDetails.stakeProfit, stakeRewardDetails.earlyExitFee);
    }

    /// @notice Update staking power
    /// @param _account User
    /// @param _ids stakes to update
    function updateStakingPower(address _account, uint[] calldata _ids) external override {
        for (uint i; i < _ids.length; ++i) {
            _updateStakingPowerForId(_account, _ids[i]);
        }
    }

    /// @notice Set user's registration date
    /// @param _account User
    /// @param _registrationDate IDO registration date
    function setLastRegistrationDate(address _account, uint _registrationDate) external override onlyRole(IDO_ROLE) {
        accountOf_[_account].lastIDORegistration = _registrationDate;
        emit SetLastRegistrationDate(msg.sender, _account, _registrationDate);
    }

    /// @notice Set user's participation date
    /// @param _account User
    /// @param _participationDate IDO participation date
    function setLastParticipationDate(address _account, uint _participationDate) external override onlyRole(IDO_ROLE) {
        accountOf_[_account].lastIDOParticipation = _participationDate;
        emit SetLastParticipationDate(msg.sender, _account, _participationDate);
    }

    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "Staking: FORBIDDEN");
        _;
    }

    modifier accumulateRewards(address _address, address _referrer, uint _id) {
        uint lastIdTierBoosterInBP = _referralBoosterOfId(_address, _id);
        uint lastBoostedStake = _referralBoostedStakeOf(_address);
        uint lastBoostedStakeOfReferrer = _referralBoostedStakeOf(_referrer);
        uint stakeShare;
        if (stakes[_address][_id].stakeId != 0) {
            stakeShare = stakes[_address][_id].amountInToken;
        }

        _;

        uint idTierBoosterInBP = _referralBoosterOfId(_address, _id);

        // Change boosters shares
        if (stakeShare == 0) {
            stakeShare = stakes[_address][_id].amountInToken;
        }
        _changeShares(_address, stakeShare, _referralBoostedStakeOf(_address), lastBoostedStake, _id);

        // Change referrer's shares (be referrer and referee)
        _updateReferralBooster(_address, _referrer, idTierBoosterInBP.toUint16(), lastIdTierBoosterInBP.toUint16());
        _changeShares(_referrer, 0, _referralBoostedStakeOf(_referrer), lastBoostedStakeOfReferrer, 0);
    }

    function setTiers(
        Tier[] calldata _tiers,
        uint8 _tierLength,
        uint8 _firstEarlyUnstakeIndex
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _tiers.length >= 2 // zero tier + 1 other tier
            && _tierLength > 0
            && _tiers.length <= type(uint8).max,
            "Staking: INVALID_ARGUMENTS"
        );
        uint currentSnapshot = ++lastTierSnapshot;
        
        for (uint i; i < _tiers.length; ++i) {
            if (i > 0) {
                require(_tiers[i - 1].boosterInBP < _tiers[i].boosterInBP || _tiers[i - 1].thresholdInToken < _tiers[i].thresholdInToken, "Staking: INVALID_ORDER");
            }
            tierSnapshots_[currentSnapshot].push(_tiers[i]);
        }
        tierSnapshotsColumnCount_[currentSnapshot] = _tierLength;
        tierSnapshotsFirstEarlyUnstakeIndex_[currentSnapshot] = _firstEarlyUnstakeIndex;
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _linearTierBoosterInBP(
        uint _startAmount,
        uint16 _startTierBoosterInBP,
        uint _endAmount,
        uint16 _endTierBoosterInBP,
        uint _currentAmount
    ) private pure returns (uint16) {
        if (_startTierBoosterInBP == _endTierBoosterInBP || _currentAmount == _startAmount) {
            return _startTierBoosterInBP;
        }
        if (_currentAmount == _endAmount) {
            return _endTierBoosterInBP;
        }
        require(_endAmount > _startAmount 
                && _endTierBoosterInBP > _startTierBoosterInBP
                && _currentAmount >= _startAmount, "Staking: INVALID_PARAMETERS");

        uint diff = SCALING_FACTOR * (_currentAmount - _startAmount) / (_endAmount - _startAmount);
        return (_startTierBoosterInBP + ((_endTierBoosterInBP - _startTierBoosterInBP) * diff) / SCALING_FACTOR).toUint16();
    }

    function _tierBoostedStake(uint _tierBoosterInBP, uint _amountInToken) private pure returns (uint) {
        return (BP.DECIMAL_FACTOR + _tierBoosterInBP) * _amountInToken / BP.DECIMAL_FACTOR;
    }

    function _referralBoosterOfId(address _account, uint _id) private view returns (uint _referralTierBoosterInBP) {
        if (stakes[_account][_id].stakeId == 0) {
            return 0;
        }
        _referralTierBoosterInBP = uint(stakes[_account][_id].tierBoosterInBP) * REFERRER_REWARD_IN_BP / BP.DECIMAL_FACTOR;
    }

    function _referralBoostedStakeOf(
        address _account
    ) private view returns (uint) {
        if (_account == address(0)) {
            return 0;
        }
        AccountDetails storage account = accountOf_[_account];
        uint averageBoosterInBP;
        if (account.totalStake > 0) {
           averageBoosterInBP = (account.totalBoostedStake * BP.DECIMAL_FACTOR / account.totalStake) - BP.DECIMAL_FACTOR;
        }
        uint referralLinkBoosterInBP = account.referrer == address(0) ? 0 : REFERRAL_LINK_REWARD_IN_BP;
        uint16 referralBoosterInBP = uint16(Math.min(MAX_REFERRER_BOOSTER_IN_BP, account.referralBoosterInBP));
        return (BP.DECIMAL_FACTOR + referralBoosterInBP + referralLinkBoosterInBP + averageBoosterInBP) * account.totalStake / BP.DECIMAL_FACTOR;
    }

    // This function uses only for early unstakes (no zero-time)
    function _actualTierBoosterInBP(
        uint _actualDuration, 
        StakeDetails storage _stakeDetails
    ) private view returns (uint) {
        Tier[] storage snapshotTiers = tierSnapshots_[_stakeDetails.tierSnapshot];
        uint snapshotTiersColumnsCount = tierSnapshotsColumnCount_[_stakeDetails.tierSnapshot];
        uint earlyUnstakeIndex = tierSnapshotsFirstEarlyUnstakeIndex_[_stakeDetails.tierSnapshot];

        // if less than first vesting period
        if (_actualDuration < snapshotTiers[earlyUnstakeIndex].vestingLockPeriodInSeconds) { 
            return _linearTierBoosterInBP(0, 0, snapshotTiers[earlyUnstakeIndex].vestingLockPeriodInSeconds, _stakeDetails.tierBoosterInBP, _actualDuration);
        } 
        // if more than last vesting period
        uint startColumnByTimestamp;
        for (uint i = 1; i < snapshotTiersColumnsCount; ++i) {
            if (_actualDuration < snapshotTiers[i].vestingLockPeriodInSeconds) {
                startColumnByTimestamp = i - 1;
                break;
            }
        }
        uint row = _stakeDetails.nextTierIndex / snapshotTiersColumnsCount;
        Tier storage startTier = snapshotTiers[row * snapshotTiersColumnsCount + startColumnByTimestamp];
        uint16 startBoosterInBP = startTier.boosterInBP;

        if (_stakeDetails.amountInToken < startTier.thresholdInToken) { // if we need to find new start tier
            Tier storage prevTier = snapshotTiers[(row - 1) * snapshotTiersColumnsCount + startColumnByTimestamp];
            startBoosterInBP = _linearTierBoosterInBP(
                                    prevTier.thresholdInToken, 
                                    prevTier.boosterInBP, 
                                    startTier.thresholdInToken, 
                                    startTier.boosterInBP, 
                                    _stakeDetails.amountInToken
                                );
        }

        return _linearTierBoosterInBP(
                    startTier.vestingLockPeriodInSeconds, 
                    startBoosterInBP, 
                    _stakeDetails.durationInSeconds, 
                    _stakeDetails.tierBoosterInBP, 
                    _actualDuration
                );
    }

    function _boosterInfoForStake(StakeInfo memory _stakeInfo) private view returns (uint16 tierBoosterInBP, uint8 nextTierIndex, Tier storage nextTier) {
        Tier[] storage tiers = tierSnapshots_[lastTierSnapshot];
        uint8 snapshotTiersColumnsCount = tierSnapshotsColumnCount_[lastTierSnapshot];
        uint8 rowsCount = (tiers.length / snapshotTiersColumnsCount).toUint8();
        nextTierIndex = _stakeInfo.row * snapshotTiersColumnsCount + _stakeInfo.column;
        nextTier = tiers[nextTierIndex];
        tierBoosterInBP = nextTier.boosterInBP;

        if (_stakeInfo.row == 0 && _stakeInfo.amount < nextTier.thresholdInToken) { // User stakes amount that is less than 1st tier
            tierBoosterInBP = _linearTierBoosterInBP(0, 0, nextTier.thresholdInToken, nextTier.boosterInBP, _stakeInfo.amount);
        } else if (nextTier.thresholdInToken > _stakeInfo.amount) { // Between tiers
            Tier storage prevTier = tiers[(_stakeInfo.row - 1) * snapshotTiersColumnsCount + _stakeInfo.column];
            require(_stakeInfo.amount >= prevTier.thresholdInToken && _stakeInfo.amount <= nextTier.thresholdInToken, "Staking: INVALID_ARGUMENT");
            tierBoosterInBP = _linearTierBoosterInBP(prevTier.thresholdInToken, prevTier.boosterInBP, nextTier.thresholdInToken, nextTier.boosterInBP, _stakeInfo.amount);
        } else { // In other cases tierBoosterInBP stays the same
            require(_stakeInfo.amount >= nextTier.thresholdInToken, "Staking: INVALID_AMOUNT");
            if (_stakeInfo.row < rowsCount - 1) { // if now last tier
                require(_stakeInfo.amount < tiers[nextTierIndex + snapshotTiersColumnsCount].thresholdInToken, "Staking: INVALID_AMOUNT");
            }
        }   
    }

    function _stake(StakeInfo memory _stakeInfo) accumulateRewards(msg.sender, _stakeInfo.referrer, ++stakesCount) private {
        require(_stakeInfo.amount > 0, "Staking: ZERO_AMOUNT");        
        (uint16 tierBoosterInBP, uint8 nextTierIndex, Tier storage nextTier) = _boosterInfoForStake(_stakeInfo);
 
        AccountDetails storage account = accountOf_[msg.sender];
        IERC20(token).safeTransferFrom(msg.sender, address(this), _stakeInfo.amount);
        
        account.totalStake += _stakeInfo.amount;
        account.totalBoostedStake += (_stakeInfo.amount * (BP.DECIMAL_FACTOR + tierBoosterInBP)) / BP.DECIMAL_FACTOR;

        stakes[msg.sender][stakesCount] = StakeDetails({
            stakeId: stakesCount,
            amountInToken: _stakeInfo.amount,
            stakingPower: 0,
            startDateInSeconds: block.timestamp.toUint64(),
            durationInSeconds: nextTier.vestingLockPeriodInSeconds.toUint32(),
            tierBoosterInBP: tierBoosterInBP,
            nextTierIndex: nextTierIndex,
            tierSnapshot: uint136(lastTierSnapshot)
        });

        if (_stakeInfo.referrer != address(0) && account.referrer == address(0)) {
            account.referrer = _stakeInfo.referrer;
        }

        emit Stake(msg.sender, _stakeInfo.referrer, stakesCount);
    }

    function _updateReferralBooster(address _address, address _referrer, uint16 _newReferralBoosterInBP, uint16 _lastReferralBoosterInBP) private {
        // We can use current tiers, because this condition works only on stake
        if (_referrer == address(0) 
            || (_newReferralBoosterInBP >= _lastReferralBoosterInBP 
                && accountOf_[_address].totalStake < tierSnapshots_[lastTierSnapshot][minTierReferrerBooster].thresholdInToken)) {
            return;
        }

        if (_newReferralBoosterInBP > _lastReferralBoosterInBP) { // stake
            accountOf_[_referrer].referralBoosterInBP += _newReferralBoosterInBP;
        } else if (_lastReferralBoosterInBP > _newReferralBoosterInBP) { // unstake
            accountOf_[_referrer].referralBoosterInBP -= _lastReferralBoosterInBP;
        }
    }

    function _changeShares(address _account, uint _stakeShare, uint _current, uint _prev, uint _id) private {
        if (_current > _prev) {
            IIdPool(tokenPool).mintForId(_account, _stakeShare, _current - _prev, _id);
        } else if (_prev > _current) {
            IIdPool(tokenPool).burnForId(_account, _stakeShare, _prev - _current, _id);
        }
    }

    function _sendStakeReward(address _address, StakeDetails storage _stakeDetails, bool _withoutFee) private returns (
        StakeRewardDetails memory details
    ) {
        uint amountInToken = _stakeDetails.amountInToken;
        uint currentIdStake = _tierBoostedStake(_stakeDetails.tierBoosterInBP, _stakeDetails.amountInToken);
        uint actualCurrentIdStake = currentIdStake;
        uint earlyExitFee = 0;
        if (_stakeDetails.startDateInSeconds + _stakeDetails.durationInSeconds > block.timestamp) { // early exit
            uint actualDuration = block.timestamp - _stakeDetails.startDateInSeconds;

            actualCurrentIdStake = _tierBoostedStake(
                _actualTierBoosterInBP(actualDuration, _stakeDetails),
                amountInToken
            );

            // 5% fee from the initial amount
            if (!_withoutFee) {
                earlyExitFee = amountInToken * EXIT_FEE_IN_BP / BP.DECIMAL_FACTOR;
                amountInToken -= earlyExitFee;
            }
        }
        IERC20(token).safeTransfer(_address, amountInToken);
        // Stake reward
        uint totalBoostedStake = accountOf_[_address].totalBoostedStake;
        uint stakeProfit = _stakeProfit(_address, tokenPool, _stakeDetails.stakeId, currentIdStake, actualCurrentIdStake, totalBoostedStake);
        details = StakeRewardDetails({
            amountInToken: amountInToken,
            earlyExitFee: earlyExitFee,
            stakeProfit: stakeProfit
        });
    }

    function _stakeProfit(
        address _account, 
        address _poolAddress, 
        uint _stakeId, 
        uint _currentIdStake, 
        uint _actualCurrentIdStake, 
        uint _totalBoostedStake
    ) private returns (uint stakeProfit) {
        stakeProfit = IIdPool(_poolAddress).withdrawableRewardsForId(_account, _stakeId);
        uint fee;
        if (_currentIdStake != _actualCurrentIdStake) { // early exit
            uint actualStakeProfit = ((_actualCurrentIdStake * stakeProfit * SCALING_FACTOR) / _totalBoostedStake) / SCALING_FACTOR;
            fee = stakeProfit - actualStakeProfit;
            stakeProfit = actualStakeProfit;
        }
        IStakingPool(_poolAddress).withdrawForAccount(_account, _stakeId, stakeProfit, fee);
    }

    function _updateStakingPowerForId(address _account, uint _id) private {
        StakeDetails storage stake_ = stakes[_account][_id];
        require(stake_.amountInToken > 0, "Staking: INVALID_ID");
        if (stake_.stakingPower > 0) {
            return;
        }

        uint stakingPower = stakingPowerData.expectedStakingPower(stake_.stakingPower, stake_.amountInToken, stake_.startDateInSeconds, stake_.tierBoosterInBP);
        if (stakingPower > 0) {
            stakes[_account][_id].stakingPower = stakingPower;
            accountOf_[_account].totalStakingPower += stakingPower;
            emit UpdateStakingPowerForId(msg.sender, _account, _id, stakingPower);
        }
    }

    function _processReferring(
        bytes[] calldata _signaturesUser,
        address _referrer,
        bytes[] calldata _signaturesReferrer,
        address[] calldata _signers
    ) private {
        address parent = IReferrersData(referrersData).parentOf(msg.sender);
        if ((_referrer == address(0) && parent == address(0)) || parent == _referrer) {
            return;
        }
        require(
            msg.sender != _referrer &&
            IReferrersData(referrersData).parentOf(_referrer) != msg.sender &&
            whitelist != address(0) &&
            _signers.length > 0 &&
            IWhitelist(whitelist).isAddressWhitelisted(_encodeData(msg.sender), _signaturesUser, _signers) &&
            IWhitelist(whitelist).isAddressWhitelisted(_encodeData(_referrer), _signaturesReferrer, _signers) &&
            accountOf_[_referrer].totalStake >= minReferrerStakeAmount,
            "Staking: REFERRING_NOT_VALID"
        );
        IReferrersData(referrersData).addUser(msg.sender, _referrer);
    }

    function _encodeData(address _user) private pure returns (bytes memory) {
        return abi.encode(_user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IStaking {
    event SetWhitelist(address whitelist);
    event SetMinTierReferrerBooster(uint16 minTierReferrerBooster);
    event SetMinReferrerStakeAmount(uint minReferrerStakeAmount);
    event Stake(address indexed account, address indexed referrer, uint stakeId);
    event Unstake(address indexed account, uint stakeId, uint amountInToken, uint exitFeeInToken);
    event SetStakingPowerData(uint32 stakingPowerInitialBreak, uint32 participationBreak);
    event SetLastRegistrationDate(address indexed caller, address account, uint registrationDate);
    event SetLastParticipationDate(address indexed caller, address account, uint participationDate);
    event UpdateStakingPowerForId(address indexed caller, address indexed account, uint id, uint stakingPower);

    struct Tier {
        // % booster for tier qualification
        uint16 boosterInBP;
        // amount of LIFT required to qualify for this tier
        uint240 thresholdInToken;
        // vesting period
        uint vestingLockPeriodInSeconds;
    }

    struct AccountDetails {
        uint totalBoostedStake; // 256
        uint totalStake; // 256
        uint totalStakingPower; // 256
        uint lastIDOParticipation; // 256
        address referrer; // 160
        uint16 referralBoosterInBP; // 160 + 16 = 176
        uint lastIDORegistration; // 256
    }

    struct StakeDetails {
        uint stakeId; // 256
        uint amountInToken; // 256
        uint stakingPower; // 256
        uint64 startDateInSeconds; // 64
        // in seconds this is 136 years
        uint32 durationInSeconds; // 64 + 32 = 96
        uint16 tierBoosterInBP; // 64 + 32 + 16 = 112
        uint8 nextTierIndex; // 64 + 32 + 16 + 8 = 120
        uint136 tierSnapshot; // 64 + 32 + 16 + 8 + 136 = 256
    }

    struct InfoAccountDetails {
        uint8 tierLength; 
        Tier[] tiers; 
        AccountDetails accountDetails;
        uint minReferrerStakeAmount;
        uint32 stakingPowerInitialBreak;
        string whitelistLink;
    }

    struct StakeInfo {
        address referrer;
        uint8 row;
        uint8 column;
        uint amount;
    }

    struct PermitStakeDetails {
        uint amount;
        uint8 row;
        uint8 column;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct StakeRewardDetails {
        uint amountInToken;
        uint earlyExitFee;
        uint stakeProfit;
    }

    struct PermitStakeDetailsWithReferrer {
        bytes[] signaturesUser;
        address referrer;
        bytes[] signaturesReferrer;
        address[] signers;
        uint amount;
        uint8 row;
        uint8 column;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct StakeWithReferrerParams {
        bytes[] signaturesUser;
        address referrer;
        bytes[] signaturesReferrer;
        address[] signers;
        uint amount;
        uint8 row;
        uint8 column;
    }

    function registry() external view returns (address);
    function token() external view returns (address);
    function tokenPool() external view returns (address);
    function whitelist() external view returns (address);
    function referrersData() external view returns (address);
    function stakingPowerData() external view returns (uint32 stakingPowerInitialBreak, uint32 participationBreak);
    
    function minTierReferrerBooster() external view returns (uint16);
    function stakesCount() external view returns (uint);
    function minReferrerStakeAmount() external view returns (uint);

    function stakes(address, uint) external view returns (
        uint stakeId,
        uint amountInToken,
        uint stakingPower,
        uint64 startDateInSeconds,
        uint32 durationInSeconds,
        uint16 tierBoosterInBP,
        uint8 nextTierIndex,
        uint136 tierSnapshot
    );
    function lastTierSnapshot() external view returns (uint);
    function setWhitelist(address _whitelist) external;
    function setMinTierReferrerBooster(uint16 _minTierReferrerBooster) external;
    function setMinReferrerStakeAmount(uint _minReferrerStakeAmount) external;
    function stake(uint _amount, uint8 _row, uint8 _column) external;
    function stakeWithReferrer(StakeWithReferrerParams calldata _stakeParams) external;
    function stakeWithPermit(PermitStakeDetails calldata _details) external;
    function stakeWithPermitWithReferrer(PermitStakeDetailsWithReferrer calldata _details) external;
    function unstake(uint _id) external;
    function unstakeWithoutFee(address _address, uint _id) external;
    function setStakingPowerData(uint32 _stakingPowerInitialBreak, uint32 _participationBreak) external;
    function setTiers(Tier[] calldata _tiers, uint8 _tierLength, uint8 _firstEarlyUnstakeIndex) external;
    function info(address _account) external view returns (InfoAccountDetails memory details);
    function tierSnapshotInfo(uint _snapshotIndex) external view returns (
        Tier[] memory snapshot,
        uint8 columnCount,
        uint8 firstEarlyUnstakeIndex
    );
    function canParticipate(address _account) external view returns (bool);
    function expectedStakingPower(address _account, uint[] calldata _ids) external view returns (uint[] memory stakingPower);
    function setLastRegistrationDate(address _account, uint _registrationDate) external;
    function setLastParticipationDate(address _account, uint _participationDate) external;
    function updateStakingPower(address _account, uint[] calldata _ids) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IPool {
    event SetToken(address token);
    event Mint(address indexed account, uint amount);
    event Burn(address indexed account, uint amount);
    event Withdraw(address indexed account, uint reward);

    function balanceOf(address _account) external view returns (uint);
    function registry() external view returns (address);
    function token() external view returns (address);
    function totalSupply() external view returns (uint);

    function setToken(address _token) external;
    function mint(address _account, uint _amount) external;
    function burn(address _account, uint _amount) external;
    function withdraw() external returns (uint);
    function withdrawableRewardsOf(address _account) external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IThrottledPool {
    event SetEmissionController(address emissionController);
    event SetTokensPerSeconds(uint64 emittedTokensPerSecond);

    function emissionController() external view returns (address);

    function setEmissionController(address _emissionController) external;
    function setTokensPerSeconds(uint64 _emittedTokensPerSecond) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IStakingPool {
    event WithdrawForAccount(address indexed account, uint withdrawAmount, uint fee, uint id);

    function withdrawForAccount(address _account, uint _id, uint _withdrawAmount, uint _fee) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IIdPool {
    event MintForId(address indexed account, uint amount, uint id);
    event BurnForId(address indexed account, uint amount, uint id);
    event WithdrawForId(address indexed account, uint reward, uint id);

    function idBalanceOf(address, uint) external view returns (uint);
    function accountTotalSupply(address) external view returns (uint);

    function mintForId(address _account, uint _idAmount, uint _totalAmount, uint _id) external;
    function burnForId(address _account, uint _idAmount, uint _totalAmount, uint _id) external;
    function withdrawForId(uint _id) external returns (uint);
    function withdrawableRewardsForId(address _account, uint _id) external returns (uint);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IReferrersData {
    event MigrateUser(address indexed user, address parent);
    event AddUser(address sender, address indexed user, address parent);

    function registry() external view returns (address);
    function parentOf(address) external view returns (address);

    function parentsOf(address _user) external view returns (address parent, address grandparent);
    function parentsOfUsers(address[] calldata _users) external view returns (address[] memory parents);

    function migrateUsers(address[] calldata _users, address[] calldata _parents) external;
    function addUser(address _user, address _parent) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IWhitelist {

    event SetSignaturesRequiredForValidation(address indexed sender, uint8 signaturesRequiredForValidation);

    function signaturesRequiredForValidation() external view returns (uint8);
    function registry() external view returns (address);
    function setSignaturesRequiredForValidation(uint8 _signaturesRequiredForValidation) external;
    function isAddressWhitelisted(bytes calldata _dataToSign, bytes[] calldata _signatures, address[] calldata _signers) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

library BP {
    uint16 constant DECIMAL_FACTOR = 10000;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "./BP.sol";

library StakingPowerLibrary {

    struct StakingPowerData {
        // uint32 in seconds = 136 years 
        uint32 stakingPowerInitialBreak;
        uint32 participationBreak;
    }

    function info(StakingPowerData storage self) internal view returns (uint32 _stakingPowerInitialBreak, uint32 _participationBreak) {
        _stakingPowerInitialBreak = self.stakingPowerInitialBreak;
        _participationBreak = self.participationBreak;
    }
    
    function canParticipate(StakingPowerData storage self, uint _lastIDOParticipation) internal view returns (bool) {
        return _lastIDOParticipation == 0 || block.timestamp - _lastIDOParticipation >= self.participationBreak;
    }

    function expectedStakingPower(
        StakingPowerData storage self, 
        uint _currentStakingPowerOf,
        uint _amountInToken,
        uint64 _startDateInSeconds,
        uint16 _tierBoosterInBP
    ) internal view returns (uint) {
        if (_currentStakingPowerOf > 0) {
            return _currentStakingPowerOf;
        }
        if (_amountInToken == 0 || _startDateInSeconds + self.stakingPowerInitialBreak > block.timestamp) {
            return 0;
        }
        return (_amountInToken * (BP.DECIMAL_FACTOR + _tierBoosterInBP)) / BP.DECIMAL_FACTOR;
    }

    function setInfo(
        StakingPowerData storage self,
        uint32 _stakingPowerInitialBreak,
        uint32 _participationBreak
    ) internal {
        self.stakingPowerInitialBreak = _stakingPowerInitialBreak;
        self.participationBreak = _participationBreak;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}