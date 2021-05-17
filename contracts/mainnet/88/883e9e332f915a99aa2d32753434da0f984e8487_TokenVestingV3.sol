// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
// import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IStakingPoolsVesting.sol";
import "./interfaces/IUniswapV2RouterMinimal.sol";
import "./interfaces/IERC20Minimal.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

// import "hardhat/console.sol";
contract TokenVestingV3 is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Schedule {
        // the total amount that has been vested
        uint256 totalAmount;
        // the total amount that has been claimed
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        uint256 cliffWeeks;
        // amount of vesting kko staked in the kko staking pool
        uint256 totalStakedKko;
        // the amount of eth lp tokens owned by the account
        uint256 kkoEthLpTokens;
        // tracks the amount of kko tokens that are in active LP
        uint256 kkoInLp;
    }

    mapping (address => mapping(uint => Schedule)) public schedules;
    mapping (address => uint) public numberOfSchedules;

    modifier onlyConfigured() {
        require(configured, "Vesting: only configured"); 
        _;
    }

    /// @dev total kko locked in the contract
    uint256 public valueLocked;
    IERC20Minimal private kko;
    IERC20Minimal private lpToken;
    IUniswapV2RouterMinimal private router;
    IStakingPoolsVesting private stakingPools;
    bool private configured;
    uint256 public kkoPoolsId;
    uint256 public kkoLpPoolsId;
    event Claim(uint amount, address claimer);

    function initialize(address _kko, address _lpToken, address _router) public initializer {
        OwnableUpgradeable.__Ownable_init();
        kko = IERC20Minimal(_kko);
        lpToken = IERC20Minimal(_lpToken);
        router = IUniswapV2RouterMinimal(_router);
        // approve the router to spend kko
        require(kko.approve(_router, 2**256-1));
        require(lpToken.approve(_router, 2**256-1));
    }

    fallback() external payable {}

    function setStakingPools(address _contract, uint256 _kkoPoolsId, uint256 _kkoLpPoolsId) external onlyOwner {
        require(configured == false, "must not be configured");
        stakingPools = IStakingPoolsVesting(_contract);
        kkoPoolsId = _kkoPoolsId;
        kkoLpPoolsId = _kkoLpPoolsId;
        configured = true;
        // todo(bonedaddy): is this optimal? not sure
        // approve max uint256 value
        require(kko.approve(_contract, 2**256-1));
        require(lpToken.approve(_contract, 2**256-1));
    }

    /**
    * @notice Sets up a vesting schedule for a set user.
    * @notice at the moment this only supports staking of the kko staking
    * @dev adds a new Schedule to the schedules mapping.
    * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
    *                the cliff period.
    * @param amount the amount of tokens being vested for the user.
    * @param cliffWeeks the number of weeks that the cliff will be present at.
    * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
    */
    function setVestingSchedule(
        address account,
        uint256 amount,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        bool danger
    ) public onlyOwner onlyConfigured {
        if (danger == false) {
            require(
                kko.balanceOf(address(this)).sub(valueLocked) >= amount,
                "Vesting: amount > tokens leftover"
            );
        }

        require(
            vestingWeeks >= cliffWeeks,
            "Vesting: cliff after vesting period"
        );
        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            block.timestamp,
            block.timestamp.add(cliffWeeks * 1 weeks),
            block.timestamp.add(vestingWeeks * 1 weeks),
            cliffWeeks,
            0, // amount staked in kko pool
            0, // amount of lp tokens
            0 // amount of kko lp'd
        );
        numberOfSchedules[account] = currentNumSchedules + 1;
        valueLocked = valueLocked.add(amount);
    }

    /// @dev allows staking vesting KKO tokens in the kko single staking pool
    function stakeSingle(uint256 scheduleNumber, uint256 _amountToStake) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            // ensure that the total amount of staked kko including the amount we are staking and lp'ing
            // is less than the total available amount
            schedule.totalStakedKko.add(_amountToStake).add(schedule.kkoInLp) <= schedule.totalAmount.sub(schedule.claimedAmount),
            "Vesting: total staked must be less than or equal to available amount (totalAmount - claimedAmount)"
        );
        schedule.totalStakedKko = schedule.totalStakedKko.add(_amountToStake);
        require(
            stakingPools.depositVesting(
                msg.sender,
                kkoPoolsId,
                _amountToStake
            ),
            "Vesting: depositVesting failed"
        );
    }

    function stakePool2(
        uint256 scheduleNumber, 
        uint256 _amountKko, 
        uint256 _amountEther,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint _deadline
    ) public payable onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.totalStakedKko.add(_amountKko).add(schedule.kkoInLp) <= schedule.totalAmount.sub(schedule.claimedAmount),
            "Vesting: total staked must be less than or equal to available amount (totalAmount - claimedAmount)"
        );
        require(msg.value == _amountEther, "Vesting: sending not supplying enough ether");
        schedule.kkoInLp = schedule.kkoInLp.add(_amountKko);
        // amountToken = The amount of token sent to the pool.
        // amountETH = The amount of ETH converted to WETH and sent to the pool.
        // liquidity = The amount of liquidity tokens minted.
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: msg.value}(
            address(kko),
            _amountKko, // the amount of token to add as liquidity if the WETH/token price is <= msg.value/amountTokenDesired (token depreciates).
            _amountTokenMin, // Bounds the extent to which the WETH/token price can go up before the transaction reverts. Must be <= amountTokenDesired.
            _amountETHMin, // Bounds the extent to which the token/WETH price can go up before the transaction reverts. Must be <= msg.value.
            address(this),
            _deadline
        );
        // if we didnt add the fully amount requested, reduce the amount staked
        if (amountToken < _amountKko) {
            schedule.kkoInLp = schedule.kkoInLp.sub(amountToken);
        }
        schedule.kkoEthLpTokens = schedule.kkoEthLpTokens.add(liquidity);
        require(
            stakingPools.depositVesting(
                msg.sender,
                kkoLpPoolsId,
                liquidity
            ),
            "Vesting: depositVesting failed"
        );
        if (amountETH < _amountEther) {
            msg.sender.transfer(_amountEther.sub(amountETH));
        }
    }


    function exitStakePool2(
        uint256 scheduleNumber,
        uint256 _amountLpTokens,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint _deadline    
    ) public payable onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            _amountLpTokens <= schedule.kkoEthLpTokens,
            "Vesting: insufficient lp token balance"
        );
        (bool ok,) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            kkoLpPoolsId,
            0,
            true,
            true
        );
        require(ok, "Vesting exitStakePool2 failed");
        // amountToken is the amount of tokens received
        // amountETH is the maount of ETH received
        (uint256 amountToken, uint256 amountETH) = router.removeLiquidityETH(
            address(kko),
            schedule.kkoEthLpTokens,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        // due to lp fees they may be withdrawing more kko than they originally deposited
        // in this case we will send the difference directly to their wallet
        if (amountToken > schedule.kkoInLp) {
            uint256 difference = amountToken.sub(schedule.kkoInLp);
            schedule.kkoInLp = 0;
            require(kko.transfer(msg.sender, difference));
        } else {
            schedule.kkoInLp = schedule.kkoInLp.sub(amountToken);
        }
        msg.sender.transfer(amountETH);
    }

    /// @dev used to exit from the single staking pool
    /// @dev this does not transfer the unstaked tokens to the msg.sender, but rather this contract
    function exitStakeSingle(uint256 scheduleNumber) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        (bool ok,) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            kkoPoolsId,
            0, // we are exiting the pool so withdrawing all kko
            true,
            true
        );
        require(ok, "Vesting: exitStakeSingle failed");
        uint256 totalStaked = schedule.totalStakedKko;
        // we're exiting this pool so set to 0
        schedule.totalStakedKko = schedule.totalStakedKko.sub(totalStaked);
    }

    /// @dev allows claiming staking rewards without exiting the staking pool
    function claimStakingRewards(uint256 _poolId) public onlyConfigured {
        require(_poolId == kkoPoolsId || _poolId == kkoLpPoolsId);
        (bool ok, uint256 reward) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            _poolId,
            0, // we are solely claiming rewards
            false,
            false
        );
        require(ok);
        require(kko.transfer(msg.sender, reward));
    }

    /**
    * @notice allows users to claim vested tokens if the cliff time has passed.
    * @notice needs to handle claiming from kko and kkoeth-lp staking
    */
    function claim(uint256 scheduleNumber) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliffTime not reached"
        );
        require(schedule.totalAmount > 0, "Vesting: No claimable tokens");

        // Get the amount to be distributed
        uint amount = calcDistribution(schedule.totalAmount, block.timestamp, schedule.startTime, schedule.endTime);
        
        // Cap the amount at the total amount
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint amountToTransfer = amount.sub(schedule.claimedAmount);
        // set the previous amount claimed 
        uint prevClaimed = schedule.claimedAmount;
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        // if the amount that is unstaked is smaller than the amount being transffered
        // destake first
        require(
            // amountToTransfer < (schedule.claimedAmount - (schedule.totalStakedKkoPool2 + schedule.totalStakedKkoSingle)),
            amountToTransfer <= (schedule.totalAmount - prevClaimed),
            "Vesting: amount unstaked too small for claim please destake"
        );

        require(kko.transfer(msg.sender, amountToTransfer));
        // todo(bonedaddy): this might need some updating
        // as it doesnt factor in staking rewards
        emit Claim(amount, msg.sender);
    }

    /**
    * @notice returns the total amount and total claimed amount of a users vesting schedule.
    * @param account the user to retrieve the vesting schedule for.
    */
    function getVesting(address account, uint256 scheduleId)
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        Schedule memory schedule = schedules[account][scheduleId];
        return (schedule.totalAmount, schedule.claimedAmount, schedule.kkoInLp, schedule.totalStakedKko);
    }

    /**
    * @notice calculates the amount of tokens to distribute to an account at any instance in time, based off some
    *         total claimable amount.
    * @param amount the total outstanding amount to be claimed for this vesting schedule.
    * @param currentTime the current timestamp.
    * @param startTime the timestamp this vesting schedule started.
    * @param endTime the timestamp this vesting schedule ends.
    */
    function calcDistribution(uint amount, uint currentTime, uint startTime, uint endTime) public pure returns(uint256) {
        return amount.mul(currentTime.sub(startTime)).div(endTime.sub(startTime));
    }

    /** 
    * @notice this doesn't handle withdrawing from staking pools
    * @notice Withdraws KKO tokens from the contract.
    * @dev blocks withdrawing locked tokens.
    * @notice if danger is set to true, then all amount checking is witdhrawn
    * @notice this could potentially have bad implications so use with caution
    */
    function withdraw(uint amount, bool danger) public onlyOwner {
        if (danger == false) {
            require(
                kko.balanceOf(address(this)).sub(valueLocked) >= amount,
                "Vesting: amount > tokens leftover"
            );
        }
        require(kko.transfer(msg.sender, amount));
    }

    /// used to update the amount of tokens an account is vesting
    function updateVestingAmount(
        address account,
        uint256 amount,
        uint256 scheduleNumber
    ) public onlyOwner onlyConfigured {
        Schedule storage schedule = schedules[account][scheduleNumber];
        uint256 prevAmountTotal =  schedule.totalAmount;
        schedule.totalAmount = amount;
        // we are decreasing the amount they are vesting
        uint256 difference = prevAmountTotal.sub(amount);
        // subtract the difference from value locked
        valueLocked = valueLocked.sub(difference);
        // transfer the difference back to the caller
        require(kko.transfer(msg.sender, difference));
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

pragma solidity ^0.7.0;

/// @title interfaces used by the vesting contract

interface IStakingPoolsVesting {
    function depositVesting(address _account, uint256 _poolId, uint256 _depositAmount) external returns (bool);
    function withdrawOrClaimOrExitVesting(address _account, uint256 _poolId, uint256 _withdrawAmount, bool _doWithdraw, bool _doExit) external returns (bool, uint256);
}

pragma solidity ^0.7.0;

interface IUniswapV2RouterMinimal {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

pragma solidity ^0.7.0;

interface IERC20Minimal {
    function transfer(address recipient, uint256 amount) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}