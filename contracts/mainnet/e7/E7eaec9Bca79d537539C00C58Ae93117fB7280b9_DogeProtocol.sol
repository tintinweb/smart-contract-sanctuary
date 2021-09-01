// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Detailed.sol";

contract DogeProtocol is ERC20Detailed {
    
  string constant tokenNameWeNeed = "Doge Protocol";
  string constant tokenSymbol = "dogep";
  uint8 decimalsWeNeed = 18;
  
  uint256 totalSupplyWeNeed = 100 * (10**12) * (10**decimalsWeNeed);
  uint256  baseBurnPercentDivisor = 100000; //0.1% per transaction

  //Saturday, April 30, 2022 11:59:59 PM
  uint256 tokenAllowedCutOffDate = 1651363199;  
  uint256 tokenAllowedPerAccount = 99 * (10**10) * (10**decimalsWeNeed);
  
  constructor(address priorApprovalContractAddress) public payable ERC20Detailed
  (
       tokenNameWeNeed, 
       tokenSymbol, 
       totalSupplyWeNeed,
       baseBurnPercentDivisor, 
       decimalsWeNeed,
       tokenAllowedCutOffDate,
       tokenAllowedPerAccount,
       priorApprovalContractAddress
   ) 
  {
    _mint(msg.sender, totalSupply());
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  
}