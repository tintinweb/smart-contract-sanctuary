pragma solidity ^0.4.13;

contract Agent {
    
    function g(address addr) payable {
        addr.transfer(msg.value);
    }

}