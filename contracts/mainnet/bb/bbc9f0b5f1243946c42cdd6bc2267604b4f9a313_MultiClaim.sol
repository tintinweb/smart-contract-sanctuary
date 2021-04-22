/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface Bridge {
  function executeSignatures(bytes calldata message, bytes calldata signatures) external;
}

contract MultiClaim {
  function claim(address bridge, bytes[] calldata messages, bytes[] calldata signatures) external {
    for (uint256 i = 0; i < messages.length; i++) {
      bytes calldata message = messages[i];
      bytes calldata signature = signatures[i];
      Bridge(bridge).executeSignatures(message, signature);
    }
  }
}