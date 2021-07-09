// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./tokens/erc20permit-upgradeable/ERC20PermitUpgradeable.sol";
import "./interfaces/helpers/IPriceFeed.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/ILiquidityMining.sol";
import "./interfaces/IPolicyQuote.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/ILiquidityRegistry.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract PolicyBook is IPolicyBook, ERC20PermitUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
    uint256 public constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

    uint256 public constant PROTOCOL_PERCENTAGE = 20 * PRECISION;

    uint256 public constant RISKY_UTILIZATION_RATIO = 80 * PRECISION;
    uint256 public constant MODERATE_UTILIZATION_RATIO = 50 * PRECISION;

    uint256 public constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
    uint256 public constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;

    uint256 public constant MINIMUM_REWARD = 15 * PRECISION; // 0.15
    uint256 public constant MAXIMUM_REWARD = 2 * PERCENTAGE_100; // 2.0
    uint256 public constant BASE_REWARD = PERCENTAGE_100; // 1.0

    uint256 public constant override EPOCH_DURATION = 1 weeks;
    uint256 public constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
    uint256 public constant VIRTUAL_EPOCHS = 2;

    uint256 public constant WITHDRAWAL_PERIOD = 8 days;
    uint256 public constant override READY_TO_WITHDRAW_PERIOD = 2 days;

    bool public override whitelisted;

    uint256 public override epochStartTime;
    uint256 public lastDistributionEpoch;

    uint256 public lastPremiumDistributionEpoch;
    int256 public lastPremiumDistributionAmount;

    address public override insuranceContractAddress;
    IPolicyBookFabric.ContractType public override contractType;

    IPriceFeed public priceFeed;
    ERC20 public stblToken;
    IPolicyRegistry public policyRegistry;
    IBMICoverStaking public bmiCoverStaking;
    IRewardsGenerator public rewardsGenerator;
    ILiquidityMining public liquidityMining;
    IClaimVoting public claimVoting;
    IClaimingRegistry public claimingRegistry;
    ILiquidityRegistry public liquidityRegistry;
    address public reinsurancePoolAddress;
    IPolicyQuote public policyQuote;
    address public policyBookAdmin;
    address public policyBookRegistry;
    address public policyBookFabricAddress;

    uint256 public override totalLiquidity;
    uint256 public override totalCoverTokens;

    mapping(address => WithdrawalInfo) public override withdrawalsInfo;
    mapping(address => PolicyHolder) public policyHolders;
    mapping(address => uint256) public liquidityFromLM;
    mapping(uint256 => uint256) public epochAmounts;
    mapping(uint256 => int256) public premiumDistributionDeltas;

    uint256 public stblDecimals;

    event LiquidityAdded(
        address _liquidityHolder,
        uint256 _liquidityAmount,
        uint256 _newTotalLiquidity
    );
    event WithdrawalRequested(
        address _liquidityHolder,
        uint256 _tokensToWithdraw,
        uint256 _readyToWithdrawDate
    );
    event LiquidityWithdrawn(
        address _liquidityHolder,
        uint256 _tokensToWithdraw,
        uint256 _newTotalLiquidity
    );
    event PolicyBought(
        address _policyHolder,
        uint256 _coverTokens,
        uint256 _price,
        uint256 _newTotalCoverTokens
    );
    event CoverageChanged(uint256 _newTotalCoverTokens);

    modifier onlyClaimVoting() {
        require(_msgSender() == address(claimVoting), "PB: Not a CV");
        _;
    }

    modifier onlyPolicyBookRegistry() {
        require(_msgSender() == policyBookRegistry, "PB: Not a PBR");
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(_msgSender() == policyBookAdmin, "PB: Not a PBA");
        _;
    }

    modifier onlyLiquidityAdders() {
        require(
            _msgSender() == address(liquidityMining) || _msgSender() == policyBookFabricAddress,
            "PB: Not allowed"
        );
        _;
    }

    modifier updateBMICoverStakingReward() {
        _;
        _updateBMICoverStakingReward();
    }

    modifier withPremiumsDistribution() {
        _distributePremiums();
        _;
    }

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external override initializer {
        string memory fullSymbol = string(abi.encodePacked("bmi", _projectSymbol, "Cover"));
        __ERC20Permit_init(fullSymbol);
        __ERC20_init(_description, fullSymbol);

        insuranceContractAddress = _insuranceContract;
        contractType = _contractType;

        epochStartTime = block.timestamp;
        lastDistributionEpoch = 1;

        lastPremiumDistributionEpoch = _getPremiumDistributionEpoch();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
        rewardsGenerator = IRewardsGenerator(_contractsRegistry.getRewardsGeneratorContract());
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        policyRegistry = IPolicyRegistry(_contractsRegistry.getPolicyRegistryContract());
        reinsurancePoolAddress = _contractsRegistry.getReinsurancePoolContract();
        policyQuote = IPolicyQuote(_contractsRegistry.getPolicyQuoteContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        liquidityRegistry = ILiquidityRegistry(_contractsRegistry.getLiquidityRegistryContract());
        policyBookAdmin = _contractsRegistry.getPolicyBookAdminContract();
        policyBookRegistry = _contractsRegistry.getPolicyBookRegistryContract();
        policyBookFabricAddress = _contractsRegistry.getPolicyBookFabricContract();

        stblDecimals = stblToken.decimals();
    }

    function whitelist(bool _whitelisted)
        external
        override
        onlyPolicyBookAdmin
        updateBMICoverStakingReward
    {
        whitelisted = _whitelisted;
    }

    function getEpoch(uint256 time) public view override returns (uint256) {
        return time.sub(epochStartTime).div(EPOCH_DURATION) + 1;
    }

    function _getPremiumDistributionEpoch() internal view returns (uint256) {
        return block.timestamp / PREMIUM_DISTRIBUTION_EPOCH;
    }

    function _getSTBLToBMIXRatio(uint256 currentLiquidity) internal view returns (uint256) {
        uint256 _currentTotalSupply = totalSupply();

        if (_currentTotalSupply == 0) {
            return PERCENTAGE_100;
        }

        return currentLiquidity.mul(PERCENTAGE_100).div(_currentTotalSupply);
    }

    function convertBMIXToSTBL(uint256 _amount) public view override returns (uint256) {
        (, uint256 currentLiquidity) = getNewCoverAndLiquidity();

        return _amount.mul(_getSTBLToBMIXRatio(currentLiquidity)).div(PERCENTAGE_100);
    }

    function convertSTBLToBMIX(uint256 _amount) public view override returns (uint256) {
        (, uint256 currentLiquidity) = getNewCoverAndLiquidity();

        return _amount.mul(PERCENTAGE_100).div(_getSTBLToBMIXRatio(currentLiquidity));
    }

    // TODO possible sandwich attack or allowance fluctuation
    function getClaimApprovalAmount(address user) external view override returns (uint256) {
        return
            priceFeed.howManyBMIsInUSDT(
                DecimalsConverter.convertFrom18(
                    policyHolders[user].coverTokens.div(100),
                    stblDecimals
                )
            );
    }

    function _submitClaimAndInitializeVoting(string memory evidenceURI, bool appeal) internal {
        uint256 cover = policyHolders[_msgSender()].coverTokens;
        uint256 virtualEndEpochNumber =
            policyHolders[_msgSender()].endEpochNumber + VIRTUAL_EPOCHS;

        /// @dev "lock" claim and appeal tokens
        if (!appeal) {
            epochAmounts[virtualEndEpochNumber] = epochAmounts[virtualEndEpochNumber].sub(cover);
        } else {
            uint256 claimIndex = claimingRegistry.claimIndex(_msgSender(), address(this));
            uint256 endLockEpoch =
                Math.max(
                    getEpoch(claimingRegistry.claimEndTime(claimIndex)) + 1,
                    virtualEndEpochNumber
                );

            epochAmounts[endLockEpoch] = epochAmounts[endLockEpoch].sub(cover);
        }

        /// @dev if appeal period expired, this would fail in case of appeal (no button is displayed on FE)
        claimVoting.initializeVoting(
            _msgSender(),
            address(this),
            evidenceURI,
            cover,
            policyHolders[_msgSender()].paid.mul(PROTOCOL_PERCENTAGE).div(PERCENTAGE_100),
            appeal
        );
    }

    function submitClaimAndInitializeVoting(string calldata evidenceURI) external override {
        _submitClaimAndInitializeVoting(evidenceURI, false);
    }

    function submitAppealAndInitializeVoting(string calldata evidenceURI) external override {
        _submitClaimAndInitializeVoting(evidenceURI, true);
    }

    function commitClaim(
        address claimer,
        uint256 claimAmount,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external override onlyClaimVoting withPremiumsDistribution updateBMICoverStakingReward {
        updateEpochsInfo();

        if (status == IClaimingRegistry.ClaimStatus.ACCEPTED) {
            uint256 newTotalCover = totalCoverTokens.sub(claimAmount);

            totalCoverTokens = newTotalCover;
            totalLiquidity = totalLiquidity.sub(claimAmount);

            stblToken.safeTransfer(
                claimer,
                DecimalsConverter.convertFrom18(claimAmount, stblDecimals)
            );

            emit CoverageChanged(newTotalCover);

            delete policyHolders[claimer];
            policyRegistry.removePolicy(claimer);
        } else if (status == IClaimingRegistry.ClaimStatus.REJECTED_CAN_APPEAL) {
            uint256 endUnlockEpoch =
                Math.max(
                    getEpoch(claimEndTime) + 1,
                    policyHolders[claimer].endEpochNumber + VIRTUAL_EPOCHS
                );

            epochAmounts[endUnlockEpoch] = epochAmounts[endUnlockEpoch].add(
                policyHolders[claimer].coverTokens
            );
        } else {
            uint256 virtualEndEpochNumber =
                policyHolders[claimer].endEpochNumber.add(VIRTUAL_EPOCHS);

            if (lastDistributionEpoch <= virtualEndEpochNumber) {
                epochAmounts[virtualEndEpochNumber] = epochAmounts[virtualEndEpochNumber].add(
                    policyHolders[claimer].coverTokens
                );
            } else {
                uint256 newTotalCover = totalCoverTokens.sub(claimAmount);
                totalCoverTokens = newTotalCover;

                emit CoverageChanged(newTotalCover);
            }
        }
    }

    function _getPremiumsDistribution(uint256 lastEpoch, uint256 currentEpoch)
        internal
        view
        returns (
            int256 currentDistribution,
            uint256 distributionEpoch,
            uint256 newTotalLiquidity
        )
    {
        currentDistribution = lastPremiumDistributionAmount;
        newTotalLiquidity = totalLiquidity;
        distributionEpoch = Math.min(
            currentEpoch,
            lastEpoch + MAX_PREMIUM_DISTRIBUTION_EPOCHS + 1
        );

        for (uint256 i = lastEpoch + 1; i <= distributionEpoch; i++) {
            currentDistribution += premiumDistributionDeltas[i];
            newTotalLiquidity = newTotalLiquidity.add(uint256(currentDistribution));
        }
    }

    function _distributePremiums() internal {
        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();

        if (currentEpoch > lastEpoch) {
            (
                lastPremiumDistributionAmount,
                lastPremiumDistributionEpoch,
                totalLiquidity
            ) = _getPremiumsDistribution(lastEpoch, currentEpoch);
        }
    }

    function _updateBMICoverStakingReward() internal {
        uint256 rewardMultiplier;

        if (whitelisted) {
            rewardMultiplier = MINIMUM_REWARD;
            uint256 liquidity = totalLiquidity;
            uint256 coverTokens = totalCoverTokens;

            if (coverTokens > 0 && liquidity > 0) {
                rewardMultiplier = BASE_REWARD;

                uint256 utilizationRatio = coverTokens.mul(PERCENTAGE_100).div(liquidity);

                if (utilizationRatio < MODERATE_UTILIZATION_RATIO) {
                    rewardMultiplier = Math
                        .max(utilizationRatio, PRECISION)
                        .sub(PRECISION)
                        .mul(BASE_REWARD.sub(MINIMUM_REWARD))
                        .div(MODERATE_UTILIZATION_RATIO)
                        .add(MINIMUM_REWARD);
                } else if (utilizationRatio > RISKY_UTILIZATION_RATIO) {
                    rewardMultiplier = MAXIMUM_REWARD
                        .sub(BASE_REWARD)
                        .mul(utilizationRatio.sub(RISKY_UTILIZATION_RATIO))
                        .div(PERCENTAGE_100.sub(RISKY_UTILIZATION_RATIO))
                        .add(BASE_REWARD);
                }
            }
        }

        rewardsGenerator.updatePolicyBookShare(rewardMultiplier.div(10**22)); // 5 decimal places or zero
    }

    function getNewCoverAndLiquidity()
        public
        view
        override
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity)
    {
        newTotalLiquidity = totalLiquidity;
        newTotalCoverTokens = totalCoverTokens;

        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();

        if (currentEpoch > lastEpoch) {
            (, , newTotalLiquidity) = _getPremiumsDistribution(lastEpoch, currentEpoch);
        }

        uint256 newDistributionEpoch = Math.min(getEpoch(block.timestamp), MAXIMUM_EPOCHS);

        for (uint256 i = lastDistributionEpoch; i < newDistributionEpoch; i++) {
            newTotalCoverTokens = newTotalCoverTokens.sub(epochAmounts[i]);
        }
    }

    function getPolicyPrice(uint256 _epochsNumber, uint256 _coverTokens)
        public
        view
        override
        returns (uint256 totalSeconds, uint256 totalPrice)
    {
        require(_coverTokens >= MINUMUM_COVERAGE, "PB: Wrong cover");
        require(_epochsNumber > 0 && _epochsNumber <= MAXIMUM_EPOCHS, "PB: Wrong epoch duration");

        (uint256 newTotalCoverTokens, uint256 newTotalLiquidity) = getNewCoverAndLiquidity();

        totalSeconds = secondsToEndCurrentEpoch().add(_epochsNumber.sub(1).mul(EPOCH_DURATION));
        totalPrice = policyQuote.getQuotePredefined(
            totalSeconds,
            _coverTokens,
            newTotalCoverTokens,
            newTotalLiquidity,
            whitelisted
        );
    }

    function buyPolicyFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external override onlyPolicyBookRegistry {
        _buyPolicy(_buyer, _epochsNumber, _coverTokens);
    }

    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external override {
        _buyPolicy(_msgSender(), _epochsNumber, _coverTokens);
    }

    function _buyPolicy(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) internal withPremiumsDistribution updateBMICoverStakingReward {
        require(
            !policyRegistry.isPolicyActive(_buyer, address(this)),
            "PB: The holder already exists"
        );
        require(claimingRegistry.canBuyNewPolicy(_buyer, address(this)), "PB: Claim is pending");

        updateEpochsInfo();

        uint256 _totalCoverTokens = totalCoverTokens.add(_coverTokens);

        require(totalLiquidity >= _totalCoverTokens, "PB: Not enough liquidity");

        (uint256 _totalSeconds, uint256 _totalPrice) = getPolicyPrice(_epochsNumber, _coverTokens);

        uint256 _reinsurancePrice = _totalPrice.mul(PROTOCOL_PERCENTAGE).div(PERCENTAGE_100);
        uint256 _price = _totalPrice.sub(_reinsurancePrice);

        uint256 _currentEpochNumber = getEpoch(block.timestamp);
        uint256 _endEpochNumber = _currentEpochNumber.add(_epochsNumber.sub(1));
        uint256 _virtualEndEpochNumber = _endEpochNumber + VIRTUAL_EPOCHS;

        policyHolders[_buyer] = PolicyHolder(
            _coverTokens,
            _currentEpochNumber,
            _endEpochNumber,
            _totalPrice
        );

        epochAmounts[_virtualEndEpochNumber] = epochAmounts[_virtualEndEpochNumber].add(
            _coverTokens
        );

        totalCoverTokens = _totalCoverTokens;

        uint256 _stblDecimals = stblDecimals;

        stblToken.safeTransferFrom(
            _buyer,
            reinsurancePoolAddress,
            DecimalsConverter.convertFrom18(_reinsurancePrice, _stblDecimals)
        );
        stblToken.safeTransferFrom(
            _buyer,
            address(this),
            DecimalsConverter.convertFrom18(_price, _stblDecimals)
        );

        _addPolicyPremiumToDistributions(
            _totalSeconds.add(VIRTUAL_EPOCHS * EPOCH_DURATION),
            _price
        );

        emit PolicyBought(_buyer, _coverTokens, _totalPrice, _totalCoverTokens);

        policyRegistry.addPolicy(_buyer, _coverTokens, _price, _totalSeconds);
    }

    /// @dev no need to cap epochs because the maximum policy duration is 1 year
    function _addPolicyPremiumToDistributions(uint256 _totalSeconds, uint256 _distributedAmount)
        internal
    {
        uint256 distributionEpochs = _totalSeconds.add(1).div(PREMIUM_DISTRIBUTION_EPOCH).max(1);

        int256 distributedPerEpoch = int256(_distributedAmount.div(distributionEpochs));
        uint256 nextEpoch = _getPremiumDistributionEpoch() + 1;

        premiumDistributionDeltas[nextEpoch] += distributedPerEpoch;
        premiumDistributionDeltas[nextEpoch + distributionEpochs] -= distributedPerEpoch;
    }

    function updateEpochsInfo() public override {
        uint256 _lastDistributionEpoch = lastDistributionEpoch;
        uint256 _newDistributionEpoch =
            Math.min(getEpoch(block.timestamp), _lastDistributionEpoch + MAXIMUM_EPOCHS);

        if (_lastDistributionEpoch < _newDistributionEpoch) {
            uint256 _newTotalCoverTokens = totalCoverTokens;

            for (uint256 i = _lastDistributionEpoch; i < _newDistributionEpoch; i++) {
                _newTotalCoverTokens = _newTotalCoverTokens.sub(epochAmounts[i]);
                delete epochAmounts[i];
            }

            lastDistributionEpoch = _newDistributionEpoch;
            totalCoverTokens = _newTotalCoverTokens;

            emit CoverageChanged(_newTotalCoverTokens);
        }
    }

    function secondsToEndCurrentEpoch() public view override returns (uint256) {
        uint256 epochNumber = block.timestamp.sub(epochStartTime).div(EPOCH_DURATION) + 1;

        return epochNumber.mul(EPOCH_DURATION).sub(block.timestamp.sub(epochStartTime));
    }

    function addLiquidity(uint256 _liquidityAmount) external override {
        _addLiquidity(_msgSender(), _liquidityAmount);
    }

    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liquidityAmount)
        external
        override
        onlyLiquidityAdders
    {
        _addLiquidity(_liquidityHolderAddr, _liquidityAmount);
    }

    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount)
        external
        override
    {
        require(_stakeSTBLAmount <= _liquidityAmount, "PB: Wrong staking amount");

        _addLiquidity(_msgSender(), _liquidityAmount);
        bmiCoverStaking.stakeBMIXFrom(_msgSender(), convertSTBLToBMIX(_stakeSTBLAmount));
    }

    function _addLiquidity(address _liquidityHolderAddr, uint256 _liquidityAmount)
        internal
        withPremiumsDistribution
        updateBMICoverStakingReward
    {
        uint256 stblLiquidity = DecimalsConverter.convertFrom18(_liquidityAmount, stblDecimals);
        require(stblLiquidity > 0, "PB: Liquidity amount is zero");

        updateEpochsInfo();

        /// @dev PBF already sent stable tokens
        if (_msgSender() != policyBookFabricAddress) {
            stblToken.safeTransferFrom(_liquidityHolderAddr, address(this), stblLiquidity);
        }

        /// @dev have to add to LM liquidity
        if (_msgSender() == address(liquidityMining)) {
            liquidityFromLM[_liquidityHolderAddr] = liquidityFromLM[_liquidityHolderAddr].add(
                _liquidityAmount
            );
        }

        _mint(_liquidityHolderAddr, convertSTBLToBMIX(_liquidityAmount));
        uint256 liquidity = totalLiquidity.add(_liquidityAmount);
        totalLiquidity = liquidity;

        liquidityRegistry.tryToAddPolicyBook(_liquidityHolderAddr, address(this));

        emit LiquidityAdded(_liquidityHolderAddr, _liquidityAmount, liquidity);
    }

    function getAvailableBMIXWithdrawableAmount(address _userAddr)
        external
        view
        override
        returns (uint256)
    {
        (uint256 newTotalCoverTokens, uint256 newTotalLiquidity) = getNewCoverAndLiquidity();

        return
            convertSTBLToBMIX(
                Math.min(
                    newTotalLiquidity.sub(newTotalCoverTokens),
                    _getUserAvailableSTBL(_userAddr)
                )
            );
    }

    function _getUserAvailableSTBL(address _userAddr) internal view returns (uint256) {
        uint256 availableSTBL =
            convertBMIXToSTBL(
                balanceOf(_userAddr).add(withdrawalsInfo[_userAddr].withdrawalAmount)
            );

        if (block.timestamp < liquidityMining.getEndLMTime()) {
            availableSTBL = availableSTBL.sub(liquidityFromLM[_userAddr]);
        }

        return availableSTBL;
    }

    function getWithdrawalStatus(address _userAddr)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        uint256 readyToWithdrawDate = withdrawalsInfo[_userAddr].readyToWithdrawDate;

        if (readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >= readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD) &&
            !withdrawalsInfo[_userAddr].withdrawalAllowed
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        permit(_msgSender(), address(this), _tokensToWithdraw, MAX_INT, _v, _r, _s);

        requestWithdrawal(_tokensToWithdraw);
    }

    function requestWithdrawal(uint256 _tokensToWithdraw)
        public
        override
        withPremiumsDistribution
    {
        require(_tokensToWithdraw > 0, "PB: Amount is zero");

        uint256 _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);
        uint256 _availableSTBLBalance = _getUserAvailableSTBL(_msgSender());

        require(_availableSTBLBalance >= _stblTokensToWithdraw, "PB: Wrong announced amount");

        updateEpochsInfo();

        require(
            totalLiquidity >= totalCoverTokens.add(_stblTokensToWithdraw),
            "PB: Not enough free liquidity"
        );

        _lockTokens(_msgSender(), _tokensToWithdraw);

        uint256 _readyToWithdrawDate = block.timestamp.add(WITHDRAWAL_PERIOD);

        withdrawalsInfo[_msgSender()] = WithdrawalInfo(
            _tokensToWithdraw,
            _readyToWithdrawDate,
            false
        );

        emit WithdrawalRequested(_msgSender(), _tokensToWithdraw, _readyToWithdrawDate);
    }

    function _lockTokens(address _userAddr, uint256 _neededTokensToLock) internal {
        uint256 _currentLockedTokens = withdrawalsInfo[_userAddr].withdrawalAmount;

        if (_currentLockedTokens > _neededTokensToLock) {
            this.transfer(_userAddr, _currentLockedTokens - _neededTokensToLock);
        } else if (_currentLockedTokens < _neededTokensToLock) {
            this.transferFrom(
                _userAddr,
                address(this),
                _neededTokensToLock - _currentLockedTokens
            );
        }
    }

    function unlockTokens() external override {
        uint256 _lockedAmount = withdrawalsInfo[_msgSender()].withdrawalAmount;

        require(_lockedAmount > 0, "PB: Amount is zero");

        this.transfer(_msgSender(), _lockedAmount);
        delete withdrawalsInfo[_msgSender()];
    }

    function withdrawLiquidity()
        external
        override
        withPremiumsDistribution
        updateBMICoverStakingReward
    {
        require(
            getWithdrawalStatus(_msgSender()) == WithdrawalStatus.READY,
            "PB: Withdrawal is not ready"
        );

        updateEpochsInfo();

        uint256 liquidity = totalLiquidity;
        uint256 _currentWithdrawalAmount = withdrawalsInfo[_msgSender()].withdrawalAmount;
        uint256 _tokensToWithdraw =
            Math.min(_currentWithdrawalAmount, convertSTBLToBMIX(liquidity.sub(totalCoverTokens)));

        uint256 _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);
        stblToken.safeTransfer(
            _msgSender(),
            DecimalsConverter.convertFrom18(_stblTokensToWithdraw, stblDecimals)
        );

        _burn(address(this), _tokensToWithdraw);
        liquidity = liquidity.sub(_stblTokensToWithdraw);

        _currentWithdrawalAmount = _currentWithdrawalAmount.sub(_tokensToWithdraw);

        if (_currentWithdrawalAmount == 0) {
            delete withdrawalsInfo[_msgSender()];
            liquidityRegistry.tryToRemovePolicyBook(_msgSender(), address(this));
        } else {
            withdrawalsInfo[_msgSender()].withdrawalAllowed = true;
            withdrawalsInfo[_msgSender()].withdrawalAmount = _currentWithdrawalAmount;
        }

        totalLiquidity = liquidity;

        emit LiquidityWithdrawn(_msgSender(), _stblTokensToWithdraw, liquidity);
    }

    /// @notice returns APY% with 10**5 precision
    function getAPY() public view override returns (uint256) {
        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();
        int256 premiumDistributionAmount = lastPremiumDistributionAmount;

        // sumilates addLiquidity()
        if (currentEpoch > lastEpoch) {
            (premiumDistributionAmount, currentEpoch, ) = _getPremiumsDistribution(
                lastEpoch,
                currentEpoch
            );
        }

        premiumDistributionAmount += premiumDistributionDeltas[currentEpoch + 1];

        return
            uint256(premiumDistributionAmount).mul(365).mul(10**7).div(
                totalSupply().add(convertSTBLToBMIX(APY_TOKENS))
            );
    }

    function userStats(address _user) external view override returns (PolicyHolder memory) {
        return policyHolders[_user];
    }

    /// @notice _annualProfitYields is multiplied by 10**5
    /// @notice _annualInsuranceCost is calculated for 1000 STBL cover (or _maxCapacities if it is less)
    /// @notice _bmiXRatio is multiplied by 10**18. To get STBL representation,
    ///     multiply BMIX tokens by this value and then divide by 10**18
    function numberStats()
        external
        view
        override
        returns (
            uint256 _maxCapacities,
            uint256 _totalSTBLLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        )
    {
        uint256 newTotalCoverTokens;

        (newTotalCoverTokens, _totalSTBLLiquidity) = getNewCoverAndLiquidity();
        _maxCapacities = _totalSTBLLiquidity - newTotalCoverTokens;

        _stakedSTBL = rewardsGenerator.getStakedPolicyBookSTBL(address(this));
        _annualProfitYields = getAPY().add(bmiCoverStaking.getPolicyBookAPY(address(this)));

        uint256 possibleCoverage = Math.min(ANNUAL_COVERAGE_TOKENS, _maxCapacities);

        if (possibleCoverage > 0) {
            _annualInsuranceCost = policyQuote.getQuotePredefined(
                SECONDS_IN_THE_YEAR,
                possibleCoverage,
                newTotalCoverTokens,
                _totalSTBLLiquidity,
                whitelisted
            );

            _annualInsuranceCost = _annualInsuranceCost
                .mul(ANNUAL_COVERAGE_TOKENS.mul(PRECISION).div(possibleCoverage))
                .div(PRECISION)
                .div(10);
        }

        _bmiXRatio = convertBMIXToSTBL(10**18);
    }

    function info()
        external
        view
        override
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        )
    {
        return (symbol(), insuranceContractAddress, contractType, whitelisted);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IBMICoverStaking {
    struct StakingInfo {
        address policyBookAddress;
        uint256 stakedBMIXAmount;
    }

    struct PolicyBookInfo {
        uint256 totalStakedSTBL;
        uint256 rewardPerBlock;
        uint256 stakingAPY;
        uint256 liquidityAPY;
    }

    struct UserInfo {
        uint256 totalStakedBMIX;
        uint256 totalStakedSTBL;
        uint256 totalBmiReward;
    }

    struct NFTsInfo {
        uint256 nftIndex;
        string uri;
        uint256 stakedBMIXAmount;
        uint256 stakedSTBLAmount;
        uint256 reward;
    }

    function aggregateNFTs(address policyBookAddress, uint256[] calldata tokenIds) external;

    function stakeBMIX(uint256 amount, address policyBookAddress) external;

    function stakeBMIXWithPermit(
        uint256 bmiXAmount,
        address policyBookAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakeBMIXFrom(address user, uint256 amount) external;

    function stakeBMIXFromWithPermit(
        address user,
        uint256 bmiXAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    function restakeBMIProfit(uint256 tokenId) external;

    function restakeStakerBMIProfit(address policyBookAddress) external;

    function withdrawBMIProfit(uint256 tokenID) external;

    function withdrawStakerBMIProfit(address policyBookAddress) external;

    function withdrawFundsWithProfit(uint256 tokenID) external;

    function withdrawStakerFundsWithProfit(address policyBookAddress) external;

    function stakingInfoByToken(uint256 tokenID) external view returns (StakingInfo memory);

    /// @notice exhaustive information about staker's stakes
    /// @param staker is a user to return information for
    /// @param policyBooksAddresses is an array of PolicyBooks to check the stakes in
    /// @param offset is a starting ordinal number of user's NFT
    /// @param limit is a number of NFTs to check per function's call
    /// @return policyBooksInfo - an array of infos (totalStakedSTBL, rewardPerBlock (in BMI), stakingAPY, liquidityAPY)
    /// @return usersInfo - an array of user's info per PolicyBook (totalStakedBMIX, totalStakedSTBL, totalBmiReward)
    /// @return nftsCount - number of NFTs for each respective PolicyBook
    /// @return nftsInfo - 2 dimensional array of NFTs info per each PolicyBook
    ///     (nftIndex, uri, stakedBMIXAmount, stakedSTBLAmount, reward (in BMI))
    function stakingInfoByStaker(
        address staker,
        address[] calldata policyBooksAddresses,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (
            PolicyBookInfo[] memory policyBooksInfo,
            UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            NFTsInfo[][] memory nftsInfo
        );

    function getSlashedBMIProfit(uint256 tokenId) external view returns (uint256);

    function getBMIProfit(uint256 tokenId) external view returns (uint256);

    function getSlashedStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function getStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function totalStaked(address user) external view returns (uint256);

    function totalStakedSTBL(address user) external view returns (uint256);

    function stakedByNFT(uint256 tokenId) external view returns (uint256);

    function stakedSTBLByNFT(uint256 tokenId) external view returns (uint256);

    function policyBookByNFT(uint256 tokenId) external view returns (address);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IClaimingRegistry.sol";

interface IClaimVoting {
    enum VoteStatus {
        ANONYMOUS_PENDING,
        AWAITING_EXPOSURE,
        EXPIRED,
        EXPOSED_PENDING,
        AWAITING_CALCULATION,
        MINORITY,
        MAJORITY
    }

    struct VotingResult {
        uint256 withdrawalAmount;
        uint256 lockedBMIAmount;
        uint256 reinsuranceTokensAmount;
        uint256 votedAverageWithdrawalAmount;
        uint256 votedYesStakedBMIAmountWithReputation;
        uint256 votedNoStakedBMIAmountWithReputation;
        uint256 allVotedStakedBMIAmount;
        uint256 votedYesPercentage;
    }

    struct VotingInst {
        uint256 claimIndex;
        bytes32 finalHash;
        string encryptedVote;
        address voter;
        uint256 voterReputation;
        uint256 suggestedAmount;
        uint256 stakedBMIAmount;
        bool accept;
        VoteStatus status;
    }

    struct MyClaimInfo {
        uint256 index;
        address policyBookAddress;
        string evidenceURI;
        bool appeal;
        uint256 claimAmount;
        IClaimingRegistry.ClaimStatus finalVerdict;
        uint256 finalClaimAmount;
        uint256 bmiCalculationReward;
    }

    struct PublicClaimInfo {
        uint256 claimIndex;
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        bool appeal;
        uint256 claimAmount;
        uint256 time;
    }

    struct AllClaimInfo {
        PublicClaimInfo publicClaimInfo;
        IClaimingRegistry.ClaimStatus finalVerdict;
        uint256 finalClaimAmount;
        uint256 bmiCalculationReward;
    }

    struct MyVoteInfo {
        AllClaimInfo allClaimInfo;
        string encryptedVote;
        uint256 suggestedAmount;
        VoteStatus status;
        uint256 time;
    }

    struct VotesUpdatesInfo {
        uint256 bmiReward;
        uint256 stblReward;
        int256 reputationChange;
        int256 stakeChange;
    }

    /// @notice starts the voting process
    function initializeVoting(
        address claimer,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 coverTokens,
        uint256 reinsuranceTokensAmount,
        bool appeal
    ) external;

    /// @notice returns true if the user has no PENDING votes
    function canWithdraw(address user) external view returns (bool);

    /// @notice returns true if the user has no AWAITING_CALCULATION votes
    function canVote(address user) external view returns (bool);

    /// @notice returns how many votes the user has
    function countVotes(address user) external view returns (uint256);

    /// @notice returns status of the vote
    function voteStatus(uint256 index) external view returns (VoteStatus);

    /// @notice returns a list of claims that are votable for msg.sender
    function whatCanIVoteFor(uint256 offset, uint256 limit)
        external
        returns (uint256 _claimsCount, PublicClaimInfo[] memory _votablesInfo);

    /// @notice returns info list of ALL claims
    function allClaims(uint256 offset, uint256 limit)
        external
        view
        returns (AllClaimInfo[] memory _allClaimsInfo);

    /// @notice returns info list of claims of msg.sender
    function myClaims(uint256 offset, uint256 limit)
        external
        view
        returns (MyClaimInfo[] memory _myClaimsInfo);

    /// @notice returns info list of claims that are voted by msg.sender
    function myVotes(uint256 offset, uint256 limit)
        external
        view
        returns (MyVoteInfo[] memory _myVotesInfo);

    /// @notice returns an array of votes that can be calculated + update information
    function myVotesUpdates(uint256 offset, uint256 limit)
        external
        view
        returns (
            uint256 _votesUpdatesCount,
            uint256[] memory _claimIndexes,
            VotesUpdatesInfo memory _myVotesUpdatesInfo
        );

    /// @notice anonymously votes (result used later in exposeVote())
    /// @notice the claims have to be PENDING, the voter can vote only once for a specific claim
    /// @param claimIndexes are the indexes of the claims the voter is voting on
    ///     (each one is unique for each claim and appeal)
    /// @param finalHashes are the hashes produced by the encryption algorithm.
    ///     They will be verified onchain in expose function
    /// @param encryptedVotes are the AES encrypted values that represent the actual vote
    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes
    ) external;

    /// @notice exposes votes of anonymous votings
    /// @notice the vote has to be voted anonymously prior
    /// @param claimIndexes are the indexes of the claims to expose votes for
    /// @param suggestedClaimAmounts are the actual vote values.
    ///     They must match the decrypted values in anonymouslyVoteBatch function
    /// @param hashedSignaturesOfClaims are the validation data needed to construct proper finalHashes
    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedClaimAmounts,
        bytes32[] calldata hashedSignaturesOfClaims
    ) external;

    /// @notice calculates results of votes
    function calculateVoterResultBatch(uint256[] calldata claimIndexes) external;

    /// @notice calculates results of claims
    function calculateVotingResultBatch(uint256[] calldata claimIndexes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum ClaimStatus {
        CAN_CLAIM,
        UNCLAIMABLE,
        PENDING,
        AWAITING_CALCULATION,
        REJECTED_CAN_APPEAL,
        REJECTED,
        ACCEPTED
    }

    struct ClaimInfo {
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        uint256 dateSubmitted;
        uint256 dateEnded;
        bool appeal;
        ClaimStatus status;
        uint256 claimAmount;
    }

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration(uint256 index) external view returns (uint256);

    /// @notice returns how many time should pass before anyone could calculate a claim result
    function anyoneCanCalculateClaimResultAfter(uint256 index) external view returns (uint256);

    /// @notice returns true if a user can buy new policy of specified PolicyBook
    function canBuyNewPolicy(address buyer, address policyBookAddress)
        external
        view
        returns (bool);

    /// @notice submits new PolicyBook claim for the user
    function submitClaim(
        address user,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external returns (uint256);

    /// @notice returns true if the claim with this index exists
    function claimExists(uint256 index) external view returns (bool);

    /// @notice returns claim submition time
    function claimSubmittedTime(uint256 index) external view returns (uint256);

    /// @notice returns claim end time or zero in case it is pending
    function claimEndTime(uint256 index) external view returns (uint256);

    /// @notice returns true if the claim is anonymously votable
    function isClaimAnonymouslyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if the claim is exposably votable
    function isClaimExposablyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if claim is anonymously votable or exposably votable
    function isClaimVotable(uint256 index) external view returns (bool);

    /// @notice returns true if a claim can be calculated by anyone
    function canClaimBeCalculatedByAnyone(uint256 index) external view returns (bool);

    /// @notice returns true if this claim is pending or awaiting
    function isClaimPending(uint256 index) external view returns (bool);

    /// @notice returns how many claims the holder has
    function countPolicyClaimerClaims(address user) external view returns (uint256);

    /// @notice returns how many pending claims are there
    function countPendingClaims() external view returns (uint256);

    /// @notice returns how many claims are there
    function countClaims() external view returns (uint256);

    /// @notice returns a claim index of it's claimer and an ordinal number
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        returns (uint256);

    /// @notice returns pending claim index by its ordinal index
    function pendingClaimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns claim index by its ordinal index
    function claimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns current active claim index by policybook and claimer
    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns true if the claim is appealed
    function isClaimAppeal(uint256 index) external view returns (bool);

    /// @notice returns current status of a claim
    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        returns (ClaimStatus);

    /// @notice returns current status of a claim
    function claimStatus(uint256 index) external view returns (ClaimStatus);

    /// @notice returns the claim owner (claimer)
    function claimOwner(uint256 index) external view returns (address);

    /// @notice returns the claim PolicyBook
    function claimPolicyBook(uint256 index) external view returns (address);

    /// @notice returns claim info by its index
    function claimInfo(uint256 index) external view returns (ClaimInfo memory _claimInfo);

    /// @notice marks the user's claim as Accepted
    function acceptClaim(uint256 index) external;

    /// @notice marks the user's claim as Rejected
    function rejectClaim(uint256 index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getLegacyBMIStakingContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLegacyLiquidityMiningStakingContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct TeamDetails {
        string teamName;
        address referralLink;
        uint256 membersNumber;
        uint256 totalStakedAmount;
        uint256 totalReward;
    }

    struct UserInfo {
        address userAddr;
        string teamName;
        uint256 stakedAmount;
        uint256 mainNFT; // 0 or NFT index if available
        uint256 platinumNFT; // 0 or NFT index if available
    }

    struct UserRewardsInfo {
        string teamName;
        uint256 totalBMIReward; // total BMI reward
        uint256 availableBMIReward; // current claimable BMI reward
        uint256 incomingPeriods; // how many month are incoming
        uint256 timeToNextDistribution; // exact time left to next distribution
        uint256 claimedBMI; // actual number of claimed BMI
        uint256 mainNFTAvailability; // 0 or NFT index if available
        uint256 platinumNFTAvailability; // 0 or NFT index if available
        bool claimedNFTs; // true if user claimed NFTs
    }

    struct MyTeamInfo {
        TeamDetails teamDetails;
        uint256 myStakedAmount;
        uint256 teamPlace;
    }

    struct UserTeamInfo {
        address teamAddr;
        uint256 stakedAmount;
        uint256 countOfRewardedMonth;
        bool isNFTDistributed;
    }

    struct TeamInfo {
        string name;
        uint256 totalAmount;
        address[] teamLeaders;
    }

    function startLiquidityMiningTime() external view returns (uint256);

    function getTopTeams() external view returns (TeamDetails[] memory teams);

    function getTopUsers() external view returns (UserInfo[] memory users);

    function getAllTeamsLength() external view returns (uint256);

    function getAllTeamsDetails(uint256 _offset, uint256 _limit)
        external
        view
        returns (TeamDetails[] memory _teamDetailsArr);

    function getMyTeamsLength() external view returns (uint256);

    function getMyTeamMembers(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _teamMembers, uint256[] memory _memberStakedAmount);

    function getAllUsersLength() external view returns (uint256);

    function getAllUsersInfo(uint256 _offset, uint256 _limit)
        external
        view
        returns (UserInfo[] memory _userInfos);

    function getMyTeamInfo() external view returns (MyTeamInfo memory _myTeamInfo);

    function getRewardsInfo(address user)
        external
        view
        returns (UserRewardsInfo memory userRewardInfo);

    function createTeam(string calldata _teamName) external;

    function deleteTeam() external;

    function joinTheTeam(address _referralLink) external;

    function getSlashingPercentage() external view returns (uint256);

    function investSTBL(uint256 _tokensAmount, address _policyBookAddr) external;

    function distributeNFT() external;

    function checkPlatinumNFTReward(address _userAddr) external view returns (uint256);

    function checkMainNFTReward(address _userAddr) external view returns (uint256);

    function distributeBMIReward() external;

    function getTotalUserBMIReward(address _userAddr) external view returns (uint256);

    function checkAvailableBMIReward(address _userAddr) external view returns (uint256);

    /// @notice checks if liquidity mining event is lasting (startLiquidityMining() has been called)
    /// @return true if LM is started and not ended, false otherwise
    function isLMLasting() external view returns (bool);

    /// @notice checks if liquidity mining event is finished. In order to be finished, it has to be started
    /// @return true if LM is finished, false if event is still going or not started
    function isLMEnded() external view returns (bool);

    function getEndLMTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityRegistry {
    struct LiquidityInfo {
        address policyBookAddr;
        uint256 lockedAmount;
        uint256 availableAmount;
        uint256 bmiXRatio; // multiply availableAmount by this num to get stable coin
    }

    struct WithdrawalRequestInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableLiquidity;
        uint256 readyToWithdrawDate;
        uint256 endWithdrawDate;
    }

    struct WithdrawalSetInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableSTBLAmount;
    }

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr) external;

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr) external;

    function getPolicyBooksArrLength(address _userAddr) external view returns (uint256);

    function getPolicyBooksArr(address _userAddr)
        external
        view
        returns (address[] memory _resultArr);

    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (LiquidityInfo[] memory _resultArr);

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr);

    function getWithdrawalSet(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256 _arrLength, WithdrawalSetInfo[] memory _resultArr);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    function EPOCH_DURATION() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmount,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get BMIX equivalent
    function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice updates info on claim acceptance
    function commitClaim(
        address claimer,
        uint256 claimAmount,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    /// @notice view function to get precise policy price
    function getPolicyPrice(uint256 _epochsNumber, uint256 _coverTokens)
        external
        view
        returns (uint256 totalSeconds, uint256 totalPrice);

    function buyPolicyFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _coverTokens is number of tokens to cover
    function buyPolicy(uint256 _durationSeconds, uint256 _coverTokens) external;

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liqudityAmount) external;

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _totalSTBLLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyBookFabric {
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyQuote {
    /// @notice Let user to calculate policy cost in stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is a number of tokens to cover
    /// @param _totalCoverTokens is a number of covered tokens
    /// @param _totalLiquidity is a liquidity amount
    /// @return amount of stable coin policy costs
    function getQuotePredefined(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        bool _safePolicyBook
    ) external view returns (uint256);

    /// @notice Let user to calculate policy cost in stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is number of tokens to cover
    /// @param _policyBookAddr is address of policy book
    /// @return amount of stable coin policy costs
    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";

interface IPolicyRegistry {
    struct PolicyInfo {
        uint256 coverAmount;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
    }

    struct PolicyUserInfo {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 coverTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 paid;
    }

    function STILL_CLAIMABLE_FOR() external view returns (uint256);

    /// @notice Returns the number of the policy for the user, access: ANY
    /// @param _userAddr Policy holder address
    /// @return the number of police in the array
    function getPoliciesLength(address _userAddr) external view returns (uint256);

    /// @notice Shows whether the user has a policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has policy in specific policy book
    function policyExists(address _userAddr, address _policyBookAddr) external view returns (bool);

    /// @notice Returns information about current policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has active policy in specific policy book
    function isPolicyActive(address _userAddr, address _policyBookAddr)
        external
        view
        returns (bool);

    /// @notice returns current policy start time or zero
    function policyStartTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice returns current policy end time or zero
    function policyEndTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice Returns the array of the policy itself , access: ANY
    /// @param _userAddr Policy holder address
    /// @param _isActive If true, then returns an array with information about active policies, if false, about inactive
    /// @return _policiesCount is the number of police in the array
    /// @return _policyBooksArr is the array of policy books addresses
    /// @return _policies is the array of policies
    /// @return _policyStatuses parameter will show which button to display on the dashboard
    function getPoliciesInfo(
        address _userAddr,
        bool _isActive,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        returns (
            uint256 _policiesCount,
            address[] memory _policyBooksArr,
            PolicyInfo[] memory _policies,
            IClaimingRegistry.ClaimStatus[] memory _policyStatuses
        );

    /// @notice Getting stats from users of policy books, access: ANY
    function getUsersInfo(address[] calldata _users, address[] calldata _policyBooks)
        external
        view
        returns (PolicyUserInfo[] memory _stats);

    function getPoliciesArr(address _userAddr) external view returns (address[] memory _arr);

    /// @notice Adds a new policy to the list , access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    /// @param _coverAmount is the number of insured tokens
    /// @param _premium is the name of PolicyBook
    /// @param _durationDays is the number of days for which the insured
    function addPolicy(
        address _userAddr,
        uint256 _coverAmount,
        uint256 _premium,
        uint256 _durationDays
    ) external;

    /// @notice Removes the policy book from the list, access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    function removePolicy(address _userAddr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IRewardsGenerator {
    struct PolicyBookRewardInfo {
        uint256 rewardMultiplier; // includes 5 decimal places
        uint256 totalStaked;
        uint256 startStakeBlock;
        uint256 lastUpdateBlock;
        uint256 cumulativeSum; // includes 100 percentage
        uint256 cumulativeReward;
        uint256 average; // includes 100 percentage
        uint256 toUpdateAverage; // includes 100 percentage
    }

    struct StakeRewardInfo {
        uint256 averageOnStake; // includes 100 percentage
        uint256 aggregatedReward;
        uint256 stakeAmount;
        uint256 stakeBlock;
    }

    /// @notice this function is called every time policybook's STBL to bmiX rate changes
    function updatePolicyBookShare(uint256 newRewardMultiplier) external;

    /// @notice aggregates specified nfts into a single one
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external;

    /// @notice informs generator of stake (rewards)
    function stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount
    ) external;

    /// @notice returns policybook's APY multiplied by 10**5
    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns PolicyBook's staked STBL
    function getStakedPolicyBookSTBL(address policyBookAddress) external view returns (uint256);

    /// @notice returns NFT's staked STBL
    function getStakedNFTSTBL(uint256 nftIndex) external view returns (uint256);

    /// @notice returns a reward of NFT
    function getReward(address policyBookAddress, uint256 nftIndex)
        external
        view
        returns (uint256);

    /// @notice informs generator of withdrawal (all funds)
    function withdrawFunds(address policyBookAddress, uint256 nftIndex) external returns (uint256);

    /// @notice informs generator of withdrawal (rewards)
    function withdrawReward(address policyBookAddress, uint256 nftIndex)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPriceFeed {
    function howManyBMIsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInBMI(uint256 bmiAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v3.4/contracts/drafts
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.div(10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v3.4/contracts/drafts
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        initializer
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../interfaces/tokens/erc20permit-upgradeable/IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v3.4/contracts/drafts
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20PermitUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash =
            keccak256(
                abi.encode(
                    _PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    _nonces[owner].current(),
                    deadline
                )
            );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    uint256[49] private __gap;
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
library SafeMathUpgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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