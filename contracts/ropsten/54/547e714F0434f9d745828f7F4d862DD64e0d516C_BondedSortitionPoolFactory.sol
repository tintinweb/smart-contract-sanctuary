pragma solidity 0.5.17;

import "./BondedSortitionPool.sol";
import "./api/IBonding.sol";
import "./api/IStaking.sol";

/// @title Bonded Sortition Pool Factory
/// @notice Factory for the creation of new bonded sortition pools.
contract BondedSortitionPoolFactory {
  /// @notice Creates a new bonded sortition pool instance.
  /// @return Address of the new bonded sortition pool contract instance.
  function createSortitionPool(
    IStaking stakingContract,
    IBonding bondingContract,
    uint256 minimumStake,
    uint256 initialMinimumBond,
    uint256 poolWeightDivisor
  ) public returns (address) {
    return
      address(
        new BondedSortitionPool(
          stakingContract,
          bondingContract,
          minimumStake,
          initialMinimumBond,
          poolWeightDivisor,
          msg.sender
        )
      );
  }
}

pragma solidity 0.5.17;

interface IStaking {
    // Gives the amount of KEEP tokens staked by the `operator`
    // eligible for work selection in the specified `operatorContract`.
    //
    // If the operator doesn't exist or hasn't finished initializing,
    // or the operator contract hasn't been authorized for the operator,
    // returns 0.
    function eligibleStake(
        address operator,
        address operatorContract
    ) external view returns (uint256);
}

pragma solidity 0.5.17;

interface IBonding {
    // Gives the amount of ETH
    // the `operator` has made available for bonding by the `bondCreator`.
    // If the operator doesn't exist,
    // or the bond creator isn't authorized,
    // returns 0.
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address authorizedSortitionPool
    ) external view returns (uint256);
}

pragma solidity 0.5.17;

library StackLib {
  function stackPeek(uint256[] storage _array) internal view returns (uint256) {
    require(_array.length > 0, "No value to peek, array is empty");
    return (_array[_array.length - 1]);
  }

  function stackPush(uint256[] storage _array, uint256 _element) public {
    _array.push(_element);
  }

  function stackPop(uint256[] storage _array) internal returns (uint256) {
    require(_array.length > 0, "No value to pop, array is empty");
    uint256 value = _array[_array.length - 1];
    _array.length -= 1;
    return value;
  }

  function getSize(uint256[] storage _array) internal view returns (uint256) {
    return _array.length;
  }
}

pragma solidity 0.5.17;

import "./StackLib.sol";
import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";

contract SortitionTree {
  using StackLib for uint256[];
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 constant POOL_CAPACITY = SLOT_COUNT**LEVELS;
  ////////////////////////////////////////////////////////////////////////////

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 root;
  mapping(uint256 => mapping(uint256 => uint256)) branches;
  mapping(uint256 => uint256) leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 rightmostLeaf;
  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] emptyLeaves;

  constructor() public {
    root = 0;
    rightmostLeaf = 0;
  }

  // checks if operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Sum the number of operators in each trunk
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.getSize();

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  function insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, weight);

    root = setLeaf(position, theLeaf, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  function removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    updateLeaf(unflaggedPosition, weight);
  }

  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    uint256 newRoot = setLeaf(position, 0, _root);

    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.stackPush(position);
    }
    return newRoot;
  }

  function updateLeaf(uint256 position, uint256 weight) internal {
    uint256 oldLeaf = leaves[position];
    if (oldLeaf.weight() != weight) {
      uint256 newLeaf = oldLeaf.setWeight(weight);
      root = setLeaf(position, newLeaf, root);
    }
  }

  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = theLeaf.weight();

    // set leaf
    leaves[position] = theLeaf;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition, uint256 leafFirstIndex)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
    // get the first index of the leaf
    // This works because the last weight returned from `pickWeightedSlot()`
    // equals the "overflow" from getting the current slot.
    leafFirstIndex = index - currentIndex;
  }

  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      bool emptyLeavesInStack = leavesInStack();
      require(emptyLeavesInStack, "Pool is full");
      return emptyLeaves.stackPop();
    }
  }

  function leavesInStack() internal view returns (bool) {
    return emptyLeaves.getSize() > 0;
  }
}

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
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant WEIGHT_WIDTH = 256 / SLOT_COUNT;
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
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    uint256 bits = WEIGHT_WIDTH - 1;

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

