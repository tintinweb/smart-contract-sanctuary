pragma solidity 0.5.17;

import "./Leaf.sol";
import "./Interval.sol";
import "./DynamicArray.sol";

library RNG {
  using DynamicArray for DynamicArray.UintArray;
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant POSITION_BITS = LEVELS * SLOT_BITS;
  ////////////////////////////////////////////////////////////////////////////

  struct State {
    // RNG output
    uint256 currentMappedIndex;
    uint256 currentTruncatedIndex;
    // The random bytes used to derive indices
    bytes32 currentSeed;
    // The full range of indices;
    // generated random numbers are in [0, fullRange).
    uint256 fullRange;
    // The truncated range of indices;
    // how many non-skipped indices are left to consider.
    // Random indices are generated within this range,
    // and mapped to the full range by skipping the specified intervals.
    uint256 truncatedRange;
    DynamicArray.UintArray skippedIntervals;
  }

  function initialize(
    bytes32 seed,
    uint256 range,
    uint256 expectedSkippedCount
  ) internal view returns (State memory self) {
    self = State(
      0,
      0,
      seed,
      range,
      range,
      DynamicArray.uintArray(expectedSkippedCount)
    );
    reseed(self, seed, 0);
    return self;
  }

  function reseed(
    State memory self,
    bytes32 seed,
    uint256 nonce
  ) internal view {
    self.currentSeed = keccak256(
      abi.encodePacked(seed, nonce, address(this), "reseed")
    );
  }

  function retryIndex(State memory self) internal view {
    uint256 truncatedIndex = self.currentTruncatedIndex;
    if (self.currentTruncatedIndex < self.truncatedRange) {
      self.currentMappedIndex = Interval.skip(
        truncatedIndex,
        self.skippedIntervals
      );
    } else {
      generateNewIndex(self);
    }
  }

  function updateInterval(
    State memory self,
    uint256 startIndex,
    uint256 oldWeight,
    uint256 newWeight
  ) internal pure {
    int256 weightDiff = int256(newWeight) - int256(oldWeight);
    uint256 effectiveStartIndex = startIndex + newWeight;
    self.truncatedRange = uint256(int256(self.truncatedRange) + weightDiff);
    self.fullRange = uint256(int256(self.fullRange) + weightDiff);
    Interval.remapIndices(
      effectiveStartIndex,
      weightDiff,
      self.skippedIntervals
    );
  }

  function addSkippedInterval(
    State memory self,
    uint256 startIndex,
    uint256 weight
  ) internal pure {
    self.truncatedRange -= weight;
    Interval.insert(self.skippedIntervals, Interval.make(startIndex, weight));
  }

  /// @notice Generate a new index based on the current seed,
  /// without reseeding first.
  /// This will result in the same truncated index as before
  /// if it still fits in the current truncated range.
  function generateNewIndex(State memory self) internal view {
    uint256 _truncatedRange = self.truncatedRange;
    require(_truncatedRange > 0, "Not enough operators in pool");
    uint256 bits = bitsRequired(_truncatedRange);
    uint256 truncatedIndex = truncate(bits, uint256(self.currentSeed));
    while (truncatedIndex >= _truncatedRange) {
      self.currentSeed = keccak256(
        abi.encodePacked(self.currentSeed, address(this), "generate")
      );
      truncatedIndex = truncate(bits, uint256(self.currentSeed));
    }
    self.currentTruncatedIndex = truncatedIndex;
    self.currentMappedIndex = Interval.skip(
      truncatedIndex,
      self.skippedIntervals
    );
  }

  /// @notice Calculate how many bits are required
  /// for an index in the range `[0 .. range-1]`.
  ///
  /// @dev Our sortition pool can support up to 2^21 virtual stakers,
  /// therefore we calculate how many bits we need from 1 to 21.
  ///
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    // Start at 19 to be faster for large ranges
    uint256 bits = POSITION_BITS - 1;

    // Left shift by `bits`,
    // so we have a 1 in the (bits + 1)th least significant bit
    // and 0 in other bits.
    // If this number is equal or greater than `range`,
    // the range [0, range-1] fits in `bits` bits.
    //
    // Because we loop from high bits to low bits,
    // we find the highest number of bits that doesn't fit the range,
    // and return that number + 1.
    while (1 << bits >= range) {
      bits--;
    }

    return bits + 1;
  }

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint256 bits, uint256 input)
    internal
    pure
    returns (uint256)
  {
    return input & ((1 << bits) - 1);
  }

  /// @notice Get an index in the range `[0 .. range-1]`
  /// and the new state of the RNG,
  /// using the provided `state` of the RNG.
  ///
  /// @param range The upper bound of the index, exclusive.
  ///
  /// @param state The previous state of the RNG.
  /// The initial state needs to be obtained
  /// from a trusted randomness oracle (the random beacon),
  /// or from a chain of earlier calls to `RNG.getIndex()`
  /// on an originally trusted seed.
  ///
  /// @dev Calculates the number of bits required for the desired range,
  /// takes the least significant bits of `state`
  /// and checks if the obtained index is within the desired range.
  /// The original state is hashed with `keccak256` to get a new state.
  /// If the index is outside the range,
  /// the function retries until it gets a suitable index.
  ///
  /// @return index A random integer between `0` and `range - 1`, inclusive.
  ///
  /// @return newState The new state of the RNG.
  /// When `getIndex()` is called one or more times,
  /// care must be taken to always use the output `state`
  /// of the most recent call as the input `state` of a subsequent call.
  /// At the end of a transaction calling `RNG.getIndex()`,
  /// the previous stored state must be overwritten with the latest output.
  function getIndex(uint256 range, bytes32 state)
    internal
    view
    returns (uint256, bytes32)
  {
    uint256 bits = bitsRequired(range);
    bool found = false;
    uint256 index = 0;
    bytes32 newState = state;
    while (!found) {
      index = truncate(bits, uint256(newState));
      newState = keccak256(abi.encodePacked(newState, address(this)));
      if (index < range) {
        found = true;
      }
    }
    return (index, newState);
  }

  /// @notice Return an index corresponding to a new, unique leaf.
  ///
  /// @dev Gets a new index in a truncated range
  /// with the weights of all previously selected leaves subtracted.
  /// This index is then mapped to the full range of possible indices,
  /// skipping the ranges covered by previous leaves.
  ///
  /// @param range The full range in which the unique index should be.
  ///
  /// @param state The RNG state.
  ///
  /// @param previousLeaves List of indices and weights
  /// corresponding to the _first_ index of each previously selected leaf,
  /// and the weight of the same leaf.
  /// An index number `i` is a starting index of leaf `o`
  /// if querying for index `i` in the sortition pool returns `o`,
  /// but querying for `i-1` returns a different leaf.
  /// This list REALLY needs to be sorted from smallest to largest.
  ///
  /// @param sumPreviousWeights The sum of the weights of previous leaves.
  /// Could be calculated from `previousLeafWeights`
  /// but providing it explicitly makes the function a bit simpler.
  ///
  /// @return uniqueIndex An index in [0, range) that does not overlap
  /// any of the previousLeaves,
  /// as determined by the range [index, index + weight).
  function getUniqueIndex(
    uint256 range,
    bytes32 state,
    uint256[] memory previousLeaves,
    uint256 sumPreviousWeights
  ) internal view returns (uint256 uniqueIndex, bytes32 newState) {
    // Get an index in the truncated range.
    // The truncated range covers only new leaves,
    // but has to be mapped to the actual range of indices.
    uint256 truncatedRange = range - sumPreviousWeights;
    uint256 truncatedIndex;
    (truncatedIndex, newState) = getIndex(truncatedRange, state);

    // Map the truncated index to the available unique indices.
    uniqueIndex = Interval.skip(
      truncatedIndex,
      DynamicArray.convert(previousLeaves)
    );

    return (uniqueIndex, newState);
  }
}
