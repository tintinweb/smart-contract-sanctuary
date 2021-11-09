// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "../Role/PoolCreator.sol";
import "./StakingPool.sol";
import "./RewardManager.sol";
import "../Distribution/USDRetriever.sol";

contract StakingPoolFactory is PoolCreator {
    TotemToken public immutable totemToken;
    RewardManager public immutable rewardManager;
    address public swapRouter;
    address immutable usdToken;
    uint256 public stakingPoolTaxRate;
    uint256 public minimumStakeAmount;

    event PoolCreated(
        address indexed pool,
        string wrappedTokenSymbole,
        string poolType,
        // variables[0] launchDate,
        // variables[1] = maturityTime,
        // variables[2] = lockTime,
        // variables[3] = sizeAllocation,
        // variables[4] = stakeApr,
        // variables[5] = prizeAmount,
        // variables[6] = usdPrizeAmount,
        // variables[7] = potentialCollabReward,
        // variables[8] = collaborativeRange,
        // variables[9] = stakingPoolTaxRate,
        // variables[10] = minimumStakeAmount,
        // the order of the variable is as above
        uint256[11] variables,
        uint256[8] ranks,
        uint256[8] percentages,
        bool isEnhancedEnabled
    );

    constructor(
        TotemToken _totemToken,
        RewardManager _rewardManager,
        address _swapRouter,
        address _usdToken
    ) {
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        swapRouter = _swapRouter;
        usdToken = _usdToken;
         
        stakingPoolTaxRate = 300;

        // minimum amount of totem can be staked is 250 TOTM,
        // it's a mechanism to prevent DDOS attack
        // minimumStakeAmount = 250*(10**18);
    }

    function create(
        address _oracleContract,
        address _wrappedTokenContract,
        string memory _wrappedTokenSymbole,
        string memory _poolType,
        // uint256 launchDate,
        // uint256 maturityTime,
        // uint256 lockTime,
        // uint256 sizeAllocation,
        // uint256 stakeApr,
        // uint256 prizeAmount,
        // uint256 usdPrizeAmount,
        // uint256 potentialCollabReward,
        // uint256 collaborativeRange,
        // uint256 burnRate,
        // uint256 minimumStakeAmount,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool isEnhancedEnabled
    ) external onlyPoolCreator returns (address) {

        require(
            _ranks.length == _percentages.length,
            "length of ranks and percentages should be same"
        );

        if (_variables[9] == 0) {
            _variables[9] = stakingPoolTaxRate;
        }

        address[4] memory addrs = [swapRouter, usdToken, _oracleContract, _wrappedTokenContract];

        address newPool = createPool( addrs, _wrappedTokenSymbole, _poolType, _variables, _ranks, _percentages, isEnhancedEnabled);

        return newPool;
    }

    function createPool(
        address[4] memory _addrs,
        // address _oracleContract,
        // address _wrappedTokenContract,
        string memory _wrappedTokenSymbole,
        string memory _poolType,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool _isEnhancedEnabled
    ) internal returns (address) {

        address newPool =
            address(
                new StakingPool(
                    _wrappedTokenSymbole,
                    _poolType,
                    totemToken,
                    rewardManager,
                    _msgSender(),
                    _addrs,
                    _variables,
                    _ranks,
                    _percentages,
                    _isEnhancedEnabled
                )
            );

        emit PoolCreated(
            newPool,
            _wrappedTokenSymbole,
            _poolType,
            _variables,
            _ranks,
            _percentages,
            _isEnhancedEnabled
        );

        rewardManager.addPool(newPool);

        return newPool;
    }


    
    function setSwapRouter(address _swapRouter) external onlyPoolCreator {
        require(_swapRouter != address(0), "0410");
        swapRouter = _swapRouter;
    }

    function setDefaultTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "0420 Tax connot be over 100% (10000 BP)"
        );
        stakingPoolTaxRate = newStakingPoolTaxRate;
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
import "../Distribution/USDRetriever.sol";
import "./RewardManager.sol";
import "../Distribution/WrappedTokenDistributor.sol"; 

