// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Burnable.sol";
import "./Capped.sol";
import "./Pausable.sol";

contract Token is Pausable, Capped, Burnable {

  /**
   * @dev {BEP20} token, including:
   *
   *  - Preminted initial supply
   *  - Capped the number of tokens that can be minted
   *  - Ability for holders to burn (destroy) their tokens
   *  - Ability to token minting (creation)
   *  - Ability to stop all token transfers
   *
   * The account that deploys the contract will be allowed mint and pause smart contract
   */
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    // uint256 initialSupply,
    uint256 maxSupply
  ) BEP20(name, symbol, decimals) Capped(maxSupply)  {
    // require(initialSupply < maxSupply, "Token: initialSupply greater than cap");
    // BEP20._mint(_msgSender(), initialSupply);
  }

  function _mint(address account, uint256 amount) internal override(BEP20, Capped) {
    super._mint(account, amount);
  }

  /**
   * @dev Create `amount` new tokens to `to`
   *
   * See {BEP20-_mint} 
   *
   * Requirements:
   *
   */
  function mint(uint256 amount) public onlyOwner returns(bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   */
  function pause() public onlyOwner virtual {
      _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   */
  function unpause() public onlyOwner virtual {
      _unpause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(BEP20, Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}