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

  function isMinion(address account_) virtual external view returns(bool);
  function isWorker(address account_) virtual external view returns(bool);
  function isWorkerOrMinion(address account_) virtual external view returns(bool);

  function getMinionGroup(bytes32 groupId_) virtual external view returns(address[] memory);
  function addMinionGroup(bytes32 groupId_, address[] calldata minionList_) virtual external;
  function removeMinionGroup(bytes32 groupId_) virtual external;

  function assignWorker(address worker_, bool isWorker_) virtual external returns(bool);

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
  function isOwner(address owner_) virtual external view returns (bool);
  function isCFO(address cfo_) virtual external view returns (bool);
  function isCOO(address coo_) virtual external view returns (bool);
  function isWorker(address account_) virtual external view returns (bool);
  function isWorkerOrMinion(address account_) virtual external view returns (bool);
  function makeFundedCall(address account_) virtual external returns (bool);
  function updateCollectibleSaleStatus(uint game_, uint card_, bool isOnSale_) virtual external;

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



  constructor(address masterContract_)
  {
    masterContract = iGAME_Master(masterContract_);
    require(masterContract.isMaster(), "masterContract_ must implement isMaster()");
  }

  modifier onlyMaster() {
    // Cannot be called using native meta-transactions
    require(address(masterContract) == msg.sender, "sender must be the master contract");
    _;
  }

  function isMinion(address account_)
    external
    override
    view
  returns(bool) {
    return minions[account_];
  }

  function isWorker(address account_)
    external
    override
    view
  returns(bool) {
    return workers[account_];
  }

  function isWorkerOrMinion(address account_)
    external
    override
    view
  returns(bool) {
    return workers[account_] || minions[account_];
  }

  function getMinionGroup(bytes32 groupId_)
    external
    override
    view
  returns(address[] memory) {
    return minionGroups[groupId_];
  }

  function addMinionGroup(bytes32 groupId_, address[] calldata minionList_)
    external
    override
    onlyMaster
  {
    require(minionGroupIds[groupId_] == false, "groupId can't be recorded");
    require(minionList_.length > 0, "must be at least one minion");
    minionGroupIds[groupId_] = true;
    minionGroups[groupId_] = minionList_;
    for(uint i = 0; i < minionList_.length; i++) {
      require(minions[minionList_[i]] == false, "minion must not exist");
      minions[minionList_[i]] = true;
    }
  }

  function removeMinionGroup(bytes32 groupId_)
    external
    override
    onlyMaster
  {
    require(minionGroupIds[groupId_] == true, "groupId must exist");
    address[] storage minionList = minionGroups[groupId_];
    for(uint i = 0; i < minionList.length; i++) {
      minions[minionList[i]] = true;
    }
    delete minionGroups[groupId_];
    minionGroupIds[groupId_] = false;
  }

  function assignWorker(address worker_, bool isWorker_)
    external
    override
    onlyMaster
  returns(bool isChanged)
  {
    isChanged = workers[worker_] != isWorker_;
    if(isChanged) {
      workers[worker_] = isWorker_;
    }
  }
}