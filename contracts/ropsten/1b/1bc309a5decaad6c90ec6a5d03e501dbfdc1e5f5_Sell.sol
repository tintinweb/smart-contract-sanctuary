/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.4.23;

contract Sell {

    struct Product_Quantity{
        string _product_name;  
        uint256 _product_quantity;        
        uint256 _price_unity; 
        bool isValue;
    }

    mapping (address => Product_Quantity) product_owners;

    struct Seller{
        address _id;
        mapping(string => Product_Quantity) products;
    }

    Seller public seller;

    constructor() public {
        seller._id = msg.sender;
    }

    function add_product (string product_name, uint256 product_quantity, uint256 price_unity) public {        
        require(msg.sender == seller._id);
        if (seller.products[product_name].isValue) {
            seller.products[product_name]._product_quantity += product_quantity;
        }
        else{
            seller.products[product_name] = Product_Quantity(product_name, product_quantity, price_unity, true); 
        }
    }

    modifier hasEnoughEther (string product_name, uint256 quantity) {
        require (seller.products[product_name].isValue);  // does the product exists?
        uint256 neededEther = seller.products[product_name]._price_unity * quantity;
        require (msg.value == neededEther);  // did the buyer sent the correct value?
        _;
    }

    function buy (string product_name, uint256 quantity) payable public hasEnoughEther (product_name, quantity) {
        if (product_owners[msg.sender].isValue) {
            product_owners[msg.sender]._product_quantity += quantity; 
        } else {
            product_owners[msg.sender] = Product_Quantity(product_name, quantity, seller.products[product_name]._price_unity, true);
        }
        seller.products[product_name]._product_quantity -= quantity;
        seller._id.transfer(seller.products[product_name]._price_unity * quantity);
    }
}