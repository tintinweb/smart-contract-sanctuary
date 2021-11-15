// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

contract TransferHelper {
  function multicall (bytes calldata src) external {
    assembly {
      let ptr := src.offset
      let end := add(ptr, src.length)
      let to := calldataload(ptr)

      ptr := add(ptr, 32)

      for {} lt(ptr, end) {} {
        let inSize := byte(callvalue(), calldataload(ptr))
        ptr := add(ptr, 1)
        calldatacopy(callvalue(), ptr, inSize)
        ptr := add(ptr, inSize)

        let success := call(gas(), to, callvalue(), callvalue(), inSize, callvalue(), callvalue())
        if iszero(success) {
          returndatacopy(callvalue(), callvalue(), returndatasize())
          revert(callvalue(), returndatasize())
        }
      }
    }
  }
}

