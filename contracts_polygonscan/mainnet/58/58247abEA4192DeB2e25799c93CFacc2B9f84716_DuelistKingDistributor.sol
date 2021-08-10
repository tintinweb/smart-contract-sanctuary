/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

// Dependency file: contracts/dk/DuelistKingItem.sol

// SPDX-License-Identifier: Apache-2.0

// pragma solidity >=0.8.4 <0.9.0;

/**
 * Item of Duelist King
 * Name: Item
 * Domain: Duelist King
 */
library DuelistKingItem {
  // We have 256 bits to store an item's id so we dicide to contain as much as posible data
  // Application      64  bits    We can't control this, it will be assigned by DKDAO

  // Edition:         16  bits    For now, 0-Standard edition 0xffff-Creator edition
  // Generation:      16  bits    Generation of item, now it's Gen 0
  // Rareness:        16  bits    1-C, 2-U, 3-R, 4-SR, 5-SSR, 6-L
  // Type:            16  bits    0-Card, 1-Loot Box
  // Id:              64  bits    Increasement value that unique for each item
  // Serial:          64  bits    Increasement value that count the number of items
  // 256         192         176             160            144         128       64            0 
  //  |application|  edition  |  generation   |   rareness   |   type    |   id    |   seiral   |
  function set(
    uint256 value,
    uint256 shift,
    uint256 mask,
    uint256 newValue
  ) internal pure returns (uint256 result) {
    require((mask | newValue) ^ mask == 0, 'Card: New value is out range');
    assembly {
      result := and(value, not(shl(shift, mask)))
      result := or(shl(shift, newValue), result)
    }
  }

  function get(
    uint256 value,
    uint256 shift,
    uint256 mask
  ) internal pure returns (uint256 result) {
    assembly {
      result := shr(shift, and(value, shl(shift, mask)))
    }
  }

  function setSerial(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 0, 0xffffffffffffffff, b);
  }

  function getSerial(uint256 a) internal pure returns (uint256 c) {
    return get(a, 0, 0xffffffffffffffff);
  }

  function setId(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 64, 0xffffffffffffffff, b);
  }

  function getId(uint256 a) internal pure returns (uint256 c) {
    return get(a, 64, 0xffffffffffffffff);
  }

  function setType(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 128, 0xffff, b);
  }

  function getType(uint256 a) internal pure returns (uint256 c) {
    return get(a, 128, 0xffff);
  }

  function setRareness(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 144, 0xffff, b);
  }

  function getRareness(uint256 a) internal pure returns (uint256 c) {
    return get(a, 144, 0xffff);
  }

  function setGeneration(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 160, 0xffff, b);
  }

  function getGeneration(uint256 a) internal pure returns (uint256 c) {
    return get(a, 160, 0xffff);
  }

  function setEdition(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return set(a, 176, 0xffff, b);
  }

  function getEdition(uint256 a) internal pure returns (uint256 c) {
    return get(a, 176, 0xffff);
  }
}

// Dependency file: contracts/interfaces/IRNGConsumer.sol

// pragma solidity >=0.8.4 <0.9.0;

interface IRNGConsumer {
  function compute(bytes memory data) external returns (bool);
}


// Dependency file: contracts/interfaces/IRegistry.sol

// pragma solidity >=0.8.4 <0.9.0;

interface IRegistry {
  event Registered(bytes32 domain, bytes32 indexed name, address indexed addr);

  function isExistRecord(bytes32 domain, bytes32 name) external view returns (bool);

  function set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) external returns (bool);

  function batchSet(
    bytes32[] calldata domains,
    bytes32[] calldata names,
    address[] calldata addrs
  ) external returns (bool);

  function getAddress(bytes32 domain, bytes32 name) external view returns (address);

  function getDomainAndName(address addr) external view returns (bytes32, bytes32);
}


// Dependency file: contracts/libraries/User.sol

// pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/interfaces/IRegistry.sol';

abstract contract User {
  // Registry contract
  IRegistry internal registry;

  // Active domain
  bytes32 internal domain;

  // Allow same domain calls
  modifier onlyAllowSameDomain(bytes32 name) {
    require(msg.sender == registry.getAddress(domain, name), 'User: Only allow call from same domain');
    _;
  }

  // Allow cross domain call
  modifier onlyAllowCrossDomain(bytes32 fromDomain, bytes32 name) {
    require(msg.sender == registry.getAddress(fromDomain, name), 'User: Only allow call from allowed cross domain');
    _;
  }

  // Constructing with registry address and its active domain
  function _init(address _registry, bytes32 _domain) internal returns (bool) {
    require(domain == bytes32(0) && address(registry) == address(0), "User: It's only able to set once");
    registry = IRegistry(_registry);
    domain = _domain;
    return true;
  }

  // Get address in the same domain
  function getAddressSameDomain(bytes32 name) internal view returns (address) {
    return registry.getAddress(domain, name);
  }

  // Return active domain
  function getDomain() external view returns (bytes32) {
    return domain;
  }

  // Return registry address
  function getRegistry() external view returns (address) {
    return address(registry);
  }
}