contract StakingPool is
    Context,
    Ownable,
    PriceConsumer,
    USDRetriever,
    WrappedTokenDistributor
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

    // FIXME: change the following variables types to add more flexibilty to the contract
    RewardManager public immutable rewardManager;
    IERC20 public immutable wrappedToken;

    string public wrappedTokenSymbol;
    string public poolType;

    uint256 public immutable launchDate;
    uint256 public immutable lockTime;
    uint256 public immutable maturityTime;

    uint256 public immutable sizeAllocation;
    uint256 public immutable stakeApr;

    uint256 public immutable prizeAmount;

    // usdPrizeAmount is the enabler of WrappedToken rewarder if it would be 0 then the pool is only TOTM rewarder
    uint256 public immutable usdPrizeAmount;

    uint256 public immutable stakeTaxRate;
    uint256 public immutable minimumStakeAmount;

    mapping(address => StakeWithPrediction[]) public predictions;
    Staker[] public stakers;
    Staker[] public sortedStakers;

    uint256 public totalStaked;

    // TODO: the maturing price is not the real maturity price and it depends on
    // the calling endPool function
    uint256 public maturingPrice;

    // FIXME: change the sizeLimitRange to basisPoint format
    uint256 public constant sizeLimitRangeRate = 5;
    // TODO: implement a mechanism to get the decimals from the oracle
    uint256 public constant oracleDecimal = 8;

    uint256 public immutable potentialCollabReward;
    uint256 public immutable collaborativeRange;
    // based on the white paper the collaborative reward can be 20% (2000), 25% (2500) or 35% (3500)
    uint256 public collaborativeReward; 

    address public poolCreator;
    address public oracleContract;

    bool public isAnEmergency;
    bool public immutable isEnhancedEnabled;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;
    

    PrizeRewardRate[] public prizeRewardRates;

    event Stake(address indexed user, uint256 amount, uint256 pricePrediction);
    event Withdraw(address indexed user, uint256 amount, uint256 wrappedTokenAmount);
    event Unstake(address indexed user, uint256 amount);
    event PoolLocked();
    event PoolSorted();
    event PoolMatured();
    event PoolDeleted();

    constructor(
        string memory _wrappedTokenSymbol,
        string memory _poolType,
        TotemToken _totemToken,
        RewardManager _rewardManager,
        address _poolCreator,
        address[4] memory _addrs,

        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool _isEnhancedEnabled
    )
        PriceConsumer(_addrs[2])
        WrappedTokenDistributor(_addrs[0], _addrs[1], _addrs[3])
    {

        require(
            _variables[0] > block.timestamp,
            "0301 launch date can't be in past"
        );

        wrappedTokenSymbol = _wrappedTokenSymbol;
        poolType = _poolType;

        totemToken = _totemToken;
        rewardManager = _rewardManager;
        oracleContract = _addrs[2];

        poolCreator = _poolCreator;

        setUSDToken(_addrs[1]);
        wrappedToken = IERC20(_addrs[3]);

        // deployDate = block.timestamp;

        launchDate = _variables[0];

        maturityTime = _variables[1];
        lockTime = _variables[2];

        sizeAllocation = _variables[3];
        stakeApr = _variables[4];
        
        prizeAmount = _variables[5];
        usdPrizeAmount = _variables[6];
        potentialCollabReward = _variables[7];
        collaborativeRange = _variables[8];
        // FIXME: _variables[8] is burnRate 
        stakeTaxRate = _variables[9];
        minimumStakeAmount = _variables[10];   


        isEnhancedEnabled = _isEnhancedEnabled; 

        for (uint256 i = 0; i < _ranks.length; i++) {

            if (_percentages[i] == 0) break;

            prizeRewardRates.push(
                PrizeRewardRate({
                    rank: _ranks[i], 
                    percentage: _percentages[i]
                })
            );
        }
    }

    function setActivationStatus(bool _activationStatus) 
        external 
        onlyPoolCreator 
    {
        isActive = _activationStatus;
    }

    function stake(uint256 _amount, uint256 _pricePrediction) external {
        require(
            isActive && block.timestamp > launchDate,
            "0313 pool is not active"
        );
        require(
            !isLocked, 
            "0310 Pool is locked"
        );
        require(
            _amount >= minimumStakeAmount, 
            "0311 Amount can't be less than the minimum"
        );
        
        uint256 limitRange = sizeAllocation.mul(sizeLimitRangeRate).div(100);
        uint256 taxRate = totemToken.taxRate();
        uint256 tax =
            totemToken.taxExempt(_msgSender()) ? 0 : _amount.mulBP(taxRate);
        
        require(
            totalStaked.add(_amount).sub(tax) <= sizeAllocation.add(limitRange), 
            "0312 Can't stake above size allocation"
        );

        
        uint256 stakeTaxAmount;
        // now the stakeTaxAmount is the staking tax and the _amount is initial amount minus the staking tax
        (stakeTaxAmount, _amount) = _getStakingTax(_amount, taxRate);

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

        // FIXME: spilit the stake function into two functions 
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

        if (totalStaked >= sizeAllocation) {
            // if the staking pool has not anymore capacity then it is locked
            _lockPool();
        }

        emit Stake(_msgSender(), _amount, _pricePrediction);
    }

    function claimReward() external {
        (uint256 reward, uint256 wrappedTokenReward) = getTotalReward(_msgSender());

        if (reward > 0) {
            if (totemToken.balanceOf(address(rewardManager)) >= reward) {
                // FIXME: all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), reward);
            }
        }
        
        // _wthdraw don't withdraw actually, and only update the array in the map
        _withdrawStakingReward(_msgSender());
        
        //FIXME: withdraws must come before the actual transfers to prevent attacks

        if (isMatured) {

            if (usdPrizeAmount > 0) {
                if (wrappedTokenReward > 0) require(wrappedToken.transfer(_msgSender(), wrappedTokenReward), "0320");

                // _withdraw don't withdraw actually, and only update the array in the map
                _withdrawPrizeReward(_msgSender());
            }

            // Users can't unstake until the pool matures
            uint256 stakedBalance = getTotalStakedBalance(_msgSender());
            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                // _wthdraw don't withdraw actually, and only update the array in the map
                _withdrawStakedBalance(_msgSender());

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit Withdraw(_msgSender(), reward, wrappedTokenReward);
    }


    // FIXME: uncomment it when proxy is applied
    // function indexedClaimReward(uint256 stakeIndex) external {
    //     (uint256 reward, uint256 wrappedTokenReward) = getIndexedReward(_msgSender(), stakeIndex);

    //     if (reward > 0) {
    //         // Send the token reward only when the rewardManager has the enough fund
    //         if (totemToken.balanceOf(address(rewardManager)) >= reward) {
    //             rewardManager.rewardUser(_msgSender(), reward);
    //         }
    //     }
        
    //     _withdrawIndexedStakingReward(_msgSender(), stakeIndex);
        

    //     if (isMatured) {
            
    //         if (usdPrizeAmount > 0) {
    //             if (wrappedTokenReward > 0) require(wrappedToken.transfer(_msgSender(), wrappedTokenReward), "0330");

    //             _withdrawIndexedPrizeReward(_msgSender(), stakeIndex);
    //         }


    //         uint256 stakedBalance = getIndexedStakedBalance(_msgSender(), stakeIndex);
    //         if (stakedBalance > 0) {
    //             totemToken.transfer(_msgSender(), stakedBalance);

    //             _withdrawIndexedStakedBalance(_msgSender(), stakeIndex);

    //             emit Unstake(_msgSender(), stakedBalance);
    //         }
    //     }

    //     emit Withdraw(_msgSender(), reward, wrappedTokenReward);
    // }

    function purchaseWrappedToken(uint256 usdAmount, uint256 deadline)
        external
        onlyPoolCreator
    {
        //TODO: require usdAmount to be more than usdPrizeAmount, to have enough rewards!
        require(
            usdPrizeAmount > 0, 
            "0340 The pool is only TOTM rewarder"
        );
        
        require(
            usdAmount > 0, 
            "0341 Amount can't be zero"
        );

        require(
            deadline >= block.timestamp, 
            "0342 Deadline is low"
        );

        // This approves tokens to swap router
        address swapRouterAddress = getswapRouter();
        approveTokens(swapRouterAddress, usdAmount);
        
        // Get equivalent USD amount for Wrapped Token
        uint256 wrappedTokenAmount = getEstimatedWrappedTokenForUSD(usdAmount);

        uint256 wrappedTokenAmountWithSlippage =
            wrappedTokenAmount.sub(wrappedTokenAmount.mulBP(300));

        transferTokensThroughSwap(
            address(this),
            usdAmount,
            wrappedTokenAmountWithSlippage,
            deadline
        );
    }

    function getWrappedTokenBalance() public view returns (uint256) {
        return wrappedToken.balanceOf(address(this));
    }

    function getPredictionRange(uint256 amount)
        public
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
        //FIXME: add a require to prevent locking a pool before locktime or max size allocation
        _lockPool();
    }

    function _lockPool() internal {
        isLocked = true;

        emit PoolLocked();
    }

    // If oracle is not zero address, then _price is ignored
    // When there is no oracle, _price is the maturingPrice and is set manually by the pool creator
    //FIXME: add a function to set oracle to zero in case it was given incorrectly by the owner
    function updateMaturingPrice(uint256 _price) external onlyPoolCreator {
        require(
            block.timestamp >= launchDate + lockTime + maturityTime,
            "0350 Can't set maturing price before the maturity time"
        );

        if (oracleContract == address(0)) {
            maturingPrice = _price;
        } else {
            maturingPrice = getLatestPrice();
        }
    }

    function endPool() external onlyPoolCreator {
        require(
            block.timestamp >= launchDate + lockTime + maturityTime,
            "0360 Can't end pool before the maturity time"
        );
        //TODO: check to see if there is enough USD to buy the wrapped token with, the mimimum USD
        // must be usdPrizeAmount, if there is not, do not allow endPool
        if (usdPrizeAmount > 0) {
            require(
                getWrappedTokenBalance() != 0, 
                "0361 WrappedToken Rewards not available"
            );
        }

        if (stakers.length > 0) {
            require(
                sortedStakers.length != 0,
                "0362 first should sort"
            );
        }

        // potentialCollabReward allows the admin to set the collaborateive reward 
        if (potentialCollabReward > 0) {
            // the collaborative reward only gave to the pools that the average price predicted with 
            // the accuracy of 25 $
            uint256 avgPricePrediction = getAveragePricePrediction();
            if (getDifference(avgPricePrediction, collaborativeRange) == 0) {
                collaborativeReward = potentialCollabReward;
            }
        }

        uint256 max = sortedStakers.length > 25 ? 25 : sortedStakers.length;
        for (uint256 i = 0; i < max; i++) {
            predictions[sortedStakers[i].stakerAddress][sortedStakers[i].index].rank =
                i + 1;
        }

        // there is possibility that the size allocation is not reached 
        // and the isLocked is not set to ture
        isLocked = true;
        isMatured = true;

        emit PoolMatured();
    }
    function deletePool() external onlyPoolCreator {
        isDeleted = true;
        emit PoolDeleted();
    }

    function getDifference(uint256 prediction, uint256 _range)
        public
        view
        returns (uint256)
    {
        if (prediction > maturingPrice) {
            if (prediction.sub(_range) <= maturingPrice) return 0;
            else return prediction.sub(_range).sub(maturingPrice);
        } else {
            if (prediction.add(_range) >= maturingPrice) return 0;
            else return maturingPrice.sub(prediction.add(_range));
        }
    }

    function setSortedStakers(address[25] calldata addrArray, uint256[25] calldata indexArray)
        external 
        onlyPoolCreator 
    {
        if(sortedStakers.length != 0) {
            delete sortedStakers;
        }

        for (uint256 i = 0; i < addrArray.length; i++) {

            // the first 0 address means the other addresses are also 0 so they won't be checked
            if (addrArray[i] == address(0)) break;

            sortedStakers.push(
            Staker({
                stakerAddress: addrArray[i],
                index: indexArray[i]
                })
            );
        }

        emit PoolSorted();
    }

    function getStakers() 
        public 
        view 
        returns(address[] memory, uint256[] memory) 
    {
        address[] memory addrs = new address[](stakers.length);
        uint256[] memory indexes = new uint256[](stakers.length);

        for (uint256 i = 0; i < stakers.length; i++) {
            addrs[i] = stakers[i].stakerAddress;
            indexes[i] = stakers[i].index;
        }

        return (addrs, indexes);
    }

    function _getStakingRewardPerStake(address staker, uint256 stakeIndex)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction memory userStake = predictions[staker][stakeIndex];
        uint256 maturityDate = launchDate + lockTime + maturityTime;

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

    function getStakingReward(address staker) 
        public 
        view 
        returns (uint256) 
    {
        StakeWithPrediction[] memory userStakes = predictions[staker];
        if (userStakes.length == 0) return 0;

        uint256 reward = 0;
        for (uint256 i = 0; i < userStakes.length; i++) {
            uint256 rewardPerStake = _getStakingRewardPerStake(staker, i);

            reward = reward.add(rewardPerStake);
        }

        return reward;
    }

    // function getIndexedStakingReward(address staker, uint256 stakeIndex) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     StakeWithPrediction[] memory userStakes = predictions[staker];
    //     if (userStakes.length == 0) return 0;
    //     if (stakeIndex >= userStakes.length) return 0;

    //     uint256 reward = 0;
        
    //     uint256 rewardPerStake = _getStakingRewardPerStake(staker, stakeIndex);
    //     reward = reward.add(rewardPerStake);

    //     return reward;
    // }

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

    // function _withdrawIndexedStakingReward(address staker, uint256 stakeIndex) internal {
    //     StakeWithPrediction[] storage userStakes = predictions[staker];
    //     if (userStakes.length == 0) return;
    //     if (stakeIndex >= userStakes.length) return;

    //     uint256 rewardPerStake = _getStakingRewardPerStake(staker, stakeIndex);

    //     userStakes[stakeIndex].lastWithdrawalTime = block.timestamp;
    //     userStakes[stakeIndex].amountWithdrawn = userStakes[stakeIndex].amountWithdrawn.add(
    //         rewardPerStake
    //     );
    // }

    function _getEnhancedRewardRate(uint256 stakedTime)
        internal
        view
        returns (uint256)
    {

        // if the enhanced reward is not enabled so consider enhanced raward 0
        if (!isEnhancedEnabled) {
            return 0;
        }

        uint256 lockDate = launchDate.add(lockTime);
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

    function getPrizeReward(address staker)
        public
        view
        returns (uint256, uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!isMatured) return (0, 0);

        StakeWithPrediction[] memory userStakes = predictions[staker];

        // users that don't stake don't get any prize also
        if (userStakes.length == 0) return (0, 0);

        uint256 maturingWrappedTokenPrizeAmount =
            (usdPrizeAmount.mul(10**oracleDecimal)).div(maturingPrice);

        uint256 reward = 0;
        uint256 wrappedTokenReward = 0;

        for (uint256 i = 0; i < userStakes.length; i++) {
            // only calculate the prize amount for stakes that are not withdrawn yet
            if (!userStakes[i].prizeRewardWithdrawn) {

                uint256 _percent = _getPercentageReward(userStakes[i].rank);

                reward = reward.add(
                            prizeAmount.mulBP(_percent)
                        );

                wrappedTokenReward = wrappedTokenReward.add(
                            maturingWrappedTokenPrizeAmount
                                .mulBP(_percent)
                        );        
            }
        }

        if (collaborativeReward > 0) {
            reward = reward.addBP(collaborativeReward);
            wrappedTokenReward = wrappedTokenReward.addBP(collaborativeReward);
        }

        return (reward, wrappedTokenReward);
    }

    function _getPercentageReward(uint256 _rank)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < prizeRewardRates.length; i++) {
            if (_rank <= prizeRewardRates[i].rank) {
                return prizeRewardRates[i].percentage;
            }
        }

        return 0;
    }        

    // function getIndexedPrizeReward(address staker, uint256 stakeIndex)
    //     public
    //     view
    //     returns (uint256, uint256)
    // {
    //     // wihtout the maturing price calculating prize is impossible
    //     if (!isMatured) return (0, 0);

    //     StakeWithPrediction[] memory userStakes = predictions[staker];

    //     // users that don't stake don't get any prize also
    //     if (userStakes.length == 0) return (0, 0);

    //     // the prize reward considered 0 if stakeIndex exceeds
    //     if (stakeIndex >= userStakes.length) return (0,0);

    //     // If the first prize reward is withdrawn, we can assume that all the prize/collaborative rewards are withdrawn
    //     if (userStakes[stakeIndex].prizeRewardWithdrawn) return (0, 0);

    //     uint256 maturingWrappedTokenPrizeAmount =
    //         (usdPrizeAmount.mul(10**oracleDecimal)).div(maturingPrice);

    //     uint256 reward = 0;
    //     uint256 wrappedTokenReward = 0;

    //     uint256 _percent = _getPercentageReward(userStakes[stakeIndex].rank);

    //     reward = reward.add(
    //                     prizeAmount.mulBP(_percent)
    //                 );

    //     wrappedTokenReward = wrappedTokenReward.add(
    //                     maturingWrappedTokenPrizeAmount
    //                         .mulBP(_percent)
    //                 );            

    //     if (collaborativeReward > 0) {
    //         reward = reward.addBP(collaborativeReward);
    //         wrappedTokenReward = wrappedTokenReward.addBP(collaborativeReward);
    //     }

    //     return (reward, wrappedTokenReward);
    // }



    function _withdrawPrizeReward(address staker) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;

        for (uint256 i = 0; i < userStakes.length; i++) {
            userStakes[i].prizeRewardWithdrawn = true;
        }
    }

    // function _withdrawIndexedPrizeReward(address staker, uint256 stakeIndex) internal {
    //     StakeWithPrediction[] storage userStakes = predictions[staker];
    //     if (userStakes.length == 0) return;
    //     if (userStakes[stakeIndex].prizeRewardWithdrawn) return;

    //     userStakes[stakeIndex].prizeRewardWithdrawn = true;
    // }

    // getTotalStakedBalance return remained staked balance
    function getTotalStakedBalance(address staker)
        public
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
    // function getIndexedStakedBalance(address staker, uint256 stakeIndex)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     StakeWithPrediction[] memory userStakes = predictions[staker];
    //     if (userStakes.length == 0) return 0;
    //     if (stakeIndex >= userStakes.length) return 0; 

    //     uint256 totalStakedBalance = 0;

    //     if (!userStakes[stakeIndex].didUnstake) {
    //         totalStakedBalance = totalStakedBalance.add(
    //             userStakes[stakeIndex].stakedBalance
    //         );
    //     }

    //     return totalStakedBalance;
    // }

    function _withdrawStakedBalance(address staker) internal {
        StakeWithPrediction[] storage userStakes = predictions[staker];
        if (userStakes.length == 0) return;

        for (uint256 i = 0; i < userStakes.length; i++) {
            userStakes[i].didUnstake = true;
        }
    }

    // function _withdrawIndexedStakedBalance(address staker, uint256 stakeIndex) internal {
    //     StakeWithPrediction[] storage userStakes = predictions[staker];
    //     if (userStakes.length == 0) return;
    //     if (stakeIndex >= userStakes.length) return;

    //     userStakes[stakeIndex].didUnstake = true;
    // }

    function getTotalReward(address staker)
        public
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 prizeReward;
        uint256 wrappedTokenPrizeReward;
        uint256 stakingReward = getStakingReward(staker);
        (prizeReward, wrappedTokenPrizeReward) = getPrizeReward(staker);

        return (stakingReward.add(prizeReward), wrappedTokenPrizeReward);
    }

    
    // function getIndexedReward(address staker, uint256 stakeIndex)
    //     public
    //     view
    //     returns (uint256, uint256)
    // {
    //     // since in the getPrizeReward function the maturingPrice is used
    //     // so we got error if it would not be maturityDate
    //     uint256 prizeReward;
    //     uint256 wrappedTokenPrizeReward;
    //     uint256 stakingReward = getIndexedStakingReward(staker, stakeIndex);
    //     (prizeReward, wrappedTokenPrizeReward) = getIndexedPrizeReward(staker, stakeIndex);

    //     return (stakingReward.add(prizeReward), wrappedTokenPrizeReward);
    // }

    function _getStakingTax(uint256 amount, uint256 tokenTaxRate)
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

    function withdrawStuckTokens(address _stuckToken, uint256 amount, address receiver)
        external
        onlyPoolCreator
    {
        require(
            _stuckToken != address(totemToken), 
            "0370 totems can not be transfered"
        );
        IERC20 stuckToken = IERC20(_stuckToken);
        stuckToken.transfer(receiver, amount);
    }

	// hasUnStaked return true if the user staked in the pool and then has unStaked it (in claim usecase)
    function hasUnStaked(address staker, uint256 stakeIndex) external view returns (bool) {
        StakeWithPrediction[] memory userStakes = predictions[staker];

        require(
            userStakes.length > 0,
            "0380 this address didn't stake in this pool"
        );

        require(
            stakeIndex < userStakes.length,
            "0381 this index exceeds"
        );
    

        if (userStakes[stakeIndex].didUnstake) {
            return true;
        }
        return false;
    }

    function declareEmergency()
        external
        onlyPoolCreator
    {
        isActive = false;
        isAnEmergency = true;

        _lockPool();
    }

    function emergentWithdraw() external {
        require(
            isAnEmergency,
            "it's not an emergency"
        );

        // Users can't unstake until the pool matures
        uint256 stakedBalance = getTotalStakedBalance(_msgSender());
        if (stakedBalance > 0) {
            totemToken.transfer(_msgSender(), stakedBalance);

            // _wthdraw don't withdraw actually, and only update the array in the map
            _withdrawStakedBalance(_msgSender());

            emit Unstake(_msgSender(), stakedBalance);
        }
    }

    modifier onlyPoolCreator {
        require(
            _msgSender() == poolCreator,
            "0300 caller is not a pool creator"
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

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    constructor(TotemToken _totemToken) {
        totemToken = _totemToken;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "0200 New Operator address cannot be zero."
        );

        addOperator(_newOperator);
        emit SetOperator(_newOperator);
    }

    function addPool(address _poolAddress) public onlyOperator {
        require(
            _poolAddress != address(0),
            "0210 Pool address cannot be zero."
        );

        addRewarder(_poolAddress);
        emit SetRewarder(_poolAddress);
    }

    function rewardUser(address _user, uint256 _amount) public onlyRewarder {
        require(_user != address(0), "0230 User address cannot be zero.");

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

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    /**
     * @param _oracle The chainlink node oracle address to send requests
     */
    constructor(address _oracle) {
        // commented for updatingMaturingPrice function in staking pool to work correctly
        // require(_oracle != address(0));
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

contract WrappedTokenDistributor {
    IPancakeRouter02 internal swapRouter;
    address internal BUSD_CONTRACT_ADDRESS;
    address internal WRAPPED_Token_CONTRACT_ADDRESS;

    event DistributedBTC(address indexed to, uint256 amount);

    constructor(
        address swapRouterAddress,
        address BUSDContractAddress,
        address WrappedTokenContractAddress
    ) {
        swapRouter = IPancakeRouter02(swapRouterAddress);
        BUSD_CONTRACT_ADDRESS = BUSDContractAddress;
        WRAPPED_Token_CONTRACT_ADDRESS = WrappedTokenContractAddress;
    }

    /**
     * @param _to Reciever address
     * @param _usdAmount USD Amount
     * @param _wrappedTokenAmount Wrapped Token Amount
     */
    function transferTokensThroughSwap(
        address _to,
        uint256 _usdAmount,
        uint256 _wrappedTokenAmount,
        uint256 _deadline
    ) internal {
        require(_to != address(0));
        // Get max USD price we can spend for this amount.
        swapRouter.swapExactTokensForTokens(
            _usdAmount,
            _wrappedTokenAmount,
            getPathForUSDToWrappedToken(),
            _to,
            _deadline
        );
    }

    /**
     * @param _amount Amount
     */
    function getEstimatedWrappedTokenForUSD(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256[] memory wrappedTokenAmount =
            swapRouter.getAmountsOut(_amount, getPathForUSDToWrappedToken());
        // since in the path the wrappedToken is the second one, so we should retuen the second one also here    
        return wrappedTokenAmount[1];
    }

    function getPathForUSDToWrappedToken() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = BUSD_CONTRACT_ADDRESS;
        path[1] = WRAPPED_Token_CONTRACT_ADDRESS;

        return path;
    }

    // the function should be rename to getSwapRouter
    function getswapRouter() public view returns (address) {
        return address(swapRouter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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