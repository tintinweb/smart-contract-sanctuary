/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity >=0.8.2;

contract Marketplace {
    string public name;
    uint256 public productsCount = 0;
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

    constructor() {
        name = "Dapp Marketplace";
    }


    function createProduct(string memory _name, uint256 _price) public {
        // make sure the parameters are correct
        require(bytes(_name).length > 0, "");
        require(_price > 0, "");

        // increment product count
        productsCount++;

        // create product
        products[productsCount] = Product(
            productsCount,
            _name,
            _price,
            payable(msg.sender),
            false
        );

        // trigger an event
        emit ProductCreated(
            productsCount,
            _name,
            _price,
            payable(msg.sender),
            false
        );
    }

    function purchaseProduct(uint256 _id) public payable {
        // Fetch the product
        Product memory _product = products[_id];

        // Fetch the owner
        address payable _seller = _product.owner;

        // Make sure the product is valid
        require(
            !_product.purchased,
            "You can't buy this. Product is already sold"
        );
        require(
            _product.id > 0 && _product.id <= productsCount,
            "You can't buy this. Incorrct product.id"
        );
        require(
            msg.value >= _product.price,
            "You can't buy this. Not enough Eth"
        );
        require(
            _seller != msg.sender,
            "You can't buy your own product"
        );

        // Transfer ownership to the buyer
        _product.owner = payable(msg.sender);
        _product.purchased = true;

        // Mark as purchased
        products[_id] = _product;

        // Pay to the seller
        _seller.transfer(msg.value);

        // trigger an event
        emit ProductPurchased(
            _product.id,
            _product.name,
            _product.price,
            _product.owner,
            _product.purchased
        );
    }
}