// Dependency file: contracts/libraries/Bytes.sol

// pragma solidity >=0.8.4 <0.9.0;

library Bytes {
  // Convert bytes to bytes32[]
  function toBytes32Array(bytes memory input) internal pure returns (bytes32[] memory) {
    require(input.length % 32 == 0, 'Bytes: invalid data length should divied by 32');
    bytes32[] memory result = new bytes32[](input.length / 32);
    assembly {
      // Read length of data from offset
      let length := mload(input)

      // Seek offset to the beginning
      let offset := add(input, 0x20)

      // Next is size of chunk
      let resultOffset := add(result, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 0x20)
      } {
        mstore(resultOffset, mload(add(offset, i)))
        resultOffset := add(resultOffset, 0x20)
      }
    }
    return result;
  }

  // Read address from input bytes buffer
  function readAddress(bytes memory input, uint256 offset) internal pure returns (address result) {
    require(offset + 20 <= input.length, 'Bytes: Our of range, can not read address from bytes');
    assembly {
      result := shr(96, mload(add(add(input, 0x20), offset)))
    }
  }

  // Read uint256 from input bytes buffer
  function readUint256(bytes memory input, uint256 offset) internal pure returns (uint256 result) {
    require(offset + 32 <= input.length, 'Bytes: Our of range, can not read uint256 from bytes');
    assembly {
      result := mload(add(add(input, 0x20), offset))
    }
  }

  // Read bytes from input bytes buffer
  function readBytes(
    bytes memory input,
    uint256 offset,
    uint256 length
  ) internal pure returns (bytes memory) {
    require(offset + length <= input.length, 'Bytes: Our of range, can not read bytes from bytes');
    bytes memory result = new bytes(length);
    assembly {
      // Seek offset to the beginning
      let seek := add(add(input, 0x20), offset)

      // Next is size of data
      let resultOffset := add(result, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 0x20)
      } {
        mstore(add(resultOffset, i), mload(add(seek, i)))
      }
    }
    return result;
  }
}


// Dependency file: contracts/interfaces/ITheDivine.sol

// pragma solidity >=0.8.4 <0.9.0;

interface ITheDivine {
  function rand() external returns (uint256);
}


// Dependency file: contracts/interfaces/INFT.sol

// pragma solidity >=0.8.4 <0.9.0;

interface INFT {
  function init(
    string memory name_,
    string memory symbol_,
    address registry,
    bytes32 domain
  ) external returns (bool);

  function mint(address to, uint256 tokenId) external returns (bool);
}


// Dependency file: contracts/interfaces/IPress.sol

// pragma solidity >=0.8.4 <0.9.0;

interface IPress {
  function newNFT(
    bytes32 _domain,
    string calldata name,
    string calldata symbol
  ) external returns (address);

  function createItem(
    bytes32 _domain,
    address _owner,
    uint256 _itemId
  ) external returns (bool);
}


// Root file: contracts/dk/DuelistKingDistributor.sol


pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/dk/DuelistKingItem.sol';
// import 'contracts/interfaces/IRNGConsumer.sol';
// import 'contracts/libraries/User.sol';
// import 'contracts/libraries/Bytes.sol';
// import 'contracts/interfaces/ITheDivine.sol';
// import 'contracts/interfaces/INFT.sol';
// import 'contracts/interfaces/IPress.sol';

/**
 * Card distributor
 * Name: Distributor
 * Domain: Duelist King
 */
