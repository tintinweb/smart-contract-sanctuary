// SPDX-License-Identifier: MIT


pragma solidity 0.7.3;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual onlyAdmin {
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;


contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dex/IUniswapV2Factory.sol";
import "./dex/IUniswapV2Pair.sol";
import "./dex/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract DexCaller is IUniswapV2Callee {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    struct UniVars {
        address sellToken;
        uint amount;
    }



    function flashSell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount) internal returns (uint buyAmount){
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');
        UniVars memory uniVars = UniVars({
        sellToken : sellToken,
        amount : sellAmount
        });
        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            buyAmount = getAmountOut(sellAmount, token1Reserves, token0Reserves);
            require(buyAmount >= minBuyAmount, 'buy amount less than min');
            IUniswapV2Pair(pair).swap(buyAmount, 0, address(this), abi.encode(uniVars));
        } else {
            buyAmount = getAmountOut(sellAmount, token0Reserves, token1Reserves);
            require(buyAmount >= minBuyAmount, 'buy amount less than min');
            IUniswapV2Pair(pair).swap(0, buyAmount, address(this), abi.encode(uniVars));
        }
        return buyAmount;
    }

    function flashBuy(address buyToken, address sellToken, uint buyAmount, uint maxSellAmount) internal returns (uint sellAmount){
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');

        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            sellAmount = getAmountIn(buyAmount, token1Reserves, token0Reserves);
            require(maxSellAmount >= sellAmount, 'sell amount not enough');
            UniVars memory uniVars = UniVars({
            sellToken : sellToken,
            amount : sellAmount
            });
            IUniswapV2Pair(pair).swap(buyAmount, 0, address(this), abi.encode(uniVars));
        } else {
            sellAmount = getAmountIn(buyAmount, token0Reserves, token1Reserves);
            require(maxSellAmount >= sellAmount, 'sell amount not enough');
            UniVars memory uniVars = UniVars({
            sellToken : sellToken,
            amount : sellAmount
            });
            IUniswapV2Pair(pair).swap(0, buyAmount, address(this), abi.encode(uniVars));
        }
        return sellAmount;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        onSwapCall(sender, amount0, amount1, data);
    }
