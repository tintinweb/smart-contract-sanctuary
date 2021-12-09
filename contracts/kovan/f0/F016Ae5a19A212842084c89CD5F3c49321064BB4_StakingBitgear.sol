// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "./uniswap/interface/IUniswapV2Pair.sol";

contract StakingBitgear is Ownable
{
    using SafeMath for uint256;

    IUniswapV2Pair public pair;
    bool private ifGearZeroTokenInPair;
    IERC20 public gearAddress;

    uint256 public zeroDayStartTime;
    uint256 public dayDurationSec;
    uint256 constant public numDaysInMonth = 30;
    uint256 constant public monthsInYear = 12;
    modifier onlyWhenOpen
    {
        require(
            now >= zeroDayStartTime,
            "StakingBitgear: Contract is not open yet"
        );
        _;
    }

    uint256 public allLpTokensStaked;
    uint256 public allGearTokens;
    uint256 public unfreezedGearTokens;
    uint256 public freezedGearTokens;
    event LpTokensIncome(address who, uint256 amount, uint256 day);
    event LpTokensOutcome(address who, uint256 amount, uint256 day);
    event GearTokenIncome(address who, uint256 amount, uint256 day);
    event GearTokenOutcome(address who, uint256 amount, uint256 day);
    event TokenFreezed(address who, uint256 amount, uint256 day);
    event TokenUnfreezed(address who, uint256 amount, uint256 day);

    uint256 public stakeIdLast;
    uint256 constant public maxNumMonths = 3;
    uint256[] public MonthsApyPercentsNumerator = [15, 20, 30];
    uint256[] public MonthsApyPercentsDenominator = [100, 100, 100];
    struct StakeInfo
    {
        uint256 stakeId;
        uint256 startDay;
        uint256 numMonthsStake;
        uint256 stakedLP;
        uint256 stakedGear;
        uint256 freezedRewardGearTokens;
    }
    mapping(address => StakeInfo[]) public stakeList;
    event StakeStart(
        address who,
        uint256 LpIncome,
        uint256 gearEquivalent,
        uint256 gearEarnings,
        uint256 numMonths,
        uint256 day,
        uint256 stakeId
    );
    event StakeEnd(
        address who,
        uint256 stakeId,
        uint256 LpOutcome,
        uint256 gearEarnings,
        uint256 servedNumMonths,
        uint256 day
    );

    constructor(
        IUniswapV2Pair _pair,
        IERC20 _gearAddress,
        uint256 _zeroDayStartTime,
        uint256 _dayDurationSec
    )
        public
    {
        pair = _pair;
        gearAddress = _gearAddress;
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(
            token0 == address(gearAddress) || token1 == address(gearAddress),
            "StakingBitgear: Invalid LP address"
        );
        zeroDayStartTime = _zeroDayStartTime;
        dayDurationSec = _dayDurationSec;
        ifGearZeroTokenInPair = (token0 == address(gearAddress));
        _testMonthsApyPercents();
    }

    function gearTokenDonation(uint256 amount) external
    {
        address sender = _msgSender();
        require(
            gearAddress.transferFrom(sender, address(this), amount),
            "StakingBitgear: Could not get gear tokens"
        );
        allGearTokens = allGearTokens.add(amount);
        unfreezedGearTokens = unfreezedGearTokens.add(amount);
        emit GearTokenIncome(sender, amount, _currentDay());
    }

    function gearOwnerWithdraw(uint256 amount) external onlyOwner
    {
        address sender = _msgSender();
        require(
            sender == owner(),
            "StakingBitgear: Sender is not owner"
        );
        require(
            allGearTokens > amount,
            "StakingBitgear: Not enough value on this contract"
        );
        require(
            unfreezedGearTokens > amount,
            "StakingBitgear: Not enough unfreezed value on this contract"
        );
        require(
            gearAddress.transfer(sender, amount),
            "StakingBitgear: Could not send gear tokens"
        );
        allGearTokens = allGearTokens.sub(amount);
        unfreezedGearTokens = unfreezedGearTokens.sub(amount);
        emit GearTokenOutcome(sender, amount, _currentDay());
    }

    function stakeStart(uint256 amount, uint256 numMonthsStake) external onlyWhenOpen
    {
        require(
            numMonthsStake > 0 && numMonthsStake <= maxNumMonths,
            "StakingBitgear: Wrong number of months"
        );
        address sender = _msgSender();
        // Get LP tokens
        require(
            pair.transferFrom(sender, address(this), amount),
            "StakingBitgear: LP token transfer failed"
        );
        allLpTokensStaked = allLpTokensStaked.add(amount);
        uint256 currDay = _currentDay();
        emit LpTokensIncome(sender, amount, currDay);
        // Calculate equivalent of LP tokens in Gear tokens
        uint256 LpPairTotalSupply = pair.totalSupply();
        uint256 gearPairTotalReserves;
        //uint256 ethPairTotalReserves;
        if (ifGearZeroTokenInPair)
            (gearPairTotalReserves, /* ethPairTotalReserves */,) = pair.getReserves();
        else
            (/* ethPairTotalReserves */, gearPairTotalReserves,) = pair.getReserves();
        uint256 gearEquivalent = gearPairTotalReserves.mul(amount).div(LpPairTotalSupply);
        // Calculate earnings in Gear tokens that user will get
        uint256 gearEarnings = _getGearEarnings(gearEquivalent, numMonthsStake);
        // Freeze Gear tokens on contract
        require(
            unfreezedGearTokens >= gearEarnings,
            "StakingBitgear: Insufficient funds of Gear tokens to this stake"
        );
        unfreezedGearTokens = unfreezedGearTokens.sub(gearEarnings);
        freezedGearTokens = freezedGearTokens.add(gearEarnings);
        emit TokenFreezed(sender, gearEarnings, currDay);
        // Add stake into stakeList
        StakeInfo memory st = StakeInfo(
            ++stakeIdLast,
            currDay,
            numMonthsStake,
            amount,
            gearEquivalent,
            gearEarnings
        );
        stakeList[sender].push(st);
        emit StakeStart(
            sender,
            amount,
            gearEquivalent,
            gearEarnings,
            numMonthsStake,
            currDay,
            stakeIdLast
        );
    }

    function stakeEnd(uint256 stakeIndex, uint256 stakeId) external onlyWhenOpen
    {
        address sender = _msgSender();
        require(
            stakeIndex >= 0 && stakeIndex < stakeList[sender].length,
            "StakingBitgear: Wrong stakeIndex"
        );
        StakeInfo storage st = stakeList[sender][stakeIndex];
        require(
            st.stakeId == stakeId,
            "StakingBitgear: Wrong stakeId"
        );
        uint256 currDay = _currentDay();
        uint256 servedNumOfMonths = _getServedMonths(currDay, st.startDay, st.numMonthsStake);
        uint256 gearTokensToReturn = _getGearEarnings(st.stakedGear, servedNumOfMonths);
        require(
            st.freezedRewardGearTokens >= gearTokensToReturn,
            "StakingBitgear: Internal error!"
        );

        pair.transfer(sender, st.stakedLP);
        allLpTokensStaked = allLpTokensStaked.sub(st.stakedLP);
        emit LpTokensOutcome(sender, st.stakedLP, currDay);

        uint256 remainingGearTokens = st.freezedRewardGearTokens.sub(gearTokensToReturn);
        unfreezedGearTokens = unfreezedGearTokens.add(remainingGearTokens);
        freezedGearTokens = freezedGearTokens.sub(st.freezedRewardGearTokens);
        emit TokenUnfreezed(sender, st.freezedRewardGearTokens, currDay);
        allGearTokens = allGearTokens.sub(gearTokensToReturn);
        gearAddress.transfer(sender, gearTokensToReturn);
        emit GearTokenOutcome(sender, gearTokensToReturn, currDay);

        emit StakeEnd(
            sender,
            st.stakeId,
            st.stakedLP,
            gearTokensToReturn,
            servedNumOfMonths,
            currDay
        );
        _removeStake(stakeIndex, stakeId);
    }

    function stakeListCount(address who) external view returns(uint256)
    {
        return stakeList[who].length;
    }

    function currentDay() external view onlyWhenOpen returns(uint256)
    {
        return _currentDay();
    }

    function getDayUnixTime(uint256 day) public view returns(uint256)
    {
        return zeroDayStartTime.add(day.mul(dayDurationSec));
    }

    function changeMonthsApyPercents(
        uint256 month,
        uint256 numerator,
        uint256 denominator
    )
        external
        onlyOwner
    {
        require(
            month > 0 && month <= maxNumMonths,
            "StakingBitgear: Wrong month"
        );
        MonthsApyPercentsNumerator[month.sub(1)] = numerator;
        MonthsApyPercentsDenominator[month.sub(1)] = denominator;
        _testMonthsApyPercents();
    }

    function getEndDayOfStakeInUnixTime(
        address who,
        uint256 stakeIndex,
        uint256 stakeId
    )
        external
        view
        returns(uint256)
    {
        require(
            stakeIndex < stakeList[who].length,
            "StakingBitgear: Wrong stakeIndex"
        );
        require(
            stakeId == stakeList[who][stakeIndex].stakeId,
            "StakingBitgear: Wrong stakeId"
        );

        return getDayUnixTime(
            stakeList[who][stakeIndex].startDay.add(
                stakeList[who][stakeIndex].numMonthsStake.mul(
                    numDaysInMonth
                )
            )
        );
    }

    function getStakeDivsNow(
        address who,
        uint256 stakeIndex,
        uint256 stakeId
    )
        external
        view
        returns(uint256)
    {
        require(
            stakeIndex < stakeList[who].length,
            "StakingBitgear: Wrong stakeIndex"
        );
        require(
            stakeId == stakeList[who][stakeIndex].stakeId,
            "StakingBitgear: Wrong stakeId"
        );

        uint256 currDay = _currentDay();
        uint256 servedMonths = _getServedMonths(
            currDay,
            stakeList[who][stakeIndex].startDay,
            stakeList[who][stakeIndex].numMonthsStake
        );
        return _getGearEarnings(stakeList[who][stakeIndex].stakedGear, servedMonths);
    }

    function _getServedMonths(
        uint256 currDay,
        uint256 startDay,
        uint256 numMonthsStake
    )
        private
        pure
        returns(uint256 servedMonths)
    {
        servedMonths = currDay.sub(startDay).div(numDaysInMonth);
        if (servedMonths > numMonthsStake)
            servedMonths = numMonthsStake;
    }

    function _getGearEarnings(
        uint256 gearAmount,
        uint256 numOfMonths
    )
        private
        view
        returns (uint256 reward)
    {
        require(
            numOfMonths >= 0 && numOfMonths <= maxNumMonths,
            "StakingBitgear: Wrong numOfMonths"
        );
        for (uint256 month = 1; month <= numOfMonths; ++month)
        {
            reward +=
                gearAmount.add(reward)
                    .mul(MonthsApyPercentsNumerator[month - 1])
                    .div(monthsInYear)
                    .div(MonthsApyPercentsDenominator[month - 1]);
        }
        return reward;
    }

    function _currentDay() private view returns(uint256)
    {
        return now.sub(zeroDayStartTime).div(dayDurationSec);
    }

    function _removeStake(uint256 stakeIndex, uint256 stakeId) private
    {
        address sender = _msgSender();
        uint256 stakeListLength = stakeList[sender].length;
        require(
            stakeIndex >= 0 && stakeIndex < stakeListLength,
            "StakingBitgear: Wrong stakeIndex"
        );
        StakeInfo storage st = stakeList[sender][stakeIndex];
        require(
            st.stakeId == stakeId,
            "StakingBitgear: Wrong stakeId"
        );
        if (stakeIndex < stakeListLength - 1)
            stakeList[sender][stakeIndex] = stakeList[sender][stakeListLength - 1];
        stakeList[sender].pop();
    }

    function _testMonthsApyPercents() private view
    {
        uint256 amount = 100000;
        require(
            maxNumMonths == 3,
            "StakingBitgear: Wrong MonthsApyPercents parameters"
        );
        require(
            amount
                .mul(MonthsApyPercentsNumerator[0])
                .div(MonthsApyPercentsDenominator[0])
                >=
            amount.mul(5).div(100),
            "StakingBitgear: Wrong MonthsApyPercents parameters"
        );
        require(
            amount
                .mul(MonthsApyPercentsNumerator[1])
                .div(MonthsApyPercentsDenominator[1])
                >=
            amount.mul(7).div(100),
            "StakingBitgear: Wrong MonthsApyPercents parameters"
        );
        require(
            amount
                .mul(MonthsApyPercentsNumerator[2])
                .div(MonthsApyPercentsDenominator[2])
                >=
            amount.mul(10).div(100),
            "StakingBitgear: Wrong MonthsApyPercents parameters"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

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