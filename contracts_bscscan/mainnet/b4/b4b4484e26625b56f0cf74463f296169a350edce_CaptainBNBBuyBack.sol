/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/*

Hold $Captain and get rewarded in BNB on every transaction!
Telegram: https://t.me/CaptainBNBCommunity
Website: https://captainbnb.com
Dashboard: https://app.captainbnb.com
Twitter: https://twitter.com/CaptainBnbCoin

*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract CaptainBNBBuyBack{

    IDEXRouter router;
    address pair;
    address manager;
    address WBNB;
    // declaring the constructor
    constructor(){
        //Initializing the owner to the address that deploys the contract
        manager = msg.sender; 
        
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
    }
    
    receive() external payable { }
    
    function randomBuyBack(address token, address to, uint256 amount, uint256 num) public{
        require(msg.sender == manager);
        
        uint256 i=0;
        
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = token;
        
        while(i<num){
            
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0,
                path,
                to,
                block.timestamp
            );
            
            i++;
        }
    }
}