// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IPunkBodies.sol";

interface IDistributor {
    function token() external view returns(address);
    function mintReserved(address to, uint16[] memory ids) external;
    function merkleRoot() external view returns(bytes32);
    function claimed(uint256 index) external view returns(bool);
    function withdraw() external;
}

contract PBAirdropExtended is Ownable {
    address immutable distributor;
    bytes32 public immutable merkleRoot; // new merkle root
    address public immutable token;
    uint256 public immutable airdrop_deadline;

    uint256 constant total_count = 10000;
    uint256 constant airdrop_id_start = 8062; // 9999 - airdrop_count + 1

    bool[2000] private _claimed;

    event Claimed(uint256 index, address account, uint256 tokenId);

    constructor(address _distributor, uint256 deadline) {
        distributor = _distributor;
        token = IDistributor(_distributor).token();
        merkleRoot = IDistributor(_distributor).merkleRoot();
        airdrop_deadline = deadline;
    }

    function receive() external {
    }

    function claim(uint256 index, address account, bytes32[] calldata merkleProof) external {
        require(block.timestamp <= airdrop_deadline, "PBAirdropExtended: Airdrop has ended.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "PBAirdropExtended: Invalid proof.");

        // Mark it claimed and send the token.
        _claimed[index] = true;

        uint16[] memory tokenId = new uint16[](1);
        tokenId[0] = uint16(total_count - uint16(index) - 1); // 9999~ airdrop ids
        IDistributor(distributor).mintReserved(account, tokenId);

        emit Claimed(index, account, tokenId[0]);
    }

    function claimed(uint256 index) external view returns(bool) {
        return _claimed[index] || IDistributor(distributor).claimed(index);
    }

    function mintReserved(address to, uint16[] memory ids) external onlyOwner {
        if(block.timestamp <= airdrop_deadline) {
            for (uint256 i = 0; i < ids.length; i ++) {
                require(ids[i] < airdrop_id_start, "Airdrop not finished.");
            }
        }
        IDistributor(distributor).mintReserved(to, ids);
    }

    function withdraw() external onlyOwner {
        IDistributor(distributor).withdraw();
        msg.sender.transfer(address(this).balance);
    }

    function transferDistributorOwnership(address newOwner) public virtual onlyOwner {
        Ownable(distributor).transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IPunkBodies {
    function mint(address to, uint256 tokenId) external;
}

