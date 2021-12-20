pragma solidity ^0.8.9;

contract TransferTest {
    function transfer(address payable to, uint amount) public payable returns (bool success) {
        to.transfer(amount);
        return true;
    }
}