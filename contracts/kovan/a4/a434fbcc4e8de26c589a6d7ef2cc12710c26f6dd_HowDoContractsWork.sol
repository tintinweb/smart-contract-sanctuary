/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
    function WETH() external pure returns (address); //This can be replaced with literal once deployed to mainnet, if necessary
}

interface IWETH {
    function balanceOf(address vault) external view returns (uint);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract HowDoContractsWork 
{
    function doesRequirePrintIfFalse() public payable returns (uint256 weiPaid)
    {
        return msg.value;
    }
    
    function wrapVaultETH() public {
        address UNISWAP_API_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //This address is the same on testnets too.
        address WETHAddress = IUniswap(UNISWAP_API_ADDRESS).WETH();
        IWETH(WETHAddress).deposit{value: address(this).balance}();
        //require(address(this).balance == 0, "Wrapping ETH failed");
    }
}