pragma solidity 0.5.17;

library Position {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_POINTER_MAX = (2**SLOT_BITS) - 1;
  uint256 constant LEAF_FLAG = 1 << 255;

  ////////////////////////////////////////////////////////////////////////////

  // Return the last 3 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint256 a) internal pure returns (uint256) {
    return a & SLOT_POINTER_MAX;
  }

  // Return the parent of a position number
  function parent(uint256 a) internal pure returns (uint256) {
    return a >> SLOT_BITS;
  }

  // Return the location of the child of a at the given slot
  function child(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a << SLOT_BITS) | (s & SLOT_POINTER_MAX); // slot(s)
  }

  // Return the uint p as a flagged position uint:
  // the least significant 21 bits contain the position
  // and the 22nd bit is set as a flag
  // to distinguish the position 0x000000 from an empty field.
  function setFlag(uint256 p) internal pure returns (uint256) {
    return p | LEAF_FLAG;
  }

  // Turn a flagged position into an unflagged position
  // by removing the flag at the 22nd least significant bit.
  //
  // We shouldn't _actually_ need this
  // as all position-manipulating code should ignore non-position bits anyway
  // but it's cheap to call so might as well do it.
  function unsetFlag(uint256 p) internal pure returns (uint256) {
    return p & (~LEAF_FLAG);
  }
}

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

pragma solidity 0.5.17;

contract GasStation {
  mapping(address => mapping(uint256 => uint256)) gasDeposits;

  function depositGas(address addr) internal {
    setDeposit(addr, 1);
  }

  function releaseGas(address addr) internal {
    setDeposit(addr, 0);
  }

  function setDeposit(address addr, uint256 val) internal {
    for (uint256 i = 0; i < gasDepositSize(); i++) {
      gasDeposits[addr][i] = val;
    }
  }

  function gasDepositSize() internal pure returns (uint256);
}

pragma solidity 0.5.17;

