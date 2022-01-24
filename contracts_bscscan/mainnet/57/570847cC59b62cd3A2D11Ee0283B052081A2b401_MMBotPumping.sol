// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}

contract MMBotPumping {
  ChiToken constant public chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
  IUniswapV2Router02 constant public uniRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  address constant public LFW = 0xD71239a33C8542Bd42130c1B4ACA0673B4e4f48B;
  address constant public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  modifier discountCHI {
    uint256 gasStart = gasleft();

    _;

    uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
    chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
  }
  
  function convertBNBToLFW() external payable {
    _convertBNBToLFW();
  }

  function convertBNBToLFWWithGasRefund() external payable discountCHI {
    _convertBNBToLFW();
  }
  

  function _getPathForBNBtoLFW() private pure returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = wbnb;
    path[1] = LFW;
    
    return path;
  }
  
  function _convertBNBToLFW() private {
    // using 'now' for convenience in Remix, for mainnet pass deadline from frontend!
    uint deadline = block.timestamp + 15;

    uniRouter.swapExactETHForTokens{ value: msg.value }(
      0,
      _getPathForBNBtoLFW(),
      address(this),
      deadline
    );
    
    // refund leftover BNB to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  // important to receive BNB
  receive() payable external {}
}