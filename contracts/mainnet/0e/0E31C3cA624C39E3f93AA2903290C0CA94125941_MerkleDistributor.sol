/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface IERC20Mintable {
    function mint(address _receiver, uint256 _amount) external returns (bool);
}

contract MerkleDistributor {
    bytes32[] public merkleRoots;

    event Claimed(
        uint256 merkleIndex,
        uint256 index,
        address account,
        uint256 amount
    );
    event NewMerkleRoot(uint256 merkleIndex, bytes32 root);

    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    address public owner;
    IERC20Mintable public token;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, IERC20Mintable _token) public {
        owner = _owner;
        token = _token;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function addMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoots.push(_merkleRoot);
        emit NewMerkleRoot(merkleRoots.length - 1, _merkleRoot);
    }

    function isClaimed(uint256 merkleIndex, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 merkleIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleIndex][claimedWordIndex] =
            claimedBitMap[merkleIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 merkleIndex,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(
            merkleIndex < merkleRoots.length,
            "MerkleDistributor: Invalid merkleIndex"
        );
        require(
            !isClaimed(merkleIndex, index),
            "MerkleDistributor: Drop already claimed."
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(
            verify(merkleProof, merkleRoots[merkleIndex], node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(merkleIndex, index);
        token.mint(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}