contract DuelistKingDistributor is User, IRNGConsumer {
  // Using Bytes for bytes
  using Bytes for bytes;

  // Using Duelist King Card for uint256
  using DuelistKingItem for uint256;

  // Number of seiral
  uint256 private serial;

  // Campaign index
  uint256 campaignIndex;

  // The Divine
  ITheDivine private immutable theDivine;

  // Maping genesis
  mapping(uint256 => uint256) genesisEdition;

  // Entropy data
  uint256 private entropy;

  // Campaign structure
  struct Campaign {
    // Total number of issued card
    uint64 opened;
    // Soft cap of card distribution
    uint64 softCap;
    // Deadline of timestamp
    uint64 deadline;
    // Generation
    uint64 generation;
    // Start card Id
    uint64 start;
    // Start end card Id
    uint64 end;
    // Card distribution
    uint256[] distribution;
  }

  // Campaign storage
  mapping(uint256 => Campaign) private campaignStorage;

  // New campaign
  event NewCampaign(uint256 indexed campaginId, uint256 indexed generation, uint64 indexed softcap);

  constructor(
    address _registry,
    bytes32 _domain,
    address divine
  ) {
    _init(_registry, _domain);
    theDivine = ITheDivine(divine);
  }

  // Create new campaign
  function newCampaign(Campaign memory campaign) external onlyAllowSameDomain('Oracle') returns (uint256) {
    // Overwrite start with number of unique design
    // and then increase unique design to new card
    // To make sure card id won't be duplicated
    // Auto assign generation
    campaignIndex += 1;
    campaignStorage[campaignIndex] = campaign;
    emit NewCampaign(campaignIndex, campaign.generation, campaign.softCap);
    return campaignIndex;
  }

  // Compute random value from RNG
  function compute(bytes memory data)
    external
    override
    onlyAllowCrossDomain('DKDAO Infrastructure', 'RNG')
    returns (bool)
  {
    require(data.length == 32, 'Distributor: Data must be 32 in length');
    // We combine random value with The Divine's result to prevent manipulation
    // https://github.com/chiro-hiro/thedivine
    entropy ^= uint256(data.readUint256(0)) ^ theDivine.rand();
    return true;
  }

  // Calcualte card
  function caculateCard(Campaign memory currentCampaign, uint256 luckyNumber) private pure returns (uint256) {
    uint256 luckyDraw = luckyNumber % (currentCampaign.softCap * 5);
    for (uint256 i = 0; i < currentCampaign.distribution.length; i += 1) {
      uint256 t = currentCampaign.distribution[i];
      uint256 rEnd = t & 0xffffffff;
      uint256 rStart = (t >> 32) & 0xffffffff;
      uint256 rareness = (t >> 64) & 0xffffffff;
      uint256 cardStart = (t >> 96) & 0xffffffff;
      uint256 cardFactor = (t >> 128) & 0xffffffff;
      if (luckyDraw >= rStart && luckyDraw <= rEnd) {
        // Return card Id
        return uint256(0).setRareness(rareness).setId(currentCampaign.start + cardStart + (luckyNumber % cardFactor));
      }
    }
    return 0;
  }

  // Open loot boxes
  function openBox(
    uint256 campaignId,
    address owner,
    uint256 numberOfBoxes
  ) external onlyAllowSameDomain('Oracle') returns (bool) {
    require(
      numberOfBoxes <= 10,
      'Distributor: Invalid number of loot boxes'
    );
    IPress infrastructurePress = IPress(registry.getAddress('DKDAO Infrastructure', 'Press'));
    require(campaignId > 0 && campaignId <= campaignIndex, 'Distributor: Invalid campaign Id');
    Campaign memory currentCampaign = campaignStorage[campaignId];
    currentCampaign.opened += uint64(numberOfBoxes);
    // Set deadline if softcap is reached
    if (currentCampaign.deadline > 0) {
      require(block.timestamp > currentCampaign.deadline, 'Distributor: Card sale is over');
    }
    if (currentCampaign.deadline == 0 && currentCampaign.opened > currentCampaign.softCap) {
      currentCampaign.deadline = uint64(block.timestamp + 3 days);
    }
    uint256 rand = uint256(keccak256(abi.encodePacked(entropy, owner)));
    uint256 boughtCards = numberOfBoxes * 5;
    uint256 luckyNumber;
    uint256 card = uint256(0).setGeneration(currentCampaign.generation);
    uint256 cardSerial = serial;
    for (uint256 i = 0; i < boughtCards; ) {
      // Repeat hash on its selft
      rand = uint256(keccak256(abi.encodePacked(rand)));
      for (uint256 j = 0; j < 256 && i < boughtCards; j += 32) {
        luckyNumber = (rand >> j) & 0xffffffff;
        // Draw card by lucky number
        card = caculateCard(currentCampaign, luckyNumber);
        if (card > 0) {
          cardSerial += 1;
          infrastructurePress.createItem(domain, owner, card.setSerial(cardSerial));
          i += 1;
        }
      }
    }
    serial = cardSerial;
    campaignStorage[campaignId] = currentCampaign;
    // Update old random with new one
    entropy = rand;
    return true;
  }

  // Issue genesis edition for card creator
  function issueGenesisEdittion(address owner, uint256 id) public onlyAllowSameDomain('Oracle') returns (bool) {
    // This card is genesis edittion
    uint256 card = uint256(0x0000000000000000ffff00000000000000000000000000000000000000000000).setId(id);
    require(genesisEdition[card] == 0, 'Distributor: Only one genesis edition will be distributed');
    serial += 1;
    uint256 issueCard = card.setSerial(serial);
    genesisEdition[card] = issueCard;
    IPress(registry.getAddress('DKDAO Infrastructure', 'Press')).createItem(domain, owner, issueCard);
    return true;
  }

  // Read campaign storage of a given campaign index
  function getCampaignIndex() external view returns (uint256) {
    return campaignIndex;
  }

  // Read campaign storage of a given campaign index
  function getCampaign(uint256 index) external view returns (Campaign memory) {
    return campaignStorage[index];
  }
}