pragma solidity ^0.4.18;


contract S {

    function shaThree( string s ) public pure returns (bytes32) {
        return keccak256(s); // sha3(s)
    }

}