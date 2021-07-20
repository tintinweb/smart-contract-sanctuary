// SPDX-License-Identifier: MIT

// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {

  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function swapExactTokensForTokens(

    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function addLiquidityETH(
    //address of the token
    address token,
    //the desired amount of token we want to add
    uint amountTokenDesired,
    //the minimum amount of token we want to add
    uint amountTokenMin,
    //the minimum amount of ETH
    uint amountETHMin,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract CommunityTokenTest is ERC20 {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    string constant _name='CommunityTokenTest';
    string  constant _symbol='CTT';
    uint256 constant initialSupply=999000000000000;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */

    constructor()  ERC20(_name, _symbol) {
        _mint(_msgSender(), initialSupply);
    }
    /**
     * @dev Transfer that transfers given amount of Tokens from msg.sender to recipient.
     */

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //address of the uniswap v2 router
    address private UNISWAP_V3_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUniswapRouter(address uniswap_router) public {
        UNISWAP_V3_ROUTER = uniswap_router;

    }

    //address of WETH token.  This is needed because some times it is better to trade through WETH.
    //you might get a better price using WETH.
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setWeth(address weth) public {
        WETH = weth;

    }

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to

   function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) public
        returns (uint[] memory amounts){
        require(_tokenOut != address(0),'Cannot Transfer to 0x0 Account');
        //first we need to transfer the amount in tokens from the msg.sender to this contract
        //this contract will have the amount of in tokens
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        IERC20(_tokenIn).safeApprove(UNISWAP_V3_ROUTER, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
        }
            //then we will call swapExactTokensForTokens
            //for the deadline we will pass in block.timestamp
            //the deadline is the latest time the trade is valid for
        return IUniswapV2Router(UNISWAP_V3_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }

       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
      address[] memory path;
      if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
      } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
      }

      uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V3_ROUTER).getAmountsOut(_amountIn, path);
      return amountOutMins[path.length -1];

    }

    //this add liquidity function is used to trade from one token to another
    //the inputs are self explainatory
    //token  = the token address you want to add liquidity
    //amountTokenDesired = the desired amount of token we want to add
    //amountTokenMin = the minimum amount of token we want to add
    //amountETHMin = the minimum amount of ETH
    //deadline = the last time that the trade is valid for

    function addLiquidity(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline) public payable returns (uint amountToken, uint amountETH, uint liquidity){

        require(token != address(0),'Cannot Add Liquidity to 0x0 Account');
        require(amountTokenDesired <= IERC20(token).balanceOf(msg.sender),'Cannot Add to Liquidity Value greater than Balance');

        IERC20(token).safeApprove(UNISWAP_V3_ROUTER, amountTokenDesired);
        return IUniswapV2Router(UNISWAP_V3_ROUTER).addLiquidityETH{ value: msg.value }(
          token,
          amountTokenDesired,
          amountTokenMin,
          amountETHMin,
          msg.sender,
          deadline
        );
    }
}