// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IHBSC {
	 function mintTo(address to, uint256 amount) external;
	 function approve(address spender, uint256 amount) external returns (bool);
	 function allowance(address owner, address spender) external view returns (uint256);
	 function balanceOf(address account) external view returns (uint256);
	 function burnTokens(uint256 amount) external returns (bool);
	 function transfer(address recipient, uint256 amount) external returns (bool);
	 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeMath.sol";
import "../IBEP20.sol";
import "../IHBSC.sol";
import "../IPancakeRouter02.sol";

/**
 * @title HBSC Staking Contract
 */
contract HBSCStake {

    using SafeMath for uint256;

    struct Staked{
        uint256 Stake0StartTimestamp;
        uint256 Stake180StartTimestamp;
        uint256 Stake270StartTimestamp;
        uint256 Stake365StartTimestamp;
        uint256 StartRate0;
        uint256 StartRate180;
        uint256 StartRate270;
        uint256 StartRate365;
    }

    struct Claimed{
        uint256 Days0;
        uint256 Days180;
        uint256 Days270;
        uint256 Days365;
    }

    uint256 totalDividends;
    //amount of HBSC earned per day per HBSC staked, to be set in constructor
    uint256 public initialRate0;  //1000000000000000;
    uint256 public initialRate180; //2000000000000000;
    uint256 public initialRate270; //3000000000000000;
    uint256 public initialRate365; //4000000000000000;
    uint256 public compoundRate; //10000000000;
    uint256 creationDate;
    uint256 public daySeconds = 30;//86400; 
    uint256 public totalStaked;
    uint256 public total0Staked;
    uint256 public total180Staked;
    uint256 public total270Staked;
    uint256 public total365Staked;
    bool private sync;
    bool rateSet;
    address public hbscAddress;
    IHBSC hbscToken;
    address public busdAddress;
    IBEP20 busdToken;
    address constant pancakeRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //testnet
    IPancakeRouter02 pancakeRouter;
    address public adminWallet;
    address owner;
  
    mapping(address => uint256) public token0StakedBalances;
    mapping(address => uint256) public token180StakedBalances;
    mapping(address => uint256) public token270StakedBalances;
    mapping(address => uint256) public token365StakedBalances;
    mapping(address => uint256) public dividendsClaimed;
    mapping(address => Staked) public staked;
    mapping(address => Claimed) public claimed;

    event TokenStake(
        address user,
        uint value,
        uint length
    );

    event TokenUnStake(
        address user,
        uint value,
        uint length
    );

    event BusdClaimed(
        address user,
        uint value
    );

    event BusdReceived(
        uint value
    );

    constructor(
        address hbscTokenAddress, 
        address busdTokenAddress,
        address admin,
        uint256 newInitialRate0,
        uint256 newInitialRate180,
        uint256 newInitialRate270,
        uint256 newInitialRate365,
        uint256 newCompoundRate
    ) 
    {
        hbscAddress = hbscTokenAddress;
        hbscToken = IHBSC(hbscTokenAddress);
        busdAddress = busdTokenAddress;
        busdToken = IBEP20(busdTokenAddress);
        pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
        adminWallet = admin;
        owner = msg.sender;
        initialRate0 = newInitialRate0;
        initialRate180 = newInitialRate180;
        initialRate270 = newInitialRate270;
        initialRate365 = newInitialRate365;
        compoundRate = newCompoundRate;
        creationDate = block.timestamp;

        hbscToken.approve(pancakeRouterAddress, 2**256 - 1);
        busdToken.approve(pancakeRouterAddress, 2**256 - 1);
    }

    modifier onlyAdmin() {
        require(
            msg.sender == adminWallet || msg.sender == owner, 
            "Admin only function"
        );
        _;
    }

    /*
    * @dev Protects against reentrancy
    */
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    /*
    * @dev Receives HBSC tokens that will be distributed to stakeholders as dividends
    */
    function receiveBUSD (uint256 amount) 
        external
    {
        require(
            busdToken.transferFrom(msg.sender, address(this), amount),
            "Receive BUSD failed"
        );

        totalDividends += amount;
        emit BusdReceived(amount);
    }

    /*
    * @dev Allows staker to claim BUSD dividends
    */
    function claimBusd() 
        external
    {
        uint256 claimAmount = getClaimAmount(msg.sender);
        claim(msg.sender, claimAmount);     
    }

    
    /*
    * @dev Stake HBSC tokens
    */
    function stakeTokens(uint256 amount, uint256 dayLength)
        external
    {
        address user = msg.sender;

        require(hbscToken.allowance(user, address(this)) >= amount, 
           "Please first approve HBSC");
        require(amount > 0, "Stake amount can not be 0");
        require(hbscToken.balanceOf(user) >= amount, "Insufficient balance");
        require(hbscToken.transferFrom(user, address(this), amount), "Transfer failed");

        Staked memory userStake = staked[user];

        autoClaim(user);

        if(dayLength == 0){
            token0StakedBalances[user] += amount;
            total0Staked += amount;
            userStake.StartRate0 = getCurrentRate(initialRate0);
            userStake.Stake0StartTimestamp = block.timestamp;
        }
        else if(dayLength == 180){
            token180StakedBalances[user] += amount;
            total180Staked += amount;
            userStake.StartRate180 = getCurrentRate(initialRate180);
            userStake.Stake180StartTimestamp = block.timestamp;
        }
        else if(dayLength == 270){
            token270StakedBalances[user] += amount;
            total270Staked += amount;
            userStake.StartRate270 = getCurrentRate(initialRate270);
            userStake.Stake270StartTimestamp = block.timestamp;
        }
        else if(dayLength == 365){
            token365StakedBalances[user] += amount;
            total365Staked += amount;
            userStake.StartRate365 = getCurrentRate(initialRate365);
            userStake.Stake365StartTimestamp = block.timestamp;
        }
        else{
            revert("Invalid stake length");
        }
        
        totalStaked = totalStaked.add(amount);
        staked[user] = userStake;

        emit TokenStake(user, amount, dayLength);
    }

    /**
    * @dev UnStake HBSC Token
    */
    function unStakeTokens(uint dayLength)
        external
        synchronized
    {
        uint256 amount;
        address user = msg.sender;
        autoClaim(user);

        if(dayLength == 0){
            amount = token0StakedBalances[user];

            require(
                amount > 0,
                "No available tokens to unstake in tier 0"
            );

            token0StakedBalances[user] = 0;
            staked[user].Stake0StartTimestamp = 0;
            total0Staked = total0Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
            hbscToken.transfer(user, amount);
        }
        else if(dayLength == 180){
            amount = token180StakedBalances[user];

            require(
                amount > 0,
                "No available tokens to unstake in tier 180"
            );

            if(isStakeFinished(user, dayLength)) {
                hbscToken.transfer(user, amount);
            }
            else {
                emergencyUnstake(user, dayLength);
            }

            token180StakedBalances[user] = 0;
            staked[user].Stake180StartTimestamp = 0;
            total180Staked = total180Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
        }
        else if(dayLength == 270){
            amount = token270StakedBalances[user];

            require(
                amount > 0,
                "No available tokens to unstake in tier 270"
            );

            if(isStakeFinished(user, dayLength)) {
                hbscToken.transfer(user, amount);
            }
            else {
                emergencyUnstake(user, dayLength);
            }

            token270StakedBalances[user] = 0;
            staked[user].Stake270StartTimestamp = 0;
            total270Staked = total270Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
        }
        else if(dayLength == 365){
            amount = token365StakedBalances[user];

            require(
                amount > 0,
                "No available tokens to unstake in tier 365"
            );
            if(isStakeFinished(user, dayLength)){
                hbscToken.transfer(user, amount);
            }
            else {
                emergencyUnstake(user, dayLength);
            }

            token365StakedBalances[user] = 0;
            staked[user].Stake365StartTimestamp = 0;
            total365Staked = total365Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);           
        }
        else{
            revert("Invalid stake length");
        }

        emit TokenUnStake(user, amount, dayLength);
    }

    /*
    * @dev Allows admin to claim tokens accidentaly sent to the contract address
    */
    function reclaimTokens(
        address tokenAddress, 
        address wallet
    ) 
        external
        onlyAdmin
    {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        
        if(tokenAddress == hbscAddress){
            balance = token.balanceOf(address(this)).sub(totalStaked);
        }

        require(balance > 0, "No tokens available for this contract address");

        token.transfer(wallet, balance);
    }

    /*
    * @dev Gets the current rate for today
    */
    function getCurrentRate(uint256 initialRate) 
        public
        view
        returns(uint256)
    {
        uint256 daysElapsed = getElapsedDays(creationDate);

        if(daysElapsed <= 1){
            return initialRate;
        }
        
        uint256 compound = daysElapsed.mul(compoundRate);
        return initialRate.add(compound);
    }

    /*
    * @dev Determines whether stake is fininshed or liable to emergency unstake penalty
    */
    function isStakeFinished(
        address user, 
        uint256 stakeDayLength
    )
        public
        view
        returns(bool)
    {
        if(stakeDayLength == 0){
            return true;
        }
        else if(stakeDayLength == 180){
            if(staked[user].Stake180StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake180StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else if(stakeDayLength == 270){
            if(staked[user].Stake270StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake270StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else if(stakeDayLength == 365){
            if(staked[user].Stake365StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake365StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else{
            return false;
        }
    }

    /*
    * @dev Emergency unstake process
    * Refund completed stake amount corresponding to 10% percentiles
    * Distribute 90% of uncompleted stake amount of HBSC among other stakers
    * Remaining 10% goes to team wallet
    */
    function emergencyUnstake(
        address user, 
        uint256 stakeDayLength
    )
        internal
    {
        uint256 balance;
        uint256 startTimestamp;
        Staked memory userStake = staked[user];

        if(stakeDayLength == 180) {
            balance = token180StakedBalances[user];
            startTimestamp = userStake.Stake180StartTimestamp;
        }
        else if(stakeDayLength == 270) {
            balance = token270StakedBalances[user];
            startTimestamp = userStake.Stake270StartTimestamp;
        }
        else if(stakeDayLength == 365) {
            balance = token365StakedBalances[user];
            startTimestamp = userStake.Stake365StartTimestamp;
        }
        else {
            revert("Invalid stake length");
        }

        uint256 percentile = getPercentileStaked(stakeDayLength, startTimestamp);
        uint256 refundAmount;
        uint256 lostAmount;

        if(percentile < 10){
            refundAmount = 0;
            lostAmount = balance;
        }
        else {
            refundAmount = balance.mul(100).div(percentile);
            lostAmount = balance.sub(refundAmount);
            hbscToken.transfer(user, refundAmount);
        }

        uint256 teamAmount = lostAmount.mul(10).div(100);
        hbscToken.transfer(adminWallet, teamAmount);

        uint256 burnAmount = lostAmount.mul(50).div(100);
        hbscToken.burnTokens(burnAmount);

        uint256 liquidityAmount = lostAmount.sub(teamAmount).sub(burnAmount);
        swapAndPushLiquidity(liquidityAmount);
    }

    /*
    * @dev rounds down to the nearest 10%
    */
    function getPercentileStaked(
        uint256 stakeDayLength, 
        uint256 startTimestamp
    ) 
        internal
        view
        returns (uint256)
    {
        uint256 totalStakeTime = stakeDayLength.mul(daySeconds);
        uint256 timeRemaining = (startTimestamp + totalStakeTime) - block.timestamp;

        uint256 percent = 100 - timeRemaining.mul(100) / totalStakeTime;

        return percent.sub(percent.mod(10));
    }


    event Test(
        uint amount,
        uint amountout1,
        uint amountout2,
        uint slippage
    );
    /*
    * @dev Swaps half amount for BUSD and then adds pancakeswap liquidity
    */
    function swapAndPushLiquidity(uint256 amount)
        private
        returns(bool)
    {
        uint256 half = amount.div(2);

        address[] memory path;
        
        path = new address[](2);
        path[0] = address(hbscToken);
        path[1] = address(busdToken);
        uint256[] memory amountOutMins = pancakeRouter.getAmountsOut(amount, path);
        uint256 amountOut = amountOutMins[1].mul(85).div(100);// 15% slippage

        emit Test(half, amountOutMins[0], amountOutMins[1], amountOut);
        uint[] memory busdAmount = pancakeRouter.swapExactTokensForTokens(
            half, 
            amountOut, 
            path, 
            address(this), 
            block.timestamp
        );

        pancakeRouter.addLiquidity
        (
            address(hbscToken),
            address(busdToken),
            half,
            busdAmount[1],
            0,
            0,
            address(this),
            block.timestamp + 10 minutes
        );
        

        return true;
    }

    /*
    * @dev Claims dividends
    */
    function claim(address user, uint256 amount) 
        private
    {
        require(
            hbscToken.balanceOf(address(this)) > amount, 
            "BUSD dividend balance must be increased"
        );
        Staked memory stakeInfo = staked[user];
        Claimed memory claimInfo = claimed[user];

        busdToken.transfer(msg.sender, amount);
        totalDividends -= amount;
        claimInfo.Days0 = getElapsedDays(stakeInfo.Stake0StartTimestamp);
        claimInfo.Days180 = getElapsedDays(stakeInfo.Stake180StartTimestamp);
        claimInfo.Days270 = getElapsedDays(stakeInfo.Stake270StartTimestamp);
        claimInfo.Days365 = getElapsedDays(stakeInfo.Stake365StartTimestamp);
        
        emit BusdClaimed(msg.sender, amount);
    }

    /*
    * @dev Claims all outsanding divs for user
    */
    function autoClaim(address user)
        private
    {
        uint256 claimAmount = getClaimAmount(user);
        if(claimAmount > 0){
            claim(user, claimAmount);
        }
    }

    /*
    * @dev Calculates outstanding dividends since last claim 
    */
    function calculateDividends(
        uint256 daysClaimed,
        uint256 daysElapsed,
        uint256 stakedBalance,
        uint256 startRate
    )
        private
        view
        returns(uint256)
    {
        uint256 total;
        for(uint i = daysClaimed; i < daysElapsed; i++)
        {
            total += stakedBalance.mul(startRate + (compoundRate * i))
                                  .div(10 ** 18);                         
        }
        return total;
    }
    
    /*
    * @dev Gets the number of days since specified time
    */
    function getElapsedDays(uint256 startTime) 
        private
        view
        returns(uint256)
    {
        uint256 totalTimeElapsed = block.timestamp.sub(startTime);
        if(totalTimeElapsed < daySeconds){
            return 0;
        }
        return totalTimeElapsed.div(daySeconds);
    }

    
    /*
    * @dev Calculates total HBSC claim amount
    */
    function getClaimAmount(address stakeholder)
        public
        view
        returns(uint256)
    {
        Staked memory stakeInfo = staked[stakeholder];
        Claimed memory claimInfo = claimed[stakeholder];
        uint256 dividendAmount;

        if(token0StakedBalances[stakeholder] > 0){
            uint256 elapsedDays = getElapsedDays(stakeInfo.Stake0StartTimestamp);
            if(elapsedDays > 30) { //Limit instant unstake tier to 30 days
                elapsedDays = 30;
            }
            if(elapsedDays >0) {
                dividendAmount += calculateDividends(
                    claimInfo.Days0, 
                    elapsedDays, 
                    token0StakedBalances[stakeholder],
                    stakeInfo.StartRate0);
            }
        }
        if(token180StakedBalances[stakeholder] > 0)
        {
            uint256 elapsedDays = getElapsedDays(stakeInfo.Stake180StartTimestamp);
            if(elapsedDays > 180) {
                elapsedDays = 180;
            }
            if(elapsedDays > 0) {
                 dividendAmount += calculateDividends(
                    claimInfo.Days180, 
                    elapsedDays, 
                    token180StakedBalances[stakeholder],
                    stakeInfo.StartRate180);
            }
        } 
        if(token270StakedBalances[stakeholder] > 0)
        {
            uint256 elapsedDays = getElapsedDays(stakeInfo.Stake270StartTimestamp);
            if(elapsedDays > 270) {
                elapsedDays = 270;
            }
            if(elapsedDays > 0) {
                dividendAmount += calculateDividends(
                    claimInfo.Days270, 
                    elapsedDays, 
                    token270StakedBalances[stakeholder],
                    stakeInfo.StartRate270);
            }
        }
        if(token365StakedBalances[stakeholder] > 0)
        {
            uint256 elapsedDays = getElapsedDays(stakeInfo.Stake365StartTimestamp);
            if(elapsedDays > 365) {
                elapsedDays = 365;
            }
            if(elapsedDays > 0){
                dividendAmount += calculateDividends(
                    claimInfo.Days365, 
                    elapsedDays, 
                    token365StakedBalances[stakeholder],
                    stakeInfo.StartRate365);
            }
        }

        return dividendAmount;
    }
}

