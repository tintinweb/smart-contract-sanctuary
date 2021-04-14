pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;
import "./router.sol";
import "./router2.sol";
import "./router3.sol";

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

contract swapping{
    // ETHEREUM UNISWAP FACTORY KOVAN ADDRESS - 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    // ETHEREUM UNISWAP ROUTER KOVAN ADDRESS  - 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a
    
    // ETHEREUM AND BINANCE SUSHI SWAP ROUTER TESTNET ADDRESS - 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    
    // BINANCE PANCAKE FACTORY TESTNET ADDRESS - 0x6725F303b657a9451d8BA641348b6761A6CC7a17
    // BINANCE PANCAKE ROUTER TESTNET ADDRESS - 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    
    
    // ETHEREUM UNISWAP FACTORY KOVAN ADDRESS
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    // ETHEREUM UNISWAP ROUTER KOVAN ADDRESS 
    IUniswapV2Router01 router = IUniswapV2Router01(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
    
    // ETHEREUM AND BINANCE SUSHI SWAP ROUTER TESTNET ADDRESS
    IUniswapV2Router02 router2 = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    
    // BINANCE PANCAKE SWAP ROUTER TESTNET ADDRESS
    IPancakeRouter01 router3 = IPancakeRouter01(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    
    string[] routerStringArray;
    
    constructor () {
        routerStringArray.push("Uniswap router no. - 1");
        routerStringArray.push('SushiSwap router no. - 2');
        routerStringArray.push('Pancake router no. - 3');
    }
    
    function createPair(address _tokenA, address _tokenB) public returns(address pair){
        return factory.createPair(_tokenA,  _tokenB);
    }
    
    function getPair(address _tokenA, address _tokenB) public view returns (address pair){
        return factory.getPair(_tokenA, _tokenB);
    }
    
    function allPairs(uint _index) public view returns (address pair) {
        return factory.allPairs(_index);
    }
    
    // ------------------- PAIR ---------------------------
    
    function price0CumulativeLast(address _pair) public view returns (uint){
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        return pair.price0CumulativeLast();
    }
    
    function price1CumulativeLast(address _pair) public view returns (uint){
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        return pair.price1CumulativeLast();
    }
    
    // --------------------- ROUTER --------------------------
    
    function routerNumbers() public view returns(string[] memory routerList){ 
        return routerStringArray;
    }
    
    function factoryAddress(uint _routerNo) public view returns (address){
        return _routerNo == 1 ? router.factory() : _routerNo == 2 ? router2.factory() : router3.factory();
    }
    
    function ethAddress(uint _routerNo) public view returns (address){
        return _routerNo == 1 ? router.WETH() : _routerNo == 2 ? router2.WETH() : router3.WETH();
    }
    
    function swapExactETHForTokens(uint _routerNo, uint amountOutMin, address[] calldata path, address to, uint deadline)
      public
      payable
    {
        _routerNo == 1 ? router.swapExactETHForTokens(amountOutMin, path, to, deadline) : _routerNo == 2 ? router2.swapExactETHForTokens(amountOutMin, path, to, deadline) : router3.swapExactETHForTokens(amountOutMin, path, to, deadline);
    }
    
    function swapETHForExactTokens(uint _routerNo, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
      public
      payable
    {
        router.swapETHForExactTokens(amountOutMin, path, to, deadline);
        //   _routerNo == 1 ? router.swapETHForExactTokens(amountOutMin, path, to, deadline) : _routerNo == 2 ? router2.swapETHForExactTokens(amountOutMin, path, to, deadline) : router3.swapETHForExactTokens(amountOutMin, path, to, deadline);
    }
    
    function swapTokensForExactETH(uint _routerNo, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      public
    {
        _routerNo == 1 ? router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline) : _routerNo == 2 ? router2.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline) : router3.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
    }
    
    function swapExactTokensForETH(uint _routerNo, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      public
    {
        _routerNo == 1 ? router.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline) : _routerNo == 2 ? router2.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline) : router3.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }
    
    function swapExactTokensForTokens(uint _routerNo, uint amountIn,
      uint amountOutMin, address[] calldata path, address to, uint deadline)
      public
    {
        _routerNo == 1 ? router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline) : _routerNo == 2 ? router2.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline) : router3.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }
    
    function swapTokensForExactTokens(uint _routerNo, uint amountOut,
      uint amountInMax, address[] calldata path, address to, uint deadline)
      public
    {
        _routerNo == 1 ? router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline) : _routerNo == 2 ? router2.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline) : router3.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }
    
}