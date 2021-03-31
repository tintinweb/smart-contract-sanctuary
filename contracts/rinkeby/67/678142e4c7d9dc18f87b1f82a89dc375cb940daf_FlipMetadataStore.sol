/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract FlipMetadataStore is Ownable {
    // Public variables

    bytes32[] public ipfsHashesInHexadecimal;
    bytes3[] public traitBytes;

    // Public constants

    uint256 public constant MAX_CELLS_SUPPLY = 9;

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
    function storeMetadata(bytes32[] memory ipfsHex) public onlyOwner{
        storeMetadataStartingAtIndex(ipfsHashesInHexadecimal.length, ipfsHex);
    }

    /*
    Store metadata starting at a particular index. In case any corrections are required before completion
    */
    function storeMetadataStartingAtIndex(uint256 startIndex, bytes32[] memory ipfsHex) public onlyOwner {
        require(startIndex <= ipfsHashesInHexadecimal.length);

        for (uint256 i = 0; i < ipfsHex.length; i++) {
            if ((i + startIndex) >= ipfsHashesInHexadecimal.length) {
                ipfsHashesInHexadecimal.push(ipfsHex[i]);
            } else {
                ipfsHashesInHexadecimal[i + startIndex] = ipfsHex[i];
            }
        }

        // Post-assertions
        require(ipfsHashesInHexadecimal.length <= MAX_CELLS_SUPPLY);
    }

    /*
    Returns the IPFS Hash in Hexadecimal format for the Hashmask image at specified position in the original hashed sequence
    */
    function getIPFSHashHexAtIndex(uint256 index) public view returns (bytes memory) {
        require(index < ipfsHashesInHexadecimal.length,
            "Metadata does not exist for the specified index");
        return abi.encodePacked(IPFS_PREFIX, ipfsHashesInHexadecimal[index]);
    }
}