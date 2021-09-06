pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract Oracle {
  //using sushiv2
    UniswapRouter UR = UniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    uint[] price;
    function getUniPrice(uint _eth_amount) public view returns(uint[] memory amount) {
        address[] memory path = new address[](2);
        path[0] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        path[1] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

        uint256[] memory result = UR.getAmountsOut(_eth_amount, path);
        return result;
    }
    function showUniPrice() public view returns(uint256) {
      return price[1];
    }

    function setPrice() public {
      price = getUniPrice(25000000000000000);
    }
}

function getEstimatedETHforUNI(uint amount) returns (uint256) {
  IQuoter quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
  address tokenIn = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address tokenOut = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  uint24 fee = 3000;
  uint160 sqrtPriceLimitX96 = 0;

  return quoter.quoteExactOutputSingle(
      tokenIn,
      tokenOut,
      fee,
      amount,
      sqrtPriceLimitX96
  );
}

interface UniswapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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