library DynamicArray {
  // The in-memory dynamic Array is implemented
  // by recording the amount of allocated memory
  // separately from the length of the array.
  // This gives us a perfectly normal in-memory array
  // with all the behavior we're used to,
  // but also makes O(1) `push` operations possible
  // by expanding into the preallocated memory.
  //
  // When we run out of preallocated memory when trying to `push`,
  // we allocate twice as much and copy the array over.
  // With linear allocation costs this would amortize to O(1)
  // but with EVM allocations being actually quadratic
  // the real performance is a very technical O(N).
  // Nonetheless, this is reasonably performant in practice.
  //
  // A dynamic array can be useful
  // even when you aren't dealing with an unknown number of items.
  // Because the array tracks the allocated space
  // separately from the number of stored items,
  // you can push items into the dynamic array
  // and iterate over the currently present items
  // without tracking their number yourself,
  // or using a special null value for empty elements.
  //
  // Because Solidity doesn't really have useful safety features,
  // only enough superficial inconveniences
  // to lull yourself into a false sense of security,
  // dynamic arrays require a bit of care to handle appropriately.
  //
  // First of all,
  // dynamic arrays must not be created or modified manually.
  // Use `uintArray(length)`, or `convert(existingArray)`
  // which will perform a safe and efficient conversion for you.
  // This also applies to storage;
  // in-memory dynamic arrays are for efficient in-memory operations only,
  // and it is unnecessary to store dynamic arrays.
  // Use a regular `uint256[]` instead.
  // The contents of `array` may be written like `dynamicArray.array[i] = x`
  // but never reassign the `array` pointer itself
  // nor mess with `allocatedMemory` in any way whatsoever.
  // If you fail to follow these precautions,
  // dragons inhabiting the no-man's-land
  // between the array as it's seen by Solidity
  // and the next thing allocated after it
  // will be unleashed to wreak havoc upon your memory buffers.
  //
  // Second,
  // because the `array` may be reassigned when pushing,
  // the following pattern is unsafe:
  // ```
  // UintArray dynamicArray;
  // uint256 len = dynamicArray.array.length;
  // uint256[] danglingPointer = dynamicArray.array;
  // danglingPointer[0] = x;
  // dynamicArray.push(y);
  // danglingPointer[0] = z;
  // uint256 surprise = danglingPointer[len];
  // ```
  // After the above code block,
  // `dynamicArray.array[0]` may be either `x` or `z`,
  // and `surprise` may be `y` or out of bounds.
  // This will not share your address space with a malevolent agent of chaos,
  // but it will cause entirely avoidable scratchings of the head.
  //
  // Dynamic arrays should be safe to use like ordinary arrays
  // if you always refer to the array field of the dynamic array
  // when reading or writing values:
  // ```
  // UintArray dynamicArray;
  // uint256 len = dynamicArray.array.length;
  // dynamicArray.array[0] = x;
  // dynamicArray.push(y);
  // dynamicArray.array[0] = z;
  // uint256 notSurprise = dynamicArray.array[len];
  // ```
  // After this code `notSurprise` is reliably `y`,
  // and `dynamicArray.array[0]` is `z`.
  struct UintArray {
    // XXX: Do not modify this value.
    // In fact, do not even read it.
    // There is never a legitimate reason to do anything with this value.
    // She is quiet and wishes to be left alone.
    // The silent vigil of `allocatedMemory`
    // is the only thing standing between your contract
    // and complete chaos in its memory.
    // Respect her wish or face the monstrosities she is keeping at bay.
    uint256 allocatedMemory;
    // Unlike her sharp and vengeful sister,
    // `array` is safe to use normally
    // for anything you might do with a normal `uint256[]`.
    // Reads and loops will check bounds,
    // and writing in individual indices like `myArray.array[i] = x`
    // is perfectly fine.
    // No curse will befall you as long as you obey this rule:
    //
    // XXX: Never try to replace her or separate her from her sister
    // by writing down the accursed words
    // `myArray.array = anotherArray` or `lonelyArray = myArray.array`.
    //
    // If you do, your cattle will be diseased,
    // your children will be led astray in the woods,
    // and your memory will be silently overwritten.
    // Instead, give her a friend with
    // `mySecondArray = convert(anotherArray)`,
    // and call her by her family name first.
    // She will recognize your respect
    // and ward your memory against corruption.
    uint256[] array;
  }

  struct AddressArray {
    uint256 allocatedMemory;
    address[] array;
  }

  /// @notice Create an empty dynamic array,
  /// with preallocated memory for up to `length` elements.
  /// @dev Knowing or estimating the preallocated length in advance
  /// helps avoid frequent early allocations when filling the array.
  /// @param length The number of items to preallocate space for.
  /// @return A new dynamic array.
  function uintArray(uint256 length) internal pure returns (UintArray memory) {
    uint256[] memory array = _allocateUints(length);
    return UintArray(length, array);
  }

  function addressArray(uint256 length)
    internal
    pure
    returns (AddressArray memory)
  {
    address[] memory array = _allocateAddresses(length);
    return AddressArray(length, array);
  }

  /// @notice Convert an existing non-dynamic array into a dynamic array.
  /// @dev The dynamic array is created
  /// with allocated memory equal to the length of the array.
  /// @param array The array to convert.
  /// @return A new dynamic array,
  /// containing the contents of the argument `array`.
  function convert(uint256[] memory array)
    internal
    pure
    returns (UintArray memory)
  {
    return UintArray(array.length, array);
  }

  function convert(address[] memory array)
    internal
    pure
    returns (AddressArray memory)
  {
    return AddressArray(array.length, array);
  }

  /// @notice Push `item` into the dynamic array.
  /// @dev This function will be safe
  /// as long as you haven't scorned either of the sisters.
  /// If you have, the dragons will be released
  /// to wreak havoc upon your memory.
  /// A spell to dispel the curse exists,
  /// but a sacred vow prohibits it from being shared
  /// with those who do not know how to discover it on their own.
  /// @param self The dynamic array to push into;
  /// after the call it will be mutated in place to contain the item,
  /// allocating more memory behind the scenes if necessary.
  /// @param item The item you wish to push into the array.
  function arrayPush(UintArray memory self, uint256 item) internal pure {
    uint256 length = self.array.length;
    uint256 allocLength = self.allocatedMemory;
    // The dynamic array is full so we need to allocate more first.
    // We check for >= instead of ==
    // so that we can put the require inside the conditional,
    // reducing the gas costs of `push` slightly.
    if (length >= allocLength) {
      // This should never happen if `allocatedMemory` isn't messed with.
      require(length == allocLength, "Array length exceeds allocation");
      // Allocate twice the original array length,
      // then copy the contents over.
      uint256 newMemory = length * 2;
      uint256[] memory newArray = _allocateUints(newMemory);
      _copy(newArray, self.array);
      self.array = newArray;
      self.allocatedMemory = newMemory;
    }
    // We have enough free memory so we can push into the array.
    _push(self.array, item);
  }

  function arrayPush(AddressArray memory self, address item) internal pure {
    uint256 length = self.array.length;
    uint256 allocLength = self.allocatedMemory;
    if (length >= allocLength) {
      require(length == allocLength, "Array length exceeds allocation");
      uint256 newMemory = length * 2;
      address[] memory newArray = _allocateAddresses(newMemory);
      _copy(newArray, self.array);
      self.array = newArray;
      self.allocatedMemory = newMemory;
    }
    _push(self.array, item);
  }

  /// @notice Pop the last item from the dynamic array,
  /// removing it and decrementing the array length in place.
  /// @dev This makes the dragons happy
  /// as they have more space to roam.
  /// Thus they have no desire to escape and ravage your buffers.
  /// @param self The array to pop from.
  /// @return item The previously last element in the array.
  function arrayPop(UintArray memory self)
    internal
    pure
    returns (uint256 item)
  {
    uint256[] memory array = self.array;
    uint256 length = array.length;
    require(length > 0, "Can't pop from empty array");
    return _pop(array);
  }

  function arrayPop(AddressArray memory self)
    internal
    pure
    returns (address item)
  {
    address[] memory array = self.array;
    uint256 length = array.length;
    require(length > 0, "Can't pop from empty array");
    return _pop(array);
  }

  /// @notice Allocate an empty array,
  /// reserving enough memory to safely store `length` items.
  /// @dev The array starts with zero length,
  /// but the allocated buffer has space for `length` words.
  /// "What be beyond the bounds of `array`?" you may ask.
  /// The answer is: dragons.
  /// But do not worry,
  /// for `Array.allocatedMemory` protects your EVM from them.
  function _allocateUints(uint256 length)
    private
    pure
    returns (uint256[] memory array)
  {
    // Calculate the size of the allocated block.
    // Solidity arrays without a specified constant length
    // (i.e. `uint256[]` instead of `uint256[8]`)
    // store the length at the first memory position
    // and the contents of the array after it,
    // so we add 1 to the length to account for this.
    uint256 inMemorySize = (length + 1) * 0x20;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Get some free memory
      array := mload(0x40)
      // Write a zero in the length field;
      // we set the length elsewhere
      // if we store anything in the array immediately.
      // When we allocate we only know how many words we reserve,
      // not how many actually get written.
      mstore(array, 0)
      // Move the free memory pointer
      // to the end of the allocated block.
      mstore(0x40, add(array, inMemorySize))
    }
    return array;
  }

  function _allocateAddresses(uint256 length)
    private
    pure
    returns (address[] memory array)
  {
    uint256 inMemorySize = (length + 1) * 0x20;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      array := mload(0x40)
      mstore(array, 0)
      mstore(0x40, add(array, inMemorySize))
    }
    return array;
  }

  /// @notice Unsafe function to copy the contents of one array
  /// into an empty initialized array
  /// with sufficient free memory available.
  function _copy(uint256[] memory dest, uint256[] memory src) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(src)
      let byteLength := mul(length, 0x20)
      // Store the resulting length of the array.
      mstore(dest, length)
      // Maintain a write pointer
      // for the current write location in the destination array
      // by adding the 32 bytes for the array length
      // to the starting location.
      let writePtr := add(dest, 0x20)
      // Stop copying when the write pointer reaches
      // the length of the source array.
      // We can track the endpoint either from the write or read pointer.
      // This uses the write pointer
      // because that's the way it was done
      // in the (public domain) code I stole this from.
      let end := add(writePtr, byteLength)

      for {
        // Initialize a read pointer to the start of the source array,
        // 32 bytes into its memory.
        let readPtr := add(src, 0x20)
      } lt(writePtr, end) {
        // Increase both pointers by 32 bytes each iteration.
        writePtr := add(writePtr, 0x20)
        readPtr := add(readPtr, 0x20)
      } {
        // Write the source array into the dest memory
        // 32 bytes at a time.
        mstore(writePtr, mload(readPtr))
      }
    }
  }

  function _copy(address[] memory dest, address[] memory src) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(src)
      let byteLength := mul(length, 0x20)
      mstore(dest, length)
      let writePtr := add(dest, 0x20)
      let end := add(writePtr, byteLength)

      for {
        let readPtr := add(src, 0x20)
      } lt(writePtr, end) {
        writePtr := add(writePtr, 0x20)
        readPtr := add(readPtr, 0x20)
      } {
        mstore(writePtr, mload(readPtr))
      }
    }
  }

  /// @notice Unsafe function to push past the limit of an array.
  /// Only use with preallocated free memory.
  function _push(uint256[] memory array, uint256 item) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Get array length
      let length := mload(array)
      let newLength := add(length, 1)
      // Calculate how many bytes the array takes in memory,
      // including the length field.
      // This is equal to 32 * the incremented length.
      let arraySize := mul(0x20, newLength)
      // Calculate the first memory position after the array
      let nextPosition := add(array, arraySize)
      // Store the item in the available position
      mstore(nextPosition, item)
      // Increment array length
      mstore(array, newLength)
    }
  }

  function _push(address[] memory array, address item) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(array)
      let newLength := add(length, 1)
      let arraySize := mul(0x20, newLength)
      let nextPosition := add(array, arraySize)
      mstore(nextPosition, item)
      mstore(array, newLength)
    }
  }

  function _pop(uint256[] memory array) private pure returns (uint256 item) {
    uint256 length = array.length;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Calculate the memory position of the last element
      let lastPosition := add(array, mul(length, 0x20))
      // Retrieve the last item
      item := mload(lastPosition)
      // Decrement array length
      mstore(array, sub(length, 1))
    }
    return item;
  }

  function _pop(address[] memory array) private pure returns (address item) {
    uint256 length = array.length;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let lastPosition := add(array, mul(length, 0x20))
      item := mload(lastPosition)
      mstore(array, sub(length, 1))
    }
    return item;
  }
}

