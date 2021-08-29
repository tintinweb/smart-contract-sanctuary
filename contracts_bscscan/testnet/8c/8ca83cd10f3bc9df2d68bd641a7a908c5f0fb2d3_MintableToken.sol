// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "ERC20.sol";
import "Ownable.sol";
import "Pausable.sol";

contract MintableToken is Ownable, Pausable, ERC20 {
    
  event Pause();
  event Unpause();
  
 
   //Fin rutina-tareas pausa 
    
    
  uint256 public token_transfer_count = 0;

  constructor () ERC20("Peko", "PKO") {
    _mint(msg.sender, 10000 ether);

  }
  
    /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    _pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
     _unpause();
  }

  function mint(address account, uint256 amount) public onlyOwner whenNotPaused{
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public onlyOwner whenNotPaused{
    _burn(account, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused
  {
    token_transfer_count += 1;
  }
}