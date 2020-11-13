pragma solidity 0.5.17;

import "./Leaf.sol";
import "./DynamicArray.sol";

library Interval {
  using DynamicArray for DynamicArray.UintArray;
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

  uint256 constant START_INDEX_WIDTH = WEIGHT_WIDTH;
  uint256 constant START_INDEX_MAX = WEIGHT_MAX;
  uint256 constant START_INDEX_SHIFT = WEIGHT_WIDTH;

  ////////////////////////////////////////////////////////////////////////////

  // Interval stores information about a selected interval
  // inside a single uint256 in a manner similar to Leaf
  // but optimized for use within group selection
  //
  // The information stored consists of:
  // - weight
  // - starting index

  function make(uint256 startingIndex, uint256 weight)
    internal
    pure
    returns (uint256)
  {
    uint256 idx = (startingIndex & START_INDEX_MAX) << START_INDEX_SHIFT;
    uint256 wt = weight & WEIGHT_MAX;
    return (idx | wt);
  }

  function opWeight(uint256 op) internal pure returns (uint256) {
    return (op & WEIGHT_MAX);
  }

  // Return the starting index of the interval
  function index(uint256 a) internal pure returns (uint256) {
    return ((a >> WEIGHT_WIDTH) & START_INDEX_MAX);
  }

  function setIndex(uint256 op, uint256 i) internal pure returns (uint256) {
    uint256 shiftedIndex = ((i & START_INDEX_MAX) << WEIGHT_WIDTH);
    return (op & (~(START_INDEX_MAX << WEIGHT_WIDTH))) | shiftedIndex;
  }

  function insert(DynamicArray.UintArray memory intervals, uint256 interval)
    internal
    pure
  {
    uint256 tempInterval = interval;
    for (uint256 i = 0; i < intervals.array.length; i++) {
      uint256 thisInterval = intervals.array[i];
      // We can compare the raw underlying uint256 values
      // because the starting index is stored
      // in the most significant nonzero bits.
      if (tempInterval < thisInterval) {
        intervals.array[i] = tempInterval;
        tempInterval = thisInterval;
      }
    }
    intervals.arrayPush(tempInterval);
  }

  function skip(uint256 truncatedIndex, DynamicArray.UintArray memory intervals)
    internal
    pure
    returns (uint256 mappedIndex)
  {
    mappedIndex = truncatedIndex;
    for (uint256 i = 0; i < intervals.array.length; i++) {
      uint256 interval = intervals.array[i];
      // If the index is greater than the starting index of the `i`th leaf,
      // we need to skip that leaf.
      if (mappedIndex >= index(interval)) {
        // Add the weight of this previous leaf to the index,
        // ensuring that we skip the leaf.
        mappedIndex += Leaf.weight(interval);
      } else {
        break;
      }
    }
    return mappedIndex;
  }

  /// @notice Recalculate the starting indices of the previousLeaves
  /// when an interval is removed or added at the specified index.
  /// @dev Applies weightDiff to each starting index in previousLeaves
  /// that exceeds affectedStartingIndex.
  /// @param affectedStartingIndex The starting index of the interval.
  /// @param weightDiff The difference in weight;
  /// negative for a deleted interval,
  /// positive for an added interval.
  /// @param previousLeaves The starting indices and weights
  /// of the previously selected leaves.
  /// @return The starting indices of the previous leaves
  /// in a tree with the affected interval updated.
  function remapIndices(
    uint256 affectedStartingIndex,
    int256 weightDiff,
    DynamicArray.UintArray memory previousLeaves
  ) internal pure {
    uint256 nPreviousLeaves = previousLeaves.array.length;

    for (uint256 i = 0; i < nPreviousLeaves; i++) {
      uint256 interval = previousLeaves.array[i];
      uint256 startingIndex = index(interval);
      // If index is greater than the index of the affected interval,
      // update the starting index by the weight change.
      if (startingIndex > affectedStartingIndex) {
        uint256 newIndex = uint256(int256(startingIndex) + weightDiff);
        previousLeaves.array[i] = setIndex(interval, newIndex);
      }
    }
  }
}
