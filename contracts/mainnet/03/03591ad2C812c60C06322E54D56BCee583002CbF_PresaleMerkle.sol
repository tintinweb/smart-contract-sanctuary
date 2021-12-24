// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.0;



interface IERC721Extended {
    function purchaseMultipleFor(uint256 count, address to) external payable returns (uint256 id, uint256 purchased);
    function giveawayMint(uint256 count, address to) external payable;
}

contract PresaleMerkle is Ownable {

    /**
    * Merkle based whitelist and giveaway module. Works for any IERC721Extended contract 
    * CAUTION: This approach stores data based on the MERKLE ROOTS themselves. Because of this,
    * be careful to AVOID using a previously used merkle root, as previous data could exist.
    */


    /********* WHITELIST **********/
    // mapping of contract address to merkle root
    mapping(address /* contractAddress */ => bytes32 /* merkleRoot */) whitelistMerkleRoots;
    // maximum presale items per account
    mapping(bytes32 /* merkleRoot */ => uint256 /*presaleLimit */) public whitelistLimits;
    // mapping of contract addresses to mints per addresses
    mapping(bytes32 /*merkleRoot*/ => mapping(address /* userAddress */ => uint256 /* numMinted */)) whitelistMintsPerMerkleRoot;

    /********* GIVEAWAY **********/
    // mapping of contract address to merkle root
    mapping(address /* contractAddress */ => bytes32 /* merkleRoot */) giveawayMerkleRoots;
   // maximum presale items per account
    mapping(bytes32 /* contractAddress */ => uint256 /*presaleLimit */) public giveawayLimits;
    // mapping of contract addresses to mints per addresses
    mapping(bytes32 /*merkleRoot*/ => mapping(address /* userAddress */ => uint256 /* numMinted */)) giveawayMintsPerMerkleRoot;



    constructor () {

    }

    /**
     * @dev Checks whether current account is in the whitelist
     */
    function inMerkleTree(address addr, bytes32 merkleRoot, bytes32[] memory proof) public pure returns (bool) {
        // create hash of leaf data, using target address
        bytes32 leafHash = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, merkleRoot, leafHash);
    }

    /**
     * @dev View function to check if in whitelist for contract
     */
    function inWhitelist(address user, address contractAddress, bytes32[] calldata proof) public view returns (bool) {
        bytes32 root = whitelistMerkleRoots[contractAddress];
        return inMerkleTree(user, root, proof);
    }

    /**
     * @dev View function to check remaining whitelist mints
     */
    function whitelistMintsRemaining(address user, address contractAddress, bytes32[] calldata proof) public view returns (uint256) {
        bytes32 root = whitelistMerkleRoots[contractAddress];
   
        if(inMerkleTree(user, root, proof)) {
            uint256 mintLimit = whitelistLimits[root];
            uint256 alreadyMinted = whitelistMintsPerMerkleRoot[root][user]; 
            return mintLimit - alreadyMinted;
        }
        // otherwise not in whitelist so return 0
        return 0;
    }

    /**
     * @dev View function to check if in giveaway for contract
     */
    function inGiveaway(address user, address contractAddress, bytes32[] calldata proof) public view returns (bool) {
        bytes32 root = giveawayMerkleRoots[contractAddress];
        return inMerkleTree(user, root, proof);
    }

    /**
     * @dev View function to check remaining giveaway mints
     */
    function giveawayMintsRemaining(address user, address contractAddress, bytes32[] calldata proof) public view returns (uint256) {
        bytes32 root = giveawayMerkleRoots[contractAddress];
   
        if(inMerkleTree(user, root, proof)) {
            uint256 mintLimit = giveawayLimits[root];
            uint256 alreadyMinted = giveawayMintsPerMerkleRoot[root][user];
            return mintLimit - alreadyMinted;
        }
        // otherwise not in giveaway so return 0
        return 0;
    }

    /**
     * @dev Creates whitelist based on a merkle root
     *
     */
    function setWhitelist(bytes32 merkleRoot, address contractAddress, uint256 mintLimit) public onlyOwner {
        whitelistMerkleRoots[contractAddress] = merkleRoot;
        whitelistLimits[merkleRoot] = mintLimit;
    }

    /**
     * @dev Creates giveaway list based on a merkle root
     *
     */
    function setGiveaway(bytes32 merkleRoot, address contractAddress, uint256 mintLimit) public onlyOwner {
        giveawayMerkleRoots[contractAddress] = merkleRoot;
        giveawayLimits[merkleRoot] = mintLimit;
    }

    /**
     * @dev Try to mint via whitelist
     * Checks proof against merkle tree.
     * @param to -- the address to mint the asset to. This allows for minting on someone's behalf if neccesary
     * @param contractAddress -- the target token contract to mint from
     * @param amount -- the num to mint
     * @param proof -- the merkle proof for this address
     */
    function whitelistPurchase(address to, address contractAddress, uint256 amount, bytes32[] calldata proof) external payable {
        // validate authorization via merkle proof
        bytes32 merkleRoot = whitelistMerkleRoots[contractAddress];
        require(inMerkleTree(to, merkleRoot, proof), "PresaleMerkle: Invalid address or proof!");

        // validate still remaining mints
        uint256 mintLimit = whitelistLimits[merkleRoot];
        uint256 alreadyMinted = whitelistMintsPerMerkleRoot[merkleRoot][to];
        require(alreadyMinted + amount <= mintLimit, "PresaleMerkle: Too many mints.");

        // update mints
        whitelistMintsPerMerkleRoot[merkleRoot][to] = alreadyMinted + amount;

        // mint from contract, passing along eth
        IERC721Extended tokenContract = IERC721Extended(contractAddress);
        tokenContract.purchaseMultipleFor{value: msg.value}(amount, to);
    }

    /**
     * @dev Try to mint via giveaway -- essnetially the same as whitelist, just different data stores
     * Checks proof against merkle tree.
     * @param to -- the address to mint the asset to. This allows for minting on someone's behalf if neccesary
     * @param contractAddress -- the target token contract to mint from
     * @param amount -- the num to mint
     * @param proof -- the merkle proof for this address
     */
    function giveaway(address to, address contractAddress, uint256 amount, bytes32[] calldata proof) external {
        // validate authorization via merkle proof
        bytes32 merkleRoot = giveawayMerkleRoots[contractAddress];
        require(inMerkleTree(to, merkleRoot, proof), "PresaleMerkle: Invalid address or proof!");

        // validate mints
        uint256 mintLimit = giveawayLimits[merkleRoot];
        uint256 alreadyMinted = giveawayMintsPerMerkleRoot[merkleRoot][to];
        require(alreadyMinted + amount <= mintLimit, "PresaleMerkle: Too many mints.");

        // update mints
        giveawayMintsPerMerkleRoot[merkleRoot][to] = alreadyMinted + amount;

        // ask contract for giveaway
        IERC721Extended tokenContract = IERC721Extended(contractAddress);
        tokenContract.giveawayMint(amount, to);
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