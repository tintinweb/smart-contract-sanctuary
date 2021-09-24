pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVestable {
    function vest(address _receiver, uint256 _amount) external;
}

contract AirDrop is Ownable {
    bytes32[] public merkleRoots;
    bytes32 public pendingMerkleRoot;

    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;
    IVestable public vesting;

    event Claimed(uint256 merkleIndex, uint256 index, address account, uint256 amount);

    function setVesting(address _vesting) public onlyOwner {
        vesting = IVestable(_vesting);
    }

    function proposewMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        pendingMerkleRoot = _merkleRoot;
    }

    function reviewPendingMerkleRoot(bool _approved) public onlyOwner {
        require(pendingMerkleRoot != 0x00);
        if (_approved) {
            merkleRoots.push(pendingMerkleRoot);
        }
        delete pendingMerkleRoot;
    }

    function isClaimed(uint256 merkleIndex, uint256 index) public view returns (bool) {
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
        require(merkleIndex < merkleRoots.length, "MerkleDistributor: Invalid merkleIndex");
        require(!isClaimed(merkleIndex, index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoots[merkleIndex], node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(merkleIndex, index);
        vesting.vest(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function verifyDrop(
        uint256 merkleIndex,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        require(merkleIndex < merkleRoots.length, "MerkleDistributor: Invalid merkleIndex");
        require(!isClaimed(merkleIndex, index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        return verify(merkleProof, merkleRoots[merkleIndex], node);
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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
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
  }
}