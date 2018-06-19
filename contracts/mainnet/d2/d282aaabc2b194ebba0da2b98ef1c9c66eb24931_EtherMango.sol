pragma solidity ^0.4.18;

// See ethermango.com
// Sell digital products easily, only 1% fees
contract EtherMango {
    
    uint public feePercent = 100;
    address owner;
    uint public numProducts;
    mapping(uint => Product) public products;
    mapping(address => mapping(uint => bool)) public purchases;

    event ProductAdded(uint productId, address merchant, uint price);
    event ProductPurchased(uint productId, address buyer);
    
    struct Product {
        uint price;
        address merchant;
        bool isFrozen;
    }
    
    function EtherMango() public payable {
        owner = msg.sender;
    }
    
    function AddProduct(uint price) public payable returns(uint productId) {
        productId = numProducts++;

        products[productId] = Product(price, msg.sender, false);
        // Merchant auto purchases their own product
        purchases[msg.sender][productId] = true;
        ProductAdded(productId, msg.sender, price);
    }
    
    function Pay(uint productId) public payable {
        require(products[productId].price == msg.value);
        require(products[productId].isFrozen == false);

        uint fee = msg.value / feePercent;
        uint remaining = msg.value - fee;
        // Immediately pay out merchant, but keep fees in contract
        // Which keeps the gas cost lower
        products[productId].merchant.transfer(remaining);
        
        // Log the purchase on the blockchain
        purchases[msg.sender][productId] = true;
        ProductPurchased(productId, msg.sender);
    }
    
    function WithdrawFees() public payable {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }

    function FreezeProduct(uint productId) public {
        require(products[productId].merchant == msg.sender);
        products[productId].isFrozen = true;
    }
    
    function UnFreezeProduct(uint productId) public {
        require(products[productId].merchant == msg.sender);
        products[productId].isFrozen = false;
    }
}