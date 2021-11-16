/*
  .oooooo.              o8o                           o8o                     
 d8P'  `Y8b             `"'                           `"'                     
888           .ooooo.  oooo  ooo. .oo.   oooo    ooo oooo   .oooo.o  .ooooo.  
888          d88' `88b `888  `888P"Y88b   `88.  .8'  `888  d88(  "8 d88' `88b 
888          888   888  888   888   888    `88..8'    888  `"Y88b.  888ooo888 
`88b    ooo  888   888  888   888   888     `888'     888  o.  )88b 888    .o 
 `Y8bood8P'  `Y8bod8P' o888o o888o o888o     `8'     o888o 8""888P' `Y8bod8P' 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

contract Multisend {
  function multisendEther(address[] memory recipients, uint256[] memory values)
    external
    payable
  {
    for (uint256 i = 0; i < recipients.length; i++)
      payable(recipients[i]).transfer(values[i]);
    uint256 balance = address(this).balance;
    if (balance > 0) payable(msg.sender).transfer(balance);
  }

  function multisendToken(
    IERC20 token,
    address[] memory recipients,
    uint256[] memory values
  ) external {
    uint256 total = 0;
    for (uint256 i = 0; i < recipients.length; i++) total += values[i];
    require(token.transferFrom(msg.sender, address(this), total));
    for (uint256 i = 0; i < recipients.length; i++)
      require(token.transfer(recipients[i], values[i]));
  }
}