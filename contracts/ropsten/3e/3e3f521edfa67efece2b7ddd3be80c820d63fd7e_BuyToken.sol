/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity 0.7.1;
 
 interface IUniswap {

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}

 contract BuyToken{
          
    IUniswap usi = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       
function buyTokenWithExactEth() public payable returns(uint256) {
        address cryptoToken = 0x8D55238C12948d3E29Ca450654f22f1DA091C7d7;

        uint deadline = block.timestamp + 15; // I am only using 'now' for convenience, for mainnet I will pass deadline from frontend
        usi.swapExactETHForTokens{value: msg.value}(0, getPathForETHToToken(cryptoToken), address(this), deadline);

        // no need to refund ETH
        return 1000;
}

  function getPathForETHToToken(address crypto) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = usi.WETH();
    path[1] = crypto;
    
    return path;
  }
 }