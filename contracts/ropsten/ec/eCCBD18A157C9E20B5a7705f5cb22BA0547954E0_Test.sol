// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

   
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
   
}

contract Test{  

   // IRouter public pancakeRouter;
    //IERC20 public ERC20Token ; 

    IUniswapV2Router01 public pancakeRouter ; 

    constructor()  {
        pancakeRouter = IUniswapV2Router01(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // replace with 0x10ED43C718714eb63d5aA57B78B54704E256024E while deploying to mainnet
        ); 

       // ERC20Token = IERC20() ;  
      //  pair = IUniswapV2Pair(0xD6bDAdC30625ee1ffce67e0C865CfBAD5ba22551) ; 
    } 

    function getRate1() public view  returns (uint[] memory amounts){ 
        address[] memory path = new address[](2);
        path[0] = address(0x8f41AA28ea6a8d20E59Abe4730b6896d432a3EFb);
        path[1] = pancakeRouter.WETH();


        return pancakeRouter.getAmountsOut(1000000000,path) ; 
    } 

    function getRate2() public view  returns (uint[] memory amounts){ 
        address[] memory path = new address[](2);
        path[1] = address(0x8f41AA28ea6a8d20E59Abe4730b6896d432a3EFb);
        path[0] = pancakeRouter.WETH();
        return pancakeRouter.getAmountsOut(1000000000000000000,path) ; 
    }
    
    

}