/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity >=0.4.21 <0.6.0;


/**
 * @author Wanseob Lim <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7d18101c14113d0a1c130e18121f531e1210">[email&#160;protected]</a>>
 * @title Merkle Mountain Range solidity library
 *
 * The index starts from 1 not 0. And it uses keccak256 for its hash function
 */
library MMR {

    struct Tree {
        bytes32 root;
        uint256 size;
        mapping(uint256 => bytes32) hashes;
    }

    /**
     * @dev This only stores the hashed value of the leaf.
     * If you need to retrieve the detail data later, use a map to store them.
     */
    function append(Tree storage tree, bytes memory data) public {
        // Hash the leaf node first
        bytes32 hash = hashLeaf(tree.size + 1, data);
        // Put the hashed leaf to the map
        tree.hashes[tree.size + 1] = hash;
        // Find peaks for the increased size tree
        uint256[] memory peaks = getPeaks(tree.size + 1);
        // The right most peak&#39;s value is the new size of the updated tree
        tree.size = peaks[peaks.length - 1];
        // Starting from the left-most peak, get all peak hashes using _getOrCreateNode() function.
        bytes32[] memory peakBagging = new bytes32[](peaks.length);
        for (uint i = 0; i < peaks.length; i++) {
            peakBagging[i] = _getOrCreateNode(tree, peaks[i]);
        }
        // Create the root hash and update the tree
        tree.root = keccak256(
            abi.encodePacked(
                tree.size,
                keccak256(abi.encodePacked(tree.size, abi.encodePacked(peakBagging)))
            )
        );
    }

    /**
     * @dev It returns the root value of the tree
     */
    function getRoot(Tree storage tree) public view returns (bytes32) {
        return tree.root;
    }

    /**
     * @dev It returns the size of the tree
     */
    function getSize(Tree storage tree) public view returns (uint256) {
        return tree.size;
    }

    /**
     * @dev It returns the hash value of a node for the given position. Note that the index starts from 1
     */
    function getNode(Tree storage tree, uint256 index) public view returns (bytes32) {
        return tree.hashes[index];
    }

    /**
     * @dev It returns a merkle proof for the given position. Note that the index starts from 1
     */
    function getMerkleProof(Tree storage tree, uint256 index) public view returns (
        bytes32 root,
        uint256 size,
        bytes32[] memory peakBagging,
        bytes32[] memory siblings
    ){
        require(index < tree.size, "Out of range");
        require(isLeaf(index), "Not a leaf");

        root = tree.root;
        size = tree.size;
        // Find all peaks for bagging
        uint256[] memory peaks = getPeaks(size);

        peakBagging = new bytes32[](peaks.length);
        uint256 myPeakIndex;
        for (uint i = 0; i < peaks.length; i++) {
            // Collect the hash of all peaks
            peakBagging[i] = tree.hashes[peaks[i]];
            // Find the peak which includes the target index
            if (peaks[i] >= index && myPeakIndex == 0) {
                myPeakIndex = peaks[i];
            }
        }
        uint256 left;
        uint256 right;

        // Get hashes of the siblings in the mountain which the index belongs to.
        // It moves myPeakIndex from the summit of the mountain down to the target index
        uint8 myPeakHeight = heightAt(myPeakIndex);
        siblings = new bytes32[](myPeakHeight - 1);
        while (myPeakIndex != index) {
            myPeakHeight--;
            (left, right) = getChildren(myPeakIndex);
            // Move myPeakIndex down to the left side or right side
            myPeakIndex = index <= left ? left : right;
            // Remaining node is the sibling
            siblings[myPeakHeight - 1] = tree.hashes[index <= left ? right : left];
        }
    }

    /** Pure functions */

    /**
     * @dev It returns true when the given params verifies that the given value exists in the tree or reverts the transaction.
     */
    function inclusionProof(
        bytes32 root,
        uint256 size,
        uint256 index,
        bytes memory value,
        bytes32[] memory peakBagging,
        bytes32[] memory siblings
    ) public pure returns (bool) {
        // Check the root equals the peak bagging hash
        require(root == keccak256(abi.encodePacked(size, keccak256(abi.encodePacked(size, peakBagging)))), "Invalid root hash from the peaks");

        // Find the mountain where the target index belongs to
        uint256 cursor;
        bytes32 targetPeak;
        uint256[] memory peaks = getPeaks(size);
        for (uint i = 0; i < peaks.length; i++) {
            if (peaks[i] >= index) {
                targetPeak = peakBagging[i];
                cursor = peaks[i];
                break;
            }
        }
        require(targetPeak != bytes32(0), "Target is not found");

        // Find the path climbing down
        uint256[] memory path = new uint256[](siblings.length + 1);
        uint256 left;
        uint256 right;
        uint8 height = uint8(siblings.length) + 1;
        while (height > 0) {
            // Record the current cursor and climb down
            path[--height] = cursor;
            if (cursor == index) {
                // On the leaf node. Stop climbing down
                break;
            } else {
                // On the parent node. Go left or right
                (left, right) = getChildren(cursor);
                cursor = index > left ? right : left;
                continue;
            }
        }

        // Calculate the summit hash climbing up again
        bytes32 node;
        while (height < path.length) {
            // Move cursor
            cursor = path[height];
            if (height == 0) {
                // cursor is on the leaf
                node = hashLeaf(cursor, value);
            } else if (cursor - 1 == path[height - 1]) {
                // cursor is on a parent and a sibling is on the left
                node = hashParent(cursor, siblings[height - 1], node);
            } else {
                // cursor is on a parent and a sibling is on the right
                node = hashParent(cursor, node, siblings[height - 1]);
            }
            // Climb up
            height++;
        }

        // Computed hash value of the summit should equal to the target peak hash
        require(node == targetPeak, "Hashed peak is invalid");
        return true;
    }

    // Hash(M | Left | Right )
    function hashParent(uint256 index, bytes32 left, bytes32 right) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, left, right));
    }

    // Hash(M | DATA )
    function hashLeaf(uint256 index, bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, data));
    }

    /**
     * It returns the height of the highest peak
     */
    function mountainHeight(uint256 size) public pure returns (uint8) {
        uint8 height = 1;
        while (uint256(1) << height <= size + height) {
            height++;
        }
        return height - 1;
    }

    /**
     * It returns the height of the index
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

    function isLeaf(uint256 index) public pure returns (bool) {
        return heightAt(index) == 1;
    }

    function getChildren(uint256 index) public pure returns (uint256 left, uint256 right) {
        left = index - (uint256(1) << (heightAt(index) - 1));
        right = index - 1;
        require(left != right, "Not a parent");
    }

    /**
     * @dev It returns all peaks of the smallest merkle mountain range tree which includes
            the given index(size)
     */
    function getPeaks(uint256 size) public pure returns (uint256[] memory peaks) {
        uint8 height = 0;
        uint256 leftPeak = 0;
        uint8 i = 0;


        // Maximum number of possible peaks is 256
        uint256[] memory tempPeaks = new uint256[](256);
        // Find peaks from the left
        while (size > leftPeak) {
            height = mountainHeight(size - leftPeak);
            leftPeak += (uint256(1) << height) - 1;
            tempPeaks[i++] = leftPeak;
        }
        // Return
        peaks = new uint256[](i);
        while (i > 0) {
            i--;
            peaks[i] = tempPeaks[i];
        }
    }

    /**
     * @dev It returns the hash value of the node for the index.
            If the hash already exists it simply returns the value, but on the other hand,
            it computes hashes recursively through downward. This computation occurs when a
            new item appended to the node
     */
    function _getOrCreateNode(Tree storage tree, uint256 index) private returns (bytes32) {
        require(index <= tree.size, "Out of range");
        if (tree.hashes[index] == bytes32(0)) {
            (uint256 leftIndex, uint256 rightIndex) = getChildren(index);
            bytes32 leftHash = _getOrCreateNode(tree, leftIndex);
            bytes32 rightHash = _getOrCreateNode(tree, rightIndex);
            tree.hashes[index] = hashParent(index, leftHash, rightHash);
        }
        return tree.hashes[index];
    }
}