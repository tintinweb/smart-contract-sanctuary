// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import './SimplePositionBaseConnector.sol';
import '../interfaces/ILeverageWithV3FlashswapConnector.sol';
import '../../modules/FundsManager/FundsManager.sol';
import '../../modules/Flashswapper/FlashswapStorage.sol';

contract LeverageWithV3FlashswapConnector is
    SimplePositionBaseConnector,
    FundsManager,
    FlashswapStorage,
    ILeverageWithV3FlashswapConnector
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    address private immutable SELF_ADDRESS;
    address private immutable factory;

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder,
        address _factory
    ) public FundsManager(_principal, _profit, _holder) {
        SELF_ADDRESS = address(this);
        factory = _factory;
    }

    function increasePositionWithV3Flashswap(IncreasePositionWithFlashswapParams calldata params)
        external
        override
        onlyAccountOwnerOrRegistry
    {
        _verifySetup(params.platform, params.supplyToken, params.borrowToken);

        address pool = getPool(params.supplyToken, params.borrowToken, params.fee);
        _setExpectedCallback(pool);

        bool zeroForOne = params.borrowToken < params.supplyToken;

        IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            params.borrowAmount.toInt256(), // positive amount => this amount is the exact input
            (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            abi.encode(
                SwapCallbackDataParams(
                    true,
                    abi.encode(
                        IncreasePositionInternalParams(
                            params.principalAmount,
                            params.minimumSupplyAmount,
                            params.borrowToken,
                            params.supplyToken,
                            params.platform
                        )
                    )
                )
            )
        );
    }

    function decreasePositionWithV3Flashswap(DecreasePositionWithFlashswapParams calldata params)
        external
        override
        onlyAccountOwner
    {
        requireSimplePositionDetails(params.platform, params.supplyToken, params.borrowToken);
        require(params.maximumFlashAmount <= params.redeemAmount, 'LWV3FC3');

        address pool = getPool(params.supplyToken, params.borrowToken, params.fee);
        _setExpectedCallback(pool);

        bool zeroForOne = params.borrowToken > params.supplyToken;

        address lender = getLender(params.platform);
        uint256 debt = getBorrowBalance(lender, params.platform, params.borrowToken);

        IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            params.repayAmount > debt ? -(debt.toInt256()) : -(params.repayAmount.toInt256()), // negative amount => this amount is an exact output
            (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            abi.encode(
                SwapCallbackDataParams(
                    false,
                    abi.encode(
                        DecreasePositionInternalParams(
                            params.redeemAmount,
                            params.maximumFlashAmount,
                            debt,
                            params.borrowToken,
                            params.supplyToken,
                            params.platform,
                            lender
                        )
                    )
                )
            )
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();

        SwapCallbackDataParams memory data = abi.decode(_data, (SwapCallbackDataParams));

        if (data.increasePosition) {
            IncreasePositionInternalParams memory params = abi.decode(
                data.internalParams,
                (IncreasePositionInternalParams)
            );

            uint256 amountToSupply = amount0Delta < 0
                ? params.principalAmount.add(uint256(-amount0Delta))
                : params.principalAmount.add(uint256(-amount1Delta));

            require(amountToSupply >= params.minimumSupplyAmount, 'LWV3FC1');
            uint256 amountToBorrow = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

            addPrincipal(params.principalAmount);

            _increasePosition(params.platform, params.supplyToken, amountToSupply, params.borrowToken, amountToBorrow);
            IERC20(params.borrowToken).safeTransfer(msg.sender, amountToBorrow);
        } else {
            DecreasePositionInternalParams memory params = abi.decode(
                data.internalParams,
                (DecreasePositionInternalParams)
            );

            uint256 amountOwedToPool = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);
            uint256 deposit = getSupplyBalance(params.lender, params.platform, params.supplyToken);
            uint256 amountToRedeem = params.redeemAmount > deposit ? deposit : params.redeemAmount;

            require(amountOwedToPool <= params.maximumFlashAmount, 'LWV3FC4');
            uint256 amountToRepay = uint256(amount0Delta < 0 ? -amount0Delta : -amount1Delta);

            _decreasePosition(
                params.platform,
                params.lender,
                params.supplyToken,
                amountToRedeem,
                params.borrowToken,
                amountToRepay
            );

            IERC20(params.supplyToken).safeTransfer(msg.sender, amountOwedToPool);

            uint256 amountToWithdraw = amountToRedeem - amountOwedToPool;

            if (amountToWithdraw > 0) {
                uint256 positionValue = deposit.sub(
                    params.debt.mul(getReferencePrice(params.lender, params.platform, params.borrowToken)).div(
                        getReferencePrice(params.lender, params.platform, params.supplyToken)
                    )
                );
                withdraw(amountToWithdraw, positionValue);
            }
        }
    }

    function _increasePosition(
        address platform,
        address supplyToken,
        uint256 amountToSupply,
        address borrowToken,
        uint256 amountToBorrow
    ) internal {
        address lender = getLender(platform);
        supply(lender, platform, supplyToken, amountToSupply);
        borrow(lender, platform, borrowToken, amountToBorrow);
    }

    function _decreasePosition(
        address platform,
        address lender,
        address supplyToken,
        uint256 amountToRedeem,
        address borrowToken,
        uint256 amountToRepay
    ) internal {
        repayBorrow(lender, platform, borrowToken, amountToRepay);
        redeemSupply(lender, platform, supplyToken, amountToRedeem);
    }

    function _verifySetup(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal {
        address lender = getLender(platform);

        if (isSimplePosition()) {
            requireSimplePositionDetails(platform, supplyToken, borrowToken);
        } else {
            simplePositionStore().platform = platform;
            simplePositionStore().supplyToken = supplyToken;
            simplePositionStore().borrowToken = borrowToken;

            address[] memory markets = new address[](2);
            markets[0] = supplyToken;
            markets[1] = borrowToken;
            enterMarkets(lender, platform, markets);
        }
    }

    function _setExpectedCallback(address pool) internal {
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = bytes4(keccak256('uniswapV3SwapCallback(int256,int256,bytes)'));
        flashswapStore().expectedCaller = pool;
    }

    function _verifyCallbackAndClear() internal {
        // Verify and clear authorisations for callbacks
        require(msg.sender == flashswapStore().expectedCaller, 'LWV3FC2');
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

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../../modules/Lender/LendingDispatcher.sol';
import '../../modules/SimplePosition/SimplePositionStorage.sol';
import '../interfaces/ISimplePositionBaseConnector.sol';

contract SimplePositionBaseConnector is LendingDispatcher, SimplePositionStorage, ISimplePositionBaseConnector {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function getBorrowBalance() public override returns (uint256) {
        return
            getBorrowBalance(
                getLender(simplePositionStore().platform),
                simplePositionStore().platform,
                simplePositionStore().borrowToken
            );
    }

    function getSupplyBalance() public override returns (uint256) {
        return
            getSupplyBalance(
                getLender(simplePositionStore().platform),
                simplePositionStore().platform,
                simplePositionStore().supplyToken
            );
    }

    function getCollateralUsageFactor() public override returns (uint256) {
        return getCollateralUsageFactor(getLender(simplePositionStore().platform), simplePositionStore().platform);
    }

    function getPositionValue() public override returns (uint256 positionValue) {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);

        uint256 debt = getBorrowBalance(lender, sp.platform, sp.borrowToken);
        uint256 deposit = getSupplyBalance(lender, sp.platform, sp.supplyToken);
        debt = debt.mul(getReferencePrice(lender, sp.platform, sp.borrowToken)).div(
            getReferencePrice(lender, sp.platform, sp.supplyToken)
        );
        if (deposit >= debt) {
            positionValue = deposit - debt;
        } else {
            positionValue = 0;
        }
    }

    function getPrincipalValue() public override returns (uint256) {
        return simplePositionStore().principalValue;
    }

    function getPositionMetadata() external override returns (SimplePositionMetadata memory metadata) {
        metadata.positionAddress = address(this);
        metadata.platformAddress = simplePositionStore().platform;
        metadata.supplyTokenAddress = simplePositionStore().supplyToken;
        metadata.borrowTokenAddress = simplePositionStore().borrowToken;
        metadata.supplyAmount = getSupplyBalance();
        metadata.borrowAmount = getBorrowBalance();
        metadata.collateralUsageFactor = getCollateralUsageFactor();
        metadata.principalValue = getPrincipalValue();
        metadata.positionValue = getPositionValue();
    }

    function getSimplePositionDetails()
        external
        view
        override
        returns (
            address,
            address,
            address
        )
    {
        SimplePositionStore storage sp = simplePositionStore();
        return (sp.platform, sp.supplyToken, sp.borrowToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct IncreasePositionWithFlashswapParams {
    uint256 principalAmount; // Amount that will be used as principal
    uint256 minimumSupplyAmount; // Minimum amount expected to be supplied (enforce slippage here)
    uint256 borrowAmount; // Amount that will be borrowed to pay the flashswap
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    uint24 fee; // Selector of Uniswap Pool to flash
}

struct DecreasePositionWithFlashswapParams {
    uint256 redeemAmount; // Total amount of supply token that will be redeemed from position to repay flash and withdraw to user
    uint256 maximumFlashAmount; // Amount of supply token that will be redeemed to repay the flash
    uint256 repayAmount; // Amount of borrowToken that will be repaid with maximumFlashAmount
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    uint24 fee; // Selector of Uniswap Pool to flash
}

// Struct that is received by UniswapV3SwapCallback
struct SwapCallbackDataParams {
    bool increasePosition; // Whether to increase position or decrease position
    bytes internalParams;
}

// Parameters that are passed to UniswapV3Callback when the action is increase position
struct IncreasePositionInternalParams {
    uint256 principalAmount;
    uint256 minimumSupplyAmount;
    address borrowToken;
    address supplyToken;
    address platform;
}

// Parameters that are passed to UniswapV3Callback when the action is decrease position
struct DecreasePositionInternalParams {
    uint256 redeemAmount; // Total amount to be redeemed
    uint256 maximumFlashAmount;
    uint256 debt; // Computed debt prior to flashswap, for tax purposes and gas savings
    address borrowToken;
    address supplyToken;
    address platform;
    address lender; // For gas savings
}

interface ILeverageWithV3FlashswapConnector {
    function increasePositionWithV3Flashswap(IncreasePositionWithFlashswapParams calldata params) external;

    function decreasePositionWithV3Flashswap(DecreasePositionWithFlashswapParams calldata params) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct SimplePositionMetadata {
    uint256 supplyAmount;
    uint256 borrowAmount;
    uint256 collateralUsageFactor;
    uint256 principalValue;
    uint256 positionValue;
    address positionAddress;
    address platformAddress;
    address supplyTokenAddress;
    address borrowTokenAddress;
}

interface ISimplePositionBaseConnector {
    function getBorrowBalance() external returns (uint256);

    function getSupplyBalance() external returns (uint256);

    function getPositionValue() external returns (uint256);

    function getPrincipalValue() external returns (uint256);

    function getCollateralUsageFactor() external returns (uint256);

    function getSimplePositionDetails()
        external
        view
        returns (
            address,
            address,
            address
        );

    function getPositionMetadata() external returns (SimplePositionMetadata memory);
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