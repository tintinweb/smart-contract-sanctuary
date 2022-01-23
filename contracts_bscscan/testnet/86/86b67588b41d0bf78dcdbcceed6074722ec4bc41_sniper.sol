// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";

abstract contract pinkSale {
    function claim() external virtual;
}

contract sniper {

    address owner;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router02 uniswapRouter;
    address[] public baseTokens;
    address WBNB;



    constructor(address routerAddress) payable{
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02(routerAddress);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        WBNB = uniswapRouter.WETH();
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOutTokens(address token) public onlyOwner {
        IERC20(token).transfer(msg.sender , IERC20(token).balanceOf(address(this)));
    }

    function getOutBNB() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function claimAndSell(address pinkSaleAddress,address token,uint slippage) public onlyOwner {
        pinkSale(pinkSaleAddress).claim();
        SELL(token,slippage,WBNB);
    }

    function contribute(address pinkSaleAddress,uint amount) public onlyOwner {
        payable(pinkSaleAddress).transfer(amount);
    }

    function buyWithWETH(address[] memory path,uint amount,uint slippage) internal  {
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(slippage , path , address(this) , block.timestamp + 200);
    }

    function buyWithOtherToken(address[] memory path,uint amount,uint slippage) internal {
        IERC20(path[0]).approve(address(uniswapRouter),IERC20(path[0]).balanceOf(address(this)));
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            slippage,
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function BUY(address token , address buyWith, uint amount  ,uint slippage) public onlyOwner  {
        address[] memory path = new address[](2);
        path[0] = buyWith;
        path[1] = token;
        uint amountsOut = uniswapRouter.getAmountsOut(amount , path )[1];
        slippage = (slippage * amountsOut) / 100;
        slippage = amountsOut - slippage;
        uint balanceNow = IERC20(token).balanceOf(address(this));
        uint toBuyWithBalance = IERC20(buyWith).balanceOf(address(this));
        if(toBuyWithBalance < amount){
            address[] memory route = new address[](2);
            route[0] = WBNB;
            route[1] = buyWith;
            uint outAmount = uniswapRouter.getAmountsIn(amount - toBuyWithBalance,route)[1];
            buyWithWETH(route,outAmount,1);

        }
        if(buyWith == WBNB){
            buyWithWETH(path,amount,slippage);
        } else {
            buyWithOtherToken(path,amount,slippage);
        }
        uint balances = IERC20(token).balanceOf(address(this)) - balanceNow;
        require(balances >= slippage , "Too much tax");
    }

    function SELL(address token , uint slippage , address sellTo) public onlyOwner{
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = sellTo;
        uint amountsOut = uniswapRouter.getAmountsOut(IERC20(token).balanceOf(address(this)) , path )[1];
        slippage = (slippage * amountsOut) / 100;
        slippage = amountsOut - slippage;
        uint balanceNow = IERC20(sellTo).balanceOf(address(this));
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(uniswapRouter) , tokenBalance);
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBalance , slippage , path , address(this) , block.timestamp + 600);
        uint balance = IERC20(sellTo).balanceOf(address(this)) - balanceNow;
        require(balance >= slippage , "Too much tax");
    } 







}