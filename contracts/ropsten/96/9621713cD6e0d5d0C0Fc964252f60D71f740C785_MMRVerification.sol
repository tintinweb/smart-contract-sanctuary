// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.5;

/**
 * @dev MMRVerification library for MMR inclusion proofs generated
 *      by https://github.com/nervosnetwork/merkle-mountain-range.

 *                  Sample 7-leaf MMR:
 *
 *          Height 3 |      7
 *          Height 2 |   3      6     10
 *          Height 1 | 1  2   4  5   8  9    11
 *                   | |--|---|--|---|--|-----|-
 *      Leaf indexes | 0  1   2  3   4  5     6
 *
 *      General definitions:
 *      - Height:         the height of the tree.
 *      - Width:          the number of leaves in the tree.
 *      - Size:           the number of nodes in the tree.
 *      - Nodes:          an item in the tree. A node is a leaf or a parent. Nodes' positions are ordered from 1
 *                        to size in the order that they were added to the tree.
 *      - Leaf Index:     the leaf's location in an ordered array of all leaf nodes. Because Solidity interprets
 *                        0 as null, this MMR implementation internally converts leaf index to leaf position.
 *      - Parent Node:    leaf nodes are hashed together into parent nodes. To maintain the tree's structure,
 *                        parent nodes are hashed together until they form a mountain with a peak.
 *      - Mountain Peak:  the local root of a mountain; it has a greater height than other nodes in the mountain.
 *      - MMR root:       hashing each peak's hash together right-to-left gives the MMR root.
 *
 *      Our 7-leaf MMR has:
 *      - Height:          3
 *      - Size:            11
 *      - Nodes:          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
 *      - Leaf Indexes:   [0, 1, 2, 3, 4, 5, 6] which correspond to nodes [1, 2, 4, 5, 8, 9, 11]
 *      - Parent Nodes:   [3, 6, 7, 10, 11]
 *      - Mountain peaks: [7, 10, 11]
 *      - MMR root:       hash(hash(11, 10), 7)
 */
