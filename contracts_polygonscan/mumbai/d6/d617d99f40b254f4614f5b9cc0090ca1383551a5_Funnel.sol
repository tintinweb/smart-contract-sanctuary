/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract Funnel {
    
    event PaymentMade(address from, uint storeId, uint productId);

    mapping(uint => address payable) public storeAddresses;
    mapping(uint => uint) public storeVolume;
    mapping(uint => uint) public storeProductAmount;

    struct Product {
        uint productId;
        uint price;
    }

    mapping(uint => Product) public storeProducts;

    uint storeAmount;

    function totalStores() public view returns (uint) {
        return storeAmount;
    }

    function registerStore(
        address payable storeAddress
    ) external returns (uint) {
        uint storeIndex = totalStores();
        storeAddresses[storeIndex] = storeAddress;
        storeAmount += 1;

        return storeIndex;
    }

    function makePayment(
        uint storeId,
        // uint amount
        uint productId
    ) external payable returns (bool) { 
        Product memory product = storeProducts[productId];
        uint price = product.price;
        require(msg.value==price, "Pay the right price");

        address payable storeAddress = storeAddresses[storeId];
        storeAddress.transfer(msg.value);
        storeVolume[storeId]+=msg.value;

        emit PaymentMade(msg.sender, storeId, productId);

        return true;
    }
    
    function totalProducts(
        uint storeId
    ) public view returns (uint) {
        return storeProductAmount[storeId];
    }
 
    function createProduct(
        uint storeId,
        uint price
    ) external returns (uint) {
        uint productIndex = totalProducts(storeId);
        Product memory product = Product(productIndex, price);
        storeProductAmount[storeId] += 1;
        storeProducts[productIndex] = product;

        return productIndex;
    }   

}