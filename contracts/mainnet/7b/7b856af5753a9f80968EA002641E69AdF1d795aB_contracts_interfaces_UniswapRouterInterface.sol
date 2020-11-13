pragma solidity ^0.6.0;

abstract contract UniswapRouterInterface {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external virtual returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external virtual
    returns (uint[] memory amounts);

    function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
    ) external virtual returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) public virtual view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) public virtual view returns (uint[] memory amounts);
}
