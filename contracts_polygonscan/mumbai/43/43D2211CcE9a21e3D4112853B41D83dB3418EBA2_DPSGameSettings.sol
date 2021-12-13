//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/DPSStructs.sol";

contract DPSGameSettings is Ownable {
  mapping(VOYAGE_TYPE => CartographerConfig) public voyageConfigPerType;
  mapping(FLAGSHIP_PART => uint16) public skillsPerFlagshipPart;
  mapping(uint8 => FLAGSHIP_PART[]) public partsForEachSkillType;
  uint16 public flagshipBaseSkills;
  uint16 public blockJumps;
  uint16 public maxPointsCap = 750;
  mapping(VOYAGE_TYPE => uint256) tmapPerVoyage;

  constructor() {
    voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfChests = 2;
    voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfChests = 4;
    voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfStorms = 1;
    voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfStorms = 2;
    voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfEnemies = 1;
    voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfEnemies = 2;
    voyageConfigPerType[VOYAGE_TYPE.EASY].totalInteractions = 6;
    voyageConfigPerType[VOYAGE_TYPE.EASY].gapBetweenInteractions = 3600;

    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfChests = 4;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfChests = 6;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfStorms = 3;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfStorms = 4;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfEnemies = 3;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfEnemies = 4;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].totalInteractions = 12;
    voyageConfigPerType[VOYAGE_TYPE.MEDIUM].gapBetweenInteractions = 3600;

    voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfChests = 6;
    voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfChests = 8;
    voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfStorms = 5;
    voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfStorms = 6;
    voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfEnemies = 5;
    voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfEnemies = 6;
    voyageConfigPerType[VOYAGE_TYPE.HARD].totalInteractions = 18;
    voyageConfigPerType[VOYAGE_TYPE.HARD].gapBetweenInteractions = 3600;

    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfChests = 8;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfChests = 12;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfStorms = 7;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfStorms = 8;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfEnemies = 7;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfEnemies = 8;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].totalInteractions = 24;
    voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].gapBetweenInteractions = 3600;

    skillsPerFlagshipPart[FLAGSHIP_PART.CANNON] = 5;
    skillsPerFlagshipPart[FLAGSHIP_PART.HULL] = 5;
    skillsPerFlagshipPart[FLAGSHIP_PART.SAILS] = 5;
    skillsPerFlagshipPart[FLAGSHIP_PART.HELM] = 5;
    skillsPerFlagshipPart[FLAGSHIP_PART.FLAG] = 5;
    skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD] = 5;

    flagshipBaseSkills = 250;

    partsForEachSkillType[uint8(SKILL_TYPE.LUCK)] = [FLAGSHIP_PART.FLAG, FLAGSHIP_PART.FIGUREHEAD];
    partsForEachSkillType[uint8(SKILL_TYPE.NAVIGATION)] = [FLAGSHIP_PART.SAILS, FLAGSHIP_PART.HELM];
    partsForEachSkillType[uint8(SKILL_TYPE.STRENGTH)] = [FLAGSHIP_PART.CANNON, FLAGSHIP_PART.HULL];

    tmapPerVoyage[VOYAGE_TYPE.EASY] = 1 * 1e18;
    tmapPerVoyage[VOYAGE_TYPE.MEDIUM] = 2 * 1e18;
    tmapPerVoyage[VOYAGE_TYPE.HARD] = 3 * 1e18;
    tmapPerVoyage[VOYAGE_TYPE.LEGENDARY] = 4 * 1e18;

    blockJumps = 5;
  }

  function setVoyageConfig(CartographerConfig calldata config, VOYAGE_TYPE _type) external onlyOwner {
    voyageConfigPerType[_type] = config;
  }

  function setTmapPerVoyage(VOYAGE_TYPE _type, uint256 _amount) external onlyOwner {
    tmapPerVoyage[_type] = _amount;
  }

  function setVoyageConfigPerType(VOYAGE_TYPE _type, CartographerConfig calldata _config) external onlyOwner {
    voyageConfigPerType[_type].minNoOfChests = _config.minNoOfChests;
    voyageConfigPerType[_type].maxNoOfChests = _config.maxNoOfChests;
    voyageConfigPerType[_type].minNoOfStorms = _config.minNoOfStorms;
    voyageConfigPerType[_type].maxNoOfStorms = _config.maxNoOfStorms;
    voyageConfigPerType[_type].minNoOfEnemies = _config.minNoOfEnemies;
    voyageConfigPerType[_type].maxNoOfEnemies = _config.maxNoOfEnemies;
    voyageConfigPerType[_type].totalInteractions = _config.totalInteractions;
    voyageConfigPerType[_type].gapBetweenInteractions = _config.gapBetweenInteractions;
  }

  function setSkillsPerFlagshipPart(FLAGSHIP_PART _part, uint16 _amount) external onlyOwner {
    skillsPerFlagshipPart[_part] = _amount;
  }

  function setBlockJumps(uint16 _jumps) external onlyOwner {
    blockJumps = _jumps;
  }

  function getVoyageConfig(VOYAGE_TYPE _type) external view returns (CartographerConfig memory) {
    return voyageConfigPerType[_type];
  }

  function getMaxPointsCap() external view returns (uint16) {
    return maxPointsCap;
  }

  function getBlockJumps() external view returns (uint16) {
    return blockJumps;
  }

  function getFlagshipBaseSkills() external view returns (uint16) {
    return flagshipBaseSkills;
  }

  function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes) {
    for (uint8 i = 0; i < 3; i++) {
      for (uint8 j = 0; j < partsForEachSkillType[i].length; j++) {
        skillTypes[uint256(partsForEachSkillType[i][j])] = i;
      }
    }
  }

  function getTMAPPerVoyageType(VOYAGE_TYPE _type) external view returns (uint256) {
    return tmapPerVoyage[_type];
  }

  function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills) {
    skills[uint256(FLAGSHIP_PART.CANNON)] = skillsPerFlagshipPart[FLAGSHIP_PART.CANNON];
    skills[uint256(FLAGSHIP_PART.HULL)] = skillsPerFlagshipPart[FLAGSHIP_PART.HULL];
    skills[uint256(FLAGSHIP_PART.SAILS)] = skillsPerFlagshipPart[FLAGSHIP_PART.SAILS];
    skills[uint256(FLAGSHIP_PART.HELM)] = skillsPerFlagshipPart[FLAGSHIP_PART.HELM];
    skills[uint256(FLAGSHIP_PART.FLAG)] = skillsPerFlagshipPart[FLAGSHIP_PART.FLAG];
    skills[uint256(FLAGSHIP_PART.FIGUREHEAD)] = skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum VOYAGE_TYPE {
  EASY,
  MEDIUM,
  HARD,
  LEGENDARY
}

enum SUPPORT_SHIP_TYPE {
  SLOOP_STRENGTH,
  SLOOP_LUCK,
  SLOOP_NAVIGATION,
  CARAVEL_STRENGTH,
  CARAVEL_LUCK,
  CARAVEL_NAVIGATION,
  GALLEON_STRENGTH,
  GALLEON_LUCK,
  GALLEON_NAVIGATION
}

enum INTERACTION {
  NONE,
  CHEST,
  STORM,
  ENEMY
}

enum FLAGSHIP_PART {
  HEALTH,
  CANNON,
  HULL,
  SAILS,
  HELM,
  FLAG,
  FIGUREHEAD
}

enum SKILL_TYPE {
  LUCK,
  STRENGTH,
  NAVIGATION
}

struct VoyageConfig {
  VOYAGE_TYPE typeOfVoyage;
  uint8 noOfInteractions;
  uint16 noOfBlockJumps;
  // 1 - Chest 2 - Storm 3 - Enemy
  uint8[] sequence;
  uint256 boughtAt;
  uint256 gapBetweenInteractions;
}

struct CartographerConfig {
  uint8 minNoOfChests;
  uint8 maxNoOfChests;
  uint8 minNoOfStorms;
  uint8 maxNoOfStorms;
  uint8 minNoOfEnemies;
  uint8 maxNoOfEnemies;
  uint8 totalInteractions;
  uint256 gapBetweenInteractions;
}

struct RandomInteractions {
  uint256 randomNoOfChests;
  uint256 randomNoOfStorms;
  uint256 randomNoOfEnemies;
  uint8 generatedChests;
  uint8 generatedStorms;
  uint8 generatedEnemies;
  uint256[] positionsForGeneratingInteractions;
}

struct CausalityParams {
  address _address;
  uint256[] _blockNumber;
  bytes32[] _hash1;
  bytes32[] _hash2;
  uint256[] _timestamp;
  bytes[] _signature;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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