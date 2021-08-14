// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 *
 * @title      
 * 
 */
contract Fazan is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {

  /**
   * @dev        constructor
   */
  constructor() ERC20("Fazan", "FZN") {
    _mint(msg.sender, 400000000 * 10 ** decimals());
  }

  /**
   * @dev        
   */
  function snapshot() public onlyOwner {
    _snapshot();
  }

  /**
   * @dev        {developper_note }
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev        {developper_note }
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev        {developper_note }
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override(ERC20, ERC20Snapshot)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}