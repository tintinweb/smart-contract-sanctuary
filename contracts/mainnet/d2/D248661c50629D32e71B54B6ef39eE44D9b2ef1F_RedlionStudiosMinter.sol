pragma solidity ^0.8.0;

import "./IRedlionStudios.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface ERC1155 {
    function burn(address _owner, uint256 _id, uint256 _value) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract RedlionStudiosMinter is Ownable {

    using BitMaps for BitMaps.BitMap;

    struct Sale {
        uint128 onSale;
        uint128 price;
        bytes32 merkleRoot;
    }

    IRedlionStudios public studios;

    uint public limitPerBuy = 5;

    mapping (uint => Sale) public sales; // publication => sale mapping
    mapping (address => BitMaps.BitMap) private _claimedAirdrop;

    constructor(address _studios) {
        studios = IRedlionStudios(_studios);
    }

    function withdraw(address recipient) onlyOwner public {
        uint amount = address(this).balance;
        payable(recipient).transfer(amount);
    }

    function setOnSale(uint256 publication, uint128 onSale) onlyOwner public {
        sales[publication].onSale = onSale;
    }

    function setMintingPrice(uint256 publication, uint128 price) onlyOwner public {
        sales[publication].price = price;
    }

    function setMerkleAirdrop(uint256 publication, bytes32 root) onlyOwner public {
        sales[publication].merkleRoot = root;
    }

    function createNewSale(uint256 publication, uint128 onSale, uint128 price, bytes32 root) onlyOwner public {
        sales[publication] = Sale(onSale, price, root);
    }

    function setLimitPerBuy(uint limit) onlyOwner public {
        limitPerBuy = limit;
    }

    function claim(uint256 publication, bytes32[] calldata proof, uint256 amount) public {
        require(!_claimedAirdrop[msg.sender].get(publication), "ALREADY CLAIMED FOR PUBLICATION");
        _claimedAirdrop[msg.sender].set(publication);
        require(MerkleProof.verify(proof, sales[publication].merkleRoot, keccak256(abi.encodePacked(msg.sender, amount))), "INVALID PROOF");
        studios.mint(publication, uint128(amount), msg.sender);
    }
    
    function purchase(uint publication, uint128 amount) public payable {
        require(msg.value == sales[publication].price * amount, "INCORRECT MSG.VALUE");
        require(amount <= limitPerBuy, "OVER LIMIT");
        sales[publication].onSale -= amount;
        studios.mint(publication, amount, msg.sender);
    }

    function mintGenesis() public {
        ERC1155 rewards = ERC1155(0x0Aa3850C4e084402D68F47b0209f222041093915);
        uint256 balance0 = rewards.balanceOf(msg.sender, 10003);
        uint256 balance1 = rewards.balanceOf(msg.sender, 10002);
        require(balance0 > 0 || balance1 > 0, "Nothing to burn");
        //burn token in user's stead
        if (balance0 > 0) rewards.burn(msg.sender, 10003, balance0);
        if (balance1 > 0) rewards.burn(msg.sender, 10002, balance1);
        studios.mint(0, uint128(balance0+balance1), msg.sender);

    }

    function isAirdropClaimed(address user, uint publication) public view returns (bool) {
        return _claimedAirdrop[user].get(publication);
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

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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

pragma solidity ^0.8.0;

interface IRedlionStudios {
    function mint(uint publication, uint128 amount, address to) external;
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

