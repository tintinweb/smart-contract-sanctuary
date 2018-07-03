pragma solidity ^0.4.24;

contract Splitter {
    address firstRecipient = 0xF34fd541478A03B1a5e5Eb9776d5762F85bB370d;
    address secondRecipient = 0xBB5f44dE119F74ffC1b8265bd9D0F829A78d9Cd8;
    
    function splitEther() external payable {
        uint value = msg.value;
        
        secondRecipient.transfer(value/2);
        firstRecipient.transfer(value/2);
    }
}