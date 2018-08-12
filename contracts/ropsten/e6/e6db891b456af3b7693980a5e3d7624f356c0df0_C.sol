pragma solidity ^0.4.24;

contract A {
    function get() public pure returns (string) {
        return "A";
    }
}

contract B {
    function get() public pure returns (string) {
        return "B";
    }
}

// https://ropsten.etherscan.io/address/0xe6db891b456af3b7693980a5e3d7624f356c0df0
contract C is A, B {
    function get() public pure returns (string) {
        return super.get();
    }
}