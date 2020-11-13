pragma solidity 0.5.17;

library Leaf {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

  uint256 constant WEIGHT_WIDTH = SLOT_WIDTH;
  uint256 constant WEIGHT_MAX = SLOT_MAX;

  uint256 constant BLOCKHEIGHT_WIDTH = 96 - WEIGHT_WIDTH;
  uint256 constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

  ////////////////////////////////////////////////////////////////////////////

  function make(
    address _operator,
    uint256 _creationBlock,
    uint256 _weight
  ) internal pure returns (uint256) {
    // Converting a bytesX type into a larger type
    // adds zero bytes on the right.
    uint256 op = uint256(bytes32(bytes20(_operator)));
    // Bitwise AND the weight to erase
    // all but the 32 least significant bits
    uint256 wt = _weight & WEIGHT_MAX;
    // Erase all but the 64 least significant bits,
    // then shift left by 32 bits to make room for the weight
    uint256 cb = (_creationBlock & BLOCKHEIGHT_MAX) << WEIGHT_WIDTH;
    // Bitwise OR them all together to get
    // [address operator || uint64 creationBlock || uint32 weight]
    return (op | cb | wt);
  }

  function operator(uint256 leaf) internal pure returns (address) {
    // Converting a bytesX type into a smaller type
    // truncates it on the right.
    return address(bytes20(bytes32(leaf)));
  }

  /// @notice Return the block number the leaf was created in.
  function creationBlock(uint256 leaf) internal pure returns (uint256) {
    return ((leaf >> WEIGHT_WIDTH) & BLOCKHEIGHT_MAX);
  }

  function weight(uint256 leaf) internal pure returns (uint256) {
    // Weight is stored in the 32 least significant bits.
    // Bitwise AND ensures that we only get the contents of those bits.
    return (leaf & WEIGHT_MAX);
  }

  function setWeight(uint256 leaf, uint256 newWeight)
    internal
    pure
    returns (uint256)
  {
    return ((leaf & ~WEIGHT_MAX) | (newWeight & WEIGHT_MAX));
  }
}
