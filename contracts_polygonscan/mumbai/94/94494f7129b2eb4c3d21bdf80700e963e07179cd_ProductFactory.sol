/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract ProductFactory {

    event NewProduct(uint productId, string name);
    event DelegateProduct(uint productId, address newOwner, uint8 status);
    event AcceptProduct(uint productId, string name, uint8 status);

    struct Product {
        string name;
        uint8 status;
        address owner;
        address newOwner;

    }

    Product[] public products;

    mapping (uint => address) public productToOwner;
    mapping (address => uint) ownerProductCount;

    function createProduct (string memory _name) public {
        require(ownerProductCount[msg.sender] <= 10);
        products.push(Product(_name, 0, msg.sender, address(0)));
        uint id = products.length - 1;
        productToOwner[id] = msg.sender;
        ownerProductCount[msg.sender]++;
        emit NewProduct(id, _name);
    }
    function delegateProduct(uint _productId, address _newOwner) public{
        require (productToOwner[_productId]== msg.sender);
        require (products[_productId].status == 0, "is already delegated");
        Product storage p = products[_productId];
        p.status = 1;
        p.newOwner = _newOwner;
        emit DelegateProduct(_productId, _newOwner, p.status);

    }

    function acceptProduct(uint _productId) public{
        require (products[_productId].status == 1);
        require (products[_productId].newOwner == msg.sender);
        Product storage p = products[_productId];
        p.status = 0;
        p.newOwner = address(0);
        p.owner = msg.sender;
        emit AcceptProduct(_productId, p.name, p.status);
    }


}