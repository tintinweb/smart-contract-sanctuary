pragma solidity ^0.4.24;

contract RecoverEosKey {
    
    mapping (address => string) public keys;
    
    event LogRegister (address user, string key);
    
    function register(string key) public {
        assert(bytes(key).length <= 64);
        keys[msg.sender] = key;
        emit LogRegister(msg.sender, key);
    }
}