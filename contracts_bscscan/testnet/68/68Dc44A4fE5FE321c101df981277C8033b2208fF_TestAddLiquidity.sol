/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.6.6;



interface IUniswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TestAddLiquidity {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // Ropsten

    IUniswap public uniswap;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }
    
    function addLiq(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external payable {
     
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountTokenDesired);
        uniswap.addLiquidityETH(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
    }
  /*  
    // calculate price based on pair reserves
   function getTokenPrice(address pairAddress, uint amount) public view returns(uint)
   {
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    IERC20 token1 = IERC20(pair.token1());
    (uint Res0, uint Res1,) = pair.getReserves();   

    // decimals
    uint res0 = Res0*(10**token1.decimals());
    return((amount*res0)/Res1); // return amount of token0 needed to buy token1
   }
  */
}