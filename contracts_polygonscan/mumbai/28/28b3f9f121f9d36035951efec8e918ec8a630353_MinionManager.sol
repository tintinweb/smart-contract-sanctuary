/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: UNLICENSED




// @title Minion Manager
// @dev Contract for managing minions for other contracts in the GAME ecosystem
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iMinionManager {

  function isMinion(address _account) virtual external view returns(bool);
  function isWorker(address _account) virtual external view returns(bool);
  function isWorkerOrMinion(address _account) virtual external view returns(bool);

  function getMinionGroup(bytes32 groupId) virtual external view returns(address[] memory);
  function addMinionGroup(bytes32 groupId, address[] calldata minionList) virtual external;
  function removeMinionGroup(bytes32 groupId) virtual external;

  function assignWorker(address _worker, bool _isWorker) virtual external returns(bool);

  function isMinionManager()
    external
    pure
  returns(bool) {
    return true;
  }
}



// @title iGAME_Master
// @dev The interface for the Master contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iGAME_Master {
  function isOwner(address _owner) virtual external view returns (bool);
  function isCFO(address _cfo) virtual external view returns (bool);
  function isCOO(address _coo) virtual external view returns (bool);
  function isWorker(address _account) virtual external view returns (bool);
  function isWorkerOrMinion(address _account) virtual external view returns (bool);
  function makeFundedCall(address _account) virtual external returns (bool);

  function isMaster()
    external
    pure
  returns(bool) {
    return true;
  }
}

// @title Minion Manager
// @dev Contract for managing minions for other contracts in the GAME ecosystem
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
contract MinionManager is iMinionManager {

  iGAME_Master public masterContract;

  mapping(address => bool) public workers;
  mapping(address => bool) public minions;
  mapping(bytes32 => address[]) public minionGroups;
  mapping(bytes32 => bool) public minionGroupIds;



  constructor(address _masterContract)
  {
    masterContract = iGAME_Master(_masterContract);
    require(masterContract.isMaster(), "_masterContract must implement isMaster()");
  }

  modifier onlyMaster() {
    // Cannot be called using native meta-transactions
    require(address(masterContract) == msg.sender, "sender must be the master contract");
    _;
  }

  function isMinion(address _account)
    external
    override
    view
  returns(bool) {
    return minions[_account];
  }

  function isWorker(address _account)
    external
    override
    view
  returns(bool) {
    return workers[_account];
  }

  function isWorkerOrMinion(address _account)
    external
    override
    view
  returns(bool) {
    return workers[_account] || minions[_account];
  }

  function getMinionGroup(bytes32 groupId)
    external
    override
    view
  returns(address[] memory) {
    return minionGroups[groupId];
  }

  function addMinionGroup(bytes32 groupId, address[] calldata minionList)
    external
    override
    onlyMaster
  {
    require(minionGroupIds[groupId] == false, "groupId can't be recorded");
    require(minionList.length > 0, "must be at least one minion");
    minionGroupIds[groupId] = true;
    minionGroups[groupId] = minionList;
    for(uint i = 0; i < minionList.length; i++) {
      require(minions[minionList[i]] == false, "minion must not exist");
      minions[minionList[i]] = true;
    }
  }

  function removeMinionGroup(bytes32 groupId)
    external
    override
    onlyMaster
  {
    require(minionGroupIds[groupId] == true, "groupId must exist");
    address[] storage minionList = minionGroups[groupId];
    for(uint i = 0; i < minionList.length; i++) {
      minions[minionList[i]] = true;
    }
    delete minionGroups[groupId];
    minionGroupIds[groupId] = false;
  }

  function assignWorker(address _worker, bool _isWorker)
    external
    override
    onlyMaster
  returns(bool isChanged)
  {
    isChanged = workers[_worker] != _isWorker;
    if(isChanged) {
      workers[_worker] = _isWorker;
    }
  }
}