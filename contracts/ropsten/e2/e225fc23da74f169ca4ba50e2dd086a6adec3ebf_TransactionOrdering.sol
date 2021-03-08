/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.4.18;

contract TransactionOrdering {
    uint256 price;
    address owner;
    
    event Purchase(address _buyer, uint256 _price);
    event PriceChange(address _owner, uint256 _price);
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function TransactionOrdering() {
        // constructor
        owner = msg.sender;
        price = 100;
    }

    function buy() returns (uint256) {
        Purchase(msg.sender, price);
        return price;
    }

    function setPrice(uint256 _price) ownerOnly() {
        price = _price;
        PriceChange(owner, price);
    }
}