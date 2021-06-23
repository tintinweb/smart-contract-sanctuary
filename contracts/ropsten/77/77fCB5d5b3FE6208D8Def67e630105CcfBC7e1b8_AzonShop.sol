/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract AzonGood
{
    string ProductName;
    uint32 private price;
    address immutable thisContract;
    address immutable Owner;
    
    constructor(string memory _ProductName, uint32 _price)
    {
        ProductName = _ProductName;
        price = _price;
        thisContract = address(this);
        Owner = msg.sender;
    }
    
    function getProductName() public view returns(string memory){
        return ProductName;
    }
    
    function getPrice() public view returns(uint32){
        return price;
    }
    
    function getAdress() public view returns(address){
        return thisContract;
    }
    
    function setPrice(uint32 _price) public payable{
        require(Owner == msg.sender);
        price = _price;
    }
}

contract AzonShop
{
    address[] goods;
    address immutable Owner;
    
    constructor()
    {
        Owner = msg.sender;
    }
    
    function addGood(string memory _ProductName, uint32 _price) public payable
    {
        require(msg.sender == Owner);
        goods.push(address(new AzonGood(_ProductName, _price)));
    }
    
    function getGoods() public view returns(string[] memory, uint32[] memory, address[] memory)
    {
        string[] memory names = new string[](goods.length);
        uint32[] memory prices = new uint32[](goods.length);
        for(uint i = 0; i < goods.length; i++)
        {
            names[i] = AzonGood(goods[i]).getProductName();
            prices[i] = AzonGood(goods[i]).getPrice();
        }
        return(names,prices,goods);
    }
}