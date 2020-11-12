// File: contracts/vaults/IStrategy.sol

/*
 A strategy must implement the following functions:
 - getName(): Name of strategy
 - want(): Desired token for investment. Should be same as underlying vault token (Eg. USDC)
 - deposit function that will calls controller.earn()
 - withdraw(address): For miscellaneous tokens, must exclude any tokens used in the yield
    - Should return to Controller
 - withdraw(uint): Controller | Vault role - withdraw should always return to vault
 - withdrawAll(): Controller | Vault role - withdraw should always return to vault
 - balanceOf(): Should return underlying vault token amount
*/

pragma solidity 0.5.17;


interface IStrategy {
    function getName() external pure returns (string memory);
    function want() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external returns (uint256);
    function balanceOf() external view returns (uint256);
}

// File: contracts/IERC20.sol

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.5.17;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/ITreasury.sol

pragma solidity 0.5.17;



interface ITreasury {
    function defaultToken() external view returns (IERC20);
    function deposit(IERC20 token, uint256 amount) external;
    function withdraw(uint256 amount, address withdrawAddress) external;
}

// File: contracts/vaults/IVault.sol

pragma solidity 0.5.17;



interface IVault {
    function want() external view returns (IERC20);
    function transferFundsToStrategy(address strategy, uint256 amount) external;
    function availableFunds() external view returns (uint256);
}

// File: contracts/vaults/IVaultRewards.sol

pragma solidity 0.5.17;



interface IVaultRewards {
    function want() external view returns (IERC20);
    function notifyRewardAmount(uint256 reward) external;
}

// File: contracts/vaults/IController.sol

pragma solidity 0.5.17;






interface IController {
    function currentEpochTime() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function rewards(address token) external view returns (IVaultRewards);
    function vault(address token) external view returns (IVault);
    function allowableAmount(address) external view returns (uint256);
    function treasury() external view returns (ITreasury);
    function approvedStrategies(address, address) external view returns (bool);
    function getHarvestInfo(address strategy, address user)
        external view returns (
        uint256 vaultRewardPercentage,
        uint256 hurdleAmount,
        uint256 harvestPercentage
    );
    function withdraw(address, uint256) external;
    function earn(address, uint256) external;
    function increaseHurdleRate(address token) external;
}

// File: contracts/ISwapRouter.sol

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.5.17;


interface SwapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}

// File: contracts/SafeMath.sol

pragma solidity 0.5.17;

// Note: This file has been modified to include the sqrt function for quadratic voting
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
    * Imported from: https://github.com/alianse777/solidity-standard-library/blob/master/Math.sol
    * @dev Compute square root of x
    * @return sqrt(x)
    */
   function sqrt(uint256 x) internal pure returns (uint256) {
       uint256 n = x / 2;
       uint256 lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2;
       }
       return uint256(n);
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/zeppelin/Address.sol

pragma solidity 0.5.17;


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/zeppelin/SafeERC20.sol

pragma solidity 0.5.17;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/vaults/strategy/MStableStrategy.sol

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.5.17;






interface IBPT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address whom) external view returns (uint);
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);
    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);
}

interface IMPool {
    function balanceOf(address _account) external view returns (uint256);
    function earned(address _account) external view returns (uint256, uint256);
    function stake(uint256 _amount) external;
    function claimReward() external;
    function exit() external;
}

interface IMTAGov {
    function balanceOf(address _account) external view returns (uint256);
    function earned(address _account) external view returns (uint256);
    function createLock(uint256 _value, uint256 _unlockTime) external;
    function withdraw() external;
    function increaseLockAmount(uint256 _value) external;
    function claimReward() external;
}


