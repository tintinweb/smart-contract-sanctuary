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
