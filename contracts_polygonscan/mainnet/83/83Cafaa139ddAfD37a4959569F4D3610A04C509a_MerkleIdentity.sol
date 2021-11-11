/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IVoterID {
    /**
        Minting function
    */
    function createIdentityFor(address newId, uint tokenId, string memory uri) external;

    /**
        Who's in charge around here
    */
    function owner() external view returns (address);

    /**
        How many of these things exist?
    */
    function totalSupply() external view returns (uint);
}

interface IPriceGate {

    function getCost(uint) external view returns (uint ethCost);

    function passThruGate(uint, address) external payable;
}


interface IEligibility {
    
    function isEligible(uint, address, bytes32[] memory) external view returns (bool eligible);

    function passThruGate(uint, address, bytes32[] memory) external;
}


library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}


contract MerkleIdentity {
    using MerkleLib for bytes32;

    struct MerkleTree {
        bytes32 metadataMerkleRoot;
        bytes32 ipfsHash;
        address nftAddress;
        address priceGateAddress;
        address eligibilityAddress;
        uint eligibilityIndex; // enables re-use of eligibility contracts
        uint priceIndex; // enables re-use of price gate contracts
    }

    mapping (uint => MerkleTree) public merkleTrees;
    uint public numTrees;

    address public management;
    address public treeAdder;

    event MerkleTreeAdded(uint indexed index, address indexed nftAddress);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address _mgmt) {
        management = _mgmt;
        treeAdder = _mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    function setTreeAdder(address newAdder) external managementOnly {
        treeAdder = newAdder;
    }

    function setIpfsHash(uint merkleIndex, bytes32 hash) external managementOnly {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        tree.ipfsHash = hash;
    }

    function addMerkleTree(bytes32 metadataMerkleRoot, bytes32 ipfsHash, address nftAddress, address priceGateAddress, address eligibilityAddress, uint eligibilityIndex, uint priceIndex) external {
        require(msg.sender == treeAdder, 'Only treeAdder can add trees');
        MerkleTree storage tree = merkleTrees[++numTrees];
        tree.metadataMerkleRoot = metadataMerkleRoot;
        tree.ipfsHash = ipfsHash;
        tree.nftAddress = nftAddress;
        tree.priceGateAddress = priceGateAddress;
        tree.eligibilityAddress = eligibilityAddress;
        tree.eligibilityIndex = eligibilityIndex;
        tree.priceIndex = priceIndex;
        emit MerkleTreeAdded(numTrees, nftAddress);
    }

    function withdraw(uint merkleIndex, uint tokenId, string memory uri, bytes32[] memory addressProof, bytes32[] memory metadataProof) external payable {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        IVoterID id = IVoterID(tree.nftAddress);

        // mint an identity first, this keeps the token-collision gas cost down
        id.createIdentityFor(msg.sender, tokenId, uri);

        // check that the merkle index is real
        require(merkleIndex <= numTrees, 'merkleIndex out of range');

        // verify that the metadata is real
        require(verifyMetadata(tree.metadataMerkleRoot, tokenId, uri, metadataProof), "The metadata proof could not be verified");

        // check eligibility of address
        IEligibility(tree.eligibilityAddress).passThruGate(tree.eligibilityIndex, msg.sender, addressProof);

        // check that the price is right
        IPriceGate(tree.priceGateAddress).passThruGate{value: msg.value}(tree.priceIndex, msg.sender);

    }

    function getPrice(uint merkleIndex) public view returns (uint) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        uint ethCost = IPriceGate(tree.priceGateAddress).getCost(tree.priceIndex);
        return ethCost;
    }

    function isEligible(uint merkleIndex, address recipient, bytes32[] memory proof) public view returns (bool) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        return IEligibility(tree.eligibilityAddress).isEligible(tree.eligibilityIndex, recipient, proof);
    }

    function verifyMetadata(bytes32 root, uint tokenId, string memory uri, bytes32[] memory proof) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encode(tokenId, uri));
        return root.verifyProof(leaf, proof);
    }

}