// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @dev {ERC20} BANK token, including:
 * 
 * - a minter role that allows for token minting (creation)
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions
 * using the different roles.
 * This contract is upgradable.
 */
contract BankToken is Initializable, PausableUpgradeable, AccessControlUpgradeable, ERC20Upgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
    @notice Construct a BankToken instance
    @param admin The default role controller, minter and pauser for the contract.
    @param minter An additional minter (for quick launch of epoch 1).
   */
  function initialize(address admin, address minter) public initializer {
    __ERC20_init("Float Bank", "BANK");
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    _setupRole(MINTER_ROLE, admin);
    _setupRole(MINTER_ROLE, minter);
    _setupRole(PAUSER_ROLE, admin);
  }

  /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
  function mint(address to, uint256 amount) public virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), "Bank::mint: must have minter role to mint");
    _mint(to, amount);
  }

  /**
    * @dev Pauses all token transfers.
    *
    * See {ERC20Pausable} and {Pausable-_pause}.
    *
    * Requirements:
    *
    * - the caller must have the `PAUSER_ROLE`.
    */
  function pause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Bank::pause: must have pauser role to pause");
    _pause();
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
  function unpause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Bank::unpause: must have pauser role to unpause");
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual
    override(ERC20Upgradeable) {
      super._beforeTokenTransfer(from, to, amount);

      require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}