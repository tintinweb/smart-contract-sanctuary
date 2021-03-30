/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity >=0.8.0 <0.9.0;

abstract contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }
}

contract QualityProduct is Owned {
    bytes32 product_hash;

    constructor(bytes32 _product_hash) onlyOwner {
        setProduct(_product_hash);
    }

    function setProduct(bytes32 _product_hash) public onlyOwner {
        product_hash = _product_hash;
    }
}