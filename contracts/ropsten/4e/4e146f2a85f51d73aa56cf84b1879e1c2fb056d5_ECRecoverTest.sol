pragma solidity 0.4.24;

// File: contracts/ECRecoverTest.sol

contract ECRecoverTest {

    constructor() public {}

    event testComlete(address user, address owner);

    function test(uint8 v, bytes32 r, bytes32 s, address user, address owner) public {
        if (recover(v, r, s, user) != owner) {
            revert();
        }   
        emit testComlete(user, owner);
    }   

    function recover(uint8 v, bytes32 r, bytes32 s, address user) public pure returns (address) {
        return ecrecover(hash(user), v, r, s);
    }   

    function hash(address user) public pure returns (bytes32) {
        return keccak256(encode(user));
    }   

    function encode(address user) public pure returns (bytes) {
        return abi.encodePacked(user);
    }   
}