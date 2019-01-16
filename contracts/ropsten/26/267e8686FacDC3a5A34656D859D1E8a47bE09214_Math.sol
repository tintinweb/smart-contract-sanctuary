pragma solidity ^0.4.24;

library Math {
    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) return a;
        else return b;
    }
}