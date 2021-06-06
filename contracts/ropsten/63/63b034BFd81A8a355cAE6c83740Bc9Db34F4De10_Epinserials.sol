/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Epinserials {
    address private owner;
    uint private productCount = 0;
    mapping(uint => Product) public products;

    struct Product {
        uint id;
        string name;
        uint price;
        address payable owner;
        bool purchased;
        bool expired;
    }

    event Created(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased,
        bool expired
    );

    event Purchased(
        uint id,
        uint price,
        address payable owner,
        bool purchased
    );
    
    event Expired( uint id, bool expired );
       
    constructor() {owner = msg.sender; }
        
    function created(string memory _name, uint _price) public {
        require(owner == msg.sender, 'Not authorized');
        require(bytes(_name).length > 0);
        require(_price > 0);
        productCount ++;
        products[productCount] = Product(productCount, _name, _price, payable(msg.sender), false, false);
        emit Created(productCount, _name, _price,payable(msg.sender), false, false);
    }

    function purchased(uint _id) public payable {
        Product memory _product = products[_id];
        address payable _seller = _product.owner;
        require(_product.id > 0 && _product.id <= productCount);
        require(msg.value >= _product.price, 'price not attached');
        require(!_product.purchased,'Already purchased');
        require(_seller != msg.sender, 'Owner not allowed');
        _product.owner = payable(msg.sender);
        _product.purchased = true;
        products[_id] = _product;
        _product.owner.transfer(msg.value);
        emit Purchased(productCount, _product.price,payable(msg.sender), true);
    }
    
    function count() public view returns (uint) {
        require(owner == msg.sender, 'Not authorized'); // only owner can do it
        return productCount;
    }
    
     function expire(uint _id) public payable {
        Product memory _product = products[_id];
        require(_product.id > 0 && _product.id <= productCount);
        require(_product.purchased, 'Not yet purchased');
        require(_product.owner == msg.sender, 'Not owner');
        _product.expired = true;
        products[_id] = _product;
        emit Expired(productCount, true);
    }
}