/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AzonProduct
{
    string private name;
    address private owner;
    address private contractAddress;
    uint24 private price;
    
    constructor(string memory _name, uint24 _price) payable
    {
        owner = msg.sender;
        contractAddress = address(this);
        name = _name;
        price = _price;
    }
    
    function getPrice() view public returns(uint24){ return price; }
    function getAddress() view public returns(address){ return contractAddress; }
    function getName() view public returns(string memory){ return name; }
    
    function setPrice(uint24 new_price) payable public
    {
        require(msg.sender == owner);
        price = new_price;
    }
}

contract AzonShop
{
    address owner;
    address[] goods;
    uint32 revenue = 0;
    constructor() { owner = msg.sender; }
    
    function addProduct(string memory new_name, uint24 new_price) public payable
    {
        require(msg.sender == owner);
        goods.push(address(new AzonProduct(new_name, new_price)));
    }
    
    function getProducts() view public returns(string[] memory, uint24[] memory, address[] memory)
    {
        string [] memory names = new string[](goods.length);
        uint24[] memory prices = new uint24[](goods.length);
        address[] memory adressess = new address[](goods.length);
        for (uint16 i = 0; i < goods.length; i++)
        {
            names[i] = AzonProduct(goods[i]).getName();
            prices[i] = AzonProduct(goods[i]).getPrice();
            adressess[i] = AzonProduct(goods[i]).getAddress();
        }
        return(names, prices, adressess);
    }
    
    function addToRevenue(uint32 money) payable public
    {
        revenue += money;
    }
}

contract ShoppingCart
{
    address owner;
    uint32 deposite;
    uint32 AllPrice;
    mapping(address => uint8) productsMap;
    
    constructor(uint24 _deposite)
    {
        deposite = _deposite;
        owner = msg.sender;
    }
    function addToCart(address productAddress, uint8 countProduct) public payable
    {
        require(msg.sender == owner);
        productsMap[productAddress] = countProduct;
        AllPrice += countProduct*AzonProduct(productAddress).getPrice();
    }
    
    function buyProduct(address ShopAzon, address productAddress) payable public
    {
        require(msg.sender == owner && deposite>= AllPrice && productsMap[productAddress] > 0);
        deposite -= AllPrice;
        AzonShop(ShopAzon).addToRevenue(AllPrice);
        productsMap[productAddress] -= 1;
    }
}