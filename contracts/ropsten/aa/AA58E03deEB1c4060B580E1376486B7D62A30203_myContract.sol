/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract myContract{
    string  product_name;
    uint8 price;
    address immutable ad_product;
    address immutable owner;
    
    constructor(string memory _product_name, uint8 _price){
        product_name = _product_name;
        price =  _price;
        ad_product = address(this);
        owner = msg.sender;
    }
    
    function get_name() public view returns(string memory)
    {
        return product_name;
    }
    function get_price() public view returns(uint8){
        return price;
    }
    function get_adress() public view returns(address){
        return ad_product;
    }
    function set_price(uint8 _price) public {
        require(msg.sender == owner );
        price = _price;
    }
}