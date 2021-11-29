//    .oooooo.                                      .oooooo.                 .          .oooooo.                                          
//   d8P'  `Y8b                                    d8P'  `Y8b              .o8         d8P'  `Y8b                                         
//  888           .ooooo.  oo.ooooo.  oooo    ooo 888           .oooo.   .o888oo      888            .oooo.   ooo. .oo.  .oo.    .ooooo.  
//  888          d88' `88b  888' `88b  `88.  .8'  888          `P  )88b    888        888           `P  )88b  `888P"Y88bP"Y88b  d88' `88b 
//  888          888   888  888   888   `88..8'   888           .oP"888    888        888     ooooo  .oP"888   888   888   888  888ooo888 
//  `88b    ooo  888   888  888   888    `888'    `88b    ooo  d8(  888    888 .      `88.    .88'  d8(  888   888   888   888  888    .o 
//   `Y8bood8P'  `Y8bod8P'  888bod8P'     .8'      `Y8bood8P'  `Y888""8o   "888"       `Y8bood8P'   `Y888""8o o888o o888o o888o `Y8bod8P' 
//                          888       .o..P'                                                                                              
//                         o888o      `Y8P'                                                                                               
//                                                                                                                                        
//     o    ooo        ooooo  o8o  oooo  oooo             ooooooooooooo           oooo                                                    
//  .d88888 `88.       .888'  `"'  `888  `888             8'   888   `8           `888                                                    
//  8[ 8     888b     d'888  oooo   888   888  oooo            888       .ooooo.   888  oooo   .ooooo.  ooo. .oo.                         
//  `Y888B.  8 Y88. .P  888  `888   888   888 .8P'             888      d88' `88b  888 .8P'   d88' `88b `888P"Y88b                        
//     8 ]8  8  `888'   888   888   888   888888.              888      888   888  888888.    888ooo888  888   888                        
//  88888P'  8    Y     888   888   888   888 `88b.            888      888   888  888 `88b.  888    .o  888   888                        
//     8    o8o        o888o o888o o888o o888o o888o          o888o     `Y8bod8P' o888o o888o `Y8bod8P' o888o o888o                       



// https://discord.gg/KBRDfVaM
// SPDX-License-Identifier: MIT LICENSE

// ALL CHANGES DONE

pragma solidity ^0.8.0;
import "ERC20.sol";
import "Ownable.sol";

contract MILK is ERC20, Ownable {

  
  mapping(address => bool) controllers;        // a mapping from an address to whether or not it can mint / burn
  constructor() ERC20("MILK", "MILK") { }

  // mints $MILK to a recipient
  function mint(address to, uint256 amount) external {                    
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  // burns $MILK from a holder
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }


  // enables an address to mint / burn
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  // disables an address from minting / burning
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}