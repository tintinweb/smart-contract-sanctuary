/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0;


contract Product
{
    string name;
    uint32 cost;
    address thisContract;
    address owner;
    
    
    constructor (string memory _name, uint32 _cost)
    {
        name = _name;
        cost = _cost;
        thisContract = address(this);
        owner = msg.sender;
    }
    
    
    function getName() public view returns(string memory)
    {
        return name;
    }
    
    function getCost() public view returns(uint32)
    {
        return cost;
    }
    
    function getAddress() public view returns(address)
    {
        return thisContract;
    }
    
    function setCost(uint32 _cost) public payable
    {
        require(owner == msg.sender);
        
        cost = _cost;
    }
}




contract Shop
{
    address[] products;
    string[] names;
    uint32[] costs;
    address owner_shop;
    
    
    constructor()
    {
        owner_shop = msg.sender;
    }
    
    
    function add_element(address address_product) public payable
    {
        require(owner_shop == msg.sender);
        
        products.push(address_product);
    }
    
    function get_products() public payable returns(string[] memory, uint32[] memory, address[] memory)
    {
        for (uint i = 0; i < products.length; i++)
        {
            names.push(Product(products[i]).getName());
            costs.push(Product(products[i]).getCost());
        }
        
        return (names, costs, products);
    }
}