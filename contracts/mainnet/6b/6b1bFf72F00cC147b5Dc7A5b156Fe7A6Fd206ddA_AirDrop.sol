// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IVestable {
    function vest(address _receiver, uint256 _amount) external;
}

contract AirDrop is Ownable {
    struct DropInfo {
        bytes32 root;
        uint128 total;
        uint128 remaining;
    }

    mapping(uint256 => DropInfo) public drops;
    uint256 public tranches;

    mapping(uint256 => mapping(address => bool)) private claimed;
    IVestable public vesting;

    event LogNewDrop(uint256 trancheId, bytes32 merkleRoot, uint128 totalAmount);
    event LogClaim(address indexed account, uint256 trancheId, uint128 amount);
    event LogExpireDrop(uint256 trancheId, bytes32 merkleRoot, uint128 totalAmount, uint128 remaining);

    function setVesting(address _vesting) public onlyOwner {
        vesting = IVestable(_vesting);
    }

    function newDrop(bytes32 merkleRoot, uint128 totalAmount) external onlyOwner returns (uint256 trancheId) {
        trancheId = tranches;
        DropInfo memory di = DropInfo(merkleRoot, totalAmount, totalAmount);
        drops[trancheId] = di;
        tranches += 1;

        emit LogNewDrop(trancheId, merkleRoot, totalAmount);
    }

    function expireDrop(uint256 trancheId) external onlyOwner {
        require(trancheId < tranches, "expireDrop: !trancheId");
        DropInfo memory di = drops[trancheId];
        delete drops[trancheId];

        emit LogExpireDrop(trancheId, di.root, di.total, di.remaining);
    }

    function isClaimed(uint256 trancheId, address account) public view returns (bool) {
        return claimed[trancheId][account];
    }

    function claim(
        uint256 trancheId,
        uint128 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(trancheId < tranches, "claim: !trancheId");
        require(!isClaimed(trancheId, msg.sender), "claim: Drop already claimed");
        DropInfo storage di = drops[trancheId];
        bytes32 root = di.root;
        require(root != 0, "claim: Drop expired");
        uint128 remaining = di.remaining;
        require(amount <= remaining, "claim: Not enough remaining");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, root, node), "claim: Invalid proof");

        // Mark it claimed and send the token.
        claimed[trancheId][msg.sender] = true;
        di.remaining = remaining - amount;
        vesting.vest(msg.sender, amount);

        emit LogClaim(msg.sender, trancheId, amount);
    }

    function verifyDrop(
        uint256 trancheId,
        uint128 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        require(trancheId < tranches, "verifyDrop: !trancheId");
        require(!isClaimed(trancheId, msg.sender), "verifyDrop: Drop already claimed");
        DropInfo storage di = drops[trancheId];
        bytes32 root = di.root;
        require(root != 0, "verifyDrop: Drop expired");
        require(amount <= di.remaining, "verifyDrop: Not enough remaining");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        return MerkleProof.verify(merkleProof, root, node);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
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