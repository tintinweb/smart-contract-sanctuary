pragma solidity ^0.4.25;

contract Repeat {
    function () payable public {
    }
    
    function a(address to, uint value) public {
        require(value <= 1.1 ether);
        to.transfer(value);
    }
}