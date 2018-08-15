pragma solidity ^0.4.23;

contract DecentralizedMarket {
    struct Product {
        bytes32 storage_hash;
        bytes1 protocol_type;
    }

    // This declares a state variable that
    // stores a `product` struct for each possible address.
    mapping(address => Product) public products;
    address[] public sellerAccts;

    function StoreProduct(bytes32 _hash,bytes1 _ptype) public {

    Product storage dataproduct = products[msg.sender];

    dataproduct.storage_hash = _hash;
    dataproduct.protocol_type = _ptype;

    sellerAccts.push(msg.sender) -1;
    }

    function getProductCount() public constant returns(uint productCount) {
    return sellerAccts.length;
    }

}