contract MStableStrat is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant PERFORMANCE_FEE = 500; // 5%
    uint256 public constant DENOM = 10000;
    uint256 public hurdleLastUpdateTime;
    uint256 public harvestAmountThisEpoch;
    uint256 public strategistCollectedFee;
    uint256 public numPools = 1;

    IERC20 internal usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal musd = IERC20(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    IERC20 internal mta = IERC20(0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2);

    IBPT internal musdcBpt = IBPT(0x72Cd8f4504941Bf8c5a21d1Fd83A96499FD71d2C);

    SwapRouter public swapRouter = SwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IMPool internal mPool = IMPool(0x881c72D1e6317f10a1cDCBe05040E7564E790C80);
    IMTAGov internal mtaGov = IMTAGov(0xaE8bC96DA4F9A9613c323478BE181FDb2Aa0E1BF);

    IERC20 public want = usdc; // should be set only in constructor or hardcoded
    IController public controller; // should be set only in constructor

    address public strategist; // mutable, but only by strategist

    // want must be equal to an underlying vault token (Eg. USDC)
    constructor(IController _controller) public {
        controller = _controller;
        strategist = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "MstableStrategy";
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
    }

    function setNumPoolsForSwap(uint256 _numPools) external {
        require(msg.sender == strategist, "!strategist");
        numPools = _numPools;
    }

    function setAllowances(IERC20 token, address[] calldata recipients, bool isIncrease) external {
        require(msg.sender == strategist, "!strategist");
        for (uint i = 0; i < recipients.length; i++) {
            require(
                recipients[i] == address(musdcBpt) ||
                recipients[i] == address(swapRouter) ||
                recipients[i] == address(mPool) ||
                recipients[i] == address(mtaGov),
                "bad recipient"
            );
            uint256 allowance = isIncrease ? uint256(-1) : 0;
            token.safeApprove(recipients[i], allowance);
        }
    }

    // Assumed that caller checks against available funds in vault
    function deposit(uint256 amount) public {
        uint256 availFunds = controller.allowableAmount(address(this));
        require(amount <= availFunds, "exceed contAllowance");
        controller.earn(address(this), amount);

        // deposit into musdcBpt
        uint256 bptTokenAmt = musdcBpt.joinswapExternAmountIn(address(want), amount, 0);

        // deposit into mstable pool
        mPool.stake(bptTokenAmt);

        // deposit any MTA token in this contract into mStaking contract
        depositMTAInStaking();
    }

    function balanceOf() external view returns (uint256) {
        // get balance in mPool
        uint256 bptStakeAmt = mPool.balanceOf(address(this));

        // get usdc + musd amts in BPT, and total BPT
        uint256 usdcAmt = usdc.balanceOf(address(musdcBpt));
        uint256 musdAmt = musd.balanceOf(address(musdcBpt));
        uint256 totalBptAmt = musdcBpt.totalSupply();

        // convert musd to usdc
        usdcAmt = usdcAmt.add(
            musdAmt.mul(1e18).div(musdcBpt.getSpotPrice(address(musd), address(usdc)))
        );

        return bptStakeAmt.mul(usdcAmt).div(totalBptAmt);
    }

    function earned() external view returns (uint256) {
        (uint256 earnedAmt,) = mPool.earned(address(this));
        return earnedAmt.add(mtaGov.earned(address(this)));
    }

    function withdraw(address token) external {
        IERC20 erc20Token = IERC20(token);
        require(msg.sender == address(controller), "!controller");
        erc20Token.safeTransfer(address(controller), erc20Token.balanceOf(address(this)));
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == address(controller), "!controller");

        // exit fully
        mPool.exit();

        // convert to desired amount
        musdcBpt.exitswapExternAmountOut(address(want), amount, uint256(-1));

        // deposit whatever remaining bpt back into mPool
        mPool.stake(musdcBpt.balanceOf(address(this)));

        // send funds to vault
        want.safeTransfer(address(controller.vault(address(want))), amount);
    }

    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == address(controller), "!controller");

        // exit fully
        mPool.exit();

        // convert reward to want tokens
        // in case swap fails, continue
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "exchangeRewardForWant(bool)",
                true
            )
        );
        // to remove compiler warning
        success;

        // convert bpt to want tokens
        musdcBpt.exitswapPoolAmountIn(
            address(want),
            musdcBpt.balanceOf(address(this)),
            0
        );

        // exclude collected strategist fee
        balance = want.balanceOf(address(this)).sub(strategistCollectedFee);
        // send funds to vault
        want.safeTransfer(address(controller.vault(address(want))), balance);
    }

    function harvest(bool claimMPool, bool claimGov) external {
        if (claimMPool) mPool.claimReward();
        if (claimGov) mtaGov.claimReward();

        // convert 80% reward to want tokens
        // in case swap fails, return
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "exchangeRewardForWant(bool)",
                false
            )
        );
        // to remove compiler warning
        if (!success) return;

        uint256 amount = want.balanceOf(address(this)).sub(strategistCollectedFee);
        uint256 vaultRewardPercentage;
        uint256 hurdleAmount;
        uint256 harvestPercentage;
        uint256 epochTime;
        (vaultRewardPercentage, hurdleAmount, harvestPercentage) =
            controller.getHarvestInfo(address(this), msg.sender);

        // check if harvest amount has to be reset
        if (hurdleLastUpdateTime < epochTime) {
            // reset collected amount
            harvestAmountThisEpoch = 0;
        }
        // update variables
        hurdleLastUpdateTime = block.timestamp;
        harvestAmountThisEpoch = harvestAmountThisEpoch.add(amount);

        // first, take harvester fee
        uint256 harvestFee = amount.mul(harvestPercentage).div(DENOM);
        want.safeTransfer(msg.sender, harvestFee);

        uint256 fee;
        // then, if hurdle amount has been exceeded, take performance fee
        if (harvestAmountThisEpoch >= hurdleAmount) {
            fee = amount.mul(PERFORMANCE_FEE).div(DENOM);
            strategistCollectedFee = strategistCollectedFee.add(fee);
        }

        // do the subtraction of harvester and strategist fees
        amount = amount.sub(harvestFee).sub(fee);

        // calculate how much is to be re-invested
        // fee = vault reward amount, reusing variable
        fee = amount.mul(vaultRewardPercentage).div(DENOM);
        want.safeTransfer(address(controller.rewards(address(want))), fee);
        controller.rewards(address(want)).notifyRewardAmount(fee);
        amount = amount.sub(fee);

        // finally, use remaining want amount for reinvestment
        amount = musdcBpt.joinswapExternAmountIn(address(want), amount, 0);

        // deposit into mstable pool
        mPool.stake(amount);

        // deposit any MTA token in this contract into mStaking contract
        depositMTAInStaking();
    }

    function withdrawStrategistFee() external {
        strategistCollectedFee = 0;
        want.safeTransfer(strategist, strategistCollectedFee);
    }

    function exitMGov() external {
        mtaGov.withdraw();
        // convert to want tokens
        // in case swap fails, continue
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "exchangeRewardForWant(bool)",
                true
            )
        );
        // to remove compiler warning
        success;
        want.safeTransfer(
            address(controller.rewards(address(want))),
            want.balanceOf(address(this)).sub(strategistCollectedFee)
        );
    }

    function exchangeRewardForWant(bool exchangeAll) public {
        uint256 swapAmt = mta.balanceOf(address(this));
        if (swapAmt == 0) return;

        // do the exchange
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(mta);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(want);

        swapRouter.swapExactTokensForTokens(
            exchangeAll ? swapAmt : swapAmt.mul(8000).div(DENOM),
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );
    }

    function depositMTAInStaking() internal {
        uint256 mtaBal = mta.balanceOf(address(this));
        if (mtaBal == 0) return;
        if (mtaGov.balanceOf(address(this)) == 0) {
            // create lock with max time
            mtaGov.createLock(mtaBal, 1632580257);
        } else {
            // increase amount
            mtaGov.increaseLockAmount(mtaBal);
        }
    }
}