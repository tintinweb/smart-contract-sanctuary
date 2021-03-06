/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract FiveItemSale {
    mapping (string => Item) private items;
    string[] private itemKeys;
    uint private itemLength;

    struct Item{
        uint _price;
        address payable _owner;
    }

    event PurchasedItem(address buyer, string itemID, uint price);

    constructor() public{
        uint startPrice = 100000000000000; // 10^14 wei = 0.0001 eth
        itemKeys = ["AAA", "BBB", "CCC", "DDD", "EEE"];
        itemLength = itemKeys.length;

        for (uint i = 0; i < itemLength; ++i){
            items[itemKeys[i]] = Item(startPrice, msg.sender);
        }
    }

    function getItems() public view returns(string[] memory, uint[] memory){
        string[] memory names = new string[](itemLength);
        uint[] memory prices = new uint[](itemLength);

        for (uint i = 0; i < itemLength; i++) {
            names[i] = itemKeys[i];
            prices[i] = items[itemKeys[i]]._price;
        }

        return (names, prices);
    }

    function buyItem(string memory itemID) public payable{
        require(items[itemID]._price != 0, "Incorrect item ID");
        require(msg.sender != items[itemID]._owner, "Can't sell to myself");
        require(msg.value >= items[itemID]._price + items[itemID]._price/2, "Price must be 50% higher");

        items[itemID]._owner.transfer(msg.value);
        items[itemID]._owner = msg.sender;
        items[itemID]._price = msg.value;

        emit PurchasedItem(msg.sender, itemID, msg.value);
    }

}