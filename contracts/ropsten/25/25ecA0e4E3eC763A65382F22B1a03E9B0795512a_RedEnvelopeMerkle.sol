// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IEnvelope.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RedEnvelopeMerkle is IEnvelope, Ownable {
    using Bits for uint8;

    mapping(string => MerkleEnvelope) private idToEnvelopes;

    function returnEnvelope(string calldata envelopeID) public onlyOwner {
        MerkleEnvelope storage env = idToEnvelopes[envelopeID];
        require(env.balance > 0, "Balance should be larger than zero");
        require(env.creator == msg.sender, "We will only return to the creator!");
        address payable receiver = payable(env.creator);
        receiver.call{value: env.balance}("");
    }

    function addEnvelope(
        string calldata envelopeID,
        uint16 numParticipants,
        uint256 minPerOpen,
        bytes32 hashedMerkelRoot,
        uint32 bitarraySize
    ) payable public {
        require(idToEnvelopes[envelopeID].balance == 0, "balance not zero");
        require(msg.value > 0, "Trying to create zero balance envelope");
        validateMinPerOpen(msg.value, minPerOpen, numParticipants);

        MerkleEnvelope storage envelope = idToEnvelopes[envelopeID];
        envelope.minPerOpen = minPerOpen;
        envelope.numParticipants = numParticipants;
        envelope.creator = msg.sender;
        envelope.unclaimedPasswords = hashedMerkelRoot;
        envelope.balance = msg.value;
        envelope.isPasswordClaimed = new uint8[](bitarraySize/8 + 1);
    }


    function openEnvelope(
        address payable receiver,
        string calldata envelopeID,
        bytes32[] memory proof,
        bytes32 leaf
    ) public {
        require(idToEnvelopes[envelopeID].balance > 0, "Envelope cannot be empty");
        MerkleEnvelope storage currentEnv = idToEnvelopes[envelopeID];

        // First check if the password has been claimed
        uint256 bitarrayLen = currentEnv.isPasswordClaimed.length;
        uint32 idx = uint32(uint256(leaf) % bitarrayLen);
        uint32 bitsetIdx = idx / 8;
        uint8 positionInBitset = uint8(idx % 8);
        uint8 curBitSet = currentEnv.isPasswordClaimed[bitsetIdx];
        uint8 contains = curBitSet.bit(positionInBitset);
        require(contains == 0, "password already used!");

        // Now check if it is a valid password
        bool isUnclaimed = MerkleProof.verify(proof, currentEnv.unclaimedPasswords, leaf);
        require(isUnclaimed, "password need to be valid!");

        // claim the password
        currentEnv.isPasswordClaimed[bitsetIdx].setBit(positionInBitset);

        // currently withdrawl the full balance, turn this into something either true random or psuedorandom
        if (currentEnv.numParticipants == 1) {
            receiver.call{value: currentEnv.balance}("");
            currentEnv.balance = 0;
            return;
        }

        uint256 moneyThisOpen = getMoneyThisOpen(
            receiver,
            currentEnv.balance,
            currentEnv.minPerOpen,
            currentEnv.numParticipants);
        
        currentEnv.numParticipants--;
        receiver.call{value: moneyThisOpen}("");
        currentEnv.balance -= moneyThisOpen;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// Move the last element to the deleted spot.
// Remove the last element.
function _burn(uint256[] storage array, uint32 index) {
  require(index < array.length);
  array[index] = array[array.length-1];
  array.pop();
}

library Bits {

    uint constant internal ONE = uint(1);
    // uint8 constant internal ONES = uint8(~0);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint self, uint8 index) internal pure returns (uint) {
        return self | ONE << index;
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint self, uint8 index) internal pure returns (uint) {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint self, uint8 index) internal pure returns (uint) {
        return self ^ ONE << index;
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint self, uint8 index) internal pure returns (uint8) {
        return uint8(self >> index & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint self, uint8 index) internal pure returns (bool) {
        return self >> index & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(uint self, uint other, uint8 index) internal pure returns (bool) {
        return (self ^ other) >> index & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - (self >> index & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self & other) >> index & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self | other) >> index & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self ^ other) >> index & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    // function bits(uint self, uint8 startIndex, uint16 numBits) internal pure returns (uint) {
    //     require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
    //     return self >> startIndex & ONES >> 256 - numBits;
    // }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (ONE << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (ONE << i) - 1 == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }

}

contract IEnvelope {

  struct Status {
      bool initialized;
      bool claimed;
  }
  
  struct Envelope {
      uint256 balance;
      uint256 minPerOpen;
      address creator;
      mapping(uint256 => Status) passwords;
      uint16 numParticipants;
      uint8 passLength;
  }

  struct MerkleEnvelope {
      uint256 balance;
      uint256 minPerOpen;
      // we need a Merkle roots, to
      // keep track of claimed passwords, 
      bytes32 unclaimedPasswords;
      // we will keep a bitset for used passwords
      uint8[] isPasswordClaimed;
      address creator;
      uint16 numParticipants;
  }

  struct MerkleEnvelopeERC721 {
      // we need a Merkle roots, to
      // keep track of claimed passwords, 
      bytes32 unclaimedPasswords;
      // we will keep a bitset for used passwords
      uint8[] isPasswordClaimed;
      address creator;
      uint16 numParticipants;
      address tokenAddress;
      uint256[] tokenIDs;
  }

  function initStatus() public pure returns(Status memory) {
    Status memory envStatus;
    envStatus.initialized = true;
    envStatus.claimed = false;
    return envStatus;
  }

  function hashPassword(string memory unhashedPassword) public pure returns(uint64) {
    uint64 MAX_INT = 2**64 - 1;
    uint256 password = uint256(keccak256(abi.encodePacked(unhashedPassword)));
    uint64 passInt64 = uint64(password % MAX_INT);
    return passInt64;
  }

  function validateMinPerOpen(uint256 envBalance, uint256 minPerOpen, uint16 numParticipants) internal pure {
    require(envBalance >= minPerOpen * numParticipants, "Everyone should be able to get min!");
  }

  function getMoneyThisOpen(
    address receiver,
    uint256 envBalance,
    uint256 minPerOpen,
    uint16 numParticipants
  ) public view returns (uint256) {
    // calculate the money open amount. We calculate a rand < 1k, then
    // max * rand1k / 1k
    // we generate a psuedorandom number. The cast here is basicalluy the same as mod
    // https://ethereum.stackexchange.com/questions/100029/how-is-uint8-calculated-from-a-uint256-conversion-in-solidity
    uint16 rand = uint16(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, receiver))));
    uint16 rand1K = rand % 1000;
    uint256 randBalance = envBalance - minPerOpen * numParticipants;
    // We need to be careful with overflow here if the balance is huge. It needs to be 1k less than max.
    uint256 maxThisOpen = randBalance / 2;
    uint256 moneyThisOpen = (maxThisOpen * rand1K / 1000) + minPerOpen;
    return moneyThisOpen;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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