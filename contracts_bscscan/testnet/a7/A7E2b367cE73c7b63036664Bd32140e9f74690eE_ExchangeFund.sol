// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Initializable} from "./libraries/Upgradability.sol";
import {Governed} from "./Governance.sol";

/// @dev Thrown when trying to set platform fees that don't sum up to one.
/// @param stabilizationFee The stabilization fee that was tried to set.
/// @param exchangeFee The stabilization fee that was tried to set.
/// @param developmentFee The stabilization fee that was tried to set.
error BaksDAOPlatformFeesDontSumUpToOne(uint256 stabilizationFee, uint256 exchangeFee, uint256 developmentFee);

interface ICore {
    event MinimumPrincipalAmountUpdated(uint256 minimumPrincipalAmount, uint256 newMinimumPrincipalAmount);
    event StabilityFeeUpdated(uint256 stabilityFee, uint256 newStabilityFee);
    event RebalancingThresholdUpdated(uint256 rebalancingThreshold, uint256 newRebalancingThreshold);
    event PlatformFeesUpdated(
        uint256 stabilizationFee,
        uint256 newStabilizationFee,
        uint256 exchangeFee,
        uint256 newExchangeFee,
        uint256 developmentFee,
        uint256 newDevelopmentFee
    );
    event MarginCallLoanToValueRatioUpdated(uint256 marginCallLoanToValueRatio, uint256 newMarginCallLoanToValueRatio);
    event LiquidationLoanToValueRatioUpdated(
        uint256 liqudationLoanToValueRatio,
        uint256 newLiquidationLoanToValueRatio
    );

    event ServicingThresholdUpdated(uint256 servicingThreshold, uint256 newServicingThreshold);
    event MinimumLiquidityUpdated(uint256 minimumLiquidity, uint256 newMinimumLiquidity);

    function minimumPrincipalAmount() external view returns (uint256);

    function stabilityFee() external view returns (uint256);

    function stabilizationFee() external view returns (uint256);

    function exchangeFee() external view returns (uint256);

    function developmentFee() external view returns (uint256);

    function marginCallLoanToValueRatio() external view returns (uint256);

    function liquidationLoanToValueRatio() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function servicingThreshold() external view returns (uint256);

    function minimumLiquidity() external view returns (uint256);
}

