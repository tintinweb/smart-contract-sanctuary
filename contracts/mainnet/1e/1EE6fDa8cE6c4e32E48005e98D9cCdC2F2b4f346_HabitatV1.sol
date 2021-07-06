// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './NutBerryEvents.sol';

/// @notice The Layer 2 core protocol.
// Audit-1: ok
contract NutBerryCore is NutBerryEvents {
  /// @dev Constant, the maximum size a single block can be.
  /// Default: 31744 bytes
  function MAX_BLOCK_SIZE () public view virtual returns (uint24) {
    return 31744;
  }

  /// @dev Constant, the inspection period defines how long it takes (in L1 blocks)
  /// until a submitted solution can be finalized.
  /// Default: 60 blocks ~ 14 minutes.
  function INSPECTION_PERIOD () public view virtual returns (uint16) {
    return 60;
  }

  /// Add multiplicator parameter that says:
  /// if any N blocks get flagged, then increase the INSPECTION_PERIOD times INSPECTION_PERIOD_MULTIPLIER
  /// that puts the possible inspection period for these blocks higher up so that
  /// operators and chain users can cooperate on any situation within a bigger timeframe.
  /// That means if someone wrongfully flags valid solutions for blocks,
  /// then this just increases the INSPECTION_PERIOD and operators are not forced into challenges.
  /// If no one challenges any blocks within the increased timeframe,
  /// then the block(s) can be finalized as usual after the elevated INSPECTION_PERIOD.
  function INSPECTION_PERIOD_MULTIPLIER () public view virtual returns (uint256) {
    return 3;
  }

  /// @dev The address of the contract that includes/handles the
  /// `onChallenge` and `onFinalizeSolution` logic.
  /// Default: address(this)
  function _CHALLENGE_IMPLEMENTATION_ADDRESS () internal virtual returns (address) {
    return address(this);
  }

  /// @dev Returns the storage key used for storing the number of the highest finalized block.
  function _FINALIZED_HEIGHT_KEY () internal pure returns (uint256) {
    return 0x777302ffa8e0291a142b7d0ca91add4a3635f6d74d564879c14a0a3f2c9d251c;
  }

  /// @dev Returns the highest finalized block.
  function finalizedHeight () public view returns (uint256 ret) {
    uint256 key = _FINALIZED_HEIGHT_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `finalizedHeight`
  function _setFinalizedHeight (uint256 a) internal {
    uint256 key = _FINALIZED_HEIGHT_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key used for storing the number of the highest block.
  function _PENDING_HEIGHT_KEY () internal pure returns (uint256) {
    return 0x8171e809ec4f72187317c49280c722650635ce37e7e1d8ea127c8ce58f432b98;
  }

  /// @dev Highest not finalized block
  function pendingHeight () public view returns (uint256 ret) {
    uint256 key = _PENDING_HEIGHT_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `pendingHeight`
  function _setPendingHeight (uint256 a) internal {
    uint256 key = _PENDING_HEIGHT_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key used for storing the (byte) offset in chunked challenges.
  function _CHALLENGE_OFFSET_KEY () internal pure returns (uint256) {
    return 0xd733644cc0b916a23c558a3a2815e430d2373e6f5bf71acb729373a0dd995878;
  }

  /// @dev tracks the block offset in chunked challenges.
  function _challengeOffset () internal view returns (uint256 ret) {
    uint256 key = _CHALLENGE_OFFSET_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_challengeOffset`
  function _setChallengeOffset (uint256 a) internal {
    uint256 key = _CHALLENGE_OFFSET_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key for storing a block hash given `height`.
  function _BLOCK_HASH_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x4d8e47aa6de2727816b4bbef070a604f701f0084f916418d1cdc240661f562e1)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Returns the block hash for `height`.
  function _blockHashFor (uint256 height) internal view returns (bytes32 ret) {
    uint256 key = _BLOCK_HASH_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_blockHashFor`.
  function _setBlockHash (uint256 height, bytes32 hash) internal {
    uint256 key = _BLOCK_HASH_KEY(height);
    assembly {
      sstore(key, hash)
    }
  }

  /// @dev Returns the storage key for storing a block solution hash for block at `height`.
  function _BLOCK_SOLUTIONS_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Returns the block solution hash for block at `height`, or zero.
  function _blockSolutionFor (uint256 height) internal view returns (bytes32 ret) {
    uint256 key = _BLOCK_SOLUTIONS_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_blockSolutionFor`.
  function _setBlockSolution (uint256 height, bytes32 hash) internal {
    uint256 key = _BLOCK_SOLUTIONS_KEY(height);
    assembly {
      sstore(key, hash)
    }
  }

  function _BLOCK_META_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Holds metadata for blocks.
  /// | finalization target (blockNumber) | least significant bit is a dispute flag |
  function blockMeta (uint256 height) public view returns (uint256 ret) {
    uint256 key = _BLOCK_META_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `blockMeta`.
  function _setBlockMeta (uint256 height, uint256 val) internal {
    uint256 key = _BLOCK_META_KEY(height);
    assembly {
      sstore(key, val)
    }
  }

  /// @dev Clears storage slots and moves `finalizedHeight` to `blockNumber`.
  /// @param blockNumber The number of the block to finalize.
  function _resolveBlock (uint256 blockNumber) internal {
    _setFinalizedHeight(blockNumber);
    _setChallengeOffset(0);

    _setBlockHash(blockNumber, 0);
    _setBlockSolution(blockNumber, 0);
    _setBlockMeta(blockNumber, 0);
  }

  constructor () {
    assembly {
      // created at block
      sstore(0x319a610c8254af7ecb1f669fb64fa36285b80cad26faf7087184ce1dceb114df, number())
    }
  }

  function _onlyEOA () internal view {
    assembly {
      // if caller is not tx sender, then revert.
      // Thus, we make sure that only regular accounts can submit blocks.

      if iszero(eq(origin(), caller())) {
        revert(0, 0)
      }
    }
  }

  /// @dev This can be used to import custom data into the chain.
  /// This will create a new Block with type=3 and includes
  /// every byte from calldata starting from byte offset 4.
  /// Only regular accounts are allowed to submit blocks.
  function _createBlockMessage () internal {
    _onlyEOA();

    uint256 blockNumber = pendingHeight() + 1;
    _setPendingHeight(blockNumber);

    bytes32 blockHash;
    uint24 maxBlockSize = MAX_BLOCK_SIZE();
    assembly {
      // Computes blockHash from calldata excluding function signature.

      let size := sub(calldatasize(), 4)
      if or(gt(size, maxBlockSize), iszero(size)) {
        // exceeded MAX_BLOCK_SIZE or zero-size block
        revert(0, 0)
      }
      // temporarily save the memory pointer
      let tmp := mload(64)

      // the block nonce / block number.
      mstore(0, blockNumber)
      // block type = 3
      mstore(32, 3)
      mstore(64, timestamp())

      // copy from calldata and hash
      calldatacopy(96, 4, size)
      blockHash := keccak256(0, add(size, 96))

      // restore memory pointer
      mstore(64, tmp)
      // zero the slot
      mstore(96, 0)
    }
    _setBlockHash(blockNumber, blockHash);

    emit CustomBlockBeacon();
  }

  /// @dev Submit a transaction blob (a block).
  /// The block data is expected right after the 4-byte function signature.
  /// Only regular accounts are allowed to submit blocks.
  function submitBlock () external {
    _onlyEOA();

    uint256 blockNumber = pendingHeight() + 1;
    _setPendingHeight(blockNumber);

    // a user submitted blockType = 2
    bytes32 blockHash;
    uint24 maxBlockSize = MAX_BLOCK_SIZE();
    assembly {
      // Computes blockHash from calldata excluding function signature.

      let size := sub(calldatasize(), 4)
      if or(gt(size, maxBlockSize), iszero(size)) {
        // exceeded MAX_BLOCK_SIZE or zero-size block
        revert(0, 0)
      }
      // temporarily save the memory pointer
      let tmp := mload(64)

      // the block nonce / block number.
      mstore(0, blockNumber)
      // block type = 2
      mstore(32, 2)
      mstore(64, timestamp())

      // copy from calldata and hash
      calldatacopy(96, 4, size)
      blockHash := keccak256(0, add(size, 96))

      // restore memory pointer
      mstore(64, tmp)
      // zero the slot
      mstore(96, 0)
    }
    _setBlockHash(blockNumber, blockHash);

    emit BlockBeacon();
  }

  /// @dev Register solution for given `blockNumber`.
  /// Up to 256 solutions can be registered ahead in time.
  /// calldata layout:
  /// <4 byte function sig>
  /// <32 bytes number of first block>
  /// <32 bytes for each solution for blocks starting at first block (increments by one)>
  /// Note: You can put `holes` in the layout by inserting a 32 byte zero value.
  /// Only regular accounts are allowed to submit solutions.
  function submitSolution () external {
    _onlyEOA();

    uint256 min = finalizedHeight() + 1;
    uint256 max = min + 255;

    {
      uint256 tmp = pendingHeight();
      if (max > tmp) {
        max = tmp;
      }
    }

    uint256 finalizationTarget = (block.number + INSPECTION_PERIOD()) << 1;
    assembly {
      // underflow ok
      let blockNum := sub(calldataload(4), 1)

      for { let i := 36 } lt(i, calldatasize()) { i := add(i, 32) } {
        blockNum := add(blockNum, 1)
        let solutionHash := calldataload(i)

        if or( iszero(solutionHash), or( lt(blockNum, min), gt(blockNum, max) ) ) {
          continue
        }

        // inline _BLOCK_SOLUTIONS_KEY
        mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
        mstore(32, blockNum)
        let key := keccak256(0, 64)

        if iszero(sload(key)) {
          // store hash
          sstore(key, solutionHash)

          // store finalizationTarget
          // inline _BLOCK_META_KEY
          mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
          key := keccak256(0, 64)
          sstore(key, finalizationTarget)
        }
      }

      // emit NewSolution();
      log1(0, 0, 0xd180748b1b0c35f46942acf30f64a94a79d303ffd18cce62cbbb733b436298cb)
      stop()
    }
  }

  /// @dev Flags up to 256 solutions. This will increase the inspection period for the block(s).
  /// @param blockNumber the starting point.
  /// @param bitmask Up to 256 solutions can be flagged.
  /// Thus, a solution will be flagged if the corresponding bit is `1`.
  /// LSB first.
  function dispute (uint256 blockNumber, uint256 bitmask) external {
    uint256 min = finalizedHeight();
    uint256 finalizationTarget = 1 | ((block.number + (INSPECTION_PERIOD() * INSPECTION_PERIOD_MULTIPLIER())) << 1);

    for (uint256 i = 0; i < 256; i++) {
      uint256 flag = (bitmask >> i) & 1;
      if (flag == 0) {
        continue;
      }

      uint256 blockN = blockNumber + i;

      if (blockN > min) {
        // if a solution exists and is not not already disputed
        uint256 v = blockMeta(blockN);
        if (v != 0 && v & 1 == 0) {
          // set dispute flag and finalization target
          _setBlockMeta(blockN, finalizationTarget);
        }
      }
    }
  }

  /// @dev Challenge the solution or just verify the next pending block directly.
  /// Expects the block data right after the function signature to be included in the call.
  /// calldata layout:
  /// < 4 bytes function sig >
  /// < 32 bytes size of block >
  /// < 32 bytes number of challenge rounds >
  /// < arbitrary witness data >
  /// < data of block >
  function challenge () external {
    uint256 blockSize;
    uint256 blockDataStart;
    assembly {
      blockSize := calldataload(4)
      blockDataStart := sub(calldatasize(), blockSize)
    }

    uint256 blockNumber = finalizedHeight() + 1;

    {
      // validate the block data
      bytes32 blockHash;
      assembly {
        let tmp := mload(64)
        calldatacopy(0, blockDataStart, blockSize)
        blockHash := keccak256(0, blockSize)
        mstore(64, tmp)
        mstore(96, 0)
      }
      // blockHash must match
      require(_blockHashFor(blockNumber) == blockHash);
    }

    uint256 challengeOffset = _challengeOffset();
    address challengeHandler = _CHALLENGE_IMPLEMENTATION_ADDRESS();
    assembly {
      // function onChallenge ()
      mstore(128, 0xc47c519d)
      // additional arguments
      mstore(160, challengeOffset)
      mstore(192, challengeHandler)
      // copy calldata
      calldatacopy(224, 4, calldatasize())

      // stay in this context
      let success := callcode(gas(), challengeHandler, 0, 156, add(calldatasize(), 64), 0, 32)
      if iszero(success) {
        // Problem:
        // If for whatever reason, the challenge never proceeds,
        // then using some kind of global timeout to determine
        // that the transactions in this block until the last challengeOffset are accepted
        // but everything else is discarded is one way to implement this recovery mechanism.
        // For simplicity, just revert now. This situation can be resolved via chain governance.
        revert(0, 0)
      }
      challengeOffset := mload(0)
    }

    bool complete = !(challengeOffset < blockSize);

    if (complete) {
      // if we are done, finalize this block
      _resolveBlock(blockNumber);
    } else {
      // not done yet, save offset
      _setChallengeOffset(challengeOffset);
    }

    assembly {
      // this helps chain clients to better estimate challenge costs.
      // this may change in the future and thus is not part of the function sig.
      mstore(0, complete)
      mstore(32, challengeOffset)
      return(0, 64)
    }
  }

  /// @dev Returns true if `blockNumber` can be finalized, else false.
  /// Helper function for chain clients.
  /// @param blockNumber The number of the block in question.
  /// @return True if the block can be finalized, otherwise false.
  function canFinalizeBlock (uint256 blockNumber) public view returns (bool) {
    // shift left by 1, the lsb is the dispute bit
    uint256 target = blockMeta(blockNumber) >> 1;
    // solution too young
    if (target == 0 || block.number < target) {
      return false;
    }

    // if there is no active challenge, then yes
    return _challengeOffset() == 0;
  }

  /// @dev Finalize solution and move to the next block.
  /// This must happen in block order.
  /// Nothing can be finalized if a challenge is still active.
  /// and cannot happen if there is an active challenge.
  /// calldata layout:
  /// < 4 byte function sig >
  /// < 32 byte block number >
  /// ---
  /// < 32 byte length of solution >
  /// < solution... >
  /// ---
  /// < repeat above (---) >
  function finalizeSolution () external {
    if (_challengeOffset() != 0) {
      revert();
    }

    address challengeHandler = _CHALLENGE_IMPLEMENTATION_ADDRESS();
    assembly {
      if lt(calldatasize(), 68) {
        revert(0, 0)
      }
      // underflow ok
      let blockNumber := sub(calldataload(4), 1)

      let ptr := 36
      for { } lt(ptr, calldatasize()) { } {
        blockNumber := add(blockNumber, 1)
        // this is going to be re-used
        mstore(32, blockNumber)

        let length := calldataload(ptr)
        ptr := add(ptr, 32)

        // being optimistic, clear all the storage values in advance

        // reset _BLOCK_HASH_KEY
        mstore(0, 0x4d8e47aa6de2727816b4bbef070a604f701f0084f916418d1cdc240661f562e1)
        sstore(keccak256(0, 64), 0)

        // inline _BLOCK_SOLUTIONS_KEY
        mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
        let k := keccak256(0, 64)
        let solutionHash := sload(k)
        // reset - _BLOCK_SOLUTIONS_KEY
        sstore(k, 0)

        // _BLOCK_META_KEY
        mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
        k := keccak256(0, 64)
        // check if the finalization target is reached,
        // else revert
        let finalizationTarget := shr(1, sload(k))
        if or( lt( number(), finalizationTarget ), iszero(finalizationTarget) ) {
          // can not be finalized yet
          revert(0, 0)
        }
        // clear the slot
        sstore(k, 0)

        // function onFinalizeSolution (uint256 blockNumber, bytes32 hash)
        mstore(0, 0xc8470b09)
        // blockNumber is still stored @ 32
        mstore(64, solutionHash)
        // witness
        calldatacopy(96, ptr, length)
        // call
        let success := callcode(gas(), challengeHandler, 0, 28, add(length, 68), 0, 0)
        if iszero(success) {
          revert(0, 0)
        }

        ptr := add(ptr, length)
      }

      if iszero(eq(ptr, calldatasize())) {
        // malformed calldata?
        revert(0, 0)
      }

      // inline _setFinalizedHeight and save the new height.
      // at this point, blockNumber is assumed to be validated inside the loop
      sstore(0x777302ffa8e0291a142b7d0ca91add4a3635f6d74d564879c14a0a3f2c9d251c, blockNumber)

      // done
      stop()
    }
  }

  /// @dev Loads storage for `key`. Only attempts a load if execution happens
  /// inside a challenge, otherwise returns zero.
  function _getStorageL1 (bytes32 key) internal view returns (uint256 v) {
    assembly {
      if origin() {
        v := sload(key)
      }
    }
  }

  /// @dev Reflect a storage slot `key` with `value` to Layer 1.
  /// Useful for propagating storage changes to the contract on L1.
  function _setStorageL1 (bytes32 key, uint256 value) internal {
    assembly {
      switch origin()
      case 0 {
        // emit a event on L2
        log3(0, 0, 1, key, value)
      }
      default {
        // apply the change directly on L1 (challenge)
        sstore(key, value)
      }
    }
  }

  /// @dev Reflect a delta for storage slot with `key` to Layer 1.
  /// Useful for propagating storage changes to the contract on L1.
  function _incrementStorageL1 (bytes32 key, uint256 value) internal {
    assembly {
      switch origin()
      case 0 {
        // emit a event on L2
        log3(0, 0, 2, key, value)
      }
      default {
        // apply the change directly on L1 (challenge)
        sstore(key, add(sload(key), value))
      }
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

/// @notice Contains event declarations related to NutBerry.
// Audit-1: ok
interface NutBerryEvents {
  event BlockBeacon();
  event CustomBlockBeacon();
  event NewSolution();
  event RollupUpgrade(address target);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './NutBerryCore.sol';

/// @notice Includes Deposit & Withdraw functionality
// Audit-1: ok
contract NutBerryTokenBridge is NutBerryCore {
  event Deposit(address owner, address token, uint256 value, uint256 tokenType);
  event Withdraw(address owner, address token, uint256 value);

  /// @dev Checks if the contract at `token` implements `ownerOf(uint)`.
  /// This function saves the result on first run and returns the token type from storage
  /// on subsequent invocations.
  /// Intended to be used in a L1 context.
  /// @return tokenType Either `1` for ERC-20 or `2` for ERC-721 like contracts (NFTs).
  function _probeTokenType (address token, uint256 tokenId) internal returns (uint256 tokenType) {
    uint256 key = _L1_TOKEN_TYPE_KEY(token);
    assembly {
      tokenType := sload(key)

      if iszero(tokenType) {
        // defaults to ERC-20
        tokenType := 1

        // call ownerOf(tokenId)
        mstore(0, 0x6352211e)
        mstore(32, tokenId)
        // Note: if there is less than 60k gas available,
        // this will either succeed or fail.
        // If it fails because there wasn't enough gas left,
        // then the current call context will highly likely fail too.
        let success := staticcall(60000, token, 28, 36, 0, 0)
        // ownerOf() should return a 32 bytes value
        if and(success, eq(returndatasize(), 32)) {
          tokenType := 2
        }
        // save the result
        sstore(key, tokenType)
      }
    }
  }

  /// @dev Loads token type from storage for `token`.
  /// Intended to be used in a L2 context.
  function _getTokenType (address token) internal virtual returns (uint256) {
    uint256 key = _TOKEN_TYPE_KEY(token);
    return _sload(key);
  }

  /// @dev Saves the token type for `token`.
  /// Intended to be used in a L2 context.
  function _setTokenType (address token, uint256 tokenType) internal virtual {
    uint256 key = _TOKEN_TYPE_KEY(token);
    _sstore(key, tokenType);
  }

  /// @dev Deposit `token` and value (`amountOrId`) into bridge.
  /// @param token The ERC-20/ERC-721 token address.
  /// @param amountOrId Amount or the token id.
  /// @param receiver The account who receives the token(s).
  function deposit (address token, uint256 amountOrId, address receiver) external {
    uint256 pending = pendingHeight() + 1;
    _setPendingHeight(pending);

    uint256 tokenType = _probeTokenType(token, amountOrId);
    bytes32 blockHash;
    assembly {
      // deposit block - header

      // 32 bytes nonce
      mstore(128, pending)
      // 32 bytes block type
      mstore(160, 1)
      // 32 bytes timestamp
      mstore(192, timestamp())

      // 20 byte receiver
      mstore(224, shl(96, receiver))
      // 20 byte token
      mstore(244, shl(96, token))
      // 32 byte amount or token id
      mstore(264, amountOrId)
      // 32 byte token type
      mstore(296, tokenType)
      blockHash := keccak256(128, 200)
    }

    _setBlockHash(pending, blockHash);
    emit Deposit(receiver, token, amountOrId, tokenType);

    assembly {
      // transferFrom
      mstore(0, 0x23b872dd)
      mstore(32, caller())
      mstore(64, address())
      mstore(96, amountOrId)
      let success := call(gas(), token, 0, 28, 100, 0, 32)
      if iszero(success) {
        revert(0, 0)
      }
      // some (old) ERC-20 contracts or ERC-721 do not have a return value.
      // those who do return a non-negative value.
      if returndatasize() {
        if iszero(mload(0)) {
          revert(0, 0)
        }
      }
      stop()
    }
  }

  /// @dev Withdraw `token` and `tokenId` from bridge.
  /// `tokenId` is ignored if `token` is not a ERC-721.
  /// @param owner address of the account to withdraw from and to.
  /// @param token address of the token.
  /// @param tokenId ERC-721 token id.
  function withdraw (address owner, address token, uint256 tokenId) external {
    require(owner != address(0));

    uint256 val;
    uint256 tokenType = _probeTokenType(token, tokenId);

    if (tokenType == 1) {
      val = getERC20Exit(token, owner);
      _setERC20Exit(token, owner, 0);
    } else {
      address exitOwner = getERC721Exit(token, tokenId);
      if (owner != exitOwner) {
        revert();
      }
      val = tokenId;
      _setERC721Exit(token, address(0), val);
    }

    emit Withdraw(owner, token, val);

    assembly {
      // use transfer() for ERC-20's instead of transferFrom,
      // some token contracts check for allowance even if caller() == owner of tokens
      if eq(tokenType, 1) {
        // transfer(...)
        mstore(0, 0xa9059cbb)
        mstore(32, owner)
        mstore(64, val)
        let success := call(gas(), token, 0, 28, 68, 0, 32)
        if iszero(success) {
          revert(0, 0)
        }
        // some (old) contracts do not have a return value.
        // those who do return a non-negative value.
        if returndatasize() {
          if iszero(mload(0)) {
            revert(0, 0)
          }
        }
        stop()
      }

      // else use transferFrom
      mstore(0, 0x23b872dd)
      mstore(32, address())
      mstore(64, owner)
      mstore(96, val)
      let success := call(gas(), token, 0, 28, 100, 0, 0)
      if iszero(success) {
        revert(0, 0)
      }
      stop()
    }
  }

  function _hashERC20Exit (address target, address owner) internal pure returns (bytes32 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x409d98be992cf6feb2d0dd08517cea5626d092a062b587294f77c8867ee9ecae)
      mstore(32, target)
      mstore(64, owner)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _hashERC721Exit (address target, uint256 tokenId) internal pure returns (bytes32 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xed93405f54628300c204dec35dc26ea0937dddc7eef817a80d167cf6034b6abe)
      mstore(32, target)
      mstore(64, tokenId)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _L1_TOKEN_TYPE_KEY (address token) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x9e605931b4eb546bb835cd7af4f2eb8c79ca4254e07a7c8807e14ea0c9b99084)
      mstore(32, token)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_TYPE_KEY (address token) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x7e9dc5694c1711234663ad3120e3efc70aeefda23e219929e3785ccf356431ff)
      mstore(32, token)
      ret := keccak256(0, 64)
    }
  }

  function _incrementExit (address target, address owner, uint256 value) internal {
    NutBerryCore._incrementStorageL1(_hashERC20Exit(target, owner), value);
  }

  function getERC20Exit (address target, address owner) public view returns (uint256) {
    return NutBerryCore._getStorageL1(_hashERC20Exit(target, owner));
  }

  function _setERC20Exit (address target, address owner, uint256 value) internal {
    NutBerryCore._setStorageL1(_hashERC20Exit(target, owner), value);
  }

  function getERC721Exit (address target, uint256 tokenId) public view returns (address) {
    return address(NutBerryCore._getStorageL1(_hashERC721Exit(target, tokenId)));
  }

  function _setERC721Exit (address target, address owner, uint256 tokenId) internal {
    NutBerryCore._setStorageL1(_hashERC721Exit(target, tokenId), uint256(owner));
  }

  /// @dev SLOAD in a L2 context. Must be implemented by consumers of this contract.
  function _sload (uint256 key) internal virtual returns (uint256 ret) {
  }

  /// @dev SSTORE in a L2 context. Must be implemented by consumers of this contract.
  function _sstore (uint256 key, uint256 value) internal virtual {
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import '../../tsm/contracts/NutBerryTokenBridge.sol';

/// @notice Composition of EVM enabled, application specific rollup.
/// Version 1
// Audit-1: ok
contract NutBerryFlavorV1 is NutBerryTokenBridge {
  /// @dev Returns the storage value for `key`.
  /// Verifies access on L1(inside challenge) and reverts if no witness for this key exists.
  function _sload (uint256 key) internal override returns (uint256 ret) {
    assembly {
      switch origin()
      case 0 {
        // nothing special needs to be done on layer 2
        ret := sload(key)
      }
      default {
        // on layer 1:
        // iterates over a list of keys (32 bytes).
        // if the key is found, then a valid witness was provided in a challenge,
        // otherwise we revert here :grumpy_cat
        //
        // < usual calldata... >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >

        let end := sub(calldatasize(), 32)
        end := sub(sub(end, 32), mul(calldataload(end), 32))
        let nKeys := calldataload(end)
        let start := sub(end, mul(nKeys, 32))
        let found := 0

        for { let i := 0 } lt(i, nKeys) { i := add(i, 1) } {
          let ptr := add(start, mul(i, 32))
          if eq(calldataload(ptr), key) {
            found := 1
            break
          }
        }

        if iszero(found) {
          revert(0, 0)
        }

        ret := sload(key)
      }
    }
  }

  /// @dev Stores `value` with `key`.
  /// Verifies access on L1(inside challenge) and reverts if no witness for this key exists.
  function _sstore (uint256 key, uint256 value) internal override {
    assembly {
      switch origin()
      case 0 {
        // nothing to do on layer 2
        sstore(key, value)
      }
      default {
        // layer 1
        // iterates over a list of keys
        // if the key is found, then a valid witness was provided in a challenge,
        // otherwise: revert
        //
        // < usual calldata... >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >
        let end := sub(calldatasize(), 32)
        let nKeys := calldataload(end)
        let start := sub(end, mul(nKeys, 32))
        let found := 0

        for { let i := 0 } lt(i, nKeys) { i := add(i, 1) } {
          let ptr := add(start, mul(i, 32))
          if eq(calldataload(ptr), key) {
            // this is used to verify that all provided (write) witnesses
            // was indeed written to.
            // rollup transactions must never write to this slot
            let SPECIAL_STORAGE_SLOT := 0xabcd
            let bitmask := sload(SPECIAL_STORAGE_SLOT)

            sstore(SPECIAL_STORAGE_SLOT, and( bitmask, not(shl(i, 1)) ))
            found := 1
            break
          }
        }

        if iszero(found) {
          revert(0, 0)
        }

        sstore(key, value)
      }
    }
  }

  /// @dev Returns the timestamp (in seconds) of the block this transaction is part of.
  /// It returns the equivalent of `~~(Date.now() / 1000)` for a not yet submitted block - (L2).
  function _getTime () internal virtual returns (uint256 ret) {
    assembly {
      switch origin()
      case 0 {
        // layer 2: return the equivalent of `~~(Date.now() / 1000)`
        ret := timestamp()
      }
      default {
        // load the timestamp from calldata on layer 1.
        // the setup is done inside a challenge
        //
        // < usual calldata... >
        // < 32 bytes timestamp >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >
        let ptr := sub(calldatasize(), 32)
        // load the length of nElements and sub
        ptr := sub(ptr, mul(32, calldataload(ptr)))
        // points to the start of `write witnesses`
        ptr := sub(ptr, 32)
        // points at `# read witnesses` and subtracts
        ptr := sub(ptr, mul(32, calldataload(ptr)))
        // at the start of `read witnesses` sub 32 again
        ptr := sub(ptr, 32)
        // finish line
        ret := calldataload(ptr)
      }
    }
  }

  /// @dev Emits a log event that signals the l2 node
  /// that this transactions has to be submitted in a block before `timeSeconds`.
  function _emitTransactionDeadline (uint256 timeSeconds) internal {
    assembly {
      // only if we are off-chain
      if iszero(origin()) {
        log2(0, 0, 3, timeSeconds)
      }
    }
  }

  /// @dev Finalize solution for `blockNumber` and move to the next block.
  /// Calldata(data appended at the end) contains a blob of key:value pairs that go into storage.
  /// If this functions reverts, then the block can only be finalised by a call to `challenge`.
  /// - Should only be callable from self.
  /// - Supports relative value(delta) and absolute storage updates
  /// calldata layout:
  /// < 4 byte function sig >
  /// < 32 byte blockNumber >
  /// < 32 byte submitted solution hash >
  /// < witness data >
  function onFinalizeSolution (uint256 /*blockNumber*/, bytes32 hash) external {
    // all power to the core protocol
    require(msg.sender == address(this));

    assembly {
      // the actual witness data should be appended after the function arguments.
      let witnessDataSize := sub(calldatasize(), 68)

      calldatacopy(0, 68, witnessDataSize)
      // hash the key:value blob
      let solutionHash := keccak256(0, witnessDataSize)

      // the hash of the witness should match
      if iszero(eq(solutionHash, hash)) {
        revert(0, 0)
      }

      // update contract storage
      for { let ptr := 68 } lt(ptr, calldatasize()) { } {
        // first byte; 0 = abs, 1 = delta
        let storageType := byte(0, calldataload(ptr))
        ptr := add(ptr, 1)

        // first 32 bytes is the key
        let key := calldataload(ptr)
        ptr := add(ptr, 32)

        // second 32 bytes the value
        let val := calldataload(ptr)
        ptr := add(ptr, 32)

        switch storageType
        case 0 {
          // the value is absolute
          sstore(key, val)
        }
        default {
          // the value is actually a delta
          sstore(key, add(sload(key), val))
        }
      }
      stop()
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';

/// @notice Habitat Accounts, basic functionality for social features.
// Audit-1: ok
contract HabitatAccount is HabitatBase {
  event ClaimUsername(address indexed account, bytes32 indexed shortString);

  /// @dev State transition when a user claims a (short) username.
  /// Only one username can be claimed for `msgSender`.
  /// If `msgSender` already claimed a name, then it should be freed.
  function onClaimUsername (address msgSender, uint256 nonce, bytes32 shortString) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // checks if the `shortString` is already taken
    require(HabitatBase._getStorage(_NAME_TO_ADDRESS_KEY(shortString)) == 0, 'SET');

    {
      // free the old name, if any
      uint256 oldName = HabitatBase._getStorage(_ADDRESS_TO_NAME_KEY(msgSender));
      if (oldName != 0) {
        HabitatBase._setStorage(_NAME_TO_ADDRESS_KEY(bytes32(oldName)), bytes32(0));
      }
    }

    HabitatBase._setStorage(_NAME_TO_ADDRESS_KEY(shortString), msgSender);
    HabitatBase._setStorage(_ADDRESS_TO_NAME_KEY(msgSender), shortString);

    if (_shouldEmitEvents()) {
      emit ClaimUsername(msgSender, shortString);
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import '@NutBerry/NutBerry/src/v1/contracts/NutBerryFlavorV1.sol';
import './UpgradableRollup.sol';

/// @notice Global state and public utiltiy functions for the Habitat Rollup
// Audit-1: ok
contract HabitatBase is NutBerryFlavorV1, UpgradableRollup {
  // Useful for fetching (compressed) metadata about a specific topic.
  event MetadataUpdated(uint256 indexed topic, bytes metadata);

  /// @dev The maximum time drift between the time of block submission and a proposal's start date.
  /// This is here to avoid keeping proposals off-chain, accumulating votes and finalizing the proposal
  /// all at once on block submission without anyone being aware of it.
  function _PROPOSAL_DELAY () internal pure virtual returns (uint256) {
    // in seconds - 32 hrs
    return 3600 * 32;
  }

  function EPOCH_GENESIS () public pure virtual returns (uint256) {
  }

  function SECONDS_PER_EPOCH () public pure virtual returns (uint256) {
  }

  /// @notice The divisor for every tribute. A fraction of the operator tribute always goes into the staking pool.
  function STAKING_POOL_FEE_DIVISOR () public pure virtual returns (uint256) {
  }

  /// @dev Includes common checks for rollup transactions.
  function _commonChecks () internal view {
    // only allow calls from self
    require(msg.sender == address(this));
  }

  /// @dev Verifies and updates the account nonce for `msgSender`.
  function _checkUpdateNonce (address msgSender, uint256 nonce) internal {
    require(nonce == txNonces(msgSender), 'NONCE');

    _incrementStorage(_TX_NONCE_KEY(msgSender));
  }

  /// @dev Helper function to calculate a unique seed. Primarily used for deriving addresses.
  function _calculateSeed (address msgSender, uint256 nonce) internal pure returns (bytes32 ret) {
    assembly {
      mstore(0, msgSender)
      mstore(32, nonce)
      ret := keccak256(0, 64)
    }
  }

  // Storage helpers, functions will be replaced with special getters/setters to retrieve/store on the rollup
  /// @dev Increments `key` by `value`. Reverts on overflow or if `value` is zero.
  function _incrementStorage (uint256 key, uint256 value) internal returns (uint256 newValue) {
    uint256 oldValue = _sload(key);
    newValue = oldValue + value;
    require(newValue >= oldValue, 'INCR');
    _sstore(key, newValue);
  }

  function _incrementStorage (uint256 key) internal returns (uint256 newValue) {
    newValue = _incrementStorage(key, 1);
  }

  /// @dev Decrements `key` by `value`. Reverts on underflow or if `value` is zero.
  function _decrementStorage (uint256 key, uint256 value) internal returns (uint256 newValue) {
    uint256 oldValue = _sload(key);
    newValue = oldValue - value;
    require(newValue <= oldValue, 'DECR');
    _sstore(key, newValue);
  }

  function _getStorage (uint256 key) internal returns (uint256 ret) {
    return _sload(key);
  }

  function _setStorage (uint256 key, uint256 value) internal {
    _sstore(key, value);
  }

  function _setStorage (uint256 key, bytes32 value) internal {
    _sstore(key, uint256(value));
  }

  function _setStorage (uint256 key, address value) internal {
    _sstore(key, uint256(value));
  }

  /// @dev Helper for `_setStorage`. Writes `uint256(-1)` if `value` is zero.
  function _setStorageInfinityIfZero (uint256 key, uint256 value) internal {
    if (value == 0) {
      value = uint256(-1);
    }

    _setStorage(key, value);
  }

  /// @dev Decrements storage for `key` if `a > b` else increments the delta between `a` and `b`.
  /// Reverts on over-/underflow and if `a` equals `b`.
  function _setStorageDelta (uint256 key, uint256 a, uint256 b) internal {
    uint256 newValue;
    {
      uint256 oldValue = _sload(key);
      if (a > b) {
        uint256 delta = a - b;
        newValue = oldValue - delta;
        require(newValue < oldValue, 'DECR');
      } else {
        uint256 delta = b - a;
        newValue = oldValue + delta;
        require(newValue > oldValue, 'INCR');
      }
    }
    _sstore(key, newValue);
  }
  // end of storage helpers

  function _TX_NONCE_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x1baf1b358a7f0088724e8c8008c24c8182cafadcf6b7d0da2db2b55b40320fbf)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _ERC20_KEY (address tkn, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x24de14bddef9089376483557827abada7f1c6135d6d379c3519e56e7bc9067b9)
      mstore(32, tkn)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _ERC721_KEY (address tkn, uint256 b) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x0b0adec1d909ec867fdb1853ca8d859f7b8137ab9c01f734b3fbfc40d9061ded)
      mstore(32, tkn)
      let tmp := mload(64)
      mstore(64, b)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_SHARES_KEY (bytes32 proposalId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x24ce236379086842ae19f4302972c7dd31f4c5054826cd3e431fd503205f3b67)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_SIGNAL_KEY (bytes32 proposalId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x12bc1ed237026cb917edecf1ca641d1047e3fc382300e8b3fab49ae10095e490)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_COUNT_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x637730e93bbd8200299f72f559c841dfae36a36f86ace777eac8fe48f977a46d)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _VOTING_TOTAL_SHARE_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x847f5cbc41e438ef8193df4d65950ec6de3a1197e7324bffd84284b7940b2d4a)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _VOTING_TOTAL_SIGNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x3a5afbb81b36a1a15e90db8cc0deb491bf6379592f98c129fd8bdf0b887f82dc)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _MEMBER_OF_COMMUNITY_KEY (bytes32 communityId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x0ff6c2ccfae404e7ec55109209ac7c793d30e6818af453a7c519ca59596ccde1)
      mstore(32, communityId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _MEMBERS_TOTAL_COUNT_KEY (bytes32 communityId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xe1338c6a5be626513cff1cb54a827862ae2ab4810a79c8dfd1725e69363f4247)
      mstore(32, communityId)
      ret := keccak256(0, 64)
    }
  }

  function _NAME_TO_ADDRESS_KEY (bytes32 shortString) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x09ec9a99acfe90ba324ac042a90e28c5458cfd65beba073b0a92ea7457cdfc56)
      mstore(32, shortString)
      ret := keccak256(0, 64)
    }
  }

  function _ADDRESS_TO_NAME_KEY (address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x83cb99259282c2842186d0db03ab6fdfc530b2afa0eb2a4fe480c4815a5e1f34)
      mstore(32, account)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_VAULT_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x622061f2b694ba7aa754d63e7f341f02ac8341e2b36ccbb1d3fc1bf00b57162d)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_START_DATE_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x539a579b21c2852f7f3a22630162ab505d3fd0b33d6b46f926437d8082d494c1)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_OF_COMMUNITY_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xeadaeda4a4005f296730d16d047925edeb6f21ddc028289ebdd9904f9d65a662)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _COMMUNITY_OF_VAULT_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xf659eca1f5df040d1f35ff0bac6c4cd4017c26fe0dbe9317b2241af59edbfe06)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _MODULE_HASH_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xe6ab7761f522dca2c6f74f7f7b1083a1b184fec6b893cb3418cb3121c5eda5aa)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _VAULT_CONDITION_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x615e61b2f7f9d8ca18a90a9b0d27a62ae27581219d586cb9aeb7c695bc7b92c8)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_STATUS_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x40e11895caf89e87d4485af91bd7e72b6a6e56b94f6ea4b7edb16e869adb7fe9)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_TVL_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x4e7484f055e36257052a570831d7e3114ad145e0c8d8de63ded89925c7e17cb6)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_HASH_INTERNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x9f6ffbe6bd26bda84ec854c7775d819340fd4340bc8fa1ab853cdee0d60e7141)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_HASH_EXTERNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xcd566f7f1fd69d79df8b7e0a3e28a2b559ab3e7f081db4a0c0640de4db78de9a)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _EXECUTION_PERMIT_KEY (address vault, bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x8d47e278a5e048b636a1e1724246c4617684aff8b922d0878d0da2fb553d104e)
      mstore(32, vault)
      mstore(64, proposalId)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _VOTING_ACTIVE_STAKE_KEY (address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x2a8a915836beef625eda7be8c32e4f94152e89551893f0eae870e80cab73c496)
      mstore(32, token)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev Tracks account owner > delegatee allowance for `token`
  function _DELEGATED_ACCOUNT_ALLOWANCE_KEY (address account, address delegatee, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xf8affafdc89531391d5ba543f3f243d05d9f0325e7bebb13e50d0158dfe7ff74)
      mstore(32, account)
      mstore(64, delegatee)
      mstore(96, token)
      ret := keccak256(0, 128)
      mstore(64, backup)
      mstore(96, 0)
    }
  }

  /// @dev Tracks account owner > total delegated amount of `token`.
  function _DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY (address account, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x5f823da33b83835d30bb64c6b6539db24009aecef661452e8903ad12aee6bf8d)
      mstore(32, account)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev Tracks delegatee > total delegated amount of `token`.
  function _DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY (address delegatee, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x82dffec7bb13e333bbe061529a9dc24cdad0f5d0900f144abb0bf82b70e68452)
      mstore(32, delegatee)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _DELEGATED_VOTING_SHARES_KEY (bytes32 proposalId, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x846d3c69e4bfb41c345a501556d4ab5cfb40fa2bbfa478d2d6863adb6a612ce7)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _DELEGATED_VOTING_SIGNAL_KEY (bytes32 proposalId, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x785294304b174fede6de17c61b65e5b77d3e5ad5a71821b78dad3e2dab50d10f)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _DELEGATED_VOTING_ACTIVE_STAKE_KEY (address token, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xbe24be1148878e5dc0cfaecb52c8dd418ecc98483a44968747d43843653a5754)
      mstore(32, token)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev The last total value locked of `token` in `epoch`.
  function _STAKING_EPOCH_TVL_KEY (uint256 epoch, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x8975800e5c219c77b3263a2c64fd28d02cabe02e45f8f9463d035b3c1aae8a62)
      mstore(32, epoch)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev The last total user balance for `account` in `epoch` of `token`.
  function _STAKING_EPOCH_TUB_KEY (uint256 epoch, address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x6094318105f3510ea893d7758a4f394f18bfa74ee039be1ce39d67a0ab12524c)
      mstore(32, epoch)
      mstore(64, token)
      mstore(96, account)
      ret := keccak256(0, 128)
      mstore(64, backup)
      mstore(96, 0)
    }
  }

  function _STAKING_EPOCH_LAST_CLAIMED_KEY (address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x6094318105f3510ea893d7758a4f394f18bfa74ee039be1ce39d67a0ab12524f)
      mstore(32, token)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @notice Execution permit for <vault, proposalId> = keccak256(actions).
  function executionPermit (address vault, bytes32 proposalId) external virtual view returns (bytes32 ret) {
    uint256 key = _EXECUTION_PERMIT_KEY(vault, proposalId);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `executionPermit`.
  /// Reflects the storage slot for `executionPermit` on L1.
  function _setExecutionPermit (address vault, bytes32 proposalId, bytes32 hash) internal {
    bytes32 key = bytes32(_EXECUTION_PERMIT_KEY(vault, proposalId));
    _setStorageL1(key, uint256(hash));
  }

  /// @dev Updates the member count for the community if `account` is a new member.
  function _maybeUpdateMemberCount (bytes32 proposalId, address account) internal {
    address vault = address(_getStorage(_PROPOSAL_VAULT_KEY(proposalId)));
    bytes32 communityId = communityOfVault(vault);
    if (_getStorage(_MEMBER_OF_COMMUNITY_KEY(communityId, account)) == 0) {
      _setStorage(_MEMBER_OF_COMMUNITY_KEY(communityId, account), 1);
      _incrementStorage(_MEMBERS_TOTAL_COUNT_KEY(communityId));
    }
  }

  /// @notice The nonce of account `a`.
  function txNonces (address a) public virtual returns (uint256) {
    uint256 key = _TX_NONCE_KEY(a);
    return _sload(key);
  }

  /// @notice The token balance of `tkn` for `account. This works for ERC-20 and ERC-721.
  function getBalance (address tkn, address account) public virtual returns (uint256) {
    uint256 key = _ERC20_KEY(tkn, account);
    return _sload(key);
  }

  /// @notice Returns the owner of a ERC-721 token.
  function getErc721Owner (address tkn, uint256 b) public virtual returns (address) {
    uint256 key = _ERC721_KEY(tkn, b);
    return address(_sload(key));
  }

  /// @notice Returns the cumulative voted shares on `proposalId`.
  function getTotalVotingShares (bytes32 proposalId) public returns (uint256) {
    uint256 key = _VOTING_TOTAL_SHARE_KEY(proposalId);
    return _sload(key);
  }

  /// @notice Returns the member count for `communityId`.
  /// An account automatically becomes a member if it interacts with community vaults & proposals.
  function getTotalMemberCount (bytes32 communityId) public returns (uint256) {
    uint256 key = _MEMBERS_TOTAL_COUNT_KEY(communityId);
    return _sload(key);
  }

  /// @notice Governance Token of community.
  function tokenOfCommunity (bytes32 a) public virtual returns (address) {
    uint256 key = _TOKEN_OF_COMMUNITY_KEY(a);
    return address(_sload(key));
  }

  /// @notice Returns the `communityId` of `vault`.
  function communityOfVault (address vault) public virtual returns (bytes32) {
    uint256 key = _COMMUNITY_OF_VAULT_KEY(vault);
    return bytes32(_sload(key));
  }

  /// @notice Returns the voting status of proposal id `a`.
  function getProposalStatus (bytes32 a) public virtual returns (uint256) {
    uint256 key = _PROPOSAL_STATUS_KEY(a);
    return _sload(key);
  }

  function getTotalValueLocked (address token) public virtual returns (uint256) {
    uint256 key = _TOKEN_TVL_KEY(token);
    return _sload(key);
  }

  function getActiveVotingStake (address token, address account) public returns (uint256) {
    uint256 key = _VOTING_ACTIVE_STAKE_KEY(token, account);
    return _sload(key);
  }

  function getActiveDelegatedVotingStake (address token, address account) public returns (uint256) {
    uint256 key = _DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, account);
    return _sload(key);
  }

  /// @notice Epoch should be greater than 0.
  function getCurrentEpoch () public virtual returns (uint256) {
    return ((_getTime() - EPOCH_GENESIS()) / SECONDS_PER_EPOCH()) + 1;
  }

  /// @notice Used for testing purposes.
  function onModifyRollupStorage (address msgSender, uint256 nonce, bytes calldata data) external virtual {
    revert('OMRS1');
  }

  /// @dev Returns true on Layer 2.
  function _shouldEmitEvents () internal returns (bool ret) {
    assembly {
      ret := iszero(origin())
    }
  }

  function getLastClaimedEpoch (address token, address account) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, account));
  }

  function getHistoricTub (address token, address account, uint256 epoch) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_TUB_KEY(epoch, token, account));
  }

  function getHistoricTvl (address token, uint256 epoch) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_TVL_KEY(epoch, token));
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';

