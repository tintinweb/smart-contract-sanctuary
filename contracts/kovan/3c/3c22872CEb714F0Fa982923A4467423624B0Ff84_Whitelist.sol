pragma solidity ^0.8.5;

contract Whitelist {
    mapping(address => bool) public addresses;

    function join() public {
        addresses[msg.sender] = true;
    }

    function isAddressWhitelisted(address address_) public view returns (bool) {
        return addresses[address_];
    }
}