contract MMRVerification {
    struct MountainData {
        uint256 position;
        bytes32 hash;
        uint256 height;
    }

    mapping(uint256 => MountainData) public queue;

    /**
     * @dev Verify an MMR inclusion proof for a leaf at a given index.
     */
    function verifyInclusionProof(
        bytes32 root,
        bytes32 leafNodeHash,
        uint256 leafIndex,
        uint256 leafCount,
        bytes32[] memory proofItems
    ) public returns (bool) {
        // Input index must be a leaf
        uint256 leafPos = leafIndexToPos(leafIndex);
        if (!isLeaf(leafPos)) {
            return false;
        }

        // Handle 1-leaf MMR
        if (leafCount == 1 && leafPos == 1 && leafNodeHash == root) {
            return true;
        }

        // Calculate the position of our leaf's mountain peak
        uint256 targetPeakPos;
        uint256 numLeftPeaks;
        uint256[] memory peakPositions = getPeakPositions(leafCount);
        for (uint256 i = 0; i < peakPositions.length; i++) {
            if (peakPositions[i] >= leafPos) {
                targetPeakPos = peakPositions[i];
                break;
            }
            numLeftPeaks++;
        }

        // Calculate our leaf's mountain peak hash
        bytes32 mountainHash =
            calculatePeakRoot(
                numLeftPeaks,
                leafNodeHash,
                leafPos,
                targetPeakPos,
                proofItems
            );

        // Bag peaks
        bytes32 bagger = mountainHash;

        // All right peaks are rolled up into one hash. If there are any, bag them.
        if (targetPeakPos < peakPositions[peakPositions.length - 1]) {
            bagger = keccak256(
                abi.encodePacked(proofItems[proofItems.length - 1], bagger)
            );
        }

        // Bag left peaks one-by-one
        for (uint256 i = numLeftPeaks; i > 0; i--) {
            bagger = keccak256(abi.encodePacked(bagger, proofItems[i - 1]));
        }

        return bagger == root;
    }

    /**
     * @dev Calculate a leaf's mountain peak based on it's hash, it's position,
     *      the mountain peak's position, and the proof contents.
     */
    function calculatePeakRoot(
        uint256 numLeftPeaks,
        bytes32 leafNodeHash,
        uint256 leafPos,
        uint256 peakPos,
        bytes32[] memory proofItems
    ) public returns (bytes32) {
        if (leafPos == peakPos) {
            return leafNodeHash;
        }
        uint256 proofItemsCounter = numLeftPeaks;
        uint256 qFront;
        uint256 qBack;

        MountainData memory mountainData =
            MountainData(leafPos, leafNodeHash, 1);
        queue[qBack] = mountainData;
        qBack = qBack + 1;

        while (qBack >= qFront) {
            MountainData memory mData = queue[qFront];
            uint256 pos = mData.position;

            // Calculate sibling and parent position
            uint256 siblingPos;
            uint256 parentPos;

            uint256 nextHeight = heightAt(pos + 1);
            uint256 sibOffset = siblingOffset(mData.height - 1);
            if (nextHeight > mData.height) {
                // Current position is right sibling
                siblingPos = pos - sibOffset;
                parentPos = pos + 1;
            } else {
                // Current position is left sibling
                siblingPos = pos + sibOffset;
                parentPos = pos + parentOffset(mData.height - 1);
            }

            // Sibling hash is either next in queue or next proof item
            bytes32 siblingHash;
            if (siblingPos == queue[qFront].position) {
                siblingHash = queue[qFront].hash;
            } else {
                siblingHash = proofItems[proofItemsCounter];
                proofItemsCounter = proofItemsCounter + 1;
            }

            // Calculate parent hash
            bytes32 parentHash;
            if (nextHeight > mData.height) {
                parentHash = keccak256(
                    abi.encodePacked(siblingHash, mData.hash)
                );
            } else {
                parentHash = keccak256(
                    abi.encodePacked(mData.hash, siblingHash)
                );
            }

            if (parentPos < peakPos) {
                // Parent is not the mountain peak
                queue[qBack] = MountainData(
                    parentPos,
                    parentHash,
                    mData.height + 1
                );
                qBack = qBack + 1;
            } else {
                // Parent is the peak
                delete (queue[qFront]);
                return parentHash;
            }

            // Move to next item in queue
            delete (queue[qFront]);
            qFront = qFront + 1;
        }
        revert();
    }

    /**
     * @dev It returns the height of the highest peak
     */
    function mountainHeight(uint256 size) public pure returns (uint8) {
        uint8 height = 1;
        while (uint256(1) << height <= size + height) {
            height++;
        }
        return height - 1;
    }

    /**
     * @dev It returns the height of the index
     */
    function heightAt(uint256 index) public pure returns (uint8 height) {
        uint256 reducedIndex = index;
        uint256 peakIndex;
        // If an index has a left mountain subtract the mountain
        while (reducedIndex > peakIndex) {
            reducedIndex -= (uint256(1) << height) - 1;
            height = mountainHeight(reducedIndex);
            peakIndex = (uint256(1) << height) - 1;
        }
        // Index is on the right slope
        height = height - uint8((peakIndex - reducedIndex));
    }

    /**
     * @dev It returns whether the index is the leaf node or not
     */
    function isLeaf(uint256 index) public pure returns (bool) {
        return heightAt(index) == 1;
    }

    /**
     * @dev It returns positions of all peaks
     */
    function getPeakPositions(uint256 width)
        public
        pure
        returns (uint256[] memory peakPositions)
    {
        peakPositions = new uint256[](numOfPeaks(width));
        uint256 count;
        uint256 size;
        for (uint256 i = 255; i > 0; i--) {
            if (width & (1 << (i - 1)) != 0) {
                // peak exists
                size = size + (1 << i) - 1;
                peakPositions[count++] = size;
            }
        }
        require(count == peakPositions.length, "Invalid bit calculation");
    }

    /**
     * @dev Return number of peaks from number of leaves
     */
    function numOfPeaks(uint256 numLeaves)
        public
        pure
        returns (uint256 numPeaks)
    {
        uint256 bits = numLeaves;
        while (bits > 0) {
            if (bits % 2 == 1) numPeaks++;
            bits = bits >> 1;
        }
        return numPeaks;
    }

    /**
     * @dev Return MMR size from number of leaves
     */
    function getSize(uint256 numLeaves) internal pure returns (uint256) {
        return (numLeaves << 1) - numOfPeaks(numLeaves);
    }

    /**
     * @dev Counts the number of 1s in the binary representation of an integer
     */
    function bitCount(uint256 n) internal pure returns (uint256) {
        uint256 count;
        while (n > 0) {
            count = count + 1;
            n = n & (n - 1);
        }
        return count;
    }

    /**
     * @dev Return position of leaf at given leaf index
     */
    function leafIndexToPos(uint256 index) internal pure returns (uint256) {
        return leafIndexToMmrSize(index) - trailingZeros(index + 1);
    }

    /**
     * @dev Return
     */
    function leafIndexToMmrSize(uint256 index) internal pure returns (uint256) {
        uint256 leavesCount = index + 1;
        uint256 peaksCount = bitCount(leavesCount);
        return (2 * leavesCount) - peaksCount;
    }

    /**
     * @dev Counts the number of trailing 0s in the binary representation of an integer
     */
    function trailingZeros(uint256 x) internal pure returns (uint256) {
        if (x == 0) return (32);
        uint256 n = 1;
        if ((x & 0x0000FFFF) == 0) {
            n = n + 16;
            x = x >> 16;
        }
        if ((x & 0x000000FF) == 0) {
            n = n + 8;
            x = x >> 8;
        }
        if ((x & 0x0000000F) == 0) {
            n = n + 4;
            x = x >> 4;
        }
        if ((x & 0x00000003) == 0) {
            n = n + 2;
            x = x >> 2;
        }
        return n - (x & 1);
    }

    /**
     * @dev Return parent offset at a given height
     */
    function parentOffset(uint256 height) internal pure returns (uint256 num) {
        return 2 << height;
    }

    /**
     * @dev Return sibling offset at a given height
     */
    function siblingOffset(uint256 height) internal pure returns (uint256 num) {
        return (2 << height) - 1;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}