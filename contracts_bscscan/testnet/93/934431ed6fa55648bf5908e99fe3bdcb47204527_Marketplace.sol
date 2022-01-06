/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {

    string public name;

    struct Product {
        uint id;
        string name;
        uint price;
        address owner;
        bool purchased;
    }
    mapping(uint => Product) public products;
    uint public productCount = 0;

    event ProductCreated(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased
    );

    event ProductPurchased(
        uint id,
        string name,
        uint price,
        address owner,
        bool purchased
    );





    constructor() {
        name = "Marketplace";
    }

    function createProduct(string memory _name, uint _price) public {
        //require name
        //require(bytes(_name).length > 0, "The name cannot be blank");

        //require price
        //require(_price > 0,"The price must be ");
        //make sure paameters are correct
        
        //increment product constructor
        productCount++;
        //create product
        products[productCount] = Product(productCount,_name, _price,payable(msg.sender),false);
        //trigger event
        emit ProductCreated(productCount,_name, _price,payable(msg.sender),false);


    }

    function purchaseProduct(uint _id)public payable {
            //fetch the product
        Product memory _product = products[_id];
            //fetch the owner
         address _seller = _product.owner;
            //make sure the product is valid
        require(_product.id > 0 && _product.id <= productCount, "Invalid product Id!");
            //purchase productCount
        require(msg.value >= _product.price, "Price does not meet the product price!");  
        require(!_product.purchased, "Sorry, the product has already been purchased!");
        require(_seller != msg.sender, "You cannot buy your own product!");      
            //mark as purchased
        _product.purchased = true;
            //transfer ownership
        _product.owner  = msg.sender;
            //update the product
        products[_id] = _product;
            //pay the seller
        payable(_seller).transfer(msg.value);
        
            //trigger event
        emit ProductPurchased(productCount,_product.name, _product.price,msg.sender,true);
    }



    // contract bracket
}