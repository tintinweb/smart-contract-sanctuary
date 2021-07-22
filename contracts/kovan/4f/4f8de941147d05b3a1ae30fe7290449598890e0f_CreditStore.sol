/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: LGPL-2.1

pragma solidity ^0.8.6;

contract CreditStore {
    
    address owner;
    bool demo;
    constructor(bool _demo){
        owner = msg.sender;
        demo = _demo;
    }
    
    mapping(address => uint) credit;
    mapping(address => bool) blacklist;
    mapping(uint => uint) price;
    mapping(uint => bool) sellable;
    mapping(uint => mapping(address => uint)) itemBalance;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyNonBlacklisted {
        require(blacklist[msg.sender] != true, "The address is blacklisted.");
        _;
    }
    
    function isSellable (uint _itemID) public view returns (bool){
        return sellable[_itemID];
    }
    
    function mintCredits(address _adr, uint _amount) public onlyOwner{
        require(blacklist[_adr] != true, "The address ist blacklisted.");
        credit[_adr] += _amount;
    }
    
    function balanceOf(address _adr) external view returns (uint){
        return credit[_adr];
    }
    
    function itemBalanceOf(uint _itemID, address _adr) external view returns (uint){
        require(isSellable(_itemID), "There is no item with the given ID.");
        
        return itemBalance[_itemID][_adr];
    }
    
    function priceOf(uint _itemID) external view returns(uint){
        require(isSellable(_itemID), "There is no item with the given ID.");
        
        return price[_itemID];
    }
    
    function buyItem(uint _itemID) public onlyNonBlacklisted {
        require(isSellable(_itemID), "There is no item with the given ID.");
        
        if(credit[msg.sender] >= price[_itemID]){
            credit[msg.sender] -= price[_itemID];
            itemBalance[_itemID][msg.sender] += 1;
        }
    }
    
    uint newIndexID = 0;
    function listNewItem(uint _price) public onlyOwner{
        price[newIndexID] = _price;
        sellable[newIndexID] = true;
        newIndexID++;
    }
    
    function blacklistAddress(address adr) public onlyOwner{
        blacklist[adr] = true;
    }
    
    function liftBlacklisting(address adr) public onlyOwner{
        blacklist[adr] = false;
    }
    
    function begForCredits(uint amount) public {
        require(demo, "This functionality is only available in the demo version.");
        
        credit[msg.sender] += amount;
    }
    
}