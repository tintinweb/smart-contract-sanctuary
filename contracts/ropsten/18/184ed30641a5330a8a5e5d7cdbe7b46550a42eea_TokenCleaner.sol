pragma solidity ^0.4.25;

contract TokenCleaner {

    function () public payable {
    }

    function Clean () public {
        selfdestruct(address(this));
    }
}