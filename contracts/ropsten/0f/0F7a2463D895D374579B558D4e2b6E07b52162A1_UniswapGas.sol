/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity 0.8.1;

interface IUniswap {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract UniswapGas {
  ChiToken constant public chi = ChiToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);
  IUniswap constant public uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  modifier discountCHI {
    uint256 gasStart = gasleft();

    _;

    uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
    chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
  }
  
  function swapETHForExactTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        discountCHI {
            
            uniswap.swapETHForExactTokens{ value: msg.value }(
              amountOutMin,
              path,
              to,
              deadline
            );
            
        }
        
  function swapExactTokensForETH(address tokenAddress, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        discountCHI {
            
            IERC20(tokenAddress).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, uint(2**256 - 1));
            
            uniswap.swapExactTokensForETH(
              amountIn,
              amountOutMin,
              path,
              to,
              deadline
            );
            
            
        }
  
  
  
  
  
  // important to receive ETH
  receive() payable external {}
}