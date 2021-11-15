// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;


interface IEthMap {
  function buyZone(uint zoneId) external payable returns (bool success);
  function sellZone(uint zoneId, uint amount) external returns (bool success);
  function transferZone(uint zoneId, address recipient) external returns (bool success);
  function computeInitialPrice(uint zoneId) external view returns (uint price);
  function getZone(uint zoneId) external view returns (uint id, address owner, uint sellPrice);
  function getBalance() external view returns (uint amount);
  function withdraw() external returns (bool success);
  function transferContractOwnership(address newOwner) external returns (bool success);
}


contract ZoneMap {
  IEthMap public constant map = IEthMap(0xB6bbf89c3DbBa20Cb4d5cABAa4A386ACbbAb455e);

  struct Zone {
    uint id;
    address owner;
    uint sellPrice;
  }

  function getAllZones() external view returns (Zone[] memory zones) {
    zones = new Zone[](178);
    for (uint256 i; i < 178; i++) {
      (uint id, address owner, uint sellPrice) = map.getZone(i);
      zones[i] = Zone(id, owner, sellPrice);
    }
  }

  function getZonesForSale() external view returns (Zone[] memory zones) {
    zones = new Zone[](178);
    uint256 n;
    for (uint256 i; i < 178; i++) {
      (uint id, address owner, uint sellPrice) = map.getZone(i + 1);
      if (sellPrice > 0) {
        zones[n++] = Zone(id, owner, sellPrice);
      }
    }
    assembly { mstore(zones, n) }
  }
}

