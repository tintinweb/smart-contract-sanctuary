pragma solidity ^0.7.0;

import "./Ownable.sol";

contract MasksMetadataStore is Ownable {
    // Public variables

    bytes32[] public ipfsHashesInHexadecimal;
    bytes3[] public traitBytes;

    // Public constants

    uint256 public constant MAX_MASKS_SUPPLY = 16384;

    // IPFS CID is generated using default options of the IPFS node version specified in the variable below
    string public constant IPFS_VERSION = "go-ipfs 0.8.0"; // Version of IPFS node used. For reproducibility.
    bytes2 public constant IPFS_PREFIX = 0x1220; // Multihash function: SHA2-256 Hashing algorithm
    string public constant IPFS_CHUNKER = "size-262144"; // IPFS Chunker used: size-262144
    uint256 public constant IPFS_CID_VERSION = 0; // IPFS CID Version: v0
    bool public constant IPFS_RAW_LEAVES_FLAG = false; // IPFS Raw leaves option flag: Set to false
    string public constant IPFS_DAG_FORMAT = "Merkle DAG"; // IPFS DAG: Merkle DAG by default

    /*
    Store Metadata comprising of IPFS Hashes (In Hexadecimal minus the first two fixed bytes) and explicit traits
    Ordered according to original hashed sequence pertaining to the Hashmasks provenance
    Ownership is intended to be burned (Renounced) after storage is completed
    */
    function storeMetadata(bytes32[] memory ipfsHex, bytes3[] memory traitsHex)
        public
        onlyOwner
    {
        storeMetadataStartingAtIndex(
            ipfsHashesInHexadecimal.length,
            ipfsHex,
            traitsHex
        );
    }

    /*
    Store metadata starting at a particular index. In case any corrections are required before completion
    */
    function storeMetadataStartingAtIndex(
        uint256 startIndex,
        bytes32[] memory ipfsHex,
        bytes3[] memory traitsHex
    ) public onlyOwner {
        require(startIndex <= ipfsHashesInHexadecimal.length);
        require(
            ipfsHex.length == traitsHex.length,
            "Arrays must be equal in length"
        );

        for (uint256 i = 0; i < ipfsHex.length; i++) {
            if ((i + startIndex) >= ipfsHashesInHexadecimal.length) {
                ipfsHashesInHexadecimal.push(ipfsHex[i]);
                traitBytes.push(traitsHex[i]);
            } else {
                ipfsHashesInHexadecimal[i + startIndex] = ipfsHex[i];
                traitBytes[i + startIndex] = traitsHex[i];
            }
        }

        // Post-assertions
        require(ipfsHashesInHexadecimal.length <= MAX_MASKS_SUPPLY);
        require(traitBytes.length <= MAX_MASKS_SUPPLY);
    }

    /*
    Returns the IPFS Hash in Hexadecimal format for the Hashmask image at specified position in the original hashed sequence
    */
    function getIPFSHashHexAtIndex(uint256 index)
        public
        view
        returns (bytes memory)
    {
        require(
            index < ipfsHashesInHexadecimal.length,
            "Metadata does not exist for the specified index"
        );
        return abi.encodePacked(IPFS_PREFIX, ipfsHashesInHexadecimal[index]);
    }

    /*
    Returns the trait bytes for the Hashmask image at specified position in the original hashed sequence
    */
    function getTraitBytesAtIndex(uint256 index) public view returns (bytes3) {
        require(
            index < traitBytes.length,
            "Metadata does not exist for the specified index"
        );
        return traitBytes[index];
    }
}