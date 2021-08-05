/**
 *Submitted for verification at Etherscan.io on 2020-07-03
*/

pragma solidity ^0.6.0;


interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


interface IUniswap {
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


interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) external returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) external returns(uint);
}



contract R2D2 {
  address kyberAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
  address uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function runTokenKyberUniswap(uint amount, address srcTokenAddress, address dstTokenAddress) onlyOwner() external {
    //Kyber srcToken => dstToken 
    //Uniswap dstToken => srcToken 
    ERC20 srcToken = ERC20(srcTokenAddress);
    ERC20 dstToken = ERC20(dstTokenAddress);
    srcToken.transfer(address(this), amount);

    //Kyber srcToken => dstToken 
    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    srcToken.approve(address(kyber), amount);
    (uint rate, ) = kyber.getExpectedRate(srcToken, dstToken, amount);
    kyber.swapTokenToToken(srcToken, amount, dstToken, rate);

    //Uniswap dstToken => srcToken 
    IUniswap uniswap = IUniswap(uniswapAddress);
    uint balanceDstToken = dstToken.balanceOf(address(this));
    dstToken.approve(address(uniswap), balanceDstToken);
    address[] memory path = new address[](2);
    path[0] = address(dstToken);
    path[1] = address(srcToken);
    uint[] memory minOuts = uniswap.getAmountsOut(balanceDstToken, path); 
    uniswap.swapExactTokensForTokens(
      balanceDstToken,
      minOuts[0], 
      path, 
      address(this), 
      now
    );
  }

  function runTokenUniswapKyber(uint amount, address srcTokenAddress, address dstTokenAddress) onlyOwner() external {
    //Kyber srcToken => dstToken 
    //Uniswap dstToken => srcToken 
    ERC20 srcToken = ERC20(srcTokenAddress);
    ERC20 dstToken = ERC20(dstTokenAddress);
    srcToken.transfer(address(this), amount);

    //Uniswap srcToken => dstToken 
    IUniswap uniswap = IUniswap(uniswapAddress);
    srcToken.approve(address(uniswap), amount);
    address[] memory path = new address[](2);
    path[0] = address(srcToken);
    path[1] = address(dstToken);
    uint[] memory minOuts = uniswap.getAmountsOut(amount, path); 
    uniswap.swapExactTokensForTokens(
      amount,
      minOuts[0], 
      path, 
      address(this), 
      now
    );

    //Kyber dstToken => srcToken
    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    uint balanceDstToken = dstToken.balanceOf(address(this));
    srcToken.approve(address(kyber), balanceDstToken);
    (uint rate, ) = kyber.getExpectedRate(dstToken, srcToken, balanceDstToken);
    kyber.swapTokenToToken(dstToken, balanceDstToken, srcToken, rate);
  }

  function withdrawETHAndTokens(address tokenAddress) external onlyOwner() {
    msg.sender.transfer(address(this).balance);
    ERC20 token = ERC20(tokenAddress);
    uint256 currentTokenBalance = token.balanceOf(address(this));
    token.transfer(msg.sender, currentTokenBalance);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'only owner');
    _;
  }

}