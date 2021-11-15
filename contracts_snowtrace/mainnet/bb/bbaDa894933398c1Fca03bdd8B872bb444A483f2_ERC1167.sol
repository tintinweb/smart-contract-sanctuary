// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable no-inline-assembly
library ERC1167 {
  bytes public constant CLONE =
    hex"363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";

  /**
   * @notice Make new proxy contract.
   * @param impl Address prototype contract.
   * @return proxy Address new proxy contract.
   */
  function clone(address impl) external returns (address proxy) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, impl))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, ptr, 0x37)
    }
    require(proxy != address(0), "ERC1167: create failed");
  }

  /**
   * @notice Returns address of prototype contract for proxy.
   * @param proxy Address proxy contract.
   * @return impl Address prototype contract (current contract address if not proxy).
   */
  function implementation(address proxy) external view returns (address impl) {
    uint256 size;
    assembly {
      size := extcodesize(proxy)
    }

    impl = proxy;
    if (size <= 45 && size >= 41) {
      bool matches = true;
      uint256 i;

      bytes memory code;
      assembly {
        code := mload(0x40)
        mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        mstore(code, size)
        extcodecopy(proxy, add(code, 0x20), 0, size)
      }
      for (i = 0; matches && i < 9; i++) {
        matches = code[i] == CLONE[i];
      }
      for (i = 0; matches && i < 15; i++) {
        if (i == 4) {
          matches = code[code.length - i - 1] == bytes1(uint8(CLONE[45 - i - 1]) - uint8(45 - size));
        } else {
          matches = code[code.length - i - 1] == CLONE[45 - i - 1];
        }
      }
      if (code[9] != bytes1(0x73 - uint8(45 - size))) {
        matches = false;
      }
      uint256 forwardedToBuffer;
      if (matches) {
        assembly {
          forwardedToBuffer := mload(add(code, 30))
        }
        forwardedToBuffer &= (0x1 << (20 * 8)) - 1;
        impl = address(uint160(forwardedToBuffer >> ((45 - size) * 8)));
      }
    }
  }
}