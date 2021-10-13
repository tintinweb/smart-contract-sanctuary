/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// hevm: flattened sources of src/MerkleMint.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

////// lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol

/* pragma solidity ^0.8.0; */

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

////// src/MerkleMint.sol
/* pragma solidity ^0.8.0; */

/* import "@openzeppelin/contracts/access/Ownable.sol"; */
/* import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; */
/* import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; */

interface IERC1155_2 {
    function mint(address, uint256, uint256) external;
    function totalSupply(uint256) external view returns (uint256);
}

contract MerkleMint is Ownable, ReentrancyGuard {
    IERC1155_2 public immutable token;
    uint256 public immutable id;
    bytes32 public immutable merkleRootPresale;
    bytes32 public immutable merkleRoot;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant START = 1634140800;
    uint256 public constant MAX = 2949;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMapPresale;
    mapping(uint256 => uint256) private claimedBitMap;

    event Minted(uint256 index, address account, uint256 amount);

    constructor(
        address _token,
        uint256 _id,
        bytes32 _merkleRoot,
        bytes32 _merkleRootPresale
    ) {
        token = IERC1155_2(_token);
        id = _id;
        merkleRoot = _merkleRoot;
        merkleRootPresale = _merkleRootPresale;
    }

    function amountLeft() public view returns(uint256) {
        return MAX - token.totalSupply(id);
    }

    function isMintedPresale(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMapPresale[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setMintedPresale(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMapPresale[claimedWordIndex] =
            claimedBitMapPresale[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function isMinted(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setMinted(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function mintPresale(
        uint256 amount,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant() {
        require(block.timestamp > START, "too soon");
        require(msg.value == amount * PRICE, "wrong price");
        require(!isMintedPresale(index), "already minted");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRootPresale, node),
            "invalid proof"
        );

        // Mark it claimed and send the token.
        _setMintedPresale(index);
        _mint(account, amount, index);
    }

    function mint(
        uint256 amount,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant() {
        require(amount < 6, "too many");
        require(!isMinted(index), "already minted");
        require(block.timestamp > START + 1 days, "too soon");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, uint256(1)));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "invalid proof"
        );

        // Mark it claimed and send the token.
        _setMinted(index);
        _mint(account, amount, index);
    }

    function mintLeftover(uint256 amount) external payable nonReentrant() {
        require(block.timestamp > START + 2 days, "too soon");
        _mint(msg.sender, amount, 99999);
    }

    function _mint(address to, uint256 amount, uint256 index) internal {
        require(amount <= amountLeft(), "too many");
        require(msg.value == amount * PRICE, "wrong price");
        token.mint(to, id, amount);
        emit Minted(index, msg.sender, amount);
    }

    function devMint(uint256 amount) external onlyOwner {
        token.mint(owner(), id, amount);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}