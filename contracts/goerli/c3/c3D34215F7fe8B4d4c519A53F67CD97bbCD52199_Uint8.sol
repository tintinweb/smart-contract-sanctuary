/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.6.0;

library Uint8 {
  function getUint256(bytes memory num, uint256 offset)
    external
    pure
    returns (uint256 result)
  {
    assembly {
      result := mload(add(num, offset))
    }
  }

  function getUint256V2(bytes memory num, uint256 offset)
    external
    pure
    returns (uint256 result)
  {
    assembly {
      result := mload(add(num, offset))

      result := and(result, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
  }

  function getUint8(bytes memory num, uint256 offset)
    external
    pure
    returns (uint8 result)
  {
    assembly {
      result := mload(add(num, offset))
    }
  }

  function getUint8V2(bytes memory num, uint256 offset)
    external
    pure
    returns (uint8 result)
  {
    assembly {
      result := mload(add(num, offset))

      result := and(result, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
  }

  function getUint8V3(bytes memory num, uint256 offset)
    external
    pure
    returns (uint8 result)
  {
    assembly {
      result := mload(add(num, offset))

      result := and(result, 0xFF)
    }
  }
}