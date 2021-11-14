// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.7;

import './IBEP20.sol';

contract Payment {
    
    address public _admin;
    
    IBEP20 public token ; 
    
    struct Product {
        string name;
        bool isExist;
        uint price;
        uint expireInDays;
    }
    
    mapping (uint => Product) public products;
    
    uint public _id = 0;
    
    
    constructor() public {
        _admin = msg.sender;
        token  = IBEP20(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
    }
    
    
    modifier onlyAdmin (){
        require(msg.sender == _admin, "only for owner");
        _;
    }
    
    function addProduct (string memory _name, uint _price, uint _expireInDays) public onlyAdmin {
        require(_price >= 0, 'price is not valid');
        require(_expireInDays >= 1, 'expire days is not valid');
        
        Product memory product = Product({
            name : _name,
            price : _price,
            isExist : true,
            expireInDays: _expireInDays
        });
        
        _id++;
        products[_id] = product;
    }
    
    function buyProduct(uint _productID) public {
        require(products[_productID].isExist, 'Product not exists !');
        require(token.balanceOf(msg.sender) >= products[_productID].price, 'Value Incorrect');
        token.transferFrom(msg.sender, _admin , products[_productID].price);
    }
    
    function register (uint _productID , address r) public {
        address(r);
        this.buyProduct(_productID);
    }
    
    function getBalance (address wallet) public view returns (uint){
        return token.balanceOf(wallet);
    }
    
}