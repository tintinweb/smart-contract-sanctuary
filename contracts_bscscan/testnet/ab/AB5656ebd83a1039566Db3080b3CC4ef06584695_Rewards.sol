// SPDX-License-Identifier: MIT
import "./autoClaim/AutoClaimDetails.sol";
import "./claim/Claim.sol";
import "./interfaces/IRewards.sol";

pragma solidity ^0.8.0;

/**
 * @dev Rewards contract that sends out rewards (auto & manual claim) from fees
 *      taken on transfers.
 */
contract Rewards is Claim, AutoClaimDetails, IRewards {
    /**
     * @dev Initialise router manager, swap manager, omnia address. Excludes
     *      some addresses from rewards and whitelist some token to use as
     *      custome rewards.
     *
     * @param routerManager_ address of existing router manager.
     * @param swapManager_ address of existing swap manager.
     * @param routerManager_ address of existing OMNIA token.
     */
    function initialize(
        address routerManager_,
        address swapManager_,
        address omnia_
    ) public override initializer {
        router = IRouterManager(routerManager_);
        swapManager = ISwapManager(swapManager_);
        omnia = ERC20(omnia_);

        _initializeRewardExcludedList(ERC20(omnia_));
        _initializeCustomRewardTokenWhitelist(ERC20(omnia_));
        _initializeStableTokenRewardManager(ERC20(omnia_));
        _initializeRewardCycle(ERC20(omnia_));

        _addressesExcludedFromRewardsByDefault();
        _tokensWhitelistedByDefault();
    }

    function _addressesExcludedFromRewardsByDefault() private {
        _setExcludedFromRewards(
            0x000000000000000000000000000000000000dEaD,
            true
        );
        _setExcludedFromRewards(address(0x0), true);
        _setExcludedFromRewards(address(omnia), true);
        _setExcludedFromRewards(address(this), true);
        _setExcludedFromRewards(owner(), true);
        _setExcludedFromRewards(address(router.pancakeswapV2Pair()), true);
        _setExcludedFromRewards(address(router.pancakeswapV2Router()), true);
    }

    function _tokensWhitelistedByDefault() private {
        // DAI
        _addCustomRewardToken(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
        //  USDC
        _addCustomRewardToken(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
        //  BUSD
        _addCustomRewardToken(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        //  WBNB
        _addCustomRewardToken(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        //  DOT
        _addCustomRewardToken(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);
        //  ADA
        _addCustomRewardToken(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
        // EGLD
        _addCustomRewardToken(0xbF7c81FFF98BbE61B40Ed186e4AfD6DDd01337fe);
        // CAKE
        _addCustomRewardToken(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    }

    /**
     * @dev Transfers lost BEP20 sent by error to Rewards contract.
     *
     *      Only lost `rewardStableToken()` can be retrieved by the owner. This
     *      means the amount of `rewardStableToken()` swapped for rewards will
     *      never be able to be withdrawn.
     *
     * Requirements:
     * - only the owner can transfers lost BEP20
     * - `maxOunt` of stablecoin to transfer cant be 0
     */
    function transferLostBEP20(address tokenAddress, address to)
        external
        onlyOwner
    {
        uint256 maxAmount = IERC20(tokenAddress).balanceOf(address(this));

        if (tokenAddress == rewardStableToken()) {
            // Amount of stablecoin left minus amount of stablecoin allocated to rewards
            maxAmount -= stablecoinLeftAsRewardsInREWARDSContract;
            require(maxAmount > 0, "Stablecoin reserved to rewards");
        }

        ERC20(tokenAddress).transfer(to, maxAmount);
    }

    /**
     * @dev Transfer the whole BNB balance of this contract to `to` address.
     *
     *      No BNB should ever be sent there but if some are sent here it means
     *      they are lost.
     */
    function transferLostBNB(address payable to) external payable onlyOwner {
        to.transfer(address(this).balance);
    }

    /**
     * @inheritdoc AutoClaimPausable
     */
    function autoClaimPaused()
        public
        view
        override(IRewards, AutoClaimPausable)
        returns (bool)
    {
        return AutoClaimPausable.autoClaimPaused();
    }

    /**
     * @inheritdoc AutoClaimDetails
     */
    function isProcessingAutoClaim()
        public
        view
        override(IRewards, AutoClaimDetails)
        returns (bool)
    {
        return AutoClaimDetails.isProcessingAutoClaim();
    }

    /**
     * @inheritdoc AutoClaimDetails
     */
    function maxBatchRewardsDistributionGAS()
        public
        override(IRewards, AutoClaimDetails)
        returns (uint256)
    {
        return AutoClaimDetails.maxBatchRewardsDistributionGAS();
    }

    /**
     * @inheritdoc AutoClaimInterval
     */
    function processAutoClaimIntervalReached()
        public
        view
        override(IRewards, AutoClaimInterval)
        returns (bool)
    {
        return AutoClaimInterval.processAutoClaimIntervalReached();
    }

    /**
     * @inheritdoc AutoClaim
     */
    function processAutoClaim(uint256 gas)
        public
        override(IRewards, AutoClaim)
    {
        AutoClaim.processAutoClaim(gas);
    }

    /**
     * @notice override allows to use an instance of IRewards everywhere passing this
     *         as an address + add restriction on who can call the function.
     * @inheritdoc AutoClaimQueueList
     */
    function updateAutoClaimQueue(address user)
        public
        override(IRewards, AutoClaimQueueList)
    {
        require(
            _msgSender() == address(_rToken) ||
                _msgSender() == address(this) ||
                _msgSender() == owner(),
            "Only OMNIA token or this or owner"
        );
        AutoClaimQueueList.updateAutoClaimQueue(user);
    }

    /**
     * @notice override allows to use an instance of IRewards everywhere passing this
     *         as an address + add restriction on who can call the function.
     * @inheritdoc CumulativeRewardsCalculator
     */
    function updateEligibleSupplyForRewards(
        address sender_,
        address receiver_,
        uint256 sentAmount_,
        uint256 receivedAmount_
    ) public override(IRewards, CumulativeRewardsCalculator) {
        require(_msgSender() == address(_rToken), "Only OMNIA token");
        CumulativeRewardsCalculator.updateEligibleSupplyForRewards(
            sender_,
            receiver_,
            sentAmount_,
            receivedAmount_
        );
    }

    /**
     * @notice override allows to use an instance of IRewards everywhere passing this
     *         as an address + add restriction on who can call the function.
     * @inheritdoc RewardCycle
     */
    function updateNextClaimDate(
        address rewardee_,
        uint256 rewardeeBalance_,
        uint256 transferAmount_
    ) public override(IRewards, RewardCycle) {
        require(_msgSender() == address(_rToken), "Only OMNIA token");
        RewardCycle.updateNextClaimDate(
            rewardee_,
            rewardeeBalance_,
            transferAmount_
        );
    }

    /**
     * @notice override allows to use an instance of IRewards everywhere passing this
     *         as an address + add restriction on who can call the function.
     * @inheritdoc CumulativeRewardsCalculator
     */
    function updateRewardPointsOnTransfer(address sender_, address receiver_)
        public
        override(IRewards, CumulativeRewardsCalculator)
    {
        require(_msgSender() == address(_rToken), "Only OMNIA token");
        CumulativeRewardsCalculator.updateRewardPointsOnTransfer(
            sender_,
            receiver_
        );
    }

    function excludeContractFromRewards(address account_)
        public
        override(IRewards, RewardExcludedList)
    {
        // Avoid failure on deployment as Rewards is initialised after
        // RouterManager, see {OMNIA.inisitialise}
        if (address(router) != address(0))
            require(
                _msgSender() == owner() ||
                    _msgSender() == address(_rToken) ||
                    _msgSender() == address(router),
                "Owner, OMNIA token or RouterManager"
            );
        RewardExcludedList.excludeContractFromRewards(account_);
    }

    /**
     * @inheritdoc RewardExcludedList
     */
    function OMNIA_REFLECTION_WALLET()
        public
        view
        override(IRewards, RewardExcludedList)
        returns (address)
    {
        return RewardExcludedList.OMNIA_REFLECTION_WALLET();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AutoClaim.sol";

/**
 * @notice Next part of {AutoClaim} to keep ~100 lines/file.
 *
 * @dev Defines getters & setters for variables used in {AutoClaim}.
 */
abstract contract AutoClaimDetails is AutoClaim {
    /**
     * @param gas maximum amount of gas that can be consumed during auto claim (used in {Transfers._beforeTokenTransfer}).
     *
     * Requirements:
     *
     * - `gas` cannot be lower than 1M.
     */
    function setMaxBatchRewardsDistributionGAS(uint256 gas) external onlyOwner {
        require(gas >= 10**6, "gas < 1M");
        _maxBatchRewardsDistributionGAS = gas;
    }

    /**
     * @param autoClaimMinAmount_ minimum amount of OMNIA (in Wei), required to swap OMNIA into 
                                  stablecoin.
     *
     * Requirements:
     *
     * - `autoClaimMinAmount_` cannot be stricly lower than 0.1 OMNIA (10 ** 17, in Wei).
     * - `autoClaimMinAmount_` cannot be stricly greater than 100 OMNIA (10 ** 17, in Wei).
     */
    function setAutoClaimMinAmount(uint256 autoClaimMinAmount_)
        external
        onlyOwner
    {
        if (autoClaimMinAmount_ < 10**17) revert("amount < 0.1");
        if (autoClaimMinAmount_ > 100 * 10**18) revert("amount > 100");
        autoClaimMinAmount = autoClaimMinAmount_;
    }

    /**
     * @return bool
     *         whether an auto claim is currently being processed or not.
     */
    function isProcessingAutoClaim() public view virtual returns (bool) {
        return _isProcessingAutoClaim;
    }

    /**
     * @return uint256
     *         maximum amount of gas that can be consumed during auto claim (on transfers).
     */
    function maxBatchRewardsDistributionGAS() public virtual returns (uint256) {
        return _maxBatchRewardsDistributionGAS;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClaimCoins.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev _msgSender() can claim their specific custom rewards, if the time has come.
 */
abstract contract Claim is ClaimCoins {
    event RewardClaimed(
        address indexed rewardee,
        uint256 rewardInOMNIA,
        uint256 omniaRewardsAsStableToken,
        uint256 omniaRewardsAsCustomToken,
        uint256 _nextAvailableClaimDate
    );

    /**
     * @dev Allows `_msgSender()` to claim their very custom rewards..
     *
     *
     * Requirements:
     *
     * - `_msgSender()` must wait until their next available claiming date, see {RewardCycle.isRewardReady()}.
     * - `_msgSender()` must have enough balance and should not be inside
     *   {_addressesExcludedFromRewards} EnumerableSet, see {RewardExcludedList.isIncludedInRewards()}.
     * - `success` must be true AKA no issues while claiming their OMNIA or custom tokens
     *   (e.g. issues with pancakeswap or not enough custom tokens inside the contract).
     */
    function claimReward() external {
        require(isRewardReady(_msgSender()), "Claim date not passed yet");
        require(
            isIncludedInRewards(_msgSender()),
            "Address excluded from rewards"
        );

        bool success = _doClaimReward();
        require(success, "Rewards claim failed");
    }

    /**
     * @notice rewards calculation are made in {CumulativeRewardsCalculator.calculateManualClaimRewardTokens()}
     *         and tokens are claimed in {ClaimCoins._claimTokens()}.
     *
     * @dev `_msgSender()` claims their rewards proportionally on their held amount of OMNIA
     *      AND circulating supply.
     *      Once tokens have been claimed it increases next claim date to `rewardCyclePeriod`.
     *
     * @return bool
     *         whether `_msgSender()` has been able to claim their rewards or not.
     *
     * Emits a {RewardClaimed} event on successful claim.
     */
    function _doClaimReward() internal returns (bool) {
        (
            uint256 omnia,
            uint256 stablecoinInOmnia,
            uint256 customInOmnia
        ) = calculateManualClaimRewardTokens(_msgSender());

        (bool tokensSuccess, , , ) = _claimTokens(
            _msgSender(),
            omnia,
            stablecoinInOmnia,
            customInOmnia
        );

        // Update the next claim date & the total amount claimed
        _nextAvailableClaimDate[_msgSender()] =
            block.timestamp +
            rewardCyclePeriod;

        // Fire the event in case something was claimed
        if (tokensSuccess) {
            emit RewardClaimed(
                _msgSender(),
                omnia,
                stablecoinInOmnia,
                customInOmnia,
                _nextAvailableClaimDate[_msgSender()]
            );
        }

        return tokensSuccess;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Only methods that need to be used in OMNIA contract are present in this interface.
 * @dev Interface to use in OMNIA token contract.
 */
interface IRewards {
    function initialize(
        address routerManager_,
        address swapManager_,
        address omnia_
    ) external;

    function isProcessingAutoClaim() external view returns (bool);

    function updateNextClaimDate(
        address rewardee_,
        uint256 rewardeeBalance_,
        uint256 transferAmount_
    ) external;

    function updateRewardPointsOnTransfer(address sender_, address receiver_)
        external;

    function processAutoClaimIntervalReached() external view returns (bool);

    function autoClaimPaused() external view returns (bool);

    function processAutoClaim(uint256 gas) external;

    function maxBatchRewardsDistributionGAS() external returns (uint256);

    function updateAutoClaimQueue(address user) external;

    function updateEligibleSupplyForRewards(
        address sender_,
        address receiver_,
        uint256 sentAmount_,
        uint256 receivedAmount_
    ) external;

    function excludeContractFromRewards(address account_) external;

    function OMNIA_REFLECTION_WALLET() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClaimBatchRewards.sol";
import "./AutoClaimInterval.sol";
import "./AutoClaimPausable.sol";

/**
 * @notice Abstract contract, part of Rewards contract
 * @dev Triggers the auto claim process & update interval  for next auto claim.
 */
abstract contract AutoClaim is
    ClaimBatchRewards,
    AutoClaimInterval,
    AutoClaimPausable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // only used as {processAutoClaim} parameter
    uint256 internal _maxBatchRewardsDistributionGAS = 20 * 10**6; // The maximum gas to consume for sending out OMNIA and USDT as rewards.
    // only used as {processAutoClaim._processRewardsAutoClaim} parameter
    uint256 public autoClaimMinAmount = 5 * 10**18; // Minimum amount of OMNIA to swap into USDT. 5 OMNIA by default.

    bool internal _isProcessingAutoClaim; // Flag that indicates whether the queue is currently being processed and sending out rewards or not.

    event GasRefunded(uint256 amount, address to);

    /**
     * @notice Any external address/account/processor can process the claim queue when the auto claim is not paused.
     *         A transaction can use a maximum of 30M gas on BSC.
     *
     * @dev Sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1
     *      cycle through the whole queue.
     *
     * @param gas is the maximum amount of gas allowed to be consumed.
     */
    function processAutoClaim(uint256 gas)
        public
        virtual
        whenAutoClaimNotPaused
    {
        require(gas > 300000, "Gas < 300k");

        _isProcessingAutoClaim = true;

        _processRewardsAutoClaim(
            autoClaimQueueAddresses(),
            autoClaimMinAmount,
            gas
        );

        _updateAutoClaimProcessInterval();

        _isProcessingAutoClaim = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AutoClaimQueueList.sol";
import "../rewards/CumulativeRewardsCalculator.sol";
import "../swaps/BEP20Swap.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Swaps OMNIA to stablecoin for the addresses that chose it and sends out all rewards to everyone.
 */
abstract contract ClaimBatchRewards is
    AutoClaimQueueList,
    CumulativeRewardsCalculator,
    BEP20Swap
{
    uint256 internal _amountOmniaToSend; // How much OMNIA has to be sent during this auto claim cycle
    mapping(address => uint256) internal _omniaAmountOf; // How much OMNIA will be sent to selected rewardee

    uint256 internal _stableCoinAsOmniaToSwap; // How much OMNIA will be swapped into stablecoin for rewards
    uint256 internal _stableCoinSwappedForRewardsForCurrentAutoClaim; // How much stablecoin there is to be sent as rewards
    mapping(address => uint256) internal _stableCoinAmountInOmniaOf; // How much stablecoin will be sent to selected rewardee

    // prevent the owner from retrieving stablecoin left in the contract if a or multiple transfer failed
    uint256 public stablecoinLeftAsRewardsInREWARDSContract;

    // {processAutoClaim}
    uint256 public rewardClaimQueueIndex; // Pointer on current addresse's index while auto claim is happening
    uint256 private _maxBatchRewardClaimLength = 100; // How many addresses can be processed during a single auto claim

    event AutoClaimFailed(address rewardee, uint256 omnia, uint256 stable);
    event RewardAutoClaimed(
        address indexed rewardee,
        uint256 rewardInOMNIA,
        uint256 omniaRewardsAsStableToken,
        uint256 _nextAvailableClaimDate
    );

    /**
     * @dev Sets how many addresses can be processed during a single auto claim.
     *
     * Requirements:
     * - only the owner can set it
     */
    function setMaxBatchRewardClaimLength(uint256 _maxBatchLength)
        external
        onlyOwner
    {
        if (_maxBatchLength < 2) revert("batch < 2");
        _maxBatchRewardClaimLength = _maxBatchLength;
    }

    /**
     * @return uint256
     *         how many addresses can be processed during a single auto claim.
     */
    function maxBatchRewardClaimLength() external view returns (uint256) {
        return _maxBatchRewardClaimLength;
    }

    /**
     *
     * @dev Calculates amount of rewards as OMNIA and as stablecoin to send to a certain rewardee, swaps
     *      OMNIA to `rewardStableToken()` and sends out rewards to the right rewardee.
     *
     *      Only 100 addresses can be processed.
     *
     * @param rewardClaimQueue_ addresses included in current auto claim, see {AutoClaim.processAutoClaim()}.
     * @param autoClaimMinAmount mininmum amount of OMNIA needed to swap OMNIA to `rewardStableToken()`,
     *                           see {AutoClaim.autoClaimMinAmount}.
     */
    function _processRewardsAutoClaim(
        bytes32[] memory rewardClaimQueue_,
        uint256 autoClaimMinAmount,
        uint256 _maxDistributionGas
    ) internal {
        _calculateAmountOfRewardsToBeSent(rewardClaimQueue_);
        _swapOMNIAToStablecoinForRewards(autoClaimMinAmount);
        _distributeRewards(rewardClaimQueue_, _maxDistributionGas);
    }

    /**
     * @dev Calculates amount of OMNIA and `rewardStableToken()` to send as rewards to each addresses included in
     *      current auto claim.
     *      It can not process more than `_maxBatchRewardClaimLength` addresses per auto claim.
     *
     * @param rewardClaimQueue_ addresses included in current auto claim, see {AutoClaim.processAutoClaim()}.
     */
    function _calculateAmountOfRewardsToBeSent(
        bytes32[] memory rewardClaimQueue_
    ) internal {
        uint256 queueLength = rewardClaimQueue_.length;

        if (queueLength == 0 || _maxBatchRewardClaimLength == 0) {
            return;
        }

        uint256 _maxIters = queueLength > _maxBatchRewardClaimLength
            ? _maxBatchRewardClaimLength
            : queueLength;

        uint256 _integrationIteration = 0;
        rewardClaimQueueIndex = 0;

        while (_integrationIteration < _maxIters) {
            // bytes32 to address
            address _rewardee = _format(
                rewardClaimQueue_[rewardClaimQueueIndex]
            );

            // next rewardee
            rewardClaimQueueIndex++;
            _integrationIteration++;

            /// Amount of OMNIA and `rewardStableToken()` to be earned by `_rewardee`
            (
                uint256 omnia,
                uint256 stablecoinInOmnia
            ) = calculateAutoClaimRewardTokens(_rewardee);

            // OMNIA token
            _omniaAmountOf[_rewardee] = omnia;
            _amountOmniaToSend += omnia;

            // `rewardStableToken()`
            _stableCoinAmountInOmniaOf[_rewardee] = stablecoinInOmnia;
            _stableCoinAsOmniaToSwap += stablecoinInOmnia;
        }
    }

    /**
     * @dev Swaps OMNIA into `rewardStableToken()`, towards this Rewards contract.
     *      It saves the amount of `rewardStableToken()` the Rewards contract received to send rewards.
     *
     *      If amount of OMNIA to swap into `rewardStableToken()` is strictly lower than `minAmountToSwap_`,
     *      all rewardees will be rewarded in OMNIA instead. This limitation is not applied when a user
     *      manualy claim their rewards.
     *
     * @param minAmountToSwap_ mininmum amount of OMNIA needed to swap into `rewardStableToken()`,
     *                         see {AutoClaim.autoClaimMinAmount}.
     */
    function _swapOMNIAToStablecoinForRewards(uint256 minAmountToSwap_)
        internal
    {
        // Need a minimum amount of OMNIA to swap to `rewardStableToken()`
        if (_stableCoinAsOmniaToSwap >= minAmountToSwap_) {
            uint256 _initBalance = IERC20(rewardStableToken()).balanceOf(
                address(this)
            );
            _swapOMNIAForExactStablecoinRewardAmount(
                rewardStableToken(),
                _stableCoinAsOmniaToSwap
            );
            // Amount of `rewardStableToken()` swapped to this Rewards contract
            uint256 _swapped = IERC20(rewardStableToken()).balanceOf(
                address(this)
            ) - _initBalance;
            _stableCoinSwappedForRewardsForCurrentAutoClaim = _swapped;
            stablecoinLeftAsRewardsInREWARDSContract += _swapped;
        }
        // If the minimum amount of OMNIA required to swap is not attain, claim OMNIA instead
        // `rewardStableToken()`
        else {
            _amountOmniaToSend += _stableCoinAsOmniaToSwap;
            _stableCoinAsOmniaToSwap = 0;
        }
    }

    /**
     * @dev Sends rewards to all rewardees selected in {_calculateAmountOfRewardsToBeSent}.
     *
     *      Once rewards have sent to a rewardee it updates the amount of OMNIA left to send as rewards, updates
     *      next claiming date & updates how much rewards have been sent.
     *
     * @param rewardClaimQueue_ addresses included in current auto claim, see {AutoClaim.processAutoClaim()}.
     *
     * Emits a {RewardAutoClaimed} event.
     */
    function _distributeRewards(
        bytes32[] memory rewardClaimQueue_,
        uint256 maxGas_
    ) internal {
        uint256 queueLength = rewardClaimQueue_.length;

        if (queueLength == 0 || _maxBatchRewardClaimLength == 0) {
            return;
        }

        uint256 _maxIters = queueLength > _maxBatchRewardClaimLength
            ? _maxBatchRewardClaimLength
            : queueLength;

        uint256 _gasUsed = 0;
        uint256 _gasLeft = gasleft();

        // distribute tokens
        rewardClaimQueueIndex = 0;
        while (_gasUsed < maxGas_ && rewardClaimQueueIndex < _maxIters) {
            address _rewardee = _format(
                rewardClaimQueue_[rewardClaimQueueIndex]
            );

            rewardClaimQueueIndex++;

            uint256 _rewardPaidInOmnia = _distributeRewardsOf(_rewardee);

            if (_rewardPaidInOmnia == 0) continue;

            _amountOmniaToSend -= _rewardPaidInOmnia;

            // Update the next claim date by a cycle
            _nextAvailableClaimDate[_rewardee] =
                block.timestamp +
                rewardCyclePeriod;

            // Update total amount claimed
            _updateRewardsPaid(_rewardee, _rewardPaidInOmnia);

            uint256 _newGasLeft = gasleft();
            if (_gasLeft > _newGasLeft) {
                uint256 consumedGas = _gasLeft - _newGasLeft;
                _gasUsed += consumedGas;
                _gasLeft = _newGasLeft;
            }

            emit RewardAutoClaimed(
                _rewardee,
                _omniaAmountOf[_rewardee],
                _stableCoinAmountInOmniaOf[_rewardee],
                _nextAvailableClaimDate[_rewardee]
            );
        }
    }

    /**
     * @dev Distributes amount of `rewardStableToken()` and amount of OMNIA allocated to `rewardee_`.
     */
    function _distributeRewardsOf(address rewardee_)
        internal
        returns (uint256)
    {
        uint256 _rewardsAsOmniaPaid = 0;

        (
            ,
            ,
            uint256 _omniaToBePaidForStablecoin,
            uint256 _amountStablecoinSent
        ) = _distributeStablecoinRewardOf(rewardee_);

        // Claim in OMNIA if not claimed in stablecoin
        _omniaAmountOf[rewardee_] += _omniaToBePaidForStablecoin;

        // If the amount of OMNIA to be claimed by rewardee_ is greater than the balance of the Rewards contract
        // it can only claim what is left in the contract.
        uint256 _omniaAmount = _omniaAmountOf[rewardee_] >
            _rToken.balanceOf(address(this))
            ? _rToken.balanceOf(address(this))
            : _omniaAmountOf[rewardee_];

        if (_omniaAmount == 0) {
            return 0;
        }

        try _rToken.transfer(rewardee_, _omniaAmount) returns (bool success) {
            if (success) _rewardsAsOmniaPaid += _omniaAmount;
        } catch {
            emit AutoClaimFailed(
                rewardee_,
                _omniaAmount,
                _amountStablecoinSent
            );
        }

        return _rewardsAsOmniaPaid;
    }

    /**
     * @dev Sends out exact amount of `rewardStableToken()` allocated to `rewardee_`.
     */
    function _distributeStablecoinRewardOf(address rewardee_)
        internal
        returns (
            bool _paid,
            uint256 _omniaPaidAsToken,
            uint256 _omniaToBePaid,
            uint256 _amountStablecoinSent
        )
    {
        IERC20 stable = IERC20(rewardStableToken());

        // Value returned by default when reward transfer fails for any reason
        _paid = false;
        _omniaPaidAsToken = 0;
        _amountStablecoinSent = 0;

        uint256 _rewardsAsOmnia = _stableCoinAmountInOmniaOf[rewardee_];

        // Do the calculation of how much `rewardStableToken()` is allocated to `rewardee_`,
        // if _stableCoinAsOmniaToSwap != 0 to avoid arithmetic errors
        uint256 _tokenRewards = _stableCoinAsOmniaToSwap != 0
            ? (_rewardsAsOmnia *
                _stableCoinSwappedForRewardsForCurrentAutoClaim) /
                _stableCoinAsOmniaToSwap
            : 0;
        // If amount allocated to `rewardee_` is higher than balance of Rewards contract, it sends what is left
        // otherwise send the exact amount required
        _tokenRewards = _tokenRewards >= stable.balanceOf(address(this))
            ? stable.balanceOf(address(this))
            : _tokenRewards;

        /// If `rewardStableToken()` is not set or rewards to send equal to 0, claim `rewards_` as OMNIA.
        // Also works when `rewardStableToken()` transfer fails for any reason
        _stableCoinAmountInOmniaOf[rewardee_] = 0;
        _omniaToBePaid = _rewardsAsOmnia;

        if (rewardStableToken() == address(0) || _tokenRewards == 0) {} else {
            /// Transfer should never fail due to insufficient amount due to
            // `_stableCoinSwappedForRewardsForCurrentAutoClaim` & `_tokenRewards` variables.
            try stable.transfer(rewardee_, _tokenRewards) returns (
                bool success
            ) {
                if (success) {
                    _paid = true;
                    _omniaPaidAsToken = _rewardsAsOmnia;
                    _omniaToBePaid = 0;
                    _amountStablecoinSent = _tokenRewards;
                    // Update how much `rewardStableToken()` there is left into Rewards contract to send as rewards
                    stablecoinLeftAsRewardsInREWARDSContract -= _tokenRewards;
                }
            } catch {}
        }
    }

    /**
     * @dev Converts byte32 to address.
     * @param addr address in byte32.
     * @return address converted from byte32.
     */
    function _format(bytes32 addr) internal pure returns (address) {
        return address(uint160(uint256(addr)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 *
 * @dev Tracks, sets & update when auto claim can be processed on transfers.
 */
abstract contract AutoClaimInterval is Ownable {
    uint256 public lastAutoClaimProcessed; // last time auto claim queue has been processed
    uint256 public processAutoClaimInterval = 1 hours; // interval between 2 auto claim (on transfers)

    /**
     * @dev Updates the time required to wait between two auto claim when a transfer happens.
     * @param interval_ new auto claim interval in seconds
     *
     * Requirements:
     *
     * - `interval_` cant be greater than 6h.
     */
    function setAutoClaimInterval(uint256 interval_) external onlyOwner {
        if (interval_ > 6 hours) revert("> 6h");
        _setAutoClaimInterval(interval_);
    }

    /**
     * @dev Updates last time the auto claim has been processed, to now.
     */
    function _updateAutoClaimProcessInterval() internal {
        lastAutoClaimProcessed = block.timestamp;
    }

    /**
     * @dev Checks if the auto claim can be processed.
     * @return bool
     *         if no auto claim since deployment (lastAutoClaimProcessed == 0): _true_
     *         otherwise: verify 6h has passed since last auto claim
     */
    function processAutoClaimIntervalReached()
        public
        view
        virtual
        returns (bool)
    {
        return
            lastAutoClaimProcessed == 0
                ? true
                : block.timestamp >=
                    lastAutoClaimProcessed + processAutoClaimInterval;
    }

    /**
     * @dev Sets time interval between two auto claim.
     * @param interval_ time interval in seconds.
     */
    function _setAutoClaimInterval(uint256 interval_) private {
        processAutoClaimInterval = interval_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Pauses or un-pauses auto claim.
 */

abstract contract AutoClaimPausable is Ownable {
    bool internal _autoClaimPaused = false;

    modifier whenAutoClaimNotPaused() {
        require(!_autoClaimPaused, "auto claim paused");
        _;
    }

    function autoClaimPaused() public view virtual returns (bool) {
        return _autoClaimPaused;
    }

    function setPauseAutoClaim(bool _paused) public onlyOwner {
        _autoClaimPaused = _paused;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../rewards/RewardExcludedList.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Updates the queue for current auto claim & allow an address/account to exclude itself
 *      from auto claim (useful in case the address/account really wants to earn custom
 *      rewards).
 */

abstract contract AutoClaimQueueList is RewardExcludedList {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Save addresses included into auto claim process
    EnumerableSet.AddressSet internal _rewardAutoClaimQueue;
    // Save addresses excluded from auto claim
    EnumerableSet.AddressSet internal _rewardAutoClaimQueueExcluded;

    /**
     * @dev Updates `user` auto claim queue status.
     */
    function updateAutoClaimQueue(address user) public virtual {
        bool isQueued = _rewardAutoClaimQueue.contains(user);
        if (!isIncludedInRewards(user)) {
            if (isQueued) _rewardAutoClaimQueue.remove(user);
        } else {
            if (!isQueued) _rewardAutoClaimQueue.add(user);
        }
    }

    /**
     * @dev `_msgSender()` can exclude themselves from auto claim to only benefit from manual claim
     *      specific rewards.
     *      They can re-includes themselves in auto claim if they were previously excluded.
     *
     * Requirements:
     * - if selfExclude is true: `_msgSender()` cannot already be excluded from rewards
     * - if selfExclude is false: `_msgSender()` cannot already be included in rewards
     */
    function setExcludedFromAutoClaim(bool selfExclude) external {
        if (selfExclude) {
            require(
                _rewardAutoClaimQueueExcluded.add(_msgSender()),
                "Already excluded from auto claim"
            );
            _rewardAutoClaimQueue.remove(_msgSender());
        } else {
            require(
                _rewardAutoClaimQueueExcluded.remove(_msgSender()),
                "Already included in auto claim"
            );
            updateAutoClaimQueue(_msgSender());
        }
    }

    /**
     * @notice bytes32 can be converted into address using: address(uint160(uint256(addr))).
     * @dev Usage of _bytes32[] memory_ to store addresses, is due to {EnumerableSet.AddressSet}.
     *
     * @return bytes32[] memory
     *         All addresses included in next auto claim.
     */
    function autoClaimQueueAddresses() public view returns (bytes32[] memory) {
        return _rewardAutoClaimQueue._inner._values;
    }

    /**
     * @return bool
     *         whether `addr` has chosen to exclude itself from auto claim or not.
     */
    function excludedFromAutoClaim(address rewardee_)
        external
        view
        returns (bool)
    {
        return _rewardAutoClaimQueueExcluded.contains(rewardee_);
    }

    /**
     * @return bool
     *         whether `addr` is included or not in the next auto claim.
     */
    function isInRewardClaimQueue(address addr) external view returns (bool) {
        return _rewardAutoClaimQueue.contains(addr);
    }

    /**
     * @return uint256
     *         how much addresses will be paid during next auto claim.
     *
     */
    function rewardClaimQueueLength() external view returns (uint256) {
        return _rewardAutoClaimQueue.length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardCycle.sol";
import "./AutoRewardClaimTokensTracker.sol";
import "./ManualRewardClaimTokensTracker.sol";
import "./RewardExcludedList.sol";
import "./CustomRewardTokenConfig.sol";
import "./StableTokenRewardManager.sol";
import "../../Token/interfaces/IOMNIA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Calculates amount of tokens (in OMNIA) to be rewarded to each user
 * according to its cumulative reward points and total amount of OMNIA tokens
 * stored as reward tokens through transfer fee.
 * Rewards points are the integral of user's OMNIA balance in the course of time.
 *
 * Calculator considers reward configurations of rewardees to distribute rewards
 * in terms of OMNIA, Custom and Stable tokens.
 */
abstract contract CumulativeRewardsCalculator is
    RewardCycle,
    AutoRewardClaimTokensTracker,
    ManualRewardClaimTokensTracker,
    RewardExcludedList,
    CustomRewardTokenConfig,
    StableTokenRewardManager
{
    // total amount of rewards paid to rewardees, expressed in OMNIA
    uint256 public totalRewardsPaidInOMNIA;
    // total amount of rewards paid to an address
    mapping(address => uint256) internal _rewardsOf;

    // total reward points (Integral of (totalSupplyEligible * timePassed))
    uint256 private _totalRewardPoints;
    // total reward points of an address
    mapping(address => uint256) private _rewardPoints;
    // las time reward points have been updated for an address
    mapping(address => uint256) internal _lastRewardPointsUpdatedOf;
    // las time reward points have been updated
    uint256 internal _lastRewardPointsUpdated;

    // total amount of tokens held by addresses eligible for rewards
    // some contracts can be excluded from rewards:
    // e.g. Rewards, OMNIA, Farming...
    uint256 public totalSupplyEligibleForRewards;

    /*-------------------Rewards Paid----------------------*/

    /**
     * @dev Updates total rewards paid to a specified rewardee and total rewards ever paid.
     * @param rewardee_ address that has been rewarded.
     * @param rewards_ new amount of OMNIA sent as rewards.
     */
    function _updateRewardsPaid(address rewardee_, uint256 rewards_) internal {
        _rewardsOf[rewardee_] += rewards_;
        totalRewardsPaidInOMNIA += rewards_;
    }

    /**
     * @return uint256
     *         total amount of rewards paid to `rewardee_`, expressed in OMNIA.
     */
    function rewardedTo(address rewardee_) external view returns (uint256) {
        return _rewardsOf[rewardee_];
    }

    /*-------------------Eligible to reward----------------------*/

    /**
     * @dev Updates total amount of tokens that is eligible for rewards, as some contracts
     *      can be excluded from rewards.
     *
     * @param sender_ address which sends tokens.
     * @param receiver_ address which receives tokens.
     * @param sentAmount_ amount of tokens sent by `sender_`.
     * @param receivedAmount_ amount of tokens received by `receiver_` after fee
     */
    //TODO: issue if min balance for rewards is updated
    //TODO: isIncludedInRewards or _isExcluded?
    function updateEligibleSupplyForRewards(
        address sender_,
        address receiver_,
        uint256 sentAmount_,
        uint256 receivedAmount_
    ) public virtual {
        // if `sender_` is not eligible and `receiver_` is eligible
        if (
            !isIncludedInRewards(sender_) && !_isExcludedFromRewards(receiver_)
        ) {
            totalSupplyEligibleForRewards += receivedAmount_;
        }
        // if `sender_` is eligible & `receiver_` is NOT eligible
        if (isIncludedInRewards(sender_) && _isExcludedFromRewards(receiver_)) {
            totalSupplyEligibleForRewards -= sentAmount_;
        }
        // if both are eligible
        if (
            isIncludedInRewards(sender_) && !_isExcludedFromRewards(receiver_)
        ) {
            uint256 fee = sentAmount_ - receivedAmount_;
            totalSupplyEligibleForRewards -= fee;
        }
    }

    /*-------------------Rewards Points----------------------*/

    /**
     * @dev Updates `_totalRewardPoints` by computing Integral of (total eligible supply * time)
     *      and last time it was updated.
     *
     *      It also updates total reward points for `sender_` & `receiver_`.
     *
     * @param sender_ address which sends tokens.
     * @param receiver_ address which receives tokens.
     */
    function updateRewardPointsOnTransfer(address sender_, address receiver_)
        public
        virtual
    {
        // Time passed since last time `_totalRewardPoints` was updated till now
        // if points have never been updated return 0
        uint256 _timePassed = _lastRewardPointsUpdated > 0
            ? block.timestamp - _lastRewardPointsUpdated
            : 0;

        _totalRewardPoints += _timePassed * totalSupplyEligibleForRewards;

        _updateRewardPointsOf(sender_);
        _updateRewardPointsOf(receiver_);

        // update last update time of `_totalRewardPoints` to now
        _lastRewardPointsUpdated = block.timestamp;
    }

    /**
     * @dev Calculates and returns total reward points according to last total points
     * and total balances eligible to reward
     * @return uint256
     *         total reward points, taking into account: balance eligible for rewards &
     *         time passed since last `_totalRewardPoints` update.
     */
    function _getTotalRewardPoints() internal view returns (uint256) {
        uint256 _timePassed = _lastRewardPointsUpdated > 0
            ? block.timestamp - _lastRewardPointsUpdated
            : 0;
        return _totalRewardPoints + _timePassed * totalSupplyEligibleForRewards;
    }

    /**
     * @dev Updates reward points of a specified address and last time
     *      their were updated.
     *
     *      If `rewardee_` is excluded from rewards it doesnt update the
     *      time, nor the point.
     *
     * @param rewardee_ address of which reward points must be updated.
     */
    function _updateRewardPointsOf(address rewardee_) internal {
        // last _rewardPoints is already calculated inside _getRewardPointsOf, no need of
        //  another addition
        _rewardPoints[rewardee_] = _getRewardPointsOf(rewardee_);
        _lastRewardPointsUpdatedOf[rewardee_] = !_isExcludedFromRewards(
            rewardee_
        )
            ? block.timestamp
            : _lastRewardPointsUpdatedOf[rewardee_];
    }

    /**
     * @notice It doesnt update the points if `rewardee_` is excluded from rewards.
     * @param rewardee_ address reward points to be calculated.
     * @return uint256
     *         total reward points of `rewardee_`, taking into account: current balance
     *         of `rewardee_` and last time their rewards points have been updated.
     */
    function _getRewardPointsOf(address rewardee_)
        internal
        view
        returns (uint256)
    {
        if (!_isExcludedFromRewards(rewardee_)) {
            uint256 _timePassed = _lastRewardPointsUpdatedOf[rewardee_] > 0
                ? block.timestamp - _lastRewardPointsUpdatedOf[rewardee_]
                : 0;

            return
                _rewardPoints[rewardee_] +
                _timePassed *
                _rToken.balanceOf(rewardee_);
        } else {
            return 0;
        }
    }

    /*-------------------Rewards Calculators----------------------*/

    /**
     * @param rewardee_ address that might be rewarded.
     * @return _pendingRewards
     *         total amount of tokens, expressed in OMNIA, `rewardee_` will received if
     *         they claim it.
     */
    function getPendingRewardsAsOMNIA(address rewardee_)
        external
        view
        returns (uint256 _pendingRewards)
    {
        _pendingRewards = _calculateOMNIAReward(rewardee_);
    }

    /**
     * @dev Calculates rewards of a specified address according to each token share set
     *      for manual claim.
     *
     * @param rewardee_ address of who might be rewarded
     *
     * @return omnia
     *         amount of OMNIA to be received by `rewardee_`.
     *
     * @return stablecoinInOmnia
     *         amount of stablecoin (in OMNIA) to be received by `rewardee_`.
     *
     * @return customInOmnia
     *         amount of custom token (in OMNIA) to be received by `rewardee_`.
     */
    function calculateManualClaimRewardTokens(address rewardee_)
        public
        view
        returns (
            uint256 omnia,
            uint256 stablecoinInOmnia,
            uint256 customInOmnia
        )
    {
        uint256 reward = _calculateOMNIAReward(rewardee_);

        return (_calculateManualClaimRewardTokensOf(rewardee_, reward));
    }

    /**
     * @dev Calculates rewards of a specified address according to each token share set for auto claim
     *
     * @param rewardee_ address of who might be rewarded
     *
     * @return omnia
     *         amount of OMNIA to be received by `rewardee_`.
     *
     * @return stablecoinInOmnia
     *         amount of stablecoin (in OMNIA) to be received by `rewardee_`.
     */
    function calculateAutoClaimRewardTokens(address rewardee_)
        public
        view
        returns (uint256 omnia, uint256 stablecoinInOmnia)
    {
        uint256 reward = _calculateOMNIAReward(rewardee_);

        return (_calculateAutoClaimRewardTokensOf(rewardee_, reward));
    }

    /**
     * @dev Calculates total amount of rewards to be paid to a specified address
     *
     * @param rewardee_ address to be rewarded.
     * @return _toBeRewarded
     *         total amount of OMNIA tokens that might be rewarded.
     */
    function _calculateOMNIAReward(address rewardee_)
        internal
        view
        returns (uint256 _toBeRewarded)
    {
        if (!isIncludedInRewards(rewardee_)) _toBeRewarded = 0;

        // if the time has not come for `rewardee_`
        if (block.timestamp < nextAvailableClaimDate(rewardee_)) return 0;

        uint256 _rewardPointsOf = _getRewardPointsOf(rewardee_);
        uint256 _rewardeesTotalRewardPoints = _getTotalRewardPoints();

        if (_rewardeesTotalRewardPoints == 0) return 0;

        uint256 _totalFeesPooledForRewards = IOMNIA(address(_rToken))
            .totalFeesPooledForRewards();

        uint256 _totalRewards = (_totalFeesPooledForRewards * _rewardPointsOf) /
            _rewardeesTotalRewardPoints;

        _toBeRewarded = _totalRewards - _rewardsOf[rewardee_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../Router/interfaces/IRouterManager.sol";
import "../../SwapManager/ISwapManager.sol";
import "../../Token/imported/ERC20.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 *
 * @dev Swaps OMNIA to any BEP20 token.
 */
abstract contract BEP20Swap {
    IRouterManager public router;
    ISwapManager public swapManager;
    ERC20 public omnia;

    event OmniaToBEP20Swap(
        uint256 omniaAmount,
        address token,
        uint256 tokenMaxOut
    );
    event OmniaToBEP20SwapFailed(string reason);

    /**
     * @dev Swap OMNIA to selected BEP20 token.
     *      It uses {SwapManager.pathAndMaxOut()} to get the maximum amount of `bep20Token_`
     *      the `receiver_` can get.
     *
     * @param bep20Token_ address of BEP20 to swap OMNIA into.
     * @param omniaAmount_ amount of OMNIA to swap into `bep20Token_`.
     * @param receiver_ address that will receive the amount of `bep20Token_`.
     *
     * @return bool
     *         swap succeed or failed.
     *
     * Emits a {OmniaToBEP20Swap} event, if the OMNIA > BNB > BEP20 swap succeed.
     * Emits a {OmniaToBEP20SwapFailed} event, if the OMNIA > BNB > BEP20 swap failed, containing the reason of the failure.
     */
    function _swapOMNIAForBEP20(
        address bep20Token_,
        uint256 omniaAmount_,
        address receiver_
    ) internal returns (bool) {
        (uint256 maxOut, address[] memory path) = swapManager.pathAndMaxOut(
            address(omnia),
            bep20Token_,
            omniaAmount_
        );
        omnia.increaseAllowance(
            address(router.pancakeswapV2Router()),
            omniaAmount_
        );

        try
            router
                .pancakeswapV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    omniaAmount_,
                    swapManager.calculateSplippageOn(maxOut),
                    path,
                    receiver_,
                    block.timestamp + 360
                )
        {
            emit OmniaToBEP20Swap(omniaAmount_, bep20Token_, maxOut);
            return true;
        } catch Error(string memory reason) {
            emit OmniaToBEP20SwapFailed(reason);
            return false;
        }
    }

    /**
     * @dev Swaps OMNIA for `rewardStableToken()` for an exact amount of 
     *      stablecoin that will be sent as rewards.
     *
     *      e.g. there are 10 USDT left in the Rewards contract and we 
     *           need to send 12 USDT, we only need to send 12 - 10 = 2 USDT.
                 We only swap `_omniaAmountToBeSwapped` OMNIA to get 2 more
                 USDT.
     *
     * @param stablecoin_ address of custom BEP20 token to swap OMNIA into.
     * @param maxOmniaAmount_ maximum OMNIA amount available for swap.
     */
    function _swapOMNIAForExactStablecoinRewardAmount(
        address stablecoin_,
        uint256 maxOmniaAmount_
    ) internal returns (bool) {
        (uint256 maxOut, ) = swapManager.pathAndMaxOut(
            address(omnia),
            stablecoin_,
            maxOmniaAmount_
        );

        uint256 _omniaBalance = IERC20(stablecoin_).balanceOf(address(this));

        if (_omniaBalance < maxOut) {
            // Swap only needed amount
            uint256 _omniaAmountToBeSwapped = (maxOmniaAmount_ -
                (maxOmniaAmount_ * _omniaBalance) /
                maxOut);

            return
                _swapOMNIAForBEP20(
                    stablecoin_,
                    _omniaAmountToBeSwapped,
                    address(this)
                );
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../libraries/IsContractLib.sol";
import "../../Token/imported/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Verifies addresses excluded from rewards.
 *
 *      Allows the owner to exclude a contract from rewards and update the minimum
 *      amount of OMNIA required to get rewards.
 */
abstract contract RewardExcludedList is Ownable, Initializable {
    ERC20 internal _rToken;

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
    // By default, 10 OMNIA is required to be eligible for rewards
    // This is made to prevent wasting gas in auto claim for too
    // small rewards amounts.
    uint256 private _minIndividualClaimAmount = 10 * 10**18;

    address private constant _OMNIA_REFLECTION_WALLET =
        0x19eF52F4cE991fe9705c3a443dc1c2C7DDdB2fF9;

    /**
     * @dev Initialise OMNIA address as reward token, `_rToken`.
     */
    function _initializeRewardExcludedList(ERC20 rToken_) internal initializer {
        _rToken = rToken_;
    }

    /**
     * @dev In-exclude `account_` from rewards.
     *
     * @param account_ address to in-exclude from rewards.
     * @param isExcluded_ bool to in-exclude `account_` from rewards.
     */
    function _setExcludedFromRewards(address account_, bool isExcluded_)
        internal
    {
        if (isExcluded_) _addressesExcludedFromRewards.add(account_);

        if (!isExcluded_) _addressesExcludedFromRewards.remove(account_);
    }

    /**
     * @notice Only a contract can be excluded.
     * @dev Exclude contract's address from rewards.
     *
     * Requirements:
     * only the owner can exclude a contract.
     */
    function excludeContractFromRewards(address account_) public virtual {
        require(
            IsContractLib.isContract(account_) &&
                account_ != _OMNIA_REFLECTION_WALLET,
            "OMNIA wallet"
        );
        _setExcludedFromRewards(account_, true);
    }

    /**
     * @notice Only a contract can be included in rewards again.
     * @dev Include contract's address in rewards again.
     *
     * Requirements:
     * only the owner can include a contract again.
     */
    function includeContractInRewards(address account_) external onlyOwner {
        require(IsContractLib.isContract(account_), "Not a contract");
        _setExcludedFromRewards(account_, false);
    }

    /**
     * @dev Sets the minimum amount of OMNIA to held to benefit from reflection rewards.
     *
     * @param minIndividualClaimAmount_ minimum amount of OMNIA to earn reflection rewards.
     *
     * Requirements:
     * - only the owner can update `_minIndividualClaimAmount`.
     * - `minIndividualClaimAmount_` must stricly be higher than 0 OMNIA.
     * - `minIndividualClaimAmount_` must stricly be lower than 100 OMNIA.
     */
    function setMinIndividualClaimAmount(uint256 minIndividualClaimAmount_)
        external
        onlyOwner
    {
        require(minIndividualClaimAmount_ > 0, "amount <= 0");
        require(minIndividualClaimAmount_ <= 100 * 10**18, "amount > 100");
        _minIndividualClaimAmount = minIndividualClaimAmount_;
    }

    /**
     * @return bool
     *         whether an address is in list of excluded addresses or not.
     */
    function _isExcludedFromRewards(address account_)
        internal
        view
        returns (bool)
    {
        return EnumerableSet.contains(_addressesExcludedFromRewards, account_);
    }

    /**
     * @return bool
     *         whether `user` has at the very least {minIndividualClaimAmount()}, which is 10 OMNIA by
     *         default, AND is not included into {_addressesExcludedFromRewards} EnumerableSet.
     */
    function isIncludedInRewards(address user) public view returns (bool) {
        return
            _rToken.balanceOf(user) >= _minIndividualClaimAmount &&
            !_isExcludedFromRewards(user);
    }

    /**
     * @return uint256
     *         current minimum blance of OMNIA required to earn reflection rewards, 10 OMNIA by default.
     */
    function minIndividualClaimAmount() public view returns (uint256) {
        return _minIndividualClaimAmount;
    }

    /**
     * @return address
     *         wallet of Omnia DeFi company that earns reflection rewards.
     *         when 10M total supply will be released, 5% of it will be helded in this wallet
     *         to allow a steady growth of Omnia DeFi and the CreateLinX ecosystem.
     */
    function OMNIA_REFLECTION_WALLET() public view virtual returns (address) {
        return _OMNIA_REFLECTION_WALLET;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library IsContractLib {
    /**
     * @notice An addres is a contract if its {extcodesize} is greater than 0.
     *
     * @return bool
     *         on whether `account` is a contract.
     */
    function isContract(address account) external view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice _balances has been set as an internal variable & _mint has been updated.
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    /**
     * @dev Made private by Openzeppelin. Internal required for OMNIA as the reflection
     * needed to updates balances to take fees
     */
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @notice _beforeTokenTransfer & _afterTokenTransfer have been deleted because we override
     *         these functions later and it creates issue when the OMNIA token is deployed.
     *@dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../Token/imported/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Manage cycle extension of reward claiming.
 */
abstract contract RewardCycle is Ownable, Initializable {
    ERC20 private _rToken;

    // Can claim rewards every 6h
    uint256 public immutable rewardCyclePeriod = 6 hours;

    // If someone sends or receives more than 50% of their current balance in a transaction,
    // their reward cycle date will increase accordingly (max one more cycle to get rewards)
    uint8 private _rewardCycleExtensionThresholdOnTransfers = 50;
    // The next available reward claim date for each address
    mapping(address => uint256) internal _nextAvailableClaimDate;

    /**
     * @dev Initialise OMNIA address as reward token, `_rToken`.
     */
    function _initializeRewardCycle(ERC20 rToken_) internal initializer {
        _rToken = rToken_;
    }

    /**
     * @dev Updates `_rewardCycleExtensionThresholdOnTransfers`: percentage
     *      limit transferred/received of the toal amount held, which
     *      triggers a specific cycle extension for rewards claiming.
     *
     *      The extension is proportional to percentage sent, e.g. if Alice
     *      sends 50% of her helded amount she will have to wait another
     *      3h (6h * 0.5) before claiming her rewards.
     *
     * @param threshold amount expressed in percentage.
     *
     * Requirements:
     * - `threshold` cannot be stricly lower than 0.
     * - `threshold` cannot be stricly higher than 100.
     */
    function setRewardCycleExtensionThreshold(uint8 threshold)
        external
        onlyOwner
    {
        require(threshold >= 0 && threshold <= 100, "Percentage only");
        _rewardCycleExtensionThresholdOnTransfers = threshold;
    }

    /**
     * @return uint256
     *         Percentage limit transferred/received of the toal amount held,
     *         which triggers a specific cycle extension for rewards claiming.
     */
    function rewardCycleExtensionThresholdOnTransfers()
        external
        view
        returns (uint8)
    {
        return _rewardCycleExtensionThresholdOnTransfers;
    }

    /**
     * @dev Update next reward claim date for `rewardee_` while using
     *      {calculateRewardCycleExtension()}.
     *
     * @param rewardee_ address that will see its reward claim date increase.
     * @param rewardeeBalance_ total balance of OMNIA of `rewardee_`.
     * @param transferAmount_ amount of OMNIA transfered, without any fee applied.
     */
    function updateNextClaimDate(
        address rewardee_,
        uint256 rewardeeBalance_,
        uint256 transferAmount_
    ) public virtual {
        _nextAvailableClaimDate[rewardee_] += calculateRewardCycleExtension(
            rewardeeBalance_,
            transferAmount_,
            _nextAvailableClaimDate[rewardee_]
        );
    }

    /**
     * @param ofAddress address of which we want to query `_nextAvailableClaimDate`.
     * @return uint256
     *         time in seconds when `ofAddress` can claim their rewards.
     */
    function nextAvailableClaimDate(address ofAddress)
        public
        view
        returns (uint256)
    {
        return _nextAvailableClaimDate[ofAddress];
    }

    /**
     * @dev Calculates how much (and if) the reward cycle of an address should
     *      be increased, based on its current balance and the amount
     *      transferred in a transaction.
     *
     *      Both the sender and recipient can get their claiming rewards
     *      cycle increased.
     *
     *      To avoid increasing the next claiming rewards date for dozens of
     *      years we need `nextAvailableClaimDate_`.
     *
     * @param balance total balance of OMNIA held by an address.
     * @param amount amount of OMNIA tokens to be sent/received.
     * @param nextAvailableClaimDate_ current next claiming date for an address.
     *
     * @return uint256
     *         next reward claiming date for an address in seconds.
     */
    function calculateRewardCycleExtension(
        uint256 balance,
        uint256 amount,
        uint256 nextAvailableClaimDate_
    ) public view returns (uint256) {
        if (balance == 0) {
            /** Receiving $OMNIA on a zero balance address means:
             *
             * - either the address has never received tokens before. Its current
             *   reward date is 0, in which case we need to set its initial value
             *
             *- or the address has transferred all of its tokens in the past and
             *  has now received some again, in which case we will add another
             *  reward cycle (6h).
             */
            return
                nextAvailableClaimDate_ == 0
                    ? block.timestamp + rewardCyclePeriod
                    : rewardCyclePeriod;
        }

        uint256 percentageTransferred = (amount * 100) / balance;

        /**
         * Depending on the % of $OMNIA tokens transferred/received, relative to the
         * balance, we might need to extend the period a bit more.
         */
        if (
            percentageTransferred >= _rewardCycleExtensionThresholdOnTransfers
        ) {
            // If new balance is X percent higher, then we will extend the reward date by X percent
            uint256 extension = (rewardCyclePeriod * percentageTransferred) /
                100;

            // Cap to the base period
            if (extension >= rewardCyclePeriod) {
                extension = rewardCyclePeriod;
            }

            return extension;
        }

        return 0;
    }

    /**
     * @return bool
     *         whether `user` can already claim they rewards (exact date or later) or not.
     */
    function isRewardReady(address user) public view returns (bool) {
        return _nextAvailableClaimDate[user] <= block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Let an address configures their percentage of OMNIA and stablecoin to earn during auto claim.
 */
abstract contract AutoRewardClaimTokensTracker is Context {
    struct AutoClaimTokenConfig {
        uint8 omnia;
        uint8 stable;
    }

    mapping(address => AutoClaimTokenConfig) private _autoClaimTokenConfig;

    event AutoClaimRewardTokenConfigSet(uint8 omnia, uint8 stable);

    /**
     * @param rewardee_ address of user of which we want to get auto claim rewards configuration.
     * @return AutoClaimTokenConfig
     *         percentage of OMNIA and stablecoin to be rewarded in during auto claim.
     */
    function autoClaimTokenConfig(address rewardee_)
        external
        view
        returns (AutoClaimTokenConfig memory)
    {
        return _autoClaimTokenConfig[rewardee_];
    }

    /**
     * @dev Sets OMNIA and stablecoin percentages for `_msgSender()` to use during auto claim.
     *
     * @param autoClaimTokenConfig_ token configuration containing  OMNIA and stablecoin percentages.
     *
     * Emits a {AutoClaimRewardTokenConfigSet} event.
     */
    function setAutoRewardClaimTokenConfig(
        AutoClaimTokenConfig memory autoClaimTokenConfig_
    ) external {
        uint16 _totalPercentage = autoClaimTokenConfig_.omnia +
            autoClaimTokenConfig_.stable;

        require(_totalPercentage == 100, "Sum: not 100%");
        _autoClaimTokenConfig[_msgSender()] = autoClaimTokenConfig_;

        emit AutoClaimRewardTokenConfigSet(
            autoClaimTokenConfig_.omnia,
            autoClaimTokenConfig_.stable
        );
    }

    /**
     * @dev Calculates amount of OMNIA and amount of stablecoin (expressed in OMNIA), to be claimed during auto claim
     *      and sent to `rewardee_`.
     *
     * @param rewardee_ address of user to be rewarded.
     * @param rewards_ total amount of rewards in OMNIA.
     *
     * @return uint256
     *         exact amount of OMNIA to be rewarded
     * @return uint256
     *         exact amount of stablecoin to be rewarded, expressed in OMNIA.
     */
    function _calculateAutoClaimRewardTokensOf(
        address rewardee_,
        uint256 rewards_
    ) internal view returns (uint256, uint256) {
        if (areAutoClaimRewardTokensPercentageSet(rewardee_)) {
            AutoClaimTokenConfig
                memory rewardTokenConfig = _autoClaimTokenConfig[rewardee_];

            return (
                (rewards_ * rewardTokenConfig.omnia) / 100,
                (rewards_ * rewardTokenConfig.stable) / 100
            );
        } else {
            return (rewards_, 0);
        }
    }

    /**
     * @dev Checks if `rewardee_` has customised their auto claim rewards to earn some stablecoin or not.
     *
     * @param rewardee_ user address.
     * @return bool
     *         whether `rewardee_` has configured their auto claim rewards or not.
     */
    function areAutoClaimRewardTokensPercentageSet(address rewardee_)
        public
        view
        returns (bool)
    {
        AutoClaimTokenConfig memory _rewardTokenConfig = _autoClaimTokenConfig[
            rewardee_
        ];

        uint16 _totalPercentage = _rewardTokenConfig.omnia +
            _rewardTokenConfig.stable;

        return _totalPercentage == 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Let an address configures their percentage of OMNIA, stablecoin & custom token to earn during manual claim.
 */
abstract contract ManualRewardClaimTokensTracker is Context {
    struct ManualClaimTokenConfig {
        uint8 omnia;
        uint8 stable;
        uint8 custom;
    }

    mapping(address => ManualClaimTokenConfig) private _manualClaimTokenConfig;

    event ManualClaimRewardTokenConfigSet(
        uint8 omnia,
        uint8 stable,
        uint8 custom
    );

    /**
     * @param rewardee_ address of user of which we want to get manual claim rewards configuration.
     * @return ManualClaimTokenConfig
     *         percentage of OMNIA, stablecoin & custom token to be rewarded in during manual claim.
     */
    function manualClaimTokenConfig(address rewardee_)
        external
        view
        returns (ManualClaimTokenConfig memory)
    {
        return _manualClaimTokenConfig[rewardee_];
    }

    /**
     * @dev Sets OMNIA, stablecoin & custom token percentages for `_msgSender()` to use during
     *      manual claim.
     *
     * @param manualClaimTokenConfig_ token configuration containing  OMNIA, stablecoin & custom
     *                              token percentages.
     *
     * Emits a {ManualClaimRewardTokenConfigSet} event.
     */
    function setManualRewardClaimTokenConfig(
        ManualClaimTokenConfig memory manualClaimTokenConfig_
    ) external {
        uint16 _totalPercentage = manualClaimTokenConfig_.omnia +
            manualClaimTokenConfig_.stable +
            manualClaimTokenConfig_.custom;

        require(_totalPercentage == 100, "Sum: not 100%");
        _manualClaimTokenConfig[_msgSender()] = manualClaimTokenConfig_;

        emit ManualClaimRewardTokenConfigSet(
            manualClaimTokenConfig_.omnia,
            manualClaimTokenConfig_.stable,
            manualClaimTokenConfig_.custom
        );
    }

    /**
     * @dev Calculates amount of OMNIA, stablecoin & custom token (both expressed in OMNIA), to be
     *      claimed during manual claim and sent to `rewardee_`.
     *
     * @param rewardee_ address of user to be rewarded.
     * @param rewards_ total amount of rewards in OMNIA.
     *
     * @return uint256
     *         exact amount of OMNIA to be rewarded
     * @return uint256
     *         exact amount of stablecoin to be rewarded, expressed in OMNIA.
     * @return uint256
     *         exact amount of custom token to be rewarded, expressed in OMNIA.
     */
    function _calculateManualClaimRewardTokensOf(
        address rewardee_,
        uint256 rewards_
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (areManualClaimRewardTokensPercentageSet(rewardee_)) {
            ManualClaimTokenConfig
                memory rewardTokenConfig = _manualClaimTokenConfig[rewardee_];

            return (
                (rewards_ * rewardTokenConfig.omnia) / 100,
                (rewards_ * rewardTokenConfig.stable) / 100,
                (rewards_ * rewardTokenConfig.custom) / 100
            );
        } else {
            return (rewards_, 0, 0);
        }
    }

    /**
     * @dev Checks if `rewardee_` has customised their manual claim rewards to earn some
     *      stablecoin and/or custom token or not.
     *
     * @param rewardee_ user address.
     * @return bool
     *         whether `rewardee_` has configured their manual claim rewards or not.
     */
    function areManualClaimRewardTokensPercentageSet(address rewardee_)
        public
        view
        returns (bool)
    {
        ManualClaimTokenConfig
            memory _rewardTokenConfig = _manualClaimTokenConfig[rewardee_];

        uint16 _totalPercentage = _rewardTokenConfig.omnia +
            _rewardTokenConfig.stable +
            _rewardTokenConfig.custom;

        return _totalPercentage == 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CustomRewardTokenWhitelist.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Let an address configure their custom token they want to be rewarded in.
 *      The token should be whitelisted, {CustomRewardTokenWhitelist}.
 */
abstract contract CustomRewardTokenConfig is CustomRewardTokenWhitelist {
    mapping(address => address) private _customRewardToken;

    event CustomRewardTokenSet(address indexed rewardee, address indexed token);

    /**
     * @dev Sets a custom rewarding token, if it is whitelisted, for `_msgSender()`.
     *
     * @param token_ custom rewarding token address.
     *
     * Requirement:
     * - `token_` must have been whitelisted by the owner.
     *
     * Emits a {CustomRewardTokenSet} event.
     */
    function setCustomToken(address token_) external {
        require(customRewardTokenExists(token_), "Token not whitelisted");
        _customRewardToken[_msgSender()] = token_;

        emit CustomRewardTokenSet(_msgSender(), token_);
    }

    /**
     * @param rewardee_ account address whose custom token must be queried.
     *
     * @return address
     *         returns custom rewarding token address set by `rewardee_`.
     */
    function customRewardToken(address rewardee_)
        public
        view
        returns (address)
    {
        return _customRewardToken[rewardee_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../Token/imported/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 *
 * @dev Allows the Rewards contract owner to update the stablecoin used as rewards
 *      in both auto & manual claim.
 */
abstract contract StableTokenRewardManager is Ownable, Initializable {
    ERC20 private _rToken;
    address private _rewardStableToken; // USDT by default

    // Stablecoin update
    event StablecoinUpdated(address old_, address new_);

    /**
     * @dev Initialise OMNIA address as reward token, `_rToken` and `_rewardStableToken` as USDT.
     */
    function _initializeStableTokenRewardManager(ERC20 rToken_)
        internal
        initializer
    {
        _rToken = rToken_;
        _rewardStableToken = 0x55d398326f99059fF775485246999027B3197955;
    }

    /**
     * @return address
     *         stablecoin token used for auto & manual claim rewards.
     */
    function rewardStableToken() public view returns (address) {
        return _rewardStableToken;
    }

    /**
     * @dev Sets address of the stablecoin used as rewards in both auto & manual claim.
     *
     * @param token_ address of stable token
     *
     * Requirements:
     * - `token_` cant be address(0x0)
     * - `token_` cant be OMNIA address
     * - `token_` cant be the current `_rewardStableToken`
     *
     * Emits a {StablecoinUpdated} event.
     */
    function setRewardStableToken(address token_) external onlyOwner {
        require(token_ != address(0x0), "addr(0)");
        require(token_ != address(_rToken), "OMNIA addr");
        require(token_ != _rewardStableToken, "Already set");

        emit StablecoinUpdated(_rewardStableToken, token_);
        _rewardStableToken = token_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface to be used inside {Rewards.CumulativeRewardCalculator._calculateOMNIAReward(...)}
 */
interface IOMNIA {
    function totalFeesPooledForRewards() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../Token/imported/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Create a whitelist of custom tokens that users can be rewarded in during manual claim.
 */
abstract contract CustomRewardTokenWhitelist is Ownable, Initializable {
    ERC20 private _rToken;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _customRewardTokensList;

    // Coins approvals
    event CustomTokenAdded(address indexed token);
    event CustomTokenRemoved(address indexed token);
    event CustomTokensAdded(address[] indexed token);
    event CustomTokensRemoved(address[] indexed token);

    /**
     * @dev Initialise OMNIA address as reward token, `_rToken`.
     */
    function _initializeCustomRewardTokenWhitelist(ERC20 rToken_)
        internal
        initializer
    {
        _rToken = rToken_;
    }

    /**
     * @param token_ address of token to be checked through custom token whitelist
     * @return bool
     *         whether `token_` does exist or not in custom token whitelist.
     */
    function customRewardTokenExists(address token_)
        public
        view
        returns (bool)
    {
        return _customRewardTokensList.contains(token_);
    }

    /**
     * @return bytes32[] memory
     *         all tokens whitelisted as custom reward tokens
     */
    function getCustomRewardTokens() external view returns (bytes32[] memory) {
        return _customRewardTokensList._inner._values;
    }

    /**
     * @dev Adds a specified token address to the custom reward token whitelist, if does not already exist.
     *
     * @param token_ address of token must be added to the custom reward token whitelist.
     *
     * Requirements:
     * - `token_` cant be address(0x0)
     * - `token_` cant be OMNIA address
     * - `token_` cant already be whitelisted
     */
    function addCustomRewardToken(address token_) public onlyOwner {
        require(token_ != address(0x0), "addr(0)");
        require(token_ != address(_rToken), "OMNIA addr");
        _addCustomRewardToken(token_);
    }

    /**
     * @dev Removes an existing token from custom reward token whitelist.
     *
     * @param token_ address of token that must be removed from the token whitelist.
     *
     * Requirements:
     * - `token_` cant be address(0x0)
     * - `token_` cant be OMNIA address
     * - `token_` must exists in the whitelist
     *
     * Emits a {CustomTokensRemoved} event.
     */
    function removeCustomRewardToken(address token_) external onlyOwner {
        require(token_ != address(0x0), "addr(0)");
        require(token_ != address(_rToken), "OMNIA addr");
        require(_customRewardTokensList.remove(token_), "Nonexistent");
        emit CustomTokenRemoved(token_);
    }

    /**
     * @dev Batches addings of custom reward tokens into the whitelist.
     *
     * @param tokens_ array of tokens to be added to custom reward token whitelist.
     *
     * Requirements:
     * - not a single address from `tokens_` can be address(0x0)
     * - not a single address from `tokens_` can be OMNIA address
     * - not a single address from `tokens_` can already be whitelisted
     *
     * Emits a {CustomTokensAdded} event.
     */
    function addBatchCustomRewardTokens(address[] memory tokens_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens_.length; i++) {
            require(tokens_[i] != address(0x0), "addr(0)");
            require(tokens_[i] != address(_rToken), "OMNIA addr");
            if (_customRewardTokensList.contains(tokens_[i]))
                revert("Duplicate(s)");
        }

        for (uint256 i = 0; i < tokens_.length; i++)
            _customRewardTokensList.add(tokens_[i]);

        emit CustomTokensAdded(tokens_);
    }

    /**
     * @dev Batches removals of custom reward tokens from the whitelist.
     *
     * @param tokens_ array of tokens to be removed from custom reward token whitelist.
     *
     * Requirements:
     * - not a single address from `tokens_` can be address(0x0)
     * - not a single address from `tokens_` can be OMNIA address
     * - all addresses from `tokens_` must exist int whitelist
     *
     * Emits a {CustomTokensRemoved} event.
     */
    function removeBatchCustomRewardTokens(address[] memory tokens_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens_.length; i++) {
            require(tokens_[i] != address(0x0), "addr(0)");
            require(tokens_[i] != address(_rToken), "OMNIA addr");
            if (!_customRewardTokensList.contains(tokens_[i]))
                revert("Nonexistant");
        }

        for (uint256 i = 0; i < tokens_.length; i++) {
            require(tokens_[i] != address(0x0), "addr(0)");
            require(tokens_[i] != address(_rToken), "OMNIA addr");
            _customRewardTokensList.remove(tokens_[i]);
        }
        emit CustomTokensRemoved(tokens_);
    }

    /**
     * @notice only addings have an internal functions because it is used in {Rewards.initialize()}.
     * @dev Adds a token address into the custom token whitelist.
     *
     * Emits a {CustomTokenAdded} event.
     */
    function _addCustomRewardToken(address token_) internal {
        require(_customRewardTokensList.add(token_), "Duplicate");
        emit CustomTokenAdded(token_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IPancakeRouter02.sol";

/**
 * @dev Interface to be used in {BEP20Swap}, {SwapManager} and {SwapToBNB}.
 */
interface IRouterManager {
    function initialize(
        address omnia_,
        address router_,
        address rewards_
    ) external;

    function updateRewardsContract(address rewards_) external;

    /**
     * @dev Given PancakeSwapRouter address will create OMNIA-WBNB LP and
     *      and update `pancakeswapV2Router()` and `pancakeswapV2Router()`
     *      returns.
     *
     *      👉 On updates after deployment 🚨
     *      ⚠⚠ DONT FORGET to EXCLUDE new PAIR AND ROUTER manually ⚠⚠
     *
     * @param routerAddress new address of PancakeSwapRouter to use.
     */
    function setPancakeSwapRouter(address routerAddress) external;

    /**
     * @return IPancakeRouter02
     *         interface of PancakeSWapRouter contract.
     */
    function pancakeswapV2Router() external view returns (IPancakeRouter02);

    /**
     * @return IUniswapV2Pair
     *         interface of OMNIA-BNB LP contract.
     */
    function pancakeswapV2Pair() external view returns (IUniswapV2Pair);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is selling or not.
     */
    function isSelling(address sender_, address recipient_)
        external
        view
        returns (bool);

    /**
     * @return bool
     *         is `account_` nor PCS router nor pair.
     */
    function isNotRouterNorPair(address account_) external view returns (bool);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is the transfer not sell nor a purchase.
     */
    function isNotSellingAndNotPurchasing(address sender_, address recipient_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface to be used in {BEP20Swap} and {SwapToBNB}.
 */
interface ISwapManager {
    /**
     * @dev Calculates the exact amount to be received after slippage has been applied.
     *
     * @param amount amount of some token to be swapped
     * @return uint256
     *         amount after slippage has been applied.
     */
    function calculateSplippageOn(uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @notice Swaps OMNIA for BNB, using `_pancakeswapV2Router.WETH()` as `bep20Token_`.
     * @dev Gets the path to swap OMNIA to chosen token & calculates maximum
     *      amount to receive in selected token.
     *
     * @param bep20Token_ coin to swap from OMNIA.
     * @param omniaAmount_ amount of OMNIA to swap into `bep20Token_`.
     *
     * @return maxOut
     *         maximum amount of `bep20Token_` to be received.
     * @return path
     *         path for OMNIA > `bep20Token_` swap.
     *
     */
    function pathAndMaxOut(
        address omnia,
        address bep20Token_,
        uint256 omniaAmount_
    ) external view returns (uint256 maxOut, address[] memory path);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../rewards/CumulativeRewardsCalculator.sol";
import "../swaps/BEP20Swap.sol";

/**
 * @notice Abstract contract, part of Rewards contract.
 * @dev Claim dedicated portion of rewards from given address.
 */
abstract contract ClaimCoins is CumulativeRewardsCalculator, BEP20Swap {
    /**
     * @dev Calls {_claimCustomToken} to claim custom rewards for `user`.
     *
     *      If custom token rewards claiming failed, it will claim rewards as ONMIA.
     *
     * @param user rewards' beneficiary.
     * @param omniaAmount amount of OMNIA to be claimed by `user`.
     * @param stablecoinInOmnia amount of `rewardStableToken()`, expressed in OMNIA, to be claimed by `user`.
     * @param customInOmnia amount of custom token, expressed in OMNIA, to be claimed by `user`.
     *
     */
    function _claimTokens(
        address user,
        uint256 omniaAmount,
        uint256 stablecoinInOmnia,
        uint256 customInOmnia
    )
        internal
        returns (
            bool rewardSuccess,
            bool omniaPaid,
            uint256 rewardsPaidAsOmnia,
            uint256 rewardsPaidAsCustomTokens
        )
    {
        rewardsPaidAsCustomTokens = 0;

        (
            ,
            uint256 omniaPaidAsStablecoin,
            uint256 _omniaToBePaidForStablecoin
        ) = _claimCustomToken(user, rewardStableToken(), stablecoinInOmnia);
        rewardsPaidAsCustomTokens += omniaPaidAsStablecoin;

        (
            ,
            uint256 omniaPaidAsCustomToken,
            uint256 _omniaToBePaidForCustomToken
        ) = _claimCustomToken(user, customRewardToken(user), customInOmnia);
        rewardsPaidAsCustomTokens += omniaPaidAsCustomToken;

        // Calculates how much OMNIA will be claimed when it couldn't pay the user in `rewardStableToken()`
        // and/or custom token
        omniaAmount += (_omniaToBePaidForStablecoin +
            _omniaToBePaidForCustomToken);

        rewardSuccess = true;
        omniaPaid = false;
        if (omniaAmount > 0) {
            try omnia.transfer(user, omniaAmount) returns (bool success) {
                rewardSuccess = success;
                rewardsPaidAsOmnia = rewardSuccess ? omniaAmount : 0;
                omniaPaid = rewardSuccess;
            } catch {
                rewardSuccess = false;
                rewardsPaidAsOmnia = 0;
                omniaPaid = false;
            }
        }
        // If all rewards failed to be claimed
        rewardsPaidAsCustomTokens = !rewardSuccess
            ? 0
            : rewardsPaidAsCustomTokens;

        // If OMNIA has been sent as rewards we add how much has been claimed in OMNIA
        // otherwise not
        uint256 totalRewardPaidInOmnia = omniaPaid
            ? rewardsPaidAsCustomTokens + omniaAmount
            : rewardsPaidAsCustomTokens;
        /// Update {_rewardsOf[`user`]} & {totalRewardsPaidInOMNIA}, see {CumulativeRewardsCalculator._updateRewardsPaid}.
        _updateRewardsPaid(user, totalRewardPaidInOmnia);
    }

    /**
     * @dev Swaps OMNIA into `token_` to `rewardee_`. If it can not claim rewards
     *      in `token_` it will claim it in OMNIA.
     *
     *      `token_` address must be set &  `rewards_` > 0 to swap OMNIA into `token_`.
     *
     * @param rewardee_ address that will receive rewards.
     * @param token_ token to pay rewards in.
     * @param rewards_ amount of OMNIA to swap into `token_`.
     *
     * @return _paid bool
     *         whether `rewardee_` has received rewards in `token_` or not.
     *
     * @return _omniaPaidAsToken uint256
     *         how many OMNIA have been swaped to `token_` and sent to `rewardee_`
     *         as reflection rewards.
     *
     * @return _omniaToBePaid uint256
     *         how many OMNIA must be sent to `rewardee_` as rewarding in `token_` failed.
     */
    function _claimCustomToken(
        address rewardee_,
        address token_,
        uint256 rewards_
    )
        internal
        returns (
            bool _paid,
            uint256 _omniaPaidAsToken,
            uint256 _omniaToBePaid
        )
    {
        _paid = false;
        _omniaPaidAsToken = 0;
        _omniaToBePaid = 0;

        /// Does not pay any reward, when token is address(0) or amount of rewards is 0.
        if (token_ == address(0) || rewards_ == 0) {}
        /// If `token_` is OMNIA token, claim `rewards_` amount as OMNIA later.
        else if (token_ == address(omnia)) {
            _omniaToBePaid = rewards_;
        } else {
            /// If claiming `rewards_` in `token_` was successful
            if (_claimBEP20(token_, rewardee_, rewards_)) {
                _paid = true;
                _omniaPaidAsToken = rewards_;
            }
            /// If claiming `rewards_` in `token_` failed: claim `rewards_` in OMNIA later.
            else {
                _omniaToBePaid = rewards_;
            }
        }
    }

    /**
     *
     * @dev Swaps OMNIA into `bep20Token`, from this Rewards contract to `user`.
     *
     * @param bep20Token token to swap to from OMNIA
     * @param user address that is claiming and receiving rewards
     * @param omniaAmount amount of OMNIA to swap into `bep20Token`
     *
     * @return bool
     *         whether the swap to `bep20Token` was successful or not.
     *
     *  Requirements:
     * - `omniaAmount` cant be 0.
     */
    function _claimBEP20(
        address bep20Token,
        address user,
        uint256 omniaAmount
    ) internal returns (bool) {
        if (omniaAmount == 0) revert("cant swap: 0 amount");

        return _swapOMNIAForBEP20(bep20Token, omniaAmount, user);
    }
}