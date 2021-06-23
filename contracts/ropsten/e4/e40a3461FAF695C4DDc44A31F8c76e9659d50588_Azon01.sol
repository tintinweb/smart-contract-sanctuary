/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Azon00{
    string  product_name;
    uint8 price;
    address[] prodContracts;
    address immutable ad_product;
    address immutable owner;
    
    constructor(string memory _product_name, uint8 _price){
        product_name = _product_name;
        price =  _price;
        ad_product = address(this);
        owner = msg.sender;
    }
    
    function get_name() public view returns(string memory)
    {
        return product_name;
    }
    function get_price() public view returns(uint8){
        return price;
    }
    function get_adress() public view returns(address){
        return ad_product;
    }
    function set_price(uint8 _price) public {
        require(msg.sender == owner );
        price = _price;
    }
}

contract Azon01
{
    uint32 cash = 0;
    address[] products;
    address immutable owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    function addProduct(string memory _product_name, uint8 _price)public payable
    {
         require(msg.sender == owner );
         products.push(address (new Azon00(_product_name, _price)));
    }
    
    function getProducts()public view returns(string[] memory, uint8[] memory, address[] memory)
    {
        string[] memory names = new string[](products.length);
        uint8[] memory prices = new uint8[](products.length);
        for (uint i = 0; i < products.length; i++)
        {
            names[i] = Azon00(products[i]).get_name();
            prices[i] = Azon00(products[i]).get_price();
        }
        return (names, prices,products);
    }
    function buy(address _azonCart) public payable
    {
        cash += Azon02(_azonCart).buy(msg.sender);
    }
}
contract Azon02
{
    address owner;
    mapping(address => uint16) cart;
    uint32 deposit = 0;
    uint32 sum = 0;
    
    constructor(uint32 _deposit)
    {
        deposit = _deposit;
        owner = msg.sender;
    }
    
    function addproductToCart(address _product_Address, uint16 _product_Count) public payable
    {
        cart[_product_Address] = _product_Count;
        sum += Azon00(_product_Address).get_price() * _product_Count;
    }
    
    function buy(address _buyer) public payable returns(uint32)
    {
        if(_buyer == owner && deposit >= sum)
        {
            uint32 cash = sum;
            deposit-= sum;
            sum = 0;
            return cash;
        }
        else
        {
        
        return 0;
        }
    }
}