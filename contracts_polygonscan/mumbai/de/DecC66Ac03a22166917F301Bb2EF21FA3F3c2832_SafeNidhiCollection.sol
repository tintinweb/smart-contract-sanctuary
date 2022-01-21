// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./NidhiCollection.sol";

library SafeNidhiCollection {

    function safeAdd(
        mapping (address => NidhiCollection) storage collections,
        address who,
        uint itemId
    ) public {
        NidhiCollection collection = collections[who];
        if (address(collection) == address(0)) {
            collections[who] = collection = new NidhiCollection();
        }
        collection.append(itemId);
    }

    function safeRemove(NidhiCollection collection, uint itemId) public {
        if (address(collection) != address(0)) {
            collection.remove(itemId);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract NidhiCollection {

    struct Item {
        uint prev;
        uint next;
        uint itemId;
    }

    uint public size;
    uint private _head;
    uint private _tail;

    address private immutable _owner;

    mapping (uint => Item) private _items;

    constructor() {
        _owner = msg.sender;
    }

    function append(uint itemId) public onlyOwner {
        Item memory item;
        item.itemId = itemId;
        if (size++ == 0) {
            _head = _tail = itemId;
        } else {
            item.prev = _tail;
            _items[_tail].next = itemId;
            _tail = itemId;
        }
        _items[itemId] = item;
    }

    function remove(uint itemId) public onlyOwner {
        uint prev = _items[itemId].prev;
        uint next = _items[itemId].next;
        if (--size == 0) {
            _head = _tail = 0;
        } else {
            if (_head == itemId) {
                _head = _items[itemId].next;
            }
            if (_tail == itemId) {
                _tail = _items[itemId].prev;
            }
            _items[prev].next = next;
            _items[next].prev = prev;
        }
        delete _items[itemId];
    }

    function get(uint id) public view returns (Item memory) {
        return _items[id];
    }

    function getNext(Item memory current, bool ascending)
        public
        view
        returns (Item memory)
    {
        return get(ascending ? current.next : current.prev);
    }

    function head() public view returns (Item memory) {
        return _items[_head];
    }

    function tail() public view returns (Item memory) {
        return _items[_tail];
    }

    function first(bool ascending) public view returns (Item memory) {
        return ascending ? head() : tail();
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }
}