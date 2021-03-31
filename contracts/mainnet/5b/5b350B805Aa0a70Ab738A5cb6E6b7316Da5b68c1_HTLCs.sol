/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/IHTLCs.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;


/**
 * @dev Interface for a contract that allows using HTLCs for ERC-20 tokens.
 */
interface IHTLCs
{

  /**
   * @dev Returns the hash used in HTLCs of the given data.
   */
  function hashData (bytes memory data) external pure returns (bytes20);

  /**
   * @dev Computes and returns the hash / ID of an HTLC corresponding
   * to the given data.
   */
  function getId (IERC20 token, address from, address to, uint256 value,
                  uint endtime, bytes20 hash) external pure returns (bytes32);

  /**
   * @dev Creates a new HTLC:  value tokens are removed from the message
   * sender's balance and "locked" into the HTLC.  They can be reclaimed
   * by the message sender at the endtime block time, or redeemed for the
   * receiver if the preimage of hash is provided.
   */
  function create (IERC20 token, address to, uint256 value,
                   uint endtime, bytes20 hash)
      external returns (bytes32);

  /**
   * @dev Refunds a HTLC that has timed out.  All data for the HTLC has to be
   * provided here again, and the contract will check that a HTLC with this
   * data exists (as well as that it is timed out).
   */
  function timeout (IERC20 token, address from, address to, uint256 value,
                    uint endtime, bytes20 hash) external;

  /**
   * @dev Redeems a HTLC with the preimage to the receiver.  The data
   * for the HTLC has to be passed in (the hash is computed from the preimage).
   */
  function redeem (IERC20 token, address from, address to, uint256 value,
                   uint endtime, bytes memory preimage) external;

  /** @dev Emitted when a new HTLC has been created.  */
  event Created (IERC20 token, address from, address to, uint256 value,
                 uint endtime, bytes20 hash, bytes32 id);

  /** @dev Emitted when a HTLC is timed out.  */
  event TimedOut (IERC20 token, address from, address to, uint256 value,
                  uint endtime, bytes20 hash, bytes32 id);

  /** @dev Emitted when a HTLC is redeemed.  */
  event Redeemed (IERC20 token, address from, address to, uint256 value,
                  uint endtime, bytes20 hash, bytes32 id);

}

// File: contracts/HTLCs.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;



/**
 * @dev This contract allows creating (and redeeming) HTLCs based on RIPMED-160
 * for ERC-20 tokens.  With this, those tokens can be used in atomic
 * swaps e.g. with Bitcoin-based blockchains or even Lightning.
 */
contract HTLCs is IHTLCs
{

  /**
   * @dev Hashes of all currently active HTLCs.  Each HTLC consists of
   * its token's address, the value in tokens, a sender and receiver address,
   * a timestamp for when it times out, and a hash value with which the
   * receiver can redeem it.
   *
   * These pieces of data are hashed together to produce an ID, which is
   * stored here in a set.  This way, the contract can verify any claims about
   * active HTLCs, while not having to store all the corresponding data
   * itself in contract storage.
   */
  mapping (bytes32 => bool) public active;

  /**
   * @dev Returns the hash used for HTLCs.  We use RIPEMD160, to be
   * compatible with HTLCs from BOLT 03 (Lightning).
   */
  function hashData (bytes memory data) public override pure returns (bytes20)
  {
    return ripemd160 (data);
  }

  /**
   * @dev Computes and returns the ID that we use internally to refer
   * to an HTLC with the given data.  This is a hash value of the data,
   * so commits to the HTLC's content.
   */
  function getId (IERC20 token, address from, address to, uint256 value,
                  uint endtime, bytes20 hash)
      public override pure returns (bytes32)
  {
    return keccak256 (abi.encodePacked (address (token), from, to, value,
                                        endtime, hash));
  }

  /**
   * @dev Creates a new HTLC, locking the tokens and marking its hash as active.
   */
  function create (IERC20 token, address to, uint256 value,
                   uint endtime, bytes20 hash)
      external override returns (bytes32)
  {
    bytes32 id = getId (token, msg.sender, to, value, endtime, hash);
    require (!active[id], "HTLCs: HTLC with this data is already active");

    require (token.transferFrom (msg.sender, address (this), value),
             "HTLCs: failed to receive tokens");
    active[id] = true;

    emit Created (token, msg.sender, to, value, endtime, hash, id);
    return id;
  }

  /**
   * @dev Times out an HTLC.  This can be called by anyone who wants to
   * execute the transaction, and will pay back to the original sender
   * who locked the tokens.
   */
  function timeout (IERC20 token, address from, address to, uint256 value,
                    uint endtime, bytes20 hash) external override
  {
    require (block.timestamp >= endtime,
             "HTLCs: HTLC is not yet timed out");

    bytes32 id = getId (token, from, to, value, endtime, hash);
    require (active[id], "HTLCs: HTLC with this data is not active");

    delete active[id];
    require (token.transfer (from, value), "HTLCs: failed to send tokens");

    emit TimedOut (token, from, to, value, endtime, hash, id);
  }

  /**
   * @dev Redeems an HTLC with its preimage to the receiver.  This can be
   * called by anyone willing to pay for execution, and will send the tokens
   * always to the HTLC's receiver.
   */
  function redeem (IERC20 token, address from, address to, uint256 value,
                   uint endtime, bytes memory preimage) external override
  {
    bytes20 hash = hashData (preimage);
    bytes32 id = getId (token, from, to, value, endtime, hash);
    /* Since we compute the hash from the preimage, and then the HTLC ID
       from the hash, the check below automatically verifies that the
       sender knows a preimage to the HTLC.  */
    require (active[id], "HTLCs: HTLC with this data is not active");

    delete active[id];
    require (token.transfer (to, value), "HTLCs: failed to send tokens");

    emit Redeemed (token, from, to, value, endtime, hash, id);
  }

}