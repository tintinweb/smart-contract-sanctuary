/**
 *Submitted for verification at polygonscan.com on 2021-10-03
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED


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

struct RewardData {
    address token;
    uint256 amount;
}
struct LockedBalance {
    uint256 amount;
    uint256 unlockTime;
}

// Interface for EPS Staking contract - http://ellipsis.finance/
interface IMultiFeeDistribution {

    /* ========== VIEWS ========== */
    function totalSupply() external view returns (uint256);
    function lockedSupply() external view returns (uint256);

    function rewardPerToken(address _rewardsToken) external view returns (uint256);

    function getRewardForDuration(address _rewardsToken) external view returns (uint256);

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account) external view returns (RewardData[] memory);

    // Total balance of an account, including unlocked, locked and earned tokens
    function totalBalance(address user) view external returns (uint256 amount);

    // Total withdrawable balance for an account to which no penalty is applied
    function unlockedBalance(address user) view external returns (uint256 amount);

    // Final balance received and penalty balance paid by user upon calling exit
    function withdrawableBalance(address user) view external returns (uint256 amount, uint256 penaltyAmount);

    // Information on the "earned" balances of a user
    // Earned balances may be withdrawn immediately for a 50% penalty
    function earnedBalances(address user) view external returns (uint256 total, LockedBalance[] memory earningsData);

    // Information on a user's locked balances
    function lockedBalances(address user) view external returns (uint256 total, uint256 unlockable, uint256 locked, LockedBalance[] memory lockData);

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Mint new tokens
    // Minted tokens receive rewards normally but incur a 50% penalty when
    // withdrawn before lockDuration has passed.
    function mint(address user, uint256 amount) external;

    // Withdraw full unlocked balance and claim pending rewards
    function exit() external;

    // Withdraw all currently locked tokens where the unlock time has passed
    function withdrawExpiredLocks() external;

    // Claim all pending staking rewards (both BUSD and EPS)
    function getReward() external;

    // Stake tokens to receive rewards
    // Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
    function stake(uint256 amount, bool lock) external;
    
    // Withdraw staked tokens
    // First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
    // incurs a 50% penalty which is distributed based on locked balances.
    function withdraw(uint256 amount) external;
    
    /* ========== ADMIN CONFIGURATION ========== */

    // Used to let FeeDistribution know that _rewardsToken was added to it
    function notifyRewardAmount(address _rewardsToken, uint256 rewardAmount) external;
}

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


//A Jar is a contract that users deposit funds into.
//Jar contracts are paired with a strategy contract that interacts with the pool being farmed.
interface IJar {
    function token() external view returns (IERC20);

    function getRatio() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function depositAll() external;

    function deposit(uint256) external;

    //function depositFor(address user, uint256 amount) external;

    function withdrawAll() external;

    //function withdraw(uint256) external;

    //function earn() external;

    function strategy() external view returns (address);

    //function decimals() external view returns (uint8);

    //function getLastTimeRestaked(address _address) external view returns (uint256);

    //function notifyReward(address _reward, uint256 _amount) external;

    //function getPendingReward(address _user) external view returns (uint256);
}

//Vaults are jars that emit ADDY rewards.
interface IVault is IJar {

    function getBoost(address _user) external view returns (uint256);

    function getPendingReward(address _user) external view returns (uint256);

    function getLastDepositTime(address _user) external view returns (uint256);

    function getTokensStaked(address _user) external view returns (uint256);

    function totalShares() external view returns (uint256);

    function getRewardMultiplier() external view returns (uint256);   

    function rewardAllocation() external view returns (uint256);   

    function totalPendingReward() external view returns (uint256);   

    function withdrawPenaltyTime() external view returns (uint256);  

    function withdrawPenalty() external view returns (uint256);   
    
    function increaseRewardAllocation(uint256 _newReward) external;

    function setWithdrawPenaltyTime(uint256 _withdrawPenaltyTime) external;

    function setWithdrawPenalty(uint256 _withdrawPenalty) external;

    function setRewardMultiplier(uint256 _rewardMultiplier) external;
}
interface IMinter {
    function isMinter(address) view external returns(bool);
    function amountAddyToMint(uint256 ethProfit) view external returns(uint256);
    function mintFor(address user, address asset, uint256 amount) external;

    function addyPerProfitEth() view external returns(uint256);

    function setMinter(address minter, bool canMint) external;
}
interface IBoostHandler {

  //Returns ADDY earning boost based on user's veADDY, boost should be divided by 1e18
  function getBoost(address _user, address _vaultAddress) external view returns (uint256);

  //Returns ADDY earning boost based on user's veADDY if the user was to stake in vaultAddress, boost is divided by 1e18
  function getBoostForValueStaked(address _user, address _vaultAddress, uint256 valueStaked) external view returns (uint256);

  //Returns the value in USD for which a user's ADDY earnings are doubled
  function getDoubleLimit(address _user) external view returns (uint256 doubleLimit);

  //Returns the total VeAddy from all sources
  function getTotalVeAddy(address _user) external view returns (uint256);

  //Returns the total VeAddy from locking ADDY in the locked ADDY staking contract
  function getVeAddyFromLockedStaking(address _user) external view returns (uint256);

