/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity 0.7.1;

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

interface IUSDC {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract UniswapExample {
    
  IUSDC usdcInstance = IUSDC(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede);
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  IUniswapV2Router02 public uniswapRouter;
  address private GDT = 0x754D73CbB65B0287884E39a510F77805f5D634e1;
  address private holderGDT = 0x5CE28EeAD9F46Ae6AA389dd088Faf047A40432F7;
  address private USDC = 0xb7a4F3E9097C08dA09517b5aB877F7a917224ede;

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  function convertUSDCtoGDT(uint amountIn) public payable {
    uint[] memory _GDTAmount;
    _GDTAmount = uniswapRouter.getAmountsOut(amountIn, getPathForUSDCtoGDT());
    uint preGDTAmount = _GDTAmount[2];
    uint GDTAmount100 = preGDTAmount / 100;
    uint GDTAmount = GDTAmount100 * 88;
    
    require(usdcInstance.transferFrom(0x60f3B2fA9e878056050bAB693C3783FE8E06e290, address(this), amountIn), 'transferFrom failed');
    require(usdcInstance.approve(address(UNISWAP_ROUTER_ADDRESS), amountIn), 'approve failed');

    uint deadline = block.timestamp; 
    uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, GDTAmount, getPathForUSDCtoGDT(), holderGDT, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function getEstimatedUSDCforGDT(uint usdcAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(usdcAmount, getPathForUSDCtoGDT());
  }

  function getPathForUSDCtoGDT() private view returns (address[] memory) {
    address[] memory path = new address[](3);
    path[0] = USDC;
    path[1] = uniswapRouter.WETH();
    path[2] = GDT;
    
    return path; 
  }
  
  // important to receive ETH
  receive() payable external {}
}