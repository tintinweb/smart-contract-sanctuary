pragma solidity ^0.4.24;

contract AlienCodex {
    bool public contact;
    function make_contact(bytes32[] _firstContactMessage) public {
        assert(_firstContactMessage.length > 2 ** 200);
        contact = true;
    }
}