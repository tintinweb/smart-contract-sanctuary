/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function isOwner() public view returns(bool) {
        return (msg.sender == owner);
    }
    
    modifier onlyOwner() {
        require(isOwner(), 'only owner allow');
        _;
    }
}

contract Item {
    uint public index;
    uint public price;
    uint public paid;
    ItemManager manager;
    
    constructor(ItemManager _manager, uint _index, uint _price) {
        index = _index;
        price = _price;
        manager = _manager;
    }
    
    receive() external payable {
        require(paid == 0, 'item allready paid.');
        require(price == msg.value, 'only full payment allowed.');
        
        (bool success, )= address(manager).call{value: msg.value}(abi.encodeWithSignature("TriggerPayment(uint256)", index));
        require(success, 'TriggerPayment UnSuccess call');
    }
    
    fallback() external {}
}

contract ItemManager is Ownable {
    enum SupplyChainStatus{Created, Paid, Delivered}
    
    struct S_Item {
        Item _item;
        
        string _identifier;
        uint _itemPrice;
        ItemManager.SupplyChainStatus _status;
    }
    
    mapping(uint => S_Item) public items;
    
    uint ItemIndex;
    
    event SupplyChainStep(uint _ItemIndex, uint _step, Item _item);
    
    function CreateItem(string memory _identifier, uint _itemPrice) public onlyOwner {
        Item item = new Item(this, ItemIndex, _itemPrice);
        items[ItemIndex]._item = item;
        
        items[ItemIndex]._identifier = _identifier;
        items[ItemIndex]._itemPrice = _itemPrice;
        items[ItemIndex]._status = ItemManager.SupplyChainStatus.Created;
        
        emit SupplyChainStep(ItemIndex, uint(items[ItemIndex]._status), item);
        
        ItemIndex++;
    }
    
    function TriggerPayment(uint _ItemIndex) public payable {
        require(items[_ItemIndex]._itemPrice == msg.value, 'must pay full price.');
        require(items[_ItemIndex]._status == ItemManager.SupplyChainStatus.Created, 'items status not allow.');

        items[_ItemIndex]._status = ItemManager.SupplyChainStatus.Paid;
        
        emit SupplyChainStep(_ItemIndex, uint(items[_ItemIndex]._status), items[_ItemIndex]._item);
    }
    
    function TriggerDelivery(uint _ItemIndex) public onlyOwner {
        require(items[_ItemIndex]._status == ItemManager.SupplyChainStatus.Paid, 'must pay this item before delivery.');
        
        items[_ItemIndex]._status = ItemManager.SupplyChainStatus.Delivered;
        
        emit SupplyChainStep(_ItemIndex, uint(items[_ItemIndex]._status), items[_ItemIndex]._item);
    }
}