/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity >=0.5.0 <0.8.0;

contract Marketplace {
    string public name;
    uint public productCount = 0;
    mapping(uint => Product) public products;

    struct Product {
        uint id;
        string name;
        string factory;
        string creattime;
        string location;
        uint price;
        address payable owner;
        bool purchased;
        
    }

    event ProductCreated(
        uint id,
        string factory,
        string name,
        uint price,
        string creattime,
        string location,
        address payable owner,
        bool purchased
    );

    event ProductPurchased(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased
    );

    constructor() public {
        name = "Marketplace";
    }

    function createProduct(string memory _location,string memory _creattime,string memory _factory,string memory _name, uint _price) public {
        
        require(bytes(_location).length>0);
        
        require(bytes(_creattime).length>0);
        
        require(bytes(_factory).length>0);
        // Require a valid name
        require(bytes(_name).length > 0);
        // Require a valid price
        require(_price > 0);
        
        
        // Increment product count
        productCount ++;
        // Create the product
        products[productCount] = Product(productCount,_location, _creattime ,_factory , _name, _price, msg.sender, false);
        // Trigger an event
        emit ProductCreated(productCount, _factory,_name, _price,_creattime,_location, msg.sender, false);
    }

    function purchaseProduct(uint _id) public payable {
        // Fetch the product
        Product memory _product = products[_id];
        // Fetch the owner
        address payable _seller = _product.owner;
        // Make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);
        // Require that there is enough Ether in the transaction
        require(msg.value >= _product.price);
        // Require that the product has not been purchased already
        require(!_product.purchased);
        // Require that the buyer is not the seller
        require(_seller != msg.sender);
        // Transfer ownership to the buyer
        _product.owner = msg.sender;
        // Mark as purchased
        _product.purchased = true;
        // Update the product
        products[_id] = _product;
        // Pay the seller by sending them Ether
        address(uint160(_seller)).transfer(address(this).balance);
        // Trigger an event
        emit ProductPurchased(productCount, _product.name, _product.price, msg.sender, true);
    }
}