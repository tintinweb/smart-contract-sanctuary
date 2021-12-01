// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IVault {
    function setUserAllowance(address _user, uint256 _amount) external;
}

/// notice Airdrop contract for the stand alone vault
///     Provided merkleRoot will allow users to make an allowance claim against
///     the Gro Labs stand alone vaults - one drop allows to claim the same amount against all
///     available vaults, subsequent drops will allow the user to add to their current allowance.
///     Note that the airdrops in this contract wont be normalized to any specific token, and its
///     the sVaults responsibility to correctly translate the amount to the correct decimal, e.g.:
///         Aridrop for user 1: 10000
///         Claim against daiVault will result in an allowance of 10000 * 1E18
///         Claim against usdcVault will result in an allowance of 10000 * 1E6
///         etc...
contract Bouncer is Ownable {

    bytes32 public root;
    mapping(address => bool) public vaults;
    mapping(uint256 => address) public testVaults;
    mapping(address => mapping(address => uint128)) public claimed;

    uint256 public numberOfVaults;

    event LogNewDrop(bytes32 merkleRoot);
    event LogClaim(address indexed account, address indexed vault, uint128 amount);
    event LogVaultStatus(address indexed vault, bool status);

    function addVault(address _vault, bool _status) public onlyOwner {
        vaults[_vault] = _status;
        if (_status) {
            testVaults[numberOfVaults] = _vault;
            numberOfVaults += 1;
        }
        emit LogVaultStatus(_vault, _status);
    }

    function newDrop(bytes32 merkleRoot) external onlyOwner {
        root = merkleRoot;
        emit LogNewDrop(merkleRoot);
    }

    function getClaimed(address vault, address account) public view returns (uint128) {
        return claimed[vault][account];
    }

    function claim(
        uint128 amount,
        address _vault,
        bytes32[] calldata merkleProof
    ) external {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, root, node), "claim: Invalid proof");
        uint128 _claimed = getClaimed(_vault, msg.sender);
        require( _claimed < amount , "claim: full allowance already claimed");
        uint128 _amount = amount - _claimed;

        // Mark it claimed and send the token.
        IVault(_vault).setUserAllowance(msg.sender, _amount);
        claimed[_vault][msg.sender] = amount;

        emit LogClaim(msg.sender, _vault, _amount);
    }

    function verifyDrop(
        uint128 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
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