pragma solidity 0.5.17;

/// @notice The implicit 8-ary trees of the sortition pool
/// rely on packing 8 "slots" of 32-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {
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
  uint256 constant LAST_SLOT = SLOT_COUNT - 1;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

  ////////////////////////////////////////////////////////////////////////////

  /// @notice Calculate the right shift required
  /// to make the 32 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint32[8].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint256 position) internal pure returns (uint256) {
    return position * SLOT_WIDTH;
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint32[32].
  function getSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Doing a bitwise AND with `SLOT_MAX`
    // clears all but the 32 least significant bits.
    // Because of the right shift by `slotShift(position)` bits,
    // those 32 bits contain the 32 bits in the `position`th slot of `node`.
    return (node >> shiftBits) & SLOT_MAX;
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Shifting `SLOT_MAX` left by `slotShift(position)` bits
    // gives us a number where all bits of the `position`th slot are set,
    // and all other bits are unset.
    //
    // Using a bitwise NOT on this number,
    // we get a uint256 where all bits are set
    // except for those of the `position`th slot.
    //
    // Bitwise ANDing the original `node` with this number
    // sets the bits of `position`th slot to zero,
    // leaving all other bits unchanged.
    return node & ~(SLOT_MAX << shiftBits);
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @param weight The weight of of the node.
  /// Safely truncated to a 32-bit number,
  /// but this should never be called with an overflowing weight regardless.
  function setSlot(
    uint256 node,
    uint256 position,
    uint256 weight
  ) internal pure returns (uint256) {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Clear the `position`th slot like in `clearSlot()`.
    uint256 clearedNode = node & ~(SLOT_MAX << shiftBits);
    // Bitwise AND `weight` with `SLOT_MAX`
    // to clear all but the 32 least significant bits.
    //
    // Shift this left by `slotShift(position)` bits
    // to obtain a uint256 with all bits unset
    // except in the `position`th slot
    // which contains the 32-bit value of `weight`.
    uint256 shiftedWeight = (weight & SLOT_MAX) << shiftBits;
    // When we bitwise OR these together,
    // all other slots except the `position`th one come from the left argument,
    // and the `position`th gets filled with `weight` from the right argument.
    return clearedNode | shiftedWeight;
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint256 node) internal pure returns (uint256 sum) {
    sum = node & SLOT_MAX;
    // Iterate through each slot
    // by shifting `node` right in increments of 32 bits,
    // and adding the 32 least significant bits to the `sum`.
    uint256 newNode = node >> SLOT_WIDTH;
    while (newNode > 0) {
      sum += (newNode & SLOT_MAX);
      newNode = newNode >> SLOT_WIDTH;
    }
    return sum;
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint256 node, uint256 index)
    internal
    pure
    returns (uint256 slot, uint256 newIndex)
  {
    newIndex = index;
    uint256 newNode = node;
    uint256 currentSlotWeight = newNode & SLOT_MAX;
    while (newIndex >= currentSlotWeight) {
      newIndex -= currentSlotWeight;
      slot++;
      newNode = newNode >> SLOT_WIDTH;
      currentSlotWeight = newNode & SLOT_MAX;
    }
    return (slot, newIndex);
  }
}

