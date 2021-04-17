pragma solidity ^0.8.3;

import './OwnableUpgradeable.sol';

contract BDU_Network_Ledger is OwnableUpgradeable{

  address public manager;

  modifier onlyManager {
      require(msg.sender==manager, "Must be Network Manager");
      _;
  }

  struct community {
      string name;
      string hash;
      address manager;
      bool active;
  }

  community[] public communities;

  uint public memberCount = 0;

  uint public activeMemberCount;

  function initialize() public initializer {
    __Ownable_init();
  }

  function setManager(address newManager) public onlyManager{
    manager = newManager;
  }

  function addCommunity(string memory name, string memory hash, address communityManager,bool active) public onlyManager{
    communities.push(community(name,hash,communityManager,active));
    memberCount++;
    if(active){
        activeMemberCount++;
    }
  }

  function activateCommunity(uint id) public onlyManager{
    require(communities[id].active == false,"Community is already active");
    communities[id].active = true;
    activeMemberCount++;
  }

  function deactiveateCommunity(uint id) public onlyManager{
    require(communities[id].active == true,"Community is already inactive");
    communities[id].active = false;
    activeMemberCount--;
  }

  function updateCommunityInfo(uint id,string memory name, string memory hash, address communityManager) public{
    require(msg.sender==manager || msg.sender==communities[id].manager);
    communities[id].name = name;
    communities[id].hash = hash;
    communities[id].manager = communityManager;
  }
}