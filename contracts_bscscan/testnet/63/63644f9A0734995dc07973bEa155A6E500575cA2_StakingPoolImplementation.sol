// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./StakingPoolStorageStructure.sol";

contract StakingPoolImplementation is StakingPoolStorageStructure {
    using BasisPoints for uint256;
    using SafeMath for uint256;
    using CalculateRewardLib for *;
    using IndexedClaimRewardLib for *;
    using ClaimRewardLib for *;
 
    modifier onlyPoolCreator {
        require(
            _msgSender() == poolCreator,
            "0300 caller is not a pool creator"
        );
        _;
    }

    event Stake(address indexed user, uint256 amount, uint256 pricePrediction);
    event Withdraw(address indexed user, uint256 amount, uint256 wrappedTokenAmount);
    event Unstake(address indexed user, uint256 amount);
    event PoolLocked();
    event PoolSorted();
    event PoolMatured();
    event PoolDeleted();

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
            // if the staking pool does not have anymore capacity then it is locked
            _lockPool();
        }

        emit Stake(_msgSender(), _amount, _pricePrediction);
    }

    function claimReward() external {
        (uint256 reward, uint256 wrappedTokenReward) = 
            ClaimRewardLib.getTotalReward(
                predictions[_msgSender()],
                lps,
                prizeRewardRates
            )
        ;

        if (reward > 0) {
            if (totemToken.balanceOf(address(rewardManager)) >= reward) {
                // FIXME: all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), reward);
            }
        }
        
        // _wthidraw don't withdraw actually, and only update the array in the map
        ClaimRewardLib.withdrawStakingReward(predictions[_msgSender()], lps);

        //FIXME: withdraws must come before the actual transfers to prevent attacks

        if (isMatured) {

            if (usdPrizeAmount > 0) {
                if (wrappedTokenReward > 0) require(wrappedToken.transfer(_msgSender(), wrappedTokenReward), "0320");

                // _withdraw don't withdraw actually, and only update the array in the map
                ClaimRewardLib.withdrawPrizeReward(predictions[_msgSender()]);
            }

            // Users can't unstake until the pool matures
            uint256 stakedBalance = CalculateRewardLib.getTotalStakedBalance(predictions[_msgSender()]);
            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                // _wthdraw don't withdraw actually, and only update the array in the map
                ClaimRewardLib.withdrawStakedBalance(predictions[_msgSender()]);

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit Withdraw(_msgSender(), reward, wrappedTokenReward);
    }

    function indexedClaimReward(uint256 stakeIndex) external {
        require(predictions[_msgSender()].length >= stakeIndex, "Index does not exist");
        require(predictions[_msgSender()].length != 0, "User does not have any stakes");

        (uint256 reward, uint256 wrappedTokenReward) = IndexedClaimRewardLib.getIndexedReward(
            predictions[_msgSender()], 
            stakeIndex,
            lps,
            prizeRewardRates
        );

        if (reward > 0) {
            // Send the token reward only when the rewardManager has the enough fund
            if (totemToken.balanceOf(address(rewardManager)) >= reward) {
                rewardManager.rewardUser(_msgSender(), reward);
            }
        }
        
        IndexedClaimRewardLib.withdrawIndexedStakingReward(
            predictions[_msgSender()], 
            stakeIndex,
            lps
        );
        

        if (isMatured) {
            
            if (usdPrizeAmount > 0) {
                if (wrappedTokenReward > 0) require(wrappedToken.transfer(_msgSender(), wrappedTokenReward), "0330");

                IndexedClaimRewardLib.withdrawIndexedPrizeReward(predictions[_msgSender()], stakeIndex);
            }

            uint256 stakedBalance = IndexedClaimRewardLib.getIndexedStakedBalance(
                predictions[_msgSender()], 
                stakeIndex
            );

            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                IndexedClaimRewardLib.withdrawIndexedStakedBalance(predictions[_msgSender()], stakeIndex);

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit Withdraw(_msgSender(), reward, wrappedTokenReward);
    }

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

    function lockPool() public onlyPoolCreator virtual {
        //FIXME: add a require to prevent locking a pool before locktime or max size allocation
        _lockPool();
    }

    function _lockPool() internal {
        isLocked = true;

        emit PoolLocked();
    }

    /**
     * @param _price is ignored if oracle is not zero address.When there is no oracle,
             _price is the maturingPrice and is set manually by the pool creator
    */
    //FIXME: add a function to set oracle to zero in case it was given incorrectly by the owner
    function updateMaturingPrice(uint256 _price) external onlyPoolCreator {
        require(
            block.timestamp >= launchDate + lockTime + maturityTime,
            "0350 Can't set maturing price before the maturity time"
        );

        if (oracleContract == address(0)) {
            maturingPrice = _price;
            lps.maturingPrice = maturingPrice;
        } else {
            maturingPrice = getLatestPrice();
            lps.maturingPrice = maturingPrice;
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
                lps.collaborativeReward = collaborativeReward;
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
        lps.isMatured = isMatured;

        emit PoolMatured();
    }
    function deletePool() external onlyPoolCreator {
        isDeleted = true;
        emit PoolDeleted();
    }

    function getDifference(uint256 prediction, uint256 range)
        public
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
        uint256 stakedBalance = CalculateRewardLib.getTotalStakedBalance(predictions[_msgSender()]);
        if (stakedBalance > 0) {
            totemToken.transfer(_msgSender(), stakedBalance);

            // _wthdraw don't withdraw actually, and only update the array in the map
            ClaimRewardLib.withdrawStakedBalance(predictions[_msgSender()]);

            emit Unstake(_msgSender(), stakedBalance);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Distribution/USDRetriever.sol";
import "../Price/PriceConsumerUpgradeable.sol";
import "../Distribution/WrappedTokenDistributorUpgradeable.sol";

import "../libraries/BasisPoints.sol";
import "../libraries/CalculateRewardLib.sol";
import "../libraries/IndexedClaimRewardLib.sol";
import "../libraries/ClaimRewardLib.sol";

import "../interfaces/ITotemToken.sol";
import "../interfaces/IRewardManager.sol";

contract StakingPoolStorageStructure is 
    OwnableUpgradeable,  
    PriceConsumerUpgradeable,
    USDRetriever,
    WrappedTokenDistributorUpgradeable
{
    address public superAdmin;
    
    address public stakingPoolImplementation;
    address public poolCreator;
    address public oracleContract;

    /**
     * @notice Declared for passing the needed params to libraries.
     */
    struct LibParams {
        uint256 launchDate;
        uint256 lockTime;
        uint256 maturityTime;
        uint256 maturingPrice;
        uint256 usdPrizeAmount;
        uint256 prizeAmount;
        uint256 stakeApr;
        uint256 collaborativeReward;
        bool isEnhancedEnabled;
        bool isMatured;
    }

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

    LibParams public lps;

    PrizeRewardRate[] public prizeRewardRates;
    Staker[] public stakers;
    Staker[] public sortedStakers;

    mapping(address => StakeWithPrediction[]) public predictions;

    ITotemToken public totemToken;
    IRewardManager public rewardManager;
    IERC20 public wrappedToken;

    string public wrappedTokenSymbol;
    string public poolType;

    // FIXME: change the sizeLimitRange to basisPoint format
    uint256 public constant sizeLimitRangeRate = 5;
    uint256 public constant oracleDecimal = 8;

    uint256 public launchDate;
    uint256 public lockTime;
    uint256 public maturityTime;
    uint256 public sizeAllocation;
    uint256 public stakeApr;
    uint256 public prizeAmount;
    /**
     * @notice usdPrizeAmount is the enabler of WrappedToken rewarder; If it is set to 0 
            then the pool is only TOTM rewarder.
     */
    uint256 public usdPrizeAmount;
    uint256 public stakeTaxRate;
    uint256 public minimumStakeAmount;
    uint256 public totalStaked;
    // TODO: the maturing price is not the real maturity price and it depends on
    // the calling endPool function
    uint256 public maturingPrice;
    uint256 public potentialCollabReward;
    uint256 public collaborativeRange;
    /**
     * @notice Based on the white paper, the collaborative reward can be 20% (2000),
             25% (2500) or 35% (3500).
     */
    uint256 public collaborativeReward; 

    bool public isAnEmergency;
    bool public isEnhancedEnabled;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PriceConsumerUpgradeable is Initializable {
    AggregatorV3Interface internal priceFeed;

    /**
     * @param _oracle The chainlink node oracle address to send requests
     */
    function __PriceConsumer_initialize(address _oracle) public initializer {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IPancakeRouter.sol";

contract WrappedTokenDistributorUpgradeable is Initializable{
    IPancakeRouter02 internal swapRouter;
    address internal BUSD_CONTRACT_ADDRESS;
    address internal WRAPPED_Token_CONTRACT_ADDRESS;

    event DistributedBTC(address indexed to, uint256 amount);

    function __WrappedTokenDistributor_initialize(
        address swapRouterAddress,
        address BUSDContractAddress,
        address WrappedTokenContractAddress
    ) public initializer {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
pragma solidity ^0.8.0;

import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library CalculateRewardLib {

    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    ////////////////////////// public functions /////////////////////
    function getTotalStakedBalance(StakingPoolStorageStructure.StakeWithPrediction[] storage _staker)
        public
        view
        returns (uint256)
    {
        if (_staker.length == 0) return 0;

        uint256 totalStakedBalance = 0;
        for (uint256 i = 0; i < _staker.length; i++) {
            if (!_staker[i].didUnstake) {
                totalStakedBalance = totalStakedBalance.add(
                    _staker[i].stakedBalance
                );
            }
        }

        return totalStakedBalance;
    }

    ////////////////////////// internal functions /////////////////////
    function _getStakingRewardPerStake(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {
        uint256 maturityDate = 
            _lps.launchDate + 
            _lps.lockTime + 
            _lps.maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;

        uint256 enhancedApr;
        if ( _lps.isEnhancedEnabled ) {
            enhancedApr = _getEnhancedRewardRate(
                _staker[_stakeIndex].stakedTime,
                _lps
            );
        }

        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance
        uint256 rewardPerStake = _calcStakingReturn(
            _lps.stakeApr.add(enhancedApr),
            timeTo.sub(_staker[_stakeIndex].stakedTime),
            _staker[_stakeIndex].stakedBalance
        );

        rewardPerStake = rewardPerStake.sub(_staker[_stakeIndex].amountWithdrawn);

        return rewardPerStake;
    }

    function _getEnhancedRewardRate(
        uint256 stakedTime,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {

        // if the enhanced reward is not enabled so consider enhanced raward 0
        if (!_lps.isEnhancedEnabled) {
            return 0;
        }

        uint256 lockDate = _lps.launchDate.add(_lps.lockTime);
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

    function _getPercentageReward(
        uint256 _rank, 
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _prizeRewardRates.length; i++) {
            if (_rank <= _prizeRewardRates[i].rank) {
                return _prizeRewardRates[i].percentage;
            }
        }

        return 0;
    }        



}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library IndexedClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    ////////////////////////// public functions /////////////////////
    function getIndexedReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 prizeReward;
        uint256 wrappedTokenPrizeReward;
        uint256 stakingReward = getIndexedStakingReward(
            _staker, 
            _stakeIndex,
            _lps
        );
        (prizeReward, wrappedTokenPrizeReward) = getIndexedPrizeReward(
            _staker, 
            _stakeIndex,
            _lps,
            _prizeRewardRates
        );

        return (stakingReward.add(prizeReward), wrappedTokenPrizeReward);
    }

    function withdrawIndexedStakingReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    ) 
        public
    {
        if (_staker.length == 0) return;
        if (_stakeIndex >= _staker.length) return;

        uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
            _staker, 
            _stakeIndex,
            _lps
        );

        _staker[_stakeIndex].lastWithdrawalTime = block.timestamp;
        _staker[_stakeIndex].amountWithdrawn = _staker[_stakeIndex].amountWithdrawn.add(
            rewardPerStake
        );
    }

    function withdrawIndexedPrizeReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    ) 
        public 
    {
        if (_staker.length == 0) return;
        if (_staker[_stakeIndex].prizeRewardWithdrawn) return;

        _staker[_stakeIndex].prizeRewardWithdrawn = true;
    }

    function withdrawIndexedStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    ) 
        public
    {
        if (_staker.length == 0) return;
        if (_stakeIndex >= _staker.length) return;

        _staker[_stakeIndex].didUnstake = true;
    }

    function getIndexedStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    )
        public
        view
        returns (uint256)
    {
        if (_staker.length == 0) return 0;
        if (_stakeIndex >= _staker.length) return 0; 

        uint256 totalStakedBalance = 0;

        if (!_staker[_stakeIndex].didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                _staker[_stakeIndex].stakedBalance
            );
        }

        return totalStakedBalance;
    }

    ////////////////////////// internal functions ///////////////////
    function getIndexedStakingReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    ) 
        public
        view 
        returns (uint256) 
    {
        if (_staker.length == 0) return 0;
        if (_stakeIndex >= _staker.length) return 0;

        uint256 reward = 0;
        
        uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
            _staker, 
            _stakeIndex,
            _lps
        );
        reward = reward.add(rewardPerStake);

        return reward;
    }

    function getIndexedPrizeReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!_lps.isMatured) return (0, 0);

        // users that don't stake don't get any prize also
        if (_staker.length == 0) return (0, 0);

        // the prize reward considered 0 if stakeIndex exceeds
        if (_stakeIndex >= _staker.length) return (0,0);

        // If the first prize reward is withdrawn, we can assume that all the prize/collaborative rewards are withdrawn
        if (_staker[_stakeIndex].prizeRewardWithdrawn) return (0, 0);

        uint256 maturingWrappedTokenPrizeAmount =
            (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        uint256 wrappedTokenReward = 0;

        uint256 _percent = CalculateRewardLib._getPercentageReward(
            _staker[_stakeIndex].rank,
            _prizeRewardRates
        );

        reward = reward.add(
                        _lps.prizeAmount.mulBP(_percent)
                    );

        wrappedTokenReward = wrappedTokenReward.add(
                        maturingWrappedTokenPrizeAmount
                            .mulBP(_percent)
                    );            

        if (_lps.collaborativeReward > 0) {
            reward = reward.addBP(_lps.collaborativeReward);
            wrappedTokenReward = wrappedTokenReward.addBP(_lps.collaborativeReward);
        }

        return (reward, wrappedTokenReward);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library ClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    ////////////////////////// public functions /////////////////////
    function getTotalReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker,
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 prizeReward;
        uint256 wrappedTokenPrizeReward;
        uint256 stakingReward = getStakingReward(_staker, _lps);
        (prizeReward, wrappedTokenPrizeReward) = getPrizeReward(_staker, _lps, _prizeRewardRates);

        return (stakingReward.add(prizeReward), wrappedTokenPrizeReward);
    }

    function withdrawStakingReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        public 
    {
        
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
                _staker, 
                i, 
                _lps);

            _staker[i].lastWithdrawalTime = block.timestamp;
            _staker[i].amountWithdrawn = _staker[i].amountWithdrawn.add(
                rewardPerStake
            );
        }
    }

    function withdrawPrizeReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker
    ) 
        public
    {
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            _staker[i].prizeRewardWithdrawn = true;
        }
    }

    function withdrawStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker
    )
        public 
    {
        
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            _staker[i].didUnstake = true;
        }
    }

    ////////////////////////// internal functions ///////////////////
    function getStakingReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker,
        StakingPoolStorageStructure.LibParams storage _lps  
    ) 
        public 
        view 
        returns (uint256) 
    {
        if (_staker.length == 0) return 0;

        uint256 reward = 0;
        for (uint256 i = 0; i < _staker.length; i++) {
            uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
                _staker,
                i, 
                _lps
            );

            reward = reward.add(rewardPerStake);
        }

        return reward;
    }

    function getPrizeReward(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!_lps.isMatured) return (0, 0);

        // users that don't stake don't get any prize also
        if (_staker.length == 0) return (0, 0);

        uint256 maturingWrappedTokenPrizeAmount =
            (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        uint256 wrappedTokenReward = 0;

        for (uint256 i = 0; i < _staker.length; i++) {
            // only calculate the prize amount for stakes that are not withdrawn yet
            if (!_staker[i].prizeRewardWithdrawn) {

                uint256 _percent = CalculateRewardLib._getPercentageReward(
                    _staker[i].rank,
                    _prizeRewardRates
                );

                reward = reward.add(
                            _lps.prizeAmount.mulBP(_percent)
                        );

                wrappedTokenReward = wrappedTokenReward.add(
                            maturingWrappedTokenPrizeAmount
                                .mulBP(_percent)
                        );        
            }
        }

        if (_lps.collaborativeReward > 0) {
            reward = reward.addBP(_lps.collaborativeReward);
            wrappedTokenReward = wrappedTokenReward.addBP(_lps.collaborativeReward);
        }

        return (reward, wrappedTokenReward);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITotemToken {
    
    function setLocker(address _locker) external;

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
    ) external;

    function distributeTokens() external;

    function setTaxRate(uint256 newTaxRate) external;

    function setTaxExemptStatus(address account, bool status) external;

    function setTaxationWallet(address newTaxationWallet) external;


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Do they work?!
    function taxRate() external returns (uint256);

    function taxationWallet() external returns (address);

    // This is not gonna work!
    function taxExempt(address _msgSender) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardManager {

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}