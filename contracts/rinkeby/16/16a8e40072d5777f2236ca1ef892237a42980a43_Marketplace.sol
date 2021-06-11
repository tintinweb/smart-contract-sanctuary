/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.8.0;

contract Marketplace {
    string public name = "Dapp Uni";
    uint256 public productCount = 0;
    mapping(uint256 => Product) public products;

    struct Product {
        uint256 id;
        string name;
        uint256 price;
        address payable owner;
        bool purchased;
    }
    event ProductCreated(
        uint256 id,
        string name,
        uint256 price,
        address payable owner,
        bool purchased
    );
    event ProductPurchased(
        uint256 id,
        string name,
        uint256 price,
        address payable owner,
        bool purchased
    );

    function createProduct(string memory _name, uint256 _price) public {
        //Validator
        //It makes sure no gas cosummed when fail
        require(bytes(_name).length > 0);
        require(_price > 0);

        //Increment Product
        productCount++;
        //Create product
        products[productCount] = Product(
            productCount,
            _name,
            _price,
            payable(msg.sender),
            false
        );
        //Trigger event
        emit ProductCreated(
            productCount,
            _name,
            _price,
            payable(msg.sender),
            false
        );
    }

    function purchaseProduct(uint256 _id) public payable {
        //Fetch product
        Product memory _product = products[_id];
        //Fetch owner
        address payable _seller = _product.owner;
        //Check valid id
        require(_product.id > 0 && _product.id <= productCount);
        //Check enough balacne
        require(msg.value >= _product.price);
        //check not purchased
        require(!_product.purchased);
        //buyer not sender
        require(_seller != msg.sender);
        //Transfer ownership to buyer
        _product.owner = payable(msg.sender);
        //Mark as purchased
        _product.purchased = true;
        //Update product
        products[_id] = _product;
        //Pay to seller
        payable(address(_seller)).transfer(msg.value);
        // Trigger event
        emit ProductPurchased(
            productCount,
            _product.name,
            _product.price,
            payable(msg.sender),
            true
        );
    }
}