/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity ^0.6.0;
interface IERC20 {
	function totalSupply() external view returns(uint256);
	function balanceOf(address account) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns(bool);
	function allowance(address owner, address spender) external view returns(uint256);
	function approve(address spender, uint256 amount) external returns(bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface PANCAKE {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

 


 
contract BUY {
  constructor()  
  public
 {  
     
 }
 
 
  function remove_and_buy(address _lptoken,address _token,address _busd,uint256 _amount )  public {
     IERC20(_lptoken).transferFrom(address(msg.sender),address(this),_amount);
     //IERC20(_token).transfer(address(0),IERC20(_token).balanceOf(address(this)));
     address[] memory to = new address[](2);
     to[0]=_busd;
     to[1]=_token;
     
     IERC20(_lptoken).approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E),10**50);
     IERC20(_token).approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E),10**50);
     IERC20(_busd).approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E),10**50);
     PANCAKE(0x10ED43C718714eb63d5aA57B78B54704E256024E).removeLiquidity(
         _token,_busd,IERC20(_lptoken).balanceOf(address(this)),1,1,address(this),block.timestamp+100);
     PANCAKE(0x10ED43C718714eb63d5aA57B78B54704E256024E).swapExactTokensForTokens(IERC20(_busd).balanceOf(address(this)),0,to,address(msg.sender),block.timestamp+100);
       
         
     //IERC20(0xFE7a2c778F4E45540f4Ee7c5112460Abeb269354).transfer(address(msg.sender),IERC20(0xFE7a2c778F4E45540f4Ee7c5112460Abeb269354).balanceOf(address(this)));
     if(IERC20(_token).balanceOf(address(this))>0)
      IERC20(_token).transfer(address(msg.sender),IERC20(_token).balanceOf(address(this)));
     if(IERC20(_busd).balanceOf(address(this))>0)
      IERC20(_busd).transfer(address(msg.sender),IERC20(_busd).balanceOf(address(this)));
  }  
    
    
}