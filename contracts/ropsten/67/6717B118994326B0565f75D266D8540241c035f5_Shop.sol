/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Product
{
    string name;
    uint32 price;
    address immutable addr;
    address immutable owner;
    
    // любая вещь, неограничена, поэтому добавим ограничение в количестве
    uint32 count;
   
    constructor(string memory _name, uint32 _price, uint32 StartCount){
        name = _name;
        price = _price;
        count = StartCount;
        addr = address(this);
        owner = msg.sender;
    }
   
    function GetName() public view returns(string memory){
        return name;
    }
   
    function GetPrice() public view returns(uint32){
        return price;
    }
   
    function GetAddr() public view returns(address){
        return addr;
    }
   
    function SetPrice(uint32 _price) public payable{
        require(owner == msg.sender);
        price = _price;
    }
    
    function AddCount(uint32 _addCount) public payable{
        require(owner == msg.sender);
        count += _addCount;
    }
    
    function SubCount(uint32 _subCount) public payable{
        require(owner == msg.sender);
        if(count < _subCount){
            return;
        }
        count -= _subCount;
    }
}

contract Shop{
    address[] Products;
    address immutable owner;
    string[] Names;
    uint32[] Prices;
    address[] Addresses;
    ShopCart[] ShopCarts;
   
    uint32 Revenue = 0;
   
    constructor(){
        owner = msg.sender;
    }
   
    function AddProduct(string memory _name, uint32 _price, uint32 _count) public payable{
        require(owner == msg.sender);
        Products.push(new Product(_name, _price, _count).GetAddr());
        Names.push(_name);
        Prices.push(_price);
        Addresses.push(Products[Products.length - 1]);
    }
    
    function GetAllProducts() public view returns(string[] memory, uint32[] memory, address[] memory){
        return(Names, Prices, Addresses);
    }
    
    function Buy(uint32 price) public payable{
        Revenue += price;
    }
    
    // если вещь закончилась, то надо ее докупить по определенной цене
    function AddCount(uint32 _toBuy, uint32 _priceToBuy, address ProductAddr) public payable{
        require(owner == msg.sender);
        Product(ProductAddr).AddCount(_toBuy);
        Revenue -= _toBuy * _priceToBuy;
    }
}


contract ShopCart{
    // пускай покупать сможет не только владелец контракта, но и обычный покупатель
    address immutable buyer;
    mapping(address => uint16) cart;
    uint32 deposit;
    uint32 sum;
    
    constructor(uint16 _deposit){
        deposit = _deposit;
        buyer = msg.sender;
    }
   
    function AddProductToCart(address ProductAddr, uint16 count) public payable{
        require(buyer == msg.sender);
        cart[ProductAddr] = count;
        sum += Product(ProductAddr).GetPrice() * count;
        Product(ProductAddr).SubCount(count);
    }
    
    function Buy(address ShopAd, uint32 Price) public payable{
        require(deposit >= sum);
        deposit -= Price;
        Shop(ShopAd).Buy(Price);
    }
}