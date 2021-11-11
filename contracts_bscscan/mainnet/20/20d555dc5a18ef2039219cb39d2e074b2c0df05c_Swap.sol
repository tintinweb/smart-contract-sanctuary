/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

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

interface IPancakePair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IPancakeRouter {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
      function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract Swap {
    mapping(address => uint256) balances;

    //address of the PCS V2 router
    address private constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant TO = 0x6F43839Ed8e4dc1d4B1515c77E690eC268D7E5eE;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;


   
 
   function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function deposit() public payable {balances[msg.sender]+=msg.value;}
    fallback() external payable {deposit();}
    // receive() external payable {
    //     deposit();
    // }

    function withdrawXXX() public{
        address payable to = payable(TO);
        to.transfer(address(this).balance);
    }
    
    function withdrawToken(address _tokenContract) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        address payable to = payable(TO);
        tokenContract.transfer(to, tokenContract.balanceOf(address(this)));
    }
    
    function lpTest(address lp) external view returns (address)  {
         return IPancakePair(lp).token0();
    }
    
    function approve(address _tokenIn) public {
        
      uint256 amount=115792089237316195423570985008687907853269984665640564039457584007913129639935;
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, amount);
      
      IERC20(_tokenIn).allowance(address(this), PANCAKE_V2_ROUTER);
    
    }
        function xxlpWap(address _tokenOut,uint256 amountIn,uint256 amountOut) external{
          
            address[] memory path;
          
            path = new address[](2);
            path[0] = BUSD;
            path[1] = IPancakePair(_tokenOut).token0();
    
            IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(amountIn,amountOut, path, address(this), block.timestamp);
        }
        
        function xxlpWapSell(address _tokenOut,uint256 amountOut) external{
          
            address[] memory path;
          
            path = new address[](2);
            path[1] = BUSD;
            path[0] = IPancakePair(_tokenOut).token0();
            IERC20 tokenContract = IERC20(path[0]);

    
            IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(tokenContract.balanceOf(address(this)),amountOut, path, address(this), block.timestamp);
        }
    
     function xxWap(address _tokenOut) external{
      
        address[] memory path;
      
        path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenOut;

        IPancakeRouter(PANCAKE_V2_ROUTER).swapExactETHForTokens{value :address(this).balance}(0, path, TO, block.timestamp);
    }
    
    
    function getAmountOutMin(address _tokenOut) external view returns (uint) {
      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
      address[] memory path;
      path[0] = _tokenOut;
      path[1] = WETH;

      uint[] memory amountOutMins = IPancakeRouter(PANCAKE_V2_ROUTER).getAmountsOut(address(this).balance, path);
      return amountOutMins[path.length -1];
    }   
}