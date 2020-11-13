// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

// solium-disable security/no-inline-assembly
library MinimalProxyLibrary {
  function minimalProxy(address _logic) internal pure returns (bytes memory clone) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let size := 0x37
      // allocate output byte array - this could also be done without assembly
      // by using clone = new bytes(size)
      clone := mload(0x40)
      // new "memory end" including padding
      mstore(0x40, add(clone, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      // store length in memory
      mstore(clone, size)
      mstore(add(clone, 0x20), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x34), targetBytes)
      mstore(add(clone, 0x48), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
    }
  }
}
