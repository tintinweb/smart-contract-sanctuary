/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Shop {
    uint256 public productCount = 1;
    uint256 public orderCount = 1;
    mapping(uint256 => Product) public Products;
    mapping(uint256 => Order) public Orders;
    address payable owner;

    constructor() {
        owner =payable(msg.sender);
    }

    struct Product {
        uint256 id;
        string title;
        uint256 price;
        uint256 stock;
        string image;
        string description;
    }

    struct Order {
        uint256 id;
        address customer;
        string customerName;
        string customerEmail;
        string customerAddress;
        uint256 date;
        uint256 amount;
        string status;
        uint256[] productsID;
    }

    event AddEvent(uint256 _id, string _title, address _address);
    event EditEvent(uint256 _id, string _title, address _address);
    event RemoveEvent(uint256 _id);
    event AddOrderEvent(address _customer, uint256 _amount);

    modifier onlyAdmin() {
        require(msg.sender == owner, "access denied");
        _;
    }

    function addProduct(string memory _title,uint256 _price,uint256 _stock,string memory _image,string memory _description) public onlyAdmin {
        Products[productCount] = Product(
            productCount,
            _title,
            _price,
            _stock,
            _image,
            _description
        );
        emit AddEvent(productCount, _title, msg.sender);
        productCount++;
    }

    function editProduct(uint256 _id,string memory _title,uint256 _price,uint256 _stock,string memory _image,string memory _description) public onlyAdmin {
        Products[_id].title = _title;
        Products[_id].price = _price;
        Products[_id].stock = _stock;
        Products[_id].image = _image;
        Products[_id].description = _description;
        emit EditEvent(_id, _title, msg.sender);
    }

    function productList() public view returns (Product[] memory) {
        Product[] memory list = new Product[](productCount);
        for (uint256 i = 0; i < productCount; i++) {
            Product storage obj = Products[i];
            list[i] = obj;
        }
        return list;
    }

    function deleteProduct(uint256 _id) public onlyAdmin {
        delete Products[_id];
        emit RemoveEvent(_id);
    }

    function addOrder(uint256[] memory _productsID,uint256[] memory _productsCount,string memory _customerName,string memory _customerEmail,string memory _customerAddress) public payable {
        uint256 amount = 0;
        for (uint256 i = 0; i < _productsID.length; i++) {
             require(Products[_productsID[i]].stock >= _productsCount[i], " out of stock");
            amount += (Products[_productsID[i]].price * _productsCount[i]);
        }
       require(amount == msg.value, "amount is less than ");
         for (uint256 i = 0; i < _productsID.length; i++) {
                Products[_productsID[i]].stock-=_productsCount[i];
         }

    Orders[orderCount] = Order(
            orderCount,
            msg.sender,
            _customerName,
            _customerEmail,
            _customerAddress,
            block.timestamp,
            amount,
            "waiting",
            _productsID
        );
 
        owner.transfer(msg.value);
        emit AddOrderEvent( msg.sender, amount);
    }
}