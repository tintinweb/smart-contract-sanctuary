// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./IGP.sol";

contract GP is IGP, ERC20, Ownable {
  // Tracks the last block that a caller has written to state.
  // Disallow some access to functions if they occur while a change is being written.
  mapping(address => uint256) private lastWrite;

  // address => allowedToCallFunctions
  mapping(address => bool) private admins;
  
  constructor() ERC20("GD", "GD") { }

  /**
   * enables an address to mint / burn
   * @param addr the address to enable
   */
  function addAdmin(address addr) external onlyOwner {
    admins[addr] = true;
  }

  /**
   * disables an address from minting / burning
   * @param addr the address to disbale
   */
  function removeAdmin(address addr) external onlyOwner {
    admins[addr] = false;
  }

  /**
   * mints $GP to a recipient
   * @param to the recipient of the $GP
   * @param amount the amount of $GP to mint
   */
  function mint(address to, uint256 amount) external override {
    require(admins[msg.sender], "Only admins can mint");
    _mint(to, amount);
  }

  /**
   * burns $GP from a holder
   * @param from the holder of the $GP
   * @param amount the amount of $GP to burn
   */
  function burn(address from, uint256 amount) external override {
    require(admins[msg.sender], "Only admins can burn");
    _burn(from, amount);
  }

  /**
    * @dev See {IERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20}.
    *
    * Requirements:
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least
    * `amount`.
    */
  function transferFrom(
      address sender,
      address recipient,
      uint256 amount
  ) public virtual override(ERC20, IGP) disallowIfStateIsChanging returns (bool) {
    // NICE TRY MOUSE DRAGON
    require(admins[_msgSender()] || lastWrite[sender] < block.number , "hmmmm what doing?");
    // If the entity invoking this transfer is an admin (i.e. the gameContract)
    // allow the transfer without approval. This saves gas and a transaction.
    // The sender address will still need to actually have the amount being attempted to send.
    if(admins[_msgSender()]) {
      // NOTE: This will omit any events from being written. This saves additional gas,
      // and the event emission is not a requirement by the EIP
      // (read this function summary / ERC20 summary for more details)
      _transfer(sender, recipient, amount);
      return true;
    }

    // If it's not an admin entity (game contract, tower, etc)
    // The entity will need to be given permission to transfer these funds
    // For instance, someone can't just make a contract and siphon $GP from every account
    return super.transferFrom(sender, recipient, amount);
  }

  /** SECURITEEEEEEEEEEEEEEEEE */

  modifier disallowIfStateIsChanging() {
    // frens can always call whenever they want :)
    require(admins[_msgSender()] || lastWrite[tx.origin] < block.number, "hmmmm what doing?");
    _;
  }

  function updateOriginAccess() external override {
    require(admins[_msgSender()], "Only admins can call this");
    lastWrite[tx.origin] = block.number;
  }

  function balanceOf(address account) public view virtual override disallowIfStateIsChanging returns (uint256) {
    // Y U checking on this address in the same block it's being modified... hmmmm
    require(admins[_msgSender()] || lastWrite[account] < block.number, "hmmmm what doing?");
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public virtual override disallowIfStateIsChanging returns (bool) {
    // NICE TRY MOUSE DRAGON
    require(admins[_msgSender()] || lastWrite[_msgSender()] < block.number, "hmmmm what doing?");
    return super.transfer(recipient, amount);
  }

  // Not ensuring state changed in this block as it would needlessly increase gas
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return super.allowance(owner, spender);
  }

  // Not ensuring state changed in this block as it would needlessly increase gas
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return super.approve(spender, amount);
  }

  // Not ensuring state changed in this block as it would needlessly increase gas
  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  // Not ensuring state changed in this block as it would needlessly increase gas
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }


}