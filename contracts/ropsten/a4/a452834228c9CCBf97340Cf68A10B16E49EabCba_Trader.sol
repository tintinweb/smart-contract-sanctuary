/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.5.1;

interface IUniswapV2Router {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Trader {

    IUniswapV2Router private _uniswapV2Router;
    address private _WETH;
    address private _token;

    constructor(IUniswapV2Router __uniswapV2Router, address __token) public {
        _uniswapV2Router = IUniswapV2Router(__uniswapV2Router);
        _token = __token;
        _WETH = IUniswapV2Router(_uniswapV2Router).WETH();
    }

    function getPrice(uint ethAmount) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(_WETH);
        path[1] = _token;
        return _uniswapV2Router.getAmountsOut(ethAmount, path)[1];
    }

    function sell(address to, uint fromAmount, uint targetAmount) external payable returns (uint receivedAmount) {
        //IMPORTANT: receivedAmount should >= targetAmount
        address[] memory path = new address[](2);
        path[0] = address(_WETH);
        path[1] = _token;
        require(getPrice(msg.value) >= targetAmount, "Transaction reverted: price higher than the target");
        _uniswapV2Router.swapETHForExactTokens(fromAmount, path, to, now + 900);
        return receivedAmount;
    }
}