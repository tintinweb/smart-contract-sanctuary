pragma solidity 0.4.19;

contract C { 

function testRecovery(bytes32 h, uint8 v, bytes32 r, bytes32 s) returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, h);
        return ecrecover(prefixedHash, v, r, s);
}
function RecoverySha256(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) returns (address) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        address addr = ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s);

        return addr;
}
function RecoveryKeccak256(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) returns (address) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        address addr = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s);

        return addr;
}

function RecoverySha3(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) returns (address) {
        bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        address addr = ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s);

        return addr;
}

}