// File: @openzeppelin/contracts/cryptography/MerkleProof.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// File: contracts/Mintable.sol

pragma solidity =0.6.11;

interface Mintable {
    function setTokenId(uint256 id, bytes32 sig) external;
    function mint(address account, uint256 id, uint256 amount) external;
}

// File: contracts/Minter.sol

pragma solidity =0.6.11;




contract Minter is Ownable {
    event Claimed(
        uint256 index,
        bytes32 sig,
        address account,
        uint256 count
    );

    bytes32 public immutable merkleRoot;

    Mintable public mintable;

    mapping(uint256 => bool) public claimed;

    uint256 public nextId = 1;
    mapping(bytes32 => uint256) public sigToTokenId;

    constructor(bytes32 _merkleRoot) public {
        merkleRoot = _merkleRoot;
    }

    function setMintable(Mintable _mintable) public onlyOwner {
        require(address(mintable) == address(0), "Minter: Can't set Mintable contract twice");
        mintable = _mintable;
    }

    function merkleVerify(bytes32 node, bytes32[] memory proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, node);
    }

    function makeNode(
        uint256 index,
        bytes32 sig,
        address account,
        uint256 count
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, sig, account, count));
    }

    function claim(
        uint256 index,
        bytes32 sig,
        address account,
        uint256 count,
        bytes32[] memory proof
    ) public {
        require(address(mintable) != address(0), "Minter: Must have a mintable set");

        require(!claimed[index], "Minter: Can't claim a drop that's already been claimed");
        claimed[index] = true;

        bytes32 node = makeNode(index, sig, account, count);
        require(merkleVerify(node, proof), "Minter: merkle verification failed");

        uint256 id = sigToTokenId[sig];
        if (id == 0) {
            sigToTokenId[sig] = nextId;
            mintable.setTokenId(nextId, sig);
            id = nextId;

            nextId++;
        }

        mintable.mint(account, id, count);

        emit Claimed(index, sig, account, count);
    }
}