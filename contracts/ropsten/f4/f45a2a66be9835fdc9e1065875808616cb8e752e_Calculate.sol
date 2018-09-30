pragma solidity ^0.4.24;

contract Calculate {
    
    uint balance = 50000000000000000000;
    
    function done() public pure returns (uint) {
        return (50000000000000000000 / 3000) * 3000;
    }
    
    function fail() public view returns (uint) {
        return (balance / 3000) * 3000;
    }
    
}