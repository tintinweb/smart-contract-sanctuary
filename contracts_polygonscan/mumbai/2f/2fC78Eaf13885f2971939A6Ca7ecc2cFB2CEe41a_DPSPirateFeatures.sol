//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DPSPirateFeatures is Ownable {
  bytes32 public merkleRoot;
  string public merkleLink;

  string[] private traitsNames;
  string[] private skillsNames;

  mapping(uint16 => string[8]) traitsPerPirate;
  mapping(uint16 => uint16[3]) skillsPerPirate;

  constructor() {
    traitsNames = ["Uniform", "Hat", "Peg Leg", "Feathers", "Eyes", "Earring", "Beak", "Background"];
    skillsNames = ["Luck", "Navigation", "Strength"];
  }

  /**
   * @dev initialize in batches
   */
  function initialSkillsAndTraitsBatch(
    bytes32[] calldata _leafs,
    bytes32[][] calldata _merkleProofs,
    uint16[] calldata _dpsIds,
    string[][] calldata _traits,
    uint16[][] calldata _skills
  ) external onlyOwner {
    for (uint256 i = 0; i < _leafs.length; i++) {
      initialSkillsAndTraits(_leafs[i], _merkleProofs[i], _dpsIds[i], _traits[i], _skills[i]);
    }
  }

  function initialSkillsAndTraits(
    bytes32 _leaf,
    bytes32[] calldata _merkleProof,
    uint16 _dpsId,
    string[] calldata _traits,
    uint16[] calldata _skills
  ) internal {
    string memory concatenatedTraits = string(
      abi.encodePacked(
        string(abi.encodePacked(_traits[0], _traits[1], _traits[2], _traits[3], _traits[4], _traits[5])),
        _traits[6],
        _traits[7]
      )
    );

    string memory concatenatedSkills = string(
      abi.encodePacked(Strings.toString(_skills[0]), Strings.toString(_skills[1]), Strings.toString(_skills[2]))
    );
    bytes32 node = keccak256(abi.encodePacked(_dpsId, concatenatedTraits, concatenatedSkills));

    require(node == _leaf, "Leaf not matching the node");
    require(MerkleProof.verify(_merkleProof, merkleRoot, _leaf), "Invalid proof.");

    string[8] memory traits;
    traits[0] = _traits[0];
    traits[1] = _traits[1];
    traits[2] = _traits[2];
    traits[3] = _traits[3];
    traits[4] = _traits[4];
    traits[5] = _traits[5];
    traits[6] = _traits[6];
    traits[7] = _traits[7];

    uint16[3] memory skills;
    skills[0] = _skills[0];
    skills[1] = _skills[1];
    skills[2] = _skills[2];
    traitsPerPirate[_dpsId] = traits;
    skillsPerPirate[_dpsId] = skills;
  }

  function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory) {
    return (traitsPerPirate[_dpsId], skillsPerPirate[_dpsId]);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMerkleTreeLink(string calldata _link) external onlyOwner {
    merkleLink = _link;
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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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