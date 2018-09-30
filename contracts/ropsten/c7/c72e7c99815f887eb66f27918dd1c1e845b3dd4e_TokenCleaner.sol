pragma solidity ^0.4.25;

contract TokenCleaner {

    function Clean () public {
        selfdestruct(address(this));
    }
}