contract Core is Initializable, Governed, ICore {
    uint256 internal constant ONE = 100e16;

    uint256 public override minimumPrincipalAmount;
    uint256 public override stabilityFee;
    uint256 public override stabilizationFee;
    uint256 public override exchangeFee;
    uint256 public override developmentFee;
    uint256 public override marginCallLoanToValueRatio;
    uint256 public override liquidationLoanToValueRatio;
    uint256 public override rebalancingThreshold;

    uint256 public override servicingThreshold;
    uint256 public override minimumLiquidity;

    function initialize() external initializer {
        setGovernor(msg.sender);

        minimumPrincipalAmount = 50e18; // 50 BAKS
        stabilityFee = 3e16; // 3 %
        stabilizationFee = 85e16; // 85 %
        exchangeFee = 15e16; // 15 %
        developmentFee = 0;
        marginCallLoanToValueRatio = 75e16; // 75 %
        liquidationLoanToValueRatio = 83e16; // 83 %
        rebalancingThreshold = 1e16; // 1 %

        servicingThreshold = 1e16; // 1%
        minimumLiquidity = 50000e18; // 50000 BAKS
    }

    function setMinimumPrincipalAmount(uint256 newMinimumPrincipalAmount) external onlyGovernor {
        emit StabilityFeeUpdated(minimumPrincipalAmount, newMinimumPrincipalAmount);
        minimumPrincipalAmount = newMinimumPrincipalAmount;
    }

    function setStabilityFee(uint256 newStabilityFee) external onlyGovernor {
        emit StabilityFeeUpdated(stabilityFee, newStabilityFee);
        stabilityFee = newStabilityFee;
    }

    function setPlatformFees(
        uint256 newStabilizationFee,
        uint256 newExchangeFee,
        uint256 newDevelopmentFee
    ) external onlyGovernor {
        if (newStabilizationFee + newExchangeFee + newDevelopmentFee != ONE) {
            revert BaksDAOPlatformFeesDontSumUpToOne(newStabilizationFee, newExchangeFee, newDevelopmentFee);
        }
        emit PlatformFeesUpdated(
            stabilizationFee,
            newStabilizationFee,
            exchangeFee,
            newExchangeFee,
            developmentFee,
            newDevelopmentFee
        );
        stabilizationFee = newStabilizationFee;
        exchangeFee = newExchangeFee;
        developmentFee = newDevelopmentFee;
    }

    function setMarginCallLoanToValueRatio(uint256 newMarginCallLoanToValueRatio) external onlyGovernor {
        emit MarginCallLoanToValueRatioUpdated(marginCallLoanToValueRatio, newMarginCallLoanToValueRatio);
        marginCallLoanToValueRatio = newMarginCallLoanToValueRatio;
    }

    function setLiquidationLoanToValueRatio(uint256 newLiquidationLoanToValueRatio) external onlyGovernor {
        emit LiquidationLoanToValueRatioUpdated(liquidationLoanToValueRatio, newLiquidationLoanToValueRatio);
        liquidationLoanToValueRatio = newLiquidationLoanToValueRatio;
    }

    function setRebalancingThreshold(uint256 newRebalancingThreshold) external onlyGovernor {
        emit RebalancingThresholdUpdated(rebalancingThreshold, newRebalancingThreshold);
        rebalancingThreshold = newRebalancingThreshold;
    }

    function setServicingThreshold(uint256 newServicingThreshold) external onlyGovernor {
        emit ServicingThresholdUpdated(servicingThreshold, newServicingThreshold);
        servicingThreshold = newServicingThreshold;
    }

    function setMinimumLiquidity(uint256 newMinimumLiquidity) external onlyGovernor {
        emit MinimumLiquidityUpdated(minimumLiquidity, newMinimumLiquidity);
        minimumLiquidity = newMinimumLiquidity;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./libraries/AmountNormalization.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Math.sol";
import {Governed} from "./Governance.sol";
import {ICore} from "./Core.sol";
import {Initializable} from "./libraries/Upgradability.sol";
import {IERC20} from "./interfaces/ERC20.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IUniswapV2Factory, IUniswapV2Router, IUniswapV2Pair} from "./interfaces/UniswapV2.sol";

/// @dev Thrown when trying to list depositable token that has zero decimals.
/// @param token The address of the token contract.
error ExchangeFundDepositableTokenZeroDecimals(IERC20 token);

/// @dev Thrown when trying to list depositable token that has too large decimals.
/// @param token The address of the token contract.
error ExchangeFundDepositableTokenTooLargeDecimals(IERC20 token, uint8 decimals);

/// @dev Thrown when trying to list depositable token that's already listed.
/// @param token The address of the token contract.
error ExchangeFundDepositableTokenAlreadyListed(IERC20 token);

/// @dev Thrown when trying to unlist depositable token that's not listed.
/// @param token The address of the token contract.
error ExchangeFundDepositableTokenNotListed(IERC20 token);

/// @dev Thrown when interacting with a token that's not allowed to be deposited.
/// @param token The address of the token contract.
error ExchangeFundTokenNotAllowedToBeDeposited(IERC20 token);

/// @dev Thrown when interacting with a token that's not allowed to be withdrawn.
/// @param token The address of the token contract.
error ExchangeFundTokenNotAllowedToBeWithdrawn(IERC20 token);

/// @dev Thrown when trying to salvage one of depositable tokens or stablecoin.
/// @param token The address of the token contract.
error ExchangeFundTokenNotAllowedToBeSalvaged(IERC20 token);

error ExchangeFundInsufficientDeposits();

error ExchangeFundInsufficientLiquidity();

error ExchangeFundSameTokenSwap(IERC20 token);

/// @dev Thrown when trying to swap token that's not allowed to be swapped.
/// @param token The address of the token contract.
error ExchangeFundTokenNotAllowedToBeSwapped(IERC20 token);

/// @dev Thrown when there's no need to service the `token`/stablecoin pair cause the difference between target and
/// pair price does not exceed servicing threshold.
/// @param token The address of the token contract.
error ExchangeFundNoNeedToService(IERC20 token);

contract ExchangeFund is Initializable, Governed, ReentrancyGuard {
    using AmountNormalization for IERC20;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant ONE = 100e16;
    uint8 internal constant DECIMALS = 18;

    IERC20 public wrappedNativeCurrency;
    ICore public core;
    IERC20 public stablecoin;
    IPriceOracle public priceOracle;
    IUniswapV2Router public uniswapV2Router;

    address public operator;

    uint256 public slippageTolerance;
    uint256 public swapDeadline;

    mapping(address => mapping(IERC20 => uint256)) public deposits;
    mapping(address => mapping(IERC20 => uint256)) public liquidity;

    mapping(IERC20 => bool) public depositableTokens;
    EnumerableAddressSet.Set internal depositableTokensSet;

    event DepositableTokenListed(IERC20 indexed token, IUniswapV2Pair pair);
    event DepositableTokenUnlisted(IERC20 indexed token);

    event SlippageToleranceUpdated(uint256 slippageTolerance, uint256 newSlippageTolerance);
    event SwapDeadlineUpdated(uint256 swapDeadline, uint256 newSwapDeadline);

    event Deposit(address indexed account, IERC20 indexed token, uint256 amount);
    event Swap(address indexed account, IERC20 indexed tokenA, IERC20 indexed tokenB, uint256 amountA, uint256 amountB);
    event Invest(address indexed account, IERC20 indexed token, uint256 amount);
    event Divest(address indexed account, IERC20 indexed token, uint256 amount);
    event Withdrawal(address indexed account, IERC20 indexed token, uint256 amount);
    event Service(address indexed account, IERC20 indexed token);

    modifier tokenAllowedToBeDeposited(IERC20 token) {
        if (!depositableTokensSet.contains(address(token))) {
            revert ExchangeFundTokenNotAllowedToBeDeposited(token);
        }
        _;
    }

    modifier tokenAllowedToBeSwapped(IERC20 token) {
        if (token != stablecoin && !depositableTokensSet.contains(address(token))) {
            revert ExchangeFundTokenNotAllowedToBeSwapped(token);
        }
        _;
    }

    function initialize(
        IERC20 _wrappedNativeCurrency,
        ICore _core,
        IERC20 _stablecoin,
        IPriceOracle _priceOracle,
        IUniswapV2Router _uniswapV2Router,
        address _operator
    ) external initializer {
        setGovernor(msg.sender);

        wrappedNativeCurrency = _wrappedNativeCurrency;

        core = _core;
        stablecoin = _stablecoin;
        priceOracle = _priceOracle;
        uniswapV2Router = _uniswapV2Router;
        operator = _operator;

        slippageTolerance = 5e15; // 0.5 %
        swapDeadline = 20 minutes;

        _stablecoin.approve(address(_uniswapV2Router), type(uint256).max);
    }

    function deposit(IERC20 token, uint256 amount) external nonReentrant tokenAllowedToBeDeposited(token) {
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 normalizedAmount = token.normalizeAmount(amount);
        deposits[msg.sender][token] += normalizedAmount;

        emit Deposit(msg.sender, token, normalizedAmount);
    }

    function swap(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amount,
        bool useWrappedNativeCurrencyAsIntermediateToken
    ) external nonReentrant tokenAllowedToBeSwapped(tokenA) tokenAllowedToBeSwapped(tokenB) {
        uint256 normalizedAmount = tokenA.normalizeAmount(amount);
        if (normalizedAmount > deposits[msg.sender][tokenA]) {
            revert ExchangeFundInsufficientDeposits();
        }

        if (tokenA == tokenB) {
            revert ExchangeFundSameTokenSwap(tokenA);
        }

        IERC20[] memory path = new IERC20[](useWrappedNativeCurrencyAsIntermediateToken ? 3 : 2);
        path[0] = tokenA;
        path[1] = useWrappedNativeCurrencyAsIntermediateToken ? wrappedNativeCurrency : tokenB;
        if (useWrappedNativeCurrencyAsIntermediateToken) {
            path[2] = tokenB;
        }

        uint256[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        uint256 normalizedAmountOut = tokenB.normalizeAmount(amounts[amounts.length - 1]);

        amounts = uniswapV2Router.swapExactTokensForTokens(
            amount,
            tokenB.denormalizeAmount(normalizedAmountOut.mul(ONE - slippageTolerance)),
            path,
            address(this),
            block.timestamp + swapDeadline
        );

        uint256 normalizedTokenAAmount = tokenA.normalizeAmount(amounts[0]);
        uint256 normalizedTokenBAmount = tokenB.normalizeAmount(amounts[amounts.length - 1]);

        deposits[msg.sender][tokenA] -= normalizedTokenAAmount;
        deposits[msg.sender][tokenB] += normalizedTokenBAmount;

        emit Swap(msg.sender, tokenA, tokenB, normalizedTokenAAmount, normalizedTokenBAmount);
    }

    function invest(IERC20 token, uint256 amount) external nonReentrant {
        uint256 normalizedAmount = token.normalizeAmount(amount);
        if (normalizedAmount > deposits[msg.sender][token]) {
            revert ExchangeFundInsufficientDeposits();
        }

        uint256 tokenValue = quote(token, amount);
        (, uint256 amountSent, uint256 liquidityMinted) = uniswapV2Router.addLiquidity(
            stablecoin,
            token,
            tokenValue,
            amount,
            tokenValue.mul(ONE - slippageTolerance),
            token.denormalizeAmount(normalizedAmount.mul(ONE - slippageTolerance)),
            address(this),
            block.timestamp + swapDeadline
        );

        deposits[msg.sender][token] -= token.normalizeAmount(amountSent);
        liquidity[msg.sender][token] += liquidityMinted;

        emit Invest(msg.sender, token, normalizedAmount);
    }

    function divest(IERC20 token, uint256 amount) external nonReentrant {
        if (amount > liquidity[msg.sender][token]) {
            revert ExchangeFundInsufficientLiquidity();
        }

        (, uint256 amountReceived) = uniswapV2Router.removeLiquidity(
            stablecoin,
            token,
            amount,
            0,
            0,
            address(this),
            block.timestamp + swapDeadline
        );

        deposits[msg.sender][token] += token.normalizeAmount(amountReceived);
        liquidity[msg.sender][token] -= amount;

        emit Divest(msg.sender, token, amount);
    }

    function withdraw(IERC20 token, uint256 amount) external nonReentrant {
        if (token == stablecoin) {
            revert ExchangeFundTokenNotAllowedToBeWithdrawn(token);
        }

        uint256 normalizedAmount = token.normalizeAmount(amount);
        if (normalizedAmount > deposits[msg.sender][token]) {
            revert ExchangeFundInsufficientDeposits();
        }

        deposits[msg.sender][token] -= normalizedAmount;
        token.safeTransfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, normalizedAmount);
    }

    function listDepositableToken(IERC20 token) external onlyGovernor {
        if (depositableTokensSet.contains(address(token))) {
            revert ExchangeFundDepositableTokenAlreadyListed(token);
        }

        uint8 decimals = token.decimals();
        if (decimals == 0) {
            revert ExchangeFundDepositableTokenZeroDecimals(token);
        }
        if (decimals > DECIMALS) {
            revert ExchangeFundDepositableTokenTooLargeDecimals(token, decimals);
        }

        if (depositableTokensSet.add(address(token))) {
            token.approve(address(uniswapV2Router), type(uint256).max);

            IUniswapV2Factory uniswapV2Factory = uniswapV2Router.factory();
            IUniswapV2Pair uniswapV2Pair = uniswapV2Factory.getPair(stablecoin, token);
            if (address(uniswapV2Pair) == address(0)) {
                uniswapV2Pair = uniswapV2Factory.createPair(stablecoin, token);
            }
            uniswapV2Pair.approve(address(uniswapV2Router), type(uint256).max);

            depositableTokens[token] = true;
            emit DepositableTokenListed(token, uniswapV2Pair);
        }
    }

    function unlistDepositableToken(IERC20 token) external onlyGovernor {
        if (!depositableTokensSet.contains(address(token))) {
            revert ExchangeFundDepositableTokenNotListed(token);
        }

        if (depositableTokensSet.remove(address(token))) {
            token.approve(address(uniswapV2Router), 0);

            IUniswapV2Factory uniswapV2Factory = uniswapV2Router.factory();
            IUniswapV2Pair uniswapV2Pair = uniswapV2Factory.getPair(stablecoin, token);
            if (address(uniswapV2Pair) != address(0)) {
                uniswapV2Pair.approve(address(uniswapV2Router), 0);
            }

            delete depositableTokens[token];
            emit DepositableTokenUnlisted(token);
        }
    }

    function setSlippageTolerance(uint256 newSlippageTolerance) external onlyGovernor {
        emit SlippageToleranceUpdated(slippageTolerance, newSlippageTolerance);
        slippageTolerance = newSlippageTolerance;
    }

    function setSwapDeadline(uint256 newSwapDeadline) external onlyGovernor {
        emit SwapDeadlineUpdated(swapDeadline, newSwapDeadline);
        swapDeadline = newSwapDeadline;
    }

    function salvage(IERC20 token) external onlyGovernor {
        address tokenAddress = address(token);
        if (token == stablecoin || depositableTokensSet.contains(tokenAddress)) {
            revert ExchangeFundTokenNotAllowedToBeSalvaged(token);
        }
        token.safeTransfer(operator, token.balanceOf(address(this)));
    }

    function service(IERC20 token) external {
        (uint256 stablecoinReserve, uint256 tokenReserve) = getReserves(token);
        tokenReserve = token.normalizeAmount(tokenReserve);

        uint256 targetPrice = priceOracle.getNormalizedPrice(token);
        uint256 price = stablecoinReserve.div(tokenReserve);
        int256 delta = int256(price.div(targetPrice)) - int256(ONE);
        if (Math.abs(delta) < core.servicingThreshold()) {
            revert ExchangeFundNoNeedToService(token);
        }

        int256 amountOut;
        IERC20[] memory path = new IERC20[](2);
        if (price > targetPrice) {
            amountOut =
                int256(Math.fpsqrt(stablecoinReserve.mul(tokenReserve).mul(targetPrice))) -
                int256(stablecoinReserve);
            path[0] = token;
            path[1] = stablecoin;
        } else {
            amountOut = int256(Math.fpsqrt(stablecoinReserve.mulDiv(tokenReserve, targetPrice))) - int256(tokenReserve);
            path[0] = stablecoin;
            path[1] = token;
        }

        // NOTE: using this instead of `swapExactTokensForTokens` to shift responsibility for calculating fees to  *swap
        // itself.
        uniswapV2Router.swapTokensForExactTokens(
            Math.abs(amountOut),
            type(uint256).max,
            path,
            address(this),
            block.timestamp + swapDeadline
        );

        topUpLiquidity(token);

        emit Service(msg.sender, token);
    }

    function getDepositableTokens() external view returns (IERC20[] memory tokens) {
        uint256 length = depositableTokensSet.elements.length;
        tokens = new IERC20[](length);

        for (uint256 i = 0; i < length; i++) {
            tokens[i] = IERC20(depositableTokensSet.elements[i]);
        }
    }

    function topUpLiquidity(IERC20 token) internal {
        (uint256 stablecoinReserve, uint256 tokenReserve) = getReserves(token);
        tokenReserve = token.normalizeAmount(tokenReserve);

        if (core.minimumLiquidity() > stablecoinReserve) {
            uint256 amountADesired = core.minimumLiquidity() - stablecoinReserve;
            uint256 amountBDesired = token.denormalizeAmount(amountADesired.div(stablecoinReserve.div(tokenReserve)));
            uniswapV2Router.addLiquidity(
                stablecoin,
                token,
                amountADesired,
                amountBDesired,
                amountADesired.mul(ONE - slippageTolerance),
                token.denormalizeAmount(amountBDesired.mul(ONE - slippageTolerance)),
                address(this),
                block.timestamp + swapDeadline
            );
        }
    }

    function quote(IERC20 token, uint256 amount) internal view returns (uint256 stablecoinAmount) {
        IUniswapV2Pair uniswapV2Pair = uniswapV2Router.factory().getPair(stablecoin, token);

        (uint256 reserveA, uint256 reserveB, ) = uniswapV2Pair.getReserves();
        if (reserveA == 0 || reserveB == 0) {
            stablecoinAmount = token.normalizeAmount(amount).mul(priceOracle.getNormalizedPrice(token));
            return stablecoinAmount;
        }

        stablecoinAmount = address(stablecoin) < address(token)
            ? uniswapV2Router.quote(amount, reserveB, reserveA)
            : uniswapV2Router.quote(amount, reserveA, reserveB);
    }

    function getReserves(IERC20 token) internal view returns (uint256 stablecoinReserve, uint256 tokenReserve) {
        IUniswapV2Pair uniswapV2Pair = uniswapV2Router.factory().getPair(stablecoin, token);

        (uint256 reserveA, uint256 reserveB, ) = uniswapV2Pair.getReserves();
        if (address(stablecoin) < address(token)) {
            stablecoinReserve = reserveA;
            tokenReserve = reserveB;
        } else {
            tokenReserve = reserveA;
            stablecoinReserve = reserveB;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";
import "./../libraries/FixedPointMath.sol";

/// @notice Thrown when oracle doesn't provide price for `token` token.
/// @param token The address of the token contract.
error PriceOracleTokenUnknown(IERC20 token);
/// @notice Thrown when oracle provide stale price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleStalePrice(IERC20 token, uint256 price);
/// @notice Thrown when oracle provide negative, zero or in other ways invalid price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleInvalidPrice(IERC20 token, int256 price);

interface IPriceOracle {
    /// @notice Gets normalized to 18 decimals price for the `token` token.
    /// @param token The address of the token contract.
    /// @return normalizedPrice Normalized price.
    function getNormalizedPrice(IERC20 token) external view returns (uint256 normalizedPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Factory {
    function createPair(IERC20 tokenA, IERC20 tokenB) external returns (IUniswapV2Pair pair);

    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Pair pair);
}

interface IUniswapV2Router {
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
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

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, IERC20[] calldata path) external view returns (uint256[] memory amounts);

    function factory() external view returns (IUniswapV2Factory);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";

library AmountNormalization {
    uint8 internal constant DECIMALS = 18;

    function normalizeAmount(IERC20 self, uint256 denormalizedAmount) internal view returns (uint256 normalizedAmount) {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return denormalizedAmount * scale;
        }
        return denormalizedAmount;
    }

    function denormalizeAmount(IERC20 self, uint256 normalizedAmount)
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return normalizedAmount / scale;
        }
        return normalizedAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library EnumerableAddressSet {
    struct Set {
        address[] elements;
        mapping(address => uint256) indexes;
    }

    function add(Set storage self, address element) internal returns (bool) {
        if (contains(self, element)) {
            return false;
        }

        self.elements.push(element);
        self.indexes[element] = self.elements.length;

        return true;
    }

    function remove(Set storage self, address element) internal returns (bool) {
        uint256 elementIndex = indexOf(self, element);
        if (elementIndex == 0) {
            return false;
        }

        uint256 indexToRemove = elementIndex - 1;
        uint256 lastIndex = count(self) - 1;
        if (indexToRemove != lastIndex) {
            address lastElement = self.elements[lastIndex];
            self.elements[indexToRemove] = lastElement;
            self.indexes[lastElement] = elementIndex;
        }
        self.elements.pop();
        delete self.indexes[element];

        return true;
    }

    function indexOf(Set storage self, address element) internal view returns (uint256) {
        return self.indexes[element];
    }

    function contains(Set storage self, address element) internal view returns (bool) {
        return indexOf(self, element) != 0;
    }

    function count(Set storage self) internal view returns (uint256) {
        return self.elements.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Math {
    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
        uint256 xAux = x;
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        uint256 repeat = 7;
        while (repeat > 0) {
            result = (result + x / result) >> 1;
            repeat--;
        }
        uint256 roundedDownResult = x / result;

        return result >= roundedDownResult ? roundedDownResult : result;
    }

    function fpsqrt(uint256 a) internal pure returns (uint256 result) {
        if (a == 0) result = 0;
        else result = sqrt(a) * 1e9;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error ReentrancyGuardReentrantCall();

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private status;

    modifier nonReentrant() {
        if (status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }

    constructor() {
        status = NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";
import "./Address.sol";

error SafeERC20NoReturnData();

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IERC20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeERC20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeERC20NoReturnData();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Address.sol";

error EIP1967ImplementationIsNotContract(address implementation);
error ContractAlreadyInitialized();
error OnlyProxyCallAllowed();
error OnlyCurrentImplementationAllowed();

library EIP1967 {
    using Address for address;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed newImplementation);

    function upgradeTo(address newImplementation) internal {
        if (!newImplementation.isContract()) {
            revert EIP1967ImplementationIsNotContract(newImplementation);
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);
    }

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Proxy {
    using Address for address;

    constructor(address implementation, bytes memory data) {
        EIP1967.upgradeTo(implementation);
        implementation.delegateCall(data, "Proxy: construction failed");
    }

    receive() external payable {
        delegateCall();
    }

    fallback() external payable {
        delegateCall();
    }

    function delegateCall() internal {
        address implementation = EIP1967.getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

abstract contract Upgradeable {
    address private immutable self = address(this);

    modifier onlyProxy() {
        if (address(this) == self) {
            revert OnlyProxyCallAllowed();
        }
        if (EIP1967.getImplementation() != self) {
            revert OnlyCurrentImplementationAllowed();
        }
        _;
    }

    function upgradeTo(address newImplementation) public virtual onlyProxy {
        EIP1967.upgradeTo(newImplementation);
    }
}

abstract contract Initializable {
    bool private initializing;
    bool private initialized;

    modifier initializer() {
        if (!initializing && initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }
}