/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity 0.7.1;

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

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

interface IGorillaDiamond {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IUSDC {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}



contract AutoSwapForGDT {
    
  IGorillaDiamond gorillaDiamondInstance = IGorillaDiamond(0x754D73CbB65B0287884E39a510F77805f5D634e1);
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  IUniswapV2Router02 public uniswapRouter;
  address private GDT = 0x754D73CbB65B0287884E39a510F77805f5D634e1;
  address private holderGDT = 0x5CE28EeAD9F46Ae6AA389dd088Faf047A40432F7;
  
  IUSDC usdcInstance = IUSDC(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede);
  address private USDC = 0xb7a4F3E9097C08dA09517b5aB877F7a917224ede;
 

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }
  
  function convertEthToGDT(uint amountIn) public payable {
    uint[] memory _GDTAmount;
    _GDTAmount = uniswapRouter.getAmountsOut(amountIn, getPathForETHtoGDT());
    uint preGDTAmount = _GDTAmount[1];
    uint GDTAmount100 = preGDTAmount / 100;
    uint GDTAmount = GDTAmount100 * 88;
    

    uint deadline = block.timestamp; 
    uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn}(GDTAmount, getPathForETHtoGDT(), holderGDT, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }

  function getPathForETHtoGDT() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = GDT;
    
    return path; 
  }
  
  
  function approve(uint amountIn) public returns(bool) {
      require(gorillaDiamondInstance.approve(address(UNISWAP_ROUTER_ADDRESS), amountIn), 'approve failed');
      return true;
  }
  
  function transfer(uint amountIn) public payable returns(bool){
      require(gorillaDiamondInstance.transfer(address(this), amountIn), 'transferFrom failed');
      return true;
  }


  
  function convertGDTtoETH(uint amountIn) public payable {
    uint[] memory _GDTAmount;
    _GDTAmount = uniswapRouter.getAmountsOut(amountIn, getPathForGDTtoETH());
    uint preGDTAmount = _GDTAmount[1];
    uint GDTAmount100 = preGDTAmount / 100;
    uint GDTAmount = GDTAmount100 * 88;
    

    require(usdcInstance.approve(address(UNISWAP_ROUTER_ADDRESS), amountIn), 'approve failed');

    uint deadline = block.timestamp; 
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, GDTAmount, getPathForGDTtoETH(), holderGDT, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }

  function getPathForGDTtoETH() public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = GDT;
    path[1] = uniswapRouter.WETH();
    
    return path; 
  }
  
  
  
  function convertUSDCtoETH(uint amountIn) public payable {
    uint[] memory _GDTAmount;
    _GDTAmount = uniswapRouter.getAmountsOut(amountIn, getPathForUSDCtoETH());
    uint preGDTAmount = _GDTAmount[1];
    uint GDTAmount100 = preGDTAmount / 100;
    uint GDTAmount = GDTAmount100 * 88;
    

    require(usdcInstance.approve(address(UNISWAP_ROUTER_ADDRESS), amountIn), 'approve failed');

    uint deadline = block.timestamp; 
    uniswapRouter.swapExactTokensForETH(amountIn, GDTAmount, getPathForUSDCtoETH(), holderGDT, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }

  function getPathForUSDCtoETH() public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = USDC;
    path[1] = uniswapRouter.WETH();
    
    return path; 
  }
  
  // important to receive ETH
  receive() payable external {}
}