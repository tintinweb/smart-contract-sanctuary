/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.6.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

 /**
 * @title AddLiquidity
 * @dev AddLiquidity Contract to add liquidity 
 */
contract swap {

    // variable to store uniswap router contract address
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    IUniswap public uniswap;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }

    function testSwapExactETHForTokens(uint amountOut, address token, uint deadline) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(amountOut, path, msg.sender, deadline);
    }

    receive() external payable {}
    fallback() external payable {}
  
}