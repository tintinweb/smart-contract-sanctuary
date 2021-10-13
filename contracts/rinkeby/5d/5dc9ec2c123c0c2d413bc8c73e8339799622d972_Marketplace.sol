/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.5.16;

contract Marketplace {
    string public name;
    uint256 public productCount = 0;
    mapping(uint256 => Product) public products;

    struct Product {
        uint256 id;
        string name;
        uint256 price;
        address payable owner;
        bool visible;
    }

    event ProductChanged(
        uint256 id,
        string name,
        uint256 price,
        address payable owner,
        bool visible
    );

    constructor() public {
        name = "smart marketplace";
    }

    function createProduct(string memory _name, uint256 _price) public {
        require(bytes(_name).length > 0);
        require(_price > 0);
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _price,
            msg.sender,
            true
        );
        emit ProductChanged(productCount, _name, _price, msg.sender, true);
    }

    function hideProduct(uint256 _id) public {
        Product memory _product = products[_id];
        require(_product.id > 0 && _product.id <= productCount);
        require(_product.owner == msg.sender);
        _product.visible = false;
        products[_id] = _product;
        emit ProductChanged(
            productCount,
            _product.name,
            _product.price,
            msg.sender,
            _product.visible
        );
    }

    function purchaseProduct(uint256 _id) public payable {
        Product memory _product = products[_id];
        address payable _seller = _product.owner;
        require(_product.id > 0 && _product.id <= productCount);
        require(msg.value >= _product.price);
        require(_seller != msg.sender);
        require(_product.visible);
        _product.owner = msg.sender;
        products[_id] = _product;
        address(_seller).transfer(msg.value);
        emit ProductChanged(
            productCount,
            _product.name,
            _product.price,
            msg.sender,
            _product.visible
        );
    }
}