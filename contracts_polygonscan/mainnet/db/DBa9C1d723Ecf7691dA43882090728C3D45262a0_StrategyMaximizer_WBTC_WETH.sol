// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../GravityMaximizer.sol";

contract StrategyMaximizer_WBTC_WETH is GravityMaximizer {

    address wbtc_weth_diff;

    function initializeStrategy(
        address _store,
        address _vault
    ) public initializer {
        address farmContract = address(0xa2002c6514387B8386037ea782e626ADc8487fA1);
        address wbtc_weth_lp = address(0x84D49BeFf6AeCF52C461Eae687d959d64eDf2427);
        address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
        address gfi = address(0x874e178A2f3f3F9d34db862453Cd756E7eAb0381);
        address bgfi_weth_lp = address(0xb37e5539C66b207302BcBf1A53A34dD69D9e27c2);
        __Strategy_init(
            _store,
            wbtc_weth_lp,
            _vault,
            farmContract,
            gfi,
            bgfi_weth_lp
        );
        routes[gfi] = [gfi];
        routes[weth] = [gfi, weth];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/swaps/IUniswapV2Pair.sol";
import "../../interfaces/swaps/IUniswapV2Router02.sol";
import "../BaseUpgradeableStrategy.sol";
import "./interfaces/IGFIFarm.sol";

/// @title Gravity Maximizer Strategy
/// @author Chainvisions
/// @notice Maximizer strategy for Gravity Finance.

contract GravityMaximizer is BaseUpgradeableStrategy {
    using SafeERC20 for IERC20;

    address public constant gravityRouter = address(0x57dE98135e8287F163c59cA4fF45f1341b680248);
    mapping(address => address[]) public routes;

    constructor() BaseUpgradeableStrategy() {}

    function __Strategy_init(
        address _storage,
        address _underlying,
        address _vault,
        address _stakingContract,
        address _rewardToken,
        address _targetVault
    )
    public initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _stakingContract,
            _rewardToken,
            true,
            1e16,
            12 hours
        );
        _setTargetVault(_targetVault);

        address targetVaultUnderlying = IVault(targetVault()).underlying();

        routes[IUniswapV2Pair(targetVaultUnderlying).token0()] = new address[](0);
        routes[IUniswapV2Pair(targetVaultUnderlying).token1()] = new address[](0);
    }

    /*
    * Harvests yields generated and reinvests into the underlying. This
    * function call will fail if deposits are paused.
    */
    function doHardWork() external onlyNotPausedInvesting restricted {
        IGFIFarm(rewardPool()).deposit(0);
        _liquidateReward();
        _notifyMaximizerReward();
        _investAllUnderlying();
    }

    /*
    * Transfers out tokens that the contract is holding. One thing to note
    * is that this contract exposes a list of tokens that cannot be salvaged. 
    * This is to ensure that a malicious admin cannot steal from the vault users.
    */
    function salvage(address recipient, address token, uint256 amount) external restricted {
        require(!unsalvagableTokens(token), "Strategy: Unsalvagable token");
        IERC20(token).transfer(recipient, amount);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
        address targetVaultUnderlying = IVault(targetVault()).underlying();
        routes[IUniswapV2Pair(targetVaultUnderlying).token0()] = new address[](0);
        routes[IUniswapV2Pair(targetVaultUnderlying).token1()] = new address[](0);
    }

    /*
    * Current amount of underlying invested.
    */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IERC20(underlying()).balanceOf(address(this));
        }
        return (_rewardPoolStake() + IERC20(underlying()).balanceOf(address(this)));
    }

    /*
    * Withdraws all of the underlying to the vault. This is used in the case
    * of a problem with the strategy or a bug that compromises the safety of the
    * vault's users.
    */
    function withdrawAllToVault() public restricted {
        if(rewardPool() != address(0)) {
            IGFIFarm(rewardPool()).withdraw(_rewardPoolStake());
        }
        _liquidateReward();
        IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
    }

    /*
    * Withdraws `amount` of the underlying to the vault.
    */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        if(amount > IERC20(underlying()).balanceOf(address(this))){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = (amount - IERC20(underlying()).balanceOf(address(this)));
            IGFIFarm(rewardPool()).withdraw(Math.min(_rewardPoolStake(), needToWithdraw));
        }

        IERC20(underlying()).safeTransfer(vault(), amount);
    }

    /*
    * Performs an emergency exit from the farming contract and
    * pauses the strategy.
    */
    function emergencyExit() public onlyGovernance {
        IGFIFarm(rewardPool()).emergencyWithdraw();
        _setPausedInvesting(true);
    }

    /*
    * Re-enables investing into the strategy contract.
    */
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setSell(bool _sell) public onlyGovernance {
        _setSell(_sell);
    }

    function setSellFloor(uint256 _sellFloor) public onlyGovernance {
        _setSellFloor(_sellFloor);
    }

    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == underlying() || token == rewardToken());
    }

    function targetVault() public view returns (address) {
        return _getAddress("targetVault");
    }

    function _investAllUnderlying() internal onlyNotPausedInvesting {
        uint256 underlyingBalance = IERC20(underlying()).balanceOf(address(this));
        if(underlyingBalance > 0) {
            IERC20(underlying()).safeApprove(rewardPool(), 0);
            IERC20(underlying()).safeApprove(rewardPool(), underlyingBalance);
            IGFIFarm(rewardPool()).deposit(underlyingBalance);
        }
    }

    /*
    * Liquidates the reward and collects fees for BELUGA stakers.
    */
    function _liquidateReward() internal {
        uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
        if(!sell() || rewardBalance < sellFloor()) {
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);

        rewardBalance = IERC20(rewardToken()).balanceOf(address(this));

        address targetVaultUnderlying = IVault(targetVault()).underlying();

        address token0 = IUniswapV2Pair(targetVaultUnderlying).token0();
        address token1 = IUniswapV2Pair(targetVaultUnderlying).token1();

        uint256 toToken0 = (rewardBalance / 2);
        uint256 toToken1 = (rewardBalance - toToken0);

        uint256 token0Amount;
        uint256 token1Amount;

        if(routes[token0].length > 1) {
            IERC20(rewardToken()).safeApprove(gravityRouter, 0);
            IERC20(rewardToken()).safeApprove(gravityRouter, toToken0);
            uint256[] memory amounts = IUniswapV2Router02(gravityRouter).swapExactTokensForTokens(toToken0, 0, routes[token0], address(this), (block.timestamp + 600));
            token0Amount = amounts[(amounts.length - 1)];
        } else {
            token0Amount = toToken0;
        }

        if(routes[token1].length > 1) {
            IERC20(rewardToken()).safeApprove(gravityRouter, 0);
            IERC20(rewardToken()).safeApprove(gravityRouter, toToken1);
            uint256[] memory amounts = IUniswapV2Router02(gravityRouter).swapExactTokensForTokens(toToken1, 0, routes[token1], address(this), (block.timestamp + 600));
            token1Amount = amounts[(amounts.length - 1)];
        } else {
            token1Amount = toToken1;
        }

        IERC20(token0).safeApprove(gravityRouter, 0);
        IERC20(token0).safeApprove(gravityRouter, token0Amount);

        IERC20(token1).safeApprove(gravityRouter, 0);
        IERC20(token1).safeApprove(gravityRouter, token1Amount);

        IUniswapV2Router02(gravityRouter).addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, address(this), (block.timestamp + 600));
    }

    function _notifyMaximizerReward() internal {
        address targetVaultUnderlying = IVault(targetVault()).underlying();
        uint256 targetUnderlyingBalance = IERC20(targetVaultUnderlying).balanceOf(address(this));

        if(targetUnderlyingBalance > 0) {
            IERC20(targetVaultUnderlying).safeApprove(targetVault(), 0);
            IERC20(targetVaultUnderlying).safeApprove(targetVault(), targetUnderlyingBalance);
            IVault(targetVault()).deposit(targetUnderlyingBalance);

            uint256 targetVaultBalance = IERC20(targetVault()).balanceOf(address(this));
            IERC20(targetVault()).safeTransfer(vault(), targetVaultBalance);
            IVault(vault()).notifyRewardAmount(targetVault(), targetVaultBalance);
        }
    }

    function _setTargetVault(address _address) internal {
        _setAddress("targetVault", _address);
    }

    function _rewardPoolStake() internal view returns (uint256 stake) {
        (stake, ) = IGFIFarm(rewardPool()).userInfo(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity >=0.5.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IController} from "../interfaces/IController.sol";
import {ControllableInit} from "../ControllableInit.sol";
import {BaseUpgradeableStrategyStorage} from "./BaseUpgradeableStrategyStorage.sol";

contract BaseUpgradeableStrategy is ControllableInit, BaseUpgradeableStrategyStorage {
    using SafeERC20 for IERC20;

    event ProfitsNotCollected(bool sell, bool floor);
    event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

    modifier restricted() {
        require(msg.sender == vault() || msg.sender == controller()
        || msg.sender == governance(),
        "Strategy: The sender has to be the controller, governance, or vault");
        _;
    }

    // This is only used in `investAllUnderlying()`
    // The user can still freely withdraw from the strategy
    modifier onlyNotPausedInvesting() {
        require(!pausedInvesting(), "Strategy: Action blocked as the strategy is in emergency state");
        _;
    }

    constructor() BaseUpgradeableStrategyStorage() {}

    /// @notice Initializes the strategy proxy.
    /// @param _storage Address of the storage contract.
    /// @param _underlying Underlying token of the strategy.
    /// @param _vault Address of the strategy's vault.
    /// @param _rewardPool Address of the reward pool.
    /// @param _rewardToken Address of the reward token.
    /// @param _sell Whether or not `_rewardToken` should be liquidated.
    /// @param _sellFloor Minimum amount of `_rewardToken` to liquidate rewards.
    /// @param _timelockDelay Timelock for changing the proxy's implementation. 
    function initialize(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _rewardToken,
        bool _sell,
        uint256 _sellFloor,
        uint256 _timelockDelay
    ) public initializer {
        __Controllable_init(_storage);
        _setUnderlying(_underlying);
        _setVault(_vault);
        _setRewardPool(_rewardPool);
        _setRewardToken(_rewardToken);

        _setSell(_sell);
        _setSellFloor(_sellFloor);
        _setTimelockDelay(_timelockDelay);
        _setPausedInvesting(false);
    }

    /// @notice Collects protocol fees and sends them to the Controller.
    /// @param _rewardBalance The amount of rewards generated that is to have fees taken from.
    function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
        if( _rewardBalance > 0 ){
            uint256 feeAmount = (_rewardBalance * IController(controller()).profitSharingNumerator()) / IController(controller()).profitSharingDenominator();
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(rewardToken()).safeApprove(controller(), 0);
            IERC20(rewardToken()).safeApprove(controller(), feeAmount);

            IController(controller()).notifyFee(
                rewardToken(),
                feeAmount
            );
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

    /// @notice Determines if the proxy can be upgraded.
    /// @return If an upgrade is possible and the address of the new implementation
    function shouldUpgrade() external view returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Schedules an upgrade to the strategy proxy.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + timelockDelay());
    }

    function _finalizeUpgrade() internal {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGFIFarm {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function emergencyWithdraw() external;
    function userInfo(address _user) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function greyList(address) external view returns (bool);
    function keepers(address) external view returns (bool);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function notifyFee(address, uint256) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {GovernableInit, Storage} from "./GovernableInit.sol";

contract ControllableInit is GovernableInit {

  constructor() {}

  function __Controllable_init(address _storage) public initializer {
    __Governable_init_(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Controllable: Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "Controllable: The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract BaseUpgradeableStrategyStorage {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function underlying() public view returns (address) {
        return _getAddress("underlying");
    }

    function vault() public view returns (address) {
        return _getAddress("vault");
    }

    function rewardPool() public view returns (address) {
        return _getAddress("rewardPool");
    }

    function rewardToken() public view returns (address) {
        return _getAddress("rewardToken");
    }

    function sell() public view returns (bool) {
        return _getBool("sell");
    }

    function sellFloor() public view returns (uint256) {
        return _getUint256("sellFloor");
    }

    function pausedInvesting() public view returns (bool) {
        return _getBool("pausedInvesting");
    }

    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    function timelockDelay() public view returns (uint256) {
        return _getUint256("timelockDelay");
    }

    function _setUnderlying(address _value) internal {
        _setAddress("underlying", _value);
    }

    function _setVault(address _value) internal {
        _setAddress("vault", _value);
    }

    function _setRewardPool(address _value) internal {
        _setAddress("rewardPool", _value);
    }

    function _setRewardToken(address _value) internal {
        _setAddress("rewardToken", _value);
    }

    function _setSell(bool _value) internal {
        _setBool("sell", _value);
    }

    function _setSellFloor(uint256 _value) internal {
        _setUint256("sellFloor", _value);
    }

    function _setPausedInvesting(bool _value) internal {
        _setBool("pausedInvesting", _value);
    }

    function _setNextImplementation(address _value) internal {
        _setAddress("nextImplementation", _value);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setTimelockDelay(uint256 _value) internal {
        _setUint256("timelockDelay", _value);
    }

    function _setUint256(string memory _key, uint256 _value) internal {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setAddress(string memory _key, address _value) internal {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setBool(string memory _key, bool _value) internal {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) internal view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _getAddress(string memory _key) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _getBool(string memory _key) internal view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Storage} from "./Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
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

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
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