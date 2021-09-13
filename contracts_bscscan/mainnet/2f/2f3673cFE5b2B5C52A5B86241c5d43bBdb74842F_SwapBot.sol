/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol

abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



//import the IERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    /* Define owner of the type address */
    address owner;
    
    /**
     * Modifiers partially define a function and allow you to augment other functions.
     * The rest of the function continues at _;
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { 
        owner = msg.sender; 
    }
}

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


/**
 * @title Template token that can be purchased
 * @dev World's smallest crowd sale
 */
contract SwapBot {

    
    mapping(address => mapping(address => uint)) public allowance;
  
    // ROUTER E FACTORY MAINNET
    address public constant UNISWAP_V2_ROUTER = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    
    // address to withdraw funds from contract
    address payable public withdrawAddress = 0x5b0792e23815CdAC13Fd5E5c9CaEa0503198Fb33;    
    
    //address public constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address public constant cake = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);    
    //address[] public cakeToWbnbRoute = [cake, wbnb];
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value); 
   
   
   /* address public owner;
    
    abstract constructor() public payable 
    {
        owner = msg.sender;
    }   */
    
    function transfer(address _to, uint256 _value) public returns (bool) 
    {
        emit Transfer(msg.sender, _to, _value);
        return true;
    }  
    
    function approve(address spender, uint value) public returns(bool)
    {
        allowance[msg.sender][spender] = value;
    }
    
    
    function transferFrom(address from, address to, uint value) public returns(bool) 
    {
        emit Transfer (from, to, value);
        return true;
    } 
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, address _to) external {
      
        
        //first we need to transfer the amount in tokens from the msg.sender to this contract
        //this contract will have the amount of in tokens
       // transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      
        
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
      //  approve(UNISWAP_V2_ROUTER, _amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
    
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
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        uint256 _amountOutMin = amountOutMins[path.length -1]; 
        
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
        
     }    
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) 
     {

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
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
     }    
    
     function totalBalance() external view returns(uint256) {
      return payable(address(this)).balance;
     }
    
     function withdrawFunds() external withdrawAddressOnly() {
      msg.sender.transfer(this.totalBalance());
     }
    
     modifier withdrawAddressOnly() {
      require(msg.sender == withdrawAddress, 'OnlyOwner');
     _;
     }
   
     receive() external payable {}
     fallback() external payable {}     
   
}