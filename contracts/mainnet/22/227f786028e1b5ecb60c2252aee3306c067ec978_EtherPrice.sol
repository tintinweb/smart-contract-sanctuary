pragma solidity ^0.4.0;


contract EtherPrice {

    uint256 private dollars;

    uint8 private cents;

    address private owner;

    modifier validateCents (uint256 _dollars, uint8 _cents) {
        require(_dollars > 0 || _cents > 0);
        require(_cents < 100);
        _;
    }

    function EtherPrice(uint256 _dollars, uint8 _cents) validateCents(_dollars, _cents) {
        owner = msg.sender;
        dollars = _dollars;
        cents = _cents;
    }

    function setPrice(uint256 _dollars, uint8 _cents) validateCents(_dollars, _cents) {
        require(owner == msg.sender);
        dollars = _dollars;
        cents = _cents;
    }

    function getPrice() constant returns (uint256, uint8) {
        return (dollars, cents);
    }
}