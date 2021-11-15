// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// import "hardhat/console.sol";

contract StorageMonkey {
    /// @dev Used to store the hex hash of a base58 encoded IPFS hash.
    /// e.g QmPZ9gcCEpqKTo6aq61g2nXGUhM4iCL3ewB6LDXZCtioEB
    ///  0x12 |  20 | 120f6af601d46e10b2d2e11ed71c55d25f3042c22501e41d1246e7a1e9d3d8ec
    struct Multihash {
        bytes1 hashFunction;
        bytes1 hashLength;
        bytes32 digest;
    }

    /// @dev Will map addreses to IPFS hashes.
    /// @notice IPFS hahses are base58 encodes and are 48 bytes long.
    ///         e.g. QmPqFe8Z8oPjG8j2LgyYro1fSHNNnFYfdDiKHD3SJWsnEU
    /// https://ethereum.stackexchange.com/questions/17094/how-to-store-ipfs-hash-using-bytes32
    mapping(address => Multihash) public hashes;

    modifier storageExists(address _address) {
        require(hashes[_address].digest != bytes32(0), "No entry exists for address.");
        _;
    }

    modifier onlyOwner(address _address) {
        require(msg.sender == _address, "Only owner of address can set hash.");
        _;
    }

    event HashUpdated(address indexed _address);
    event HashDeleted(address indexed _address);

    /// @dev Read hash associated with address. Reverts if hash does not exist.
    function getStorage(address _address) external view storageExists(_address) returns (Multihash memory) {
        return hashes[_address];
    }

    /// @dev Update hash associated with address.
    function setStorage(address _address, Multihash calldata _hash) external onlyOwner(_address) {
        hashes[_address] = _hash;
        emit HashUpdated(_address);
    }

    /// @dev Deletes hash associated with address. Reverts if no addres sis set.
    function deleteStorage(address _address) external storageExists(_address) onlyOwner(_address) {
        delete hashes[_address];
        emit HashDeleted(_address);
    }

    /// @dev Returns true if address already maps to hash, false otherwise.
    function isValidStorage(address _address) external view returns (bool) {
        return hashes[_address].digest != bytes32(0) ? true : false;
    }
}

