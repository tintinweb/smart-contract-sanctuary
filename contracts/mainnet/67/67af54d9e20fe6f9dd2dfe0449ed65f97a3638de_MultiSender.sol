pragma solidity ^0.4.24;

contract MultiSender {
    function multiSend(uint256 amount, address[] addresses) public returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            addresses[i].transfer(amount);
        }
    }

    function () public payable {
        
    }
}