// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BlucamonAirdrop {
  constructor() {}

  struct EggDetail {
    uint8 rarity;
    uint8 element;
  }

  mapping(address => EggDetail) airdropWhitelist;
  address[] whitelistAddresses;

  function setEggDetail(uint8 _rarity, uint8 _element) internal pure returns (EggDetail memory) {
    return EggDetail(_rarity, _element);
  }

  function setEachWhitelist(address _address, uint8 _rarity, uint8 _element) external {
    EggDetail memory eggDetail = setEggDetail(_rarity, _element);
    airdropWhitelist[_address] = eggDetail;
    whitelistAddresses.push(_address);
  }

  function setWhitelist(address[] memory addresses, uint8[] memory rarities, uint8[] memory elements) external {
    require(addresses.length <= 1000);
    for (uint i = 0; i < addresses.length; i++) {
      EggDetail memory eggDetail = setEggDetail(rarities[i], elements[i]);
      airdropWhitelist[addresses[i]] = eggDetail;
      whitelistAddresses.push(addresses[i]);
    }
  }

  function getWhitelist() external view returns (address[] memory) {
    return whitelistAddresses;
  }
}

