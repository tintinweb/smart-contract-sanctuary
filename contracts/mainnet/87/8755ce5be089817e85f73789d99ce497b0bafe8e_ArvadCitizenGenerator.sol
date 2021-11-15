// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ArvadCrewGenerator.sol";
import "../lib/InfluenceSettings.sol";
import "../lib/Procedural.sol";


/**
 * @dev Contract which generates crew features based on the set they're part of
 */
contract ArvadCitizenGenerator is ArvadCrewGenerator, Ownable {
  using Procedural for bytes32;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  // Modifier to check if calling contract has the correct minting role
  modifier onlyManagers {
    require(isManager(_msgSender()), "ArvadCitizenGenerator: Only managers can call this function");
    _;
  }

  /**
   * @dev Sets the initial seed to allow for feature generation
   * @param _seed Random seed
   */
  function setSeed(bytes32 _seed) external onlyManagers {
    require(generatorSeed == "", "ArvadCitizenGenerator: seed already set");
    generatorSeed = InfluenceSettings.MASTER_SEED.derive(uint(_seed));
  }

  /**
   * @dev Returns the features for the specific crew member
   * @param _crewId The ERC721 tokenId for the crew member
   * @param _mod A modifier between 0 and 10,000
   */
  function getFeatures(uint _crewId, uint _mod) public view returns (uint) {
    require(generatorSeed != "", "ArvadCitizenGenerator: seed not yet set");
    uint features = 0;
    uint mod = _mod;
    bytes32 crewSeed = getCrewSeed(_crewId);
    uint sex = generateSex(crewSeed);
    features |= sex << 8; // 2 bytes
    features |= generateBody(crewSeed, sex) << 10; // 16 bytes
    uint class = generateClass(crewSeed);
    features |= class << 26; // 8 bytes
    features |= generateArvadJob(crewSeed, class, mod) << 34; // 16 bytes
    features |= generateClothes(crewSeed, class) << 50; // 16 bytes to account for color variation
    features |= generateHair(crewSeed, sex) << 66; // 16 bytes
    features |= generateFacialFeatures(crewSeed, sex) << 82; // 16 bytes
    features |= generateHairColor(crewSeed) << 98; // 8 bytes
    features |= generateHeadPiece(crewSeed, class, mod) << 106; // 8 bytes
    return features;
  }

  /**
   * @dev Add a new account / contract that can mint / burn crew members
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) external onlyOwner {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) external onlyOwner {
    _managers[_manager] = false;
  }

  /**
   * @dev Checks if an address is a manager
   * @param _manager Address of contract / account to check
   */
  function isManager(address _manager) public view returns (bool) {
    return _managers[_manager];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../lib/Procedural.sol";


/**
 * @dev Base contract for generating Arvad Crew members
 */
contract ArvadCrewGenerator {
  using Procedural for bytes32;

  bytes32 public generatorSeed;

  /**
   * @dev Returns the seed for a given crew member ID
   * @param _crewId The ERC721 tokenId for the crew member
   */
  function getCrewSeed(uint _crewId) public view returns (bytes32) {
    return generatorSeed.derive(_crewId);
  }

  /**
   * @dev Generates sex of the crew member
   * 1 = Male, 2 = Female
   * @param _seed Generator seed to derive from
   */
  function generateSex(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("sex");
    return uint(seed.getIntBetween(1, 3));
  }

  /**
   * @dev Generates body based on sex
   * @param _seed Generator seed to derive from
   * 1 - 6 = Male bodies, 7 - 12 = Female bodies
   * @param _sex The sex of the crew member
   */
  function generateBody(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("body");
    return uint(seed.getIntBetween(1, 7)) + (_sex - 1) * 6;
  }

  /**
   * @dev Generates the class based on a pre-defined distribution
   * 1 = Pilot, 2 = Engineer, 3 = Miner, 4 = Merchant, 5 = Scientist
   * @param _seed Generator seed to derive from
   */
  function generateClass(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("class");
    uint roll = uint(seed.getIntBetween(1, 10001));
    uint[5] memory classes = [ uint(703), 2770, 7122, 8837, 10000 ];

    for (uint i = 0; i < 5; i++) {
      if (roll <= classes[i]) {
        return i + 1;
      }
    }

    return 1;
  }

  /**
   * @dev Generates the job on the Arvad boosting chances based on modifier
   * @param _seed Generator seed to derive from
   * @param _class The class of the crew member
   * @param _mod Rarity modifier
   */
  function generateArvadJob(bytes32 _seed, uint _class, uint _mod) public pure returns (uint) {
    bytes32 seed = _seed.derive("arvadJobRank");

    // Generate job "rank" first
    uint[4] memory ranks = [ uint(5333), 8000, 9333, 10000 ];
    uint roll = uint(seed.getIntBetween(int128(_mod), 10001));
    uint rank = 0;

    for (uint i = 0; i < 4; i++) {
      if (roll <= ranks[i]) {
        rank = i;
        break;
      }
    }

    // Generate job based on rank and class
    uint[13][5] memory jobs;

    if (rank == 3) {
      jobs = [
        [ uint(830), 1107, 1217, 1355, 3154, 3707, 6473, 6888, 7580, 8133, 8548, 8963, 10000 ],
        [ uint(0), 0, 0, 189, 189, 943, 3208, 7736, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 0, 0, 0, 741, 2222, 4444, 4444, 4444, 4444, 10000, 10000, 10000 ],
        [ uint(0), 0, 154, 154, 798, 4402, 4659, 4659, 4659, 4659, 6203, 9678, 10000 ],
        [ uint(0), 2143, 2857, 5000, 5000, 5000, 5000, 5357, 5714, 10000, 10000, 10000, 10000 ]
      ];
    } else if (rank == 2) {
      jobs = [
        [ uint(733), 978, 1076, 1320, 3276, 3765, 6210, 6577, 7555, 8044, 8411, 8778, 10000 ],
        [ uint(0), 870, 870, 1159, 1159, 1449, 4058, 7971, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 0, 0, 0, 1125, 3625, 4875, 4875, 4875, 5875, 8125, 9813, 10000 ],
        [ uint(368), 1068, 1419, 1594, 2119, 4921, 4921, 4921, 4921, 4921, 6760, 9387, 10000 ],
        [ uint(134), 1478, 2313, 4701, 4701, 4701, 5000, 5224, 5522, 10000, 10000, 10000, 10000 ]
      ];
    } else if (rank == 1) {
      jobs = [
        [ uint(682), 2500, 2500, 2955, 5682, 5682, 7500, 7500, 8864, 8864, 8864, 8864, 10000 ],
        [ uint(295), 999, 999, 1421, 1421, 1421, 3952, 7750, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 434, 503, 503, 1631, 4059, 5620, 5880, 5880, 7268, 9089, 9740, 10000 ],
        [ uint(203), 880, 1286, 1624, 1794, 3824, 3824, 3824, 3824, 5178, 6701, 9239, 10000 ],
        [ uint(258), 688, 1720, 4731, 4731, 4731, 4731, 4731, 4946, 8387, 8387, 10000, 10000 ]
      ];
    } else {
      jobs = [
        [ uint(541), 3243, 3243, 4144, 7748, 7748, 7748, 7748, 9550, 9550, 9550, 9550, 10000 ],
        [ uint(530), 1172, 1172, 1814, 1814, 1814, 2456, 6308, 9037, 10000, 10000, 10000, 10000 ],
        [ uint(0), 514, 582, 582, 1495, 3550, 5605, 5947, 5947, 7546, 8916, 9772, 10000 ],
        [ uint(443), 1076, 1667, 2300, 2300, 3143, 3143, 3143, 3143, 4409, 5675, 8840, 10000 ],
        [ uint(0), 556, 2778, 9444, 9444, 9444, 9444, 9444, 10000, 10000, 10000, 10000, 10000 ]
      ];
    }

    seed = _seed.derive("arvadJob");
    roll = uint(seed.getIntBetween(1, 10001));

    for (uint i = 0; i < 13; i++) {
      if (roll <= jobs[_class - 1][i]) {
        return rank * 13 + i + 1;
      }
    }

    return 1;
  }

  /**
   * @dev Generates clothes based on the sex and class
   * 1-3 = Light spacesuit, 4-6 = Heavy spacesuit, 7-9 = Lab coat, 10-12 = Industrial, 12-15 = Rebel, 16-18 = Station
   * @param _seed Generator seed to derive from
   * @param _class The class of the crew member
   */
  function generateClothes(bytes32 _seed, uint _class) public pure returns (uint) {
    bytes32 seed = _seed.derive("clothes");
    uint roll = uint(seed.getIntBetween(1, 10001));
    uint outfit = 0;

    uint[6][5] memory outfits = [
      [ uint(3333), 3333, 3333, 3333, 6666, 10000 ],
      [ uint(2500), 5000, 5000, 7500, 7500, 10000 ],
      [ uint(2500), 5000, 5000, 7500, 7500, 10000 ],
      [ uint(5000), 5000, 5000, 5000, 5000, 10000 ],
      [ uint(3333), 3333, 6666, 6666, 6666, 10000 ]
    ];

    for (uint i = 0; i < 6; i++) {
      if (roll <= outfits[_class - 1][i]) {
        outfit = i;
        break;
      }
    }

    seed = _seed.derive("clothesVariation");
    roll = uint(seed.getIntBetween(1, 4));
    return (outfit * 3) + roll;
  }

  /**
   * @dev Generates hair based on the sex
   * 0 = Bald, 1 - 5 = Male hair, 6 - 11 = Female hair
   * @param _seed Generator seed to derive from
   * @param _sex The sex of the crew member
   */
  function generateHair(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("hair");
    uint style;

    if (_sex == 1) {
      style = uint(seed.getIntBetween(0, 6));
    } else {
      style = uint(seed.getIntBetween(0, 7));
    }

    if (style == 0) {
      return 0;
    } else {
      return style + (_sex - 1) * 5;
    }
  }

  /**
   * @dev Generates facial hair, piercings, scars depending on sex
   * 0 = None, 1 = Scar, 2 = Piercings, 3 - 7 = Facial hair
   * @param _seed Generator seed to derive from
   * @param _sex The sex of the crew member
   */
  function generateFacialFeatures(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("facialFeatures");
    uint feature = uint(seed.getIntBetween(0, 3));

    if (_sex == 1 && feature == 2) {
      seed = _seed.derive("facialHair");
      return uint(seed.getIntBetween(3, 8));
    } else {
      return feature;
    }
  }

  /**
   * @dev Generates hair color applied to both hair and facial hair (if applicable)
   * @param _seed Generator seed to derive from
   */
  function generateHairColor(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("hairColor");
    return uint(seed.getIntBetween(1, 6));
  }

  /**
   * @dev Generates a potential head piece based on class
   * 0 = None, 1 = Goggles, 2 = Glasses, 3 = Patch, 4 = Mask, 5 = Helmet
   * @param _seed Generator seed to derive from
   * @param _mod Modifier that increases chances of more rare items
   */
  function generateHeadPiece(bytes32 _seed, uint _class, uint _mod) public pure returns (uint) {
    bytes32 seed = _seed.derive("headPiece");
    uint roll = uint(seed.getIntBetween(int128(_mod), 10001));
    uint[6][5] memory headPieces = [
      [ uint(6667), 6667, 8445, 8889, 9778, 10000 ],
      [ uint(6667), 7619, 9524, 9524, 9524, 10000 ],
      [ uint(6667), 8572, 8572, 9524, 9524, 10000 ],
      [ uint(6667), 6667, 7778, 7778, 10000, 10000 ],
      [ uint(6667), 6667, 8572, 9048, 10000, 10000 ]
    ];

    for (uint i = 0; i < 6; i++) {
      if (roll <= headPieces[_class - 1][i]) {
        return i;
      }
    }

    return 0;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


library InfluenceSettings {

  // Game constants
  bytes32 public constant MASTER_SEED = "influence";
  uint32 public constant MAX_RADIUS = 375142; // in meters
  uint32 public constant START_TIMESTAMP = 1609459200; // Zero date timestamp for orbits
  uint public constant TOTAL_ASTEROIDS = 250000;
}

// SPDX-License-Identifier: UNLICENSED
// Portions licensed under NovakDistribute license (ref LICENSE file)
pragma solidity ^0.7.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Procedural {
  using ABDKMath64x64 for *;

  /**
   * @dev Mix string data into a hash and return a new one.
   */
  function derive(bytes32 _self, string memory _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
   * @dev Mix signed int data into a hash and return a new one.
   */
  function derive(bytes32 _self, int256 _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
  * @dev Mix unsigned int data into a hash and return a new one.
  */
  function derive(bytes32 _self, uint _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
   * @dev Returns the base pseudorandom hash for the given RandNode. Does another round of hashing
   * in case an un-encoded string was passed.
   */
  function getHash(bytes32 _self) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self));
  }

  /**
   * @dev Get an int128 full of random bits.
   */
  function getInt128(bytes32 _self) public pure returns (int128) {
    return int128(int256(getHash(_self)));
  }

  /**
   * @dev Get a 64.64 fixed point (see ABDK math) where: 0 <= return value < 1
   */
  function getReal(bytes32 _self) public pure returns (int128) {
    int128 fixedOne = int128(1 << 64);
    return getInt128(_self).abs() % fixedOne;
  }

  /**
   * @dev Get an integer between low, inclusive, and high, exclusive. Represented as a normal int, not a real.
   */
  function getIntBetween(bytes32 _self, int128 _low, int128 _high) public pure returns (int64) {
    _low = _low.fromInt();
    _high = _high.fromInt();
    int128 range = _high.sub(_low);
    int128 result = getReal(_self).mul(range).add(_low);
    return result.toInt();
  }

  /**
   * @dev Returns a normal int (roughly) normally distributed value between low and high
   */
  function getNormalIntBetween(bytes32 _self, int128 _low, int128 _high) public pure returns (int64) {
    int128 accumulator = 0;

    for (uint i = 0; i < 5; i++) {
      accumulator += getIntBetween(derive(_self, i), _low, _high);
    }

    return accumulator.fromInt().div(5.fromUInt()).toInt();
  }

  /**
   * @dev "Folds" a normal int distribution in half to generate an approx decay function
   * Only takes a high value (exclusive) as the simplistic approximation relies on low being zero
   * Returns a normal int, not a real
   */
  function getDecayingIntBelow(bytes32 _self, uint _high) public pure returns (int64) {
    require(_high < uint(1 << 64));
    int64 normalInt = getNormalIntBetween(_self, 0, int128(_high * 2 - 1));
    int128 adjusted = int128(normalInt) - int128(_high);
    return adjusted.fromInt().abs().toInt();
  }
}

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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov 
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    bool negative = x < 0 && y & 1 == 1;

    uint256 absX = uint128 (x < 0 ? -x : x);
    uint256 absResult;
    absResult = 0x100000000000000000000000000000000;

    if (absX <= 0x10000000000000000) {
      absX <<= 63;
      while (y != 0) {
        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x2 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x4 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x8 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        y >>= 4;
      }

      absResult >>= 64;
    } else {
      uint256 absXShift = 63;
      if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
      if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
      if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
      if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
      if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
      if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

      uint256 resultShift = 0;
      while (y != 0) {
        require (absXShift < 64);

        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
          resultShift += absXShift;
          if (absResult > 0x100000000000000000000000000000000) {
            absResult >>= 1;
            resultShift += 1;
          }
        }
        absX = absX * absX >> 127;
        absXShift <<= 1;
        if (absX >= 0x100000000000000000000000000000000) {
            absX >>= 1;
            absXShift += 1;
        }

        y >>= 1;
      }

      require (resultShift < 64);
      absResult >>= 64 - resultShift;
    }
    int256 result = negative ? -int256 (absResult) : int256 (absResult);
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}

