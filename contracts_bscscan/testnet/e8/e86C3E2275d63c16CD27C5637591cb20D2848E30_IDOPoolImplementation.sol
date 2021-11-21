// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDOPoolStorageStructure.sol";

contract IDOPoolImplementation is
    IDOPoolStorageStructure
{
    using BasisPoints for uint256;
    using SafeMath for uint256;
    using CalculateRewardLib for *;
    using ClaimRewardLib for *;
    using PurchaseIDOLib for *;

    modifier onlyPoolCreator {
        require(
            _msgSender() == poolCreator,
            "0600 caller is not a pool creator"
        );
        _;
    }

    event Stake(address indexed user, uint256 amount, uint256 pricePrediction1, uint256 pricePrediction2);
    event WithdrawReturn(address indexed user, uint256 stakingReturn);
    event WithdrawPrize(address indexed user, uint256 prize);
    event Unstake(address indexed user, uint256 amount);
   
    event PayUSDForIDOToken(address indexed user, uint256 usdAmount, uint256 idoTokenAmount);
    event WithdrawIDOToken(address indexed user, uint256 idoTokenAmount);

    event IDOScheduleParametersSet(uint256 startDate, uint256 withdrawInterval, uint256 releasePeriods, uint256 lockPeriods);

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

    function stake(uint256 _amount, uint256 _pricePrediction1, uint256 _pricePrediction2) external {
        
        require(
            isActive && block.timestamp > launchDate,
            "0613 pool is not active"
        );

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
            predictions[_msgSender()].stakedBalance == 0, 
            "0614 this user is already staked"
        );

        uint256 limitRange = sizeAllocation.mulBP(sizeLimitRangeRate);

        require(
            // the total amount of stakes can exceed size allocation by 5%
            totalStaked.add(_amount) <= sizeAllocation.add(limitRange),
            "0612 Can't stake above size allocation"
        );

        uint256 stakeTaxAmount = 0;
        uint256 taxRate = 0;
        // now the stakeTaxAmount is the staking tax and the _amount is initial amount minus the staking tax
        (stakeTaxAmount, _amount) = _getStakingTax(_amount, taxRate);

        sparksToken.transferFrom(
            _msgSender(),
            address(this),
            (_amount + stakeTaxAmount)
        );

        // TODO: which address must be used for staking tax
        if (stakeTaxAmount > 0)
            sparksToken.transfer(sparksToken.getTaxactionWallet(), stakeTaxAmount);

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
                didPrizeWithdrawn: false,
                didUnstake: false
            });
    }


    function claimWithStakingReward() external {
        uint256 stakingReturn = 
            ClaimRewardLib.getStakingReturn(
                predictions[_msgSender()],
                lps
            );

        if (stakingReturn > 0) {
            if (sparksToken.balanceOf(address(rewardManager)) >= stakingReturn) {
                // all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), stakingReturn);
            }
        }
        
        // _wthdraw don't withdraw actually, and only update the array in the map
        ClaimRewardLib.withdrawStakingReturn(stakingReturn, predictions[_msgSender()]);
        

        if (isMatured) {

            // Users can't unstake until the pool matures
            uint256 stakedBalance = CalculateRewardLib.getTotalStakedBalance(predictions[_msgSender()]);
            if (stakedBalance > 0) {
                sparksToken.transfer(_msgSender(), stakedBalance);

                // _wthdraw don't withdraw actually, and only update the array in the map
                ClaimRewardLib.withdrawStakedBalance(predictions[_msgSender()]);

                emit Unstake(_msgSender(), stakedBalance);
            }
        }

        emit WithdrawReturn(_msgSender(), stakingReturn);
    }

    function purchaseIDOToken() external {
        require(
            isMatured, 
            "0670 pool is not matured"
        );

        uint256 idoTotalAmount = idoRecipients[_msgSender()].totalAmount;

        require(
            idoTotalAmount > 0, 
            "0671 only winners can purchase"
        );

        uint256 idoAmount = idoWithdrawable(_msgSender());

        uint256 totalPrize = ClaimRewardLib.getPrize(
            predictions[_msgSender()],
            lps,
            prizeRewardRates
        );

        require(
            idoTokenBank.getIDOTokenBalance(idoToken) >= idoAmount, 
            "0674 there is not enough ido token"
        );

        if (!idoRecipients[_msgSender()].isUSDPaid) {
            uint256 totalUSDAmount = usdPriceForIDO(
                idoTotalAmount
            );

            usdToken.transferFrom(
                _msgSender(), 
                address(idoTokenBank), 
                totalUSDAmount
            );

            PurchaseIDOLib.payUSDForIDOToken(idoRecipients[_msgSender()]);

            emit PayUSDForIDOToken(_msgSender(), totalUSDAmount, idoTotalAmount);
        }

        if (idoAmount > 0) {
            idoTokenBank.transferUserIDOToken(idoToken, _msgSender(), idoAmount);

            PurchaseIDOLib.withdrawIDOToken(idoAmount, idoRecipients[_msgSender()]);

            emit WithdrawIDOToken(_msgSender(), idoAmount);
        }

        if (totalPrize > 0) {
               
            if (sparksToken.balanceOf(address(rewardManager)) >= totalPrize) {
                // all transfers should be in require, rewardUser is using require
                rewardManager.rewardUser(_msgSender(), totalPrize);
            }

            ClaimRewardLib.withdrawPrize(predictions[_msgSender()]);

            emit WithdrawPrize(_msgSender(), totalPrize);
        }
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
            block.timestamp >= launchDate + lockTime + maturityTime,
            "0660 Can't end pool before the maturity time"
        );
        
        // maybe the bank doesn't need to have IDO token at the maturity date
        // require(
        //         idoTokenBank.getIDOTokenBalance(idoToken) > 0, 
        //         "0661 IDO tokens not available"
        // );

        if (stakers.length > 0) {
            require(
                winnerStakers.length != 0,
                "0662 first should sort"
            );
        }

        require(
            isIdoScheduleSettled, 
            "0663 the ido schedule is not set"
        );

        uint256 max = winnerStakers.length > 25 ? 25 : winnerStakers.length;
        for (uint256 i = 0; i < max; i++) {

            StakeWithPrediction storage userStake = predictions[winnerStakers[i]];

            userStake.rank = i + 1;

            uint256 _modifiedIdoTokenAmount;

            // tier2 = 10000*(10**18)
            if (userStake.stakedBalance > 10000*(10**18)) {
                _modifiedIdoTokenAmount = 2*idoTokenAmount;
            } else {
                _modifiedIdoTokenAmount = idoTokenAmount;
            }

            idoRecipients[winnerStakers[i]] = IDOTokenSchedule({
                    isUSDPaid: false,
                    totalAmount: _modifiedIdoTokenAmount,
                    amountWithdrawn: 0
                });    
        }

        // there is possibility that the size allocation is not reached 
        // and the isLocked is not set to ture
        isLocked = true;
        isMatured = true;

        lps.isMatured = true;

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


    function setIDOMaxPriceTillMaturity(uint256 _maxPriceTillMaturity) external onlyPoolCreator {

        require(
            !isIdoScheduleSettled || block.timestamp <= idoScheduleStartDate,
            "0680 Can't change prices after ido start date"
        );
        
        maxPriceTillMaturity = _maxPriceTillMaturity;
        lps.maxPriceTillMaturity = _maxPriceTillMaturity;

    }

    function setIDOPurchasePrice(uint256 _purchasePrice) external onlyPoolCreator {

        require(
            !isIdoScheduleSettled || block.timestamp <= idoScheduleStartDate,
            "0680 Can't change prices after ido start date"
        );
        
        purchasePrice = _purchasePrice;
        lps.purchasePrice = _purchasePrice;

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
    function setWinnerStakers(address[25] calldata addrArray, uint256 _idoTokenAmount)
        external 
        onlyPoolCreator 
    {

        idoTokenAmount = _idoTokenAmount;

        if(winnerStakers.length != 0) {
            delete winnerStakers;
        }

        for (uint256 i = 0; i < 25; i++) {

            // the first 0 address means the other addresses are also 0 so they won't be checked
            if (addrArray[i] == address(0)) break;

            winnerStakers.push(
                addrArray[i]
            );
        }

        emit PoolSorted();
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
            !isIdoScheduleSettled ||
            (_idoTokenSchedule.totalAmount == 0) ||
            (idoLockPeriods == 0 && idoReleasePeriods == 0) ||
            (block.timestamp < idoScheduleStartDate)
        ) {
            return 0;
        }

        uint256 endLock = idoWithdrawInterval.mul(idoLockPeriods);
        if (block.timestamp < idoScheduleStartDate.add(endLock)) {
            return 0;
        }

        uint256 _end = idoWithdrawInterval.mul(idoLockPeriods.add(idoReleasePeriods));
        if (block.timestamp >= idoScheduleStartDate.add(_end)) {
            return _idoTokenSchedule.totalAmount;
        }

        uint256 period =
            block.timestamp.sub(idoScheduleStartDate).div(idoWithdrawInterval) + 1;
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

        usdAmount = usdAmount.addBP(idoAllocationFee);

        return usdAmount;    
    }

    function setIDOScheduleParameters (
        uint256 _idoScheduleStartDate,
        uint256 _idoWithdrawInterval,
        uint256 _idoReleasePeriods,
        uint256 _idoLockPeriods
        ) 
        public 
        onlyPoolCreator 
        {
        // Only allow to change start time before the counting starts
        require(
            !isMatured || idoScheduleStartDate > block.timestamp,
            "0630 pool matured or ido schedule start is reached"
        );
        require(
            _idoScheduleStartDate > block.timestamp,
            "0630 start date is for past"
        );

        idoScheduleStartDate = _idoScheduleStartDate;
        isIdoScheduleSettled = true;

        idoWithdrawInterval = _idoWithdrawInterval;
        idoReleasePeriods = _idoReleasePeriods;
        idoLockPeriods = _idoLockPeriods;

        emit IDOScheduleParametersSet(
            _idoScheduleStartDate,
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
            _stuckToken != address(sparksToken), 
            "0690 totems can not be transfered"
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
            sparksToken.transfer(_msgSender(), stakedBalance);

            // _wthdraw don't withdraw actually, and only update the array in the map
            ClaimRewardLib.withdrawStakedBalance(predictions[_msgSender()]);

            emit Unstake(_msgSender(), stakedBalance);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Note that we must use upgradeable forms of these contracts, otherwise we must set our contracts
// as abstract because the top level contract which is StakingPoolProxy does not have a constructor
// to call their constructors in it, so to avoid that error we must use upgradeable parent contrats
// their code size doesn't have noticable overheads
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Interfaces/IRewardManager.sol";
import "../Interfaces/IIDOTokenBank.sol";
import "../Interfaces/ISparksToken.sol";

import "../Libraries/BasisPoints.sol";
import "../Libraries/CalculateRewardLib.sol";
import "../Libraries/ClaimRewardLib.sol";
import "../Libraries/PurchaseIDOLib.sol";

contract IDOPoolStorageStructure is
    OwnableUpgradeable
{

    address public idoPoolImplementation;
    address public poolCreator;

    // declared for passing params to libraries
    struct LibParams {
        uint256 launchDate;
        uint256 lockTime;
        uint256 maturityTime;
        uint256 maxPriceTillMaturity;
        uint256 purchasePrice;
        uint256 prizeAmount;
        uint256 stakeApr;
        uint256 idoAllocationFee;
        bool isMatured;
    }
    LibParams public lps;

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction1;
        uint256 pricePrediction2;
        uint256 difference;
        uint256 rank;
        bool didPrizeWithdrawn;
        bool didUnstake;
    }

    struct IDOTokenSchedule {
        bool isUSDPaid;
        uint256 totalAmount; // Total amount of tokens can be purchased.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    struct PrizeRewardRate {
        uint256 rank;
        uint256 percentage;
    }

    // it wasn't possible to use totem token interface since we use taxRate variable
    ISparksToken public sparksToken;
    IRewardManager public rewardManager;
    IIDOTokenBank public idoTokenBank;
    IERC20 public usdToken;
    address public idoToken;

    string public poolType;

        // 100 means 1%
    uint256 public constant sizeLimitRangeRate = 500;
    
    // the default dexDecimal is 8 but can be modified in setIDOPrices
    uint256 public constant dexDecimal = 8;

    uint256 public launchDate;
    uint256 public lockTime;
    uint256 public maturityTime;
    uint256 public sizeAllocation; // total TOTM can be staked
    uint256 public stakeApr; // the annual return rate for staking TOTM

    // prizeUint (x) is the unit of TOTM that will be given to winners 
    // and multiply by 2 if user have staked more than an amount
    uint256 public prizeAmount;
    uint256 public idoTokenAmount;

    uint256 public stakeTaxRate;
    uint256 public idoAllocationFee;
    uint256 public minimumStakeAmount;

    uint256 public totalStaked;

    // matruing price and purchase price should have same decimals
    uint256 public maxPriceTillMaturity;
    uint256 public purchasePrice;

    uint256 public idoScheduleStartDate;
    bool public isIdoScheduleSettled;
    uint256 public idoWithdrawInterval; // Amount of time in seconds between withdrawal periods.
    uint256 public idoReleasePeriods; // Number of periods from start release until done.
    uint256 public idoLockPeriods; // Number of periods before start release.

    bool public isAnEmergency;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;

    
    address[] public stakers;
    address[] public winnerStakers;
    PrizeRewardRate[] public prizeRewardRates;

    mapping(address => StakeWithPrediction) public predictions;
    mapping(address => IDOTokenSchedule) public idoRecipients;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: provide an interface so IDO-prediction can work with that
interface IRewardManager {

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IIDOTokenBank {

    function addIDOPredictionWithToken(address _poolAddress, address _idoToken) external;

    function withdrawTokens(address _stuckToken, uint256 amount, address receiver) external;

    function transferUserIDOToken(address _idoToken, address _user, uint256 _amount) external;

    function getIDOTokenBalance(address _idoToken) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: add an interface for this to add the interface instead of 
interface ISparksToken {
    
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

    function getTaxactionWallet() external returns (address);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
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

import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library CalculateRewardLib {

    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant dexDecimal = 8;

    function calcStakingReturn(uint256 totalRewardRate, uint256 timeDuration, uint256 totalStakedBalance) 
        public
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

    // getTotalStakedBalance return remained staked balance
    function getTotalStakedBalance(IDOPoolStorageStructure.StakeWithPrediction storage _userStake)
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance <= 0) return 0;

        uint256 totalStakedBalance = 0;

        if (!_userStake.didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                _userStake.stakedBalance
            );
        }

        return totalStakedBalance;
    }


    ////////////////////////// internal functions /////////////////////
    function _getPrizeAmount(
        uint256 _rank,
        IDOPoolStorageStructure.LibParams storage _lps,
        IDOPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        internal
        view
        returns (uint256)
    {

        for (uint256 i = 0; i < _prizeRewardRates.length; i++) {
            if (_rank <= _prizeRewardRates[i].rank) {
                return (_lps.prizeAmount).mulBP(_prizeRewardRates[i].percentage);
            }
        }

        return 0;
    } 

    function _getStakingReturnPerStake(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake, 
        IDOPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {

        if (_userStake.didUnstake) {
            return 0;
        }

        uint256 maturityDate = 
            _lps.launchDate + 
            _lps.lockTime + 
            _lps.maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;


        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance
        uint256 rewardPerStake = calcStakingReturn(
            _lps.stakeApr,
            timeTo.sub(_userStake.stakedTime),
            _userStake.stakedBalance
        );

        rewardPerStake = rewardPerStake.sub(_userStake.amountWithdrawn);

        return rewardPerStake;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library ClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;


    ////////////////////////// public functions /////////////////////
    function getStakingReturn(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake,
        IDOPoolStorageStructure.LibParams storage _lps
    )
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance == 0) return 0;

        uint256 reward = CalculateRewardLib._getStakingReturnPerStake(_userStake, _lps);

        return reward;
    }

    function withdrawStakingReturn(
        uint256 _rewardPerStake,
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.lastWithdrawalTime = block.timestamp;
        _userStake.amountWithdrawn = _userStake.amountWithdrawn.add(
            _rewardPerStake
        );
    }

    function withdrawPrize(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    )
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didPrizeWithdrawn = true;
    }

    function withdrawStakedBalance(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didUnstake = true;
    }

    function getPrize(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake, 
        IDOPoolStorageStructure.LibParams storage _lps,
        IDOPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!_lps.isMatured) return 0;

        // users that don't stake don't get any prize also
        if (_userStake.stakedBalance <= 0) return 0;

        // uint256 maturingBTCPrizeAmount =
        //     (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        // uint256 btcReward = 0;

        // only calculate the prize amount for stakes that are not withdrawn yet
        if (!_userStake.didPrizeWithdrawn) {

            uint256 _totemAmount = CalculateRewardLib._getPrizeAmount(_userStake.rank, _lps, _prizeRewardRates);

            reward = reward.add(
                        _totemAmount
                );      
        }

        return reward;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library PurchaseIDOLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;


    ////////////////////////// public functions /////////////////////
    function payUSDForIDOToken(
        IDOPoolStorageStructure.IDOTokenSchedule storage _winnerIDOSchedule
    ) 
        public
    {
        if (_winnerIDOSchedule.isUSDPaid) return;

        _winnerIDOSchedule.isUSDPaid = true;
    }

    function withdrawIDOToken(
        uint256 _amount,
        IDOPoolStorageStructure.IDOTokenSchedule storage _winnerIDOSchedule
    ) 
        public
    {
        if (_winnerIDOSchedule.totalAmount <= 0) return;

        _winnerIDOSchedule.amountWithdrawn = _winnerIDOSchedule.amountWithdrawn.add(
            _amount
        );
    }
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