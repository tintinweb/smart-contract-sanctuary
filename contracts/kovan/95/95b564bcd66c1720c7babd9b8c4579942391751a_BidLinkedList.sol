/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: BidLinkedList.sol

contract BidLinkedList {
  struct Node {
    uint112 next; // next index in linked list
    uint112 price; // bid price
  }

  uint112 public constant HEAD = type(uint112).max - 1; // HEAD node index
  uint112 public constant LAST = type(uint112).max; // LAST node index
  address public immutable owner; // Owner address
  mapping(uint => Node) public nodes; // Mapping from index to Node

  /// @dev Initializes the linked list.
  /// @notice Should be called only once in constructor.
  constructor() {
    nodes[HEAD] = Node({next: LAST, price: type(uint112).max});
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'not owner');
    _;
  }

  /// @dev Returns the last index in the linked list that has price >= input price.
  /// @param _price Input price to compare.
  /// @return Index of the last node to return.
  function searchIndexByPrice(uint112 _price) public view returns (uint112) {
    uint112 curIndex = HEAD;
    uint112 nextIndex = nodes[curIndex].next;
    uint112 nextPrice = nodes[nextIndex].price;
    while (nextPrice >= _price) {
      curIndex = nextIndex;
      nextIndex = nodes[curIndex].next;
      nextPrice = nodes[nextIndex].price;
    }
    return curIndex;
  }

  /// @dev Inserts a new node to the linked list.
  /// @param _prevIndex Previous node index to insert after.
  /// @param _curIndex Current node index to insert.
  /// @param _price Bid price info.
  function insert(
    uint112 _prevIndex,
    uint112 _curIndex,
    uint112 _price
  ) external onlyOwner {
    require(_price > 0, 'price 0');
    require(nodes[_curIndex].next == 0, 'cur next not 0');
    require(nodes[_curIndex].price == 0, 'cur price not 0');

    Node storage prevNode = nodes[_prevIndex];
    uint112 nextIndex = prevNode.next;
    if (
      nextIndex == 0 ||
      prevNode.price < _price ||
      prevNode.price == 0 ||
      _price <= nodes[nextIndex].price
    ) {
      _prevIndex = searchIndexByPrice(_price);
      prevNode = nodes[_prevIndex];
      nextIndex = prevNode.next;
    }
    require(nextIndex != 0, 'zero next index');
    require(prevNode.price >= _price, 'prev price less than cur');
    require(prevNode.price != 0, 'prev price 0');
    require(_price > nodes[nextIndex].price, 'cur price not less than prev next');
    nodes[_curIndex] = Node({next: nextIndex, price: _price});
    prevNode.next = _curIndex;
  }

  /// @dev Removes a node at certain index from the linked list.
  /// @param _prevIndex Previous node index to remove the next node.
  /// @param _curIndex Current node index to remove.
  /// @notice Prev node's next must be cur.
  function _remove(uint112 _prevIndex, uint112 _curIndex) internal {
    nodes[_prevIndex].next = nodes[_curIndex].next;
    delete nodes[_curIndex];
  }

  /// @dev Returns the index before the target index in the linked list.
  /// @param _index The target index.
  /// @return The previous index whose next is the input index.
  function searchIndexByIndex(uint112 _index) public view returns (uint112) {
    uint112 curIndex = HEAD;
    uint112 nextIndex = nodes[curIndex].next;
    while (nextIndex != _index) {
      if (nextIndex == LAST) {
        revert('index not found in list');
      }
      curIndex = nextIndex;
      nextIndex = nodes[curIndex].next;
    }
    return curIndex;
  }

  /// @dev Removes a node from the linked list at current index.
  /// @param _prevIndex Previous node index to remove the next node.
  /// @param _curIndex Current node index to remove.
  function removeAt(uint112 _prevIndex, uint112 _curIndex) external onlyOwner {
    if (nodes[_prevIndex].next != _curIndex) {
      _prevIndex = searchIndexByIndex(_curIndex);
    }
    require(nodes[_prevIndex].next == _curIndex, 'prev next not cur');
    require(nodes[_curIndex].next != 0, 'cur next 0');
    require(nodes[_curIndex].price != 0, 'cur price 0');
    _remove(_prevIndex, _curIndex);
  }

  /// @dev Returns the frontmost node info.
  /// @return Frontmost node's index and price.
  /// @notice Reverts if no node in the linked list.
  function front() external view returns (uint112, uint112) {
    uint112 curIndex = nodes[HEAD].next;
    require(curIndex != LAST, 'no node');
    Node storage cur = nodes[curIndex];
    return (curIndex, cur.price);
  }

  /// @dev Removes the frontmost node.
  /// @notice Reverts if no node in the linked list.
  function removeFront() external onlyOwner {
    uint112 nextIndex = nodes[HEAD].next;
    require(nextIndex != LAST, 'empty linked list');
    _remove(HEAD, nextIndex);
  }

  /// @dev Returns the highest bid price.
  /// @return The highest bid price.
  function highestBidPrice() external view returns (uint112) {
    uint112 curIndex = nodes[HEAD].next;
    Node storage cur = nodes[curIndex];
    return cur.price;
  }
}