// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    CancelVerifier.sol :: 0xE0670a90E67eda0126D54843267b27Ca6343B2d8
 *    etherscan.io verified 2021-12-18
 */ 

import "../Libraries/Bit.sol";

/// @title Verifier for cancellation of messages signed with a bitmapIndex and bit
/// @notice Uses the Bit library to use the bit, which invalidates messages signed with the same bit
contract CancelVerifier {
  event Cancel (uint256 bitmapIndex, uint256 bit);

  /// @dev Cancels existing messages signed with bitmapIndex and bit
  /// @param bitmapIndex The bitmap index to use
  /// @param bit The bit to use
  function cancel(uint256 bitmapIndex, uint256 bit) external {
    Bit.useBit(bitmapIndex, bit);
    emit Cancel(bitmapIndex, bit);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/// @title Bit replay protection library
/// @notice Handles storage and loads for replay protection bits
/// @dev Solution adapted from https://github.com/PISAresearch/metamask-comp/blob/77fa8295c168ee0b6bf801cbedab797d6f8cfd5d/src/contracts/BitFlipMetaTransaction/README.md
/// @dev This is a gas optimized technique that stores up to 256 replay protection bits per bytes32 slot
library Bit {
  /// @dev Revert when bit provided is not valid
  error InvalidBit();

  /// @dev Revert when bit provided is used
  error BitUsed();

  /// @dev Initial pointer for bitmap storage ptr computation
  /// @notice This is the uint256 representation of keccak("bmp")
  uint256 constant INITIAL_BMP_PTR = 
  48874093989078844336340380824760280705349075126087700760297816282162649029611;

  /// @dev Adds a bit to the uint256 bitmap at bitmapIndex
  /// @dev Value of bit cannot be zero and must represent a single bit
  /// @param bitmapIndex The index of the uint256 bitmap
  /// @param bit The value of the bit within the uint256 bitmap
  function useBit(uint256 bitmapIndex, uint256 bit) internal {
    if (!validBit(bit)) {
      revert InvalidBit();
    }
    bytes32 ptr = bitmapPtr(bitmapIndex);
    uint256 bitmap = loadUint(ptr);
    if (bitmap & bit != 0) {
      revert BitUsed();
    }
    uint256 updatedBitmap = bitmap | bit;
    assembly { sstore(ptr, updatedBitmap) }
  }

  /// @dev Check that a bit is valid
  /// @param bit The bit to check
  /// @return isValid True if bit is greater than zero and represents a single bit
  function validBit(uint256 bit) internal pure returns (bool isValid) {
    assembly {
      // equivalent to: isValid = (bit > 0 && bit & bit-1) == 0;
      isValid := and(
        iszero(iszero(bit)), 
        iszero(and(bit, sub(bit, 1)))
      )
    } 
  }

  /// @dev Get a bitmap storage pointer
  /// @return The bytes32 pointer to the storage location of the uint256 bitmap at bitmapIndex
  function bitmapPtr (uint256 bitmapIndex) internal pure returns (bytes32) {
    return bytes32(INITIAL_BMP_PTR + bitmapIndex);
  }

  /// @dev Returns the uint256 value at storage location ptr
  /// @param ptr The storage location pointer
  /// @return val The uint256 value at storage location ptr
  function loadUint(bytes32 ptr) internal view returns (uint256 val) {
    assembly { val := sload(ptr) }
  }
}