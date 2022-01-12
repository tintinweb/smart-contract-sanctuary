/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

error NotOwner();
error ProductNotFound();
error ProductExists();
error InvalidName();
error InvalidQuantity();
error InvalidPrice();
error NoProductsInStock();
error TransferFailed();
error DuplicateProduct();
error NotEnoughWei();
error ProductNotBought();
error RefundPeriodOver();

contract  Store {

    // Allowed period in number of mined blocks for returning a product
    uint constant RETURN_PERIOD = 100;

    struct Product {
        uint id;
        string name;
        uint quantity;
        uint price;
        address[] clients;  // A list of addresses of clients that have bought the product
    }

    address public owner;

    // List of all products
    Product[] public products;

    // Used to efficiently check if a product exists by a given `name`
    mapping(string => bool) private existingProductNames;

    // Used to efficiently check if a product is bought by a client
    mapping(uint => mapping(address => uint)) private boughtProducts;

    constructor() {
        // Whoever deploys the contract is assigned as the owner
        owner = msg.sender;
    }

    modifier requireOwner() {
        if (owner != msg.sender) revert NotOwner();
        _;
    }

    modifier productExists(uint _id) {
        if (_id < 0 || _id >= products.length || products[_id].price <= 0) revert ProductNotFound();
        _;
    }

    modifier productDoesNotExist(string calldata _name) {
        if (existingProductNames[_name]) revert ProductExists();
        _;
    }

    modifier validateProduct(string calldata _name, uint _quantity, uint _price) {
        if (bytes(_name).length <= 0) revert InvalidName();
        if (_quantity <= 0) revert InvalidQuantity();
        if (_price <= 0) revert InvalidPrice();
        _;
    }

    // The owner can add new products to the contract
    function addProduct(string calldata _name, uint _quantity, uint _price) external
        requireOwner 
        productDoesNotExist(_name)
        validateProduct(_name, _quantity, _price) {

        address[] memory emptyClients;
        products.push(Product({
            id: products.length,
            name: _name,
            quantity: _quantity,
            price: _price,
            clients: emptyClients
        }));

        existingProductNames[_name] = true;
    }

    // The owner can edit the quantity of existing products
    function updateQuantity(uint _productId, uint _quantity) external requireOwner productExists(_productId) {
        products[_productId].quantity = _quantity;
    }

    // The owner can edit the price of existing products
    function updatePrice(uint _productId, uint _price) external requireOwner productExists(_productId) {
        if (_price <= 0) revert InvalidPrice();
        products[_productId].price = _price;
    }

    // Returns a filtered list of all available products (quantity > 0)
    function listProducts() external view returns(Product[] memory) {

        uint resultCount = 0;

        for (uint i = 0; i < products.length; i++) {
            Product memory p = products[i];
            if (p.quantity > 0) {
                resultCount++;
            }
        }

        Product[] memory availableProducts = new Product[](resultCount);

        uint j = 0;
        for (uint i = 0; i < products.length; i++) {
            Product memory p = products[i];
            if (p.quantity > 0) {
                availableProducts[j] = Product({
                    id: p.id,
                    name: p.name,
                    quantity: p.quantity,
                    price: p.price,
                    clients: p.clients
                });
                j++;
            }
        }

        return availableProducts;
    }

    function buyProduct(uint _productId) external payable productExists(_productId) {
        // Validates that the client is allowed to buy the selected product
        if (products[_productId].quantity <= 0) revert NoProductsInStock();        
        if (boughtProducts[_productId][msg.sender] != 0) revert DuplicateProduct();
        if (msg.value < products[_productId].price) revert NotEnoughWei();

        // Updates blockchain data
        products[_productId].quantity--;
        products[_productId].clients.push(msg.sender);
        boughtProducts[_productId][msg.sender] = block.number;
    }

    function returnProduct(uint _productId) external payable {

        // Validate that the client is allowed to return the selected product
        if (boughtProducts[_productId][msg.sender] <= 0) revert ProductNotBought();
        if (block.number - boughtProducts[_productId][msg.sender] >= RETURN_PERIOD) revert RefundPeriodOver();

        Product memory p = products[_productId];

        // Transaction to returns the client's funds
        (bool success, ) = msg.sender.call{value: p.price}("");
        if (!success) revert TransferFailed();

        // Updates blockchain data
        for (uint i = 0; i < p.clients.length; i++) {
            if (p.clients[i] == msg.sender) {
                uint lastIndex = p.clients.length - 1;
                p.clients[i] = p.clients[lastIndex];
                delete p.clients[lastIndex];
                break;
            }
        }

        products[_productId].quantity++;
        delete boughtProducts[_productId][msg.sender];
    }

    // Owner can withdraw funds
    function withdraw() external payable requireOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    // Allows depositing funds to the contract
    receive() external payable {}
    fallback() external payable {}
}