// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUtility.sol";

contract Utilitybia {
  string public constant name = "Utilitybia V2";

  event StoreUpdated(address store);
  event UtilityAdded(uint256 index, address indexed utility);

  address implementation_;
  address public owner;

  bool public initialized;

  address public store;
  address[] public utilities;

  function initialize() external {
    require(msg.sender == owner);
    require(!initialized);
    initialized = true;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setStore(address _store) external onlyOwner {
    store = _store;
    emit StoreUpdated(_store);
  }

  function totalUtilities() external view returns (uint256 total) {
    total = utilities.length;
  }

  function registerUtility(address utility) external onlyOwner {
    require(IUtility(utility).factory() == address(this));
    uint256 utilityIndex = utilities.length;
    IUtility(utility).setIndex(utilityIndex);
    utilities.push(utility);
    emit UtilityAdded(utilityIndex, utility);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUtility {
  function factory() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function isPublic(uint256 tokenId) external view returns (bool);

  function setIndex(uint256 index) external;
}