//
//    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
//        onSwapCall(sender, amount0, amount1, data);
//    }
//
//    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external override {
//        onSwapCall(sender, amount0, amount1, data);
//    }

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount) external override view returns (uint) {
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');
        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            return getAmountOut(sellAmount, token1Reserves, token0Reserves);
        } else {
            return getAmountOut(sellAmount, token0Reserves, token1Reserves);
        }
    }

    function onSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) internal {
        // Shh - currently unused
        sender;
        amount0;
        amount1;
        // fetch the address of token0
        address token0 = IUniswapV2Pair(msg.sender).token0();
        // fetch the address of token1
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // ensure that msg.sender is a V2 pair
        assert(msg.sender == uniswapFactory.getPair(token0, token1));
        // rest of the function goes here!
        (UniVars memory uniVars) = abi.decode(data, (UniVars));
        IERC20(uniVars.sellToken).safeTransfer(msg.sender, uniVars.amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./Adminable.sol";
import "./DexCaller.sol";
import "./TreasuryInterface.sol";
import "./DelegateInterface.sol";

contract Treasury is DelegateInterface, TreasuryInterface, TreasuryStorage, Adminable, DexCaller {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    constructor ()
    {
    }

    function initialize(
        IUniswapV2Factory _uniswapFactory,
        address _oleToken,
        address _sharingToken,
        uint _devFundRatio,
        address _dev
    ) public {
        require(msg.sender == admin, "not admin");
        oleToken = IERC20(_oleToken);
        sharingToken = IERC20(_sharingToken);
        devFundRatio = _devFundRatio;
        dev = _dev;
        uniswapFactory = _uniswapFactory;
    }


    function devWithdraw(uint amount) external override {
        require(msg.sender == dev, "Dev fund only be withdrawn by dev");
        require(amount != 0, "Amount can't be 0");
        require(amount <= devFund, "Exceed available balance");
        devFund = devFund.sub(amount);
        sharingToken.transfer(dev, amount);
    }

    function convertToSharingToken(address fromToken, uint amount, uint minBuyAmount) external override {
        if (fromToken == address(oleToken)) {
            require(oleToken.balanceOf(address(this)).sub(totalStaked) >= amount, 'Exceed available balance');
        }
        uint newReward;
        //sharing token increment
        if (fromToken == address(sharingToken)) {
            uint sharingTokenAvailableAmount = sharingToken.balanceOf(address(this)).add(transferredToAccount).sub(totalToShared).sub(devFund);
            require(sharingTokenAvailableAmount >= amount, 'Exceed available balance');
            newReward = amount;
        } else {
            newReward = flashSell(address(sharingToken), fromToken, amount, minBuyAmount);
        }
        uint newDevFund = newReward.mul(devFundRatio).div(100);
        uint feesShare = newReward.sub(newDevFund);
        devFund = devFund.add(newDevFund);
        totalToShared = totalToShared.add(feesShare);
        lastUpdateTime = block.timestamp;
        rewardPerTokenStored = rewardPerToken(feesShare);
        emit RewardAdded(fromToken, amount, feesShare);
    }

    function earned(address account) external override view returns (uint) {
        return earnedInternal(account);
    }

    function earnedInternal(address account) internal view returns (uint) {
        return stakedBalances[account]
        .mul(rewardPerToken(0).sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    function rewardPerToken(uint newReward) internal view returns (uint) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        if (block.timestamp == lastUpdateTime) {
            return rewardPerTokenStored.add(newReward
            .mul(1e18)
            .div(totalStaked));
        } else {
            return rewardPerTokenStored;
        }
    }

    function stake(uint amount) external override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalStaked = totalStaked.add(amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
        oleToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint amount) external override {
        withdrawInternal(amount);
    }

    function withdrawInternal(uint amount) internal updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalStaked = totalStaked.sub(amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);
        oleToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external override {
        getRewardInternal();
    }

    function getRewardInternal() internal updateReward(msg.sender) {
        uint reward = earnedInternal(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            transferredToAccount = transferredToAccount.add(reward);
            sharingToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdrawInternal(stakedBalances[msg.sender]);
        getRewardInternal();
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(0);
        rewards[account] = earnedInternal(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    /*** Admin Functions ***/
    function setDevFundRatio(uint newRatio) external override onlyAdmin {
        require(newRatio <= 100);
        devFundRatio = newRatio;
    }

    function setDev(address newDev) external override onlyAdmin {
        dev = newDev;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract TreasuryStorage {
    IERC20 public oleToken;

    IERC20 public sharingToken;

    // dev team account
    address public dev;

    uint public devFund;

    uint public totalStaked;

    // user => staked balance of OLE
    mapping(address => uint) public stakedBalances;

    uint public devFundRatio; // ex. 50 => 50%

    mapping(address => uint256) public userRewardPerTokenPaid;

    // user => reward
    mapping(address => uint256) public rewards;

    // total to shared
    uint public totalToShared;

    uint public transferredToAccount;

    uint public lastUpdateTime;

    uint public rewardPerTokenStored;

    event RewardAdded(address fromToken, uint convertAmount, uint reward);
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);
}


interface TreasuryInterface {

    function convertToSharingToken(address fromToken, uint amount, uint minBuyAmount) external;

    function devWithdraw(uint amount) external;

    function earned(address account) external view returns (uint);

    function stake(uint amount) external;

    function withdraw(uint amount) external;

    function getReward() external;

    function exit() external;

    /*** Admin Functions ***/

    function setDevFundRatio(uint newRatio) external;


    function setDev(address newDev) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IUniswapV2Factory.sol";

abstract contract IUniswapV2Callee {
    IUniswapV2Factory public uniswapFactory;

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;

//    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;
//
//    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount) external virtual view returns (uint) ;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
//mainnet:0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function token0()  external view returns (address);
    function token1()  external view returns (address);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

