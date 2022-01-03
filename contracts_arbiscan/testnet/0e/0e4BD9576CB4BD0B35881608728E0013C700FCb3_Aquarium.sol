// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);

  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);
}

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);
}

interface IData {
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;

  function addToBuildQueue(
    uint256 realmId,
    uint256 queueSlot,
    uint256 _hours
  ) external;
}

interface IResource {
  function add(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external;
}

interface IBonus {
  function amount(uint256 _realmId) external returns (uint256);
}

contract Aquarium {
  IRealm private immutable REALM;
  IManager private immutable MANAGER;
  IData private immutable DATA;
  IResource private immutable RESOURCE;
  IBonus private BONUS;

  uint256 public constant BUILD_TIME = 24 hours;

  //=======================================
  // Resource Names, IDs and bonuses
  //  Goldfish - 0
  //  Penguin - 1
  //  Otter - 2
  //  Killer Whale - 3
  //  Manta Ray (+1 Technology) - 4
  //  Giant Squid (+1 Technology) - 5
  //=======================================
  uint256[] public resourceProbability = [40, 60, 75, 85, 95, 100];
  uint256[] public resourceIds = [0, 1, 2, 3, 4, 5];

  uint256[] public metricProbability = [40, 85, 95, 100];

  mapping(uint256 => mapping(uint256 => uint256)) public aquariums;
  mapping(uint256 => uint256) public count;

  //=======================================
  // EVENTS
  //=======================================

  event Built(
    uint256 realmId,
    uint256 aquariumId,
    uint256 metricAdded,
    uint256 resourceId,
    uint256 resourceAdded,
    uint256 count
  );

  //=======================================
  // Constructor
  //=======================================

  constructor(
    address realm,
    address manager,
    address data,
    address resource,
    address bonus
  ) {
    REALM = IRealm(realm);
    MANAGER = IManager(manager);
    DATA = IData(data);
    RESOURCE = IResource(resource);
    BONUS = IBonus(bonus);
  }

  //=======================================
  // MODIFIER
  //=======================================

  modifier onlyAdmins() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  //=======================================
  // EXTERNAL
  //=======================================

  function build(uint256 _realmId, uint256 _queueSlot) external {
    address owner = REALM.ownerOf(_realmId);

    require(owner == msg.sender || REALM.isApprovedForAll(owner, msg.sender));

    DATA.addToBuildQueue(_realmId, _queueSlot, BUILD_TIME);

    _updateData(_realmId);
  }

  //=======================================
  // ADMINS
  //=======================================

  function updateBonus(address _addr) external onlyAdmins {
    BONUS = IBonus(_addr);
  }

  //=======================================
  // INTERNAL
  //=======================================

  function _updateData(uint256 _realmId) internal {
    uint256 id = count[_realmId];
    uint256 resourceId = resourceIds[_rarity(_realmId, resourceProbability)];

    uint256 metricAdded = _rarity(_realmId, metricProbability) + 1;
    uint256 resourceAdded;

    // if (resourceId > 0) {
    //   // Add resource
    //   resourceAdded = 1 + BONUS.amount(_realmId);
    //   RESOURCE.add(_realmId, resourceId, resourceAdded);

    //   if (resourceId > 3) {
    //     // Add culture bonus
    //     metricAdded = metricAdded + 1;
    //   }
    // }

    DATA.add(_realmId, 3, metricAdded);

    aquariums[_realmId][id] = resourceId;
    count[_realmId]++;

    emit Built(
      _realmId,
      id,
      metricAdded,
      resourceId,
      resourceAdded,
      count[_realmId]
    );
  }

  function _rarity(uint256 _salt, uint256[] memory probability)
    internal
    view
    returns (uint256)
  {
    uint256 rand = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
    ) % 100;

    uint256 j = 0;
    for (; j < probability.length; j++) {
      if (rand <= probability[j]) {
        break;
      }
    }
    return j;
  }
}