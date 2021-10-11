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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant GELATO = 0x3CACa7b48D0573D793d3b0279b5F0029180E83b6;
string constant OK = "OK";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
uint24 constant LOW_FEES = 500;
uint24 constant MEDIUM_FEES = 3000;
uint24 constant HIGH_FEES = 10000;

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.7;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(string memory _second, string memory _first)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(string memory _first, string memory _second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {GelatoString} from "../../../lib/GelatoString.sol";
import {UniswapV3Data, UniswapV3Result} from "../../../structs/SUniswapV3.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {
    QUOTER,
    LOW_FEES,
    MEDIUM_FEES,
    HIGH_FEES
} from "../../../constants/CUniswapV3.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {OK} from "../../../constants/CAaveServices.sol";

contract UniswapV3Resolver {
    using GelatoString for string;
    using Math for uint256;

    // should be called with callstatic of etherjs,
    // because quoteExactInputSingle is not a view function.
    function multicallGetAmountsOut(UniswapV3Data[] calldata datas_)
        public
        returns (UniswapV3Result[] memory results)
    {
        results = new UniswapV3Result[](datas_.length);

        for (uint256 i = 0; i < datas_.length; i++) {
            try this.getBestPool(datas_[i]) returns (
                UniswapV3Result memory result
            ) {
                results[i] = result;
            } catch Error(string memory error) {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: error.prefix(
                        "UniswapV3Resolver.getBestPool failed:"
                    )
                });
            } catch {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: "UniswapV3Resolver.getBestPool failed:undefined"
                });
            }
        }
    }

    function getBestPool(UniswapV3Data memory data_)
        public
        returns (UniswapV3Result memory)
    {
        uint256 amountOut = _quoteExactInputSingle(data_, LOW_FEES);
        uint24 fee = LOW_FEES;

        uint256 amountOutMediumFee;
        if (
            (amountOutMediumFee = _quoteExactInputSingle(data_, MEDIUM_FEES)) >
            amountOut
        ) {
            amountOut = amountOutMediumFee;
            fee = MEDIUM_FEES;
        }

        uint256 amountOutHighFee;
        if (
            (amountOutHighFee = _quoteExactInputSingle(data_, HIGH_FEES)) >
            amountOut
        ) {
            amountOut = amountOutHighFee;
            fee = HIGH_FEES;
        }

        return
            UniswapV3Result({
                id: data_.id,
                amountOut: amountOut,
                fee: fee,
                message: OK
            });
    }

    function _quoteExactInputSingle(UniswapV3Data memory data_, uint24 fee_)
        internal
        returns (uint256)
    {
        return
            IQuoter(QUOTER).quoteExactInputSingle(
                data_.tokenIn,
                data_.tokenOut,
                fee_,
                data_.amountIn,
                0
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct UniswapV3Result {
    bytes32 id;
    uint256 amountOut;
    uint24 fee;
    string message;
}

struct UniswapV3Data {
    bytes32 id;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
}