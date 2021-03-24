/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface Bridge {
  function executeSignatures(bytes calldata message, bytes calldata signatures) external;
}

contract MultiClaim {
  Bridge bridge = Bridge(0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016);
 
  function claim(bytes[] calldata messages, bytes[] calldata signatures) external {
    for (uint256 i = 0; i < messages.length; i++) {
      bytes calldata message = messages[i];
      bytes calldata signature = signatures[i];
      bridge.executeSignatures(message, signature);
    }
  }
}