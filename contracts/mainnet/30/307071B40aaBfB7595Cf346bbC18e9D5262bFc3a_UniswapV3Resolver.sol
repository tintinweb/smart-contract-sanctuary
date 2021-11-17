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
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
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
address constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
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
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {
    QUOTER,
    LOW_FEES,
    MEDIUM_FEES,
    HIGH_FEES,
    FACTORY
} from "../../../constants/CUniswapV3.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {OK} from "../../../constants/CAaveServices.sol";
import {PoolKey} from "../../../structs/SUniswapV3.sol";

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
        PoolKey memory poolKey = _getPoolKey(
            data_.tokenIn,
            data_.tokenOut,
            fee_
        );
        if (
            IUniswapV3Factory(FACTORY).getPool(
                poolKey.token0,
                poolKey.token1,
                poolKey.fee
            ) == address(0)
        ) return 0;
        return
            IQuoter(QUOTER).quoteExactInputSingle(
                data_.tokenIn,
                data_.tokenOut,
                fee_,
                data_.amountIn,
                0
            );
    }

    function _getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
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

struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}