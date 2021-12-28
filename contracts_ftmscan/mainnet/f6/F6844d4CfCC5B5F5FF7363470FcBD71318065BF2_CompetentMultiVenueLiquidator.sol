pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Liquidator.sol";
import "./V2PairReader.sol";
import "./OwnedLiquidator.sol";

interface IWETHDeposit {
    function deposit() external payable;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface ComptrollerForLiquidator {
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);
}

contract CompetentMultiVenueLiquidator is OwnedLiquidator, V2PairReader {
    using SafeMath for uint;

    uint public constant NO_VENUE = 0;

    // to record profit in callback
    uint public stateProfit;

    uint venueCounter;

    // Venue id -> Factory address
    mapping(uint => address) internal factories;
    // Venue id -> Pair initialization code
    mapping(uint => bytes32) internal pairsCodeHashes;

    // Represents a fractional fee
    struct VenueFee {
        uint numerator;
        uint denominator;
    }

    // Venue id -> VenueFee
    mapping(uint => VenueFee) internal venuesFees;

    constructor(address wrappedNative, address venueFactory, bytes32 codeHash, uint venueFeeNumerator, uint venueFeeDenominator) OwnedLiquidator(wrappedNative) {
        addVenue(venueFactory, codeHash, venueFeeNumerator, venueFeeDenominator);
    }

    function addVenue(address venueFactory, bytes32 codeHash, uint venueFeeNumerator, uint venueFeeDenominator) public onlyOwner {
        uint newIndex = venueCounter + 1;

        factories[newIndex] = venueFactory;
        pairsCodeHashes[newIndex] = codeHash;
        venuesFees[newIndex] = VenueFee({
           numerator:venueFeeNumerator,
            denominator:venueFeeDenominator
        });
    }

    /**
     * In order to simplify things, this contract will convert all incoming native coins to their respective wrapped tokens.
     */
    receive() external payable {
        if (msg.sender != WETH) {
            IWETHDeposit(WETH).deposit{value : msg.value}();
        }
    }

    // **** ADMIN ****

    // TODO : SECURITY : Add 'inMotion' flag and turn it off on function end (modifier?)
    // TODO : add onlyAdmin modifier
    // TODO : add admin setter
    // TODO : add withdraw tokens (profits) function

    //
    //
    /**
     * @param maxAmountInCallbackSwap Allows to limit the amount sent to the callback pair (in collateral asset) in return for the amount received from the callback pair (in borrowed asset).
     * @param minAmountOutFinalSwap Allows to limit the amount received from the final pair (in wNative) in return for the amount sent to the final pair (in collateral asset gained).
     * return amountInLiquidation is for simulation to get maxAmountIn callback pair
     *                            (e.g. for a safety buffer of 10% : use maxAmountInCallbackSwap = 1.1 * amountInLiquidation)
     * return netProfit is for simulation to get minAmountOut final pair
     *                  (e.g. for a safety buffer of 10% : use minAmountOutFinalSwap = 0.9 * netProfit)
     */
    function flashLiquidate(
        uint venue,
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral,
        uint maxAmountInCallbackSwap,
        // note : 0 for no final swap
        uint venueFinalSwap,
        // address tokenOutFinalSwap - for now we use wNative
        uint minAmountOutFinalSwap
    )
    external
    returns (uint amountInLiquidation, uint netProfit)
    {
        (uint _amountInLiquidation, address underlyingCollateral) = buildSwapCallbackPayloadAndSwap(venue, cTokenBorrow, cTokenCollateral, borrower, repayAmount, maxAmountInCallbackSwap, address(0), NO_VENUE);
        amountInLiquidation = _amountInLiquidation;

        // DEV_NOTE : The callback is locked in order to ensure 'stateProfit' will always have the proper value
        //            (only set in the callback)
        netProfit = stateProfit;
        stateProfit = 0;

        if (venueFinalSwap > 0) {
            require(underlyingCollateral != WETH, "already WETH");
            // if we started with 0 balance in underlyingCollateral netProfit == IERC20(underlyingCollateral)).balanceOf(address(this))
            netProfit = swapExactIn(venueFinalSwap, underlyingCollateral, WETH, netProfit, minAmountOutFinalSwap, address(0));
        }
    }

    function flashLiquidateConnector(
        uint venue,
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral,
        uint venueConnector,
        address tokenConnector,
        uint maxAmountInCallbackSwap,
        // note : 0 for no final swap
        uint venueFinalSwap,
        // address tokenOutFinalSwap - for now we use WETH
        uint minAmountOutFinalSwap
    )
    external
    returns (uint amountInLiquidation, uint netProfit)
    {
        address underlyingCollateral;
        (amountInLiquidation, underlyingCollateral) = buildSwapCallbackPayloadAndSwap(venue, cTokenBorrow, cTokenCollateral, borrower, repayAmount, maxAmountInCallbackSwap, tokenConnector, venueConnector);

        // DEV_NOTE : The callback is locked in order to ensure 'stateProfit' will always have the proper value
        //            (only set in the callback)
        netProfit = stateProfit;
        stateProfit = 0;

        if (venueFinalSwap > 0) {
            require(underlyingCollateral != WETH, "already WETH");
            netProfit = swapExactIn(venueFinalSwap, underlyingCollateral, WETH, netProfit, minAmountOutFinalSwap, address(0));
        }
    }

    function flashLiquidateSingle(
        uint venue,
        address cToken,
        address borrower,
        uint repayAmount,
        address tokenFlash,
        // note : 0 for no final swap
        uint venueFinalSwap,
        // address tokenOutFinalSwap - for now we use WETH
        uint minAmountOutFinalSwap
    )
    external
    returns (uint netProfit)
    {
        address underlying = buildSwapCallbackPayloadAndSwapSingle(venue, cToken, borrower, repayAmount, tokenFlash);

        // DEV_NOTE : The callback is locked in order to ensure 'stateProfit' will always have the proper value
        //            (only set in the callback)
        netProfit = stateProfit;
        stateProfit = 0;

        if (venueFinalSwap > 0) {
            require(underlying != WETH, "already WETH");
            netProfit = swapExactIn(venueFinalSwap, underlying, WETH, netProfit, minAmountOutFinalSwap, address(0));
        }
    }

    struct CallbackData {
        // to verify pair
        uint venue;
        // (collateralToken/tokenConnector/flashTokenPair) to verify pair and to complete swap
        address tokenIn;
        // to verify profit
        uint underlyingCollateralBalanceBefore;
        // (borrowToken) to verify pair
        address tokenOut;
        // to complete swap
        uint amountIn;
        // address pair -- not necessary because it will be the msg.sender
        // for calling liquidateBorrow
        address cTokenBorrow;
        // for calling liquidateBorrow
        address borrower;
        // uint repayAmount -- not necessary because it is amoun0Out or amount1Out
        // for calling liquidateBorrow
        address cTokenCollateral;
        // for connectorSwap (0 if not used)
        uint venueConnector;
    }

    // **** V2 callback ****

    // DEV_NOTE : Add flag to ensure mid run
    function uniswapV2Call(address sender, uint amount0Out, uint amount1Out, bytes calldata _data) external {
        swapV2CallInternal(sender, amount0Out, amount1Out, _data);
    }

    function pancakeCall(address sender, uint amount0Out, uint amount1Out, bytes calldata _data) external {
        swapV2CallInternal(sender, amount0Out, amount1Out, _data);
    }

    function swapV2CallInternal(address sender, uint amount0Out, uint amount1Out, bytes calldata _data) internal {
        // TODO : CRITICAL : Check for 'inMotion' flag
        CallbackData memory data = abi.decode(_data, (CallbackData));

        // SECURITY :Anyone can make the pair call this function ! Better maker sure it is only the rightful pair
        address rightfulPair = pairForVenue(data.venue, data.tokenIn, data.tokenOut);
        require(msg.sender == rightfulPair, "invalid pair");

        uint amountToRepay = amount0Out > 0 ? amount0Out : amount1Out;

        uint cTokenCollateralAmountSeized = safeLiquidatePositionInternal(data.cTokenBorrow, data.borrower, amountToRepay, data.cTokenCollateral);

        // TODO : make sure that redeeming cETH ends up in WETH due to receive()
        // note : this might fail if there's no liq in the market
        require(CTokenInterfaceForLiquidator(data.cTokenCollateral).redeem(cTokenCollateralAmountSeized) == 0, "redeem fail");

        address underlyingCollateral = sanitizeUnderlying(data.cTokenCollateral);
        uint underlyingCollateralBalanceAfter = IERC20(underlyingCollateral).balanceOf(address(this));

        // direct swap: underlyingCollateral -> underlyingBorrow (without tokenConnector)
        if (data.tokenIn == underlyingCollateral) {
            address tokenIn = data.tokenIn;

            // only from flashLiquidateSingle()
            if (data.cTokenBorrow == data.cTokenCollateral) {
                tokenIn = data.tokenOut;
            }

            // DEV_NOTE : The first sub will fail in case the redeemed underlying are less than 'data.amountIn'
            //            (The amount needed to send the pair in order to get the assets to liquidate the position)
            uint balanceDiff = sub(underlyingCollateralBalanceAfter, data.underlyingCollateralBalanceBefore);
            stateProfit = sub(balanceDiff, data.amountIn);

            // TODO : use safe transfer instead
            IERC20(tokenIn).transfer(rightfulPair, data.amountIn);
            return;
        }

        // connector swap: underlyingCollateral -> tokenConnector -> underlyingBorrow (with tokenConnector)
        uint maxAmountIn = sub(underlyingCollateralBalanceAfter, data.underlyingCollateralBalanceBefore);
        // note : handles transfer of data.amountIn tokens (of type data.tokenIn) to pair
        uint amountIn = swapExactOut(data.venueConnector, underlyingCollateral, data.tokenIn, data.amountIn, maxAmountIn, rightfulPair);
        stateProfit = sub(maxAmountIn, amountIn);
    }

    // TODO : add safeTrnasfer
    // TODO : add general function call to external functions in other contracts

    // **** Swap Venues ****

    /**
     * calculates the CREATE2 address for a pair without making any external calls
     */
    function pairForVenue(uint venueCode, address tokenA, address tokenB) internal view returns (address pair) {
        address factory = factories[venueCode];
        require(factory != address(0), "unknown factory");

        bytes32 pairCode = pairsCodeHashes[venueCode];

        pair = pairFor(factory, pairCode, tokenA, tokenB);
    }

    // **** LOGIC ****

    function buildSwapCallbackPayloadAndSwap(uint venue, address cTokenBorrow, address cTokenCollateral, address borrower, uint repayAmount, uint maxAmountIn, address tokenConnector, uint venueConnector) internal returns (uint amountInLiquidation, address underlyingCollateral) {
        repayAmount = getSafeRepayAmount(cTokenBorrow, cTokenCollateral, borrower, repayAmount);

        underlyingCollateral = sanitizeUnderlying(cTokenCollateral);
        address underlyingBorrow = sanitizeUnderlying(cTokenBorrow);

        // NOTE : comparing addresses
        uint amount0Out = underlyingBorrow < underlyingCollateral ? repayAmount : 0;
        uint amount1Out = underlyingBorrow > underlyingCollateral ? repayAmount : 0;
        require(amount0Out == 0 || amount1Out == 0, "amountsOut > 0");

        (address pair, CallbackData memory callbackData) = buildSwapCallbackPayload(venue, cTokenBorrow, cTokenCollateral, borrower, repayAmount, maxAmountIn, tokenConnector, venueConnector);
        amountInLiquidation = callbackData.amountIn;






        // Note : This will perform a swap using this contracts 'uniswapV2Call' as a callback
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), abi.encode(callbackData));
    }

    function buildSwapCallbackPayloadAndSwapSingle(uint venue, address cToken, address borrower, uint repayAmount, address tokenFlash) internal returns (address underlying) {
        repayAmount = getSafeRepayAmount(cToken, cToken, borrower, repayAmount);

        underlying = sanitizeUnderlying(cToken);

        // NOTE : comparing addresses
        uint amount0Out = underlying < tokenFlash ? repayAmount : 0;
        uint amount1Out = underlying > tokenFlash ? repayAmount : 0;
        require(amount0Out == 0 || amount1Out == 0, "amountsOut > 0");

        (address pair, CallbackData memory callbackData) = buildSwapCallbackPayloadSingle(venue, cToken, borrower, repayAmount, tokenFlash);

        // Note : This will perform a swap using this contracts 'uniswapV2Call' as a callback
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), abi.encode(callbackData));
    }

    function buildSwapCallbackPayload(uint venue, address cTokenBorrow, address cTokenCollateral, address borrower, uint repayAmount, uint maxAmountIn, address tokenConnector, uint venueConnector) internal returns (address, CallbackData memory) {

        if (tokenConnector == address(0)) {
            tokenConnector = sanitizeUnderlying(cTokenCollateral);
        }

        // note : will fail if underlyingBorrow == underlyingCollateral
        (address pair, uint tokenConnectorAmountIn) = calculatePairAndConnectorAmountIn(venue, cTokenBorrow, tokenConnector, repayAmount);
        // TODO : Move the MAI tests to after the swap (check actual received amount)
        require(maxAmountIn == 0 || tokenConnectorAmountIn <= maxAmountIn, "MAI");

        return (pair, buildCallbackData(
            venue,
            tokenConnector,
            cTokenCollateral,
            cTokenBorrow,
            tokenConnectorAmountIn,
            borrower,
            venueConnector
        ));
    }

    function buildSwapCallbackPayloadSingle(uint venue, address cToken, address borrower, uint repayAmount, address tokenFlash) internal returns (address, CallbackData memory ) {
        (address pair, uint underlyingAmountIn) = calculatePairAndAmountInFlashLoan(venue, cToken, tokenFlash, repayAmount);

        return (pair, buildCallbackData(
            venue,
            tokenFlash,
            cToken,
            cToken,
            underlyingAmountIn,
            borrower,
            NO_VENUE
        ));
    }

    function calculatePairAndConnectorAmountIn(uint venue, address cTokenBorrow, address tokenConnector, uint repayAmount) internal returns (address pair, uint tokenConnectorAmountIn) {
        address underlyingBorrow = sanitizeUnderlying(cTokenBorrow);
        pair = pairForVenue(venue, tokenConnector, underlyingBorrow);

        VenueFee memory venueFee = venuesFees[venue];
        tokenConnectorAmountIn = calculateAmountIn(pair, tokenConnector, underlyingBorrow, repayAmount, venueFee);
    }

    function calculatePairAndAmountInFlashLoan(uint venue, address cToken, address tokenFlash, uint repayAmount) internal returns (address pair, uint tokenConnectorAmountIn) {
        address underlying = sanitizeUnderlying(cToken);
        pair = pairForVenue(venue, tokenFlash, underlying);

        VenueFee memory venueFee = venuesFees[venue];
        tokenConnectorAmountIn = calculateAmountInFlashLoan(repayAmount, venueFee);
    }

    function buildCallbackData(uint venue, address tokenIn, address cTokenCollateral, address cTokenBorrow,
                               uint amountIn,  address borrower, uint venueConnector) internal returns (CallbackData memory callbackData){

        address underlyingCollateral = sanitizeUnderlying(cTokenCollateral);
        address underlyingBorrow = sanitizeUnderlying(cTokenBorrow);

        // TODO : C.F.H : Understand this function and then merge/reuse with the 'same asset liquidation'
        callbackData = CallbackData({
            venue : venue,
            tokenIn : tokenIn,
            underlyingCollateralBalanceBefore : IERC20(underlyingCollateral).balanceOf(address(this)),
            tokenOut : underlyingBorrow,
            amountIn : amountIn,
            cTokenBorrow : cTokenBorrow,
            borrower : borrower,
            cTokenCollateral : cTokenCollateral,
            venueConnector : venueConnector
        });
    }

    // TODO : Find better names for function params
    // @notice Calculates the required 'in' amount in order to get the wanted 'out' amount
    function calculateAmountIn(address pair, address underlyingCollateral, address underlyingBorrow, uint wantedOutAmount, VenueFee memory venueFee) internal returns (uint requiredAmountIn) {
        (uint reserveUnderlyingCollateral, uint reserveUnderlyingBorrow) = getReserves(pair, underlyingCollateral, underlyingBorrow);
        requiredAmountIn = getAmountIn(wantedOutAmount, reserveUnderlyingCollateral, reserveUnderlyingBorrow, venueFee.numerator, venueFee.denominator);
    }

    /**
     * Calculates the required amount for a same-token swap.
     */
    function calculateAmountInFlashLoan(uint amountOut, VenueFee memory venueFee) internal returns (uint requiredAmountIn) {
        requiredAmountIn = (amountOut * venueFee.denominator) / venueFee.numerator;
    }

    // **** Direct pair interaction ****

    function swapExactIn(uint venue, address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, address to) internal returns (uint amountOutCalculated) {
        address pair = pairForVenue(venue, tokenIn, tokenOut);
        (uint reserveIn, uint reserveOut) = getReserves(pair, tokenIn, tokenOut);
        VenueFee memory venueFee = venuesFees[venue];
        amountOutCalculated = getAmountOut(amountIn, reserveIn, reserveOut, venueFee.numerator, venueFee.denominator);
        // TODO : CRITICAL : Move 'require' to after the swap
        require(minAmountOut == 0 || amountOutCalculated >= minAmountOut, "MAO");
        doSwap(pair, tokenIn, tokenIn < tokenOut, amountIn, amountOutCalculated, to);
    }

    function swapExactOut(uint venue, address tokenIn, address tokenOut, uint amountOut, uint maxAmountIn, address to) internal returns (uint amountInCalculated) {
        address pair = pairForVenue(venue, tokenIn, tokenOut);
        (uint reserveIn, uint reserveOut) = getReserves(pair, tokenIn, tokenOut);
        VenueFee memory venueFee = venuesFees[venue];
        amountInCalculated = getAmountIn(amountOut, reserveIn, reserveOut, venueFee.numerator, venueFee.denominator);
        // TODO : CRITICAL : Move 'require' to after the swap
        require(maxAmountIn == 0 || amountInCalculated <= maxAmountIn, "MAO");
        doSwap(pair, tokenIn, tokenIn < tokenOut, amountInCalculated, amountOut, to);
    }

    function doSwap(address pair, address tokenIn, bool zeroForOne, uint amountIn, uint amountOut, address to) internal {
        // TODO : use safe transfer instead
        IERC20(tokenIn).transfer(pair, amountIn);

        uint amount0Out = zeroForOne ? 0 : amountOut;
        uint amount1Out = zeroForOne ? amountOut : 0;
        // require(amount0Out == 0 || amount1Out == 0, "amountsOut > 0");
        if (to == address(0)) {
            to = address(this);
        }
        // TODO : verify that the swap passes
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    // **** Native-Erc20 safety ****
    function sanitizeUnderlying(address cToken) internal returns (address underlying) {
        underlying = CTokenInterfaceForLiquidator(cToken).underlying();
        if (underlying == NATIVE) {
            underlying = WETH;
        }
    }


    // **** MATH ****

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y;
        require(z <= x, 'sub: ds-math-sub-underflow');
    }

    // **** SIMULATE ****

    // returns true if repayAmount would result in a liquidation that can then be redeemed and false otherwise
    // doesn't compute max repay amount but only checks 'repayAmount' that was passed as input
    function checkMarketLiquidity(address cTokenBorrow, address cTokenCollateral, address borrower, uint repayAmount) internal returns (bool) {
        repayAmount = getSafeRepayAmount(cTokenBorrow, cTokenCollateral, borrower, repayAmount);

        address underlyingCollateral = sanitizeUnderlying(cTokenCollateral);
        address underlyingBorrow = sanitizeUnderlying(cTokenBorrow);
        address comptroller = CTokenInterfaceForLiquidator(cTokenBorrow).comptroller();

        /* We calculate the number of collateral tokens that will be seized */
        (uint amountSeizeError, uint seizeTokens) = ComptrollerForLiquidator(comptroller).liquidateCalculateSeizeTokens(cTokenBorrow, cTokenCollateral, repayAmount);
        require(amountSeizeError == 0, "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        // TODO : Change to balance checking by underlying
        // DEV_NOTE : This will fail if (most surly) this contract has no cTokenCollateral balance and so we need to
        //            change this to calculate the amount in underlying and compare to available cash
        return (CTokenInterfaceForLiquidator(cTokenCollateral).redeem(seizeTokens) == 0);
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

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETHWithdraw {
    function withdraw(uint) external;
}

interface CEthInterfaceForLiquidator {
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable; // CToken instead of address
}

interface CErc20InterfaceForLiquidator {
    function underlying() external returns (address);
    function liquidateBorrow(address borrower, uint amountToRepay, address cTokenCollateral) external returns (uint); // CTokenInterface instead of address
}

interface CTokenInterfaceForLiquidator {
    function redeem(uint redeemTokens) external returns (uint);
    function underlying() external returns (address);
    function accrueInterest() external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function getCash() external view returns (uint);
    function comptroller() external view returns (address); // TODO : is this correct syntax
}

contract Liquidator {
    address public constant NATIVE = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint public constant fixedCloseFactor = 0.5e18;
    uint public constant expScale = 1e18;

    // TODO : CRITICAL : Add address
    address public WETH; // changes per chain WETH/WBNB/etc.

    constructor(address _wNative) {
        WETH = _wNative;
    }

    // DEV_NOTE : Using only self capital
    function liquidateAndRedeem(
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral,
        bool redeem
    ) internal
    returns (uint cTokenCollateralAmountSeized)
    {
        cTokenCollateralAmountSeized = safeLiquidatePositionInternal(cTokenBorrow, borrower, repayAmount, cTokenCollateral);

        // TODO : Think about profits
        if (redeem) {
            // TODO : make sure that redeeming cETH ends up in WETH due to receive()
            require(CTokenInterfaceForLiquidator(cTokenCollateral).redeem(cTokenCollateralAmountSeized) == 0, "redeem fail");
        }
    }

    /**
     * Liquidates the position after ensuring self balance is sufficient
     */
    function safeLiquidatePositionInternal(
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral
    ) internal returns (uint cTokenCollateralAmountSeized) {
        repayAmount = getSafeRepayAmount(cTokenBorrow, cTokenCollateral, borrower, repayAmount);

        address underlyingBorrow = CTokenInterfaceForLiquidator(cTokenBorrow).underlying();

        // Safety -- Ensure contract has enough balance in borrowed asset
        uint borrowedAssetSelfBalance = _safeSelfBalanceOfUnderlying(underlyingBorrow);
        require(borrowedAssetSelfBalance >= repayAmount, "not enough to repay");

        cTokenCollateralAmountSeized = liquidatePositionInternal(cTokenBorrow, underlyingBorrow, borrower, repayAmount, cTokenCollateral);
    }

    function liquidatePositionInternal(
        address cTokenBorrow,
        address underlyingBorrow,
        address borrower,
        uint amountToRepay,
        address cTokenCollateral
    )
    private
    returns (uint cTokenCollateralAmountSeized)
    {
        if (underlyingBorrow == WETH) {
            IWETHWithdraw(WETH).withdraw(amountToRepay);
            cTokenCollateralAmountSeized = _liquidatePositionEth(cTokenBorrow, borrower, amountToRepay, cTokenCollateral);
        } else if (underlyingBorrow == NATIVE) { // only from liquidateAndRedeem(), with own balance
            cTokenCollateralAmountSeized = _liquidatePositionEth(cTokenBorrow, borrower, amountToRepay, cTokenCollateral);
        } else {
            cTokenCollateralAmountSeized = _liquidatePositionErc(underlyingBorrow, cTokenBorrow, borrower, amountToRepay, cTokenCollateral);
        }
    }

    // **** Liquidation functions ****
    // **** Note : Both functions should work exactly the same (same sanity and logic, just erc20 vs native) ****

    function _liquidatePositionEth(
        address cTokenBorrow,
        address borrower,
        uint amountToRepay,
        address cTokenCollateral
    )
    internal
    returns (uint cTokenCollateralAmountSeized)
    {
        uint balanceCTokenCollateralBefore = IERC20(cTokenCollateral).balanceOf(address(this));

        // reverts if failure
        CEthInterfaceForLiquidator(cTokenBorrow).liquidateBorrow{value : amountToRepay}(borrower, cTokenCollateral);

        uint balanceCTokenCollateralAfter = IERC20(cTokenCollateral).balanceOf(address(this));
        uint cTokenGained = balanceCTokenCollateralAfter- balanceCTokenCollateralBefore;
        require(cTokenGained > 0, "no seize");

        cTokenCollateralAmountSeized = cTokenGained;
    }

    function _liquidatePositionErc(
        address underlyingBorrow,
        address cTokenBorrow,
        address borrower,
        uint amountToRepay,
        address cTokenCollateral
    )
    internal
    returns (uint cTokenCollateralAmountSeized)
    {

        uint balanceCTokenCollateralBefore = IERC20(cTokenCollateral).balanceOf(address(this));

        if (IERC20(underlyingBorrow).allowance(address(this), cTokenBorrow) < amountToRepay) {
            // TODO : add max allowance (using safe approve)

            // Setting to 0 before setting to wanted amount
            IERC20(underlyingBorrow).approve(cTokenBorrow, 0);
            IERC20(underlyingBorrow).approve(cTokenBorrow, amountToRepay);
        }

        // TODO : Add previous balance

        require(CErc20InterfaceForLiquidator(cTokenBorrow).liquidateBorrow(borrower, amountToRepay, cTokenCollateral) == 0, "liquidation fail");

        uint balanceCTokenCollateralAfter = IERC20(cTokenCollateral).balanceOf(address(this));
        uint cTokenGained = balanceCTokenCollateralAfter - balanceCTokenCollateralBefore;
        require(cTokenGained > 0, "no seize");

        cTokenCollateralAmountSeized = cTokenGained;
    }

    // **** Calculations utils ****

    function getSafeRepayAmount(address cTokenBorrow, address cTokenCollateral, address borrower, uint repayAmount) internal returns (uint) {
        require(CTokenInterfaceForLiquidator(cTokenBorrow).accrueInterest() == 0, "borrow accrue");

        // TODO : Using 'cToken.borrowBalanceCurrent' will retrieve the 'borrowBalanceStored' after accruing interest
        if (cTokenBorrow != cTokenCollateral) {
            require(CTokenInterfaceForLiquidator(cTokenCollateral).accrueInterest() == 0, "collateral accrue");
        }

        uint totalBorrow = CTokenInterfaceForLiquidator(cTokenBorrow).borrowBalanceStored(borrower);

        // TODO : CRITICAL : SafeMath
        uint maxClose = (fixedCloseFactor * totalBorrow) / expScale;

        // amountOut desired from swap
        if (repayAmount == 0) {
            repayAmount = maxClose;
        } else {
            require(repayAmount <= maxClose, "repayAmount to big");
        }

        return repayAmount;
    }

    function _safeSelfBalanceOfUnderlying(address token) internal returns (uint balance) {
        if (token == NATIVE) {
            // NOTE : self balance caused problems in the past
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }
}

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IUniswapV2PairForReader {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract V2PairReader {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, bytes32 pairCodeHash, address tokenA, address tokenB) internal view returns (address pair) {
        // already done outside ?
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                pairCodeHash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2PairForReader(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeNumerator, uint feeDenominator) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // note: in ApeSwap: 998; in PancakeSwap: 9975
        uint amountInWithFee = amountIn.mul(feeNumerator);
        uint numerator = amountInWithFee.mul(reserveOut);
        // note: in PancakeSwap: 10000
        uint denominator = reserveIn.mul(feeDenominator).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeNumerator, uint feeDenominator) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // note: in PancakeSwap: 10000
        uint numerator = reserveIn.mul(amountOut).mul(feeDenominator);
        // note: in ApeSwap: 998; in PancakeSwap: 9975
        uint denominator = reserveOut.sub(amountOut).mul(feeNumerator);
        amountIn = (numerator / denominator).add(1);
    }
}

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Liquidator.sol";

contract OwnedLiquidator is Ownable, Liquidator {

    constructor(address wrappedNative) Liquidator(wrappedNative) {
    }

    // TODO : Add 'onlyOwner'/'onlyAllowed' modifiers
    function onlyLiquidate(
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral
    ) external returns (uint cTokenCollateralAmountSeized) {
        cTokenCollateralAmountSeized = liquidateAndRedeem(cTokenBorrow, borrower, repayAmount, cTokenCollateral, false);
    }

    function liquidateAndRedeem(
        address cTokenBorrow,
        address borrower,
        uint repayAmount,
        address cTokenCollateral
    ) external returns (uint cTokenCollateralAmountSeized) {
        cTokenCollateralAmountSeized = liquidateAndRedeem(cTokenBorrow, borrower, repayAmount, cTokenCollateral, true);
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (Timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(ERC20 token) onlyOwner external {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // TODO : CRITICAL : add withdrawal of native
    // TODO : CRITICAL : Add general caller function
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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