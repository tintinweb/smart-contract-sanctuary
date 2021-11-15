// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../Role/PoolCreator.sol";
import "./IRewardManager.sol";
import "./IDOPredictionPool.sol";
import "./IIDOTokenBank.sol";


contract IDOPredictionPoolFactory is PoolCreator{
    // TODO: implement interface and add it 
    TotemToken public immutable totemToken;
    IRewardManager public immutable rewardManager;
    IIDOTokenBank public immutable idoTokenBank;
    address public immutable usdTokenAddress;

    uint256 public stakingPoolTaxRate;
    uint256 public minimumStakeAmount;

    event PoolCreated(
        address indexed pool,
        uint256 maturityTime,
        uint256 lockTime,
        uint256 sizeAllocation,
        uint256 stakeApr,
        uint256 totemPrizeAmount,
        uint256 idoTokenAmount,
        uint256 stakingPoolTaxRate,
        uint256 minimumStakeAmount
    );

    constructor(
        TotemToken _totemToken,
        IRewardManager _rewardManager,
        IIDOTokenBank _idoTokenBank,
        address _usdTokenAddress
    ) {
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        idoTokenBank = _idoTokenBank;
        usdTokenAddress = _usdTokenAddress;

        stakingPoolTaxRate = 300;

        // minimum amount of totem can be staked is 250 TOTM,
        // it's a mechanism to prevent DDOS attack
        minimumStakeAmount = 250*(10**18);
    }

    function create(
        uint256 maturityTime,
        uint256 lockTime,
        uint256 sizeAllocation,
        uint256 stakeApr,
        uint256 totemPrizeAmount, 
        uint256 idoTokenAmount,
        address idoToken
    ) external onlyPoolCreator returns (address) {

        uint256[8] memory variables = 
        [
                maturityTime,
                lockTime,
                sizeAllocation,
                stakeApr,
                totemPrizeAmount,
                idoTokenAmount,
                stakingPoolTaxRate,
                minimumStakeAmount
        ];    

        address newIDOPredictionPool =
            address(
                new IDOPredictionPool(
                    totemToken,
                    rewardManager,
                    idoTokenBank,
                    usdTokenAddress,
                    idoToken,
                    _msgSender(),
                    variables
                )
            );

        emit PoolCreated(
            newIDOPredictionPool,
            maturityTime,
            lockTime,
            sizeAllocation,
            stakeApr,
            totemPrizeAmount,
            idoTokenAmount,
            stakingPoolTaxRate,
            minimumStakeAmount
        );

        rewardManager.addPool(newIDOPredictionPool);
        idoTokenBank.addIDOPredictionWithToken(newIDOPredictionPool, idoToken);

        return newIDOPredictionPool;
    }

    function setTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "0720 Tax connot be over 100% (10000 BP)"
        );
        stakingPoolTaxRate = newStakingPoolTaxRate;
    }

    function setMinimuntToStake(uint256 newMinimumStakeAmount)
        external
        onlyPoolCreator
    {
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

import "@openzeppelin/contracts/utils/Context.sol";
import "../TotemToken.sol";
import "../Role/Operator.sol";
import "../Role/Rewarder.sol";

// TODO: provide an interface so IDO-prediction can work with that
interface IRewardManager {

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IRewardManager.sol";
import "./IIDOTokenBank.sol";

contract IDOPredictionPool is
    Context,
    Ownable
{
    using BasisPoints for uint256;
    using SafeMath for uint256;

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction1;
        uint256 pricePrediction2;
        uint256 difference;
        uint256 rank;
        bool totemPrizeWithdrawn;
        bool didUnstake;
    }

    struct IDOTokenSchedule {
        uint256 totalAmount; // Total amount of tokens can be purchased.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    // it wasn't possible to use totem token interface since we use taxRate variable
    TotemToken public immutable totemToken;
    IRewardManager public immutable rewardManager;
    IIDOTokenBank public immutable idoTokenBank;
    IERC20 public immutable usdToken;
    address public immutable idoToken;

    uint256 public immutable startDate;
    uint256 public immutable lockTime;
    uint256 public immutable maturityTime;

    uint256 public immutable sizeAllocation; // total TOTM can be staked
    uint256 public immutable stakeApr; // the annual return rate for staking TOTM

    // prizeUint (x) is the unit of TOTM that will be given to winners 
    // and multiply by 2 if user have staked more than an amount
    uint256 public immutable totemPrizeAmount;
    // idoTokenUnit is the total amount of the ido token that a winner can purchase
    uint256 public immutable idoTokenAmount;

    uint256 public immutable stakeTaxRate;
    uint256 public immutable minimumStakeAmount;

    // 100 means 1%
    uint256 public constant sizeLimitRangeRate = 500;
    
    // the default dexDecimal is 8 but can be modified in setIDOPrices
    uint256 public dexDecimal = 8;

    // matruing price and purchase price should have same decimals
    uint256 public maturingPrice;
    uint256 public purchasePrice;

    uint256 public idoStartDate;
    bool public idoIsStartDateSet;
    uint256 public idoWithdrawInterval; // Amount of time in seconds between withdrawal periods.
    uint256 public idoReleasePeriods; // Number of periods from start release until done.
    uint256 public idoLockPeriods; // Number of periods before start release.


    mapping(address => StakeWithPrediction) public predictions;
    address[] public stakers;
    address[] public winnerStakers;
    mapping(address => IDOTokenSchedule) public idoRecipients;

    uint256 public totalStaked;

    // TODO: I think it should be immutable
    address public poolCreator;

    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;

    event Stake(address indexed user, uint256 amount, uint256 pricePrediction1, uint256 pricePrediction2);
    event WithdrawTotemReturn(address indexed user, uint256 stakingReturn);
    event WithdrawTotemPrize(address indexed user, uint256 totemPrize);
    event Unstake(address indexed user, uint256 amount);
   
    event PurchaseIDOToken(address indexed user, uint256 usdAmount, uint256 idoTokenAmount);
    event IDOScheduleParametersSet(uint256 startDate, uint256 withdrawInterval, uint256 releasePeriods, uint256 lockPeriods);

    event PoolLocked();
    event PoolSorted();
    event PoolMatured();
    event PoolDeleted();

    constructor(
        TotemToken _totemToken,
        IRewardManager _rewardManager,
        IIDOTokenBank _idoTokenBank,
        address _usdTokenAddress,
        address _idoToken,
        address _poolCreator,
        uint256[8] memory _variables
    ) 
    {
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        idoTokenBank = _idoTokenBank;
        usdToken = IERC20(_usdTokenAddress);
        idoToken = _idoToken;
        poolCreator = _poolCreator;

        startDate = block.timestamp;
        maturityTime = _variables[0];
        lockTime = _variables[1];

        sizeAllocation = _variables[2];
        stakeApr = _variables[3];
        totemPrizeAmount = _variables[4];
        idoTokenAmount = _variables[5];
        stakeTaxRate = _variables[6];
        minimumStakeAmount = _variables[7];
    }

    function stake(uint256 _amount, uint256 _pricePrediction1, uint256 _pricePrediction2) external {
        require(
            !isLocked, 
            "0610 Pool is locked"
        );
        require(
            _amount >= minimumStakeAmount, 
            "0611 Amount can't be less than the minimum"
        );
        //checking if the user is already staked or not
        require(
            predictions[_msgSender()].stakedBalance <= 0, 
            "0613 this user is already staked"
        );

        uint256 limitRange = sizeAllocation.mulBP(sizeLimitRangeRate);
        uint256 stakeTaxAmount;
        uint256 taxRate = totemToken.taxRate();
        uint256 tax =
            totemToken.taxExempt(_msgSender()) ? 0 : _amount.mulBP(taxRate);
   
        require(
            // the total amount of stakes can exceed size allocation by 5%
            totalStaked.add(_amount).sub(tax) <= sizeAllocation.add(limitRange),
            "0612 Can't stake above size allocation"
        );

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

        _stake(_msgSender(), _amount, _pricePrediction1, _pricePrediction2);

        if (totalStaked >= sizeAllocation) {
            // if the staking pool has not anymore capacity then it is locked
            _lockPool();
        }

        emit Stake(_msgSender(), _amount, _pricePrediction1, _pricePrediction2);
    }

    function _stake(address _staker, uint256 _amount, uint256 _pricePrediction1, uint256 _pricePrediction2) internal {
        stakers.push(
            _staker
        );

        uint256 _modifiedPricePrediction;

        // tier1 = 2500*(10**18)
        if (_amount > 2500*(10**18)) {
            _modifiedPricePrediction = _pricePrediction2;
        } else {
            _modifiedPricePrediction = 0;
        }

        predictions[_staker] = StakeWithPrediction({
                stakedBalance: _amount,
                stakedTime: block.timestamp,
                amountWithdrawn: 0,
                lastWithdrawalTime: block.timestamp,
                pricePrediction1: _pricePrediction1,
                // if the staked amount was less than tier1 the pricePrediction2 would be 0
                pricePrediction2: _modifiedPricePrediction,
                difference: type(uint256).max,
                rank: type(uint256).max,
                totemPrizeWithdrawn: false,
                didUnstake: false
            });
    }

    function claimTotemWithStakingReward() external {
        uint256 totemStakingReturn = _getStakingReturn(_msgSender());

        if (totemStakingReturn > 0) {
            if (totemToken.balanceOf(address(rewardManager)) >= totemStakingReturn) {
                // all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), totemStakingReturn);
            }
        }
        
        // _wthdraw don't withdraw actually, and only update the array in the map
        _withdrawStakingReturn(_msgSender(), totemStakingReturn);
        

        if (isMatured) {

            // Users can't unstake until the pool matures
            uint256 stakedBalance = _getTotalStakedBalance(_msgSender());
            if (stakedBalance > 0) {
                totemToken.transfer(_msgSender(), stakedBalance);

                // _wthdraw don't withdraw actually, and only update the array in the map
                _withdrawStakedBalance(_msgSender());

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit WithdrawTotemReturn(_msgSender(), totemStakingReturn);
    }

    function purchaseIDOToken(uint256 _idoTokenAmount, uint256 _usdAmount) external {
        require(
            isMatured, 
            "0670 pool is not matured"
        );

        require(
            predictions[_msgSender()].rank <=25, 
            "0671 only winners can purchase"
        );

        uint256 idoAmount = idoWithdrawable(_msgSender());

        require(
            _idoTokenAmount <= idoAmount, 
            "0672 exceeds withdrawable"
        );

        uint256 usdAmount = usdPriceForIDO(_idoTokenAmount);

        require(
            _usdAmount == usdAmount, 
            "0673 usd amount is incorrect"
        );  

        uint256 totemPrize = _getTotemPrizeReward(_msgSender());

        require(
            idoTokenBank.getIDOTokenBalance(idoToken) >= _idoTokenAmount, 
            "0674 there is not enough ido tokne"
        );

        if (totemPrize > 0) {
                if (totemToken.balanceOf(address(rewardManager)) >= totemPrize) {
                // all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), totemPrize);
                }

                _withdrawTotemPrizeReward(_msgSender());

                emit WithdrawTotemPrize(_msgSender(), totemPrize);
        }

        usdToken.transferFrom(
            _msgSender(), 
            address(idoTokenBank), 
            _usdAmount
        );

        idoTokenBank.transferUserIDOToken(idoToken, _msgSender(), _idoTokenAmount);

        _withdrawIDOToken(_msgSender(), _idoTokenAmount);

        emit PurchaseIDOToken(_msgSender(), _usdAmount, _idoTokenAmount);

    }

    function lockPool() public onlyPoolCreator {
        _lockPool();
    }

    function _lockPool() internal {
        isLocked = true;

        emit PoolLocked();
    }

    function endIDOPrediction() external onlyPoolCreator {

        require(
            block.timestamp >= startDate + lockTime + maturityTime,
            "0660 Can't end pool before the maturity time"
        );
        
        require(
                idoTokenBank.getIDOTokenBalance(idoToken) > 0, 
                "0661 IDO tokens not available"
        );

        if (stakers.length > 0) {
            require(
                winnerStakers.length != 0,
                "0662 first should sort"
            );
        }

        require(
            idoIsStartDateSet, 
            "0663 the ido schedule is not set"
        );

        uint256 max = winnerStakers.length > 25 ? 25 : winnerStakers.length;
        for (uint256 i = 0; i < max; i++) {
            predictions[winnerStakers[i]].rank =
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

    // this function is not used anywhere
    function _getDifference(uint256 prediction)
        internal
        view
        returns (uint256)
    {
        if (prediction > maturingPrice) {
            return prediction.sub(maturingPrice);
        } else {
            return maturingPrice.sub(prediction);
        }
    }

    // the price should be got from a DEX tool
    function setIDOPrices(uint256 _maturingPrice, uint256 _purchasePrice, uint256 _priceDecimal) external onlyPoolCreator {

        require(
            !idoIsStartDateSet || block.timestamp <= idoStartDate,
            "0680 Can't change prices after ido start date"
        );
        
        dexDecimal = _priceDecimal;
        maturingPrice = _maturingPrice;
        purchasePrice = _purchasePrice;

    }

    function getStakers() 
        public 
        view 
        returns(address[] memory) 
    {
        address[] memory addrs = new address[](stakers.length);

        for (uint256 i = 0; i < stakers.length; i++) {
            addrs[i] = stakers[i];
        }

        return (addrs);
    }

    // TODO: waht is the exact number of winners
    function setWinnerStakers(address[25] calldata addrArray)
        external 
        onlyPoolCreator 
    {

        for (uint256 i = 0; i < 25; i++) {

            // the first 0 address means the other addresses are also 0 so they won't be checked
            if (addrArray[i] == address(0)) break;

            winnerStakers.push(
                addrArray[i]
            );

            idoRecipients[addrArray[i]] = IDOTokenSchedule({
                    totalAmount: idoTokenAmount,
                    amountWithdrawn: 0
                });
        }

        emit PoolSorted();
    }

    // getTotalStakedBalance return remained staked balance
    function _getTotalStakedBalance(address staker)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction memory userStake = predictions[staker];
        if (userStake.stakedBalance <= 0) return 0;

        uint256 totalStakedBalance = 0;

        if (!userStake.didUnstake) {
                totalStakedBalance = totalStakedBalance.add(
                    userStake.stakedBalance
                );
        }

        return totalStakedBalance;
    }

    function _getStakingReturn(address staker) 
        public 
        view 
        returns (uint256) 
    {
        StakeWithPrediction memory userStake = predictions[staker];
        if (userStake.stakedBalance <= 0) return 0;

        uint256 reward = _getStakingReturnPerStake(staker);
        return reward;
    }

    function _getStakingReturnPerStake(address staker)
        internal
        view
        returns (uint256)
    {
        StakeWithPrediction memory userStake = predictions[staker];

        if (userStake.didUnstake) {
            return 0;
        }

        uint256 maturityDate = startDate + lockTime + maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;

        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance

        uint256 rewardPerStake = _calcStakingReturn(
            stakeApr,
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

    function _withdrawStakingReturn(address staker, uint256 rewardPerStake) internal {
        StakeWithPrediction storage userStake = predictions[staker];
        if (userStake.stakedBalance <= 0) return;

        userStake.lastWithdrawalTime = block.timestamp;
        userStake.amountWithdrawn = userStake.amountWithdrawn.add(
            rewardPerStake
        );
    }

    function _withdrawStakedBalance(address staker) internal {
        StakeWithPrediction storage userStake = predictions[staker];
        if (userStake.stakedBalance <= 0) return;

        userStake.didUnstake = true;
    }

    function _withdrawTotemPrizeReward(address staker) internal {
        StakeWithPrediction storage userStake = predictions[staker];
        if (userStake.stakedBalance <= 0) return;

        userStake.totemPrizeWithdrawn = true;
    }

    function _withdrawIDOToken(address _staker, uint256 _amount) internal {
        IDOTokenSchedule storage userIDOSchedule = idoRecipients[_staker];
        if (userIDOSchedule.totalAmount <= 0) return;

        userIDOSchedule.amountWithdrawn = userIDOSchedule.amountWithdrawn.add(
            _amount
        );
    }

    function _getTotalTotemReward(address staker)
        public
        view
        returns (uint256, uint256)
    {
        // since in the getPrizeReward function the maturingPrice is used
        // so we got error if it would not be maturityDate
        uint256 totemPrizeReward = _getTotemPrizeReward(staker);
        uint256 stakingReturn = _getStakingReturn(staker);

        return (stakingReturn, totemPrizeReward);
    }

    function _getTotemPrizeReward(address staker)
        internal
        view
        returns (uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!isMatured) return 0;

        StakeWithPrediction memory userStake = predictions[staker];

        // users that don't stake don't get any prize also
        if (userStake.stakedBalance <= 0) return 0;

        uint256 reward = 0;

        // only calculate the prize amount for stakes that are not withdrawn yet
        if (!userStake.totemPrizeWithdrawn) {

            uint256 _totemAmount = _getTotemPrizeAmount(userStake.rank, userStake.stakedBalance);

            reward = reward.add(
                            _totemAmount
                );       
        }

        return reward;
    }

    function _getTotemPrizeAmount(uint256 _rank, uint256 _stakedAmount)
        internal
        view
        returns (uint256)
    {
        if (_rank <= 25) {
            // tier1 = 2500*(10**18)
            if (_stakedAmount > 2500*(10**18)) {
                return 2*totemPrizeAmount;
            } else {
                return totemPrizeAmount;
            }
        }

        return 0;
    } 


    // Returns the amount of ido tokens winner can withdraw
    function idoScheduledTotalAmount(address winner)
        public
        view
        virtual
        returns (uint256)
    {
        IDOTokenSchedule memory _idoTokenSchedule = idoRecipients[winner];
        if (
            !idoIsStartDateSet ||
            (_idoTokenSchedule.totalAmount == 0) ||
            (idoLockPeriods == 0 && idoReleasePeriods == 0) ||
            (block.timestamp < idoStartDate)
        ) {
            return 0;
        }

        uint256 endLock = idoWithdrawInterval.mul(idoLockPeriods);
        if (block.timestamp < idoStartDate.add(endLock)) {
            return 0;
        }

        uint256 _end = idoWithdrawInterval.mul(idoLockPeriods.add(idoReleasePeriods));
        if (block.timestamp >= idoStartDate.add(_end)) {
            return _idoTokenSchedule.totalAmount;
        }

        uint256 period =
            block.timestamp.sub(idoStartDate).div(idoWithdrawInterval) + 1;
        if (period <= idoLockPeriods) {
            return 0;
        }
        if (period >= idoLockPeriods.add(idoReleasePeriods)) {
            return _idoTokenSchedule.totalAmount;
        }

        uint256 lockAmount = _idoTokenSchedule.totalAmount.div(idoReleasePeriods);

        uint256 vestedAmount = period.sub(idoLockPeriods).mul(lockAmount);
        return vestedAmount;
    }

    function idoWithdrawable(address winner)
        public
        view
        returns (uint256)
    {
        return idoScheduledTotalAmount(winner).sub(idoRecipients[winner].amountWithdrawn);
    }

    function usdPriceForIDO(uint256 _idoAmount)
        public 
        view
        returns (uint256)
    {
        uint256 usdAmount = _idoAmount
            .mul(purchasePrice)
            .div(10**dexDecimal);

        return usdAmount;    
    }

    function setIDOScheduleParameters (
        uint256 _idoStartDate,
        uint256 _idoWithdrawInterval,
        uint256 _idoReleasePeriods,
        uint256 _idoLockPeriods
        ) 
        public 
        onlyPoolCreator 
        {
        // Only allow to change start time before the counting starts
        require(
            !isMatured || idoStartDate > block.timestamp,
            "0630 pool matured or ido started"
        );
        require(
            _idoStartDate > block.timestamp,
            "0630 start date is for past"
        );

        idoStartDate = _idoStartDate;
        idoIsStartDateSet = true;

        idoWithdrawInterval = _idoWithdrawInterval;
        idoReleasePeriods = _idoReleasePeriods;
        idoLockPeriods = _idoLockPeriods;

        emit IDOScheduleParametersSet(
            _idoStartDate,
            _idoWithdrawInterval,
            _idoReleasePeriods,
            _idoLockPeriods
        );
    }

    function withdrawStuckTokens(address _stuckToken, uint256 amount, address receiver)
        external
        onlyPoolCreator
    {
        require(
            _stuckToken != address(totemToken), 
            "0690 totems can not be transfered"
        );
        IERC20 stuckToken = IERC20(_stuckToken);
        stuckToken.transfer(receiver, amount);
    }

    

    modifier onlyPoolCreator {
        require(
            _msgSender() == poolCreator,
            "0600 caller is not a pool creator"
        );
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "../ITotemToken.sol";
import "../Role/Operator.sol";
import "../Role/Rewarder.sol";


interface IIDOTokenBank {

    function addIDOPredictionWithToken(address _poolAddress, address _idoToken) external;

    function withdrawTokens(address _stuckToken, uint256 amount, address receiver) external;

    function transferUserIDOToken(address _idoToken, address _user, uint256 _amount) external;

    function getIDOTokenBalance(address _idoToken) external returns (uint256);
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILocker.sol";
import "./BasisPoints.sol";

// TODO: add an interface for this to add the interface instead of 
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILocker.sol";
import "./BasisPoints.sol";

// TODO: add an interface for this to add the interface instead of 
interface ITotemToken is ILockerUser, IERC20 {
    
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
}

