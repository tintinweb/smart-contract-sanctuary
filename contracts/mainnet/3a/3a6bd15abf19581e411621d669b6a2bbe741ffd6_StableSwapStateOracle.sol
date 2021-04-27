/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT AND Apache-2.0

// License: MIT

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Copied from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}


// License: Apache-2.0

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        (, uint len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        (uint memPtr, uint len) = payloadLocation(item);

        uint result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint memPtr, uint len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}


// License: MIT

/**
 * Copied from https://github.com/lorenzb/proveth/blob/c74b20e/onchain/ProvethVerifier.sol
 * with minor performance and code style-related modifications.
 */

library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param path is the key of the node whose inclusion/exclusion we are
    ///        proving.
    /// @param stack is the stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;
        bytes memory rlpNode;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {
            // Root hash of empty Merkle-Patricia-Trie
            require(rootHash == 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421);
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < stack.length; i++) {

            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.

            // The root node is hashed with Keccak-256 ...
            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert();
            }
            // ... whereas all other nodes are hashed with the MPT
            // hash function.
            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert();
            }
            // We verified that stack[i] has the correct hash, so we
            // may safely decode it.
            node = stack[i].toList();

            if (node.length == 2) {
                // Extension or Leaf node

                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

                uint256 prefixLength = _sharedPrefixLength(mptKeyOffset, mptKey, nodeKey);
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent iff it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < stack.length - 1) {
                        // divergent node must come last in proof
                        revert();
                    }

                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < stack.length - 1) {
                        // leaf node must come last in proof
                        revert();
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else { // extension
                    // Sanity check
                    if (i == stack.length - 1) {
                        // shouldn't be at last level
                        revert();
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = node[1].payloadKeccak256();
                    } else {
                        // rlp(child) was less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {
                // Branch node

                if (mptKeyOffset != mptKey.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert();
                    }

                    if (_isEmptyBytesequence(node[nibble])) {
                        // Sanity
                        if (i != stack.length - 1) {
                            // leaf node should be at last level
                            revert();
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].payloadKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.

                    // Sanity
                    if (i != stack.length - 1) {
                        // should be at last level
                        revert();
                    }

                    return node[16].toBytes();
                }
            }
        }
    }


    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
    ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
    ///      *variable-length* hashes: If the item is shorter than 32 bytes,
    ///      the MPT hash is the item. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the item.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param item The RLP item to be hashed.
    /// @return Keccak-256(MPT-hash(item))
    function _mptHashHash(RLPReader.RLPItem memory item) private pure returns (bytes32) {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item) private pure returns (bool) {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80 /* empty byte string */;
    }


    function _merklePatriciaCompactDecode(bytes memory compact) private pure returns (bool isLeaf, bytes memory nibbles) {
        require(compact.length > 0);
        uint256 first_nibble = uint8(compact[0]) >> 4 & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert();
        }
        return (isLeaf, _decodeNibbles(compact, skipNibbles));
    }


    function _decodeNibbles(bytes memory compact, uint256 skipNibbles) private pure returns (bytes memory nibbles) {
        require(compact.length > 0);

        uint256 length = compact.length * 2;
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 4) & 0xF);
            } else {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 0) & 0xF);
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }


    function _sharedPrefixLength(uint256 xsOffset, bytes memory xs, bytes memory ys) private pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}


// License: MIT

/**
 * @title A helper library for verification of Merkle Patricia account and state proofs.
 */
library Verifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint256 constant HEADER_STATE_ROOT_INDEX = 3;
    uint256 constant HEADER_NUMBER_INDEX = 8;
    uint256 constant HEADER_TIMESTAMP_INDEX = 11;

    struct BlockHeader {
        bytes32 hash;
        bytes32 stateRootHash;
        uint256 number;
        uint256 timestamp;
    }

    struct Account {
        bool exists;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct SlotValue {
        bool exists;
        uint256 value;
    }


    /**
     * @notice Parses block header and verifies its presence onchain within the latest 256 blocks.
     * @param _headerRlpBytes RLP-encoded block header.
     */
    function verifyBlockHeader(bytes memory _headerRlpBytes)
        internal view returns (BlockHeader memory)
    {
        BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
        // ensure that the block is actually in the blockchain
        require(header.hash == blockhash(header.number), "blockhash mismatch");
        return header;
    }


    /**
     * @notice Parses RLP-encoded block header.
     * @param _headerRlpBytes RLP-encoded block header.
     */
    function parseBlockHeader(bytes memory _headerRlpBytes)
        internal pure returns (BlockHeader memory)
    {
        BlockHeader memory result;
        RLPReader.RLPItem[] memory headerFields = _headerRlpBytes.toRlpItem().toList();

        result.stateRootHash = bytes32(headerFields[HEADER_STATE_ROOT_INDEX].toUint());
        result.number = headerFields[HEADER_NUMBER_INDEX].toUint();
        result.timestamp = headerFields[HEADER_TIMESTAMP_INDEX].toUint();
        result.hash = keccak256(_headerRlpBytes);

        return result;
    }


    /**
     * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
     *
     * @param _addressHash Keccak256 hash of the address corresponding to the account.
     * @param _stateRootHash MPT root hash of the Ethereum state trie.
     */
    function extractAccountFromProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32 _stateRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (Account memory)
    {
        bytes memory acctRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _stateRootHash,
            abi.encodePacked(_addressHash),
            _proof
        );

        Account memory account;

        if (acctRlpBytes.length == 0) {
            return account;
        }

        RLPReader.RLPItem[] memory acctFields = acctRlpBytes.toRlpItem().toList();
        require(acctFields.length == 4);

        account.exists = true;
        account.nonce = acctFields[0].toUint();
        account.balance = acctFields[1].toUint();
        account.storageRoot = bytes32(acctFields[2].toUint());
        account.codeHash = bytes32(acctFields[3].toUint());

        return account;
    }


    /**
     * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
     *
     * @param _slotHash Keccak256 hash of the slot position.
     * @param _storageRootHash MPT root hash of the account's storage trie.
     */
    function extractSlotValueFromProof(
        bytes32 _slotHash,
        bytes32 _storageRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (SlotValue memory)
    {
        bytes memory valueRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _storageRootHash,
            abi.encodePacked(_slotHash),
            _proof
        );

        SlotValue memory value;

        if (valueRlpBytes.length != 0) {
            value.exists = true;
            value.value = valueRlpBytes.toRlpItem().toUint();
        }

        return value;
    }

}


// License: MIT


interface IPriceHelper {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory xp,
        uint256 A,
        uint256 fee
    ) external pure returns (uint256);
}


interface IStableSwap {
    function fee() external view returns (uint256);
    function A_precise() external view returns (uint256);
}


/**
 * @title
 *   A trustless oracle for the stETH/ETH Curve pool using Merkle Patricia
 *   proofs of Ethereum state.
 *
 * @notice
 *   The oracle currently assumes that the pool's fee and A (amplification
 *   coefficient) values don't change between the time of proof generation
 *   and submission.
 */
