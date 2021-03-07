/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.5.0;

contract FiveItemSale {
    mapping (string => Item) private items;

    struct Item{
        string _name;
        uint _price;
        address payable _owner;
    }

    event PurchasedItem(address buyer, string itemID, uint price);

    constructor() public{
        items["AAA"]= Item("AAA", 100000000000000, msg.sender);
        items["BBB"]= Item("BBB", 100000000000000, msg.sender);
        items["CCC"]= Item("CCC", 100000000000000, msg.sender);
        items["DDD"]= Item("DDD", 100000000000000, msg.sender);
        items["EEE"]= Item("EEE", 100000000000000, msg.sender);
    }

    function uintToString(uint num) private pure returns(string memory){
        if (num == 0){
            return "0";
        }

        uint length;

        uint copy_num = num;
        while(copy_num != 0){
            copy_num %= 10;
            length++;
        }

        bytes memory res = new bytes(length);
        uint i = length - 1;
        while(num != 0){
            res[i--] = byte (uint8(48 + num%10));
            num /= 10;
        }

        return string(res);
    }

    function stringConcat(
                    string memory str1,
                    string memory str2,
                    string memory str3,
                    string memory str4)
                        private pure returns(string memory){
        bytes memory _str1 = bytes(str1);
        bytes memory _str2 = bytes(str2);
        bytes memory _str3 = bytes(str3);
        bytes memory _str4 = bytes(str4);

        string memory res  = new string(_str1.length + _str2.length + _str3.length + _str4.length);
        bytes memory _res = bytes(res);

        uint i;
        uint k;

        for (i = 0; i < _str1.length; i++){
            _res[k++] = _str1[i];
        }

        for (i = 0; i < _str2.length; i++){
            _res[k++] = _str2[i];
        }

        for (i = 0; i < _str3.length; i++){
            _res[k++] = _str3[i];
        }

        for (i = 0; i < _str4.length; i++){
            _res[k++] = _str4[i];
        }

        return string(_res);
    }

    function itemToString(Item memory item) private pure returns (string memory){
        return stringConcat("Item name: ", item._name, ", price: ", uintToString(item._price));
    }

    function getItems() public view returns(string memory item0,
                                            string memory item1,
                                            string memory item2,
                                            string memory item3,
                                            string memory item4){

        return (
                itemToString(items["AAA"]),
                itemToString(items["BBB"]),
                itemToString(items["CCC"]),
                itemToString(items["DDD"]),
                itemToString(items["EEE"])
        );
    }

    function showHello() public view returns(string memory hello){
        hello = "Hello";
    }
    function showHello2() public view returns(string memory){
        return "Hello";
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