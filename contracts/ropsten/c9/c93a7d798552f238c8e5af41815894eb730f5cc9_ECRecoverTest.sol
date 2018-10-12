pragma solidity 0.4.24;

// File: contracts/ECRecoverTest.sol

contract ECRecoverTest {

    constructor() public {}

    event testComlete(address user, address owner);
    event prefixedTestComlete(address user, address owner);

    function test(uint8 v, bytes32 r, bytes32 s, address user, address owner) public {
        if (recover(v, r, s, user) != owner) {
            revert();
        }
        emit testComlete(user, owner);
    }

    function prefixedTest(uint8 v, bytes32 r, bytes32 s, address user, address owner) public {
        if (prefixedRecover(v, r, s, user) != owner) {
            revert();
        }
        emit prefixedTestComlete(user, owner);
    }

    function recover(uint8 v, bytes32 r, bytes32 s, address user) public pure returns (address) {
        return ecrecover(hash(user), v, r, s);
    }

    function prefixedRecover(uint8 v, bytes32 r, bytes32 s, address user) public pure returns (address) {
        return ecrecover(prefixedHash(user), v, r, s);
    }

    function prefixedHash(address user) public pure returns (bytes32) {
        return keccak256(prefixedEncode(user));
    }

    function prefixedEncode(address user) public pure returns (bytes) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return abi.encodePacked(prefix, hash(user));
    }

    function hash(address user) public pure returns (bytes32) {
        return keccak256(encode(user));
    }

    function encode(address user) public pure returns (bytes) {
        return abi.encodePacked(user);
    }
}