pragma solidity 0.5.17;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
/// The pool should specify a reasonable minimum bondable value for operators
/// trying to join the pool, to prevent griefing the selection.
contract BondedSortitionPool is AbstractSortitionPool {
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  struct PoolParams {
    IStaking stakingContract;
    uint256 minimumStake;
    IBonding bondingContract;
    // Defines the minimum unbounded value the operator needs to have to be
    // eligible to join and stay in the sortition pool. Operators not
    // satisfying minimum bondable value are removed from the pool.
    uint256 minimumBondableValue;
    // Bond required from each operator for the currently pending group
    // selection. If operator does not have at least this unbounded value,
    // it is skipped during the selection.
    uint256 requestedBond;
    // The weight divisor in the pool can differ from the minimum stake
    uint256 poolWeightDivisor;
    address owner;
  }

  PoolParams poolParams;

  constructor(
    IStaking _stakingContract,
    IBonding _bondingContract,
    uint256 _minimumStake,
    uint256 _minimumBondableValue,
    uint256 _poolWeightDivisor,
    address _poolOwner
  ) public {
    require(_minimumStake > 0, "Minimum stake cannot be zero");

    poolParams = PoolParams(
      _stakingContract,
      _minimumStake,
      _bondingContract,
      _minimumBondableValue,
      0,
      _poolWeightDivisor,
      _poolOwner
    );
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed and bonding requirements. All operators
  /// in the group are unique.
  ///
  /// If there are not enough operators in a pool to form a group or not
  /// enough operators are eligible for work selection given the bonding
  /// requirements, the function fails.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @param minimumStake The current minimum stake value
  /// @param bondValue Size of the requested bond per operator
  function selectSetGroup(
    uint256 groupSize,
    bytes32 seed,
    uint256 minimumStake,
    uint256 bondValue
  ) public returns (address[] memory) {
    PoolParams memory params = initializeSelectionParams(
      minimumStake,
      bondValue
    );
    require(msg.sender == params.owner, "Only owner may select groups");
    uint256 paramsPtr;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      paramsPtr := params
    }
    return generalizedSelectGroup(groupSize, seed, paramsPtr, true);
  }

  /// @notice Sets the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool. The pool should specify
  /// a reasonable minimum requirement for operators trying to join the pool
  /// to prevent griefing group selection.
  /// @param minimumBondableValue The minimum bondable value required from the
  /// operator.
  function setMinimumBondableValue(uint256 minimumBondableValue) public {
    require(
      msg.sender == poolParams.owner,
      "Only owner may update minimum bond value"
    );

    poolParams.minimumBondableValue = minimumBondableValue;
  }

  /// @notice Returns the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool.
  function getMinimumBondableValue() public view returns (uint256) {
    return poolParams.minimumBondableValue;
  }

  function initializeSelectionParams(uint256 minimumStake, uint256 bondValue)
    internal
    returns (PoolParams memory params)
  {
    params = poolParams;

    if (params.requestedBond != bondValue) {
      params.requestedBond = bondValue;
    }

    if (params.minimumStake != minimumStake) {
      params.minimumStake = minimumStake;
      poolParams.minimumStake = minimumStake;
    }

    return params;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    address ownerAddress = poolParams.owner;
    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = poolParams.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // Don't query stake if bond is insufficient.
    if (bondableValue < poolParams.minimumBondableValue) {
      return 0;
    }

    uint256 eligibleStake = poolParams.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // but only if eligibleStake >= minimumStake.
    // Ethereum uint256 division performs implicit floor
    // If eligibleStake < poolWeightDivisor, return 0 = ineligible.
    if (eligibleStake < poolParams.minimumStake) {
      return 0;
    }
    return (eligibleStake / poolParams.poolWeightDivisor);
  }

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory, // `selected`, for future use
    uint256 paramsPtr
  ) internal view returns (Fate memory) {
    PoolParams memory params;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      params := paramsPtr
    }
    address operator = leaf.operator();
    uint256 leafWeight = leaf.weight();

    if (!isLeafInitialized(leaf)) {
      return Fate(Decision.Skip, 0);
    }

    address ownerAddress = params.owner;

    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = params.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // If unbonded value is insufficient for the operator to be in the pool,
    // delete the operator.
    if (bondableValue < params.minimumBondableValue) {
      return Fate(Decision.Delete, 0);
    }
    // If unbonded value is sufficient for the operator to be in the pool
    // but it is not sufficient for the current selection, skip the operator.
    if (bondableValue < params.requestedBond) {
      return Fate(Decision.Skip, 0);
    }

    uint256 eligibleStake = params.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // Ethereum uint256 division performs implicit floor
    uint256 eligibleWeight = eligibleStake / params.poolWeightDivisor;

    if (eligibleWeight < leafWeight || eligibleStake < params.minimumStake) {
      return Fate(Decision.Delete, 0);
    }
    return Fate(Decision.Select, 0);
  }
}

