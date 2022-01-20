import "./ERC20.sol";
import "./Ownable.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma solidity ^0.8.0;
 

contract GEM is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  constructor() ERC20("GEM", "GEM") { }

  /**
   * mints $GEM to a recipient
   * @param to the recipient of the $GEM
   * @param amount the amount of $GEM to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $GEM from a holder
   * @param from the holder of the $GEM
   * @param amount the amount of $GEM to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
   function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }
  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
   function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}