/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.3;

contract TodoList {
    string[] private list;

    // Emitted when the storeda new item is added to the list
    event ItemAdded(string item);
    constructor() public {}

    // Adds a new item in the list
    function addItem(string memory newItem) public {
        list.push(newItem);
        emit ItemAdded(newItem);
    }

    // Gets the item from the list according to index
    function getListItem(uint256 index)
        public
        view
        returns (string memory item)
    {
        return list[index];
    }
}