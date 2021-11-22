// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Block library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BlockLib {
  struct BlockRelated {
    bool added;
    uint256 removedAtBlockNumber;
  }

  /**
   * @notice Verifies self struct at current block
   * @param self self struct
   * @return true on correct self struct
   */
  function verifyAtCurrentBlock(
    BlockRelated memory self
  )
    internal
    view
    returns (bool)
  {
    return verifyAtBlock(self, block.number);
  }

  /**
   * @notice Verifies self struct at any block
   * @param self self struct
   * @return true on correct self struct
   */
  function verifyAtAnyBlock(
    BlockRelated memory self
  )
    internal
    pure
    returns (bool)
  {
    return verifyAtBlock(self, 0);
  }

  /**
   * @notice Verifies self struct at specific block
   * @param self self struct
   * @param blockNumber block number to verify
   * @return true on correct self struct
   */
  function verifyAtBlock(
    BlockRelated memory self,
    uint256 blockNumber
  )
    internal
    pure
    returns (bool)
  {
    bool result = false;

    if (self.added) {
      if (self.removedAtBlockNumber == 0) {
        result = true;
      } else if (blockNumber == 0) {
        result = true;
      } else {
        result = self.removedAtBlockNumber > blockNumber;
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BlockLib.sol";


/**
 * @title External account registry
 *
 * @notice Global registry for keys and external (outside of the platform) contract based wallets
 *
 * @dev An account can call the registry to add (`addAccountOwner`) or remove (`removeAccountOwner`) its own owners.
 * When the owner has been added, information about that fact will live in the registry forever.
 * Removing an owner only affects the future blocks (until the owner is re-added).
 *
 * Given the fact, there is no way to sign the data using a contract based wallet,
 * we created a registry to store signed by the key wallet proofs.
 * ERC-1271 allows removing a signer after the signature was created. Thus store the signature for the later use
 * doesn't guarantee the signer is still has access to that smart account.
 * Because of that, the ERC1271's `isValidSignature()` cannot be used in e.g. `PaymentRegistry`.*
 *
 * An account can call the registry to add (`addAccountProof`) or remove (`removeAccountProof`) proof hash.
 * When the proof has been added, information about that fact will live in the registry forever.
 * Removing a proof only affects the future blocks (until the proof is re-added).
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ExternalAccountRegistry {
  using BlockLib for BlockLib.BlockRelated;

  struct Account {
    mapping(address => BlockLib.BlockRelated) owners;
    mapping(bytes32 => BlockLib.BlockRelated) proofs;
  }

  mapping(address => Account) private accounts;

  // events

  /**
   * @dev Emitted when the new owner is added
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerAdded(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the existing owner is removed
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerRemoved(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the new proof is added
   * @param account account address
   * @param hash proof hash
   */
  event AccountProofAdded(
    address account,
    bytes32 hash
  );

  /**
   * @dev Emitted when the existing proof is removed
   * @param account account address
   * @param hash proof hash
   */
  event AccountProofRemoved(
    address account,
    bytes32 hash
  );

  // external functions

  /**
   * @notice Adds a new account owner
   * @param owner owner address
   */
  function addAccountOwner(
    address owner
  )
    external
  {
    require(
      owner != address(0),
      "ExternalAccountRegistry: cannot add 0x0 owner"
    );

    require(
      !accounts[msg.sender].owners[owner].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: owner already exists"
    );

    accounts[msg.sender].owners[owner].added = true;
    accounts[msg.sender].owners[owner].removedAtBlockNumber = 0;

    emit AccountOwnerAdded(
      msg.sender,
      owner
    );
  }

  /**
   * @notice Removes existing account owner
   * @param owner owner address
   */
  function removeAccountOwner(
    address owner
  )
    external
  {
    require(
      accounts[msg.sender].owners[owner].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: owner doesn't exist"
    );

    accounts[msg.sender].owners[owner].removedAtBlockNumber = block.number;

    emit AccountOwnerRemoved(
      msg.sender,
      owner
    );
  }

  /**
   * @notice Adds a new account proof
   * @param hash proof hash
   */
  function addAccountProof(
    bytes32 hash
  )
    external
  {
    require(
      !accounts[msg.sender].proofs[hash].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: proof already exists"
    );

    accounts[msg.sender].proofs[hash].added = true;
    accounts[msg.sender].proofs[hash].removedAtBlockNumber = 0;

    emit AccountProofAdded(
      msg.sender,
      hash
    );
  }

  /**
   * @notice Removes existing account proof
   * @param hash proof hash
   */
  function removeAccountProof(
    bytes32 hash
  )
    external
  {
    require(
      accounts[msg.sender].proofs[hash].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: proof doesn't exist"
    );

    accounts[msg.sender].proofs[hash].removedAtBlockNumber = block.number;

    emit AccountProofRemoved(
      msg.sender,
      hash
    );
  }

  // external functions (views)

  /**
   * @notice Verifies the owner of the account at current block
   * @param account account address
   * @param owner owner address
   * @return true on correct account owner
   */
  function verifyAccountOwner(
    address account,
    address owner
  )
    external
    view
    returns (bool)
  {
    return accounts[account].owners[owner].verifyAtCurrentBlock();
  }

  /**
   * @notice Verifies the owner of the account at specific block
   * @param account account address
   * @param owner owner address
   * @param blockNumber block number to verify
   * @return true on correct account owner
   */
  function verifyAccountOwnerAtBlock(
    address account,
    address owner,
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    return accounts[account].owners[owner].verifyAtBlock(blockNumber);
  }

  /**
   * @notice Verifies the proof of the account at current block
   * @param account account address
   * @param hash proof hash
   * @return true on correct account proof
   */
  function verifyAccountProof(
    address account,
    bytes32 hash
  )
    external
    view
    returns (bool)
  {
    return accounts[account].proofs[hash].verifyAtCurrentBlock();
  }

  /**
   * @notice Verifies the proof of the account at specific block
   * @param account account address
   * @param hash proof hash
   * @param blockNumber block number to verify
   * @return true on correct account proof
   */
  function verifyAccountProofAtBlock(
    address account,
    bytes32 hash,
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    return accounts[account].proofs[hash].verifyAtBlock(blockNumber);
  }
}