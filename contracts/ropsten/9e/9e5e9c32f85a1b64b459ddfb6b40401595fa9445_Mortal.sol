pragma solidity ^0.4.25;

contract Mortal {
    function compute_pi(uint n) public constant returns (uint pi) {
        
        uint sum = 0;
        
        for (uint i = 1 ; i < n ; i++) {
            sum += uint(6 * 1000000) / uint(i*i);
        }
        
        return sum;
    }
}