/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.8.7;

contract DefiPortfolio {
  struct ProtocolInfo {
    string name;
    string websiteURL;
    string iconURL;
    address chefAddress;
    string poolLengthSignature;
    string poolInfoSignature;
    string userInfoSignature;
  }
  
  struct StakedPoolInfo {
    uint256 index;
    address token;
    uint256 amount;
  }

  struct StakedInfo {
    string name;
    StakedPoolInfo[] pools;
  }

  ProtocolInfo[] public protocols;
  mapping(string => uint256) public protocolIndex;
  mapping(string => bool) public protocolSupport;
  
  address public manager;
  
  modifier onlyManager() {
    require (msg.sender == manager);
    _;
  }
  
  constructor() {
    manager = msg.sender;
  }
  
  function getPoolLengthOf(
    uint256 index
  ) public view returns (uint256 length) {
    ProtocolInfo storage protocol = protocols[index];
    if (bytes(protocol.poolLengthSignature).length == 0) {
      return 0;
    }

    bytes memory callData;
    callData = abi.encodeWithSignature(protocol.poolLengthSignature);

    (
      bool success,
      bytes memory returnData
    ) = address(protocol.chefAddress).staticcall(callData);

    if (success) {
      (length) = abi.decode(returnData, (uint256));
    }
  }
  
  function getPoolInfoOf(
    uint256 index,
    uint256 id
  ) public view returns (address token) {
    ProtocolInfo storage protocol = protocols[index];
    bytes memory callData;
    callData = abi.encodeWithSignature(protocol.poolInfoSignature, id);

    (
      bool success,
      bytes memory returnData
    ) = address(protocol.chefAddress).staticcall(callData);

    if (success) {
      (token) = abi.decode(returnData, (address));
    }
  }
  
  function getUserInfoOf(
    uint256 index,
    uint256 id,
    address user
  )
    public
    view
    returns (uint256 amount)
  {
    ProtocolInfo storage protocol = protocols[index];
    bytes memory callData;
    callData = abi.encodeWithSignature(
      protocol.userInfoSignature,
      id,
      user
    );

    (
      bool success,
      bytes memory returnData
    ) = address(protocol.chefAddress).staticcall(callData);

    if (success) {
      (amount) = abi.decode(returnData, (uint256));
    }
  }
  
  function getStakedInfoOf(
    uint256 index,
    address user
  )
    public
    view
    returns (StakedPoolInfo[] memory stakedPoolInfo)
  {
    uint256 length = getPoolLengthOf(index);
    uint256[] memory userPools = new uint256[](length);
    uint256[] memory amounts = new uint256[](length);
    uint256 counter = 0;

    if (bytes(protocols[index].poolLengthSignature).length == 0) {
      for (uint256 i = 0; i < length; i++) {
        try this.getUserInfoOf(
          index,
          i,
          user
        ) returns (uint256 amount) {
          if (amount > 0) {
            userPools[counter] = i;
            amounts[counter] = amount;
            counter++;
          }
        } catch (bytes memory) {
          break;
        }
      }
    } else {
      for (uint256 i = 0; i < length; i++) {
        uint256 amount = getUserInfoOf(index, i, user);
        if (amount > 0) {
          userPools[counter] = i;
          amounts[counter] = amount;
          counter++;
        }
      }
    }
    
    stakedPoolInfo = new StakedPoolInfo[](counter);
    for (uint256 i = 0; i < counter; i++) {
      stakedPoolInfo[i].index = userPools[i];
      stakedPoolInfo[i].token = getPoolInfoOf(index, userPools[i]);
      stakedPoolInfo[i].amount = amounts[i];
    }
  }
  
  function getPoolLength(
    string calldata name
  ) public view returns (uint256 length) {
    length = getPoolLengthOf(protocolIndex[name]);
  }
  
  function getPoolInfo(
    string calldata name,
    uint256 id
  ) public view returns (address token) {
    token = getPoolInfoOf(protocolIndex[name], id);
  }
  
  function getUserInfo(
    string calldata name,
    uint256 id,
    address user
  ) public view returns (uint256 amount) {
    amount = getUserInfoOf(protocolIndex[name], id, user);
  }
 
  function getStakedInfo(
    string calldata name,
    address user
  )
    public
    view
    returns (StakedPoolInfo[] memory stakedPoolInfo)
  {
    stakedPoolInfo = getStakedInfoOf(protocolIndex[name], user);
  }
  
  function getStakedInfos(
    address user
  )
    public
    view
    returns (StakedInfo[]memory stakedInfos)
  {
    stakedInfos = new StakedInfo[](protocols.length);
    uint256 protocolLength = protocols.length;
    for (uint256 i = 0; i < protocolLength; i++) {
        stakedInfos[i].name = protocols[i].name;
        stakedInfos[i].pools = getStakedInfoOf(i, user);
    }
  }
  
  function getAllProtocols()
    public
    view
    returns (ProtocolInfo[] memory protocolInfos)
  {
    uint256 protocolLength = protocols.length;
    protocolInfos = new ProtocolInfo[](protocolLength);
    for (uint256 i = 0; i < protocolLength; i++) {
        protocolInfos[i] = protocols[i];
    }
  }

  function addProtocol(ProtocolInfo calldata info) public onlyManager {
    require(!protocolSupport[info.name]);
    require(info.chefAddress != address(0));
    protocolIndex[info.name] = protocols.length;
    protocols.push(info);
    protocolSupport[info.name] = true;
  }

  function addProtocols(
    ProtocolInfo[] calldata info
  ) external onlyManager {
    uint256 infoLength = info.length;
    for (uint256 i = 0; i < infoLength; i++) {
      addProtocol(info[i]);
    }
  }
  
  function updateProtocol(
    uint256 index,
    ProtocolInfo calldata info
  ) external onlyManager {
    require(info.chefAddress != address(0));
    protocolSupport[protocols[index].name] = false;
    protocolIndex[protocols[index].name] = 0;
    protocols[index] = info;
    protocolSupport[info.name] = true;
    protocolIndex[info.name] = index;
  }
  
  function changeManager(address newManager) external onlyManager {
    require(newManager != address(0));
    manager = newManager;
  }
}