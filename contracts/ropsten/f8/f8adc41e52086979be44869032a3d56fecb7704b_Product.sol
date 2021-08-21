/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity ^0.4.2;

contract Product {
    string public productName;

    function ProductName () public {
        productName = "Bag";
    }

    function setProduct (string memory _name) public {
        productName = _name;
    }
    
    function getProductName () public view returns (string){
        return productName;
    }
}