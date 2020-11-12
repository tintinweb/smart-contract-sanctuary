/**
 * VR Token – the fuel and the driver of the VICTORIA VR. ---> WWW.VICTORIAVR.COM <---
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Snapshot.sol";

contract VictoriaVR is Ownable, ERC20Burnable, ERC20Pausable, ERC20Snapshot {

  constructor(address totalSupplyTo) public ERC20("Victoria VR", "VR") {
    _mint(totalSupplyTo, 168000000000000000000000000000);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable, ERC20Snapshot) {
    super._beforeTokenTransfer(from, to, amount);
  }

  function pause() public onlyOwner whenNotPaused {
  	super._pause();
  }

  function unpause() public onlyOwner whenPaused {
  	super._unpause();
  }

  function snapshot() public onlyOwner returns (uint256) {
  	return super._snapshot();
  }
}

 /**
 * ---> WWW.VICTORIAVR.COM <---
 */