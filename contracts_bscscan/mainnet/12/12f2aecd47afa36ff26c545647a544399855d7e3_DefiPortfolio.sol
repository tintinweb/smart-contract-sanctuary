/**
 *Submitted for verification at BscScan.com on 2021-10-05
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
    string poolLengthArg;
    string poolInfoSignature;
    string poolInfoArg;
    string poolInfoResArg;
    string userInfoSignature;
    string userInfoArg;
    string userInfoResArg;
  }
  
  struct StakedInfo {
    uint256 index;
    address token;
    uint256 amount;
  }

  ProtocolInfo[] public protocols;
  mapping(string => uint256) public protocolIndex;
  
  address public manager;
  
  modifier onlyManager() {
      require (msg.sender == manager);
      _;
  }
  
  constructor() {
      manager = msg.sender;
  }
  
  function getPoolLengthOf(uint256 index) internal view returns (uint256 length) {
    ProtocolInfo storage protocol = protocols[index];
    bytes memory callData;
    callData = abi.encodeWithSignature(protocol.poolLengthSignature);
    (bool success, bytes memory returnData) = address(protocol.chefAddress).staticcall(callData);
    if (success) {
      (length) = abi.decode(returnData, (uint256));
    }
  }
  
  function getPoolInfoOf(uint256 index, uint256 id) internal view returns (address token) {
    ProtocolInfo storage protocol = protocols[index];
    bytes memory callData;
    callData = abi.encodeWithSignature(protocol.poolInfoSignature, id);
    (bool success, bytes memory returnData) = address(protocol.chefAddress).staticcall(callData);
    if (success) {
      (token) = abi.decode(returnData, (address));
    }
  }
  
  function getUserInfoOf(uint256 index, uint256 id, address user) internal view returns (uint256 amount) {
    ProtocolInfo storage protocol = protocols[index];
    bytes memory callData;
    callData = abi.encodeWithSignature(protocol.userInfoSignature, id, user);
    (bool success, bytes memory returnData) = address(protocol.chefAddress).staticcall(callData);
    if (success) {
      (amount) = abi.decode(returnData, (uint256));
    }
  }
  
  function getStakedInfoOf(uint256 index, address user) internal view returns (StakedInfo[] memory stakedInfo) {
    uint256 length = getPoolLengthOf(index);
    stakedInfo = new StakedInfo[](length);
    for (uint256 i = 0; i < length; i += 1) {
      stakedInfo[i].index = i;
      stakedInfo[i].token = getPoolInfoOf(index, i);
      stakedInfo[i].amount = getUserInfoOf(index, i, user);
    }
  }
  
  function getPoolLength(string calldata name) public view returns (uint256 length) {
    length = getPoolLengthOf(protocolIndex[name]);
  }
  
  function getPoolInfo(string calldata name, uint256 id) public view returns (address token) {
    token = getPoolInfoOf(protocolIndex[name], id);
  }
  
  function getUserInfo(string calldata name, uint256 id, address user) public view returns (uint256 amount) {
    amount = getUserInfoOf(protocolIndex[name], id, user);
  }
 
  function getStakedInfo(string calldata name, address user) public view returns (StakedInfo[] memory stakedInfo) {
    stakedInfo = getStakedInfoOf(protocolIndex[name], user);
  }
  
  function getStakedInfos(address user) public view returns (StakedInfo[][] memory stakedInfos) {
    stakedInfos = new StakedInfo[][](protocols.length);
    uint256 protocolLength = protocols.length;
    for (uint256 i = 0; i < protocolLength; i += 1) {
        stakedInfos[i] = getStakedInfoOf(i, user);
    }
  }

  function addProtocol(ProtocolInfo calldata info) external onlyManager {
    protocolIndex[info.name] = protocols.length;
    protocols.push(info);
  }

  function addProtocols(ProtocolInfo[] calldata info) external onlyManager {
    uint256 infoLength = info.length;
    for (uint256 i = 0; i < infoLength; i += 1) {
        protocolIndex[info[i].name] = protocols.length;
        protocols.push(info[i]);
    }
  }
  
  function updateProtocol(uint256 index, ProtocolInfo calldata info) external onlyManager {
    protocols[index] = info;
  }
  
  function changeManager(address newManager) external onlyManager {
    require(newManager != address(0));
    manager = newManager;
  }
}