/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity ^0.5.0;

contract FiveItemSale {
    mapping (bytes32 => Item) private items;
    bytes32 [] private itemKeys;
    uint private itemLength;

    struct Item{
        uint _price;
        address payable _owner;
    }

    event PurchasedItem(address buyer, bytes32 itemID, uint price);

    constructor() public{
        uint startPrice = 100000000000000; // 10^14 wei = 0.0001 eth
        
        itemKeys = [
            bytes32("AAA"),
            bytes32("BBB"),
            bytes32("CCC"),
            bytes32("DDD"),
            bytes32("EEE")
        ];

        itemLength = itemKeys.length;

        for (uint i = 0; i < itemLength; ++i){
            items[itemKeys[i]] = Item(startPrice, msg.sender);
        }
    }

    function getItems() public view returns(bytes32, uint,
                                            bytes32, uint,
                                            bytes32, uint,
                                            bytes32, uint,
                                            bytes32, uint){

        return (itemKeys[0], items[itemKeys[0]]._price,
                itemKeys[1], items[itemKeys[1]]._price,
                itemKeys[2], items[itemKeys[2]]._price,
                itemKeys[3], items[itemKeys[3]]._price,
                itemKeys[4], items[itemKeys[4]]._price);

    }

    function buyItem(bytes32 itemID) public payable{
        require(items[itemID]._price != 0, "Incorrect item ID");
        require(msg.sender != items[itemID]._owner, "Can't sell to myself");
        require(msg.value >= items[itemID]._price + items[itemID]._price/2, "Price must be 50% higher");

        items[itemID]._owner.transfer(msg.value);
        items[itemID]._owner = msg.sender;
        items[itemID]._price = msg.value;

        emit PurchasedItem(msg.sender, itemID, msg.value);
    }

}