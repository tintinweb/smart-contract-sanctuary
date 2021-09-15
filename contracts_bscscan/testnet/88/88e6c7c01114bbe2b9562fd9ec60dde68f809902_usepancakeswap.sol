// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.6.0;

import "./ownable.sol";

contract Pcwinterface {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract usepancakeswap is Ownable{
    address pcwaddress=0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    Pcwinterface pcwcontract = Pcwinterface(pcwaddress);
    function quote(uint _amountIn, address[] memory _path) public onlyOwner view returns (uint[] memory){
        uint[] memory amounts;
        amounts=pcwcontract.getAmountsOut(_amountIn, _path);
        return amounts;
    }

}