// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../Role/PoolCreator.sol";
import "./StakingPool.sol";
import "./RewardManager.sol";
import "../Distribution/USDRetriever.sol";

contract StakingPoolFactory is PoolCreator {
    TotemToken public immutable totemToken;
    RewardManager public immutable rewardManager;
    address public swapRouter;
    address public oracleContract;
    // TODO: we can add a mechanism to predict price of other top market coins 
    // like ETH, so it would be better not to use immutable addresses.
    address immutable usdToken;
    address immutable btcToken;
    uint256 public stakingPoolTaxRate;
    uint256 public minimumStakeAmount;

    event PoolCreated(
        address indexed pool,
        uint256 maturityTime,
        uint256 lockTime,
        uint256 sizeAllocation,
        uint256 stakeApr,
        uint256 prizeAmount,
        uint256 usdPrizeAmount,
        uint256 potentialCollabReward,
        uint256 stakingPoolTaxRate,
        uint256 minimumStakeAmount,
        bool isEnhancedEnabled
    );

    constructor(
        TotemToken _totemToken,
        RewardManager _rewardManager,
        address _oracleContract,
        address _swapRouter,
        address _usdToken,
        address _btcToken
    ) {
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        oracleContract = _oracleContract;
        swapRouter = _swapRouter;
        usdToken = _usdToken;
        btcToken = _btcToken;
        
        stakingPoolTaxRate = 300;

        // minimum amount of totem can be staked is 0.001 TOTM,
        // it's a mechanism to prevent DDOS attack
        minimumStakeAmount = 10**15;
    }

    function create(
        uint256 maturityTime,
        uint256 lockTime,
        uint256 sizeAllocation,
        uint256 stakeApr,
        uint256 prizeAmount,
        uint256 usdPrizeAmount,
        uint256 potentialCollabReward,
        bool isEnhancedEnabled
    ) external onlyPoolCreator returns (address) {

        // TODO: should the stakeApr and potential collab reward be checked?
        uint256[9] memory variables =
            [
                maturityTime,
                lockTime,
                sizeAllocation,
                stakeApr,
                prizeAmount,
                usdPrizeAmount,
                potentialCollabReward,
                stakingPoolTaxRate,
                minimumStakeAmount
            ];

        address newPool =
            address(
                new StakingPool(
                    totemToken,
                    rewardManager,
                    // TODO: we should use everywhere _msgSender or msg.sender
                    msg.sender,
                    swapRouter,
                    oracleContract,
                    usdToken,
                    btcToken,
                    variables,
                    isEnhancedEnabled
                )
            );

        emit PoolCreated(
            newPool,
            maturityTime,
            lockTime,
            sizeAllocation,
            stakeApr,
            prizeAmount,
            usdPrizeAmount,
            potentialCollabReward,
            stakingPoolTaxRate,
            minimumStakeAmount,
            isEnhancedEnabled
        );

        rewardManager.addPool(newPool);

        return newPool;
    }

    function setOracleContract(address _oracleContract)
        external
        onlyPoolCreator
    {
        require(_oracleContract != address(0));
        oracleContract = _oracleContract;
    }

    function setSwapRouter(address _swapRouter) external onlyPoolCreator {
        require(_swapRouter != address(0));
        swapRouter = _swapRouter;
    }

    function setTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "Tax connot be over 100% (10000 BP)"
        );
        stakingPoolTaxRate = newStakingPoolTaxRate;
    }

    function setMinimuntToStake(uint256 newMinimumStakeAmount)
        external
        onlyPoolCreator
    {
        // TODO: any condition can be applied to check the minimum amount
        minimumStakeAmount = newMinimumStakeAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Roles.sol";

contract PoolCreator is Context {
    using Roles for Roles.Role;

    event PoolCreatorAdded(address indexed account);
    event PoolCreatorRemoved(address indexed account);

    Roles.Role private _poolCreators;

    constructor() {
        if (!isPoolCreator(_msgSender())) {
            _addPoolCreator(_msgSender());
        }
    }

    modifier onlyPoolCreator() {
        require(
            isPoolCreator(_msgSender()),
            "PoolCreatorRole: caller does not have the PoolCreator role"
        );
        _;
    }

    function isPoolCreator(address account) public view returns (bool) {
        return _poolCreators.has(account);
    }

    function addPoolCreator(address account) public onlyPoolCreator {
        _addPoolCreator(account);
    }

    function renouncePoolCreator() public {
        _removePoolCreator(_msgSender());
    }

    function _addPoolCreator(address account) internal {
        _poolCreators.add(account);
        emit PoolCreatorAdded(account);
    }

    function _removePoolCreator(address account) internal {
        _poolCreators.remove(account);
        emit PoolCreatorRemoved(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../Price/PriceConsumer.sol";
import "../Distribution/BTCDistributor.sol";
import "../Distribution/USDRetriever.sol";
import "./RewardManager.sol";

contract StakingPool is
    Context,
    Ownable,
    PriceConsumer,
    USDRetriever,
    BTCDistributor
{
    using BasisPoints for uint256;
    using SafeMath for uint256;

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction;
        uint256 difference;
        uint256 rank;
        bool prizeRewardWithdrawn;
        bool didUnstake;
    }

    struct Staker {
        address stakerAddress;
        uint256 index;
    }

    struct PrizeRewardRate {
        uint256 rank;
        uint256 percentage;
    }

    TotemToken public immutable totemToken;
    RewardManager public immutable rewardManager;
    IERC20 public immutable btcToken;

    uint256 public immutable startDate;
    uint256 public immutable lockTime;
    uint256 public immutable maturityTime;

    uint256 public immutable sizeAllocation;
    uint256 public immutable stakeApr;

    uint256 public immutable prizeAmount;

    // usdPrizeAmount is the enabler of BTC rewarder if it would be 0 then the pool is only TOTM rewarder
    uint256 public immutable usdPrizeAmount;

    uint256 public immutable stakeTaxRate;
    uint256 public immutable minimumStakeAmount;

    mapping(address => StakeWithPrediction[]) public predictions;
    Staker[] public stakers;
    uint256 public totalStaked;

    // TODO: the maturing price is not the real maturity price and it depends on
    // the calling endPool function
    uint256 public maturingPrice;
    uint256 public constant sizeLimitRangeRate = 5;
    // TODO: implement a mechanism to get the decimals from the oracle
    uint256 public constant oracleDecimal = 8;

    uint256 public immutable potentialCollabReward;
    // based on the white paper the collaborative reward can be 20% (2000), 25% (2500) or 35% (3500)
    uint256 public collaborativeReward;

    address public poolCreator;

    bool public immutable isEnhancedEnabled;
    bool public isLocked;
    bool public isMatured;

    PrizeRewardRate[] public prizeRewardRates;

    event Stake(address indexed user, uint256 amount, uint256 pricePrediction);

    event Withdraw(address indexed user, uint256 amount, uint256 btcAmount);

    event Unstake(address indexed user, uint256 amount);

    event PoolLocked();

    event PoolMatured();

    constructor(
        TotemToken _totemToken,
        RewardManager _rewardManager,
        address _poolCreator,
        address _swapRouter,
        address _oracleContract,
        address _usdToken,
        address _btcToken,
        uint256[9] memory _variables,
        bool _isEnhancedEnabled
    )
        PriceConsumer(_oracleContract)
        BTCDistributor(_swapRouter, _usdToken, _btcToken)
    {
        totemToken = _totemToken;
        rewardManager = _rewardManager;

        poolCreator = _poolCreator;

        setUSDToken(_usdToken);
        btcToken = IERC20(_btcToken);

        startDate = block.timestamp;
        maturityTime = _variables[0];
        lockTime = _variables[1];

        sizeAllocation = _variables[2];
        stakeApr = _variables[3];
        prizeAmount = _variables[4];
        usdPrizeAmount = _variables[5];
        potentialCollabReward = _variables[6];
        stakeTaxRate = _variables[7];
        minimumStakeAmount = _variables[8];   

        isEnhancedEnabled = _isEnhancedEnabled; 

        // TODO: these reward-rates should be set in the factory to be able to change
        prizeRewardRates.push(PrizeRewardRate({rank: 1, percentage: 3750}));
        prizeRewardRates.push(PrizeRewardRate({rank: 2, percentage: 2000}));
        prizeRewardRates.push(PrizeRewardRate({rank: 3, percentage: 1000}));
        prizeRewardRates.push(PrizeRewardRate({rank: 10, percentage: 250}));
        prizeRewardRates.push(PrizeRewardRate({rank: 25, percentage: 100}));
    }

    function stake(uint256 _amount, uint256 _pricePrediction) external {
        require(!isLocked, "Pool is locked");
        require(_amount >= minimumStakeAmount, "Amount can't be less than the minimum");

        uint256 limitRange = sizeAllocation.mul(sizeLimitRangeRate).div(100);
        uint256 stakeTaxAmount;
        uint256 taxRate = totemToken.taxRate();
        uint256 tax =
            totemToken.taxExempt(_msgSender()) ? 0 : _amount.mulBP(taxRate);
    
        require(
            // the total amount of stakes can exceed size allocation by 5%
            totalStaked.add(_amount).sub(tax) <= sizeAllocation.add(limitRange),
            "Can't stake above size allocation"
        );

        // now the stakeTaxAmount is the staking tax and the _amount is initial amount minus the staking tax
        (stakeTaxAmount, _amount) = getStakingTax(_amount, taxRate);

        totemToken.transferFrom(
            _msgSender(),
            address(this),
            (_amount + stakeTaxAmount)
        );

        // This is to remove token tax (not staking tax) from the amount
        _amount = _amount.sub(tax);

        if (stakeTaxAmount > 0)
            totemToken.transfer(totemToken.taxationWallet(), stakeTaxAmount);

        totalStaked = totalStaked.add(_amount);

        stakers.push(
            Staker({
                stakerAddress: _msgSender(),
                index: predictions[_msgSender()].length
            })
        );

        predictions[_msgSender()].push(
            StakeWithPrediction({
                stakedBalance: _amount,
                stakedTime: block.timestamp,
                amountWithdrawn: 0,
                lastWithdrawalTime: block.timestamp,
                pricePrediction: _pricePrediction,
                // maybe it's better to use the max number available for rank and differece
                // because the 0 is the best number
                difference: type(uint256).max,
                rank: type(uint256).max,
                prizeRewardWithdrawn: false,
                didUnstake: false
            })
        );

        // TODO: Why .sub is used in the next condition
        if (totalStaked >= sizeAllocation.sub(limitRange)) {
            // if the staking pool has not anymore capacity then it is locked
            _lockPool();
        }

        emit Stake(_msgSender(), _amount, _pricePrediction);
    }

    function claimReward() external {
        (uint256 reward, uint256 btcReward) = _getTotalReward(_msgSender());

        if (reward > 0) {
            if (totemToken.balanceOf(address(rewardManager)) >= reward) {
                // all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), reward);
            }
        }
        
        // _wthdraw don't withdraw actually, and only update the array in the map
        _withdrawStakingReward(_msgSender());
        

        if (isMatured) {

            if (usdPrizeAmount > 0) {
                if (btcReward > 0) require(btcToken.transfer(_msgSender(), btcReward));

                // _wthdraw don't withdraw actually, and only update the array in the map
                _withdrawPrizeReward(_msgSender());
            }

            // Users can't unstake until the pool matures
            uint256 stakedBalance = _getTotalStakedBalance(_msgSender());
            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                // _wthdraw don't withdraw actually, and only update the array in the map
                _withdrawStakedBalance(_msgSender());

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit Withdraw(_msgSender(), reward, btcReward);
    }

    function indexedClaimReward(uint256 stakeIndex) external {
        (uint256 reward, uint256 btcReward) = _getIndexedReward(_msgSender(), stakeIndex);

        if (reward > 0) {
            // Send the token reward only when the rewardManager has the enough fund
            if (totemToken.balanceOf(address(rewardManager)) >= reward) {
                rewardManager.rewardUser(_msgSender(), reward);
            }
        }
        
        _withdrawIndexedStakingReward(_msgSender(), stakeIndex);
        

        if (isMatured) {
            
            if (usdPrizeAmount > 0) {
                // TODO: the staking pool should have ehough BTC token to run the following line of code
                // test to see what goes on if there won't be enough BTC
                if (btcReward > 0) require(btcToken.transfer(_msgSender(), btcReward));

                _withdrawIndexedPrizeReward(_msgSender(), stakeIndex);
            }


            uint256 stakedBalance = _getIndexedStakedBalance(_msgSender(), stakeIndex);
            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                _withdrawIndexedStakedBalance(_msgSender(), stakeIndex);

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit Withdraw(_msgSender(), reward, btcReward);
    }

    function purchaseBTC(uint256 usdAmount, uint256 deadline)
        external
        onlyPoolCreator
    {
        require(usdPrizeAmount > 0, "The pool is not BTC rewarder");
        
        // TODO: add another require to check the pool has wnough usd or not
        require(usdAmount > 0, "Amount can't be zero");

        require(deadline >= block.timestamp);

        // This approves tokens to swap router
        address swapRouterAddress = getswapRouter();
        approveTokens(swapRouterAddress, usdAmount);
        // Get equivalent USD amount for BTC
        uint256 btcAmount = getEstimatedBTCForUSD(usdAmount);

        uint256 btcAmountWithSlippage =
            btcAmount.sub(btcAmount.mulBP(300));

        transferTokensThroughSwap(
            address(this),
            usdAmount,
            btcAmountWithSlippage,
            deadline
        );
    }

    function getBTCBalance() public view returns (uint256) {
        return btcToken.balanceOf(address(this));
    }

    function getPredictionRange(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        uint256[4] memory steps =
            [uint256(27500), 30000, 17500, type(uint256).max];
        uint256[4] memory ranges = [uint256(1000), 700, 375, 200];
        uint256 totalRange = 0;

        for (uint256 i = 0; i < steps.length; i++) {
            uint256 stepAmount =
                i == steps.length - 1 ? amount : steps[i].mul(10**18);
            uint256 step = amount > stepAmount ? stepAmount : amount;
            totalRange = totalRange.add(
                // the use of oracleDecimal -2 is because of ranges element (100 = 1 dollar range)
                step.mul(ranges[i]).mul(10**(oracleDecimal-2)).div(500).div(10**18)
            );

            if (amount <= stepAmount) break;

            amount = amount.sub(stepAmount);
        }
        return totalRange;
    }

    // This function is to get the avg price prediction for calculating collaborative reward
    function getAveragePricePrediction() public view returns (uint256) {
        if (totalStaked == 0) return 0;
        uint256 avgPricePrediction = 0;

        for (uint256 i = 0; i < stakers.length; i++) {
            StakeWithPrediction memory prediction =
                predictions[stakers[i].stakerAddress][stakers[i].index];

            avgPricePrediction = avgPricePrediction.add(
                prediction.pricePrediction.mul(prediction.stakedBalance)
            );
        }

        avgPricePrediction = avgPricePrediction.div(totalStaked);

        return avgPricePrediction;
    }

    function lockPool() public onlyPoolCreator {
        _lockPool();
    }

    function _lockPool() internal {
        isLocked = true;

        emit PoolLocked();
    }

    function endPool() external onlyPoolCreator {
        
        if (usdPrizeAmount > 0) {
            require(getBTCBalance() != 0, "BTC Rewards not available");
        }
        
        require(
            block.timestamp >= startDate + lockTime + maturityTime,
            "Can't end pool before the maturity time"
        );

        maturingPrice = getLatestPrice();

        for (uint256 i = 0; i < stakers.length; i++) {
            // when the storage is used to get another storage variable, by changing the 
            // latter storage variable the old underlying storage variable is also changed
            StakeWithPrediction storage prediction =
                predictions[stakers[i].stakerAddress][stakers[i].index];
            uint256 range = getPredictionRange(prediction.stakedBalance);

            prediction.difference = _getDifference(
                prediction.pricePrediction,
                range
            );
        }

        // potentialCollabReward allows the admin to set the collaborateive reward 
        if (potentialCollabReward > 0) {
            // the collaborative reward only gave to the pools that the average price predicted with 
            // the accuracy of 25 $
            uint256 avgPricePrediction = getAveragePricePrediction();
            if (_getDifference(avgPricePrediction, 25 * (10**8)) == 0) {
                collaborativeReward = potentialCollabReward;
            }
        }

        _sortStakers();
        uint256 max = stakers.length > 25 ? 25 : stakers.length;
        for (uint256 i = 0; i < max; i++) {
            predictions[stakers[i].stakerAddress][stakers[i].index].rank =
                i +
                1;
        }

        // there is possibility that the size allocation is not reached 
        // and the isLocked is not set to ture
        isLocked = true;
        isMatured = true;

        emit PoolMatured();
    }

    function _getDifference(uint256 prediction, uint256 range)
        internal
        view
        returns (uint256)
    {
        if (prediction > maturingPrice) {
            if (prediction.sub(range) <= maturingPrice) return 0;
            else return prediction.sub(range).sub(maturingPrice);
        } else {
            if (prediction.add(range) >= maturingPrice) return 0;
            else return maturingPrice.sub(prediction.add(range));
        }
    }

    // TODO: test this function in several scenarios
    function _sortStakers() internal {
        uint256 stakersLength = stakers.length;

        for (uint256 i = 1; i < stakersLength; i++) {
            Staker memory _staker = stakers[i];

            uint256 j = i - 1;

            while (
                (int256(j) >= 0) &&
                (predictions[stakers[j].stakerAddress][stakers[j].index]
                    .difference >
                    predictions[_staker.stakerAddress][_staker.index]
                        .difference)
            ) {
                stakers[j + 1] = stakers[j];
                j--;
            }
            stakers[j + 1] = _staker;
        }
    }

    function _getStakingRewardPerStake(address staker, uint256 stakeIndex)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction memory userStake = predictions[staker][stakeIndex];
        uint256 maturityDate = startDate + lockTime + maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;

        uint256 enhancedApr = _getEnhancedRewardRate(userStake.stakedTime);

        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance

        uint256 rewardPerStake = _calcStakingReturn(
            stakeApr.add(enhancedApr),
            timeTo.sub(userStake.stakedTime),
            userStake.stakedBalance
            );

        rewardPerStake = rewardPerStake.sub(userStake.amountWithdrawn);

        return rewardPerStake;
    }

    function _calcStakingReturn(uint256 totalRewardRate, uint256 timeDuration, uint256 totalStakedBalance) 
        internal 
        pure
        returns (uint256) 
    {
        uint256 yearInSeconds = 365 days;

        uint256 first = (yearInSeconds**2)
            .mul(10**8);

        uint256 second = timeDuration
            .mul(totalRewardRate) 
            .mul(yearInSeconds)
            .mul(5000);
        
        uint256 third = totalRewardRate
            .mul(yearInSeconds**2)
            .mul(5000);

        uint256 forth = (timeDuration**2)
            .mul(totalRewardRate**2)
            .div(6);

        uint256 fifth = timeDuration
            .mul(totalRewardRate**2)
            .mul(yearInSeconds)
            .div(2);

        uint256 sixth = (totalRewardRate**2)
            .mul(yearInSeconds**2)
            .div(3);
 
        uint256 rewardPerStake = first.add(second).add(forth).add(sixth);

        rewardPerStake = rewardPerStake.sub(third).sub(fifth);

        rewardPerStake = rewardPerStake
            .mul(totalRewardRate)
            .mul(timeDuration);

        rewardPerStake = rewardPerStake
            .mul(totalStakedBalance)
            .div(yearInSeconds**3)
            .div(10**12);

        return rewardPerStake; 
    }

    // TODO: this function and the following one should be optimized
    function _getStakingReward(address staker) public view returns (uint256) {
        StakeWithPrediction[] memory userStakes = predictions[staker];
        if (userStakes.length == 0) return 0;

        uint256 reward = 0;
        for (uint256 i = 0; i < userStakes.length; i++) {
            uint256 rewardPerStake = _getStakingRewardPerStake(staker, i);

            reward = reward.add(rewardPerStake);
        }

        return reward;
    }

    function _getIndexedStakingReward(address staker, uint256 stakeIndex) public view returns (uint256) {
        StakeWithPrediction[] memory userStakes = predictions[staker];
        if (userStakes.length == 0) return 0;
        if (stakeIndex >= userStakes.length) return 0;

        uint256 reward = 0;
        
        uint256 rewardPerStake = _getStakingRewardPerStake(staker, stakeIndex);
        reward = reward.add(rewardPerStake);

        return reward;
    }

    // TODO: this function and the following one should be optimized
    function _withdrawStakingReward(address staker) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;

        for (uint256 i = 0; i < userStakes.length; i++) {
            uint256 rewardPerStake = _getStakingRewardPerStake(staker, i);

            userStakes[i].lastWithdrawalTime = block.timestamp;
            userStakes[i].amountWithdrawn = userStakes[i].amountWithdrawn.add(
                rewardPerStake
            );
        }
    }

    function _withdrawIndexedStakingReward(address staker, uint256 stakeIndex) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;
        if (stakeIndex >= userStakes.length) return;

        uint256 rewardPerStake = _getStakingRewardPerStake(staker, stakeIndex);

        userStakes[stakeIndex].lastWithdrawalTime = block.timestamp;
        userStakes[stakeIndex].amountWithdrawn = userStakes[stakeIndex].amountWithdrawn.add(
            rewardPerStake
        );
    }

    function _getEnhancedRewardRate(uint256 stakedTime)
        internal
        view
        returns (uint256)
    {

        // if the enhanced reward is not enabled so consider enhanced raward 0
        if (!isEnhancedEnabled) {
            return 0;
        }

        uint256 lockDate = startDate.add(lockTime);
        uint256 difference = lockDate.sub(stakedTime);

        if (difference < 48 hours) {
            return 0;
        } else if (difference < 72 hours) {
            return 100;
        } else if (difference < 96 hours) {
            return 200;
        } else if (difference < 120 hours) {
            return 300;
        } else if (difference < 144 hours) {
            return 400;
        } else {
            return 500;
        }
    }

    function _getPrizeReward(address staker)
        internal
        view
        returns (uint256, uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!isMatured) return (0, 0);

        StakeWithPrediction[] memory userStakes = predictions[staker];

        // users that don't stake don't get any prize also
        if (userStakes.length == 0) return (0, 0);

        uint256 maturingBTCPrizeAmount =
            (usdPrizeAmount.mul(10**oracleDecimal)).div(maturingPrice);

        uint256 reward = 0;
        uint256 btcReward = 0;
        for (uint256 i = 0; i < userStakes.length; i++) {
            // only calculate the prize amount for stakes that are not withdrawn yet
            if (!userStakes[i].prizeRewardWithdrawn) {
                for (uint256 j = 0; j < prizeRewardRates.length; j++) {
                    // the rank variable initiated as the muximum uint unmber and only changed when its owner 
                    // predict an accurate price, so the following code should result well
                    if (userStakes[i].rank <= prizeRewardRates[j].rank) {
                        reward = reward.add(
                            prizeAmount.mul(prizeRewardRates[j].percentage).div(
                                10000
                            )
                        );
                        btcReward = btcReward.add(
                            maturingBTCPrizeAmount
                                .mul(prizeRewardRates[j].percentage)
                                .div(10000)
                        );
                        break;
                    }
                }
            }
        }

        if (collaborativeReward > 0) {
            reward = reward.addBP(collaborativeReward);
            btcReward = btcReward.addBP(collaborativeReward);
        }

        return (reward, btcReward);
    }

    function _getIndexedPrizeReward(address staker, uint256 stakeIndex)
        internal
        view
        returns (uint256, uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!isMatured) return (0, 0);

        StakeWithPrediction[] memory userStakes = predictions[staker];

        // users that don't stake don't get any prize also
        if (userStakes.length == 0) return (0, 0);

        // the prize reward considered 0 if stakeIndex exceeds
        if (stakeIndex >= userStakes.length) return (0,0);

        // If the first prize reward is withdrawn, we can assume that all the prize/collaborative rewards are withdrawn
        if (userStakes[stakeIndex].prizeRewardWithdrawn) return (0, 0);

        uint256 maturingBTCPrizeAmount =
            (usdPrizeAmount.mul(10**oracleDecimal)).div(maturingPrice);

        uint256 reward = 0;
        uint256 btcReward = 0;

        for (uint256 j = 0; j < prizeRewardRates.length; j++) {
                if (userStakes[stakeIndex].rank <= prizeRewardRates[j].rank) {
                    reward = reward.add(
                        prizeAmount.mul(prizeRewardRates[j].percentage).div(
                            10000
                        )
                    );
                    btcReward = btcReward.add(
                        maturingBTCPrizeAmount
                            .mul(prizeRewardRates[j].percentage)
                            .div(10000)
                    );
                    break;
                }
            }

        if (collaborativeReward > 0) {
            reward = reward.addBP(collaborativeReward);
            btcReward = btcReward.addBP(collaborativeReward);
        }

        return (reward, btcReward);
    }

    // TODO: this function and the following one should be optimized
    function _withdrawPrizeReward(address staker) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;

        for (uint256 i = 0; i < userStakes.length; i++) {
            userStakes[i].prizeRewardWithdrawn = true;
        }
    }

    function _withdrawIndexedPrizeReward(address staker, uint256 stakeIndex) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;
        if (userStakes[stakeIndex].prizeRewardWithdrawn) return;

        userStakes[stakeIndex].prizeRewardWithdrawn = true;
    }

    // TODO: this function and the following one should be optimized
    // getTotalStakedBalance return remained staked balance
    function _getTotalStakedBalance(address staker)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction[] memory userStakes = predictions[staker];
        if (userStakes.length == 0) return 0;

        uint256 totalStakedBalance = 0;
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (!userStakes[i].didUnstake) {
                totalStakedBalance = totalStakedBalance.add(
                    userStakes[i].stakedBalance
                );
            }
        }

        return totalStakedBalance;
    }

    // getIndexedStakedBalance return the remained staked amount
    function _getIndexedStakedBalance(address staker, uint256 stakeIndex)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction[] memory userStakes = predictions[staker];
        if (userStakes.length == 0) return 0;
        if (stakeIndex >= userStakes.length) return 0; 

        uint256 totalStakedBalance = 0;

        if (!userStakes[stakeIndex].didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                userStakes[stakeIndex].stakedBalance
            );
        }

        return totalStakedBalance;
    }

    // TODO: this function and the following one should be optimized
    function _withdrawStakedBalance(address staker) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;

        for (uint256 i = 0; i < userStakes.length; i++) {
            userStakes[i].didUnstake = true;
        }
    }

    function _withdrawIndexedStakedBalance(address staker, uint256 stakeIndex) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;
        if (stakeIndex >= userStakes.length) return;

        userStakes[stakeIndex].didUnstake = true;
    }

    function _getTotalReward(address staker)
        internal
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 prizeReward;
        uint256 btcPrizeReward;
        uint256 stakingReward = _getStakingReward(staker);
        (prizeReward, btcPrizeReward) = _getPrizeReward(staker);

        return (stakingReward.add(prizeReward), btcPrizeReward);
    }

    
    function _getIndexedReward(address staker, uint256 stakeIndex)
        internal
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 prizeReward;
        uint256 btcPrizeReward;
        uint256 stakingReward = _getIndexedStakingReward(staker, stakeIndex);
        (prizeReward, btcPrizeReward) = _getIndexedPrizeReward(staker, stakeIndex);

        return (stakingReward.add(prizeReward), btcPrizeReward);
    }

    function getStakingReward() external view returns (uint256) {
        return _getStakingReward(_msgSender());
    }
    function getIndexedStakingReward(uint256 stakeIndex) external view returns (uint256) {
        return _getIndexedStakingReward(_msgSender(), stakeIndex);
    }

    function getPrizeReward() external view returns (uint256, uint256) {
        return _getPrizeReward(_msgSender());
    }
    function getIndexedPrizeReward(uint256 stakeIndex) external view returns (uint256, uint256) {
        return _getIndexedPrizeReward(_msgSender(), stakeIndex);
    }

    function getTotalStakedBalance() external view returns (uint256) {
        return _getTotalStakedBalance(_msgSender());
    }
    function getIndexedStakedBalance(uint256 stakeIndex) external view returns (uint256) {
        return _getIndexedStakedBalance(_msgSender(), stakeIndex);
    }

    function getTotalReward() external view returns (uint256, uint256) {
        return _getTotalReward(_msgSender());
    }
    function getIndexedReward(uint256 stakeIndex) external view returns (uint256, uint256) {
        return _getIndexedReward(_msgSender(), stakeIndex);
    }

    function getStakingTax(uint256 amount, uint256 tokenTaxRate)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 newStakeTaxRate =
            stakeTaxRate > tokenTaxRate ? stakeTaxRate.sub(tokenTaxRate) : 0;
        if (newStakeTaxRate == 0) {
            return (0, amount);
        }
        return (
            amount.mulBP(newStakeTaxRate),
            amount.sub(amount.mulBP(newStakeTaxRate))
        );
    }

    // TODO: epand the functionality of this function to withdraw all locked tokens from the pool
    function releaseBTC(uint256 amount, address receiver)
        external
        onlyPoolCreator
    {
        btcToken.transfer(receiver, amount);
    }

    // TODO: by adding the indexed claim hasUnStaked won't be usefull anymore
    // hasUnStaked return true if the user staked in the pool and then has unStaked it (in claim usecase)
    function hasUnStaked(address staker, uint256 stakeIndex) external view returns (bool) {
        StakeWithPrediction[] memory userStakes = predictions[staker];

        require(
            userStakes.length > 0,
            "this address didn't stake in this pool"
        );

        require(
            stakeIndex < userStakes.length,
            "this index exceeds"
        );
    

        if (userStakes[stakeIndex].didUnstake) {
            return true;
        }
        return false;
    }

    modifier onlyPoolCreator {
        require(
            msg.sender == poolCreator,
            "PoolCreator: caller is not a pool creator"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "../TotemToken.sol";
import "../Role/Operator.sol";
import "../Role/Rewarder.sol";

contract RewardManager is Context, Ownable, Operator, Rewarder {
    TotemToken totemToken;
    address operator;

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    constructor(TotemToken _totemToken) {
        totemToken = _totemToken;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Rewards: New Operator address cannot be zero."
        );

        addOperator(_newOperator);
        emit SetOperator(_newOperator);
    }

    function addPool(address _poolAddress) public onlyOperator {
        require(
            _poolAddress != address(0),
            "Rewards: Pool address cannot be zero."
        );

        addRewarder(_poolAddress);
        emit SetRewarder(_poolAddress);
    }

    function rewardUser(address _user, uint256 _amount) public onlyRewarder {
        require(_user != address(0), "Rewards: User address cannot be zero.");

        require(totemToken.transfer(_user, _amount));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDRetriever {
    IERC20 internal USDCContract;

    event ReceivedTokens(address indexed from, uint256 amount);
    event TransferTokens(address indexed to, uint256 amount);
    event ApproveTokens(address indexed to, uint256 amount);

    function setUSDToken(address _usdContractAddress) internal {
        USDCContract = IERC20(_usdContractAddress);
    }

    function approveTokens(address _to, uint256 _amount) internal {
        USDCContract.approve(_to, _amount);
        emit ApproveTokens(_to, _amount);
    }

    function getUSDBalance() external view returns (uint256) {
        return USDCContract.balanceOf(address(this));
    }

    function getUSDToken() external view returns (address) {
        return address(USDCContract);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    /**
     * @param _oracle The chainlink node oracle address to send requests
     */
    constructor(address _oracle) {
        require(_oracle != address(0));
        priceFeed = AggregatorV3Interface(_oracle);
    }

    /**
     * Returns decimals for oracle contract
     */
    function getDecimals() external view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    /**
     * Returns the latest price from oracle contract
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return price >= 0 ? uint256(price) : 0;
    }

    // TODO: a function must be added to get the price on a specific timestamp
    // at the moment chainlink provide a function to get the price on a round ID
    // but all round IDs don't return a valid price and mapping the round IDs to
    // timestamps is not very well defined
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../PancakeSwap/IPancakeRouter.sol";

// TODO: this contract should handle other coins like ETH too
contract BTCDistributor {
    IPancakeRouter02 internal swapRouter;
    address internal USDC_CONTRACT_ADDRESS;
    address internal WBTC_CONTRACT_ADDRESS;

    event DistributedBTC(address indexed to, uint256 amount);

    constructor(
        address swapRouterAddress,
        address USDCContractAddress,
        address wBTCContractAddress
    ) {
        swapRouter = IPancakeRouter02(swapRouterAddress);
        USDC_CONTRACT_ADDRESS = USDCContractAddress;
        WBTC_CONTRACT_ADDRESS = wBTCContractAddress;
    }

    /**
     * @param _to Reciever address
     * @param _usdAmount USD Amount
     * @param _btcAmount BTC Amount
     */
    function transferTokensThroughSwap(
        address _to,
        uint256 _usdAmount,
        uint256 _btcAmount,
        uint256 _deadline
    ) internal {
        require(_to != address(0));
        // Get max USD price we can spend for this amount.
        swapRouter.swapExactTokensForTokens(
            _usdAmount,
            _btcAmount,
            getPathForUSDToBTC(),
            _to,
            _deadline
        );
    }

    /**
     * @param _amount Amount
     */
    function getEstimatedBTCForUSD(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256[] memory btcAmount =
            swapRouter.getAmountsOut(_amount, getPathForUSDToBTC());
        // since in the path the btc is the second one, so we should retuen the second one also here    
        return btcAmount[1];
    }

    function getPathForUSDToBTC() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = USDC_CONTRACT_ADDRESS;
        path[1] = WBTC_CONTRACT_ADDRESS;

        return path;
    }

    // the function should be rename to getSwapRouter
    function getswapRouter() public view returns (address) {
        return address(swapRouter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILocker.sol";
import "./BasisPoints.sol";

contract TotemToken is ILockerUser, Context, ERC20, Ownable {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    string public constant NAME = "Totem Token";
    string public constant SYMBOL = "TOTM";
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000 * (10**uint256(DECIMALS));

    address public CommunityDevelopmentAddr;
    address public StakingRewardsAddr;
    address public LiquidityPoolAddr;
    address public PublicSaleAddr;
    address public AdvisorsAddr;
    address public SeedInvestmentAddr;
    address public PrivateSaleAddr;
    address public TeamAllocationAddr;
    address public StrategicRoundAddr;

    uint256 public constant COMMUNITY_DEVELOPMENT =
        1000000 * (10**uint256(DECIMALS)); // 10% for Community development
    uint256 public constant STAKING_REWARDS = 1650000 * (10**uint256(DECIMALS)); // 16.5% for Staking Revawards
    uint256 public constant LIQUIDITY_POOL = 600000 * (10**uint256(DECIMALS)); // 6% for Liquidity pool
    uint256 public constant ADVISORS = 850000 * (10**uint256(DECIMALS)); // 8.5% for Advisors
    uint256 public constant SEED_INVESTMENT = 450000 * (10**uint256(DECIMALS)); // 4.5% for Seed investment
    uint256 public constant PRIVATE_SALE = 2000000 * (10**uint256(DECIMALS)); // 20% for Private Sale
    uint256 public constant TEAM_ALLOCATION = 1500000 * (10**uint256(DECIMALS)); // 15% for Team allocation

    uint256 public constant LAUNCH_POOL =
        5882352941 * (10**uint256(DECIMALS - 5)); // 58823.52941 for LaunchPool
    uint256 public constant PUBLIC_SALE =
        450000 * (10**uint256(DECIMALS)) + LAUNCH_POOL; // 4.5% for Public Sale
    uint256 public constant STRATEGIC_ROUND =
        1500000 * (10**uint256(DECIMALS)) - LAUNCH_POOL; // 15% for Strategic Round
    uint256 public taxRate = 300;
    address public taxationWallet;

    bool private _isDistributionComplete = false;

    mapping(address => bool) public taxExempt;

    ILocker public override locker;

    constructor() ERC20(NAME, SYMBOL) {
        taxationWallet = _msgSender();

        _mint(address(this), INITIAL_SUPPLY);
    }

    function setLocker(address _locker) external onlyOwner() {
        require(_locker != address(0), "_locker cannot be address(0)");
        locker = ILocker(_locker);
        emit SetLocker(_locker);
    }

    function setDistributionTeamsAddresses(
        address _CommunityDevelopmentAddr,
        address _StakingRewardsAddr,
        address _LiquidityPoolAddr,
        address _PublicSaleAddr,
        address _AdvisorsAddr,
        address _SeedInvestmentAddr,
        address _PrivateSaleAddr,
        address _TeamAllocationAddr,
        address _StrategicRoundAddr
    ) public onlyOwner {
        require(!_isDistributionComplete);

        require(_CommunityDevelopmentAddr != address(0));
        require(_StakingRewardsAddr != address(0));
        require(_LiquidityPoolAddr != address(0));
        require(_PublicSaleAddr != address(0));
        require(_AdvisorsAddr != address(0));
        require(_SeedInvestmentAddr != address(0));
        require(_PrivateSaleAddr != address(0));
        require(_TeamAllocationAddr != address(0));
        require(_StrategicRoundAddr != address(0));
        // set parnters addresses
        CommunityDevelopmentAddr = _CommunityDevelopmentAddr;
        StakingRewardsAddr = _StakingRewardsAddr;
        LiquidityPoolAddr = _LiquidityPoolAddr;
        PublicSaleAddr = _PublicSaleAddr;
        AdvisorsAddr = _AdvisorsAddr;
        SeedInvestmentAddr = _SeedInvestmentAddr;
        PrivateSaleAddr = _PrivateSaleAddr;
        TeamAllocationAddr = _TeamAllocationAddr;
        StrategicRoundAddr = _StrategicRoundAddr;
    }

    function distributeTokens() public onlyOwner {
        require((!_isDistributionComplete));

        _transfer(
            address(this),
            CommunityDevelopmentAddr,
            COMMUNITY_DEVELOPMENT
        );
        _transfer(address(this), StakingRewardsAddr, STAKING_REWARDS);
        _transfer(address(this), LiquidityPoolAddr, LIQUIDITY_POOL);
        _transfer(address(this), PublicSaleAddr, PUBLIC_SALE);
        _transfer(address(this), AdvisorsAddr, ADVISORS);
        _transfer(address(this), SeedInvestmentAddr, SEED_INVESTMENT);
        _transfer(address(this), PrivateSaleAddr, PRIVATE_SALE);
        _transfer(address(this), TeamAllocationAddr, TEAM_ALLOCATION);
        _transfer(address(this), StrategicRoundAddr, STRATEGIC_ROUND);

        // Whitelist these addresses as tex exempt
        setTaxExemptStatus(CommunityDevelopmentAddr, true);
        setTaxExemptStatus(StakingRewardsAddr, true);
        setTaxExemptStatus(LiquidityPoolAddr, true);
        setTaxExemptStatus(PublicSaleAddr, true);
        setTaxExemptStatus(AdvisorsAddr, true);
        setTaxExemptStatus(SeedInvestmentAddr, true);
        setTaxExemptStatus(PrivateSaleAddr, true);
        setTaxExemptStatus(TeamAllocationAddr, true);
        setTaxExemptStatus(StrategicRoundAddr, true);

        _isDistributionComplete = true;
    }

    function setTaxRate(uint256 newTaxRate) public onlyOwner {
        require(newTaxRate < 10000, "Tax connot be over 100% (10000 BP)");
        taxRate = newTaxRate;
    }

    function setTaxExemptStatus(address account, bool status) public onlyOwner {
        require(account != address(0));
        taxExempt[account] = status;
    }

    function setTaxationWallet(address newTaxationWallet) public onlyOwner {
        require(newTaxationWallet != address(0));
        taxationWallet = newTaxationWallet;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (address(locker) != address(0)) {
            locker.lockOrGetPenalty(sender, recipient);
        }
        ERC20._transfer(sender, recipient, amount);
    }

    function _transferWithTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient, "Cannot self transfer");

        uint256 tax = amount.mulBP(taxRate);
        uint256 tokensToTransfer = amount.sub(tax);

        _transfer(sender, taxationWallet, tax);
        _transfer(sender, recipient, tokensToTransfer);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(_msgSender() != recipient, "ERC20: cannot self transfer");
        !taxExempt[_msgSender()]
            ? _transferWithTax(_msgSender(), recipient, amount)
            : _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        !taxExempt[sender]
            ? _transferWithTax(sender, recipient, amount)
            : _transfer(sender, recipient, amount);

        approve(
            _msgSender(),
            allowance(sender, _msgSender()).sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";

import "./Roles.sol";

contract Operator is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor() {
        if (!isOperator(_msgSender())) {
            _addOperator(_msgSender());
        }
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function addOperator(address account) public onlyOperator {
        _addOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(_msgSender());
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";

import "./Roles.sol";

contract Rewarder is Context {
    using Roles for Roles.Role;

    event RewarderAdded(address indexed account);
    event RewarderRemoved(address indexed account);

    Roles.Role private _rewarders;

    constructor() {
        if (!isRewarder(_msgSender())) {
            _addRewarder(_msgSender());
        }
    }

    modifier onlyRewarder() {
        require(
            isRewarder(_msgSender()),
            "RewarderRole: caller does not have the Rewarder role"
        );
        _;
    }

    function isRewarder(address account) public view returns (bool) {
        return _rewarders.has(account);
    }

    function addRewarder(address account) public onlyRewarder {
        _addRewarder(account);
    }

    function renounceRewarder() public {
        _removeRewarder(_msgSender());
    }

    function _addRewarder(address account) internal {
        _rewarders.add(account);
        emit RewarderAdded(account);
    }

    function _removeRewarder(address account) internal {
        _rewarders.remove(account);
        emit RewarderRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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

pragma solidity ^0.7.0;

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
    constructor () {
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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface ILocker {
    /**
     * @dev Fails if transaction is not allowed.
     * Return values can be ignored for AntiBot launches
     */
    function lockOrGetPenalty(address source, address dest)
        external
        returns (bool, uint256);
}

interface ILockerUser {
    function locker() external view returns (ILocker);

    /**
     * @dev Emitted when setLocker is called.
     */
    event SetLocker(address indexed locker);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

