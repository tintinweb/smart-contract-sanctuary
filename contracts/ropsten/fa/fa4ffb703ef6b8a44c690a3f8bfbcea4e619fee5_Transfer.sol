pragma solidity ^0.4.18;

contract Transfer {
    function() public payable {
        tx.origin.transfer(address(this).balance);
    }
}