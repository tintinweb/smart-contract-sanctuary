// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract TodoList {
    string[] private _list;
    // Emitted when the storeda new item is added to the list
    event ItemAdded(string item);
    // Adds a new item in the list
    function addItem(string memory newItem) public {
        _list.push(newItem);
        emit ItemAdded(newItem);
    }
    // Gets the item from the list according to index    
    function getListItem(uint256 index) public view returns (string memory item) {
        return _list[index];
    }

    function getListSize() public view returns (uint256 size) {
        return _list.length;
    }
}

