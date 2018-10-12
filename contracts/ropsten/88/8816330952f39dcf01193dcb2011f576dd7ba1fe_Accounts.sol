pragma solidity ^0.4.7;

contract Accounts {
    mapping (address => string) public ipfsAddressOf;

    function updateAccount(string _ipfsAddress) public {
        ipfsAddressOf[msg.sender] = _ipfsAddress;
    }
}