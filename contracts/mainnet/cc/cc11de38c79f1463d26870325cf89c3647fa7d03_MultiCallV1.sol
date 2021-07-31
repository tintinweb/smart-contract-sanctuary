/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.8.6;

contract MultiCallV1 {
  function executeCall(address target, string calldata signature, bytes calldata data) external returns (bytes memory) {
    bytes memory callData;

    if (bytes(signature).length == 0) {
        callData = data;
    } else {
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call(data);
    
    if (success) {   
        return returnData;
    }
    
    return "";
  }

  function executeCallsOfMultiTargets(address[] calldata targets, string calldata signature, bytes calldata data) external returns (bytes[] memory returnDatas) {
    returnDatas = new bytes[](targets.length);
    
    for(uint i = 0; i < targets.length; i++) {
      try this.executeCall(targets[i], signature, data) returns (bytes memory returnData) {
        returnDatas[i] = returnData;
      } catch {}
    }
    return returnDatas;
  }

  function executeMultiCallsOfTarget(address target, string[] calldata signatures, bytes[] calldata datas) external returns (bytes[] memory returnDatas) {
    returnDatas = new bytes[](signatures.length);
    
    for(uint i = 0; i < signatures.length; i++) {
      try this.executeCall(target, signatures[i], datas[i]) returns (bytes memory returnData) {
        returnDatas[i] = returnData;
      } catch {}
    }
    return returnDatas;
  }

  function executeMultiCallsOfMultiTarget(address[] calldata targets, string[] calldata signatures, bytes[] calldata datas) external returns (bytes[] memory returnDatas) {
    returnDatas = new bytes[](targets.length);
    
    for(uint i = 0; i < targets.length; i++) {
      try this.executeCall(targets[i], signatures[i], datas[i]) returns (bytes memory returnData) {
        returnDatas[i] = returnData;
      } catch {}
    }
    return returnDatas;
  }
}