// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ISwapRouter} from "../integrations/uniswap/IUniswapV3.sol";
import {IUniswapV2Router02} from "../integrations/uniswap/IUniswapV2Router02.sol";
import {BytesLib} from "../integrations/uniswap/BytesLib.sol";
import {ICurvePool} from "../integrations/curve/ICurvePool.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IQuoter} from "../integrations/uniswap/IQuoter.sol";
import {AddressProvider} from "../core/AddressProvider.sol";
import {ContractsRegister} from "../core/ContractsRegister.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {PriceOracle} from "../oracles/PriceOracle.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PathFinder {
    using SafeMath for uint256;
    using BytesLib for bytes;
    AddressProvider public addressProvider;
    ContractsRegister public immutable contractsRegister;
    PriceOracle public priceOracle;
    address public wethToken;

    // Mainnet
    //    address public constant ethToUsdPriceFeed =
    //    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // Kovan
    address public constant ethToUsdPriceFeed =
        0x9326BFA02ADD2366b30bacB125260Af641031331;

    // Contract version
    uint256 public constant version = 1;

    struct TradePath {
        address[] path;
        uint256 rate;
        uint256 expectedAmount;
    }

    /// @dev Allows provide data for registered credit managers only to eliminated usage for non-gearbox contracts
    modifier registeredCreditManagerOnly(address creditManager) {
        // Could be optimised by adding internal list of creditManagers
        require(
            contractsRegister.isCreditManager(creditManager),
            Errors.REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY
        ); // T:[WG-3]

        _;
    }

    constructor(address _addressProvider) {
        addressProvider = AddressProvider(_addressProvider);
        contractsRegister = ContractsRegister(
            addressProvider.getContractsRegister()
        );

        priceOracle = PriceOracle(addressProvider.getPriceOracle());
        wethToken = addressProvider.getWethToken();
    }

    function bestUniPath(
        uint256 swapInterface,
        address router,
        uint256 swapType,
        address from,
        address to,
        uint256 amount,
        address[] memory tokens
    ) public returns (TradePath memory) {
        if (amount == 0) {
            return
                TradePath({path: new address[](3), rate: 0, expectedAmount: 0});
        }

        // Checking path[2]:  [from,to]
        address[] memory path = new address[](2);

        path[0] = from;
        path[1] = to;

        (uint256 bestAmount, bool best) = _getAmountsUni(
            swapInterface,
            router,
            swapType,
            path,
            amount,
            swapType == Constants.EXACT_INPUT ? 0 : Constants.MAX_INT
        );

        address[] memory bestPath;
        uint256 expectedAmount;

        if (best) {
            bestPath = path;
        }

        // Checking path[3]: [from, <connector>, to]
        for (uint256 i = 0; i < tokens.length; i++) {
            path = new address[](3);
            path[0] = from;
            path[2] = to;

            if (tokens[i] != from && tokens[i] != to) {
                path[1] = tokens[i];
                (expectedAmount, best) = _getAmountsUni(
                    swapInterface,
                    router,
                    swapType,
                    path,
                    amount,
                    bestAmount
                );
                if (best) {
                    bestAmount = expectedAmount;
                    bestPath = path;
                }
            }
        }

        uint256 bestRate = 0;

        if (bestAmount == Constants.MAX_INT) {
            bestAmount = 0;
        }

        if (bestAmount != 0 && amount != 0) {
            bestRate = swapType == Constants.EXACT_INPUT
                ? Constants.WAD.mul(amount).div(bestAmount)
                : Constants.WAD.mul(bestAmount).div(amount);
        }

        return
            TradePath({
                rate: bestRate,
                path: bestPath,
                expectedAmount: bestAmount
            });
    }

    function _getAmountsUni(
        uint256 swapInterface,
        address router,
        uint256 swapType,
        address[] memory path,
        uint256 amount,
        uint256 bestAmount
    ) internal returns (uint256, bool) {
        return
            swapInterface == Constants.UNISWAP_V2
                ? _getAmountsV2(
                    IUniswapV2Router02(router),
                    swapType,
                    path,
                    amount,
                    bestAmount
                )
                : _getAmountsV3(
                    IQuoter(router),
                    swapType,
                    path,
                    amount,
                    bestAmount
                );
    }

    function _getAmountsV2(
        IUniswapV2Router02 router,
        uint256 swapType,
        address[] memory path,
        uint256 amount,
        uint256 bestAmount
    ) internal view returns (uint256, bool) {
        uint256 expectedAmount;

        if (swapType == Constants.EXACT_INPUT) {
            try router.getAmountsOut(amount, path) returns (
                uint256[] memory amountsOut
            ) {
                expectedAmount = amountsOut[path.length - 1];
            } catch {
                return (bestAmount, false);
            }
        } else if (swapType == Constants.EXACT_OUTPUT) {
            try router.getAmountsIn(amount, path) returns (
                uint256[] memory amountsIn
            ) {
                expectedAmount = amountsIn[0];
            } catch {
                return (bestAmount, false);
            }
        } else {
            revert("Unknown swap type");
        }

        if (
            (swapType == Constants.EXACT_INPUT &&
                expectedAmount > bestAmount) ||
            (swapType == Constants.EXACT_OUTPUT && expectedAmount < bestAmount)
        ) {
            return (expectedAmount, true);
        }

        return (bestAmount, false);
    }

    function _getAmountsV3(
        IQuoter quoter,
        uint256 swapType,
        address[] memory path,
        uint256 amount,
        uint256 bestAmount
    ) internal returns (uint256, bool) {
        uint256 expectedAmount;

        if (swapType == Constants.EXACT_INPUT) {
            try
                quoter.quoteExactInput(
                    convertPathToPathV3(path, swapType),
                    amount
                )
            returns (uint256 amountOut) {
                expectedAmount = amountOut;
            } catch {
                return (bestAmount, false);
            }
        } else if (swapType == Constants.EXACT_OUTPUT) {
            try
                quoter.quoteExactOutput(
                    convertPathToPathV3(path, swapType),
                    amount
                )
            returns (uint256 amountIn) {
                expectedAmount = amountIn;
            } catch {
                return (bestAmount, false);
            }
        } else {
            revert("Unknown swap type");
        }

        if (
            (swapType == Constants.EXACT_INPUT &&
                expectedAmount > bestAmount) ||
            (swapType == Constants.EXACT_OUTPUT && expectedAmount < bestAmount)
        ) {
            return (expectedAmount, true);
        }

        return (bestAmount, false);
    }

    function convertPathToPathV3(address[] memory path, uint256 swapType)
        public
        pure
        returns (bytes memory result)
    {
        uint24 fee = 3000;

        if (swapType == Constants.EXACT_INPUT) {
            for (uint256 i = 0; i < path.length.sub(1); i++) {
                result = result.concat(abi.encodePacked(path[i], fee));
            }
            result = result.concat(abi.encodePacked(path[path.length - 1]));
        } else {
            for (uint256 i = path.length.sub(1); i > 0; i--) {
                result = result.concat(abi.encodePacked(path[i], fee));
            }
            result = result.concat(abi.encodePacked(path[0]));
        }
    }

    function getClosurePaths(
        address router,
        address _creditManager,
        address borrower,
        address[] memory connectorTokens
    )
        external
        registeredCreditManagerOnly(_creditManager)
        returns (TradePath[] memory result)
    {
        ICreditFilter creditFilter = ICreditFilter(
            ICreditManager(_creditManager).creditFilter()
        );
        result = new TradePath[](creditFilter.allowedTokensCount());

        address creditAccount = ICreditManager(_creditManager)
        .getCreditAccountOrRevert(borrower);
        address underlyingToken = creditFilter.underlyingToken();

        for (uint256 i = 0; i < creditFilter.allowedTokensCount(); i++) {
            (address token, uint256 balance, , ) = creditFilter
            .getCreditAccountTokenById(creditAccount, i);

            if (i == 0) {
                result[0] = TradePath({
                    path: new address[](3),
                    rate: Constants.WAD,
                    expectedAmount: balance
                });
            } else {
                result[i] = bestUniPath(
                    Constants.UNISWAP_V2,
                    router,
                    Constants.EXACT_INPUT,
                    token,
                    underlyingToken,
                    balance,
                    connectorTokens
                );
            }
        }
    }

    function getPrices(address[] calldata tokens)
        external
        view
        returns (uint256[] memory prices)
    {
        (
            ,
            //uint80 roundID,
            int256 ethPrice, //uint startedAt, //uint timeStamp, //uint80 answeredInRound
            ,
            ,

        ) = AggregatorV3Interface(ethToUsdPriceFeed).latestRoundData();
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 decimals = ERC20(tokens[i]).decimals();
            prices[i] = priceOracle
            .convert(10**decimals, tokens[i], wethToken)
            .mul(uint256(ethPrice))
            .div(Constants.WAD);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter  {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external  returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external  returns (uint amountETH);

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
    ) external  payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external override view returns (address);
    function WETH() external override view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external override
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external override
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external override view returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external override view returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external override view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external override view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external override view returns (uint[] memory amounts);


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
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
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

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24)
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface ICurvePool {
    function coins(uint256) external view returns (address);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {PercentageMath} from "../math/PercentageMath.sol";

library Constants {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // 25% of MAX_INT
    uint256 constant MAX_INT_4 =
        0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // REWARD FOR LEAN DEPLOYMENT MINING
    uint256 constant ACCOUNT_CREATION_REWARD = 1e5;
    uint256 constant DEPLOYMENT_COST = 1e17;

    // FEE = 10%
    uint256 constant FEE_INTEREST = 1000; // 10%

    // FEE + LIQUIDATION_FEE 2%
    uint256 constant FEE_LIQUIDATION = 200;

    // Liquidation premium 5%
    uint256 constant LIQUIDATION_DISCOUNTED_SUM = 9500;

    // 100% - LIQUIDATION_FEE - LIQUIDATION_PREMIUM
    uint256 constant UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD =
        LIQUIDATION_DISCOUNTED_SUM - FEE_LIQUIDATION;

    // Seconds in a year
    uint256 constant SECONDS_PER_YEAR = 365 days;
    uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = SECONDS_PER_YEAR * 3 /2;

    // 1e18
    uint256 constant RAY = 1e27;
    uint256 constant WAD = 1e18;

    // OPERATIONS
    uint8 constant OPERATION_CLOSURE = 1;
    uint8 constant OPERATION_REPAY = 2;
    uint8 constant OPERATION_LIQUIDATION = 3;

    // Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
    uint8 constant LEVERAGE_DECIMALS = 100;

    // Maximum withdraw fee for pool in percentage math format. 100 = 1%
    uint8 constant MAX_WITHDRAW_FEE = 100;

    uint256 constant CHI_THRESHOLD = 9950;
    uint256 constant HF_CHECK_INTERVAL_DEFAULT = 4;

    uint256 constant NO_SWAP = 0;
    uint256 constant UNISWAP_V2 = 1;
    uint256 constant UNISWAP_V3 = 2;
    uint256 constant CURVE_V1 = 3;
    uint256 constant LP_YEARN = 4;

    uint256 constant EXACT_INPUT = 1;
    uint256 constant EXACT_OUTPUT = 2;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Errors library
library Errors {
    //
    // COMMON
    //

    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //

    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //

    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // CREDIT MANAGER
    //

    string public constant CM_NO_OPEN_ACCOUNT = "CM1";
    string
        public constant CM_ZERO_ADDRESS_OR_USER_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT =
        "CM2";

    string public constant CM_INCORRECT_AMOUNT = "CM3";
    string public constant CM_CAN_LIQUIDATE_WITH_SUCH_HEALTH_FACTOR = "CM4";
    string public constant CM_CAN_UPDATE_WITH_SUCH_HEALTH_FACTOR = "CM5";
    string public constant CM_WETH_GATEWAY_ONLY = "CM6";
    string public constant CM_INCORRECT_PARAMS = "CM7";
    string public constant CM_INCORRECT_FEES = "CM8";
    string public constant CM_MAX_LEVERAGE_IS_TOO_HIGH = "CM9";
    string public constant CM_CANT_CLOSE_WITH_LOSS = "CMA";
    string public constant CM_TARGET_CONTRACT_iS_NOT_ALLOWED = "CMB";
    string public constant CM_TRANSFER_FAILED = "CMC";
    string public constant CM_INCORRECT_NEW_OWNER = "CME";

    //
    // ACCOUNT FACTORY
    //

    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //

    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //

    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT_FILTER
    //

    string public constant CF_UNDERLYING_TOKEN_FILTER_CONFLICT = "CF0";
    string public constant CF_INCORRECT_LIQUIDATION_THRESHOLD = "CF1";
    string public constant CF_TOKEN_IS_NOT_ALLOWED = "CF2";
    string public constant CF_CREDIT_MANAGERS_ONLY = "CF3";
    string public constant CF_ADAPTERS_ONLY = "CF4";
    string public constant CF_OPERATION_LOW_HEALTH_FACTOR = "CF5";
    string public constant CF_TOO_MUCH_ALLOWED_TOKENS = "CF6";
    string public constant CF_INCORRECT_CHI_THRESHOLD = "CF7";
    string public constant CF_INCORRECT_FAST_CHECK = "CF8";
    string public constant CF_NON_TOKEN_CONTRACT = "CF9";
    string public constant CF_CONTRACT_IS_NOT_IN_ALLOWED_LIST = "CFA";
    string public constant CF_FAST_CHECK_NOT_COVERED_COLLATERAL_DROP = "CFB";
    string public constant CF_SOME_LIQUIDATION_THRESHOLD_MORE_THAN_NEW_ONE =
        "CFC";
    string public constant CF_ADAPTER_CAN_BE_USED_ONLY_ONCE = "CFD";
    string public constant CF_INCORRECT_PRICEFEED = "CFE";
    string public constant CF_TRANSFER_IS_NOT_ALLOWED = "CFF";
    string public constant CF_CREDIT_MANAGER_IS_ALREADY_SET = "CFG";

    //
    // CREDIT ACCOUNT
    //

    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // PRICE ORACLE
    //

    string public constant PO_PRICE_FEED_DOESNT_EXIST = "PO0";
    string public constant PO_TOKENS_WITH_DECIMALS_MORE_18_ISNT_ALLOWED = "PO1";
    string public constant PO_AGGREGATOR_DECIMALS_SHOULD_BE_18 = "PO2";

    //
    // ACL
    //

    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //

    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // LEVERAGED ACTIONS
    //

    string public constant LA_INCORRECT_VALUE = "LA1";
    string public constant LA_HAS_VALUE_WITH_TOKEN_TRANSFER = "LA2";
    string public constant LA_UNKNOWN_SWAP_INTERFACE = "LA3";
    string public constant LA_UNKNOWN_LP_INTERFACE = "LA4";
    string public constant LA_LOWER_THAN_AMOUNT_MIN = "LA5";
    string public constant LA_TOKEN_OUT_IS_NOT_COLLATERAL = "LA6";

    //
    // YEARN PRICE FEED
    //
    string public constant YPF_PRICE_PER_SHARE_OUT_OF_RANGE = "YP1";
    string public constant YPF_INCORRECT_LIMITER_PARAMETERS = "YP2";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {IAppAddressProvider} from "../interfaces/app/IAppAddressProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Ownable, IAppAddressProvider {
    // Mapping which keeps all addresses
    mapping(bytes32 => address) public addresses;

    // Emits each time when new address is set
    event AddressSet(bytes32 indexed service, address indexed newAddress);

    // This event is triggered when a call to ClaimTokens succeeds.
    event Claimed(uint256 user_id, address account, uint256 amount, bytes32 leaf);

    // Repositories & services
    bytes32 public constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
    bytes32 public constant ACL = "ACL";
    bytes32 public constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 public constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
    bytes32 public constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
    bytes32 public constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
    bytes32 public constant GEAR_TOKEN = "GEAR_TOKEN";
    bytes32 public constant WETH_TOKEN = "WETH_TOKEN";
    bytes32 public constant WETH_GATEWAY = "WETH_GATEWAY";
    bytes32 public constant LEVERAGED_ACTIONS = "LEVERAGED_ACTIONS";

    // Contract version
    uint256 public constant version = 1;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // T:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACL, _address); // T:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // T:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // T:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // T:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(PRICE_ORACLE, _address); // T:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // T:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // T:[AP-7]
    }

    /// @return Address of AccountFactory
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // T:[AP-8]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(DATA_COMPRESSOR, _address); // T:[AP-8]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); //T:[AP-11]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(TREASURY_CONTRACT, _address); //T:[AP-11]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // T:[AP-12]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(GEAR_TOKEN, _address); // T:[AP-12]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // T:[AP-13]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_TOKEN, _address); // T:[AP-13]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // T:[AP-14]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_GATEWAY, _address); // T:[AP-14]
    }

    /// @return Address of WETH token
    function getLeveragedActions() external view override returns (address) {
        return _getAddress(LEVERAGED_ACTIONS); // T:[AP-7]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setLeveragedActions(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(LEVERAGED_ACTIONS, _address); // T:[AP-7]
    }

    /// @return Address of key, reverts if key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // T:[AP-1]
        return result; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        emit AddressSet(key, value); // T:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Errors} from "../libraries/helpers/Errors.sol";
import {ACLTrait} from "./ACLTrait.sol";


/// @title Pools & Contract managers registry
/// @notice Keeps pools & contract manager addresses
contract ContractsRegister is ACLTrait {
    // Pools list
    address[] public pools;
    mapping(address => bool) public isPool;

    // Credit Managers list
    address[] public creditManagers;
    mapping(address => bool) public isCreditManager;

    // Contract version
    uint256 public constant version = 1;

    // emits each time when new pool was added to register
    event NewPoolAdded(address indexed pool);

    // emits each time when new credit Manager was added to register
    event NewCreditManagerAdded(address indexed creditManager);

    constructor(address addressProvider) ACLTrait(addressProvider) {}

    /// @dev Adds pool to list
    /// @param newPoolAddress Address on new pool added
    function addPool(address newPoolAddress)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newPoolAddress != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        require(!isPool[newPoolAddress], Errors.CR_POOL_ALREADY_ADDED); // T:[CR-2]
        pools.push(newPoolAddress); // T:[CR-3]
        isPool[newPoolAddress] = true; // T:[CR-3]

        emit NewPoolAdded(newPoolAddress); // T:[CR-4]
    }

    /// @dev Returns array of registered pool addresses
    function getPools() external view returns (address[] memory) {
        return pools;
    }

    /// @return Returns quantity of registered pools
    function getPoolsCount() external view returns (uint256) {
        return pools.length; // T:[CR-3]
    }

    /// @dev Adds credit accounts manager address to the registry
    /// @param newCreditManager Address on new pausableAdmin added
    function addCreditManager(address newCreditManager)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newCreditManager != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        require(
            !isCreditManager[newCreditManager],
            Errors.CR_CREDIT_MANAGER_ALREADY_ADDED
        ); // T:[CR-5]
        creditManagers.push(newCreditManager); // T:[CR-6]
        isCreditManager[newCreditManager] = true; // T:[CR-6]

        emit NewCreditManagerAdded(newCreditManager); // T:[CR-7]
    }

    /// @dev Returns array of registered credit manager addresses
    function getCreditManagers() external view returns (address[] memory) {
        return creditManagers;
    }

    /// @return Returns quantity of registered credit managers
    function getCreditManagersCount() external view returns (uint256) {
        return creditManagers.length; // T:[CR-6]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {IAppCreditManager} from "./app/IAppCreditManager.sol";
import {DataTypes} from "../libraries/data/Types.sol";


/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManager is IAppCreditManager {
    // Emits each time when the credit account is opened
    event OpenCreditAccount(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 amount,
        uint256 borrowAmount,
        uint256 referralCode
    );

    // Emits each time when the credit account is closed
    event CloseCreditAccount(
        address indexed owner,
        address indexed to,
        uint256 remainingFunds
    );

    // Emits each time when the credit account is liquidated
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        uint256 remainingFunds
    );

    // Emits each time when borrower increases borrowed amount
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    // Emits each time when borrower adds collateral
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    // Emits each time when the credit account is repaid
    event RepayCreditAccount(address indexed owner, address indexed to);

    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    // Emits each time when new fees are set
    event NewParameters(
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxLeverage,
        uint256 feeInterest,
        uint256 feeLiquidation,
        uint256 liquidationDiscount
    );

    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param amount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param leverageFactor Multiplier to borrowers own funds
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external override;

    /**
     * @dev Closes credit account
     * - Swaps all assets to underlying one using default swap protocol
     * - Pays borrowed amount + interest accrued + fees back to the pool by calling repayCreditAccount
     * - Transfers remaining funds to the trader / farmer
     * - Closes the credit account and return it to account factory
     * - Emits CloseCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#close-credit-account
     *
     * @param to Address to send remaining funds
     * @param paths Exchange type data which provides paths + amountMinOut
     */
    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override;

    /**
     * @dev Liquidates credit account
     * - Transfers discounted total credit account value from liquidators account
     * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
     * - Transfer all assets from credit account to liquidator ("to") account
     * - Returns credit account to factory
     * - Emits LiquidateCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
     *
     * @param borrower Borrower address
     * @param to Address to transfer all assets from credit account
     * @param force If true, use transfer function for transferring tokens instead of safeTransfer
     */
    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    ) external;

    /// @dev Repays credit account
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#repay-credit-account
    ///
    /// @param to Address to send credit account assets
    function repayCreditAccount(address to) external override;

    /// @dev Repays credit account with ETH. Restricted to be called by WETH Gateway only
    ///
    /// @param borrower Address of borrower
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address borrower, address to)
        external
        returns (uint256);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseBorrowedAmount(uint256 amount) external override;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external override;

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        external
        view
        override
        returns (bool);

    /// @dev Calculates Repay amount = borrow amount + interest accrued + fee
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/economy#repay
    ///           https://dev.gearbox.fi/developers/credit/economy#liquidate
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if calculated repay amount for liquidator
    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256);

    /// @dev Returns minimal amount for open credit account
    function minAmount() external view returns (uint256);

    /// @dev Returns maximum amount for open credit account
    function maxAmount() external view returns (uint256);

    /// @dev Returns maximum leveraged factor allowed for this pool
    function maxLeverageFactor() external view returns (uint256);

    /// @dev Returns underlying token address
    function underlyingToken() external view returns (address);

    /// @dev Returns address of connected pool
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditFilter() external view returns (ICreditFilter);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approves token for msg.sender's credit account
    function approve(address targetContract, address token) external;

    /// @dev Approve tokens for credit accounts. Restricted for adapters only
    function provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) external;

    function transferAccountOwnership(address newOwner) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        override
        returns (address);

