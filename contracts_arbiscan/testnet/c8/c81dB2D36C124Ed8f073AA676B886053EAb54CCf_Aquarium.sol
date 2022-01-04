// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
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

contract Aquarium {
  IRealm private immutable REALM;
  IManager private immutable MANAGER;
  IData private immutable DATA;
  IResource private immutable RESOURCE;

  uint256 public constant BUILD_TIME = 24 hours;

  string[11] public resourceNames = [
    "None",
    "Goldfish",
    "Clownfish",
    "Emperor Penguin",
    "Sea Otter",
    "Sea Turtle",
    "Lion's Mane Jellyfish",
    "Great White Shark",
    "Orca",
    "Manta Ray",
    "Giant Squid"
  ];
  uint256[] public resourceProbability = [
    40,
    52,
    62,
    72,
    77,
    82,
    87,
    91,
    94,
    97,
    100
  ];
  uint256[] public resourceIds = [0, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

  uint256[] public metricProbability = [40, 85, 95, 100];

  mapping(uint256 => uint256) public count;

  //=======================================
  // EVENTS
  //=======================================

  event Built(
    uint256 realmId,
    uint256 aquariumId,
    uint256 resourceId,
    string resourceName,
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
    address resource
  ) {
    REALM = IRealm(realm);
    MANAGER = IManager(manager);
    DATA = IData(data);
    RESOURCE = IResource(resource);
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
  // INTERNAL
  //=======================================

  function _updateData(uint256 _realmId) internal {
    uint256 id = count[_realmId];
    uint256 rarity = _rarity(_realmId, resourceProbability);
    uint256 resourceId = resourceIds[rarity];
    uint256 metricAdded = _rarity(_realmId, metricProbability) + 1;
    uint256 resourceAdded;

    if (rarity > 0) {
      if (rarity > 8) {
        metricAdded = metricAdded + 1;
      }

      RESOURCE.add(_realmId, resourceId, metricAdded);
      resourceAdded = metricAdded;
    }

    DATA.add(_realmId, 3, metricAdded);

    count[_realmId]++;

    emit Built(
      _realmId,
      id,
      resourceId,
      resourceNames[rarity],
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