contract StableSwapStateOracle {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using SafeMath for uint256;

    /**
     * @notice Logs the updated slot values of Curve pool and stETH contracts.
     */
    event SlotValuesUpdated(
        uint256 timestamp,
        uint256 poolEthBalance,
        uint256 poolAdminEthBalance,
        uint256 poolAdminStethBalance,
        uint256 stethPoolShares,
        uint256 stethTotalShares,
        uint256 stethBeaconBalance,
        uint256 stethBufferedEther,
        uint256 stethDepositedValidators,
        uint256 stethBeaconValidators
    );

    /**
     * @notice Logs the updated stETH and ETH pool balances and the calculated stETH/ETH price.
     */
    event PriceUpdated(
        uint256 timestamp,
        uint256 etherBalance,
        uint256 stethBalance,
        uint256 stethPrice
    );

    /**
     * @notice Logs the updated price update threshold percentage advised to offchain clients.
     */
    event PriceUpdateThresholdChanged(uint256 threshold);

    /**
     * @notice
     *   Logs the updated address having the right to change the advised price update threshold.
     */
    event AdminChanged(address admin);


    /// @dev Reporting data that is more fresh than this number of blocks ago is prohibited
    uint256 constant public MIN_BLOCK_DELAY = 15;

    // Constants for offchain proof generation

    address constant public POOL_ADDRESS = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address constant public STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @dev keccak256(abi.encodePacked(uint256(1)))
    bytes32 constant public POOL_ADMIN_BALANCES_0_POS = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;

    /// @dev bytes32(uint256(POOL_ADMIN_BALANCES_0_POS) + 1)
    bytes32 constant public POOL_ADMIN_BALANCES_1_POS = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf7;

    /// @dev keccak256(uint256(0xdc24316b9ae028f1497c275eb9192a3ea0f67022) . uint256(0))
    bytes32 constant public STETH_POOL_SHARES_POS = 0xae68078d7ee25b2b7bcb7d4b9fe9acf61f251fe08ff637df07889375d8385158;

    /// @dev keccak256("lido.StETH.totalShares")
    bytes32 constant public STETH_TOTAL_SHARES_POS = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

    /// @dev keccak256("lido.Lido.beaconBalance")
    bytes32 constant public STETH_BEACON_BALANCE_POS = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483;

    /// @dev keccak256("lido.Lido.bufferedEther")
    bytes32 constant public STETH_BUFFERED_ETHER_POS = 0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0;

    /// @dev keccak256("lido.Lido.depositedValidators")
    bytes32 constant public STETH_DEPOSITED_VALIDATORS_POS = 0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c;

    /// @dev keccak256("lido.Lido.beaconValidators")
    bytes32 constant public STETH_BEACON_VALIDATORS_POS = 0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10;

    // Constants for onchain proof verification

    /// @dev keccak256(abi.encodePacked(POOL_ADDRESS))
    bytes32 constant POOL_ADDRESS_HASH = 0xc70f76036d72b7bb865881e931082ea61bb4f13ec9faeb17f0591b18b6fafbd7;

    /// @dev keccak256(abi.encodePacked(STETH_ADDRESS))
    bytes32 constant STETH_ADDRESS_HASH = 0x6c958a912fe86c83262fbd4973f6bd042cef76551aaf679968f98665979c35e7;

    /// @dev keccak256(abi.encodePacked(POOL_ADMIN_BALANCES_0_POS))
    bytes32 constant POOL_ADMIN_BALANCES_0_HASH = 0xb5d9d894133a730aa651ef62d26b0ffa846233c74177a591a4a896adfda97d22;

    /// @dev keccak256(abi.encodePacked(POOL_ADMIN_BALANCES_1_POS)
    bytes32 constant POOL_ADMIN_BALANCES_1_HASH = 0xea7809e925a8989e20c901c4c1da82f0ba29b26797760d445a0ce4cf3c6fbd31;

    /// @dev keccak256(abi.encodePacked(STETH_POOL_SHARES_POS)
    bytes32 constant STETH_POOL_SHARES_HASH = 0xe841c8fb2710e169d6b63e1130fb8013d57558ced93619655add7aef8c60d4dc;

    /// @dev keccak256(abi.encodePacked(STETH_TOTAL_SHARES_POS)
    bytes32 constant STETH_TOTAL_SHARES_HASH = 0x4068b5716d4c00685289292c9cdc7e059e67159cd101476377efe51ba7ab8e9f;

    /// @dev keccak256(abi.encodePacked(STETH_BEACON_BALANCE_POS)
    bytes32 constant STETH_BEACON_BALANCE_HASH = 0xa6965d4729b36ed8b238f6ba55294196843f8be2850c5f63b6fb6d29181b50f8;

    /// @dev keccak256(abi.encodePacked(STETH_BUFFERED_ETHER_POS)
    bytes32 constant STETH_BUFFERED_ETHER_HASH = 0xa39079072910ef75f32ddc4f40104882abfc19580cc249c694e12b6de868ee1d;

    /// @dev keccak256(abi.encodePacked(STETH_DEPOSITED_VALIDATORS_POS)
    bytes32 constant STETH_DEPOSITED_VALIDATORS_HASH = 0x17216d3ffd8719eeee6d8052f7c1e6269bd92d2390d3e3fc4cde1f026e427fb3;

    /// @dev keccak256(abi.encodePacked(STETH_BEACON_VALIDATORS_POS)
    bytes32 constant STETH_BEACON_VALIDATORS_HASH = 0x6fd60d3960d8a32cbc1a708d6bf41bbce8152e61e72b2236d5e1ecede9c4cc72;

    uint256 constant internal STETH_DEPOSIT_SIZE = 32 ether;

    /**
     * @dev A helper contract for calculating stETH/ETH price from its stETH and ETH balances.
     */
    IPriceHelper internal helper;

    /**
     * @notice The admin has the right to set the suggested price update threshold (see below).
     */
    address public admin;

    /**
     * @notice
     *   The price update threshold percentage advised to oracle clients.
     *   Expressed in basis points: 10000 BP equal to 100%, 100 BP to 1%.
     *
     * @dev
     *   If the current price in the pool differs less than this, the clients are advised to
     *   skip updating the oracle. However, this threshold is not enforced, so clients are
     *   free to update the oracle with any valid price.
     */
    uint256 public priceUpdateThreshold;

    /**
     * @notice The timestamp of the proven pool state/price.
     */
    uint256 public timestamp;

    /**
     * @notice The proven ETH balance of the pool.
     */
    uint256 public etherBalance;

    /**
     * @notice The proven stETH balance of the pool.
     */
    uint256 public stethBalance;

    /**
     * @notice The proven stETH/ETH price in the pool.
     */
    uint256 public stethPrice;


    /**
     * @param _helper Address of the deployed instance of the StableSwapPriceHelper.vy contract.
     * @param _admin The address that has the right to set the suggested price update threshold.
     * @param _priceUpdateThreshold The initial value of the suggested price update threshold.
     *        Expressed in basis points, 10000 BP corresponding to 100%.
     */
    constructor(IPriceHelper _helper, address _admin, uint256 _priceUpdateThreshold) public {
        helper = _helper;
        _setAdmin(_admin);
        _setPriceUpdateThreshold(_priceUpdateThreshold);
    }


    /**
     * @notice Passes the right to set the suggested price update threshold to a new address.
     */
    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        _setAdmin(_admin);
    }


    /**
     * @notice Sets the suggested price update threshold.
     *
     * @param _priceUpdateThreshold The suggested price update threshold.
     *        Expressed in basis points, 10000 BP corresponding to 100%.
     */
    function setPriceUpdateThreshold(uint256 _priceUpdateThreshold) external {
        require(msg.sender == admin);
        _setPriceUpdateThreshold(_priceUpdateThreshold);
    }


    /**
     * @notice Retuens a set of values used by the clients for proof generation.
     */
    function getProofParams() external view returns (
        address poolAddress,
        address stethAddress,
        bytes32 poolAdminEtherBalancePos,
        bytes32 poolAdminCoinBalancePos,
        bytes32 stethPoolSharesPos,
        bytes32 stethTotalSharesPos,
        bytes32 stethBeaconBalancePos,
        bytes32 stethBufferedEtherPos,
        bytes32 stethDepositedValidatorsPos,
        bytes32 stethBeaconValidatorsPos,
        uint256 advisedPriceUpdateThreshold
    ) {
        return (
            POOL_ADDRESS,
            STETH_ADDRESS,
            POOL_ADMIN_BALANCES_0_POS,
            POOL_ADMIN_BALANCES_1_POS,
            STETH_POOL_SHARES_POS,
            STETH_TOTAL_SHARES_POS,
            STETH_BEACON_BALANCE_POS,
            STETH_BUFFERED_ETHER_POS,
            STETH_DEPOSITED_VALIDATORS_POS,
            STETH_BEACON_VALIDATORS_POS,
            priceUpdateThreshold
        );
    }


    /**
     * @return _timestamp The timestamp of the proven pool state/price.
     * @return _etherBalance The proven ETH balance of the pool.
     * @return _stethBalance The proven stETH balance of the pool.
     * @return _stethPrice The proven stETH/ETH price in the pool.
     */
    function getState() external view returns (
        uint256 _timestamp,
        uint256 _etherBalance,
        uint256 _stethBalance,
        uint256 _stethPrice
    ) {
        return (timestamp, etherBalance, stethBalance, stethPrice);
    }


    /**
     * @notice Used by the offchain clients to submit the proof.
     *
     * @dev Reverts unless:
     *   - the block the submitted data corresponds to is in the chain;
     *   - the block is at least `MIN_BLOCK_DELAY` blocks old;
     *   - all submitted proofs are valid.
     *
     * @param _blockHeaderRlpBytes RLP-encoded block header.
     *
     * @param _proofRlpBytes RLP-encoded list of Merkle Patricia proofs:
     *    1. proof of the Curve pool contract account;
     *    2. proof of the stETH contract account;
     *    3. proof of the `admin_balances[0]` slot of the Curve pool contract;
     *    4. proof of the `admin_balances[1]` slot of the Curve pool contract;
     *    5. proof of the `shares[0xDC24316b9AE028F1497c275EB9192a3Ea0f67022]` slot of stETH contract;
     *    6. proof of the `keccak256("lido.StETH.totalShares")` slot of stETH contract;
     *    7. proof of the `keccak256("lido.Lido.beaconBalance")` slot of stETH contract;
     *    8. proof of the `keccak256("lido.Lido.bufferedEther")` slot of stETH contract;
     *    9. proof of the `keccak256("lido.Lido.depositedValidators")` slot of stETH contract;
     *   10. proof of the `keccak256("lido.Lido.beaconValidators")` slot of stETH contract.
     */
    function submitState(bytes memory _blockHeaderRlpBytes, bytes memory _proofRlpBytes)
        external
    {
        Verifier.BlockHeader memory blockHeader = Verifier.verifyBlockHeader(_blockHeaderRlpBytes);

        {
            uint256 currentBlock = block.number;
            // ensure block finality
            require(
                currentBlock > blockHeader.number &&
                currentBlock - blockHeader.number >= MIN_BLOCK_DELAY,
                "block too fresh"
            );
        }

        require(blockHeader.timestamp > timestamp, "stale data");

        RLPReader.RLPItem[] memory proofs = _proofRlpBytes.toRlpItem().toList();
        require(proofs.length == 10, "total proofs");

        Verifier.Account memory accountPool = Verifier.extractAccountFromProof(
            POOL_ADDRESS_HASH,
            blockHeader.stateRootHash,
            proofs[0].toList()
        );

        require(accountPool.exists, "accountPool");

        Verifier.Account memory accountSteth = Verifier.extractAccountFromProof(
            STETH_ADDRESS_HASH,
            blockHeader.stateRootHash,
            proofs[1].toList()
        );

        require(accountSteth.exists, "accountSteth");

        Verifier.SlotValue memory slotPoolAdminBalances0 = Verifier.extractSlotValueFromProof(
            POOL_ADMIN_BALANCES_0_HASH,
            accountPool.storageRoot,
            proofs[2].toList()
        );

        require(slotPoolAdminBalances0.exists, "adminBalances0");

        Verifier.SlotValue memory slotPoolAdminBalances1 = Verifier.extractSlotValueFromProof(
            POOL_ADMIN_BALANCES_1_HASH,
            accountPool.storageRoot,
            proofs[3].toList()
        );

        require(slotPoolAdminBalances1.exists, "adminBalances1");

        Verifier.SlotValue memory slotStethPoolShares = Verifier.extractSlotValueFromProof(
            STETH_POOL_SHARES_HASH,
            accountSteth.storageRoot,
            proofs[4].toList()
        );

        require(slotStethPoolShares.exists, "poolShares");

        Verifier.SlotValue memory slotStethTotalShares = Verifier.extractSlotValueFromProof(
            STETH_TOTAL_SHARES_HASH,
            accountSteth.storageRoot,
            proofs[5].toList()
        );

        require(slotStethTotalShares.exists, "totalShares");

        Verifier.SlotValue memory slotStethBeaconBalance = Verifier.extractSlotValueFromProof(
            STETH_BEACON_BALANCE_HASH,
            accountSteth.storageRoot,
            proofs[6].toList()
        );

        require(slotStethBeaconBalance.exists, "beaconBalance");

        Verifier.SlotValue memory slotStethBufferedEther = Verifier.extractSlotValueFromProof(
            STETH_BUFFERED_ETHER_HASH,
            accountSteth.storageRoot,
            proofs[7].toList()
        );

        require(slotStethBufferedEther.exists, "bufferedEther");

        Verifier.SlotValue memory slotStethDepositedValidators = Verifier.extractSlotValueFromProof(
            STETH_DEPOSITED_VALIDATORS_HASH,
            accountSteth.storageRoot,
            proofs[8].toList()
        );

        require(slotStethDepositedValidators.exists, "depositedValidators");

        Verifier.SlotValue memory slotStethBeaconValidators = Verifier.extractSlotValueFromProof(
            STETH_BEACON_VALIDATORS_HASH,
            accountSteth.storageRoot,
            proofs[9].toList()
        );

        require(slotStethBeaconValidators.exists, "beaconValidators");

        emit SlotValuesUpdated(
            blockHeader.timestamp,
            accountPool.balance,
            slotPoolAdminBalances0.value,
            slotPoolAdminBalances1.value,
            slotStethPoolShares.value,
            slotStethTotalShares.value,
            slotStethBeaconBalance.value,
            slotStethBufferedEther.value,
            slotStethDepositedValidators.value,
            slotStethBeaconValidators.value
        );

        uint256 newEtherBalance = accountPool.balance.sub(slotPoolAdminBalances0.value);
        uint256 newStethBalance = _getStethBalanceByShares(
            slotStethPoolShares.value,
            slotStethTotalShares.value,
            slotStethBeaconBalance.value,
            slotStethBufferedEther.value,
            slotStethDepositedValidators.value,
            slotStethBeaconValidators.value
        ).sub(slotPoolAdminBalances1.value);

        uint256 newStethPrice = _calcPrice(newEtherBalance, newStethBalance);

        timestamp = blockHeader.timestamp;
        etherBalance = newEtherBalance;
        stethBalance = newStethBalance;
        stethPrice = newStethPrice;

        emit PriceUpdated(blockHeader.timestamp, newEtherBalance, newStethBalance, newStethPrice);
    }


    /**
     * @dev Given the values of stETH smart contract slots, calculates the amount of stETH owned
     *      by the Curve pool by reproducing calculations performed in the stETH contract.
     */
    function _getStethBalanceByShares(
        uint256 _shares,
        uint256 _totalShares,
        uint256 _beaconBalance,
        uint256 _bufferedEther,
        uint256 _depositedValidators,
        uint256 _beaconValidators
    )
        internal pure returns (uint256)
    {
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/StETH.sol#L283
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/Lido.sol#L719
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/Lido.sol#L706
        if (_totalShares == 0) {
            return 0;
        }
        uint256 transientBalance = _depositedValidators.sub(_beaconValidators).mul(STETH_DEPOSIT_SIZE);
        uint256 totalPooledEther = _bufferedEther.add(_beaconBalance).add(transientBalance);
        return _shares.mul(totalPooledEther).div(_totalShares);
    }


    /**
     * @dev Given the ETH and stETH balances of the Curve pool, calculates the corresponding
     *      stETH/ETH price by reproducing calculations performed in the pool contract.
     */
    function _calcPrice(uint256 _etherBalance, uint256 _stethBalance) internal view returns (uint256) {
        uint256 A = IStableSwap(POOL_ADDRESS).A_precise();
        uint256 fee = IStableSwap(POOL_ADDRESS).fee();
        return helper.get_dy(1, 0, 10**18, [_etherBalance, _stethBalance], A, fee);
    }


    function _setPriceUpdateThreshold(uint256 _priceUpdateThreshold) internal {
        require(_priceUpdateThreshold <= 10000);
        priceUpdateThreshold = _priceUpdateThreshold;
        emit PriceUpdateThresholdChanged(_priceUpdateThreshold);
    }


    function _setAdmin(address _admin) internal {
        require(_admin != address(0));
        require(_admin != admin);
        admin = _admin;
        emit AdminChanged(_admin);
    }
}