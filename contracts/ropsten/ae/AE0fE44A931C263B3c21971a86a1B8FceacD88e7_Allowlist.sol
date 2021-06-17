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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "../interfaces/IAllowlist.sol";

/**
 * @title Allowlist
 * @notice This contract is a registry holding information about how much each swap contract should
 * contain upto. Swap.sol will rely on this contract to determine whether the pool cap is reached and
 * also whether a user's deposit limit is reached.
 */
contract Allowlist is Ownable, IAllowlist {
    using SafeMath for uint256;

    // Represents the root node of merkle tree containing a list of eligible addresses
    bytes32 public merkleRoot;
    // Maps pool address -> maximum total supply
    mapping(address => uint256) private poolCaps;
    // Maps pool address -> maximum amount of pool token mintable per account
    mapping(address => uint256) private accountLimits;
    // Maps account address -> boolean value indicating whether it has been checked and verified against the merkle tree
    mapping(address => bool) private verified;

    event PoolCap(address indexed poolAddress, uint256 poolCap);
    event PoolAccountLimit(address indexed poolAddress, uint256 accountLimit);
    event NewMerkleRoot(bytes32 merkleRoot);

    /**
     * @notice Creates this contract and sets the PoolCap of 0x0 with uint256(0x54dd1e) for
     * crude checking whether an address holds this contract.
     * @param merkleRoot_ bytes32 that represent a merkle root node. This is generated off chain with the list of
     * qualifying addresses.
     */
    constructor(bytes32 merkleRoot_) public {
        merkleRoot = merkleRoot_;

        // This value will be used as a way of crude checking whether an address holds this Allowlist contract
        // Value 0x54dd1e has no inherent meaning other than it is arbitrary value that checks for
        // user error.
        poolCaps[address(0x0)] = uint256(0x54dd1e);
        emit PoolCap(address(0x0), uint256(0x54dd1e));
        emit NewMerkleRoot(merkleRoot_);
    }

    /**
     * @notice Returns the max mintable amount of the lp token per account in given pool address.
     * @param poolAddress address of the pool
     * @return max mintable amount of the lp token per account
     */
    function getPoolAccountLimit(address poolAddress)
        external
        view
        override
        returns (uint256)
    {
        return accountLimits[poolAddress];
    }

    /**
     * @notice Returns the maximum total supply of the pool token for the given pool address.
     * @param poolAddress address of the pool
     */
    function getPoolCap(address poolAddress)
        external
        view
        override
        returns (uint256)
    {
        return poolCaps[poolAddress];
    }

    /**
     * @notice Returns true if the given account's existence has been verified against any of the past or
     * the present merkle tree. Note that if it has been verified in the past, this function will return true
     * even if the current merkle tree does not contain the account.
     * @param account the address to check if it has been verified
     * @return a boolean value representing whether the account has been verified in the past or the present merkle tree
     */
    function isAccountVerified(address account) external view returns (bool) {
        return verified[account];
    }

    /**
     * @notice Checks the existence of keccak256(account) as a node in the merkle tree inferred by the merkle root node
     * stored in this contract. Pools should use this function to check if the given address qualifies for depositing.
     * If the given account has already been verified with the correct merkleProof, this function will return true when
     * merkleProof is empty. The verified status will be overwritten if the previously verified user calls this function
     * with an incorrect merkleProof.
     * @param account address to confirm its existence in the merkle tree
     * @param merkleProof data that is used to prove the existence of given parameters. This is generated
     * during the creation of the merkle tree. Users should retrieve this data off-chain.
     * @return a boolean value that corresponds to whether the address with the proof has been verified in the past
     * or if they exist in the current merkle tree.
     */
    function verifyAddress(address account, bytes32[] calldata merkleProof)
        external
        override
        returns (bool)
    {
        if (merkleProof.length != 0) {
            // Verify the account exists in the merkle tree via the MerkleProof library
            bytes32 node = keccak256(abi.encodePacked(account));
            if (MerkleProof.verify(merkleProof, merkleRoot, node)) {
                verified[account] = true;
                return true;
            }
        }
        return verified[account];
    }

    // ADMIN FUNCTIONS

    /**
     * @notice Sets the account limit of allowed deposit amounts for the given pool
     * @param poolAddress address of the pool
     * @param accountLimit the max number of the pool token a single user can mint
     */
    function setPoolAccountLimit(address poolAddress, uint256 accountLimit)
        external
        onlyOwner
    {
        require(poolAddress != address(0x0), "0x0 is not a pool address");
        accountLimits[poolAddress] = accountLimit;
        emit PoolAccountLimit(poolAddress, accountLimit);
    }

    /**
     * @notice Sets the max total supply of LPToken for the given pool address
     * @param poolAddress address of the pool
     * @param poolCap the max total supply of the pool token
     */
    function setPoolCap(address poolAddress, uint256 poolCap)
        external
        onlyOwner
    {
        require(poolAddress != address(0x0), "0x0 is not a pool address");
        poolCaps[poolAddress] = poolCap;
        emit PoolCap(poolAddress, poolCap);
    }

    /**
     * @notice Updates the merkle root that is stored in this contract. This can only be called by
     * the owner. If more addresses are added to the list, a new merkle tree and a merkle root node should be generated,
     * and merkleRoot should be updated accordingly.
     * @param merkleRoot_ a new merkle root node that contains a list of deposit allowed addresses
     */
    function updateMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        emit NewMerkleRoot(merkleRoot_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAllowlist {
    function getPoolAccountLimit(address poolAddress)
        external
        view
        returns (uint256);

    function getPoolCap(address poolAddress) external view returns (uint256);

    function verifyAddress(address account, bytes32[] calldata merkleProof)
        external
        returns (bool);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "remappings": [],
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