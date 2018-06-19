pragma solidity ^0.4.19;

contract DEMS {
    event SendMessage(bytes iv, bytes epk, bytes ct, bytes mac, address sender);
    
    function sendMessage(bytes iv, bytes epk, bytes ct, bytes mac) external {
        SendMessage(iv, epk, ct, mac, msg.sender);
    }
}