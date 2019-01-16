pragma solidity ^0.4.24;

contract testing {
    int256 public negativeNumber = -100;
    
    function updateNumber(int256 _num) public {
        negativeNumber = _num;
    }
}