pragma solidity 0.5.17;

import "./GasStation.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "./DynamicArray.sol";
import "./api/IStaking.sol";

/// @title Abstract Sortition Pool
/// @notice Abstract contract encapsulating common logic of all sortition pools.
/// @dev Inheriting implementations are expected to implement getEligibleWeight
/// function.
contract AbstractSortitionPool is SortitionTree, GasStation {
  using Leaf for uint256;
  using Position for uint256;
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  enum Decision {
    Select, // Add to the group, and use new seed
    Skip, // Retry with same seed, skip this leaf
    Delete, // Retry with same seed, delete this leaf
    UpdateRetry, // Retry with same seed, update this leaf
    UpdateSelect // Select and reseed, but also update this leaf
  }

  struct Fate {
    Decision decision;
    // The new weight of the leaf if Decision is Update*, otherwise 0
    uint256 maybeWeight;
  }

  // Require 10 blocks after joining before the operator can be selected for
  // a group. This reduces the degrees of freedom miners and other
  // front-runners have in conducting pool-bumping attacks.
  //
  // We don't use the stack of empty leaves until we run out of space on the
  // rightmost leaf (i.e. after 2 million operators have joined the pool).
  // It means all insertions are at the right end, so one can't reorder
  // operators already in the pool until the pool has been filled once.
  // Because the index is calculated by taking the minimum number of required
  // random bits, and seeing if it falls in the range of the total pool weight,
  // the only scenarios where insertions on the right matter are if it crosses
  // a power of two threshold for the total weight and unlocks another random
  // bit, or if a random number that would otherwise be discarded happens to
  // fall within that space.
  uint256 constant INIT_BLOCKS = 10;

  uint256 constant GAS_DEPOSIT_SIZE = 1;

  /// @notice The number of blocks that must be mined before the operator who
  // joined the pool is eligible for work selection.
  function operatorInitBlocks() public pure returns (uint256) {
    return INIT_BLOCKS;
  }

  // Return whether the operator is eligible for the pool.
  function isOperatorEligible(address operator) public view returns (bool) {
    return getEligibleWeight(operator) > 0;
  }

  // Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Return whether the operator's weight in the pool
  // matches their eligible weight.
  function isOperatorUpToDate(address operator) public view returns (bool) {
    return getEligibleWeight(operator) == getPoolWeight(operator);
  }

  // Returns whether the operator has passed the initialization blocks period
  // to be eligible for the work selection. Reverts if the operator is not in
  // the pool.
  function isOperatorInitialized(address operator) public view returns (bool) {
    require(isOperatorInPool(operator), "Operator is not in the pool");

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 leafPosition = flaggedPosition.unsetFlag();
    uint256 leaf = leaves[leafPosition];

    return isLeafInitialized(leaf);
  }

  // Return the weight of the operator in the pool,
  // which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = leaves[leafPosition].weight();
      return leafWeight;
    }
  }

  // Add an operator to the pool,
  // reverting if the operator is already present.
  function joinPool(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    require(eligibleWeight > 0, "Operator not eligible");

    depositGas(operator);
    insertOperator(operator, eligibleWeight);
  }

  // Update the operator's weight if present and eligible,
  // or remove from the pool if present and ineligible.
  function updateOperatorStatus(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    uint256 inPoolWeight = getPoolWeight(operator);

    require(eligibleWeight != inPoolWeight, "Operator already up to date");

    if (eligibleWeight == 0) {
      removeOperator(operator);
      releaseGas(operator);
    } else {
      updateOperator(operator, eligibleWeight);
    }
  }

  function generalizedSelectGroup(
    uint256 groupSize,
    bytes32 seed,
    // This uint256 is actually a void pointer.
    // We can't pass a SelectionParams,
    // because the implementation of the SelectionParams struct
    // can vary between different concrete sortition pool implementations.
    //
    // Whatever SelectionParams struct is used by the concrete contract
    // should be created in the `selectGroup`/`selectSetGroup` function,
    // then coerced into a uint256 to be passed into this function.
    // The paramsPtr is then passed to the `decideFate` implementation
    // which can coerce it back into the concrete SelectionParams.
    // This allows `generalizedSelectGroup`
    // to work with any desired eligibility logic.
    uint256 paramsPtr,
    bool noDuplicates
  ) internal returns (address[] memory) {
    uint256 _root = root;
    bool rootChanged = false;

    DynamicArray.AddressArray memory selected;
    selected = DynamicArray.addressArray(groupSize);

    RNG.State memory rng;
    rng = RNG.initialize(seed, _root.sumWeight(), groupSize);

    while (selected.array.length < groupSize) {
      rng.generateNewIndex();

      (uint256 leafPosition, uint256 startingIndex) = pickWeightedLeaf(
        rng.currentMappedIndex,
        _root
      );

      uint256 leaf = leaves[leafPosition];
      address operator = leaf.operator();
      uint256 leafWeight = leaf.weight();

      Fate memory fate = decideFate(leaf, selected, paramsPtr);

      if (fate.decision == Decision.Select) {
        selected.arrayPush(operator);
        if (noDuplicates) {
          rng.addSkippedInterval(startingIndex, leafWeight);
        }
        rng.reseed(seed, selected.array.length);
        continue;
      }
      if (fate.decision == Decision.Skip) {
        rng.addSkippedInterval(startingIndex, leafWeight);
        continue;
      }
      if (fate.decision == Decision.Delete) {
        // Update the RNG
        rng.updateInterval(startingIndex, leafWeight, 0);
        // Remove the leaf and update root
        _root = removeLeaf(leafPosition, _root);
        rootChanged = true;
        // Remove the record of the operator's leaf and release gas
        removeLeafPositionRecord(operator);
        releaseGas(operator);
        continue;
      }
      if (fate.decision == Decision.UpdateRetry) {
        _root = setLeaf(leafPosition, leaf.setWeight(fate.maybeWeight), _root);
        rootChanged = true;
        rng.updateInterval(startingIndex, leafWeight, fate.maybeWeight);
        continue;
      }
      if (fate.decision == Decision.UpdateSelect) {
        _root = setLeaf(leafPosition, leaf.setWeight(fate.maybeWeight), _root);
        rootChanged = true;
        selected.arrayPush(operator);
        rng.updateInterval(startingIndex, leafWeight, fate.maybeWeight);
        if (noDuplicates) {
          rng.addSkippedInterval(startingIndex, fate.maybeWeight);
        }
        rng.reseed(seed, selected.array.length);
        continue;
      }
    }
    if (rootChanged) {
      root = _root;
    }
    return selected.array;
  }

  function isLeafInitialized(uint256 leaf) internal view returns (bool) {
    uint256 createdAt = leaf.creationBlock();

    return block.number > (createdAt + operatorInitBlocks());
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256);

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory selected,
    uint256 paramsPtr
  ) internal view returns (Fate memory);

  function gasDepositSize() internal pure returns (uint256) {
    return GAS_DEPOSIT_SIZE;
  }
}