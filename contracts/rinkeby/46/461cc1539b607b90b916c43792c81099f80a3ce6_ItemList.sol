/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract ItemList {
    uint public itemCount = 0;

    struct Item {
        uint id;
        string proofdocument;
    }
    Item[] items;

    constructor() public {}

    function createItem(string memory _proofdocument) public {
        itemCount++;
        items.push(Item(itemCount, _proofdocument));
    }

    function getItems() external view returns(Item[] memory) {
        return items;
    }
}