// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import '../interfaces/IDecreaseWithV3FlashswapMultihopConnector.sol';
import '../../modules/Lender/LendingDispatcher.sol';
import '../../modules/FundsManager/FundsManager.sol';
import '../../modules/Flashswapper/FlashswapStorage.sol';

contract DecreaseWithV3FlashswapMultihopConnector is
    LendingDispatcher,
    FundsManager,
    FlashswapStorage,
    IDecreaseWithV3FlashswapMultihopConnector
{
    using Path for bytes;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    /// @dev See Uniswap V3 's TickMath
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    bytes4 internal constant UNISWAPV3_SWAP_CALLBACK_SIG =
        bytes4(keccak256('uniswapV3SwapCallback(int256,int256,bytes)'));
    bytes4 internal constant UNISWAPV3_FLASH_CALLBACK_SIG =
        bytes4(keccak256('uniswapV3FlashCallback(uint256,uint256,bytes)'));

    uint256 private immutable rewardsFactor;
    address private immutable SELF_ADDRESS;
    address private immutable factory;

    constructor(
        uint256 _principal,
        uint256 _profit,
        uint256 _rewardsFactor,
        address _holder,
        address _factory
    ) public FundsManager(_principal, _profit, _holder) {
        SELF_ADDRESS = address(this);
        rewardsFactor = _rewardsFactor;
        factory = _factory;
    }

    function decreasePositionWithV3FlashswapMultihop(DecreaseWithV3FlashswapMultihopConnectorParams calldata params)
        external
        override
        onlyAccountOwner
    {
        _verifySetup(params.platform, params.supplyToken, params.borrowToken);

        address lender = getLender(params.platform); // Get it once, pass it around and use when needed

        uint256 positionDebt = getBorrowBalance(lender, params.platform, params.borrowToken); // Same as above

        if (positionDebt == 0) {
            require(params.withdrawAmount == uint256(-1));
            uint256 withdrawableAmount = getSupplyBalance(lender, params.platform, params.supplyToken);
            redeemSupply(lender, params.platform, params.supplyToken, withdrawableAmount);
            withdraw(withdrawableAmount, withdrawableAmount);
            claimRewards();
            return;
        }

        uint256 debtToRepay = params.borrowTokenRepayAmount > positionDebt
            ? positionDebt
            : params.borrowTokenRepayAmount;

        if (params.supplyToken != params.borrowToken) {
            exactOutputInternal(
                // If specified debt to repay is over the position debt, cap it (full debt repayment)
                debtToRepay,
                SwapCallbackData(
                    params.withdrawAmount,
                    params.maxSupplyTokenRepayAmount,
                    params.borrowTokenRepayAmount,
                    positionDebt,
                    params.platform,
                    lender,
                    params.path
                )
            );
        } else {
            requestFlashloan(
                params.supplyToken,
                FlashCallbackData(
                    params.withdrawAmount,
                    debtToRepay,
                    positionDebt,
                    params.platform,
                    lender,
                    params.path
                )
            );
        }

        // If withdrawing completely, assume full position closure
        if (params.withdrawAmount == uint256(-1)) {
            claimRewards();
        }
    }

    /*************************************/
    /************* Flashswap *************/
    /*************************************/

    /// @dev Performs a single exact output swap
    function exactOutputInternal(uint256 amountOut, SwapCallbackData memory data) private {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;
        address pool = getPool(tokenIn, tokenOut, fee);

        _setExpectedCallback(pool, UNISWAPV3_SWAP_CALLBACK_SIG);

        (int256 amount0Delta, int256 amount1Delta) = IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));

        // Required as in UniswapRouter: not tested
        require(amountOutReceived == amountOut, 'DWV3FMC2');
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();

        // Required as in UniswapRouter: not tested
        require(amount0Delta > 0 || amount1Delta > 0, 'DWV3FMC3'); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address receivedToken, address owedToken, ) = data.path.decodeFirstPool();

        if (receivedToken == simplePositionStore().borrowToken) {
            repayBorrow(
                data.lender,
                data.platform,
                receivedToken,
                uint256(amount0Delta < 0 ? -amount0Delta : -amount1Delta)
            );
        }

        uint256 amountToPay = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

        if (data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, data);
        } else {
            require(owedToken == simplePositionStore().supplyToken, 'DWV3FMC4');
            require(amountToPay <= data.maxSupplyTokenRepayAmount, 'DWV3FMC5');

            uint256 deposit = getSupplyBalance(data.lender, data.platform, owedToken);

            uint256 withdrawableAmount = deposit.sub(amountToPay);
            uint256 amountToWithdraw = withdrawableAmount < data.withdrawAmount
                ? withdrawableAmount
                : data.withdrawAmount;

            redeemSupply(data.lender, data.platform, owedToken, amountToWithdraw + amountToPay);

            if (amountToWithdraw > 0) {
                uint256 positionValue = deposit.sub(
                    data
                        .positionDebt
                        .mul(getReferencePrice(data.lender, data.platform, simplePositionStore().borrowToken))
                        .div(getReferencePrice(data.lender, data.platform, owedToken))
                );
                withdraw(amountToWithdraw, positionValue);
            }
        }
        IERC20(owedToken).safeTransfer(msg.sender, amountToPay);
    }

    /*************************************/
    /************* Flashloan *************/
    /*************************************/

    function requestFlashloan(address token, FlashCallbackData memory data) internal {
        (address tokenA, address tokenB, uint24 fee) = data.path.decodeFirstPool();
        address pool = getPool(tokenA, tokenB, fee);
        _setExpectedCallback(pool, UNISWAPV3_FLASH_CALLBACK_SIG);

        bool flashToken0;

        if (token == tokenA) {
            flashToken0 = tokenA < tokenB;
        } else if (token == tokenB) {
            flashToken0 = tokenB < tokenA;
        } else {
            revert('DWV3FMC7');
        }

        IUniswapV3PoolActions(pool).flash(
            address(this),
            flashToken0 ? data.repayAmount : 0,
            flashToken0 ? 0 : data.repayAmount,
            abi.encode(data)
        );
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();
        FlashCallbackData memory data = abi.decode(_data, (FlashCallbackData));

        address supplyToken = simplePositionStore().supplyToken;
        uint256 owedAmount = fee0 > 0 ? data.repayAmount + fee0 : data.repayAmount + fee1;

        repayBorrow(data.lender, data.platform, supplyToken, data.repayAmount);

        uint256 deposit = getSupplyBalance(data.lender, data.platform, supplyToken);

        uint256 withdrawableAmount = deposit.sub(owedAmount);
        uint256 amountToWithdraw = withdrawableAmount < data.withdrawAmount ? withdrawableAmount : data.withdrawAmount;

        redeemSupply(data.lender, data.platform, supplyToken, amountToWithdraw + owedAmount);

        if (amountToWithdraw > 0) {
            withdraw(amountToWithdraw, simplePositionStore().principalValue);
        }

        IERC20(supplyToken).safeTransfer(msg.sender, owedAmount);
    }

    function _verifySetup(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal view {
        requireSimplePositionDetails(platform, supplyToken, borrowToken);
    }

    function _setExpectedCallback(address pool, bytes4 expectedCallbackSig) internal {
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = expectedCallbackSig;
        flashswapStore().expectedCaller = pool;
    }

    function _verifyCallbackAndClear() internal {
        // Verify and clear authorisations for callbacks
        require(msg.sender == flashswapStore().expectedCaller, 'DWV3FMC6');
        delete flashswapStore().expectedCaller;
        delete aStore().callbackTarget;
        delete aStore().expectedCallbackSig;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address) {
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    function claimRewards() private {
        require(isSimplePosition(), 'SP1');
        address lender = getLender(simplePositionStore().platform);

        (address rewardsToken, uint256 rewardsAmount) = claimRewards(lender, simplePositionStore().platform);
        if (rewardsToken != address(0)) {
            uint256 subsidy = rewardsAmount.mul(rewardsFactor) / MANTISSA;
            if (subsidy > 0) {
                IERC20(rewardsToken).safeTransfer(holder, subsidy);
            }
            if (rewardsAmount > subsidy) {
                IERC20(rewardsToken).safeTransfer(accountOwner(), rewardsAmount - subsidy);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct DecreaseWithV3FlashswapMultihopConnectorParams {
    uint256 withdrawAmount; // Amount that will be withdrawn
    uint256 maxSupplyTokenRepayAmount; // Max amount of supply that will be used to repay the debt (slippage is enforced here)
    uint256 borrowTokenRepayAmount; // Amount of debt that will be repaid
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    bytes path;
}

// Struct that is received by UniswapV3SwapCallback
struct SwapCallbackData {
    uint256 withdrawAmount;
    uint256 maxSupplyTokenRepayAmount;
    uint256 borrowTokenRepayAmount;
    uint256 positionDebt;
    address platform;
    address lender;
    bytes path;
}

struct FlashCallbackData {
    uint256 withdrawAmount;
    uint256 repayAmount;
    uint256 positionDebt;
    address platform;
    address lender;
    bytes path;
}

interface IDecreaseWithV3FlashswapMultihopConnector {
    function decreasePositionWithV3FlashswapMultihop(DecreaseWithV3FlashswapMultihopConnectorParams calldata params)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Address.sol';

import './ILendingPlatform.sol';
import '../../core/interfaces/ILendingPlatformAdapterProvider.sol';
import '../../modules/FoldingAccount/FoldingAccountStorage.sol';

contract LendingDispatcher is FoldingAccountStorage {
    using Address for address;

    function getLender(address platform) internal view returns (address) {
        return ILendingPlatformAdapterProvider(aStore().foldingRegistry).getPlatformAdapter(platform);
    }

    function getCollateralUsageFactor(address adapter, address platform)
        internal
        returns (uint256 collateralUsageFactor)
    {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getCollateralUsageFactor.selector, platform)
        );
        return abi.decode(returnData, (uint256));
    }

    function getCollateralFactorForAsset(
        address adapter,
        address platform,
        address asset
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getCollateralFactorForAsset.selector, platform, asset)
        );
        return abi.decode(returnData, (uint256));
    }

    /// @dev precision and decimals are expected to follow Compound 's pattern (1e18 precision, decimals taken into account).
    /// Currency in which the price is expressed is different depending on the platform that is being queried
    function getReferencePrice(
        address adapter,
        address platform,
        address asset
    ) internal returns (uint256 referencePrice) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getReferencePrice.selector, platform, asset)
        );
        return abi.decode(returnData, (uint256));
    }

    function getBorrowBalance(
        address adapter,
        address platform,
        address token
    ) internal returns (uint256 borrowBalance) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getBorrowBalance.selector, platform, token)
        );
        return abi.decode(returnData, (uint256));
    }

    function getSupplyBalance(
        address adapter,
        address platform,
        address token
    ) internal returns (uint256 supplyBalance) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getSupplyBalance.selector, platform, token)
        );
        return abi.decode(returnData, (uint256));
    }

    function enterMarkets(
        address adapter,
        address platform,
        address[] memory markets
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.enterMarkets.selector, platform, markets));
    }

    function claimRewards(address adapter, address platform)
        internal
        returns (address rewardsToken, uint256 rewardsAmount)
    {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.claimRewards.selector, platform)
        );
        return abi.decode(returnData, (address, uint256));
    }

    function supply(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.supply.selector, platform, token, amount));
    }

    function borrow(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.borrow.selector, platform, token, amount));
    }

    function redeemSupply(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.redeemSupply.selector, platform, token, amount)
        );
    }

    function repayBorrow(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.repayBorrow.selector, platform, token, amount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../SimplePosition/SimplePositionStorage.sol';
import '../FoldingAccount/FoldingAccountStorage.sol';

contract FundsManager is FoldingAccountStorage, SimplePositionStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 internal constant MANTISSA = 1e18;

    uint256 public immutable principal;
    uint256 public immutable profit;
    address public immutable holder;

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder
    ) public {
        require(_principal < MANTISSA, 'ICP1');
        require(_profit < MANTISSA, 'ICP1');
        require(_holder != address(0), 'ICP0');
        principal = _principal;
        profit = _profit;
        holder = _holder;
    }

    function addPrincipal(uint256 amount) internal {
        IERC20(simplePositionStore().supplyToken).safeTransferFrom(accountOwner(), address(this), amount);
        simplePositionStore().principalValue += amount;
    }

    function withdraw(uint256 amount, uint256 positionValue) internal {
        SimplePositionStore memory sp = simplePositionStore();

        uint256 principalFactor = sp.principalValue.mul(MANTISSA).div(positionValue);

        uint256 principalShare = amount;
        uint256 profitShare;

        if (principalFactor < MANTISSA) {
            principalShare = amount.mul(principalFactor) / MANTISSA;
            profitShare = amount.sub(principalShare);
        }

        uint256 subsidy = principalShare.mul(principal).add(profitShare.mul(profit)) / MANTISSA;

        if (sp.principalValue > principalShare) {
            simplePositionStore().principalValue = sp.principalValue - principalShare;
        } else {
            simplePositionStore().principalValue = 0;
        }

        IERC20(sp.supplyToken).safeTransfer(holder, subsidy);
        IERC20(sp.supplyToken).safeTransfer(accountOwner(), amount.sub(subsidy));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FlashswapStorage {
    bytes32 private constant FLASHSWAP_STORAGE_LOCATION = keccak256('folding.flashswap.storage');

    /**
     * expectedCaller:        address that is expected and authorized to execute a callback on the account
     */
    struct FlashswapStore {
        address expectedCaller;
    }

    function flashswapStore() internal pure returns (FlashswapStore storage s) {
        bytes32 position = FLASHSWAP_STORAGE_LOCATION;
        assembly {
            s_slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @dev All factors or APYs are written as a number with mantissa 18.
struct AssetMetadata {
    address assetAddress;
    string assetSymbol;
    uint8 assetDecimals;
    uint256 referencePrice;
    uint256 totalLiquidity;
    uint256 totalSupply;
    uint256 totalBorrow;
    uint256 totalReserves;
    uint256 supplyAPR;
    uint256 borrowAPR;
    address rewardTokenAddress;
    string rewardTokenSymbol;
    uint8 rewardTokenDecimals;
    uint256 estimatedSupplyRewardsPerYear;
    uint256 estimatedBorrowRewardsPerYear;
    uint256 collateralFactor;
    uint256 liquidationFactor;
    bool canSupply;
    bool canBorrow;
}

interface ILendingPlatform {
    function getAssetMetadata(address platform, address asset) external returns (AssetMetadata memory assetMetadata);

    function getCollateralUsageFactor(address platform) external returns (uint256 collateralUsageFactor);

    function getCollateralFactorForAsset(address platform, address asset) external returns (uint256);

    function getReferencePrice(address platform, address token) external returns (uint256 referencePrice);

    function getBorrowBalance(address platform, address token) external returns (uint256 borrowBalance);

    function getSupplyBalance(address platform, address token) external returns (uint256 supplyBalance);

    function claimRewards(address platform) external returns (address rewardsToken, uint256 rewardsAmount);

    function enterMarkets(address platform, address[] memory markets) external;

    function supply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function borrow(
        address platform,
        address token,
        uint256 amount
    ) external;

    function redeemSupply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function repayBorrow(
        address platform,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILendingPlatformAdapterProvider {
    function getPlatformAdapter(address platform) external view returns (address platformAdapter);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FoldingAccountStorage {
    bytes32 constant ACCOUNT_STORAGE_POSITION = keccak256('folding.account.storage');

    /**
     * entryCaller:         address of the caller of the account, during a transaction
     *
     * callbackTarget:      address of logic to be run when expecting a callback
     *
     * expectedCallbackSig: signature of function to be run when expecting a callback
     *
     * foldingRegistry      address of factory creating FoldingAccount
     *
     * nft:                 address of the nft contract.
     *
     * owner:               address of the owner of this FoldingAccount.
     */
    struct AccountStore {
        address entryCaller;
        address callbackTarget;
        bytes4 expectedCallbackSig;
        address foldingRegistry;
        address nft;
        address owner;
    }

    modifier onlyAccountOwner() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner, 'FA2');
        _;
    }

    modifier onlyNFTContract() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.nft, 'FA3');
        _;
    }

    modifier onlyAccountOwnerOrRegistry() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner || s.entryCaller == s.foldingRegistry, 'FA4');
        _;
    }

    function aStore() internal pure returns (AccountStore storage s) {
        bytes32 position = ACCOUNT_STORAGE_POSITION;
        assembly {
            s_slot := position
        }
    }

    function accountOwner() internal view returns (address) {
        return aStore().owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity 0.6.12;

contract SimplePositionStorage {
    bytes32 private constant SIMPLE_POSITION_STORAGE_LOCATION = keccak256('folding.simplePosition.storage');

    /**
     * platform:        address of the underlying platform (AAVE, COMPOUND, etc)
     *
     * supplyToken:     address of the token that is being supplied to the underlying platform
     *                  This token is also the principal token
     *
     * borrowToken:     address of the token that is being borrowed to leverage on supply token
     *
     * principalValue:  amount of supplyToken that user has invested in this position
     */
    struct SimplePositionStore {
        address platform;
        address supplyToken;
        address borrowToken;
        uint256 principalValue;
    }

    function simplePositionStore() internal pure returns (SimplePositionStore storage s) {
        bytes32 position = SIMPLE_POSITION_STORAGE_LOCATION;
        assembly {
            s_slot := position
        }
    }

    function isSimplePosition() internal view returns (bool) {
        return simplePositionStore().platform != address(0);
    }

    function requireSimplePositionDetails(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal view {
        require(simplePositionStore().platform == platform, 'SP2');
        require(simplePositionStore().supplyToken == supplyToken, 'SP3');
        require(simplePositionStore().borrowToken == borrowToken, 'SP4');
    }
}