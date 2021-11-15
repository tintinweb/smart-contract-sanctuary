// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/UniswapV2.sol";

//Max Supply: 5000
//At launch: 1643.75 (initial MC 155ETH @ current price 58k MC)
//Uniswap: 318.75 locked with 30ETH (puts the initial listing price at 10.625/ETH)
//Obelix fund: 700
//Locked pool incentives: 1956.25 (75 per week — 37.5 for UTY liq. / 37.5 for OBELIX liq.)
//Time-locked for OBELIX fund: 1400 in total & 60 $OBELIX weekly released into the fund
//Presale for liquidity: 625 @12.5/ETH (30ETH to OBELIX / remaining to UTY)

// Liquidity pool allows a user to stake Uniswap liquidity tokens (tokens representaing shares of ETH and OBELIX tokens in the Uniswap liquidity pool)
// Users receive rewards in tokens for locking up their liquidity
contract UTYFarming {
    using SafeMath for uint256;

    IERC20 public uniswapPair;

    IERC20 public obelixToken;

    IERC20 public UTYToken;

    address public owner;

    uint256 public minStakeDurationDays;

    uint256 public rewardAdjustmentFactor;

    bool public stakingEnabled;

    bool public exponentialRewardsEnabled;

    uint256 public exponentialDaysMax;

    bool public migrationEnabled;

    struct staker {
        uint256 startTimestamp; // Unix timestamp of when the tokens were initially staked
        uint256 lastTimestamp; // Last time tokens were locked or reinvested
        uint256 poolTokenBalance; // Balance of Uniswap liquidity tokens
        uint256 lockedRewardBalance; // Locked rewards in obelix
    }

    mapping(address => staker) public stakers;
    mapping(address => uint256) public previousContractBalances;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor() public {
        UTYToken = IERC20(0xc6BF2A2A43cA360bb0ec6770F57f77CddE64Bb3F);
        obelixToken = IERC20(0x58B5e6267486bc2d7b4221749daE5eA9003cAdd7);
        migrationEnabled = true;
        minStakeDurationDays = 2;
        owner = msg.sender;
        rewardAdjustmentFactor = 535714286E10;
        stakingEnabled = true;
        exponentialRewardsEnabled = false;
        exponentialDaysMax = 60;
    }

    function stakeLiquidityTokens(uint256 numPoolTokensToStake) external {
        require(numPoolTokensToStake > 0);
        require(stakingEnabled, "Staking is currently disabled.");

        uint256 previousBalance = uniswapPair.balanceOf(address(this));

        uniswapPair.transferFrom(
            msg.sender,
            address(this),
            numPoolTokensToStake
        ); // Transfer liquidity tokens from the sender to this contract

        uint256 postBalance = uniswapPair.balanceOf(address(this));

        require(previousBalance.add(numPoolTokensToStake) == postBalance); // This is a sanity check and likely not required as the Uniswap token is ERC20

        staker storage thisStaker = stakers[msg.sender]; // Get the sender's information

        if (
            thisStaker.startTimestamp == 0 || thisStaker.poolTokenBalance == 0
        ) {
            thisStaker.startTimestamp = block.timestamp;
            thisStaker.lastTimestamp = block.timestamp;
        } else {
            // If the sender is currently staking, adding to his balance results in a holding time penalty
            uint256 percent = mulDiv(
                1000000,
                numPoolTokensToStake,
                thisStaker.poolTokenBalance
            ); // This is not really 'percent' it is just a number that represents the totalAmount as a fraction of the recipientBalance
            assert(percent > 0);
            if (percent > 1) {
                percent = percent.div(2); // We divide the 'penalty' by 2 so that the penalty is not as bad
            }
            if (percent.add(thisStaker.startTimestamp) > block.timestamp) {
                // We represent the 'percent' or 'penalty' as seconds and add to the recipient's unix time
                thisStaker.startTimestamp = block.timestamp; // Receiving too many tokens resets your holding time
            } else {
                thisStaker.startTimestamp = thisStaker.startTimestamp.add(
                    percent
                );
            }
        }

        thisStaker.poolTokenBalance = thisStaker.poolTokenBalance.add(
            numPoolTokensToStake
        );
    }

    // Withdraw liquidity tokens, pretty self-explanatory
    function withdrawLiquidityTokens(uint256 numPoolTokensToWithdraw) external {
        require(numPoolTokensToWithdraw > 0);

        staker storage thisStaker = stakers[msg.sender];

        require(
            thisStaker.poolTokenBalance >= numPoolTokensToWithdraw,
            "Pool token balance too low"
        );

        uint256 daysStaked = block.timestamp.sub(thisStaker.startTimestamp) /
            86400; // Calculate time staked in days

        require(daysStaked >= minStakeDurationDays);

        uint256 tokensOwed = calculateTokensOwed(msg.sender); // We give all of the rewards owed to the sender on a withdrawal, regardless of the amount withdrawn

        tokensOwed = tokensOwed.add(thisStaker.lockedRewardBalance);

        thisStaker.lockedRewardBalance = 0;
        thisStaker.poolTokenBalance = thisStaker.poolTokenBalance.sub(
            numPoolTokensToWithdraw
        );

        thisStaker.startTimestamp = block.timestamp; // Reset staking timer on withdrawal
        thisStaker.lastTimestamp = block.timestamp;

        obelixToken.transfer(msg.sender, tokensOwed);

        uniswapPair.transfer(msg.sender, numPoolTokensToWithdraw);
    }

    function withdrawRewards() external {
        staker storage thisStaker = stakers[msg.sender];

        uint256 daysStaked = block.timestamp.sub(thisStaker.startTimestamp) /
            86400; // Calculate time staked in days

        require(daysStaked >= minStakeDurationDays);

        uint256 tokensOwed = calculateTokensOwed(msg.sender);

        tokensOwed = tokensOwed.add(thisStaker.lockedRewardBalance);

        thisStaker.lockedRewardBalance = 0;
        thisStaker.startTimestamp = block.timestamp; // Reset staking timer on withdrawal
        thisStaker.lastTimestamp = block.timestamp;

        obelixToken.transfer(msg.sender, tokensOwed);
    }

    function lockRewards() external {
        uint256 currentRewards = calculateTokensOwed(msg.sender);
        staker storage thisStaker = stakers[msg.sender];

        thisStaker.lastTimestamp = block.timestamp;
        thisStaker.lockedRewardBalance = thisStaker.lockedRewardBalance.add(
            currentRewards
        );
    }

    // If you call this function you forfeit your rewards
    function emergencyWithdrawLiquidityTokens() external {
        staker storage thisStaker = stakers[msg.sender];
        uint256 poolTokenBalance = thisStaker.poolTokenBalance;
        thisStaker.poolTokenBalance = 0;
        thisStaker.startTimestamp = block.timestamp;
        thisStaker.lastTimestamp = block.timestamp;
        thisStaker.lockedRewardBalance = 0;
        uniswapPair.transfer(msg.sender, poolTokenBalance);
    }

    function calculateTokensOwed(address stakerAddr)
        public
        view
        returns (uint256)
    {
        staker memory thisStaker = stakers[stakerAddr];

        uint256 totalDaysStaked = block.timestamp.sub(
            thisStaker.startTimestamp
        ) / 86400; // Calculate time staked in days
        uint256 daysSinceLast = block.timestamp.sub(thisStaker.lastTimestamp) /
            86400;

        uint256 tokens = mulDiv(
            daysSinceLast.mul(rewardAdjustmentFactor),
            thisStaker.poolTokenBalance,
            uniswapPair.totalSupply()
        ); // The formula is as follows: tokens owned = (days staked * reward adjustment factor) * (sender liquidity token balance / total supply of liquidity token)

        if (totalDaysStaked > exponentialDaysMax) {
            totalDaysStaked = exponentialDaysMax;
        }

        if (exponentialRewardsEnabled) {
            return tokens * totalDaysStaked;
        } else {
            return tokens;
        }
    }

    function calculateMonthlyYield() public view returns (uint256) {
        uint256 tokensInPool = UTYToken.balanceOf(address(uniswapPair));
        uint256 tokens = mulDiv(30 * rewardAdjustmentFactor, 1, 2); // Tokens given per month for 50% of pool (50% because APY should also consider ETH contribution)
        if (exponentialRewardsEnabled) {
            tokens = tokens * 30;
        }
        return mulDiv(10000, tokens, tokensInPool);
    }

    function updateUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapPair = IERC20(_uniswapPair);
    }

    function updateobelixToken(address _obelixToken) external onlyOwner {
        obelixToken = IERC20(_obelixToken);
    }

    function updateUTYToken(address _utyToken) external onlyOwner {
        UTYToken = IERC20(_utyToken);
    }

    function updateMinStakeDurationDays(uint256 _minStakeDurationDays)
        external
        onlyOwner
    {
        minStakeDurationDays = _minStakeDurationDays;
    }

    function updateRewardAdjustmentFactor(uint256 _rewardAdjustmentFactor)
        external
        onlyOwner
    {
        rewardAdjustmentFactor = _rewardAdjustmentFactor;
    }

    function updateStakingEnabled(bool _stakingEnbaled) external onlyOwner {
        stakingEnabled = _stakingEnbaled;
    }

    function updateExponentialRewardsEnabled(bool _exponentialRewards)
        external
        onlyOwner
    {
        exponentialRewardsEnabled = _exponentialRewards;
    }

    function updateExponentialDaysMax(uint256 _exponentialDaysMax)
        external
        onlyOwner
    {
        exponentialDaysMax = _exponentialDaysMax;
    }

    function updateMigrationEnabled(bool _migrationEnabled) external onlyOwner {
        migrationEnabled = _migrationEnabled;
    }

    function transferobelixTokens(uint256 _numTokens) external onlyOwner {
        obelixToken.transfer(msg.sender, _numTokens);
    }

    function transferEth(uint256 _eth) external onlyOwner {
        msg.sender.transfer(_eth);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function giveMeDayStart() external onlyOwner {
        stakers[owner].startTimestamp = stakers[owner].startTimestamp.sub(
            86400
        );
    }

    function giveMeDayLast() external onlyOwner {
        stakers[owner].lastTimestamp = stakers[owner].lastTimestamp.sub(86400);
    }

    function getStaker(address _staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            stakers[_staker].startTimestamp,
            stakers[_staker].lastTimestamp,
            stakers[_staker].poolTokenBalance,
            stakers[_staker].lockedRewardBalance
        );
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        assert(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    function fullMul(uint256 x, uint256 y)
        private
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    fallback() external payable {}

    receive() external payable {}
}

pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.6.12;

interface UniswapV2 {
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
}

