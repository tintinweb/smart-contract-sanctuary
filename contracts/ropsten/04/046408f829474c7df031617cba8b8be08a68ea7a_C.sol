pragma solidity 0.4.19;

contract C { 
    
mapping (address => mapping (bytes32 => bool)) public orders;
mapping (address => mapping (bytes32 => uint)) public orders1;

function getSender(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) returns (address) {
        address addr = msg.sender;

        return addr;
}
function getHash(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) returns (bytes32) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders[msg.sender][hash] = true;
        return hash;
}
function checkHash(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) returns (bytes32) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(orders[msg.sender][hash] == true);
        return hash;
}
function getHash1(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) returns (bytes32) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders1[msg.sender][hash] = 1;
        return hash;
}
function checkHash1(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) returns (bytes32) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(orders1[msg.sender][hash] == 1);
        return hash;
}

function testRecovery(bytes32 h, uint8 v, bytes32 r, bytes32 s) returns (address) {
        address addr = ecrecover(h, v, r, s);

        return addr;
}
function RecoveryKeccak256(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) returns (address) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        address addr = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s);

        return addr;
}

}