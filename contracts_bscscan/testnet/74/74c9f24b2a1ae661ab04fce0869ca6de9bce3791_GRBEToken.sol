// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';
import './SafeMath.sol';
import './Pausable.sol';

// GRBEToken with Governance
contract GRBEToken is ERC20, Pausable {
//   using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address private governance;
  address private pendingGovernance;
  mapping(address => bool) private minters;

  // max amount token: 1 billion
  uint256 public constant cap = 1000000000 ether;

  constructor() Pausable() ERC20('GB', 'GR') {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, '!governance');
    _;
  }

  modifier onlyPendingGovernance() {
    require(msg.sender == pendingGovernance, '!pendingGovernance');
    _;
  }

  function setGovernance(address governance_) external virtual onlyGovernance {
    pendingGovernance = governance_;
  }

  function claimGovernance() external virtual onlyPendingGovernance {
    governance = pendingGovernance;
    delete pendingGovernance;
  }

  function addMinter(address minter_) external virtual onlyGovernance {
    minters[minter_] = true;
  }

  function removeMinter(address minter_) external virtual onlyGovernance {
    minters[minter_] = false;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must be the governance.
   */
  function pause() external virtual onlyGovernance {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must be the governance.
   */
  function unpause() external virtual onlyGovernance {
    _unpause();
  }

  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - minted tokens must not cause the total supply to go over the cap.
   */
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 amount_
  ) internal virtual override {
    super._beforeTokenTransfer(from_, to_, amount_);

    require(!paused(), 'ERC20Pausable: token transfer while paused');

    if (from_ == address(0)) {
      // When minting tokens
      require(totalSupply().add(amount_) <= cap, 'ERC20Capped: cap exceeded');
    }
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the governance or minter.
   */
  function mint(address to_, uint256 amount_) external virtual {
    require(msg.sender == governance || minters[msg.sender], '!governance && !minter');
    _mint(to_, amount_);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount_) external virtual {
    _burn(msg.sender, amount_);
  }
}