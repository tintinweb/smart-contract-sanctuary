// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Capped.sol";
import "./AccessControl.sol";

contract SDGToken is ERC20, ERC20Capped, ERC20Pausable, ERC20Burnable, AccessControl {

  // minter role grants minting permissions (only on wednesdays)
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant COUNCIL_ROLE = keccak256("COUNCIL_ROLE");
  // maximum amount to be minted each wednesday
  uint256 public maxMint = 33333 * 1E8;
  // define initial supply
  uint256 public constant initialSuppply = 33333333 * 1E8;
  // last minting timestamp
  uint lastMintTimestamp = 0;

  constructor(address institute) ERC20('SDG Token', 'SDG') ERC20Capped(3 * 1E9 * 1E8) {
    // set number of decimals
    _setupDecimals(8);
    // grant default permissions
    _setupRole(COUNCIL_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, institute);
    // allow council to define minters
    _setRoleAdmin(MINTER_ROLE, COUNCIL_ROLE);
    // mint initial supply to institute
    _mint(institute, initialSuppply);
  }

  function pause() public {
    // check council permission
    require(hasRole(COUNCIL_ROLE, msg.sender), 'Permission denied');
    _pause();
  }

  function unpause() public {
    // check council permission
    require(hasRole(COUNCIL_ROLE, msg.sender), 'Permission denied');
    _unpause();
  }

  function setMaxMint(uint256 newMaxMint) public {
    // check council permission
    require(hasRole(COUNCIL_ROLE, msg.sender), 'Permission denied');
    maxMint = newMaxMint;
  }

  function mint (address account, uint256 amount) public whenNotPaused() onChangeWednesday() canMint() {
    // check for the mint amount
    require(amount <= maxMint, 'Invalid amount');
    // only allow minting once a week
    require(block.timestamp > lastMintTimestamp + 86400, 'Mint can only be done once a week');
    lastMintTimestamp = block.timestamp;
    // execute the minting
    _mint(account, amount);
  }

  modifier onChangeWednesday() {
    // only allow minting on wednesday
    require(isChangeWednesday(), 'Smile, change, unplug another day');
    _;
  }

  modifier canMint() {
    // check mint permission
    require(hasRole(MINTER_ROLE, msg.sender), 'Permission denied');
    _;
  }

  function isChangeWednesday() public view returns (bool) {
    return (block.timestamp / 86400 + 4) % 7 == 3;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable, ERC20Capped)  {
    super._beforeTokenTransfer(from, to, amount);
    ERC20Capped._beforeTokenTransfer(from, to, amount);
    ERC20Pausable._beforeTokenTransfer(from, to, amount);
  }

}
