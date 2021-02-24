// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./IHTLCs.sol";

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