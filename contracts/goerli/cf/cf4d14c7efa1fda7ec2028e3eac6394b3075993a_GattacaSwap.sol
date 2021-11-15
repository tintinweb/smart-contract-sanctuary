/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity ^0.7.0;

interface IUniswap {
  function swapExactTokensForETH(
    uint amountIn, 
    uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline)
    payable
    external
    returns (uint[] memory amounts);
    
  function swapExactETHForTokens(
      uint amountOutMin, 
      address[] calldata path, 
      address to, 
      uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline) 
    external
    payable
    returns (uint[] memory amounts);
    
  function WETH() external pure returns (address);
  
  function getAmountsIn(
      uint amountOut, 
      address[] memory path)
      external
      view
      returns (uint[] memory amounts);
}

interface IERC20 {
  function approve(
    address spender, 
    uint256 amount)
    external 
    returns (bool);
    
  function transferFrom(
    address sender, 
    address recipient, 
    uint256 amount) 
    external 
    returns (bool);
}

contract GattacaSwap {
  event SwappedCommencing(address to, address from, uint amount);
  event SwappedOccurred(address to, address from, uint amount);
  IUniswap uniswap;

  constructor(address _uniswap) {
    uniswap = IUniswap(_uniswap);
  }

  function swapExactTokensForTokens(address fromToken, address toToken, uint amountIn, uint deadline) payable external {
    emit SwappedCommencing(fromToken, toToken, amountIn);
    IERC20(toToken).transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswap.WETH();
    IERC20(toToken).approve(address(uniswap), amountIn);
    
    uniswap.swapExactTokensForETH{value: msg.value}(
            msg.value,
            msg.value,
            path,
            msg.sender,
            block.timestamp + 10000
        );
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
    emit SwappedOccurred(fromToken, toToken, amountIn);
  }
  
  function swapTokensForEth(address token, uint amountIn, uint amountOut, uint deadline) payable external {
    emit SwappedCommencing(token, uniswap.WETH(), amountIn);
    IERC20(token).transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswap.WETH();
    IERC20(token).approve(address(uniswap), amountIn);
    uniswap.swapExactETHForTokens{value: msg.value}(
            msg.value,
            path,
            msg.sender,
            block.timestamp + 100
        );
        
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
    emit SwappedOccurred(uniswap.WETH(), token, amountOut);
  }
  
  function getEstimatedTokenforTokenSwap(address fromToken, address toToken, uint amountIn) public view returns (uint[] memory) {
    address[] memory path = new address[](2);
    path[0] = fromToken;
    path[1] = toToken;
    return uniswap.getAmountsIn(amountIn, path);
  }
}