  function setFeeDist(address _feeDist) external;
}
interface IVaultDataStorage {
  function addSimilarVault(address vaultAddress, address otherAddress) external;
  function clearSimilarVaults(address vaultAddress) external;
  function getSimilarVaults(address vaultAddress) external view returns (address[] memory);
}

interface ILockedAddyVault {
    function balanceOf(address _user) external view returns (uint256);
    function getEndingTimestamp(address _user) external view returns (uint256);
    function getRatio() external view returns (uint256);
}
//Different than the existing price calculator
interface IPriceCalculatorUSD {
    //Returns price of an asset with precision = 18 decimals
    function unsafeValueOfAsset(address asset, uint amount) external view returns (uint valueInETH, uint valueInUSD);
}
interface IAprCalculator {
    function getApr(address calculator, address _vaultAddress) external view returns (uint256);
}
interface IBoosted {
    function boostHandler() external view returns (address);
}

contract BoostHandler is Ownable, IBoostHandler {
    using SafeMath for uint256;

    uint256 public constant MAX_DURATION = 1460 days; //4 years
    uint256 public constant MAX_BOOST = 1e18; //100%

    address public multiFeeDist = 0x920f22E1e5da04504b765F8110ab96A20E6408Bd;
    address public lockedStakingPlus = 0xC5bCD23f21B6288417eB6C760F8AC0fBb4bb8a56;
    address public lockedStakingBasic = 0xfFD82F81513b207fB9D7D7835e178B6193f2cA96;
    address public minter = 0xAAE758A2dB4204E1334236Acd6E6E73035704921;

    address public calculator = 0x47A4EB1a75abdB4f9FD1aE8eF11945f3B352E01F;
    //address public stablecoinCalculator = 0x85eA5d3fDDCe5009fb69A8fb445b80314c7B5fB9;

    address public aprCalcAggregator = 0x6E97FBc2718648D62180D50f525802C2d32EF50f;

    address public vaultDataWrapper = 0x87Fa4456898819373D2446E463DBB5602B3641F6;

    // **** Views **** //

    function getBoost(address _user, address _vaultAddress) external override view returns (uint256) {
        //Show user a warning if the boost would be 0, if boost is 0 when their veADDY is > 0?
        uint256 valueOfUserStakeUSD = getUserValueStaked(_user, _vaultAddress);
        if(valueOfUserStakeUSD == 0) {
            return 0;
        }

        valueOfUserStakeUSD = valueOfUserStakeUSD.add(getTotalValueStakedInSimilarVaults(_user, _vaultAddress));
        uint256 veAddy = getTotalVeAddy(_user);
        if(veAddy == 0) {
            return 0;
        }

        //boost = doubleLimit / valueStaked
        //if doubleLimit >= valueStaked, then boost is max boost, which is +100%
        uint256 doubleLimit = getDoubleLimitModified(_user, _vaultAddress);
        if(doubleLimit >= valueOfUserStakeUSD) {
            return MAX_BOOST;
        }

        uint256 valueBoosted = doubleLimit.mul(10 ** 18);
        uint256 boost = valueBoosted.div(valueOfUserStakeUSD);
        if(boost > MAX_BOOST) { //shouldn't be possible, but just in case
            return MAX_BOOST;
        }
        return boost;
    }

    //Returns ADDY earning boost based on user's veADDY if the user was to stake in vaultAddress, boost is divided by 1e18
    function getBoostForValueStaked(address _user, address _vaultAddress, uint256 valueStaked) external override view returns (uint256) {
        //Show user a warning if the boost would be 0, if boost is 0 when their veADDY is > 0?
        uint256 valueOfUserStakeUSD = getUserValueStaked(_user, _vaultAddress);
        valueOfUserStakeUSD = valueOfUserStakeUSD.add(getTotalValueStakedInSimilarVaults(_user, _vaultAddress)).add(valueStaked);

        uint256 veAddy = getTotalVeAddy(_user);
        if(veAddy == 0) {
            return 0;
        }

        uint256 doubleLimit = getDoubleLimitModified(_user, _vaultAddress);
        if(doubleLimit >= valueOfUserStakeUSD) {
            return MAX_BOOST;
        }

        uint256 valueBoosted = doubleLimit.mul(10 ** 18);
        uint256 boost = valueBoosted.div(valueOfUserStakeUSD);
        if(boost > MAX_BOOST) { //shouldn't be possible, but just in case
            return MAX_BOOST;
        }
        return boost;
    }

    function getDoubleLimitModified(address _user, address _vaultAddress) internal view returns (uint256) {
        uint256 doubleLimit = getDoubleLimit(_user);
        uint256 apr = IAprCalculator(aprCalcAggregator).getApr(calculator, _vaultAddress);

        /*
        If the APR is above:
        50%: -10% boosting power
        100%: -20% boosting power
        200%: -30% boosting power
        300%: -40% boosting power
        500%: -50% boosting power
        */

        if(apr >= 5 * 10 ** 18) {
            return doubleLimit.div(2);
        }
        if(apr >= 3 * 10 ** 18) {
            return doubleLimit.mul(60).div(100);
        }
        if(apr >= 2 * 10 ** 18) {
            return doubleLimit.mul(70).div(100);
        }
        if(apr >= 1 * 10 ** 18) {
            return doubleLimit.mul(80).div(100);
        }
        if(apr >= 5 * 10 ** 17) {
            return doubleLimit.mul(90).div(100);
        }
        return doubleLimit;
    }

    function getUserValueStaked(address _user, address _vaultAddress) public view returns (uint256) {
        uint256 userBal = IVault(_vaultAddress).balanceOf(_user);
        if(userBal == 0) {
            return 0;
        }

        userBal = userBal.mul(IJar(_vaultAddress).getRatio()).div(10 ** 18);

        (, uint256 valueOfUserStakeUSD) = IPriceCalculatorUSD(calculator).unsafeValueOfAsset(address(IVault(_vaultAddress).token()), userBal);
        if(valueOfUserStakeUSD == 0) {
            return 0;
        }
        return valueOfUserStakeUSD;
    }

    //Returns the total value staked in vaults similar to _vaultAddress
    //i.e. if _vaultAddress is a WETH/WMATIC vault then it returns the total value the user has staked in all WETH/WMATIC vaults
    function getTotalValueStakedInSimilarVaults(address _user, address _vaultAddress) public view returns (uint256 totalStaked) {
        address[] memory similarVaults = IVaultDataStorage(vaultDataWrapper).getSimilarVaults(_vaultAddress);

        for (uint i = 0; i < similarVaults.length; i++) {
            if(similarVaults[i] != address(0) && similarVaults[i] != _vaultAddress && isBoosted(similarVaults[i])) {
                totalStaked = totalStaked.add(getUserValueStaked(_user, similarVaults[i]));
            }
        }
    }

    //Returns the value in USD for which a user's ADDY earnings are doubled
    //Limit = veADDY * boost weight / 2
    function getDoubleLimit(address _user) public override view returns (uint256 doubleLimit) {
        //Boost weight is influenced by total market cap, emissions rate, total supply
        return getTotalVeAddy(_user).mul(IMinter(minter).addyPerProfitEth().div(2));
    }

    function getTotalVeAddy(address _user) public override view returns (uint256) {
        return getVeAddyFromLockedStaking(_user).add(getVeAddyFromLockedStakingBasic(_user));
    }

    //Returns veADDY from the "locked staking plus" contract (LockedAddyVault)
    function getVeAddyFromLockedStaking(address _user) public override view returns (uint256 veAddy) {
        uint256 endingTimestampPlus = ILockedAddyVault(lockedStakingPlus).getEndingTimestamp(_user);
        if(endingTimestampPlus > now) {
            //1 veAddy = 4 year lock, boost degrades over time
            uint256 diff = endingTimestampPlus.sub(now);
            uint256 userAddyLocked = ILockedAddyVault(lockedStakingPlus).balanceOf(_user);
            uint256 ratio = ILockedAddyVault(lockedStakingPlus).getRatio();
            veAddy = veAddy.add(userAddyLocked.mul(diff).div(MAX_DURATION).mul(ratio).div(10 ** 18));
        }
    }

    //Returns veADDY from the "locked staking basic" contract (StakingDualRewards)
    //The "locked staking basic" contract has 50% of the weight of the "plus" contract
    function getVeAddyFromLockedStakingBasic(address _user) public view returns (uint256 veAddy) {
        uint256 endingTimestampBasic = ILockedAddyVault(lockedStakingBasic).getEndingTimestamp(_user);
        if(endingTimestampBasic > now) {
            //1 veAddy = 4 year lock, boost degrades over time
            uint256 diff = endingTimestampBasic.sub(now);
            uint256 userAddyLocked = ILockedAddyVault(lockedStakingBasic).balanceOf(_user);
            veAddy = veAddy.add(userAddyLocked.mul(diff).div(MAX_DURATION)).div(2);
        }
    }

    function isBoosted(address _vaultAddress) public view returns (bool) {
        try IBoosted(_vaultAddress).boostHandler() {
            return IBoosted(_vaultAddress).boostHandler() != address(0);
        }
        catch {
            return false;
        }
    }

    // **** State Mutations ****

    //used if a token migration happens, which would require a new fee dist contract
    function setFeeDist(address _feeDist) public override onlyOwner {
        require(_feeDist != address(0));
        multiFeeDist = _feeDist;
    }

    function setLockedStakingVault(address _address) public onlyOwner {
        require(_address != address(0));
        lockedStakingPlus = _address;
    }

    function setLockedStakingBasic(address _address) public onlyOwner {
        require(_address != address(0));
        lockedStakingBasic = _address;
    }

    function setCalculator(address _calculator) public onlyOwner {
        require(_calculator != address(0));
        calculator = _calculator;
    }

    function setAprCalcAggregator(address _aggregator) public onlyOwner {
        require(_aggregator != address(0));
        aprCalcAggregator = _aggregator;
    }

    function setVaultDataWrapper(address _wrapper) public onlyOwner {
        require(_wrapper != address(0));
        vaultDataWrapper = _wrapper;
    }
}