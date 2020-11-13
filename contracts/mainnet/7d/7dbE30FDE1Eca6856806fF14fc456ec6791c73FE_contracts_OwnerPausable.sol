// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract OwnerPausable is OwnableUpgradeSafe, PausableUpgradeSafe {

  function __OwnerPausable__init() public {
    __Pausable_init_unchained();
  }

  /**
    * @dev Pauses all functions guarded by Pause
    *
    * See {Pausable-_pause}.
    *
    * Requirements:
    *
    * - the caller must be the owner.
    */
  function pause() public onlyOwner {
      _pause();
  }

  /**
    * @dev Unpauses the contract
    *
    * See {Pausable-_unpause}.
    *
    * Requirements:
    *
    * - the caller must be the owner`.
    */
  function unpause() public onlyOwner {
      _unpause();
  }
}