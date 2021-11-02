/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPancakeRouter01 {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
}

contract Swap {
    //Address assigning
    address private constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    //Swap function Totken to Token
    function swapT2T(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) external {
        
        //Transferring spending amount to this contract
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        //Getting approval from router to spend
        IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
        
        //Path declaring in array
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        //Executing the function
        IPancakeRouter01(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
      
    }
    

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint) {
     
      //Path declaring in array
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
    
        uint[] memory amountOutMins = IPancakeRouter01(PANCAKE_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];
    }   
}