/// @notice Functionality for Habitat Communities.
// Audit-1: ok
contract HabitatCommunity is HabitatBase {
  event CommunityCreated(address indexed governanceToken, bytes32 indexed communityId);

  /// @dev Creates a Habitat Community.
  function onCreateCommunity (address msgSender, uint256 nonce, address governanceToken, bytes calldata metadata) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    require(governanceToken != address(0), 'OCC1');
    // calculate a deterministic community id
    bytes32 communityId = HabitatBase._calculateSeed(msgSender, nonce);
    // checks if the community was already created - should not be possible but anyway...
    require(HabitatBase.tokenOfCommunity(communityId) == address(0), 'OCC2');

    // community > token
    HabitatBase._setStorage(_TOKEN_OF_COMMUNITY_KEY(communityId), governanceToken);
    // msgSender is now a member of the community
    HabitatBase._setStorage(_MEMBER_OF_COMMUNITY_KEY(communityId, msgSender), 1);
    // init total members count
    HabitatBase._setStorage(_MEMBERS_TOTAL_COUNT_KEY(communityId), 1);

    if (_shouldEmitEvents()) {
      emit CommunityCreated(governanceToken, communityId);
      emit MetadataUpdated(uint256(communityId), metadata);
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';

/// @notice Functionality for Habitat Modules
// Audit-1: ok
contract HabitatModule is HabitatBase {
  event ModuleRegistered(address indexed contractAddress, bytes metadata);

  /// @dev Verifies that the bytecode at `contractAddress` can not
  /// introduce side effects on the rollup at will.
  /// The convention for Modules is that they handle a known set of callbacks
  /// without handling their own state. Thus, opcodes for state handling etc are not allowed.
  function _verifyModule (address contractAddress) internal view returns (bytes32 codehash) {
    assembly {
      function doRevert () {
        // revert with non-zero returndata to signal we are not out of gas
        revert(0, 1)
      }

      let size := extcodesize(contractAddress)
      if iszero(size) {
        doRevert()
      }

      let terminatedByOpcode := 0
      let ptr := mload(64)
      let end := add(ptr, size)
      // copy the bytecode into memory
      extcodecopy(contractAddress, ptr, 0, size)
      // and hash it
      codehash := keccak256(ptr, size)

      // verify opcodes
      for { } lt(ptr, end) { ptr := add(ptr, 1) } {
        // this is used to detect metadata from the solidity compiler
        // at the end of the bytecode
        // this most likely doesn't work if strings or other data are appended
        // at the end of the bytecode,
        // but works if the developer follows some conventions.
        let terminatedByPreviousOpcode := terminatedByOpcode
        terminatedByOpcode := 0
        let opcode := byte(0, mload(ptr))

        // PUSH opcodes
        if and(gt(opcode, 95), lt(opcode, 128)) {
          let len := sub(opcode, 95)
          ptr := add(ptr, len)
          continue
        }

        // DUPx and SWAPx
        if and(gt(opcode, 127), lt(opcode, 160)) {
          continue
        }

        // everything from 0x0 to 0x20 (inclusive)
        if lt(opcode, 0x21) {
          // in theory, opcode 0x0 (STOP) also terminates execution
          // but we will ignore this one
          continue
        }

        // another set of allowed opcodes
        switch opcode
        // CALLVALUE
        case 0x34 {}
        // CALLDATALOAD
        case 0x35 {}
        // CALLDATASIZE
        case 0x36 {}
        // CALLDATACOPY
        case 0x37 {}
        // CODESIZE
        case 0x38 {}
        // CODECOPY
        case 0x39 {}
        // POP
        case 0x50 {}
        // MLOAD
        case 0x51 {}
        // MSTORE
        case 0x52 {}
        // MSTORE8
        case 0x53 {}
        // JUMP
        case 0x56 {}
        // JUMPI
        case 0x57 {}
        // PC
        case 0x58 {}
        // MSIZE
        case 0x59 {}
        // JUMPDEST
        case 0x5b {}
        // RETURN
        case 0xf3 {
          terminatedByOpcode := 1
        }
        // REVERT
        case 0xfd {
          terminatedByOpcode := 1
        }
        // INVALID
        case 0xfe {
          terminatedByOpcode := 1
        }
        default {
          // we fall through if the previous opcode terminates execution
          if iszero(terminatedByPreviousOpcode) {
            // everything else is not allowed
            doRevert()
          }
        }
      }
    }
  }

  /// @notice Register a module to be used for Habitat Vaults (Treasuries).
  /// The bytecode at `contractAddress` must apply to some conventions, see `_verifyModule`.
  /// @param _type Must be `1`.
  /// @param contractAddress of the module.
  /// @param codeHash of the bytecode @ `contractAddress`
  function registerModule (
    uint256 _type,
    address contractAddress,
    bytes32 codeHash,
    bytes calldata /*metadata*/) external
  {
    if (_type != 1) {
      revert();
    }

    _createBlockMessage();

    // verify the contract code and returns the keccak256(bytecode) (reverts if invalid)
    require(_verifyModule(contractAddress) == codeHash && codeHash != 0);
  }

  /// @notice Layer 2 callback for blocks created with `_createBlockMessage`.
  /// Used for module registration (type = 1).
  function onCustomBlockBeacon (bytes memory data) external {
    HabitatBase._commonChecks();

    uint256 _type;
    assembly {
      _type := calldataload(68)
    }

    if (_type == 1) {
      (, address contractAddress, bytes32 codeHash, bytes memory metadata) =
        abi.decode(data, (uint256, address, bytes32, bytes));

      // same contract (address) should not be submitted twice
      require(HabitatBase._getStorage(_MODULE_HASH_KEY(contractAddress)) == 0, 'OSM1');

      HabitatBase._setStorage(_MODULE_HASH_KEY(contractAddress), codeHash);

      if (_shouldEmitEvents()) {
        emit ModuleRegistered(contractAddress, metadata);
      }
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';
import './HabitatWallet.sol';

/// @notice Takes care of transferring value to a operator minus a few that goes to the staking pool.
// Audit-1: ok
contract HabitatStakingPool is HabitatBase, HabitatWallet {
  event ClaimedStakingReward(address indexed account, address indexed token, uint256 indexed epoch, uint256 amount);

  /// @dev Like `_getStorage` but with some additional conditions.
  function _specialLoad (uint256 oldValue, uint256 key) internal returns (uint256) {
    uint256 newValue = HabitatBase._getStorage(key);

    // 0 means no record / no change
    if (newValue == 0) {
      return oldValue;
    }

    // -1 means drained (no balance)
    if (newValue == uint256(-1)) {
      return 0;
    }

    // default to newValue
    return newValue;
  }

  /// @notice Claims staking rewards for `epoch`.
  function onClaimStakingReward (address msgSender, uint256 nonce, address token, uint256 sinceEpoch) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // we ignore untilEpoch wrapping around because this is not a practical problem
    uint256 untilEpoch = sinceEpoch + 10;
    {
      // assuming getCurrentEpoch never returns 0
      uint256 max = getCurrentEpoch();
      // clamp
      if (untilEpoch > max) {
        untilEpoch = max;
      }
    }
    // checks if the account can claim rewards, starting from `sinceEpoch`
    require(
      sinceEpoch != 0
      && untilEpoch > sinceEpoch
      && sinceEpoch > HabitatBase._getStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, msgSender)),
      'OCSR1'
    );

    // update last claimed epoch
    HabitatBase._setStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, msgSender), untilEpoch - 1);

    // this is the total user balance for `token` in any given epoch
    uint256 historicTotalUserBalance;

    for (uint256 epoch = sinceEpoch; epoch < untilEpoch; epoch++) {
      uint256 reward = 0;
      // special pool address
      address pool = address(epoch);
      uint256 poolBalance = getBalance(token, pool);
      // total value locked after the end of each epoch.
      // tvl being zero should imply that `historicPoolBalance` must also be zero
      uint256 historicTVL = HabitatBase._getStorage(_STAKING_EPOCH_TVL_KEY(epoch, token));
      // returns the last 'known' user balance up to `epoch`
      historicTotalUserBalance = _specialLoad(historicTotalUserBalance, _STAKING_EPOCH_TUB_KEY(epoch, token, msgSender));

      if (
        poolBalance != 0
        && historicTVL != 0
        && historicTotalUserBalance != 0
        // `historicTotalUserBalance` should always be less than `historicTVL`
        && historicTotalUserBalance < historicTVL
      ) {
        // deduct pool balance from tvl
        // assuming `historicPoolBalance` must be less than `historicTVL`
        uint256 historicPoolBalance = HabitatBase._getStorage(_STAKING_EPOCH_TUB_KEY(epoch, token, pool));
        uint256 tvl = historicTVL - historicPoolBalance;

        reward = historicPoolBalance / (tvl / historicTotalUserBalance);

        if (reward != 0) {
          // this can happen
          if (reward > poolBalance) {
            reward = poolBalance;
          }
          _transferToken(token, pool, msgSender, reward);
        }
      }

      if (_shouldEmitEvents()) {
        emit ClaimedStakingReward(msgSender, token, epoch, reward);
      }
    }

    // store the tub for the user but do not overwrite if there is already
    // a non-zero entry
    uint256 key = _STAKING_EPOCH_TUB_KEY(untilEpoch, token, msgSender);
    if (HabitatBase._getStorage(key) == 0) {
      _setStorageInfinityIfZero(key, historicTotalUserBalance);
    }
  }

  /// @notice Transfers funds to a (trusted) operator.
  /// A fraction `STAKING_POOL_FEE_DIVISOR` of the funds goes to the staking pool.
  function onTributeForOperator (
    address msgSender,
    uint256 nonce,
    address operator,
    address token,
    uint256 amount
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // fee can be zero
    uint256 fee = amount / STAKING_POOL_FEE_DIVISOR();
    // epoch is greater than zero
    uint256 currentEpoch = getCurrentEpoch();
    address pool = address(currentEpoch);
    // zero-value transfers are not a problem
    _transferToken(token, msgSender, pool, fee);
    _transferToken(token, msgSender, operator, amount - fee);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatV1Challenge.sol';
import './HabitatBase.sol';
import './HabitatAccount.sol';
import './HabitatWallet.sol';
import './HabitatCommunity.sol';
import './HabitatVault.sol';
import './HabitatVoting.sol';
import './HabitatModule.sol';
import './HabitatStakingPool.sol';

/// @notice Composition of the full Habitat Rollup contracts (v1)
// Audit-1: ok
contract HabitatV1 is
  HabitatBase,
  HabitatAccount,
  HabitatWallet,
  HabitatCommunity,
  HabitatVault,
  HabitatVoting,
  HabitatModule,
  HabitatStakingPool,
  HabitatV1Challenge
{
  /// @inheritdoc NutBerryCore
  function MAX_BLOCK_SIZE () public view override returns (uint24) {
    return 31744;
  }

  /// @inheritdoc NutBerryCore
  function INSPECTION_PERIOD () public view virtual override returns (uint16) {
    // in blocks, (3600 * 24 * 7) seconds / 14s per block
    return 43200;
  }

  /// @inheritdoc NutBerryCore
  function INSPECTION_PERIOD_MULTIPLIER () public view override returns (uint256) {
    return 3;
  }

  /// @inheritdoc NutBerryCore
  function _CHALLENGE_IMPLEMENTATION_ADDRESS () internal override returns (address addr) {
    assembly {
      // loads the target contract adddress from the proxy slot
      addr := sload(not(0))
    }
  }

  /// @inheritdoc UpgradableRollup
  function ROLLUP_MANAGER () public virtual override pure returns (address) {
    // Habitat multisig - will be replaced by the community governance proxy in the future
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  /// @inheritdoc HabitatBase
  function STAKING_POOL_FEE_DIVISOR () public virtual override pure returns (uint256) {
    // 1%
    return 100;
  }

  /// @inheritdoc HabitatBase
  function EPOCH_GENESIS () public virtual override pure returns (uint256) {
    // Date.parse('2021-06-23') / 1000
    return 1624406400;
  }

  /// @inheritdoc HabitatBase
  function SECONDS_PER_EPOCH () public virtual override pure returns (uint256) {
    // 7 days
    return 604800;
  }

  /// @notice Used for fixing rollup storage due to logic bugs.
  function onModifyRollupStorage (address msgSender, uint256 nonce, bytes calldata data) external virtual override {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    {
      // MODIFIY_ROLLUP_STORAGE_ERRATA_KEY
      uint256 storageKey = 0xa7be6244e780b8d3f5c3e14f6a3ffd87b6bbc48b7b9cb71a2e521495d8905ecc;
      uint256 currentErrata = HabitatBase._getStorage(storageKey);
      require(currentErrata == 0, 'OMRS1');
      HabitatBase._setStorage(storageKey, 1);
    }

    {
      // #1 - depositing from L1 to a vault on L2 resulted in incorrectly
      // increasing TVL
      // This happened 2x with HBT in epoch #2.
      uint256 epoch = 2;
      address token = 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
      // cumulative amount of HBT to remove from TVL
      uint256 tvlToRemove = 16800100000000000;

      HabitatBase._decrementStorage(_TOKEN_TVL_KEY(token), tvlToRemove);
      HabitatBase._setStorage(
        _STAKING_EPOCH_TVL_KEY(epoch, token),
        HabitatBase._getStorage(_TOKEN_TVL_KEY(token))
      );
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

/// @dev Autogenerated file. Do not edit manually.
contract HabitatV1Challenge {
  /// @dev Challenge the solution or just verify the next pending block directly.
  /// calldata layout:
  /// < 4 bytes function sig >
  /// < 32 bytes challenge offset >
  /// < 32 bytes address of challenge handler - contract (self) >
  /// < 32 bytes size of block >
  /// < 32 bytes number of challenge rounds >
  /// < arbitrary witness data >
  /// < data of block >
  function onChallenge () external returns (uint256) {
    // all power the core protocol
    require(msg.sender == address(this));

    assembly {
      
function _parseTransaction (o) -> offset, success, inOffset, inSize {
  // zero memory
  calldatacopy(0, calldatasize(), msize())
  offset := o

  let firstByte := byte(0, calldataload(offset))
  let v := add(and(firstByte, 1), 27)
  let primaryType := shr(1, firstByte)
  offset := add(offset, 1)
  let r := calldataload(offset)
  offset := add(offset, 32)
  let s := calldataload(offset)
  offset := add(offset, 32)

  switch primaryType

// start of TransferToken
// typeHash: 0xf121759935d81b9588e8434983e70b870ab10987a39b454ac893e1480f028e46
// function: onTransferToken(address,uint256,address,address,uint256)
case 0 {
  let headSize := 160
  let typeLen := 0
  let txPtr := 384
  let endOfSlot := add(txPtr, 160)

  txPtr := 416
  // typeHash of TransferToken
  mstore(0, 0xf121759935d81b9588e8434983e70b870ab10987a39b454ac893e1480f028e46)
  // uint256 TransferToken.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address TransferToken.token
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address TransferToken.to
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 TransferToken.value
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(128, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 160)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(352, 0x11d4aec1)
  mstore(384, mload(128))

  inOffset := 380
  inSize := sub(endOfSlot, 380)
}
// end of TransferToken

// start of ClaimUsername
// typeHash: 0x8b505a1c00897e3b1949f8e114b8f1a4cdeed6d6a26926931f57f885f33f6cfa
// function: onClaimUsername(address,uint256,bytes32)
case 1 {
  let headSize := 96
  let typeLen := 0
  let txPtr := 256
  let endOfSlot := add(txPtr, 96)

  txPtr := 288
  // typeHash of ClaimUsername
  mstore(0, 0x8b505a1c00897e3b1949f8e114b8f1a4cdeed6d6a26926931f57f885f33f6cfa)
  // uint256 ClaimUsername.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes32 ClaimUsername.shortString
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 96)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(224, 0x0827bab8)
  mstore(256, mload(128))

  inOffset := 252
  inSize := sub(endOfSlot, 252)
}
// end of ClaimUsername

// start of CreateCommunity
// typeHash: 0x4b8e81699d7dc349aa2eca5d6740c23aff4244d26288627f4ca3be7d236f5127
// function: onCreateCommunity(address,uint256,address,bytes)
case 2 {
  let headSize := 128
  let typeLen := 0
  let txPtr := 320
  let endOfSlot := add(txPtr, 128)

  txPtr := 352
  // typeHash of CreateCommunity
  mstore(0, 0x4b8e81699d7dc349aa2eca5d6740c23aff4244d26288627f4ca3be7d236f5127)
  // uint256 CreateCommunity.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address CreateCommunity.governanceToken
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes CreateCommunity.metadata
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(96, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // typeHash
  let structHash := keccak256(0, 128)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(288, 0x5b292e29)
  mstore(320, mload(128))

  inOffset := 316
  inSize := sub(endOfSlot, 316)
}
// end of CreateCommunity

// start of CreateVault
// typeHash: 0xd039a4c4cd9e9890710392eef9936bf5d690ec47246e5d6f4693c764d6b62635
// function: onCreateVault(address,uint256,bytes32,address,bytes)
case 3 {
  let headSize := 160
  let typeLen := 0
  let txPtr := 384
  let endOfSlot := add(txPtr, 160)

  txPtr := 416
  // typeHash of CreateVault
  mstore(0, 0xd039a4c4cd9e9890710392eef9936bf5d690ec47246e5d6f4693c764d6b62635)
  // uint256 CreateVault.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes32 CreateVault.communityId
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address CreateVault.condition
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes CreateVault.metadata
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(128, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // typeHash
  let structHash := keccak256(0, 160)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(352, 0x9617e0c5)
  mstore(384, mload(128))

  inOffset := 380
  inSize := sub(endOfSlot, 380)
}
// end of CreateVault

// start of CreateProposal
// typeHash: 0x4d8a9f544d08772d597445c015580bcc93a38fd87bcf6be01f7b542ccdb97814
// function: onCreateProposal(address,uint256,uint256,address,bytes,bytes,bytes)
case 4 {
  let headSize := 224
  let typeLen := 0
  let txPtr := 512
  let endOfSlot := add(txPtr, 224)

  txPtr := 544
  // typeHash of CreateProposal
  mstore(0, 0x4d8a9f544d08772d597445c015580bcc93a38fd87bcf6be01f7b542ccdb97814)
  // uint256 CreateProposal.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 CreateProposal.startDate
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address CreateProposal.vault
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes CreateProposal.internalActions
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(128, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // bytes CreateProposal.externalActions
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(160, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // bytes CreateProposal.metadata
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(192, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // typeHash
  let structHash := keccak256(0, 224)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(480, 0x9cc39bbe)
  mstore(512, mload(128))

  inOffset := 508
  inSize := sub(endOfSlot, 508)
}
// end of CreateProposal

// start of VoteOnProposal
// typeHash: 0xeedce560579f8160e8bbb71ad5823fb1098eee0d1116be92232ee87ab1bce294
// function: onVoteOnProposal(address,uint256,bytes32,uint256,address,uint8)
case 5 {
  let headSize := 192
  let typeLen := 0
  let txPtr := 448
  let endOfSlot := add(txPtr, 192)

  txPtr := 480
  // typeHash of VoteOnProposal
  mstore(0, 0xeedce560579f8160e8bbb71ad5823fb1098eee0d1116be92232ee87ab1bce294)
  // uint256 VoteOnProposal.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes32 VoteOnProposal.proposalId
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 VoteOnProposal.shares
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address VoteOnProposal.delegatedFor
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(128, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint8 VoteOnProposal.signalStrength
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(160, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 192)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(416, 0xd87eafef)
  mstore(448, mload(128))

  inOffset := 444
  inSize := sub(endOfSlot, 444)
}
// end of VoteOnProposal

// start of ProcessProposal
// typeHash: 0xb4da110edbcfa262bdf7849c0e02e03ed15ced328922eca5a0bc1c547451b4af
// function: onProcessProposal(address,uint256,bytes32,bytes,bytes)
case 6 {
  let headSize := 160
  let typeLen := 0
  let txPtr := 384
  let endOfSlot := add(txPtr, 160)

  txPtr := 416
  // typeHash of ProcessProposal
  mstore(0, 0xb4da110edbcfa262bdf7849c0e02e03ed15ced328922eca5a0bc1c547451b4af)
  // uint256 ProcessProposal.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes32 ProcessProposal.proposalId
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes ProcessProposal.internalActions
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(96, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // bytes ProcessProposal.externalActions
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(128, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // typeHash
  let structHash := keccak256(0, 160)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(352, 0x36b54032)
  mstore(384, mload(128))

  inOffset := 380
  inSize := sub(endOfSlot, 380)
}
// end of ProcessProposal

// start of TributeForOperator
// typeHash: 0x1d7f2e50c4a73ada77cc1796f78f259a43e44d6d99adaf69a6628ef42c527df7
// function: onTributeForOperator(address,uint256,address,address,uint256)
case 7 {
  let headSize := 160
  let typeLen := 0
  let txPtr := 384
  let endOfSlot := add(txPtr, 160)

  txPtr := 416
  // typeHash of TributeForOperator
  mstore(0, 0x1d7f2e50c4a73ada77cc1796f78f259a43e44d6d99adaf69a6628ef42c527df7)
  // uint256 TributeForOperator.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address TributeForOperator.operator
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address TributeForOperator.token
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 TributeForOperator.amount
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(128, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 160)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(352, 0x24fa29ea)
  mstore(384, mload(128))

  inOffset := 380
  inSize := sub(endOfSlot, 380)
}
// end of TributeForOperator

// start of DelegateAmount
// typeHash: 0x7595f378ac19fee39d9d6a79a8240d32afae43c5943289e491976d85c9e9ad54
// function: onDelegateAmount(address,uint256,address,address,uint256)
case 8 {
  let headSize := 160
  let typeLen := 0
  let txPtr := 384
  let endOfSlot := add(txPtr, 160)

  txPtr := 416
  // typeHash of DelegateAmount
  mstore(0, 0x7595f378ac19fee39d9d6a79a8240d32afae43c5943289e491976d85c9e9ad54)
  // uint256 DelegateAmount.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address DelegateAmount.delegatee
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address DelegateAmount.token
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 DelegateAmount.value
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(128, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 160)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(352, 0x1b5e17db)
  mstore(384, mload(128))

  inOffset := 380
  inSize := sub(endOfSlot, 380)
}
// end of DelegateAmount

// start of ClaimStakingReward
// typeHash: 0x56d7b9415a7ab01a4e256d5e8a8a100fcf839c82096289e6a835115c704aee67
// function: onClaimStakingReward(address,uint256,address,uint256)
case 9 {
  let headSize := 128
  let typeLen := 0
  let txPtr := 320
  let endOfSlot := add(txPtr, 128)

  txPtr := 352
  // typeHash of ClaimStakingReward
  mstore(0, 0x56d7b9415a7ab01a4e256d5e8a8a100fcf839c82096289e6a835115c704aee67)
  // uint256 ClaimStakingReward.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // address ClaimStakingReward.token
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(64, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // uint256 ClaimStakingReward.sinceEpoch
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(96, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // typeHash
  let structHash := keccak256(0, 128)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(288, 0x8e7700c0)
  mstore(320, mload(128))

  inOffset := 316
  inSize := sub(endOfSlot, 316)
}
// end of ClaimStakingReward

// start of ModifyRollupStorage
// typeHash: 0x31a8f1b3e855fde3871d440618da073d0504133dc34db1896de6774ed15abb70
// function: onModifyRollupStorage(address,uint256,bytes)
case 10 {
  let headSize := 96
  let typeLen := 0
  let txPtr := 256
  let endOfSlot := add(txPtr, 96)

  txPtr := 288
  // typeHash of ModifyRollupStorage
  mstore(0, 0x31a8f1b3e855fde3871d440618da073d0504133dc34db1896de6774ed15abb70)
  // uint256 ModifyRollupStorage.nonce
  typeLen := byte(0, calldataload(offset))
  offset := add(offset, 1)
  calldatacopy(add(txPtr, sub(32, typeLen)), offset, typeLen)
  mstore(32, mload(txPtr))
  offset := add(offset, typeLen)
  txPtr := add(txPtr, 32)

  // bytes ModifyRollupStorage.data
  typeLen := shr(240, calldataload(offset))
  offset := add(offset, 2)
  mstore(txPtr, headSize)
  headSize := add(headSize, add( 32, mul( 32, div( add(typeLen, 31), 32 ) ) ))
  txPtr := add(txPtr, 32)
  mstore(endOfSlot, typeLen)
  endOfSlot := add(endOfSlot, 32)
  calldatacopy(endOfSlot, offset, typeLen)
  mstore(64, keccak256(endOfSlot, typeLen))
  endOfSlot := add(endOfSlot, mul( 32, div( add(typeLen, 31), 32 ) ))
  offset := add(offset, typeLen)

  // typeHash
  let structHash := keccak256(0, 96)
  // prefix
  mstore(0, 0x1901000000000000000000000000000000000000000000000000000000000000)
  // DOMAIN struct hash
  mstore(2, 0x912f8ef55fd9ffcdd4f9ea4d504976c90bd78c1f95a3ca09ddc4c95af6622f46)
  // transactionStructHash
  mstore(34, structHash)
  mstore(0, keccak256(0, 66))
  mstore(32, v)
  mstore(64, r)
  mstore(96, s)
  success := staticcall(gas(), 1, 0, 128, 128, 32)
  // functionSig
  mstore(224, 0x10ea8892)
  mstore(256, mload(128))

  inOffset := 252
  inSize := sub(endOfSlot, 252)
}
// end of ModifyRollupStorage
default { }
}


      
// verifies a proof
function verifyUniform (proofOffset, len, key, root) -> valid, inTree, value {
  let _k := 0
  let _v := 0
  let ret := 0

  if len {
    // if # of proof elements are greather than 0 and less than 2, revert
    if lt(len, 2) {
      revert(0, 0)
    }

    _k := calldataload(proofOffset)
    proofOffset := add(proofOffset, 32)
    _v := calldataload(proofOffset)
    proofOffset := add(proofOffset, 32)

    if _v {
      // leafHash
      // left, right = key, value
      inTree := eq(key, _k)
      
  // hash leaf
  mstore(0, _k)
  mstore(32, _v)
  mstore(64, 1)
  ret := keccak256(0, 96)
  // end of hash leaf

    }
  }

  // it is not used anyway if it underflows (see loop)
  let depth := sub(len, 2)

  for { let i := 2 } lt(i, len) { i:= add(i, 1) } {
    depth := sub(depth, 1)
    let bitmask := shl(depth, 1)
    let goLeft := and(key, bitmask)
    let next := calldataload(proofOffset)
    proofOffset := add(proofOffset, 32)

    
  // hash branch
  switch goLeft
  case 0 {
    mstore(0, next)
    mstore(32, ret)
  }
  default {
    mstore(0, ret)
    mstore(32, next)
  }
  ret := keccak256(0, 64)
  // end of hash branch

  }

  valid := eq(ret, root)
  if iszero(valid) {
    inTree := 0
  }
  if inTree {
    value := _v
  }
}

      
function updateTree (ptr, len, key, newValue) -> ret {
  let _k := 0
  let _v := 0

  if newValue {
    // insert or update
    // hash leaf
    
  // hash leaf
  mstore(0, key)
  mstore(32, newValue)
  mstore(64, 1)
  ret := keccak256(0, 96)
  // end of hash leaf

  }

  if len {
    if lt(len, 2) {
      // invalid proof
      revert(0, 0)
    }

    _k := calldataload(ptr)
    ptr := add(ptr, 32)
    _v := calldataload(ptr)
    ptr := add(ptr, 32)

    // _v != 0 && key != _k
    if and(iszero(iszero(_v)), iszero(eq(key, _k))) {
      // Update and create a new branch.
      // Compare against the key of the other leaf and loop until diverge.
      // Then create a new branch(es).

      // minus [_k, _v]
      let depth := sub(len, 2)
      for {} true {} {
        let bitmask := shl(depth, 1)
        let goLeft := and(key, bitmask)
        let otherLeft := and(_k, bitmask)

        if eq(goLeft, otherLeft) {
          // key and _k are still on the same path, go deeper
          depth := add(depth, 1)
          continue
        }

        let other
        
  // hash leaf
  mstore(0, _k)
  mstore(32, _v)
  mstore(64, 1)
  other := keccak256(0, 96)
  // end of hash leaf

        
  // hash branch
  switch goLeft
  case 0 {
    mstore(0, other)
    mstore(32, ret)
  }
  default {
    mstore(0, ret)
    mstore(32, other)
  }
  ret := keccak256(0, 64)
  // end of hash branch

        break
      }

      // now, walk back and hash each new branch with a zero-neighbor.
      let odepth := sub(len, 2)
      for {} iszero(eq(depth, odepth)) {} {
        depth := sub(depth, 1)
        let bitmask := shl(depth, 1)
        let goLeft := and(key, bitmask)

        
  // hash branch
  switch goLeft
  case 0 {
    mstore(0, 0)
    mstore(32, ret)
  }
  default {
    mstore(0, ret)
    mstore(32, 0)
  }
  ret := keccak256(0, 64)
  // end of hash branch

      }
    }
  }

  // use the supplied proofs and walk back to the root (TM)
  // minus [_k, _v]
  let depth := sub(len, 2)
  for { let i := 2 } lt(i, len) {} {
    depth := sub(depth, 1)

    let bitmask := shl(depth, 1)
    let goLeft := and(key, bitmask)
    let next := calldataload(ptr)
    ptr := add(ptr, 32)
    i := add(i, 1)

    
  // hash branch
  switch goLeft
  case 0 {
    mstore(0, next)
    mstore(32, ret)
  }
  default {
    mstore(0, ret)
    mstore(32, next)
  }
  ret := keccak256(0, 64)
  // end of hash branch

  }

  // ret contains new root
}


      // pre & post transaction verification
      function verifyTransition (blockTimestamp, __rootHash, __witnessOffset, inOffset, inSize) -> witnessOffset, rootHash {
        // setup return value
        rootHash := __rootHash
        witnessOffset := __witnessOffset

        // number of storage reads
        let nPairs := calldataload(witnessOffset)
        witnessOffset := add(witnessOffset, 32)

        // append data to the end of the transaction
        let memPtr := add(inOffset, inSize)
        mstore(memPtr, blockTimestamp)
        memPtr := add(memPtr, 32)

        for { let i := 0 } lt(i, nPairs) { i := add(i, 1) } {
          let key := calldataload(witnessOffset)
          witnessOffset := add(witnessOffset, 32)
          let nProofElements := calldataload(witnessOffset)
          witnessOffset := add(witnessOffset, 32)

          // verify key, value
          let valid, inTree, value := verifyUniform(witnessOffset, nProofElements, key, rootHash)
          if iszero(valid) {
            // invalid proof
            revert(0, 0)
          }
          witnessOffset := add(witnessOffset, mul(nProofElements, 32))

          // only store the value if the key is in the tree.
          // Consumers must take care of not introducing key collisions for L1 storage vs L2 storage.
          if inTree {
            sstore(key, value)
          }

          // store key (for calldata)
          mstore(memPtr, key)
          memPtr := add(memPtr, 32)
        }
        // write number of storage (read access) keys
        mstore(memPtr, nPairs)
        memPtr := add(memPtr, 32)

        {
          // make a copy
          // the current position of witnessOffset is the starting point in verifyPostTransition
          let witnessOffsetCopy := witnessOffset
          // storage writes (access)
          nPairs := calldataload(witnessOffsetCopy)
          if gt(nPairs, 0xff) {
            // too large
            revert(0, 0)
          }
          witnessOffsetCopy := add(witnessOffsetCopy, 32)

          let bitmap := 0
          for { let i := 0 } lt(i, nPairs) { i := add(i, 1) } {
            bitmap := or(bitmap, shl(i, 1))

            let key := calldataload(witnessOffsetCopy)
            witnessOffsetCopy := add(witnessOffsetCopy, 32)
            let nProofElements := calldataload(witnessOffsetCopy)
            witnessOffsetCopy := add(witnessOffsetCopy, 32)
            witnessOffsetCopy := add(witnessOffsetCopy, mul(nProofElements, 32))

            // only remember the keys, the proof will be verified later
            mstore(memPtr, key)
            memPtr := add(memPtr, 32)
          }
          // write number of storage (writes) keys
          mstore(memPtr, nPairs)
          memPtr := add(memPtr, 32)

          // SPECIAL_STORAGE_SLOT - store storage write access bitmap
          sstore(0xabcd, bitmap)
          // help the compiler :ouch
          pop(bitmap)
        }

        // now, start calling the function
        // if returndatasize > 0
        //   success; even if reverted
        // else
        //   - out of gas?
        //   - implementation error?
        //   - something else?
        //
        // We can't proof if a transaction failed because of an implementation error or because it is out of gas
        // Well, technically we can enforce gas limits but div by zero, jump to invalid() or something else will
        // lead to a runtime exception and burn all gas (meh -.-).
        //
        // In this case:
        // - Revert
        // The core logic has to deal with it.
        // For example, the block could be skipped and marked as invalid partly or as a whole
        // if it's not possible to proceed the challenge for some reason.
        // Otherwise, without this functionality, it would be possible that we spin here forever.
        //

        // calldataload = address of challenge contract
        let success := delegatecall(gas(), calldataload(36), inOffset, sub(memPtr, inOffset), 0, 0)
        success := or(success, returndatasize())
        switch success
        case 0 {
          revert(0, 0)
        }
        default {
          // verifyPostTransition, verification after executing a transaction

          // SPECIAL_STORAGE_SLOT - all bits must be unset
          if sload(0xabcd) {
            revert(0, 0)
          }

          // validate & clean write accesss
          nPairs := calldataload(witnessOffset)
          witnessOffset := add(witnessOffset, 32)

          for { let i := 0 } lt(i, nPairs) { i := add(i, 1) } {
            let key := calldataload(witnessOffset)
            witnessOffset := add(witnessOffset, 32)
            let nProofElements := calldataload(witnessOffset)
            witnessOffset := add(witnessOffset, 32)

            // verify proof
            let valid, inTree, value := verifyUniform(witnessOffset, nProofElements, key, rootHash)
            if iszero(valid) {
              // invalid proof
              revert(0, 0)
            }
            // calculate new state root
            rootHash := updateTree(witnessOffset, nProofElements, key, sload(key))
            // reset storage slot
            sstore(key, 0)
            witnessOffset := add(witnessOffset, mul(nProofElements, 32))
          }
        }
        // end of verifyTransition
      }

      // load the stateRoot from storage
      let rootHash := sload(0xd27f023774f5a743d69cfc4b80b1efe4be7912753677c20f45ee5464160b7d24)
      // calldatasize - blockSize
      let startOfBlock := sub(calldatasize(), calldataload(68))
      // load timestamp for this block
      let blockTimestamp := calldataload(add(startOfBlock, 64))
      // start of arbitrary witness data in calldata
      let witnessOffset := 132
      // last block offset (byte offset for block)
      let challengeOffset := calldataload(4)
      if iszero(challengeOffset) {
        // add size of block header
        challengeOffset := add(challengeOffset, 96)
      }
      // fix the calldata offset
      challengeOffset := add(challengeOffset, startOfBlock)

      // load blockType
      // 1 = Deposit
      // 2 = arbitrary submitted data - signed transactions
      // 3 = custom message
      switch calldataload(add(startOfBlock, 32))
      case 1 {
        // function onDeposit (address owner, address token, uint256 value, uint256 tokenType) external
        mstore(128, 0x62731ff1)
        // ^ assuming this will not be overwritten in the loop below

        // iterate over the block data
        let rounds := calldataload(100)
        for { } lt(challengeOffset, calldatasize()) { } {
          if iszero(rounds) {
            break
          }
          rounds := sub(rounds, 1)

          // owner
          mstore(160, shr(96, calldataload(challengeOffset)))
          challengeOffset := add(challengeOffset, 20)

          // token
          mstore(192, shr(96, calldataload(challengeOffset)))
          challengeOffset := add(challengeOffset, 20)

          // value
          mstore(224, calldataload(challengeOffset))
          challengeOffset := add(challengeOffset, 32)

          // tokenType
          mstore(256, calldataload(challengeOffset))
          challengeOffset := add(challengeOffset, 32)

          // setup & call
          witnessOffset, rootHash := verifyTransition(blockTimestamp, rootHash, witnessOffset, 156, 132)
        }
      }
      case 2 {
        // iterate over the block data and keep track of the number of rounds to do
        let rounds := calldataload(100)
        for { } lt(challengeOffset, calldatasize()) { } {
          if iszero(rounds) {
            break
          }
          rounds := sub(rounds, 1)

          let success, inOffset, inSize
          challengeOffset, success, inOffset, inSize := _parseTransaction(challengeOffset)

          switch success
          case 0 {
            // invalid tx, ignore and skip
            success := 1
            // skip [ 32 bytes readWitnessLength, 32 bytes writeWitnessLength ]
            witnessOffset := add(witnessOffset, 64)
          }
          default {
            // setup & call
            witnessOffset, rootHash := verifyTransition(blockTimestamp, rootHash, witnessOffset, inOffset, inSize)
          }
        }
        // end of blockType = 2
      }
      case 3 {
        // onCustomBlockBeacon(bytes)
        mstore(128, 0xa891fba3)
        // abi head size
        mstore(160, 32)
        // whole block data, minus header
        let sizeOfData := sub(calldatasize(), challengeOffset)
        // store length
        mstore(192, sizeOfData)
        // copy data into memory
        calldatacopy(224, challengeOffset, sizeOfData)

        // setup & call
        witnessOffset, rootHash := verifyTransition(blockTimestamp, rootHash, witnessOffset, 156, add(sizeOfData, 68))
        // done
        challengeOffset := calldatasize()
      }
      default {
        // nothing todo - finish this block
        challengeOffset := calldatasize()
      }

      // save stateRoot
      sstore(0xd27f023774f5a743d69cfc4b80b1efe4be7912753677c20f45ee5464160b7d24, rootHash)

      // return challengeOffset.
      // if >= blockSize , then this block is done
      mstore(0, sub(challengeOffset, startOfBlock))
      return(0, 32)
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';

/// @notice A Vault holds assets with a custom (contract) condition to unlock them.
// Audit-1: ok
contract HabitatVault is HabitatBase {
  event VaultCreated(bytes32 indexed communityId, address indexed condition, address indexed vaultAddress);

  /// @dev Lookup condition (module) for `vault`, reverts on error.
  /// @return address if the contract on L1
  function _getVaultCondition (address vault) internal returns (address) {
    address contractAddress = address(HabitatBase._getStorage(_VAULT_CONDITION_KEY(vault)));
    uint256 codeHash = HabitatBase._getStorage(_MODULE_HASH_KEY(contractAddress));

    require(contractAddress != address(0) && codeHash != 0, 'GVC1');

    return contractAddress;
  }

  /// @dev Creates a Habitat Vault for a Community.
  function onCreateVault (
    address msgSender,
    uint256 nonce,
    bytes32 communityId,
    address condition,
    bytes calldata metadata
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // checks if the condition exists
    require(HabitatBase._getStorage(_MODULE_HASH_KEY(condition)) != 0, 'OCV1');
    // checks if the community exists
    require(tokenOfCommunity(communityId) != address(0), 'OCV2');
    // generate deterministic address
    address vaultAddress = address(bytes20(HabitatBase._calculateSeed(msgSender, nonce)));
    // checks if the vault already exists
    require(HabitatBase.communityOfVault(vaultAddress) == bytes32(0), 'OCV3');
    // save
    HabitatBase._setStorage(_COMMUNITY_OF_VAULT_KEY(vaultAddress), communityId);
    HabitatBase._setStorage(_VAULT_CONDITION_KEY(vaultAddress), condition);

    if (_shouldEmitEvents()) {
      emit VaultCreated(communityId, condition, vaultAddress);
      emit MetadataUpdated(uint256(vaultAddress), metadata);
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';
import './HabitatWallet.sol';
import './HabitatVault.sol';
import './IModule.sol';

/// @notice Voting Functionality.
// Audit-1: ok
contract HabitatVoting is HabitatBase, HabitatWallet, HabitatVault {
  event ProposalCreated(address indexed vault, bytes32 indexed proposalId, uint256 startDate);
  event VotedOnProposal(address indexed account, bytes32 indexed proposalId, uint8 signalStrength, uint256 shares);
  event DelegateeVotedOnProposal(address indexed account, bytes32 indexed proposalId, uint8 signalStrength, uint256 shares);
  event ProposalProcessed(bytes32 indexed proposalId, uint256 indexed votingStatus);

  /// @dev Validates if `timestamp` is inside a valid range.
  /// `timestamp` should not be under/over now +- `_PROPOSAL_DELAY`.
  function _validateTimestamp (uint256 timestamp) internal virtual {
    uint256 time = _getTime();
    uint256 delay = _PROPOSAL_DELAY();

    if (time > timestamp) {
      require(time - timestamp < delay, 'VT1');
    } else {
      require(timestamp - time < delay, 'VT2');
    }
  }

  /// @dev Parses and executes `internalActions`.
  /// TODO Only `TRANSFER_TOKEN` is currently implemented
  function _executeInternalActions (address vaultAddress, bytes calldata internalActions) internal {
    // Types, related to actionable proposal items on L2.
    // L1 has no such items and only provides an array of [<address><calldata] for on-chain execution.
    // enum L2ProposalActions {
    //  RESERVED,
    //  TRANSFER_TOKEN,
    //  UPDATE_COMMUNITY_METADATA
    // }

    // assuming that `length` can never be > 2^16
    uint256 ptr;
    uint256 end;
    assembly {
      let len := internalActions.length
      ptr := internalActions.offset
      end := add(ptr, len)
    }

    while (ptr < end) {
      uint256 actionType;

      assembly {
        actionType := byte(0, calldataload(ptr))
        ptr := add(ptr, 1)
      }

      // TRANSFER_TOKEN
      if (actionType == 1) {
        address token;
        address receiver;
        uint256 value;
        assembly {
          token := shr(96, calldataload(ptr))
          ptr := add(ptr, 20)
          receiver := shr(96, calldataload(ptr))
          ptr := add(ptr, 20)
          value := calldataload(ptr)
          ptr := add(ptr, 32)
        }
        _transferToken(token, vaultAddress, receiver, value);
        continue;
      }

      revert('EIA1');
    }

    // revert if out of bounds read(s) happened
    if (ptr > end) {
      revert('EIA2');
    }
  }

  /// @dev Invokes IModule.onCreateProposal(...) on `vault`
  function _callCreateProposal (
    address vault,
    address proposer,
    uint256 startDate,
    bytes memory internalActions,
    bytes memory externalActions
  ) internal {
    bytes32 communityId = HabitatBase.communityOfVault(vault);
    address governanceToken = HabitatBase.tokenOfCommunity(communityId);

    // encoding all all the statistics
    bytes memory _calldata = abi.encodeWithSelector(
      0x5e79ee45,
      communityId,
      HabitatBase.getTotalMemberCount(communityId),
      getTotalValueLocked(governanceToken),
      proposer,
      getBalance(governanceToken, proposer),
      startDate,
      internalActions,
      externalActions
    );
    uint256 MAX_GAS = 90000;
    address vaultCondition = _getVaultCondition(vault);
    assembly {
      // check if we have enough gas to spend (relevant in challenges)
      if lt(gas(), MAX_GAS) {
        // do a silent revert to signal the challenge routine that this is an exception
        revert(0, 0)
      }
      let success := staticcall(MAX_GAS, vaultCondition, add(_calldata, 32), mload(_calldata), 0, 0)
      // revert and forward any returndata
      if iszero(success) {
        // propagate any revert messages
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /// @notice Creates a proposal belonging to `vault`.
  /// @param startDate Should be within a reasonable range. See `_PROPOSAL_DELAY`
  /// @param internalActions includes L2 specific actions if this proposal passes.
  /// @param externalActions includes L1 specific actions if this proposal passes. (execution permit)
  function onCreateProposal (
    address msgSender,
    uint256 nonce,
    uint256 startDate,
    address vault,
    bytes memory internalActions,
    bytes memory externalActions,
    bytes calldata metadata
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);
    _validateTimestamp(startDate);

    // compute a deterministic id
    bytes32 proposalId = HabitatBase._calculateSeed(msgSender, nonce);
    // revert if such a proposal already exists (generally not possible due to msgSender, nonce)
    require(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)) == 0, 'OCP1');

    // The vault module receives a callback at creation
    // Reverts if the module does not allow the creation of this proposal or if `vault` is invalid.
    _callCreateProposal(vault, msgSender, startDate, internalActions, externalActions);

    // store
    HabitatBase._setStorage(_PROPOSAL_START_DATE_KEY(proposalId), startDate);
    HabitatBase._setStorage(_PROPOSAL_VAULT_KEY(proposalId), vault);
    HabitatBase._setStorage(_PROPOSAL_HASH_INTERNAL_KEY(proposalId), keccak256(internalActions));
    HabitatBase._setStorage(_PROPOSAL_HASH_EXTERNAL_KEY(proposalId), keccak256(externalActions));
    // update member count
    HabitatBase._maybeUpdateMemberCount(proposalId, msgSender);

    if (_shouldEmitEvents()) {
      emit ProposalCreated(vault, proposalId, startDate);
      // internal event for submission deadlines
      _emitTransactionDeadline(startDate + _PROPOSAL_DELAY());
    }
  }

  /// @dev Helper function to retrieve the governance token given `proposalId`.
  /// Reverts if `proposalId` is invalid.
  function _getTokenOfProposal (bytes32 proposalId) internal returns (address) {
    address vault = address(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)));
    bytes32 communityId = HabitatBase.communityOfVault(vault);
    address token = HabitatBase.tokenOfCommunity(communityId);
    // only check token here, assuming any invalid proposalId / vault will end with having a zero address
    require(token != address(0), 'GTOP1');

    return token;
  }

  /// @dev Helper function for validating and applying votes
  function _votingRoutine (
    address account,
    uint256 previousVote,
    uint256 previousSignal,
    uint256 signalStrength,
    uint256 shares,
    bytes32 proposalId,
    bool delegated
  ) internal {
    // requires that the signal is in a specific range...
    require(signalStrength < 101, 'VR1');

    if (previousVote == 0 && shares != 0) {
      // a new vote - increment vote count
      HabitatBase._incrementStorage(HabitatBase._VOTING_COUNT_KEY(proposalId), 1);
    }
    if (shares == 0) {
      // removes a vote - decrement vote count
      require(signalStrength == 0 && previousVote != 0, 'VR2');
      HabitatBase._decrementStorage(HabitatBase._VOTING_COUNT_KEY(proposalId), 1);
    }

    HabitatBase._maybeUpdateMemberCount(proposalId, account);

    if (delegated) {
      HabitatBase._setStorage(_DELEGATED_VOTING_SHARES_KEY(proposalId, account), shares);
      HabitatBase._setStorage(_DELEGATED_VOTING_SIGNAL_KEY(proposalId, account), signalStrength);
    } else {
      HabitatBase._setStorage(_VOTING_SHARES_KEY(proposalId, account), shares);
      HabitatBase._setStorage(_VOTING_SIGNAL_KEY(proposalId, account), signalStrength);
    }

    // update total share count and staking amount
    if (previousVote != shares) {
      address token = _getTokenOfProposal(proposalId);
      uint256 activeStakeKey =
        delegated ? _DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, account) : _VOTING_ACTIVE_STAKE_KEY(token, account);

      HabitatBase._setStorageDelta(activeStakeKey, previousVote, shares);
      HabitatBase._setStorageDelta(_VOTING_TOTAL_SHARE_KEY(proposalId), previousVote, shares);
    }

    // update total signal
    if (previousSignal != signalStrength) {
      HabitatBase._setStorageDelta(_VOTING_TOTAL_SIGNAL_KEY(proposalId), previousSignal, signalStrength);
    }
  }

  /// @dev State transition routine for `VoteOnProposal`.
  /// Note: Votes can be changed/removed anytime.
  function onVoteOnProposal (
    address msgSender,
    uint256 nonce,
    bytes32 proposalId,
    uint256 shares,
    address delegatee,
    uint8 signalStrength
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    address token = _getTokenOfProposal(proposalId);

    if (delegatee == address(0)) {
      // voter account
      address account = msgSender;
      uint256 previousVote = HabitatBase._getStorage(_VOTING_SHARES_KEY(proposalId, account));
      // check for discrepancy between balance and stake
      uint256 stakableBalance = getUnlockedBalance(token, account) + previousVote;
      require(stakableBalance >= shares, 'OVOP1');
      uint256 previousSignal = HabitatBase._getStorage(_VOTING_SIGNAL_KEY(proposalId, account));

      _votingRoutine(account, previousVote, previousSignal, signalStrength, shares, proposalId, false);

      if (_shouldEmitEvents()) {
        emit VotedOnProposal(account, proposalId, signalStrength, shares);
      }
    } else {
      uint256 previousVote = HabitatBase._getStorage(_DELEGATED_VOTING_SHARES_KEY(proposalId, delegatee));
      uint256 previousSignal = HabitatBase._getStorage(_DELEGATED_VOTING_SIGNAL_KEY(proposalId, delegatee));
      uint256 maxAmount = HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token));
      uint256 currentlyStaked = HabitatBase._getStorage(_DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, delegatee));
      // should not happen but anyway...
      require(maxAmount >= currentlyStaked, 'ODVOP1');

      if (msgSender == delegatee) {
        // the amount that is left
        uint256 freeAmount = maxAmount - (currentlyStaked - previousVote);
        // check for discrepancy between balance and stake
        require(freeAmount >= shares, 'ODVOP2');
      } else {
        // a user may only remove shares if there is no other choice
        // we have to account for
        // - msgSender balance
        // - msgSender personal stakes
        // - msgSender delegated balance
        // - delegatee staked balance

        // new shares must be less than old shares, otherwise what are we doing here?
        require(shares < previousVote, 'ODVOP3');

        if (shares != 0) {
          // the user is not allowed to change the signalStrength if not removing the vote
          require(signalStrength == previousSignal, 'ODVOP4');
        }

        uint256 unusedBalance = maxAmount - currentlyStaked;
        uint256 maxRemovable = HabitatBase._getStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token));
        // only allow changing the stake if the user has no other choice
        require(maxRemovable > unusedBalance, 'ODVOP5');
        // the max. removable amount is the total delegated amount - the unused balance of delegatee
        maxRemovable = maxRemovable - unusedBalance;
        if (maxRemovable > previousVote) {
          // clamp
          maxRemovable = previousVote;
        }

        uint256 sharesToRemove = previousVote - shares;
        require(maxRemovable >= sharesToRemove, 'ODVOP6');
      }

      _votingRoutine(delegatee, previousVote, previousSignal, signalStrength, shares, proposalId, true);

      if (_shouldEmitEvents()) {
        emit DelegateeVotedOnProposal(delegatee, proposalId, signalStrength, shares);
      }
    }
  }

  /// @dev Invokes IModule.onProcessProposal(...) on `vault`
  /// Assumes that `vault` was already validated.
  function _callProcessProposal (
    bytes32 proposalId,
    address vault
  ) internal returns (uint256 votingStatus, uint256 secondsTillClose, uint256 quorumPercent)
  {
    uint256 secondsPassed;
    {
      uint256 dateNow = _getTime();
      uint256 proposalStartDate = HabitatBase._getStorage(_PROPOSAL_START_DATE_KEY(proposalId));

      if (dateNow > proposalStartDate) {
        secondsPassed = dateNow - proposalStartDate;
      }
    }

    bytes32 communityId = HabitatBase.communityOfVault(vault);
    // call vault with all the statistics
    bytes memory _calldata = abi.encodeWithSelector(
      0xf8d8ade6,
      proposalId,
      communityId,
      HabitatBase.getTotalMemberCount(communityId),
      HabitatBase._getStorage(_VOTING_COUNT_KEY(proposalId)),
      HabitatBase.getTotalVotingShares(proposalId),
      HabitatBase._getStorage(_VOTING_TOTAL_SIGNAL_KEY(proposalId)),
      getTotalValueLocked(HabitatBase.tokenOfCommunity(communityId)),
      secondsPassed
    );
    uint256 MAX_GAS = 90000;
    address vaultCondition = _getVaultCondition(vault);
    assembly {
      let ptr := mload(64)
      // clear memory
      calldatacopy(ptr, calldatasize(), 96)
      // check if we have enough gas to spend (relevant in challenges)
      if lt(gas(), MAX_GAS) {
        // do a silent revert to signal the challenge routine that this is an exception
        revert(0, 0)
      }
      // call
      let success := staticcall(MAX_GAS, vaultCondition, add(_calldata, 32), mload(_calldata), ptr, 96)
      if success {
        votingStatus := mload(ptr)
        ptr := add(ptr, 32)
        secondsTillClose := mload(ptr)
        ptr := add(ptr, 32)
        quorumPercent := mload(ptr)
      }
    }
  }

  /// @notice Updates the state of a proposal.
  /// @dev Only emits a event if the status changes to CLOSED or PASSED
  function onProcessProposal (
    address msgSender,
    uint256 nonce,
    bytes32 proposalId,
    bytes calldata internalActions,
    bytes calldata externalActions
  ) external returns (uint256 votingStatus, uint256 secondsTillClose, uint256 quorumPercent) {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    {
      uint256 previousVotingStatus = HabitatBase.getProposalStatus(proposalId);
      require(previousVotingStatus < uint256(IModule.VotingStatus.CLOSED), 'CLOSED');
    }

    // this will revert in _getVaultCondition if the proposal doesn't exist or `vault` is invalid
    address vault = address(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)));

    (votingStatus, secondsTillClose, quorumPercent) = _callProcessProposal(proposalId, vault);

    // finalize if the new status is CLOSED or PASSED
    if (votingStatus > uint256(IModule.VotingStatus.OPEN)) {
      // save voting status
      HabitatBase._setStorage(_PROPOSAL_STATUS_KEY(proposalId), votingStatus);

      // PASSED
      if (votingStatus == uint256(IModule.VotingStatus.PASSED)) {
        // verify the internal actions and execute
        bytes32 hash = keccak256(internalActions);
        require(HabitatBase._getStorage(_PROPOSAL_HASH_INTERNAL_KEY(proposalId)) == uint256(hash), 'IHASH');
        _executeInternalActions(vault, internalActions);

        // verify external actions and store a permit
        hash = keccak256(externalActions);
        require(HabitatBase._getStorage(_PROPOSAL_HASH_EXTERNAL_KEY(proposalId)) == uint256(hash), 'EHASH');
        if (externalActions.length != 0) {
          HabitatBase._setExecutionPermit(vault, proposalId, hash);
        }
      }

      if (_shouldEmitEvents()) {
        emit ProposalProcessed(proposalId, votingStatus);
      }
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './HabitatBase.sol';

/// @notice Functionality for user wallets and token accounting.
// Audit-1: ok
contract HabitatWallet is HabitatBase {
  event TokenTransfer(address indexed token, address indexed from, address indexed to, uint256 value, uint256 epoch);
  event DelegatedAmount(address indexed account, address indexed delegatee, address indexed token, uint256 value);

  /// @notice Returns the (free) balance (amount of `token`) for `account`.
  /// Free = balance of `token` for `account` - activeVotingStake & delegated stake for `account`.
  /// Supports ERC-20 and ERC-721 and takes staked balances into account.
  function getUnlockedBalance (address token, address account) public returns (uint256 ret) {
    uint256 locked =
      HabitatBase.getActiveVotingStake(token, account) +
      HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(account, token));
    ret = getBalance(token, account);
    // something must be wrong if this happens
    require(locked <= ret, 'GUB1');
    ret = ret - locked;
  }

  /// @dev State transition when a user transfers a token.
  /// Updates Total Value Locked and does accounting needed for staking rewards.
  function _transferToken (address token, address from, address to, uint256 value) internal virtual {
    bool isERC721 = _getTokenType(token) > 1;

    // update from
    if (isERC721) {
      require(HabitatBase.getErc721Owner(token, value) == from, 'OWNER');
      HabitatBase._setStorage(_ERC721_KEY(token, value), to);
    }

    uint256 currentEpoch = getCurrentEpoch();
    // both ERC-20 & ERC-721
    uint256 balanceDelta = isERC721 ? 1 : value;
    // update `from`
    if (from != address(0)) {
      // not a deposit - check stake
      {
        uint256 availableAmount = getUnlockedBalance(token, from);
        require(availableAmount >= balanceDelta, 'LOCK');
      }

      // can revert
      HabitatBase._decrementStorage(_ERC20_KEY(token, from), balanceDelta);

      // update historic total user balance
      HabitatBase._setStorageInfinityIfZero(
        _STAKING_EPOCH_TUB_KEY(currentEpoch, token, from),
        getBalance(token, from)
      );
    }
    // update `to`
    {
      if (to == address(0)) {
        // exit
        if (isERC721) {
          _setERC721Exit(token, from, value);
        } else {
          _incrementExit(token, from, value);
        }
      } else {
        // can throw
        HabitatBase._incrementStorage(_ERC20_KEY(token, to), balanceDelta);

        // update historic total user balance
        HabitatBase._setStorageInfinityIfZero(
          _STAKING_EPOCH_TUB_KEY(currentEpoch, token, to),
          getBalance(token, to)
        );
      }
    }

    // TVL
    {
      // from == address(0) = deposit
      // to == address(0) = exit
      // classify deposits and exits in the same way as vaults (exempt from TVL)
      bool fromVault = from == address(0) || HabitatBase._getStorage(_VAULT_CONDITION_KEY(from)) != 0;
      bool toVault = to == address(0) || HabitatBase._getStorage(_VAULT_CONDITION_KEY(to)) != 0;

      // considerations
      // - transfer from user to user, do nothing
      // - transfer from vault to vault, do nothing
      // - deposits (from = 0), increase if !toVault
      // - exits (to == 0), decrease if !fromVault
      // - transfer from user to vault, decrease
      // - transfer from vault to user, increase
      if (toVault && !fromVault) {
        HabitatBase._decrementStorage(_TOKEN_TVL_KEY(token), balanceDelta);
      }
      if (fromVault && !toVault) {
        HabitatBase._incrementStorage(_TOKEN_TVL_KEY(token), balanceDelta);
      }
    }

    {
      // update tvl for epoch - accounting for staking rewards
      HabitatBase._setStorage(
        _STAKING_EPOCH_TVL_KEY(currentEpoch, token),
        HabitatBase._getStorage(_TOKEN_TVL_KEY(token))
      );
    }

    if (_shouldEmitEvents()) {
      emit TokenTransfer(token, from, to, value, currentEpoch);
      // transactions should be submitted before the next epoch
      uint256 nextEpochTimestamp = EPOCH_GENESIS() + (SECONDS_PER_EPOCH() * (currentEpoch + 1));
      _emitTransactionDeadline(nextEpochTimestamp);
    }
  }

  /// @dev State transition when a user deposits a token.
  function onDeposit (address owner, address token, uint256 value, uint256 tokenType) external {
    HabitatBase._commonChecks();
    _setTokenType(token, tokenType);
    _transferToken(token, address(0), owner, value);
  }

  /// @dev State transition when a user transfers a token.
  function onTransferToken (address msgSender, uint256 nonce, address token, address to, uint256 value) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);
    _transferToken(token, msgSender, to, value);
  }

  /// @dev State transition when a user sets a delegate.
  function onDelegateAmount (address msgSender, uint256 nonce, address delegatee, address token, uint256 newAllowance) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // can not delegate to self
    require(msgSender != delegatee, 'ODA1');

    uint256 oldAllowance = HabitatBase._getStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token));

    // track the difference
    if (oldAllowance < newAllowance) {
      uint256 delta = newAllowance - oldAllowance;
      uint256 availableBalance = getUnlockedBalance(token, msgSender);
      // check
      require(availableBalance >= delta, 'ODA2');

      // increment new total delegated balance for delegatee
      HabitatBase._incrementStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token), delta);
      // increment new total delegated amount for msgSender
      HabitatBase._incrementStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(msgSender, token), delta);
    } else {
      uint256 delta = oldAllowance - newAllowance;
      uint256 currentlyStaked = HabitatBase._getStorage(_DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, delegatee));
      uint256 total = HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token));
      uint256 freeAmount = total - currentlyStaked;
      // check that delta is less or equal to the available balance
      require(delta <= freeAmount, 'ODA3');

      // decrement new total delegated balance for delegatee
      HabitatBase._decrementStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token), delta);
      // decrement new total delegated amount for msgSender
      HabitatBase._decrementStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(msgSender, token), delta);
    }

    // save the new allowance
    HabitatBase._setStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token), newAllowance);

    if (_shouldEmitEvents()) {
      emit DelegatedAmount(msgSender, delegatee, token, newAllowance);
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

// Audit-1: ok
interface IModule {
  enum VotingStatus {
    UNKNOWN,
    OPEN,
    CLOSED,
    PASSED
  }

  function onCreateProposal (
    bytes32 communityId,
    uint256 totalMemberCount,
    uint256 totalValueLocked,
    address proposer,
    uint256 proposerBalance,
    uint256 startDate,
    bytes calldata internalActions,
    bytes calldata externalActions
  ) external view;

  function onProcessProposal (
    bytes32 proposalId,
    bytes32 communityId,
    uint256 totalMemberCount,
    uint256 totalVoteCount,
    uint256 totalVotingShares,
    uint256 totalVotingSignal,
    uint256 totalValueLocked,
    uint256 secondsPassed
  ) external view returns (VotingStatus, uint256 secondsTillClose, uint256 quorumPercent);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import '@NutBerry/NutBerry/src/tsm/contracts/NutBerryEvents.sol';

// Audit-1: ok
contract UpgradableRollup is NutBerryEvents {
  /// @notice Returns the address who is in charge of changing the rollup implementation.
  /// This contract should be managed by a `ExecutionProxy` that in turn verifies governance decisions
  /// from the rollup.
  /// The rollup will be managed by a multisig in the beginning until moving to community governance.
  /// It should be noted that there should be a emergency contract on L1 that can be used to recover from bad upgrades
  /// in case the rollup is malfunctioning itself.
  function ROLLUP_MANAGER () public virtual view returns (address) {
  }

  /// @notice Upgrades the implementation.
  function upgradeRollup (address newImplementation) external {
    require(msg.sender == ROLLUP_MANAGER());
    assembly {
      // uint256(-1) - stores the contract address to delegate calls to (RollupProxy)
      sstore(not(returndatasize()), newImplementation)
    }
    emit NutBerryEvents.RollupUpgrade(newImplementation);
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": false,
      "peephole": true,
      "yul": false
    },
    "runs": 256
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}