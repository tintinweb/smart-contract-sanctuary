pragma solidity ^0.8.4;

contract UniswapV3CrossPoolOracle {
    // moot uniswap v3 oracle for ropsten testing

    uint256 public ate;
    uint256 public ao;
    uint256 public ao2;

    function setAte(uint256 _ate) public {
        ate = _ate;
    }

    function setAo(uint256 _ate) public {
        ao = _ate;
    }

    function setAo2(uint256 _ate) public {
        ao2 = _ate;
    }

    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint32 _twapPeriod
    ) external view returns (uint256 ethAmountOut) {
        ethAmountOut = ate;
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut) {
        amountOut = ao;
    }

    function ethToAsset(
        uint256 _ethAmountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut) {
        amountOut = ao2;
    }
}

