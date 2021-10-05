/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity >=0.4.22;


contract Car {

    string public brand;
    uint public price;

    constructor (string Brand, uint Price){
        brand = Brand;
        price = Price;
    }

    function setBrand(string newBrand) public {
        brand = newBrand;
    }

    function setPrice(uint newPrice) public {
        price = newPrice;
    }
}