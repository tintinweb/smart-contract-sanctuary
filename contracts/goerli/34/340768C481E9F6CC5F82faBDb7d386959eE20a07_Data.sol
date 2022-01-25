// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Bits} from "Bits.sol";

/*
 * Data structures and utilities used in the Patricia Tree.
 *
 * More info at: https://github.com/chriseth/patricia-trie
 */
library Data {
    struct Label {
        bytes32 data;
        uint256 length;
    }

    struct Edge {
        bytes32 node;
        Label label;
    }

    struct Node {
        Edge[2] children;
    }

    struct Tree {
        bytes32 root;
        Data.Edge rootEdge;
        mapping(bytes32 => Data.Node) nodes;
    }

    // Returns a label containing the longest common prefix of `self` and `label`,
    // and a label consisting of the remaining part of `label`.
    function splitCommonPrefix(Label memory self, Label memory other)
        internal
        pure
        returns (Label memory prefix, Label memory labelSuffix)
    {
        return splitAt(self, commonPrefix(self, other));
    }

    // Splits the label at the given position and returns prefix and suffix,
    // i.e. 'prefix.length == pos' and 'prefix.data . suffix.data == l.data'.
    function splitAt(Label memory self, uint256 pos)
        internal
        pure
        returns (Label memory prefix, Label memory suffix)
    {
        assert(pos <= self.length && pos <= 256);
        prefix.length = pos;
        if (pos == 0) {
            prefix.data = bytes32(0);
        } else {
            prefix.data = bytes32(
                uint256(self.data) & (~uint256(1) << (255 - pos))
            );
        }
        suffix.length = self.length - pos;
        suffix.data = self.data << pos;
    }

    // Returns the length of the longest common prefix of the two labels.
    /*
    function commonPrefix(Label memory self, Label memory other) internal pure returns (uint prefix) {
        uint length = self.length < other.length ? self.length : other.length;
        // TODO: This could actually use a "highestBitSet" helper
        uint diff = uint(self.data ^ other.data);
        uint mask = uint(1) << 255;
        for (; prefix < length; prefix++) {
            if ((mask & diff) != 0) {
                break;
            }
            diff += diff;
        }
    }
    */

    function commonPrefix(Label memory self, Label memory other)
        internal
        pure
        returns (uint256 prefix)
    {
        uint256 length = self.length < other.length
            ? self.length
            : other.length;
        if (length == 0) {
            return 0;
        }
        uint256 diff = uint256(self.data ^ other.data) &
            (~uint256(0) << (256 - length)); // TODO Mask should not be needed.
        if (diff == 0) {
            return length;
        }
        return 255 - Bits.highestBitSet(diff);
    }

    // Returns the result of removing a prefix of length `prefix` bits from the
    // given label (shifting its data to the left).
    function removePrefix(Label memory self, uint256 prefix)
        internal
        pure
        returns (Label memory r)
    {
        require(prefix <= self.length);
        r.length = self.length - prefix;
        r.data = self.data << prefix;
    }

    // Removes the first bit from a label and returns the bit and a
    // label containing the rest of the label (shifted to the left).
    function chopFirstBit(Label memory self)
        internal
        pure
        returns (uint256 firstBit, Label memory tail)
    {
        require(self.length > 0);
        return (
            uint256(self.data >> 255),
            Label(self.data << 1, self.length - 1)
        );
    }

    function edgeHash(Data.Edge memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(self.node, self.label.length, self.label.data)
            );
    }

    // Returns the hash of the encoding of a node.
    function hash(Data.Node memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    edgeHash(self.children[0]),
                    edgeHash(self.children[1])
                )
            );
    }

    function insertNode(Data.Tree storage tree, Data.Node memory n)
        internal
        returns (bytes32 newHash)
    {
        bytes32 h = hash(n);
        tree.nodes[h].children[0] = n.children[0];
        tree.nodes[h].children[1] = n.children[1];
        return h;
    }

    function replaceNode(
        Data.Tree storage self,
        bytes32 oldHash,
        Data.Node memory n
    ) internal returns (bytes32 newHash) {
        delete self.nodes[oldHash];
        return insertNode(self, n);
    }

    function insertAtEdge(
        Tree storage self,
        Edge memory e,
        Label memory key,
        bytes32 value
    ) internal returns (Edge memory) {
        assert(key.length >= e.label.length);
        (
            Data.Label memory prefix,
            Data.Label memory suffix
        ) = splitCommonPrefix(key, e.label);
        bytes32 newNodeHash;
        if (suffix.length == 0) {
            // Full match with the key, update operation
            newNodeHash = value;
        } else if (prefix.length >= e.label.length) {
            // Partial match, just follow the path
            assert(suffix.length > 1);
            Node memory n = self.nodes[e.node];
            (uint256 head, Data.Label memory tail) = chopFirstBit(suffix);
            n.children[head] = insertAtEdge(
                self,
                n.children[head],
                tail,
                value
            );
            delete self.nodes[e.node];
            newNodeHash = insertNode(self, n);
        } else {
            // Mismatch, so let us create a new branch node.
            (uint256 head, Data.Label memory tail) = chopFirstBit(suffix);
            Node memory branchNode;
            branchNode.children[head] = Edge(value, tail);
            branchNode.children[1 - head] = Edge(
                e.node,
                removePrefix(e.label, prefix.length + 1)
            );
            newNodeHash = insertNode(self, branchNode);
        }
        return Edge(newNodeHash, prefix);
    }

    function insert(
        Tree storage self,
        bytes memory key,
        bytes memory value
    ) internal {
        Label memory k = Label(keccak256(key), 256);
        bytes32 valueHash = keccak256(value);
        Edge memory e;
        if (self.root == 0) {
            // Empty Trie
            e.label = k;
            e.node = valueHash;
        } else {
            e = insertAtEdge(self, self.rootEdge, k, valueHash);
        }
        self.root = edgeHash(e);
        self.rootEdge = e;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Bits {
    uint256 internal constant ONE = uint256(1);

    // uint256 internal constant ONES = uint256(~0);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    // function bits(
    //     uint256 self,
    //     uint8 startIndex,
    //     uint16 numBits
    // ) internal pure returns (uint256) {
    //     require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
    //     return (self >> startIndex) & (ONES >> (256 - numBits));
    // }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}