//    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function minHealthFactor() external view returns (uint256);

    function defaultSwapContract() external view override returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

interface ICreditFilter {
    // Emits each time token is allowed or liquidtion threshold changed
    event TokenAllowed(address indexed token, uint256 liquidityThreshold);

   // Emits each time token is allowed or liquidtion threshold changed
    event TokenForbidden(address indexed token);

    // Emits each time contract is allowed or adapter changed
    event ContractAllowed(address indexed protocol, address indexed adapter);

    // Emits each time contract is forbidden
    event ContractForbidden(address indexed protocol);

    // Emits each time when fast check parameters are updated
    event NewFastCheckParameters(uint256 chiThreshold, uint256 fastCheckDelay);

    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    event TransferPluginAllowed(
        address indexed pugin,
        bool state
    );

    event PriceOracleUpdated(address indexed newPriceOracle);

    //
    // STATE-CHANGING FUNCTIONS
    //

    /// @dev Adds token to the list of allowed tokens
    /// @param token Address of allowed token
    /// @param liquidationThreshold The constant showing the maximum allowable ratio of Loan-To-Value for the i-th asset.
    function allowToken(address token, uint256 liquidationThreshold) external;

    /// @dev Adds contract to the list of allowed contracts
    /// @param targetContract Address of contract to be allowed
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter) external;

    /// @dev Forbids contract and removes it from the list of allowed contracts
    /// @param targetContract Address of allowed contract
    function forbidContract(address targetContract) external;

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param amountIn Amount of tokens in
    /// @param amountOut Amount of tokens out
    function checkCollateralChange(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external;

    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    ) external;

    /// @dev Connects credit managaer, hecks that all needed price feeds exists and finalize config
    function connectCreditManager(address poolService) external;

    /// @dev Sets collateral protection for new credit accounts
    function initEnabledTokens(address creditAccount) external;

    function checkAndEnableToken(address creditAccount, address token) external;

    //
    // GETTERS
    //

    /// @dev Returns quantity of contracts in allowed list
    function allowedContractsCount() external view returns (uint256);

    /// @dev Returns of contract address from the allowed list by its id
    function allowedContracts(uint256 id) external view returns (address);

    /// @dev Reverts if token isn't in token allowed list
    function revertIfTokenNotAllowed(address token) external view;

    /// @dev Returns true if token is in allowed list otherwise false
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Calculates total value for provided address
    /// More: https://dev.gearbox.fi/developers/credit/economy#total-value
    ///
    /// @param creditAccount Token creditAccount address
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total);

    /// @dev Calculates Threshold Weighted Total Value
    /// More: https://dev.gearbox.fi/developers/credit/economy#threshold-weighted-value
    ///
    ///@param creditAccount Credit account address
    function calcThresholdWeightedValue(address creditAccount)
        external
        view
        returns (uint256 total);

    function contractToAdapter(address allowedContract)
        external
        view
        returns (address);

    /// @dev Returns address of underlying token
    function underlyingToken() external view returns (address);

    /// @dev Returns address & balance of token by the id of allowed token in the list
    /// @param creditAccount Credit account address
    /// @param id Id of token in allowed list
    /// @return token Address of token
    /// @return balance Token balance
    function getCreditAccountTokenById(address creditAccount, uint256 id)
        external
        view
        returns (
            address token,
            uint256 balance,
            uint256 tv,
            uint256 twv
        );

    /**
     * @dev Calculates health factor for the credit account
     *
     *         sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *             borrowed amount + interest accrued
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return Health factor in percents (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokens(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

    function updateUnderlyingTokenLiquidationThreshold() external;

    function revertIfCantIncreaseBorrowing(
        address creditAccount,
        uint256 minHealthFactor
    ) external view;

    function revertIfAccountTransferIsNotAllowed(
        address onwer,
        address creditAccount
    ) external view;

    function approveAccountTransfers(address from, bool state) external;

    function allowanceForAccountTransfers(address from, address to)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

import {AddressProvider} from "../core/AddressProvider.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {ACLTrait} from "../core/ACLTrait.sol";

/// @title Price Oracle based on Chainlink's price feeds
/// @notice Works as router and provide cross rates using converting via ETH
///
/// More: https://dev.gearbox.fi/developers/priceoracle
contract PriceOracle is ACLTrait, IPriceOracle {
    using SafeMath for uint256;

    // Address of WETH token
    address public wethAddress;

    // token => priceFeed
    mapping(address => address) public priceFeeds;

    // token => decimals multiplier
    mapping(address => uint256) public decimalsMultipliers;
    mapping(address => uint256) public decimalsDividers;

    // Contract version
    uint constant public version = 1;

    constructor(address addressProvider) ACLTrait(addressProvider) {
        wethAddress = AddressProvider(addressProvider).getWethToken();
        decimalsMultipliers[wethAddress] = 1;
        decimalsDividers[wethAddress] = Constants.WAD;
    }

    /// @dev Sets price feed if it doesn't exist. If price feed is already set, it changes nothing
    /// This logic is done to protect Gearbox from priceOracle attack
    /// when potential attacker can get access to price oracle, change them to fraud ones
    /// and then liquidate all funds
    /// @param token Address of token
    /// @param priceFeed Address of chainlink price feed token => Eth
    function addPriceFeed(address token, address priceFeed)
        external
        override
        configuratorOnly
    {
        // T:[PO-5]
        priceFeeds[token] = priceFeed;
        uint256 decimals = ERC20(token).decimals();

        require(
            decimals <= 18,
            Errors.PO_TOKENS_WITH_DECIMALS_MORE_18_ISNT_ALLOWED
        ); // T:[PO-3]

        require(
            AggregatorV3Interface(priceFeed).decimals() == 18,
            Errors.PO_AGGREGATOR_DECIMALS_SHOULD_BE_18
        ); // T:[PO-10]

        decimalsMultipliers[token] = 10**(18 - decimals);
        decimalsDividers[token] = 10**(36 - decimals);
        emit NewPriceFeed(token, priceFeed); // T:[PO-4]
    }

    /// @dev Converts one asset into another using price feed rate. Reverts if price feed doesn't exist
    /// @param amount Amount to convert
    /// @param tokenFrom Token address converts from
    /// @param tokenTo Token address - converts to
    /// @return Amount converted to tokenTo asset
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view override returns (uint256) {
        return
            amount
                .mul(decimalsMultipliers[tokenFrom])
                .mul(getLastPrice(tokenFrom, tokenTo))
                .div(decimalsDividers[tokenTo]); // T:[PO-8]
    }

    /// @dev Gets token rate with 18 decimals. Reverts if priceFeed doesn't exist
    /// @param tokenFrom Converts from token address
    /// @param tokenTo Converts to token address
    /// @return Rate in WAD format
    function getLastPrice(address tokenFrom, address tokenTo)
        public
        view
        override
        returns (uint256)
    {
        if (tokenFrom == tokenTo) return Constants.WAD; // T:[PO-1]

        // price = wad * price[ETH] / price[token_to] = wad^2 / price[token_to]
        if (tokenFrom == wethAddress) {
            return Constants.WAD.mul(Constants.WAD).div(_getPrice(tokenTo)); // T:[PO-6]
        }

        // price = wad * price[token_from] / price[ETH] = wad * price[token_from] / wad = price[token_from]
        if (tokenTo == wethAddress) {
            return _getPrice(tokenFrom); // T:[PO-6]
        }

        return Constants.WAD.mul(_getPrice(tokenFrom)).div(_getPrice(tokenTo)); // T:[PO-7]
    }

    /// @dev Returns rate to ETH in WAD format
    /// @param token Token converts from
    function _getPrice(address token) internal view returns (uint256) {
        require(
            priceFeeds[token] != address(0),
            Errors.PO_PRICE_FEED_DOESNT_EXIST
        ); // T:[PO-9]

        (
            ,
            //uint80 roundID,
            int256 price, //uint startedAt, //uint timeStamp, //uint80 answeredInRound
            ,
            ,

        ) = AggregatorV3Interface(priceFeeds[token]).latestRoundData(); // T:[PO-6]
        return uint256(price);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Optimised for front-end Address Provider interface
interface IAppAddressProvider {
    function getDataCompressor() external view returns (address);

    function getGearToken() external view returns (address);

    function getWethToken() external view returns (address);

    function getWETHGateway() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLeveragedActions() external view returns (address);
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL private _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        require(
            addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        require(
            _acl.isConfigurator(msg.sender),
            Errors.ACL_CALLER_NOT_CONFIGURATOR
        ); // T:[ACLT-8]
        _;
    }

    ///@dev Pause contract
    function pause() external {
        require(
            _acl.isPausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1]
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        require(
            _acl.isUnpausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1],[ACLT-2]
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    // emits each time when new pausable admin added
    event PausableAdminAdded(address indexed newAdmin);

    // emits each time when pausable admin removed
    event PausableAdminRemoved(address indexed admin);

    // emits each time when new unpausable admin added
    event UnpausableAdminAdded(address indexed newAdmin);

    // emits each times when unpausable admin removed
    event UnpausableAdminRemoved(address indexed admin);

    /// @dev Adds pausable admin address
    /// @param newAdmin Address of new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes pausable admin
    /// @param admin Address of admin which should be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is pausable admin and false if not
    function isPausableAdmin(address addr) external view returns (bool) {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Removes unpausable admin
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    function isUnpausableAdmin(address addr) external view returns (bool) {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account) external view returns (bool) {
        return account == owner(); // T:[ACL-6]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../../libraries/data/Types.sol";


/// @title Optimised for front-end credit Manager interface
/// @notice It's optimised for light-weight abi
interface IAppCreditManager {
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external;

    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external;

    function repayCreditAccount(address to) external;

    function increaseBorrowedAmount(uint256 amount) external;

    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        returns (uint256);

    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    function defaultSwapContract() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title DataType library
/// @notice Contains data types used in data compressor.
library DataTypes {
    struct Exchange {
        address[] path;
        uint256 amountOutMin;
    }

    struct TokenBalance {
        address token;
        uint256 balance;
        bool isAllowed;
    }

    struct ContractAdapter {
        address allowedContract;
        address adapter;
    }

    struct CreditAccountData {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
    }

    struct CreditAccountDataExtended {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
        uint256 repayAmount;
        uint256 liquidationAmount;
        bool canBeClosed;
        uint256 borrowedAmount;
        uint256 cumulativeIndexAtOpen;
        uint256 since;
    }

    struct CreditManagerData {
        address addr;
        bool hasAccount;
        address underlyingToken;
        bool isWETH;
        bool canBorrow;
        uint256 borrowRate;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 maxLeverageFactor;
        uint256 availableLiquidity;
        address[] allowedTokens;
        ContractAdapter[] adapters;
    }

    struct PoolData {
        address addr;
        bool isWETH;
        address underlyingToken;
        address dieselToken;
        uint256 linearCumulativeIndex;
        uint256 availableLiquidity;
        uint256 expectedLiquidity;
        uint256 expectedLiquidityLimit;
        uint256 totalBorrowed;
        uint256 depositAPY_RAY;
        uint256 borrowAPY_RAY;
        uint256 dieselRate_RAY;
        uint256 withdrawFee;
        uint256 cumulativeIndex_RAY;
        uint256 timestampLU;
    }

    struct TokenInfo {
        address addr;
        string symbol;
        uint8 decimals;
    }

    struct AddressProviderData {
        address contractRegister;
        address acl;
        address priceOracle;
        address traderAccountFactory;
        address dataCompressor;
        address farmingFactory;
        address accountMiner;
        address treasuryContract;
        address gearToken;
        address wethToken;
        address wethGateway;
    }

    struct MiningApproval {
        address token;
        address swapContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Price oracle interface
interface IPriceOracle {

    // Emits each time new configurator is set up
    event NewPriceFeed(address indexed token, address indexed priceFeed);

    /**
     * @dev Sets price feed if it doesn't exists
     * If pricefeed exists, it changes nothing
     * This logic is done to protect Gearbox from priceOracle attack
     * when potential attacker can get access to price oracle, change them to fraud ones
     * and then liquidate all funds
     * @param token Address of token
     * @param priceFeedToken Address of chainlink price feed token => Eth
     */
    function addPriceFeed(address token, address priceFeedToken) external;

    /**
     * @dev Converts one asset into another using rate. Reverts if price feed doesn't exist
     *
     * @param amount Amount to convert
     * @param tokenFrom Token address converts from
     * @param tokenTo Token address - converts to
     * @return Amount converted to tokenTo asset
     */
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /**
     * @dev Gets token rate with 18 decimals. Reverts if priceFeed doesn't exist
     *
     * @param tokenFrom Converts from token address
     * @param tokenTo Converts to token address
     * @return Rate in WAD format
     */
    function getLastPrice(address tokenFrom, address tokenTo)
        external
        view
        returns (uint256);
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